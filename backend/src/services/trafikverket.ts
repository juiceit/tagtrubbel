import type { TrainAnnouncement, Station, DepartureInfo } from '../types';

const API_URL = 'https://api.trafikinfo.trafikverket.se/v2/data.json';

function getApiKey(): string {
  const key = process.env.TRAFIKVERKET_API_KEY;
  if (!key) throw new Error('TRAFIKVERKET_API_KEY is not configured');
  return key;
}

function buildXmlRequest(query: string): string {
  return `<REQUEST>
  <LOGIN authenticationkey="${getApiKey()}" />
  ${query}
</REQUEST>`;
}

async function apiRequest<T>(query: string): Promise<T[]> {
  const body = buildXmlRequest(query);
  const res = await fetch(API_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'text/xml' },
    body,
  });

  if (!res.ok) {
    throw new Error(`Trafikverket API error: ${res.status} ${res.statusText}`);
  }

  const data = (await res.json()) as Record<string, any>;
  const result = data?.RESPONSE?.RESULT;
  if (!result || result.length === 0) return [];
  return (result[0]?.TrainAnnouncement ?? result[0]?.TrainStation ?? []) as T[];
}

export async function getDepartures(
  stationSignature: string,
  fromTime: string,
  toTime: string,
): Promise<TrainAnnouncement[]> {
  const query = `
  <QUERY objecttype="TrainAnnouncement" schemaversion="1.9" limit="50">
    <FILTER>
      <AND>
        <EQ name="LocationSignature" value="${stationSignature}" />
        <EQ name="ActivityType" value="Avgang" />
        <GT name="AdvertisedTimeAtLocation" value="${fromTime}" />
        <LT name="AdvertisedTimeAtLocation" value="${toTime}" />
      </AND>
    </FILTER>
    <INCLUDE>AdvertisedTrainIdent</INCLUDE>
    <INCLUDE>AdvertisedTimeAtLocation</INCLUDE>
    <INCLUDE>EstimatedTimeAtLocation</INCLUDE>
    <INCLUDE>Canceled</INCLUDE>
    <INCLUDE>Deviation</INCLUDE>
    <INCLUDE>ToLocation</INCLUDE>
    <INCLUDE>TrainOwner</INCLUDE>
  </QUERY>`;

  return apiRequest<TrainAnnouncement>(query);
}

export async function searchStations(query: string): Promise<Station[]> {
  const xmlQuery = `
  <QUERY objecttype="TrainStation" schemaversion="1.4" limit="20">
    <FILTER>
      <LIKE name="AdvertisedLocationName" value="/^${escapeXml(query)}/i" />
    </FILTER>
    <INCLUDE>LocationSignature</INCLUDE>
    <INCLUDE>AdvertisedLocationName</INCLUDE>
  </QUERY>`;

  const results = await apiRequest<{
    LocationSignature: string;
    AdvertisedLocationName: string;
  }>(xmlQuery);

  return results.map((s) => ({
    signature: s.LocationSignature,
    name: s.AdvertisedLocationName,
  }));
}

export function announcementToDeparture(a: TrainAnnouncement): DepartureInfo {
  const destination =
    a.ToLocation && a.ToLocation.length > 0
      ? a.ToLocation[a.ToLocation.length - 1].LocationName
      : '';

  return {
    train_ident: a.AdvertisedTrainIdent,
    scheduled_time: a.AdvertisedTimeAtLocation,
    estimated_time: a.EstimatedTimeAtLocation ?? null,
    cancelled: a.Canceled,
    deviations: a.Deviation ?? [],
    destination,
  };
}

function escapeXml(str: string): string {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&apos;');
}
