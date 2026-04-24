# Tågtrubbel 🚂

Push notifications for Swedish train delays and cancellations.

Tågtrubbel monitors your commuter trains via the Trafikverket API and sends a
notification to your phone when there are delays or cancellations — including a
"smart warning" based on earlier trains on the same line.

## Project structure

```
app/       Flutter mobile app (iOS + Android)
supabase/  Supabase backend (migrations, Edge Functions)
```

## Getting started

### Prerequisites

- Flutter SDK 3.x
- A [Supabase](https://supabase.com) project (free tier works)
- A Trafikverket API key (free): https://api.trafikinfo.trafikverket.se/
- A Firebase project (for push notifications)

### Supabase setup

1. Create a project at [supabase.com](https://supabase.com)
2. Run the migration in the Supabase SQL Editor (copy `supabase/migrations/001_initial.sql`)
3. Deploy Edge Functions:
   ```bash
   supabase functions deploy search-stations
   supabase functions deploy get-departures
   supabase functions deploy check-trains
   ```
4. Set secrets for Edge Functions:
   ```bash
   supabase secrets set TRAFIKVERKET_API_KEY=your-key
   supabase secrets set FIREBASE_SERVICE_ACCOUNT='{"type":"service_account",...}'
   ```
5. Set up a cron job to call the `check-trains` function every minute:
   - Supabase Dashboard → Database → Extensions → enable `pg_cron` and `pg_net`
   - Then run in SQL Editor:
     ```sql
     SELECT cron.schedule(
       'check-trains',
       '* * * * *',
       $$SELECT net.http_post(
         url := 'https://YOUR_PROJECT.supabase.co/functions/v1/check-trains',
         headers := '{"Authorization": "Bearer YOUR_SERVICE_ROLE_KEY"}'::jsonb
       )$$
     );
     ```

### App

1. Update `app/lib/main.dart` with your Supabase URL and anon key
2. Run:
   ```bash
   cd app
   flutter pub get
   flutter run
   ```

## Features

- Monitor specific train departures by station, direction, and time
- Select which weekdays to monitor
- Pause/resume subscriptions (e.g. during vacation)
- "Earlier trains" heuristic: checks trains 0–90 min before your departure to
  detect systemic delays before your train is officially marked late
- Push notifications for: delayed trains, cancelled trains, and pattern warnings
- Swedish and English UI (auto-detected from OS, manually switchable)
- GDPR: delete all your data from the settings screen
- Row Level Security: each device can only see its own data
