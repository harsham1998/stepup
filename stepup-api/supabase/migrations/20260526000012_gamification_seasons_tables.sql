-- Task 15: Create seasons and user_season_results tables, seed Season 1
CREATE TABLE IF NOT EXISTS seasons (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  status          TEXT NOT NULL DEFAULT 'upcoming'
                    CHECK (status IN ('upcoming', 'active', 'ended')),
  tier_decay_pct  INT NOT NULL DEFAULT 50
                    CHECK (tier_decay_pct BETWEEN 0 AND 100),
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS user_season_results (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID REFERENCES users(id) ON DELETE CASCADE,
  season_id         UUID REFERENCES seasons(id) ON DELETE CASCADE,
  final_league_slug TEXT NOT NULL,
  final_xp          INT NOT NULL,
  rank_in_tier      INT,
  coins_awarded     INT DEFAULT 0,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, season_id)
);

-- Seed Season 1 (active, 2-month duration)
INSERT INTO seasons (name, start_date, end_date, status, tier_decay_pct)
VALUES ('Season 1: Foundation', '2026-05-26', '2026-07-25', 'active', 50)
ON CONFLICT DO NOTHING;
