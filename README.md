# Tågtrubbel 🚂

Push notifications for Swedish train delays and cancellations.

Tågtrubbel monitors your commuter trains via the Trafikverket API and sends a
notification to your phone when there are delays or cancellations — including a
"smart warning" based on earlier trains on the same line.

## Project structure

```
app/       Flutter mobile app (iOS + Android)
backend/   Node.js + Express API server
```

## Getting started

### Prerequisites

- Flutter SDK 3.x
- Node.js 20+
- PostgreSQL
- A Trafikverket API key (free): https://api.trafikinfo.trafikverket.se/
- Firebase project (for push notifications)

### Backend

```bash
cd backend
cp ../.env.example .env   # Fill in your values
npm install
npm run migrate           # Create database tables
npm run dev               # Start dev server on :3000
```

### App

```bash
cd app
flutter pub get
flutter run
```

## Configuration

The app connects to the backend to register the device and manage subscriptions.
Update the API base URL in `app/lib/services/api_service.dart`.

## Features

- Monitor specific train departures by station, direction, and time
- Select which weekdays to monitor
- Pause/resume subscriptions (e.g. during vacation)
- "Earlier trains" heuristic: checks trains 0–90 min before your departure to
  detect systemic delays before your train is officially marked late
- Push notifications for: delayed trains, cancelled trains, and pattern warnings
- Swedish and English UI (auto-detected from OS, manually switchable)
- GDPR: delete all your data from the settings screen
