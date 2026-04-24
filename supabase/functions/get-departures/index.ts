import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const API_URL = "https://api.trafikinfo.trafikverket.se/v2/data.json";

serve(async (req) => {
  const url = new URL(req.url);
  const station = url.searchParams.get("station");
  const direction = url.searchParams.get("direction");

  if (!station) {
    return new Response(JSON.stringify({ error: "station parameter required" }), {
      status: 400,
      headers: { "Content-Type": "application/json" },
    });
  }

  const apiKey = Deno.env.get("TRAFIKVERKET_API_KEY");
  if (!apiKey) {
    return new Response(JSON.stringify({ error: "TRAFIKVERKET_API_KEY not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const now = new Date();
  const fromStr = now.toISOString().replace("Z", "");
  const to = new Date(now.getTime() + 3 * 60 * 60 * 1000);
  const toStr = to.toISOString().replace("Z", "");

  const xmlBody = `<REQUEST>
  <LOGIN authenticationkey="${apiKey}" />
  <QUERY objecttype="TrainAnnouncement" schemaversion="1.9" limit="50">
    <FILTER>
      <AND>
        <EQ name="LocationSignature" value="${station}" />
        <EQ name="ActivityType" value="Avgang" />
        <GT name="AdvertisedTimeAtLocation" value="${fromStr}" />
        <LT name="AdvertisedTimeAtLocation" value="${toStr}" />
      </AND>
    </FILTER>
    <INCLUDE>AdvertisedTrainIdent</INCLUDE>
    <INCLUDE>AdvertisedTimeAtLocation</INCLUDE>
    <INCLUDE>EstimatedTimeAtLocation</INCLUDE>
    <INCLUDE>Canceled</INCLUDE>
    <INCLUDE>Deviation</INCLUDE>
    <INCLUDE>ToLocation</INCLUDE>
    <INCLUDE>TrainOwner</INCLUDE>
  </QUERY>
</REQUEST>`;

  const res = await fetch(API_URL, {
    method: "POST",
    headers: { "Content-Type": "text/xml" },
    body: xmlBody,
  });

  if (!res.ok) {
    return new Response(JSON.stringify({ error: "Trafikverket API error" }), {
      status: 502,
      headers: { "Content-Type": "application/json" },
    });
  }

  const data = await res.json();
  let announcements = data?.RESPONSE?.RESULT?.[0]?.TrainAnnouncement ?? [];

  if (direction) {
    announcements = announcements.filter(
      (a: { ToLocation?: { LocationName: string }[] }) => {
        if (!a.ToLocation || a.ToLocation.length === 0) return true;
        return a.ToLocation.some((loc) => loc.LocationName === direction);
      }
    );
  }

  const departures = announcements.map(
    (a: {
      AdvertisedTrainIdent: string;
      AdvertisedTimeAtLocation: string;
      EstimatedTimeAtLocation?: string;
      Canceled: boolean;
      Deviation?: string[];
      ToLocation?: { LocationName: string }[];
    }) => ({
      train_ident: a.AdvertisedTrainIdent,
      scheduled_time: a.AdvertisedTimeAtLocation,
      estimated_time: a.EstimatedTimeAtLocation ?? null,
      cancelled: a.Canceled,
      deviations: a.Deviation ?? [],
      destination:
        a.ToLocation && a.ToLocation.length > 0
          ? a.ToLocation[a.ToLocation.length - 1].LocationName
          : "",
    })
  );

  return new Response(JSON.stringify(departures), {
    headers: { "Content-Type": "application/json" },
  });
});
