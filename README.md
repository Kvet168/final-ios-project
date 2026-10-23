# WAYFARER: AI Travel, Hotel & Location App

A Flutter mobile app (iOS and Android) backed by a **Java 21 / Spring Boot** REST + WebSocket API on **PostgreSQL** and **Redis**. The app is the product; the API is the server it talks to.

| | |
|---|---|
| Mobile app | `app/` (Flutter, Riverpod, go_router, Dio) |
| Admin console | `http://localhost:8080/admin` (web, served by the backend) |
| Partner dashboard | `http://localhost:8080/partner` (web, served by the backend) |
| Backend | `backend/` (Spring Boot 3.3, Flyway, JWT, Redis, WebSocket) |
| API docs | Swagger UI at `http://localhost:8080/api/docs`; reference in [backend/docs/API.md](backend/docs/API.md) |
| ERD / schema / SQL | [backend/docs/ERD.md](backend/docs/ERD.md), [backend/sql](backend/sql), Flyway scripts in `backend/src/main/resources/db` |

## What it does
- **Discover**: 30 destinations (Cambodia and Southeast/East Asia), 373 places, activities and restaurants, 76 stays, curated itineraries. Photos and fonts ship inside the app.
- **Hotel, room, attraction and restaurant search** with filters, date availability, price breakdowns, maps and distance.
- **Booking**: held rooms with a countdown, simulated payment (clearly labelled), cancellation with refund rules, receipts, tickets, reviews from verified stays, live status updates over WebSocket.
- **AI trip planner**: "three days in Phnom Penh and $150" becomes a day-by-day plan (sights, restaurants, a stay, budget split, travel times, route links) built only from stored records, optimised for budget, distance, opening hours, travel time and interests. Without an LLM key it uses a transparent rules engine and says so.
- **AI travel guide**: intent- and destination-aware assistant grounded in approved guides, with sources, tappable cards and follow-ups; it declines rather than guesses.
- Wishlist, notifications, and two **web dashboards** served by the same backend:
  - **Admin console** (`/admin`): creates partner accounts and hands over credentials, and *views* partners and every hotel, hostel, bungalow and resort (read-only: no prices, rooms or stock). Also bookings, payments, destinations, reviews, users and roles, audit log, AI usage.
  - **Partner dashboard** (`/partner`): each hotel owner creates and sells their own hotels, resorts, bungalows or hostels with photos, adds rooms, sets stock and prices, manages their payment QR code and confirms guest QR payments, and handles check-in.

  Roles are enforced by the server.

## Repository layout
```
app/       Flutter app; assets/ = bundled photos + fonts
backend/   Spring Boot API: src/main/java (feature packages), src/main/resources/static (the /admin and /partner web apps), src/test, scripts/smoke.sh, sql/, docs/
docs/      Documentation package
.github/   CI workflow
```

## Run it
```bash
docker compose up --build        # PostgreSQL :5432, Redis :6379, API http://localhost:8080/api (Flyway creates schema + demo data)

cd app && flutter pub get
flutter run --dart-define=API_BASE_URL=http://localhost:8080/api          # iOS Simulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api           # Android emulator
```

> If you ran the previous (Node) version of this project, its database volume is not compatible with Flyway. Run `docker compose down -v` once to start clean.

## Backend development
```bash
cd backend
docker compose -f ../docker-compose.yml up -d db redis
DATABASE_URL=jdbc:postgresql://localhost:5432/wayfarer mvn spring-boot:run   # http://localhost:8080
mvn verify                       # 36 unit tests
scripts/smoke.sh http://localhost:8080   # 202 end-to-end checks against a running API
```
Set `AI_PROVIDER_API_KEY` to let a language model rewrite the grounded summaries and answers; without it everything still works in rules/retrieval mode. See [backend/README.md](backend/README.md) for configuration.

## Demo accounts
See [docs/USER_MANUAL.md](docs/USER_MANUAL.md). The sign-in screen has a one-tap **Try the demo account** (customer Maya); the password is the `DEMO_PASSWORD` environment variable.

## Honest status
See [docs/LIMITATIONS_AND_FUTURE_WORK.md](docs/LIMITATIONS_AND_FUTURE_WORK.md) and [docs/TESTING_REPORT.md](docs/TESTING_REPORT.md).
