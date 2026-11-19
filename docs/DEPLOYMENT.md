# Deployment

| Component | Needs |
|---|---|
| API | any container host (Docker image built from `backend/Dockerfile`), Java 21, port `$PORT` (default 8080), 512 MB RAM is enough |
| Database | PostgreSQL 16 (managed or self-hosted) with the `pgcrypto` extension available |
| Cache | Redis 7 (optional at runtime, recommended) |
| Admin console and Partner dashboard | nothing extra: served by the API at `/admin` and `/partner` |
| Flutter Web (optional) | any static host; build with `--dart-define=API_BASE_URL=https://<api>/api` |

## Local
```bash
docker compose up --build     # PostgreSQL :5432, Redis :6379, API http://localhost:8080/api (Swagger /api/docs)
cd app && flutter run --dart-define=API_BASE_URL=http://localhost:8080/api      # iOS Simulator
```
Flyway builds the schema and loads the demo catalogue on first start. If an old database volume refuses to migrate
(duplicate keys in `V100__seed_catalogue.sql`), it was created by an older schema: `docker compose down -v` once
(deletes local data) and start again.

## Production: Easypanel on the VPS
Production runs on a VPS managed with [Easypanel](https://easypanel.io). The live API is
`https://porseng-finalproject-api.b1exgs.easypanel.host` (the mobile app uses it by default, see `app/lib/core/config/env.dart`).
The Easypanel configuration itself lives in Easypanel, not in this repository.

Services in the Easypanel project:
- **API**: an App service built from this repository (GitHub `Kvet168/final-ios-project`, branch `main`) with the Dockerfile
  at `backend/Dockerfile`, port 8080. Easypanel's proxy terminates HTTPS and issues the certificate for the domain.
- **PostgreSQL 16** and **Redis 7**: Easypanel database services in the same project. Use their internal connection strings
  for `DATABASE_URL` (the `postgres://` form is converted automatically) and `REDIS_URL`.

### Deploying a new version (automatic)
Pushing to `main` deploys by itself. The workflow [`.github/workflows/deploy.yml`](../.github/workflows/deploy.yml) does this:

1. Runs the backend tests (`mvn verify`). If they fail, nothing is deployed.
2. Calls the API service's **Easypanel deploy webhook**, so Easypanel rebuilds the image and redeploys (about 5 to 8 minutes:
   Maven build, then Flyway applies any new migration).
3. Waits, then checks `/actuator/health` on the live API and fails the run if it does not come back `UP`.

You can watch it in GitHub → **Actions**, and redeploy by hand with **Run workflow** on "Deploy to VPS (Easypanel)".

**One-time setup**
1. In Easypanel open the API service and copy its **deploy webhook URL** (look for "Deploy Webhook" in the service's settings or
   Deployments tab). Treat it like a password: anyone with it can trigger a deploy.
2. Save it as a GitHub repository secret named `EASYPANEL_DEPLOY_URL`:
   GitHub → repo → **Settings → Secrets and variables → Actions → New repository secret**, or from a terminal
   `gh secret set EASYPANEL_DEPLOY_URL -R Kvet168/final-ios-project` and paste the URL when asked.
3. Optional: a repository **variable** `HEALTH_URL` if the live health address ever changes (the default is the Easypanel
   domain above).
4. Make sure the Easypanel service's **Source** is this repository and branch `main`. If it still points at another copy of the
   repository, pushes here will not change what runs.

Simpler alternative with no tests in front: Easypanel can add its own GitHub webhook to the repository (service **Source**,
auto-deploy), which deploys on every push without this workflow. Use one of the two, not both, or every push deploys twice.

**Manual deploy:** Easypanel → API service → **Deploy**.

Back up the PostgreSQL service before a release that adds a migration (Easypanel: the database service, **Backups**).
Because every push to `main` deploys, merge to `main` only when you are ready for it to go live.

### Environment variables on the API service
Set them in the service's **Environment** tab. The table under *Production settings* below lists them all. At minimum:
`WAYFARER_PROD=true`, `DATABASE_URL`, `JWT_ACCESS_SECRET`, `PAYMENT_WEBHOOK_SECRET`, and `DEMO_PASSWORD` if the demo
accounts are seeded.

### What happens when the database is unreachable
The API exits within about a minute with the cause in the log (for example `UnknownHostException` or
`Unable to obtain connection from database`), so Easypanel shows the service as failing instead of one that accepts
connections and never answers. Check the service **Logs** first whenever the app cannot reach the server.

## Multi-city trips
The planner accepts several cities in one request ("3 days in Kampot and 2 days in Siem Reap", "kampot and siemreap for 5 days").
Cities are read in the order named (typos and run-together names are forgiven), days are split as stated or evenly, each
city gets its own stay, and the first day in a new city starts with an estimated transfer (road distance, about 50 km/h,
a bus-fare estimate). Migration `V105__itinerary_days.sql` adds the per-day table and backfills existing trips; the
transfer and fare rates are estimates, not live timetables or prices. Up to four cities per trip.

## Production settings
| Variable | Value |
|---|---|
| `WAYFARER_PROD` | `true` (refuses development secrets, hides the reset token) |
| `DATABASE_URL` | either the provider URL `postgres://user:pass@host:5432/db` (converted automatically), or a JDBC URL `jdbc:postgresql://host:5432/db` together with `DATABASE_USER` and `DATABASE_PASSWORD` |
| `DB_POOL_SIZE` | database connections per instance (default 10) |
| `FLYWAY_LOCATIONS` | default loads the demo catalogue; `classpath:db/migration` for a real launch without demo data |
| `JWT_ACCESS_SECRET` | 32+ random bytes |
| `PAYMENT_WEBHOOK_SECRET` | random secret shared with the payment provider |
| `REDIS_URL` (or `REDIS_HOST`, `REDIS_PORT`) | managed Redis; optional, everything fails open without it |
| `CORS_ORIGINS` | web origin(s) of a separately hosted Flutter web build; `*` is fine for the mobile app |
| `AI_PROVIDER_API_KEY` | optional; enables LLM-assisted summaries and answers |
| `FIREBASE_PROJECT_ID`, `GOOGLE_CLIENT_ID` | optional; enable Firebase and Google sign-in |
| `JAVA_OPTS` | JVM flags; the image defaults are tuned for a 512 MB container |

The image runs as a non-root user, trusts the host's `X-Forwarded-*` headers (HTTPS terminated by the proxy) and
compresses JSON responses.

## Scaling
Run more than one instance only after moving the WebSocket registry to Redis pub/sub (it is in-memory today).
Booking-hold expiry is a scheduled job per instance; the state change is guarded by an optimistic status check so
duplicates are harmless.

## Verified / not verified
Verified (8 Nov 2026): the production image with `WAYFARER_PROD=true`, a provider-style `postgres://` URL and `redis://` URL,
limited to 512 MB and half a CPU: Flyway from an empty database, healthy in about 20 seconds, about 285 MB in use, and
all 200 end-to-end checks in `backend/scripts/smoke.sh` passing (the password-reset step is skipped in production mode,
where the token is only emailed). An unreachable database makes it exit with code 1 after about 55 seconds.
Not verified in this repository: the live Easypanel setup (it is configured in Easypanel, not in a file here).
