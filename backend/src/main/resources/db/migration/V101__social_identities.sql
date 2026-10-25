-- Links a WAYFARER user to an identity at an external sign-in provider (Google today, Apple later).
-- Numbered above the seed data (V100) so databases that already ran the seed accept it without out-of-order migrations.
CREATE TABLE user_identities (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  provider   text NOT NULL CHECK (provider IN ('google', 'apple')),
  subject    text NOT NULL,
  email      text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE (provider, subject)
);
CREATE INDEX user_identities_user_ix ON user_identities (user_id);
