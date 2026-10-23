# Database design (PostgreSQL 16)

Normalized relational schema (3NF). Created by Flyway: `V1__schema.sql` (tables), `V2__integrity_and_audit.sql`
(triggers + extra indexes), `seed/V100__sample_data.sql` (demo data, dev only). A full `pg_dump` is in [`../sql/schema.sql`](../sql/schema.sql).

## ERD (core tables used by the REST API)

```mermaid
erDiagram
  users ||--o{ refresh_tokens : "issued to"
  users ||--o{ password_resets : requests
  users ||--o{ bookings : places
  users ||--o{ payments : pays
  users ||--o{ notifications : receives
  users ||--o{ audit_logs : "acts in"
  users ||--o{ reviews : writes
  users ||--o| partners : "is"
  partners ||--o{ accommodations : owns
  destinations ||--o{ accommodations : contains
  destinations ||--o{ attractions : contains
  destinations }o--o{ destinations : related_destinations
  accommodations ||--o{ room_types : has
  accommodations }o--o{ amenities : accommodation_amenities
  accommodations ||--o{ reviews : receives
  room_types ||--o{ room_inventory : "one row per night"
  room_types ||--o{ bookings : reserved
  accommodations ||--o{ bookings : receives
  bookings ||--o{ booking_items : "nightly rate snapshot"
  bookings ||--o{ booking_status_events : "state history"
  bookings ||--o{ payments : "paid by"
  payments ||--o{ payment_events : "provider events"
  currencies ||--o{ users : preferred
  currencies ||--o{ destinations : priced_in

  users {
    uuid id PK
    text email "unique (case-insensitive, active rows)"
    text password_hash "bcrypt"
    text name
    text role "customer|partner|staff|admin"
    char3 preferred_currency FK
    timestamptz deleted_at "soft delete"
    timestamptz created_at
    timestamptz updated_at "trigger"
  }
  refresh_tokens {
    uuid id PK
    uuid user_id FK
    uuid family_id "rotation chain"
    text token_hash UK "SHA-256, never the raw token"
    timestamptz expires_at
    timestamptz revoked_at
  }
  room_inventory {
    uuid room_type_id PK,FK
    date night PK
    int units_available "CHECK >= 0"
    numeric price_usd "CHECK > 0"
  }
  bookings {
    uuid id PK
    text reference UK
    uuid user_id FK
    uuid accommodation_id FK
    uuid room_type_id FK
    date check_in
    date check_out "CHECK > check_in"
    text status "9-state machine, CHECK"
    numeric total_usd
    timestamptz hold_expires_at
    timestamptz created_at
    timestamptz updated_at "trigger"
  }
  booking_items {
    uuid booking_id PK,FK
    date night PK
    numeric rate_usd
    int rooms
    boolean released
  }
  booking_status_events {
    bigint id PK
    uuid booking_id FK
    text from_status
    text to_status
    uuid actor_id FK
    timestamptz created_at
  }
  payments {
    uuid id PK
    uuid booking_id FK
    uuid user_id FK
    numeric amount_usd "CHECK > 0"
    text status
    text provider_ref UK
    text idempotency_key UK
    boolean simulated
  }
  payment_events {
    bigint id PK
    uuid payment_id FK
    text provider_event_id UK "webhook de-duplication"
    jsonb payload
  }
  audit_logs {
    bigint id PK
    uuid actor_id FK
    text action
    text entity
    text entity_id
    jsonb meta
    timestamptz created_at
  }
```

The remaining tables (`itineraries`, `itinerary_items`, `wishlist_items`, `travel_documents`, `document_chunks`, `ai_*`,
`search_history`, `exchange_rate_snapshots`) belong to the AI planner and personalisation features of the Express backend.
They are part of the shared schema but are not used by the Spring Boot API.

## How each requirement is met

| Requirement | Where |
|---|---|
| Primary keys | Every table: `uuid` (`gen_random_uuid()`), `bigserial` for append-only logs, composite keys for link/snapshot tables (`room_inventory`, `booking_items`, `accommodation_amenities`) |
| Foreign keys | 73 FK constraints; `ON DELETE CASCADE` only for owned children (tokens, images, items), plain `RESTRICT` for financial records (bookings, payments) |
| Constraints | 43 CHECKs (e.g. `check_out > check_in`, `units_available >= 0`, status/role enums, lat/lng ranges, `amount_usd > 0`), `UNIQUE` on slugs, references, provider refs, idempotency keys, token hashes |
| Indexes | 40 indexes: partial unique `users(lower(email)) WHERE deleted_at IS NULL`, `bookings(user_id, created_at DESC)`, `bookings(hold_expires_at) WHERE status='PENDING_CONFIRMATION'`, `room_inventory(night)`, GIN on `document_chunks.tsv`, and others in V1/V2 |
| Transactions | Booking creation locks inventory rows `FOR UPDATE`, decrements stock, inserts booking + items + event + notification + audit row in **one** transaction. Payment webhooks lock the payment and booking rows. Verified under load: 12 concurrent requests for 3 rooms produced exactly 3 bookings |
| Audit records | `audit_logs` (app-level: register, login-related changes, booking/payment events, admin actions) + `booking_status_events` (full state history) + DB trigger `users_audit_role` that logs any role change, even from raw SQL |
| Created/updated timestamps | `created_at` on every table; `updated_at` maintained by the `set_updated_at()` trigger on users, destinations, accommodations, attractions, bookings, payments |
| Appropriate relationships | 1-N (destination to accommodations), N-M (accommodations to amenities, destinations to related destinations), 1-N snapshot (booking to nightly rates), self-reference (`related_destinations`) |
| Soft deletion | `deleted_at` on users, destinations, accommodations, attractions, room_types. Account deletion anonymises PII but keeps bookings/payments for financial records |

## Money and inventory design notes

* All money is `numeric(12,2)` USD; display currency is converted at the edge (`currencies.per_usd`). No floats.
* `room_inventory` has one row **per room type per night**. A missing row means "not sellable". `InventoryService` keeps a rolling 180-day window filled.
* `booking_items` snapshots the nightly rate and `released` flag, so cancelling or expiring a booking returns exactly the stock that was taken, once.
