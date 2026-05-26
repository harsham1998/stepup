-- Task 11: Add reputation columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_score INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_updated_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_snapshot_prev INT DEFAULT 0;
