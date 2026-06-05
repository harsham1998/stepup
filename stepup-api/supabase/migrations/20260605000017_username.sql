-- stepup-api/supabase/migrations/20260605000017_username.sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS username text;
ALTER TABLE users ADD CONSTRAINT users_username_unique UNIQUE (username);
CREATE INDEX IF NOT EXISTS idx_users_username ON users (lower(username));
