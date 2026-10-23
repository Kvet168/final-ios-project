# Database schema

Source of truth: Flyway migrations in [`backend/src/main/resources/db/migration`](../backend/src/main/resources/db/migration) (`V1__schema.sql` tables, `V2__integrity_and_audit.sql` triggers and extra indexes). A full `pg_dump` is [`backend/sql/schema.sql`](../backend/sql/schema.sql); the ERD with the requirement mapping is [`backend/docs/ERD.md`](../backend/docs/ERD.md).

Key decisions
- **Money** is `numeric(12,2)` in USD. Display currency uses `currencies.per_usd` (documented sample rates, `exchange_rate_snapshots` keeps history).
- **Inventory**: `room_inventory(room_type_id, night)` with `units_available >= 0` CHECK. Booking locks the affected rows (`SELECT ... FOR UPDATE`) and decrements them in the same transaction; a missing row means "not sellable".
- **Snapshots**: `booking_items` stores nightly rates; `bookings` stores policy text, taxes and fees at booking time.
- **Idempotency**: `payments.idempotency_key` and `payment_events.provider_event_id` are UNIQUE.
- **Integrity**: foreign keys, CHECK constraints on enums/ranges, partial unique index on active user emails, soft delete (`deleted_at`) on users/destinations/accommodations/attractions/room types, `updated_at` maintained by trigger.
- **Audit**: `audit_logs`, `booking_status_events`, and a trigger that records every role change.
- **Search**: indexes on destination, price, night; `document_chunks.tsv` GIN index for retrieval.
- Tables not created on purpose: separate wishlist/saved-destination tables (one `wishlist_items`), `itinerary_days` (day index on items), `payment_refunds` (refund fields on `payments` + events), `user_roles`/`roles` (single role column).

Backup/recovery: `pg_dump` (or the managed database's point-in-time restore). Migrations never DROP.
