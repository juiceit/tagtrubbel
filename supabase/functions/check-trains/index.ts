import { serve } from "https://deno.land/std@0.177.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

const API_URL = "https://api.trafikinfo.trafikverket.se/v2/data.json";
const FCM_URL = "https://fcm.googleapis.com/v1/projects/{PROJECT_ID}/messages:send";
const LOOK_BACK_MINUTES = 90;
const WARNING_THRESHOLD = 0.5;

interface Subscription {
  id: string;
  device_id: string;
  station_signature: string;
  station_name: string;
  direction_signature: string;
  direction_name: string;
  departure_time: string;
  active_days: number[];
  devices: { fcm_token: string };
}

interface TrainAnnouncement {
  AdvertisedTrainIdent: string;
  AdvertisedTimeAtLocation: string;
  EstimatedTimeAtLocation?: string;
  Canceled: boolean;
  Deviation?: string[];
  ToLocation?: { LocationName: string }[];
}

serve(async (req) => {
  // Verify this is called by cron or with service role key
  const authHeader = req.headers.get("Authorization");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (!authHeader?.includes(serviceRoleKey ?? "NONE")) {
    return new Response("Unauthorized", { status: 401 });
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL")!;
  const supabase = createClient(supabaseUrl, serviceRoleKey!);
  const apiKey = Deno.env.get("TRAFIKVERKET_API_KEY");

  if (!apiKey) {
    return new Response(JSON.stringify({ error: "TRAFIKVERKET_API_KEY not configured" }), {
      status: 500,
      headers: { "Content-Type": "application/json" },
    });
  }

  const now = new Date();
  const currentDay = now.getDay() === 0 ? 7 : now.getDay();
  const currentMinutes = now.getHours() * 60 + now.getMinutes();

  // Fetch all active subscriptions with their device FCM tokens
  const { data: subscriptions, error } = await supabase
    .from("subscriptions")
    .select("*, devices!inner(fcm_token)")
    .eq("enabled", true)
    .contains("active_days", [currentDay]);

  if (error) {
    console.error("Failed to fetch subscriptions:", error);
    return new Response(JSON.stringify({ error: error.message }), { status: 500 });
  }

  let checked = 0;
  let notified = 0;

  for (const sub of (subscriptions as Subscription[]) ?? []) {
    const [h, m] = sub.departure_time.split(":").map(Number);
    const departureMinutes = h * 60 + m;
    const windowStart = departureMinutes - LOOK_BACK_MINUTES;

    if (currentMinutes < windowStart || currentMinutes > departureMinutes) continue;

    checked++;
    const result = await checkSubscription(sub, apiKey, now, supabase);
    if (result) notified++;
  }

  return new Response(
    JSON.stringify({ checked, notified, timestamp: now.toISOString() }),
    { headers: { "Content-Type": "application/json" } }
  );
});

async function checkSubscription(
  sub: Subscription,
  apiKey: string,
  now: Date,
  supabase: ReturnType<typeof createClient>
): Promise<boolean> {
  const [hours, minutes] = sub.departure_time.split(":").map(Number);
  const departureDate = new Date(now);
  departureDate.setHours(hours, minutes, 0, 0);

  const fromDate = new Date(departureDate);
  fromDate.setMinutes(fromDate.getMinutes() - LOOK_BACK_MINUTES);

  const toDate = new Date(departureDate);
  toDate.setMinutes(toDate.getMinutes() + 1);

  const fromStr = fromDate.toISOString().replace("Z", "");
  const toStr = toDate.toISOString().replace("Z", "");

  let announcements: TrainAnnouncement[];
  try {
    announcements = await fetchDepartures(apiKey, sub.station_signature, fromStr, toStr);
  } catch (err) {
    console.error(`Fetch failed for ${sub.station_signature}:`, err);
    return false;
  }

  // Filter to matching direction
  const relevant = announcements.filter((a) => {
    if (!a.ToLocation || a.ToLocation.length === 0) return true;
    return a.ToLocation.some((loc) => loc.LocationName === sub.direction_signature);
  });

  if (relevant.length === 0) return false;

  // Check user's specific train
  const userTrain = relevant.find((a) => {
    const scheduled = new Date(a.AdvertisedTimeAtLocation);
    return scheduled.getHours() === hours && Math.abs(scheduled.getMinutes() - minutes) <= 2;
  });

  if (userTrain?.Canceled) {
    return await notify(
      sub, supabase, userTrain.AdvertisedTrainIdent, "cancelled",
      `Tåg ${userTrain.AdvertisedTrainIdent} till ${sub.direction_name} kl ${sub.departure_time} är inställt.`
    );
  }

  if (userTrain?.EstimatedTimeAtLocation) {
    const scheduled = new Date(userTrain.AdvertisedTimeAtLocation).getTime();
    const estimated = new Date(userTrain.EstimatedTimeAtLocation).getTime();
    const delayMin = Math.round((estimated - scheduled) / 60000);
    if (delayMin >= 3) {
      return await notify(
        sub, supabase, userTrain.AdvertisedTrainIdent, "delayed",
        `Tåg ${userTrain.AdvertisedTrainIdent} till ${sub.direction_name} beräknas bli ${delayMin} min försenat.`
      );
    }
  }

  // Pattern detection: check if many earlier trains are delayed
  const troubled = relevant.filter((a) => {
    if (a.Canceled) return true;
    if (a.EstimatedTimeAtLocation) {
      const s = new Date(a.AdvertisedTimeAtLocation).getTime();
      const e = new Date(a.EstimatedTimeAtLocation).getTime();
      return (e - s) / 60000 >= 3;
    }
    return false;
  });

  const ratio = troubled.length / relevant.length;
  if (ratio >= WARNING_THRESHOLD && relevant.length >= 2) {
    return await notify(
      sub, supabase, "multiple", "warning",
      `Störningar på sträckan ${sub.station_name} → ${sub.direction_name}. Din avgång kl ${sub.departure_time} kan bli påverkad.`
    );
  }

  return false;
}

async function fetchDepartures(
  apiKey: string, station: string, from: string, to: string
): Promise<TrainAnnouncement[]> {
  const xmlBody = `<REQUEST>
  <LOGIN authenticationkey="${apiKey}" />
  <QUERY objecttype="TrainAnnouncement" schemaversion="1.9" limit="50">
    <FILTER>
      <AND>
        <EQ name="LocationSignature" value="${station}" />
        <EQ name="ActivityType" value="Avgang" />
        <GT name="AdvertisedTimeAtLocation" value="${from}" />
        <LT name="AdvertisedTimeAtLocation" value="${to}" />
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

  if (!res.ok) throw new Error(`API error: ${res.status}`);
  const data = await res.json();
  return data?.RESPONSE?.RESULT?.[0]?.TrainAnnouncement ?? [];
}

async function notify(
  sub: Subscription,
  supabase: ReturnType<typeof createClient>,
  trainIdent: string,
  type: "delayed" | "cancelled" | "warning",
  message: string
): Promise<boolean> {
  const today = new Date().toISOString().slice(0, 10);

  // Check for duplicate
  const { data: existing } = await supabase
    .from("notification_log")
    .select("id")
    .eq("subscription_id", sub.id)
    .eq("train_ident", trainIdent)
    .eq("notification_type", type)
    .gte("sent_at", today)
    .limit(1);

  if (existing && existing.length > 0) return false;

  const title = type === "cancelled"
    ? "Inställt tåg"
    : type === "delayed"
    ? "Försenat tåg"
    : "Möjliga störningar";

  // Send FCM notification
  const sent = await sendFcmNotification(sub.devices.fcm_token, title, message);

  if (sent) {
    await supabase.from("notification_log").insert({
      subscription_id: sub.id,
      train_ident: trainIdent,
      notification_type: type,
      message,
    });
  }

  return sent;
}

async function sendFcmNotification(
  fcmToken: string, title: string, body: string
): Promise<boolean> {
  const serviceAccountJson = Deno.env.get("FIREBASE_SERVICE_ACCOUNT");
  if (!serviceAccountJson) {
    console.log(`[DRY RUN] → ${fcmToken.slice(0, 10)}...: ${title} — ${body}`);
    return true;
  }

  try {
    const serviceAccount = JSON.parse(serviceAccountJson);
    const accessToken = await getGoogleAccessToken(serviceAccount);
    const projectId = serviceAccount.project_id;

    const res = await fetch(
      `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`,
      {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
          Authorization: `Bearer ${accessToken}`,
        },
        body: JSON.stringify({
          message: {
            token: fcmToken,
            notification: { title, body },
            android: { priority: "high" },
            apns: { payload: { aps: { sound: "default", badge: 1 } } },
          },
        }),
      }
    );

    if (!res.ok) {
      const err = await res.text();
      console.error("FCM send failed:", err);
      return false;
    }
    return true;
  } catch (err) {
    console.error("FCM error:", err);
    return false;
  }
}

async function getGoogleAccessToken(
  serviceAccount: { client_email: string; private_key: string }
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = btoa(JSON.stringify({ alg: "RS256", typ: "JWT" }));
  const claim = btoa(
    JSON.stringify({
      iss: serviceAccount.client_email,
      scope: "https://www.googleapis.com/auth/firebase.messaging",
      aud: "https://oauth2.googleapis.com/token",
      iat: now,
      exp: now + 3600,
    })
  );

  const encoder = new TextEncoder();
  const signingInput = `${header}.${claim}`;

  // Import the private key
  const pemContents = serviceAccount.private_key
    .replace(/-----BEGIN PRIVATE KEY-----/, "")
    .replace(/-----END PRIVATE KEY-----/, "")
    .replace(/\n/g, "");
  const binaryDer = Uint8Array.from(atob(pemContents), (c) => c.charCodeAt(0));

  const key = await crypto.subtle.importKey(
    "pkcs8",
    binaryDer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"]
  );

  const signature = await crypto.subtle.sign(
    "RSASSA-PKCS1-v1_5",
    key,
    encoder.encode(signingInput)
  );

  const signatureB64 = btoa(String.fromCharCode(...new Uint8Array(signature)));
  const jwt = `${signingInput}.${signatureB64}`;

  const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded" },
    body: `grant_type=urn:ietf:params:oauth:grant-type:jwt-bearer&assertion=${jwt}`,
  });

  const tokenData = await tokenRes.json();
  return tokenData.access_token;
}
