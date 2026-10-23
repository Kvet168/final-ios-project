# REST API reference

Base URL (local): `http://localhost:8081` · Interactive docs: `/api/docs` (Swagger UI) · OpenAPI JSON: `/api/openapi`

**Conventions**

* JSON in and out. Money is a number in USD. Dates are `YYYY-MM-DD`, timestamps are ISO-8601 UTC.
* Auth: `Authorization: Bearer <accessToken>` (JWT, 15 min). Refresh tokens are opaque, single-use, rotated.
* Every error has the same shape: `{"error":{"code":"STRING","message":"...","details":[...]}}`.
* Auth column: **Public** = no token, **User** = any signed-in user, **Staff** = role staff or admin, **Admin** = role admin.

**Common errors (any endpoint that needs a token)**

| Status | `code` | When |
|---|---|---|
| 401 | `UNAUTHENTICATED` | no token |
| 401 | `TOKEN_EXPIRED` | access token expired, call `/api/auth/refresh` |
| 401 | `INVALID_TOKEN` | tampered, unknown user, or logged out |
| 403 | `FORBIDDEN` | role is not allowed |
| 422 | `VALIDATION_ERROR` | body/params invalid (`details` lists `path` + `message`) |
| 429 | `RATE_LIMITED` | more than 30 `POST /api/auth/*` per 15 min per IP |

## Auth

| Method | URL | Auth | Request body | Success | Errors |
|---|---|---|---|---|---|
| POST | `/api/auth/register` | Public | `{email, password (10+ chars, letter+digit), name, phone?}` | **201** `{user, accessToken, refreshToken, expiresIn, tokenType}` | 409 `EMAIL_TAKEN`, 422 |
| POST | `/api/auth/login` | Public | `{email, password}` | **200** same as register | 401 `INVALID_CREDENTIALS` (same message for unknown email and wrong password) |
| POST | `/api/auth/refresh` | Public | `{refreshToken}` | **200** `{accessToken, refreshToken, expiresIn, tokenType}` (old token is revoked) | 401 `INVALID_REFRESH`, 401 `REFRESH_REUSED` (re-use of a rotated token revokes the whole token family) |
| POST | `/api/auth/logout` | Public (send Bearer too) | `{refreshToken}` | **204** refresh token revoked; access token denylisted in Redis | 422 |
| POST | `/api/auth/forgot-password` | Public | `{email}` | **200** `{message, demoResetToken?}` (token returned only when `WAYFARER_PROD=false`) | 422 |
| POST | `/api/auth/reset-password` | Public | `{token, password}` | **200** `{message}`; all refresh tokens revoked | 400 `INVALID_RESET_TOKEN` |

## Users

| Method | URL | Auth | Request body | Success | Errors |
|---|---|---|---|---|---|
| GET | `/api/users/me` | User | none | **200** `{id,email,name,phone,role,preferredCurrency,isDemo,createdAt}` | 401 |
| PATCH | `/api/users/me` | User | `{name?, phone?, preferredCurrency?}` | **200** user | 422 unsupported currency |
| POST | `/api/users/me/delete` | User | `{password}` | **204** soft delete + anonymise | 403 `INVALID_CREDENTIALS`, 409 `ACTIVE_BOOKINGS` |

## Catalogue (public, cached in Redis for 5 min)

| Method | URL | Query | Success |
|---|---|---|---|
| GET | `/api/meta` | | **200** `{currencies, amenities, destinations, notice}` |
| GET | `/api/destinations` | `q, country, tag, international, featured, sort(popularity\|name\|budget_asc\|budget_desc), page, pageSize` | **200** `{items, page, pageSize, total, totalPages}` |
| GET | `/api/destinations/{idOrSlug}` | | **200** destination + images, related, top attractions/accommodations. **404** `NOT_FOUND` |
| GET | `/api/accommodations` | `destination, q, checkIn, checkOut, adults, children, rooms, minPrice, maxPrice, stars, type, amenities, minRating, freeCancellation, breakfast, familyFriendly, lat, lng, maxDistanceKm, sort(relevance\|price_asc\|price_desc\|rating\|distance), page, pageSize` | **200** paged list with `price_from`, `total_for_stay_usd`. **422** `INVALID_DATES`, `MISSING_LOCATION` |
| GET | `/api/accommodations/{idOrSlug}` | `checkIn, checkOut, rooms` | **200** property + images, amenities, room types (each with a `quote` when dates are given). **404** |
| GET | `/api/accommodations/{idOrSlug}/availability` | `checkIn, checkOut, rooms` (required dates) | **200** `{results:[{roomTypeId, available, nightly, total_usd, ...}]}` |
| GET | `/api/room-types/{id}` | `checkIn, checkOut, rooms` | **200** room type (+ quote). **404** |

## Bookings (the "orders" resource)

| Method | URL | Auth | Request body | Success | Errors |
|---|---|---|---|---|---|
| POST | `/api/bookings/quote` | User | `{roomTypeId, checkIn, checkOut, rooms?}` | **200** `{available, nights, nightly, subtotal_usd, taxes_usd, fees_usd, total_usd, ...}` | 404 room, 422 `INVALID_DATES` |
| POST | `/api/bookings` | User | `{roomTypeId, checkIn, checkOut, rooms?, adults, children?, guestName, guestEmail, guestPhone?, specialRequests?}` | **201** booking, status `PENDING_CONFIRMATION`, room held for 30 min | 409 `NO_AVAILABILITY`, 422 `CAPACITY_EXCEEDED` / `INVALID_DATES` |
| GET | `/api/bookings` | User | `?status=` | **200** `{items:[...]}` own bookings, newest first | |
| GET | `/api/bookings/{id}` | User | | **200** booking + `nights_detail`, `events`, `payments`, `cancellable`, `freeCancellation` | 404 (also when it belongs to someone else) |
| POST | `/api/bookings/{id}/cancel` | User | none | **200** `{booking, refunded}` | 404, 409 `NOT_CANCELLABLE` |
| GET | `/api/bookings/{id}/receipt` | User | | **200** receipt | 409 `NO_PAYMENT` |

Status lifecycle: `PENDING_CONFIRMATION → CONFIRMED → CHECKED_IN → COMPLETED`; `PENDING_CONFIRMATION → EXPIRED`; `CONFIRMED|PENDING_CONFIRMATION → CANCELLED → REFUND_PENDING → REFUNDED`.

## Orders (course naming; same service and rules as bookings)

| Method | URL | Auth | Request body | Success | Errors |
|---|---|---|---|---|---|
| GET | `/api/orders` | User | `?status=` | **200** `{items}` own orders | 401 |
| POST | `/api/orders` | User | same as `POST /api/bookings` | **201** order, status `PENDING_CONFIRMATION` | 409 `NO_AVAILABILITY`, 422 |
| GET | `/api/orders/{id}` | User (owner) or Staff | | **200** order detail | 404 |
| PATCH | `/api/orders/{id}/status` | Owner (only `CANCELLED`) or **Staff** (any legal move) | `{status, note?}` | **200** `{id, status}` | 403 `FORBIDDEN`, 404, 409 `ILLEGAL_TRANSITION` / `NOT_CANCELLABLE` |
| DELETE | `/api/orders/{id}` | Owner or Staff | none | **200** `{booking, refunded}`. This is a cancel: rooms are released, refund if inside the free window, the record is kept for audit | 404, 409 `NOT_CANCELLABLE` |

## Payments (simulated provider)

| Method | URL | Auth | Request body | Success | Errors |
|---|---|---|---|---|---|
| POST | `/api/payments/intent` | User | `{bookingId, idempotencyKey (8+ chars)}` | **201** payment `PENDING`. Same key returns the same payment | 404, 409 `BOOKING_NOT_PAYABLE`, 409 `IDEMPOTENCY_KEY_REUSED` |
| GET | `/api/payments/{id}` | User | | **200** payment + events | 404 |
| POST | `/api/payments/{id}/simulate` | User | `{outcome: success\|fail\|cancel}` | **200** `{duplicate, status, payment}`; goes through the same code as the webhook | 403 `SIMULATION_DISABLED` outside mock mode |
| POST | `/api/payments/webhook` | Public, **HMAC** | raw JSON `{id, type, payment_ref, amount_usd, reason?}` + header `X-Wayfarer-Signature` = hex HMAC-SHA256 of the raw body | **200** `{received, duplicate, status}`. Duplicate event ids are ignored | 401 `INVALID_SIGNATURE`, 404 |

## Notifications

| Method | URL | Auth | Success |
|---|---|---|---|
| GET | `/api/notifications` | User | **200** `{items, unread}` |
| PATCH | `/api/notifications/{id}/read` | User | **204**; 404 if not yours |
| POST | `/api/notifications/read-all` | User | **204** |

## Admin (role-based authorization)

URL prefix `/api/admin/**` requires **staff or admin** (enforced in the security filter chain). Role changes additionally require **admin** (`@PreAuthorize`).

| Method | URL | Auth | Notes |
|---|---|---|---|
| GET | `/api/admin/overview` | Staff | counts and paid total |
| GET | `/api/admin/users?q=&page=&pageSize=` | Staff | |
| PATCH | `/api/admin/users/{id}/role` | **Admin** | body `{role}`; revokes the user's refresh tokens; 409 `SELF_ROLE_CHANGE`; audited |
| GET | `/api/admin/bookings?status=` | Staff | |
| GET | `/api/admin/bookings/{id}` | Staff | any booking |
| POST | `/api/admin/bookings/{id}/cancel` | Staff | same rules as customer cancel, as staff |
| POST | `/api/admin/bookings/{id}/transition` | Staff | body `{to, note?}`; illegal moves return 409 `ILLEGAL_TRANSITION`; `CANCELLED` must use `/cancel` |
| GET | `/api/admin/payments` | Staff | |
| GET | `/api/admin/audit-logs?entity=` | Staff | |

### Partner accounts and the read-only hotel catalogue (admin)

| Method | URL | Auth | Notes |
|---|---|---|---|
| GET | `/api/admin/partners?q=` | Staff | paged list: business, owner login, counts of properties/rooms/bookings, QR set up, first sign-in done |
| GET | `/api/admin/partners/{id}` | Staff | detail with the partner's properties (read-only) |
| POST | `/api/admin/partners` | **Admin** | `{businessName, ownerName, email, phone?}` -> **201** with `temporaryPassword` (shown once); 409 `EMAIL_TAKEN` |
| POST | `/api/admin/partners/{id}/reset-password` | **Admin** | new one-time temporary password; the partner is signed out everywhere |
| GET | `/api/admin/hotels?q=&type=&partnerId=` | Staff | every property with its partner, price and room count. **There are no admin writes for hotels, rooms, prices or stock.** |
| POST | `/api/auth/change-password` | signed in | `{currentPassword, newPassword}`; returns fresh tokens; clears the first-sign-in requirement |
| POST | `/api/media` | Partner, Staff, Admin | multipart `file` (PNG/JPEG/WebP, max 2 MB) -> `{id, url}`; 422 `UNSUPPORTED_IMAGE`, 413 |
| GET | `/api/media/{id}` | public | the image, cached |

### Partner: properties, rooms, photos, QR payments (partner role only)

| Method | URL | Notes |
|---|---|---|
| GET/PUT | `/api/partner/profile` | business name, phone and QR payment settings `{qrMediaId, accountName, bank, note}` (account name required with a QR) |
| GET | `/api/partner/accommodations` | own properties with rooms and photos |
| POST | `/api/partner/accommodations` | create a property (`type` hotel, resort, **bungalow**, hostel, guesthouse, boutique, villa, apartment) with `rooms[]`, `coverImage` |
| PATCH / DELETE | `/api/partner/accommodations/{id}` | edit; delete is refused with 409 `HAS_ACTIVE_BOOKINGS` while bookings are pending, confirmed or in house |
| POST | `/api/partner/accommodations/{id}/rooms` | add a room type |
| POST / DELETE | `/api/partner/accommodations/{id}/images[/{imageId}]` | gallery |
| PATCH / DELETE | `/api/partner/room-types/{id}` | edit (price, count, photo...) / delete (409 `HAS_ACTIVE_BOOKINGS`, 409 `LAST_ROOM`) |
| PUT | `/api/partner/room-types/{id}/inventory` | stock and price for a date range |
| GET | `/api/partner/payments?method=qr&status=` | QR payments (those the guest has claimed come first) |
| POST | `/api/partner/payments/{id}/confirm` · `/reject` | confirm the money arrived (booking -> CONFIRMED) or reject with a reason |

Guest side of QR: `GET /api/bookings/{id}/pay-qr`, `POST /api/payments/intent` with `"method":"qr"` (409 `QR_NOT_AVAILABLE` until the partner sets a QR), `POST /api/payments/{id}/claim`.

### Removed: admin hotel writes

Earlier versions let staff and admin create, edit and delete hotels and change room prices and stock. That moved to the owning partner (`/api/partner/**`); the old `/api/admin/accommodations*` and `/api/admin/room-types*` write endpoints no longer exist.

## Web dashboards (not API)

`GET /admin` and `GET /partner` serve the Admin console and Partner dashboard (static files from the same server). They call the endpoints above with the user's bearer token.

## WebSocket (live booking updates)

`ws://localhost:8081/ws` with header `Authorization: Bearer <accessToken>` on the upgrade request (unauthenticated upgrades get 401).
Each user only receives their own events, sent after the database transaction has committed.

```json
{"type":"connected","data":{"userId":"..."}}
{"type":"booking.status","data":{"bookingId":"...","reference":"WF-...","from":"PENDING_CONFIRMATION","to":"CONFIRMED"}}
{"type":"notification","data":{"type":"payment","title":"Payment received","body":"...","data":{"bookingId":"..."}}}
```

iOS client sketch: `var req = URLRequest(url: URL(string: "ws://localhost:8081/ws")!); req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization"); let task = URLSession.shared.webSocketTask(with: req); task.resume()` then loop on `task.receive()`.
