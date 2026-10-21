# WAYFARER: AI Travel, Hotel & Location App (Android)

A native-feeling **Android mobile app** built with Flutter, backed by a TypeScript/Express REST API and a PostgreSQL (Neon) database. The app is the product; the API is the server it talks to, exactly like any mobile app that needs accounts, bookings and a catalogue.

| | |
|---|---|
| Android app | `app/` -> `flutter build apk --release` (see below) |
| API base URL | https://wayfarer-api-liart.vercel.app/api |
| API docs (Swagger UI) | https://wayfarer-api-liart.vercel.app/api/docs |
| Health | https://wayfarer-api-liart.vercel.app/api/health |

## What it does
- **Discover**: 30 destinations (Cambodia and Southeast/East Asia), 370+ places and activities, 76 stays, curated itineraries. Photos and fonts ship inside the app, so screens never wait on image hosting and work offline.
- **Stays and booking**: real date availability, server-side filters, price breakdowns, held rooms with a countdown, simulated payment (clearly labelled), cancellation and receipts, tickets for every booking.
- **AI trip planner**: natural-language request -> day-by-day itinerary built **only from stored records**, with a budget split, route map and editable stops. Without an LLM key it uses a transparent rules engine and says so.
- **AI travel guide**: intent- and destination-aware assistant. Answers come from structured destination data and approved guides, show numbered sources, offer tappable result cards and follow-up questions, and decline rather than guess.
- Map (OpenStreetMap data), wishlist, notifications, admin console and partner portal with server-enforced roles.
- Offline resilience: catalogue pages are cached on the device and shown if the connection drops; the app warms the API during its launch animation.

## Repository layout
```
app/       Flutter Android app (Riverpod, go_router, Dio); assets/ = bundled photos + fonts
backend/   Express + TypeScript API, SQL migrations, idempotent seed, tests (Vitest)
docs/      Documentation package
.github/   CI workflow
```

## Build and run the Android app
```bash
cd app && flutter pub get
flutter run                                   # on a connected phone / emulator
flutter build apk --release --target-platform android-arm64   # installable demo APK
# -> app/build/app/outputs/flutter-apk/app-release.apk
```
The app talks to the hosted API by default. To use a local API: `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api` (Android emulator) and `cd backend && npm ci && npm run dev`.

## Backend
```bash
cd backend && npm ci && npm run dev          # http://localhost:8080/api/health (in-process Postgres when DATABASE_URL is empty)
npm run seed                                  # seeds the configured database (idempotent)
npm test                                      # API, booking, seed and assistant tests
```
Copy `backend/.env.example` to `backend/.env` and fill values. **Never commit `.env`.** Set `AI_PROVIDER_API_KEY` to let a language model rewrite the grounded answers; without it everything still works in rules/retrieval mode.

## Testing the UI without a phone
`app/test/shots_test.dart` and `shots2_test.dart` render every screen with the real theme, bundled photos and recorded API data and write PNGs to `app/test/shots/`. `flow_test.dart` drives the real router (welcome, tabs, assistant, destination detail). Run `flutter test`.

## Demo accounts
See [docs/USER_MANUAL.md](docs/USER_MANUAL.md). The sign-in screen has a one-tap **Try the demo account** (customer Maya). Admin/staff/partner demo passwords are not in the repo.

## Honest status
See [docs/LIMITATIONS_AND_FUTURE_WORK.md](docs/LIMITATIONS_AND_FUTURE_WORK.md) and [docs/TESTING_REPORT.md](docs/TESTING_REPORT.md).
