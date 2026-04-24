import { serve } from "https://deno.land/std@0.177.0/http/server.ts";

const API_URL = "https://api.trafikinfo.trafikverket.se/v2/data.json";

function escapeXml(str: string): string {
  return str
    .replace(/&/g, "&amp;")
    .replace(/</g, "&lt;")
    .replace(/>/g, "&gt;")
    .replace(/"/g, "&quot;")
    .replace(/'/g, "&apos;");
}

serve(async (req) => {
  const url = new URL(req.url);
  const query = url.searchParams.get("q") ?? "";

  if (query.length < 2) {
    return new Response(JSON.stringify([]), {
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

  const xmlBody = `<REQUEST>
  <LOGIN authenticationkey="${apiKey}" />
  <QUERY objecttype="TrainStation" schemaversion="1.4" limit="20">
    <FILTER>
      <LIKE name="AdvertisedLocationName" value="/^${escapeXml(query)}/i" />
    </FILTER>
    <INCLUDE>LocationSignature</INCLUDE>
    <INCLUDE>AdvertisedLocationName</INCLUDE>
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
  const stations = (data?.RESPONSE?.RESULT?.[0]?.TrainStation ?? []).map(
    (s: { LocationSignature: string; AdvertisedLocationName: string }) => ({
      signature: s.LocationSignature,
      name: s.AdvertisedLocationName,
    })
  );

  return new Response(JSON.stringify(stations), {
    headers: { "Content-Type": "application/json" },
  });
});
