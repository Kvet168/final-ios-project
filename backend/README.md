# WAYFARER API (Spring Boot)

Java 21 · Spring Boot 3.3 · PostgreSQL 16 · Redis 7 · WebSocket · Flyway · JWT.
It implements the course "REST API", "Authentication", "Database" and "Backend (Option A)" requirements for the WAYFARER stays and bookings domain.
The same Postgres schema is used by the Express backend in `../backend`; this module is a drop-in Spring Boot implementation of the core API.

| Course requirement | Implementation |
|---|---|
| Spring Boot + Java | `src/main/java/com/wayfarer/**` |
| Admin console and Partner dashboard (web) | `src/main/resources/static/{admin,partner,dashboard}`, served at `/admin` and `/partner` |
| PostgreSQL | Flyway migrations in `src/main/resources/db/migration`, 33 tables |
| Redis | catalogue cache (`JsonCache`), auth rate limiter, logout access-token denylist |
| WebSocket | `/ws`, JWT-authenticated, live `booking.status` and `notification` events |
| REST API (method, URL, auth, request, response, error, status) | [docs/API.md](docs/API.md) + Swagger UI at `/api/docs` |
| Register / Login / Logout | `AuthController` |
| JWT + Refresh token | 15-min HS256 access token, opaque 30-day refresh token stored as SHA-256, rotated on use, reuse detection revokes the family |
| Password hashing | BCrypt (cost 10) |
| Role-based authorization | roles `customer, partner, staff, admin`; URL rules + `@PreAuthorize`; role is re-read from the DB on every request |
| ERD, schema, SQL scripts | [docs/ERD.md](docs/ERD.md), [sql/schema.sql](sql/schema.sql), [sql/sample_data.sql](sql/sample_data.sql), Flyway scripts |
| Transactions, constraints, indexes, audit, timestamps, soft delete | see the table in [docs/ERD.md](docs/ERD.md) |
| Advanced: OTP / email verification | not implemented (password reset token flow exists, no email provider is configured) |

## Run it

Needs Docker (or a local PostgreSQL 16, Redis 7 and JDK 21). From the repository root:

```bash
docker compose up --build            # API on http://localhost:8080 (Swagger at /api/docs)
# or run the API from source against the compose database and cache:
docker compose up -d db redis
cd backend && DATABASE_URL=jdbc:postgresql://localhost:5432/wayfarer mvn spring-boot:run
```

Flyway creates the schema on first start and, with the default `FLYWAY_LOCATIONS`, loads the demo catalogue and accounts
(`admin@demo.wayfarer.test`, `staff1@`, `partner.pp@`, `maya@` ...). The password is the `DEMO_PASSWORD` environment variable
(development default: `Wayfarer#Demo2026`). For a clean database use `FLYWAY_LOCATIONS=classpath:db/migration`.

## Web dashboards

Two single-page apps ship inside the API and are served by it (same host, no CORS, nothing extra to deploy):

| URL | Who | What |
|---|---|---|
| `/admin` | staff, admin | overview and charts, **partners** (admin creates the owner account and gets a one-time temporary password; list, detail, reset password), **hotels and hostels (read-only)**, bookings (detail, cancel, check-in), payments, destinations, review moderation, users and roles (admin only), audit log, AI usage |
| `/partner` | partner only | dashboard (occupancy, bookings, revenue), **my properties** (create hotels, resorts, bungalows, hostels, guesthouses ... with photos; add, edit and delete rooms with photos; stock and price by date range), bookings (check guests in and out), **QR payments** (upload the payment QR, confirm or reject guest payments), guest reviews, account |

**Who owns what.** Hotels, rooms, prices, stock, photos and the payment QR belong to the partner. Administrators and staff can see them but every write endpoint for them lives under `/api/partner/**` (partner role only); the admin API has no hotel, room, price or stock writes. A partner can only touch their own records (anything else answers 404).

**Accounts.** An administrator creates a partner with `POST /api/admin/partners`; the response contains a random 12-character temporary password, shown once. The first sign-in forces a password change (`POST /api/auth/change-password`). `POST /api/admin/partners/{id}/reset-password` issues a new temporary password.

**QR payments.** The partner uploads their bank/KHQR code and account name. For that partner's properties a guest can choose `method: "qr"` when creating a payment: `GET /api/bookings/{id}/pay-qr` returns the QR image, account name, bank and exact amount; the guest pays in their banking app and calls `POST /api/payments/{id}/claim`; the partner sees it under QR payments and confirms (`/api/partner/payments/{id}/confirm`, booking becomes CONFIRMED) or rejects. Claiming extends the booking hold by 12 hours so the partner has time to check their account. This is manual reconciliation, not a bank integration: the system cannot verify the money arrived.

**Images.** `POST /api/media` (multipart, partner/staff/admin) stores PNG/JPEG/WebP up to 2 MB in the database (type decided from the file's bytes; SVG refused) and returns `/api/media/{id}`, which is public and cached. Properties and rooms accept only an image the caller uploaded or an `https://` URL.

They are plain ES modules (no build step, no third-party code): `static/dashboard` holds the shared design system, API client with token refresh, app shell and the hotel/booking pages used by both apps. Sign-in uses the normal `/api/auth/login`; a role that is not allowed gets a clear message. Every call is authorised by the server, so the pages are public static files but show nothing without a valid role. The pages are served with a strict Content-Security-Policy (`script-src 'self'`) and build all markup with `textContent`, never `innerHTML`.

## Test it

```bash
mvn verify                     # 36 unit tests: state machine, JWT, webhook HMAC, validation, planner, parser
scripts/smoke.sh http://localhost:8080   # 202 end-to-end checks against a running API
```

The smoke test covers register/login/refresh rotation and reuse detection, booking, idempotent payment, webhook signature rejection, refund on cancel,
cross-user isolation, staff/admin role rules and logout (access token denied via Redis). Concurrency was checked separately: 12 parallel bookings for a
room with 3 units gave exactly 3 `201` and 9 `409 NO_AVAILABILITY`.

## Configuration (environment variables)

| Variable | Default | Notes |
|---|---|---|
| `DATABASE_URL`, `DATABASE_USER`, `DATABASE_PASSWORD` | local compose values | JDBC URL |
| `REDIS_HOST`, `REDIS_PORT` | `localhost`, `6379` | Redis is optional at runtime: if it is down the API still works (cache miss, no rate limit, no denylist) and logs a warning |
| `JWT_ACCESS_SECRET` | dev value | **Required in production**, 32+ bytes |
| `PAYMENT_PROVIDER_MODE`, `PAYMENT_WEBHOOK_SECRET` | `mock`, dev value | webhook secret required in production |
| `WAYFARER_PROD` | `false` | `true` makes the app refuse dev secrets and hides the reset token |
| `CORS_ORIGINS` | `*` | comma separated |
| `BOOKING_HOLD_MINUTES` | `30` | unpaid bookings expire and release their rooms |

## Design notes

* **No overselling.** Inventory rows are locked `FOR UPDATE` inside the booking transaction; a conditional `UPDATE ... WHERE units_available >= n` is the second guard.
* **Client never confirms payment.** A booking becomes `CONFIRMED` only through a signed provider webhook or the server-side simulator, both going through `PaymentService.applyWebhookEvent` (idempotent per provider event id, amount verified).
* **Live updates after commit.** Pushes are Spring events handled by `@TransactionalEventListener(AFTER_COMMIT)`, so clients never see a state that was rolled back.
* **Security defaults.** Stateless, CSRF off (bearer tokens, no cookies), identical login errors for unknown email and wrong password (a dummy hash is checked to keep timing similar), role never accepted from the client on register.
* **Persistence style.** Plain SQL through `NamedParameterJdbcTemplate` (reusing the schema and queries of the Express backend) rather than JPA, which keeps the booking locking and reporting queries explicit.

## Known limits

* Payments are simulated; no real card processor is wired in.
* OTP and email verification are not implemented (the password-reset token flow exists, no email provider is configured).
* The WebSocket registry is in-memory (single instance). Multi-instance fan-out would publish `UserPush` through Redis pub/sub.
* The language-model path (`LlmClient`) has not been exercised without an API key; failures fall back to the rules path.
* Weather-aware planning is not implemented.
