-- Create user_levels table for XP / level tracking
CREATE TABLE IF NOT EXISTS user_levels (
  user_id    UUID PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  xp         INT NOT NULL DEFAULT 0,
  level      INT NOT NULL DEFAULT 1,
  title      TEXT NOT NULL DEFAULT 'Walker',
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Backfill from users.xp so existing users don't lose their XP
INSERT INTO user_levels (user_id, xp, level, title)
SELECT id, xp, 1, 'Walker'
FROM users
WHERE xp > 0
ON CONFLICT (user_id) DO NOTHING;
