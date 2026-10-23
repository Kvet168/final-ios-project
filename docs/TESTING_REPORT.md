# Testing report

## Backend (Spring Boot)
`cd backend && mvn verify` -> **36 unit tests, all passing**: booking state machine, JWT (round trip, tampering, wrong key, expiry), webhook HMAC, password rules, stay date rules, the request parser (including the brief's "three days in Phnom Penh and $150"), the day scheduler (no repeated stops, ordered and non-overlapping, opening hours, pace, interests, proximity, costs), query expansion, text/geo helpers.

`backend/scripts/smoke.sh` -> **202 end-to-end checks against the running API** (the Docker image with PostgreSQL 16 + Redis 7, full seed): public catalogue, hotel/room/attraction/restaurant search, register/login/refresh rotation and reuse detection, password reset, role enforcement for customer/staff/admin/partner, booking, idempotent payment, signed-webhook rejection, receipts, partner check-in, reviews (stay required, one per guest, moderation), cancellation and the `/orders` alias, wishlist, AI planner and assistant (including "needs more info" and refusing to guess), itineraries (edit, regenerate, recalculate, copy, ownership), admin content management the administrator being read-only on hotels, rooms, prices and stock; admin creating a partner account, temporary password and forced change; partner image upload (text and SVG refused, other partners' images refused) and creating a bungalow with room images; partner room and property edits, deletes and their safeguards; the full QR payment flow (set up, claim, confirm, reject, switch to card), dashboard hosting, and logout (access token denied through Redis).

The Admin and Partner web dashboards were exercised in a browser: sign-in, a customer being refused, every page loading real data, an admin creating a partner account, that partner's forced password change, creating a bungalow with real file uploads, saving a QR code, the admin's read-only view of it, reload while signed in, and the mobile layout. The mobile app's checkout does not yet offer the QR option (API only). There are no automated browser tests.

Also checked by hand: 12 concurrent bookings for a 3-unit room produced exactly 3 bookings (no overselling); WebSocket handshake rejects missing tokens and delivers `booking.status` and `notification` events; Redis outage degrades gracefully.

Migration parity: the old Express implementation and this one were run against the same database and 29 read endpoints (public, authenticated, admin, partner, AI) were compared field by field. Plans and assistant answers were identical; the only differences are extra fields on the Spring side.

## Flutter
`cd app && flutter test` -> 13 widget tests pass. Three screenshot-test files fail in setup because the harness hardcodes a Windows Flutter path (`C:/dev/flutter`); this predates the backend change. `flutter analyze` -> no errors (4 info-level lints). The iOS Simulator build was run against the API.

## Not tested
LLM mode (no key available), a real payment provider, load testing, screen-reader behaviour, physical devices, the Flutter-to-API flow driven fully through the UI for every screen.
