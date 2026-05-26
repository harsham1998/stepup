-- Ensure user_id has a unique constraint so upsert onConflict:'user_id' works.
-- Safe to run if constraint already exists.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
    WHERE conrelid = 'user_levels'::regclass
      AND contype IN ('p', 'u')
      AND conkey = ARRAY(
        SELECT attnum FROM pg_attribute
        WHERE attrelid = 'user_levels'::regclass AND attname = 'user_id'
      )
  ) THEN
    ALTER TABLE user_levels ADD CONSTRAINT user_levels_user_id_unique UNIQUE (user_id);
  END IF;
END $$;
