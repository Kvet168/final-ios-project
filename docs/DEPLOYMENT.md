# Deployment

| Component | Needs |
|---|---|
| API | any container host (Docker image built from `backend/Dockerfile`), Java 21, port 8080 |
| Database | PostgreSQL 16 (managed or self-hosted) with the `pgcrypto` extension available |
| Cache | Redis 7 (optional at runtime, recommended) |
| Admin console and Partner dashboard | nothing extra: served by the API at `/admin` and `/partner` |
| Flutter Web (optional) | any static host; build with `--dart-define=API_BASE_URL=https://<api>/api` |

## Local
```bash
docker compose up --build     # PostgreSQL :5432, Redis :6379, API http://localhost:8080/api (Swagger /api/docs)
```
Flyway builds the schema and loads the demo catalogue on first start.

## Production checklist
| Variable | Value |
|---|---|
| `WAYFARER_PROD` | `true` (refuses development secrets, hides the reset token) |
| `DATABASE_URL`, `DATABASE_USER`, `DATABASE_PASSWORD` | managed PostgreSQL |
| `FLYWAY_LOCATIONS` | `classpath:db/migration` (schema only: do **not** load the demo seed) |
| `JWT_ACCESS_SECRET` | 32+ random bytes |
| `PAYMENT_WEBHOOK_SECRET` | random secret shared with the payment provider |
| `REDIS_HOST`, `REDIS_PORT` | managed Redis |
| `CORS_ORIGINS` | the web origin(s), not `*` |
| `AI_PROVIDER_API_KEY` | optional; enables LLM-assisted summaries and answers |

Run more than one instance only after moving the WebSocket registry to Redis pub/sub (it is in-memory today). Booking-hold expiry is a scheduled job per instance; the state change is guarded by an optimistic status check so duplicates are harmless.

## Verified / not verified
Verified: `docker compose up --build` (multi-stage image, non-root user) against PostgreSQL 16 and Redis 7, Flyway from an empty database, 131 end-to-end checks (`backend/scripts/smoke.sh`) against the containerised API.
Not verified: any cloud host, TLS termination.
