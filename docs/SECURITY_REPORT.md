# Security report

| Control | Implementation |
|---|---|
| Passwords | bcrypt (cost 10), min 10 chars with letters + digit |
| Sessions | 15 min JWT with a unique id; logout adds it to a Redis denylist; refresh tokens hashed (SHA-256) and rotated; reuse revokes the family; password reset and role change revoke all |
| AuthZ | role re-read from DB per privileged request; ownership checks return 404 for foreign resources; partner scoped by `partners.user_id` |
| Input | Jakarta Bean Validation on every request body; parameterised SQL only; LIKE wildcards escaped |
| Abuse | Redis rate limits per IP on credential endpoints (30 per 15 min) and AI endpoints (20 per minute) |
| Transport/headers | TLS terminated by the host, Spring Security default headers, CORS allow-list via `CORS_ORIGINS` |
| Payments | HMAC verified raw-body webhook, idempotency, amount check, no client-supplied status |
| Errors | no stack traces/internals in responses |
| Secrets | environment variables only; the app refuses development secrets when `WAYFARER_PROD=true` |
| Audit | `audit_logs` for bookings, payments, admin and inventory changes |

## Open items
- `CORS_ORIGINS` defaults to `*` for local development; restrict it to the web origin in production.
- No email delivery, so password reset returns a demo token only outside production (disabled in production). OTP and email verification are not implemented.
- The WebSocket registry is in-memory (single instance).
- Access tokens are bearer tokens in storage; web uses secure-storage's browser fallback, which is weaker than mobile keystores.
- A database password for the retired hosted demo was shared in chat earlier and must be treated as compromised: rotate it at the provider and retire that deployment.
- No dependency scanning or pen-test has been run.
