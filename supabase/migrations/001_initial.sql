CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Devices (one per app installation)
CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fcm_token TEXT UNIQUE NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Trip subscriptions
CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE NOT NULL,
  station_signature TEXT NOT NULL,
  station_name TEXT NOT NULL,
  direction_signature TEXT NOT NULL,
  direction_name TEXT NOT NULL,
  departure_time TIME NOT NULL,
  active_days INTEGER[] NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Notification log (prevent duplicate alerts, GDPR retention)
CREATE TABLE notification_log (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id UUID REFERENCES subscriptions(id) ON DELETE CASCADE,
  train_ident TEXT NOT NULL,
  notification_type TEXT NOT NULL CHECK (notification_type IN ('delayed', 'cancelled', 'warning')),
  message TEXT NOT NULL,
  sent_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_subscriptions_device_id ON subscriptions(device_id);
CREATE INDEX idx_subscriptions_enabled ON subscriptions(enabled) WHERE enabled = TRUE;
CREATE INDEX idx_notification_log_sent_at ON notification_log(sent_at);

-- Row Level Security
-- Devices: clients identify themselves via device_id passed as a request header.
-- Supabase PostgREST reads x-device-id from the request and makes it available
-- via a custom claim. For simplicity, we use the service_role key for Edge
-- Functions (trusted server-side) and anon key + RLS for client access.

ALTER TABLE devices ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notification_log ENABLE ROW LEVEL SECURITY;

-- Devices: anyone can insert (register). Select/delete only own device.
CREATE POLICY "devices_insert" ON devices
  FOR INSERT TO anon WITH CHECK (true);

CREATE POLICY "devices_select" ON devices
  FOR SELECT TO anon
  USING (id::text = current_setting('request.headers', true)::json->>'x-device-id');

CREATE POLICY "devices_delete" ON devices
  FOR DELETE TO anon
  USING (id::text = current_setting('request.headers', true)::json->>'x-device-id');

-- Subscriptions: full CRUD scoped to own device
CREATE POLICY "subscriptions_select" ON subscriptions
  FOR SELECT TO anon
  USING (device_id::text = current_setting('request.headers', true)::json->>'x-device-id');

CREATE POLICY "subscriptions_insert" ON subscriptions
  FOR INSERT TO anon
  WITH CHECK (device_id::text = current_setting('request.headers', true)::json->>'x-device-id');

CREATE POLICY "subscriptions_update" ON subscriptions
  FOR UPDATE TO anon
  USING (device_id::text = current_setting('request.headers', true)::json->>'x-device-id');

CREATE POLICY "subscriptions_delete" ON subscriptions
  FOR DELETE TO anon
  USING (device_id::text = current_setting('request.headers', true)::json->>'x-device-id');

-- Notification log: read-only for own subscriptions
CREATE POLICY "notification_log_select" ON notification_log
  FOR SELECT TO anon
  USING (
    subscription_id IN (
      SELECT id FROM subscriptions
      WHERE device_id::text = current_setting('request.headers', true)::json->>'x-device-id'
    )
  );

-- Service role (Edge Functions) bypasses RLS, so check-trains can read/write everything.

-- Cron: clean up old notification logs (requires pg_cron extension on Supabase)
-- Run via Supabase Dashboard > Database > Extensions > pg_cron, then:
-- SELECT cron.schedule('cleanup-notification-log', '0 3 * * *',
--   $$DELETE FROM notification_log WHERE sent_at < NOW() - INTERVAL '30 days'$$);
