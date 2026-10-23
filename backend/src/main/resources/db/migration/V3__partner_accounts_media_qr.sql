-- Partner-owned properties: more property types, uploaded images, QR payment settings and the QR payment method.

-- 1. Bungalows (and resorts, hostels, ... as before)
ALTER TABLE accommodations DROP CONSTRAINT accommodations_type_check;
ALTER TABLE accommodations ADD CONSTRAINT accommodations_type_check
  CHECK (type IN ('hotel','guesthouse','resort','hostel','boutique','villa','apartment','bungalow'));

-- 2. Uploaded images (property photos, room photos, payment QR codes). Stored in the database so containers stay stateless.
CREATE TABLE media (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id     uuid REFERENCES users(id) ON DELETE SET NULL,
  content_type text NOT NULL CHECK (content_type IN ('image/png','image/jpeg','image/webp')),
  byte_size    int NOT NULL CHECK (byte_size BETWEEN 1 AND 3145728),
  data         bytea NOT NULL,
  created_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX media_owner_idx ON media (owner_id);

-- 3. Partner organisation: contact and QR payment settings (a partner is paid directly by the guest scanning this QR)
ALTER TABLE partners
  ADD COLUMN contact_phone        text,
  ADD COLUMN payment_qr_media_id  uuid REFERENCES media(id) ON DELETE SET NULL,
  ADD COLUMN payment_account_name text,
  ADD COLUMN payment_bank         text,
  ADD COLUMN payment_note         text,
  ADD COLUMN updated_at           timestamptz NOT NULL DEFAULT now();
CREATE UNIQUE INDEX partners_user_uq ON partners (user_id);       -- one organisation per owner account
CREATE TRIGGER partners_set_updated_at BEFORE UPDATE ON partners FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- 4. Rooms get a cover photo
ALTER TABLE room_types ADD COLUMN cover_image text;

-- 5. Payments: card (simulated provider) or QR (guest pays the partner directly, partner confirms receipt)
ALTER TABLE payments
  ADD COLUMN method       text NOT NULL DEFAULT 'card' CHECK (method IN ('card','qr')),
  ADD COLUMN claimed_at   timestamptz,
  ADD COLUMN claim_note   text,
  ADD COLUMN confirmed_by uuid REFERENCES users(id);
CREATE INDEX payments_method_status_idx ON payments (method, status);

-- 6. Accounts created by an administrator must choose their own password on first sign-in
ALTER TABLE users ADD COLUMN must_change_password boolean NOT NULL DEFAULT false;
