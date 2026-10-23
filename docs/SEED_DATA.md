# Seed data

Flyway loads `backend/src/main/resources/db/seed/V100__seed_catalogue.sql` when the `db/seed` location is enabled (the default for local development; production uses `FLYWAY_LOCATIONS=classpath:db/migration`). It was exported from the reference dataset, keeps the original ids, and is not idempotent: Flyway runs it once.

| Entity | Count |
|---|---|
| Destinations | 30 |
| Destination photos / related links | 236 / 66 |
| Accommodations / room types | 76 / 152 |
| Accommodation photos / amenity links | 304 / 621 |
| Attractions, activities and restaurants | 373 |
| Curated itineraries (templates) | 44 (354 stops) |
| Reviews | 318 (flagged demo) |
| Travel documents / search chunks | 41 / 47 |
| Currencies / amenities | 10 / 15 |
| Users | 20 demo accounts (1 admin, 2 staff, 3 partner, 14 customer) |

Demo accounts use the `DEMO_PASSWORD` environment variable (development default in `application.yml`). Nightly inventory is not seeded: `InventoryService` creates a rolling 180-day window at startup and daily.

**Provenance.** Landmarks are real places with approximate coordinates; prices and hours are indicative (`hours_verified=false`). Hotels, restaurants and reviews are fictional educational data (`is_demo=true`). Photos are bundled in the app (`app/assets/img`), sourced from Wikipedia/Wikimedia Commons lead images with the source page recorded; hotel and restaurant photos are illustrative and say so.

**Not in the seed.** Bookings, payments and notifications are created by use. The one-off scripts that harvested and curated the photos belonged to the retired TypeScript backend; their output (the bundled images and the URLs in this seed) is what remains.
