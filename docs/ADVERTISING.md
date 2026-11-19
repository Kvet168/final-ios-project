# Advertising and sponsored listings

Local businesses (hotels, resorts, restaurants, cafés, camping sites, tour operators, shops) pay to be more visible in the app. It runs on the existing Spring Boot API and PostgreSQL database: no new service, queue or third-party dependency.

## Packages (all editable by an administrator)

| Package | Placement in the app | Default price | One unit runs |
|---|---|---|---|
| Featured Destination | Explore, and the page of each targeted destination | $10 / week | 7 days |
| Top Search Placement | Up to 2 results above organic stay search results, only when the search matches | $15 / week | 7 days |
| Homepage Banner | Rotating banner on the home screen | $30 / week | 7 days |
| Sponsored Travel Article | "Sponsored stories" on the home screen, opens a full article | $20 / post | 30 days |
| Festival Campaign | "Festival and holiday offers" strip on the home screen | $100 / month | 30 days |

Price, days per unit, minimum and maximum units, slots per day and on-sale are columns of `ad_packages` and are edited in **Admin console → Advertising → Packages & pricing**. A campaign's price is fixed when it is created; later price changes do not change campaigns already booked.

## Who does what

- **Business owner** (`/business`, role `business`; hotel partners can use the same pages in `/partner`): register, manage the business profile, choose a package, write the campaign in English and Khmer (image, title, text, offer, link, target destinations, keywords, article or festival name), pick dates, pay, watch impressions / clicks / click rate / spend, renew.
- **Administrator and staff** (`/admin → Advertising`): verify businesses, approve or reject campaigns, pause / resume / cancel / reschedule, see how full each placement is, see revenue and top campaigns. Only the **admin** role can change packages and payment settings or verify payments.
- **Traveller** (Flutter app): sees paid placements, always labelled **Sponsored**. Nothing paid is shown on a plain, unfiltered stay list.

## Campaign life

`draft → pending_review → awaiting_payment → payment_review → scheduled → active → expired`
(`rejected`, `paused`, `cancelled` are the side exits). Approved and paid campaigns become `scheduled`, then `active` on their start date (Cambodia time, `Asia/Phnom_Penh`) and `expired` after the end date. `AdLifecycle` runs every 5 minutes; serving also checks the dates itself, so an ad never shows outside its dates even if the job is late. Unpaid approved campaigns release their slot after 3 days.

Renewing an approved campaign keeps its content and goes straight to payment.

## Fair rotation and capacity

- `slot_capacity` limits how many campaigns of a package can run on the same day. It is checked (under a per-package database lock) when a campaign is submitted, approved, resumed or rescheduled.
- Each request orders live campaigns by the impressions they already received today (least first), random among equals, so every paying business gets a similar share however many are booked.

## Payment and verification

Two methods, two currencies: KHQR or bank transfer, USD or KHR. KHR amounts use the `currencies` rate (`KHR`) and are rounded **up** to the configured step (default 100 ៛).

1. The business picks method and currency. The server creates a payment with a unique reference `WF-AD-XXXXXXXX` and the amount (the client never sends an amount).
2. The business pays using the KHQR image / bank details an administrator saved, includes the reference, then enters the bank's transaction reference (and optionally a screenshot).
3. An **administrator** opens the payment, checks the bank statement, and **types the amount that arrived**. The server accepts it only if it matches the expected amount (USD to the cent, KHR within the rounding step); otherwise `AMOUNT_MISMATCH`.
4. On success the campaign is scheduled. Every step is written to `audit_logs`.

Protections: a bank transaction reference can pay only one campaign (partial unique index), one open payment per campaign, status transitions are checked server-side, links in campaigns must be `https://` or `tel:`, images must be uploaded through the existing validated media endpoint, and roles are enforced by URL rule plus per-record ownership checks.

## Statistics

`ad_stats_daily` keeps one row per campaign per day (upsert), so storage stays tiny. The app sends impressions / clicks in batches of up to 50 (`POST /api/ads/events`, rate-limited per IP); only campaigns that are live today are counted.

## API summary

- Public: `GET /api/ads?placement=&destination=&q=&limit=`, `GET /api/ads/{id}/article`, `POST /api/ads/events`, `POST /api/business/register`
- Business (roles BUSINESS, PARTNER): `/api/business/profile|packages|quote|campaigns|payment-info|payments|analytics`, `POST /campaigns/{id}/submit|cancel|renew|payment`, `POST /payments/{id}/claim`
- Admin (STAFF, ADMIN): `/api/admin/ads/analytics|businesses|campaigns|placements|payments|packages|settings` (writes to packages, settings and payment verification are ADMIN only)

Full request and response shapes are in Swagger UI (`/api/docs`).

## Honest limits

- **KHQR is a static QR image** the administrator uploads, and payments are confirmed by a person comparing the bank statement. Automatic confirmation needs a Bakong / bank merchant API and credentials, which are not part of this project. The `ad_payments` table and the verify endpoint are where such a webhook would plug in.
- Impressions are counted when a card is built on screen, once per campaign per app session; there is no bot or duplicate-click filtering beyond the rate limit.
- Business owners manage campaigns in the web portal (responsive), not inside the traveller app.
- Dashboard texts and package names/descriptions are bilingual (English / Khmer); campaign text is whatever language the business writes in each field. Khmer strings were written by the developer and should be reviewed by a native speaker.
- The demo data (`V107__demo_advertising.sql`, in the seed folder) is for demonstration only. Remove the seed folder from `FLYWAY_LOCATIONS` in production.
