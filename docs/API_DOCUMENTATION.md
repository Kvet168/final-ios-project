# API documentation

The complete reference (method, URL, authentication, request, response, errors, status codes) is [`backend/docs/API.md`](../backend/docs/API.md).
Interactive docs: `/api/docs` (Swagger UI), machine-readable: `/api/openapi` (generated from the controllers).

**Conventions:** JSON; `Authorization: Bearer <access token>`; errors are `{ "error": { "code", "message", "details?" } }` with 400/401/403/404/409/422/429/500.

| Area | Endpoints |
|---|---|
| Auth | POST `/auth/register`, `/auth/login`, `/auth/refresh`, `/auth/logout`, `/auth/forgot-password`, `/auth/reset-password`; GET/PATCH `/users/me`; POST `/users/me/delete` |
| Discovery | GET `/home`, `/meta`, `/destinations`, `/destinations/{id}`, `/destinations/{id}/attractions`, `/destinations/{id}/accommodations`, `/attractions`, `/attractions/{id}`, `/documents` |
| Stays | GET `/accommodations`, `/accommodations/{id}`, `/accommodations/{id}/availability`, `/room-types/{id}`, `/accommodations/{id}/reviews`; POST reviews |
| Bookings / orders | POST `/bookings/quote`, `/bookings`; GET `/bookings`, `/bookings/{id}`, `/bookings/{id}/receipt`; POST `/bookings/{id}/cancel`; the same resource as `/orders` (GET, POST, GET `{id}`, PATCH `{id}/status`, DELETE `{id}`) |
| Payments | POST `/payments/intent`, `/payments/{id}/simulate` (demo), `/payments/webhook` (HMAC); GET `/payments/{id}` |
| AI | POST `/ai/travel-plan`, `/ai/assistant`, `/ai/recommendations`; GET `/ai/sources`, `/ai/status` |
| Itineraries | POST/GET `/itineraries`; GET/PATCH/DELETE `/itineraries/{id}`; POST `/{id}/generate`, `/{id}/recalculate`, `/{id}/copy` |
| Maps | GET `/locations/search`; POST `/routes/estimate` |
| Account | `/wishlist`, `/search-history`, `/users/me/reviews`, `/notifications` |
| Admin (staff/admin) | `/admin/overview|users|bookings|payments|audit-logs|reviews|ai-usage`, destinations, accommodations, room inventory; role changes and destination delete are admin only |
| Partner | `/partner/accommodations|bookings|analytics`, booking transitions, inventory |
| Live | WebSocket `/ws` (Bearer token on the upgrade request) |

## Example: search
`GET /api/accommodations?destination=phnom-penh&checkIn=2026-11-01&checkOut=2026-11-04&adults=2&maxPrice=60&sort=price_asc`
```json
{ "items": [{ "slug": "riverside-heritage-hotel", "price_from": 22, "total_for_stay_usd": 66, "free_cancel_hours": 24 }],
  "page": 1, "pageSize": 12, "total": 3, "totalPages": 1, "nights": 3 }
```

## Example: booking error
`409 { "error": { "code": "NO_AVAILABILITY", "message": "Not enough rooms left on 2026-11-30. Try different dates or fewer rooms." } }`

## Webhook
`POST /api/payments/webhook` with header `X-Wayfarer-Signature: hex(HMAC_SHA256(PAYMENT_WEBHOOK_SECRET, rawBody))` and body `{ id, type, payment_ref, amount_usd }`. Duplicate `id`s are acknowledged with `duplicate: true` and ignored.
