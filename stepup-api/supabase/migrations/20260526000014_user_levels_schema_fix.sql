-- Ensure user_levels has all required columns regardless of how the table was created
ALTER TABLE user_levels ADD COLUMN IF NOT EXISTS xp         INT NOT NULL DEFAULT 0;
ALTER TABLE user_levels ADD COLUMN IF NOT EXISTS level      INT NOT NULL DEFAULT 1;
ALTER TABLE user_levels ADD COLUMN IF NOT EXISTS title      TEXT NOT NULL DEFAULT 'Walker';
ALTER TABLE user_levels ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Ensure user_id is the primary key (no-op if already set, harmless if not)
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'user_levels'::regclass AND contype = 'p'
  ) THEN
    ALTER TABLE user_levels ADD PRIMARY KEY (user_id);
  END IF;
END $$;

-- Backfill any users with existing XP that have no user_levels row
INSERT INTO user_levels (user_id, xp, level, title)
SELECT id, xp, 1, 'Walker'
FROM users
WHERE xp > 0
ON CONFLICT (user_id) DO NOTHING;
