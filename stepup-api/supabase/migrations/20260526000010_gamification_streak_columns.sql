-- Task 6: Add streak tracking columns to users table
ALTER TABLE users ADD COLUMN IF NOT EXISTS best_streak_days INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_break_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS partial_day_count INT DEFAULT 0;

-- Backfill best_streak_days from current streak_days for existing users
UPDATE users SET best_streak_days = streak_days WHERE best_streak_days = 0 AND streak_days > 0;
