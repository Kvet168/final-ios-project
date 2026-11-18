-- Advertising & sponsored listings: businesses, configurable packages, campaigns, payments (KHQR / bank transfer), daily stats.

-- 1. New account type for advertisers (hotel partners may advertise too; they keep the 'partner' role).
ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check CHECK (role IN ('customer','partner','staff','admin','business'));

-- 2. Advertiser business profile (one per owner account)
CREATE TABLE businesses (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid NOT NULL REFERENCES users(id),
  partner_id          uuid REFERENCES partners(id) ON DELETE SET NULL,
  name                text NOT NULL,
  name_km             text,
  category            text NOT NULL DEFAULT 'other'
                        CHECK (category IN ('hotel','resort','restaurant','cafe','camping','tour_operator','activity','shop','other')),
  description         text,
  description_km      text,
  phone               text,
  website             text,
  address             text,
  destination_id      uuid REFERENCES destinations(id) ON DELETE SET NULL,
  logo_url            text,
  verification_status text NOT NULL DEFAULT 'pending' CHECK (verification_status IN ('pending','verified','rejected','suspended')),
  verification_note   text,
  verified_at         timestamptz,
  verified_by         uuid REFERENCES users(id),
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now()
);
CREATE UNIQUE INDEX businesses_user_uq ON businesses (user_id);
CREATE INDEX businesses_status_idx ON businesses (verification_status);
CREATE TRIGGER businesses_set_updated_at BEFORE UPDATE ON businesses FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 3. Packages. Price and duration are data, edited by administrators.
--    days_per_unit: how long one purchased unit runs (week = 7, month = 30; an article post runs 'days_per_unit' days).
--    slot_capacity: how many campaigns of this package may run on the same day (placement capacity limit).
CREATE TABLE ad_packages (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code            text NOT NULL UNIQUE,
  placement       text NOT NULL CHECK (placement IN ('featured_destination','top_search','homepage_banner','sponsored_article','festival')),
  name_en         text NOT NULL,
  name_km         text NOT NULL,
  description_en  text NOT NULL DEFAULT '',
  description_km  text NOT NULL DEFAULT '',
  unit            text NOT NULL CHECK (unit IN ('week','post','month')),
  unit_price_usd  numeric(10,2) NOT NULL CHECK (unit_price_usd >= 0),
  days_per_unit   int NOT NULL DEFAULT 7 CHECK (days_per_unit BETWEEN 1 AND 366),
  min_units       int NOT NULL DEFAULT 1 CHECK (min_units >= 1),
  max_units       int NOT NULL DEFAULT 12 CHECK (max_units >= 1),
  slot_capacity   int NOT NULL DEFAULT 5 CHECK (slot_capacity >= 1),
  is_active       boolean NOT NULL DEFAULT true,
  sort_order      int NOT NULL DEFAULT 0,
  updated_at      timestamptz NOT NULL DEFAULT now()
);
CREATE TRIGGER ad_packages_set_updated_at BEFORE UPDATE ON ad_packages FOR EACH ROW EXECUTE FUNCTION set_updated_at();

INSERT INTO ad_packages (code, placement, name_en, name_km, description_en, description_km, unit, unit_price_usd, days_per_unit, min_units, max_units, slot_capacity, sort_order) VALUES
 ('featured_destination', 'featured_destination', 'Featured Destination', 'គោលដៅពិសេស',
  'Your business is highlighted in the Explore and destination pages for the places you choose.',
  'អាជីវកម្មរបស់អ្នកត្រូវបានបង្ហាញនៅទំព័រស្វែងរក និងទំព័រគោលដៅដែលអ្នកជ្រើសរើស។', 'week', 10.00, 7, 1, 12, 8, 1),
 ('top_search', 'top_search', 'Top Search Placement', 'ទីតាំងកំពូលក្នុងការស្វែងរក',
  'Appears above organic results when travellers search for stays and places that match your business.',
  'បង្ហាញនៅខាងលើលទ្ធផលស្វែងរក នៅពេលអ្នកធ្វើដំណើរស្វែងរកអ្វីដែលត្រូវនឹងអាជីវកម្មរបស់អ្នក។', 'week', 15.00, 7, 1, 12, 5, 2),
 ('homepage_banner', 'homepage_banner', 'Homepage Banner', 'បដាទំព័រដើម',
  'A promotional banner on the app home screen, rotated fairly with other banners.',
  'បដាផ្សព្វផ្សាយនៅទំព័រដើមនៃកម្មវិធី ដែលបង្វិលជាមួយបដាផ្សេងៗដោយយុត្តិធម៌។', 'week', 30.00, 7, 1, 12, 4, 3),
 ('sponsored_article', 'sponsored_article', 'Sponsored Travel Article', 'អត្ថបទធ្វើដំណើរឧបត្ថម្ភ',
  'A sponsored travel article about your business, shown in the app and clearly labelled Sponsored.',
  'អត្ថបទធ្វើដំណើរឧបត្ថម្ភអំពីអាជីវកម្មរបស់អ្នក ដែលមានស្លាក «ឧបត្ថម្ភ» ច្បាស់លាស់។', 'post', 20.00, 30, 1, 5, 6, 4),
 ('festival_campaign', 'festival', 'Festival Campaign', 'យុទ្ធនាការពិធីបុណ្យ',
  'A festival or holiday promotion (Khmer New Year, Pchum Ben, Water Festival...) in the special promotions strip.',
  'យុទ្ធនាការពិធីបុណ្យ ឬថ្ងៃឈប់សម្រាក (ចូលឆ្នាំខ្មែរ ភ្ជុំបិណ្ឌ បុណ្យអុំទូក...) នៅក្នុងផ្នែកផ្សព្វផ្សាយពិសេស។', 'month', 100.00, 30, 1, 3, 4, 5);

-- 4. Campaigns
--    status flow: draft -> pending_review -> (rejected | awaiting_payment) -> payment_review -> scheduled -> active -> expired
--                 an administrator can pause / cancel; the business can cancel before payment is verified.
CREATE TABLE ad_campaigns (
  id                    uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  business_id           uuid NOT NULL REFERENCES businesses(id),
  package_id            uuid NOT NULL REFERENCES ad_packages(id),
  placement             text NOT NULL,
  status                text NOT NULL DEFAULT 'draft'
                          CHECK (status IN ('draft','pending_review','rejected','awaiting_payment','payment_review','scheduled','active','paused','expired','cancelled')),
  title_en              text NOT NULL,
  title_km              text,
  body_en               text,
  body_km               text,
  offer_en              text,
  offer_km              text,
  article_en            text,
  article_km            text,
  image_url             text,
  cta_url               text,
  accommodation_id      uuid REFERENCES accommodations(id) ON DELETE SET NULL,
  target_destination_ids uuid[] NOT NULL DEFAULT '{}',        -- empty = all Cambodia
  keywords              text[] NOT NULL DEFAULT '{}',          -- extra words that make a Top Search placement relevant
  festival_name_en      text,
  festival_name_km      text,
  start_date            date NOT NULL,
  end_date              date NOT NULL,
  units                 int NOT NULL CHECK (units >= 1),
  price_usd             numeric(10,2) NOT NULL CHECK (price_usd >= 0),   -- fixed when the campaign is submitted; later price changes do not affect it
  review_note           text,
  reviewed_by           uuid REFERENCES users(id),
  reviewed_at           timestamptz,
  renewed_from          uuid REFERENCES ad_campaigns(id) ON DELETE SET NULL,
  created_at            timestamptz NOT NULL DEFAULT now(),
  updated_at            timestamptz NOT NULL DEFAULT now(),
  CHECK (end_date >= start_date)
);
CREATE INDEX ad_campaigns_business_idx ON ad_campaigns (business_id, created_at DESC);
CREATE INDEX ad_campaigns_serve_idx ON ad_campaigns (placement, status, start_date, end_date);
CREATE INDEX ad_campaigns_package_idx ON ad_campaigns (package_id, status);
CREATE TRIGGER ad_campaigns_set_updated_at BEFORE UPDATE ON ad_campaigns FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 5. Payments for campaigns. Amounts are computed by the server; the business only supplies the method and the bank reference.
CREATE TABLE ad_payments (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  campaign_id     uuid NOT NULL REFERENCES ad_campaigns(id),
  business_id     uuid NOT NULL REFERENCES businesses(id),
  reference       text NOT NULL UNIQUE,                 -- WF-AD-XXXXXXXX: the transfer note the business must include
  method          text NOT NULL CHECK (method IN ('khqr','bank_transfer')),
  currency        char(3) NOT NULL CHECK (currency IN ('USD','KHR')),
  amount_usd      numeric(10,2) NOT NULL CHECK (amount_usd >= 0),
  amount_local    numeric(14,2) NOT NULL CHECK (amount_local >= 0),
  fx_rate         numeric(12,4) NOT NULL,               -- KHR per USD at the time the payment was created
  status          text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','claimed','verified','rejected','cancelled')),
  bank_txn_ref    text,                                 -- the bank's transaction id typed by the business
  proof_url       text,
  claimed_at      timestamptz,
  verified_by     uuid REFERENCES users(id),
  verified_at     timestamptz,
  reject_reason   text,
  created_at      timestamptz NOT NULL DEFAULT now(),
  updated_at      timestamptz NOT NULL DEFAULT now()
);
-- a bank transaction id can pay for one campaign only, so a receipt cannot be replayed against another campaign
CREATE UNIQUE INDEX ad_payments_txn_uq ON ad_payments (lower(bank_txn_ref)) WHERE bank_txn_ref IS NOT NULL AND status IN ('claimed','verified');
-- one open payment per campaign
CREATE UNIQUE INDEX ad_payments_open_uq ON ad_payments (campaign_id) WHERE status IN ('pending','claimed');
CREATE INDEX ad_payments_status_idx ON ad_payments (status, created_at DESC);
CREATE TRIGGER ad_payments_set_updated_at BEFORE UPDATE ON ad_payments FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 6. Daily counters. One row per campaign per day keeps the table small and the writes cheap.
CREATE TABLE ad_stats_daily (
  campaign_id uuid NOT NULL REFERENCES ad_campaigns(id) ON DELETE CASCADE,
  day         date NOT NULL,
  impressions int NOT NULL DEFAULT 0,
  clicks      int NOT NULL DEFAULT 0,
  PRIMARY KEY (campaign_id, day)
);

-- 7. Where businesses send money (managed by administrators)
CREATE TABLE ad_settings (
  key        text PRIMARY KEY,
  value      text NOT NULL DEFAULT '',
  updated_at timestamptz NOT NULL DEFAULT now()
);
INSERT INTO ad_settings (key, value) VALUES
  ('khqr_image_url', ''),
  ('account_name', 'WAYFARER Cambodia'),
  ('bank_name', 'ACLEDA Bank'),
  ('account_number', ''),
  ('transfer_instructions', 'Include the payment reference in the transfer note. Your campaign goes live after we confirm the money has arrived.'),
  ('khr_rounding', '100');
