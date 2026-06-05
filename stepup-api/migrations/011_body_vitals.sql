-- migrations/011_body_vitals.sql

-- Daily vitals entries (one row per user per day, upserted)
CREATE TABLE IF NOT EXISTS body_vitals_entries (
  id                  uuid        PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id             uuid        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date                date        NOT NULL DEFAULT CURRENT_DATE,
  weight_kg           numeric(5,2),
  bmi                 numeric(4,1),
  visceral_fat_level  smallint,
  muscle_percentage   numeric(4,1),
  created_at          timestamptz NOT NULL DEFAULT now(),
  updated_at          timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, date)
);
CREATE INDEX IF NOT EXISTS idx_bve_user_date ON body_vitals_entries(user_id, date DESC);

-- User body goals (one row per user, upserted)
CREATE TABLE IF NOT EXISTS body_vitals_goals (
  user_id           uuid        PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  goal_weight_kg    numeric(5,2),
  goal_bmi          numeric(4,1),
  updated_at        timestamptz NOT NULL DEFAULT now()
);

-- Track whether XP was awarded for a given date (prevents duplicate awards)
CREATE TABLE IF NOT EXISTS body_vitals_xp_log (
  user_id   uuid  NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date      date  NOT NULL,
  PRIMARY KEY (user_id, date)
);
