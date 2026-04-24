CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE devices (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  fcm_token TEXT UNIQUE NOT NULL,
  platform TEXT NOT NULL CHECK (platform IN ('ios', 'android')),
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  device_id UUID REFERENCES devices(id) ON DELETE CASCADE,
  station_signature TEXT NOT NULL,
  station_name TEXT NOT NULL,
  direction_signature TEXT NOT NULL,
  direction_name TEXT NOT NULL,
  departure_time TIME NOT NULL,
  active_days INTEGER[] NOT NULL,
  enabled BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

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
