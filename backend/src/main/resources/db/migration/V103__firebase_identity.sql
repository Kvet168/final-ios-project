-- Firebase Authentication becomes a third sign-in source next to Google and Apple. The Firebase uid is stored as the subject.
ALTER TABLE user_identities DROP CONSTRAINT IF EXISTS user_identities_provider_check;
ALTER TABLE user_identities ADD CONSTRAINT user_identities_provider_check CHECK (provider IN ('google', 'apple', 'firebase'));
