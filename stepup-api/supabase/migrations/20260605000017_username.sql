-- stepup-api/supabase/migrations/20260605000017_username.sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS username text;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'users_username_unique'
  ) THEN
    ALTER TABLE users ADD CONSTRAINT users_username_unique UNIQUE (username);
  END IF;
END
$$;

CREATE INDEX IF NOT EXISTS idx_users_username ON users (lower(username));
