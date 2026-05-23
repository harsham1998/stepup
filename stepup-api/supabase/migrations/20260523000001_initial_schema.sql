-- Users
CREATE TABLE IF NOT EXISTS users (
  id           uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone        text UNIQUE,
  name         text NOT NULL DEFAULT '',
  city         text NOT NULL DEFAULT '',
  language     text NOT NULL DEFAULT 'english'
                    CHECK (language IN ('english','hindi','telugu','tamil','kannada')),
  goal_tier    text NOT NULL DEFAULT 'active'
                    CHECK (goal_tier IN ('casual','active','champion','elite')),
  xp           int  NOT NULL DEFAULT 0,
  streak_days  int  NOT NULL DEFAULT 0,
  league       text NOT NULL DEFAULT 'bronze'
                    CHECK (league IN ('bronze','silver','gold','elite')),
  avatar_url   text,
  kyc_verified boolean NOT NULL DEFAULT false,
  fcm_token    text,
  is_admin     boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- Step data
CREATE TABLE IF NOT EXISTS step_logs (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  steps        int  NOT NULL CHECK (steps >= 0),
  synced_at    timestamptz NOT NULL,
  source       text NOT NULL CHECK (source IN ('healthkit','health_connect','manual')),
  device_model text NOT NULL DEFAULT '',
  os_version   text NOT NULL DEFAULT '',
  flagged      boolean NOT NULL DEFAULT false
);
CREATE INDEX IF NOT EXISTS idx_step_logs_user_synced ON step_logs(user_id, synced_at DESC);

CREATE TABLE IF NOT EXISTS user_daily_steps (
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date        date NOT NULL,
  total_steps int  NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, date)
);

-- Challenges
CREATE TABLE IF NOT EXISTS challenges (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title               text NOT NULL,
  type                text NOT NULL
                           CHECK (type IN ('free_daily','free_weekly','paid_pool','sponsored','team','city')),
  step_goal           int  NOT NULL,
  entry_fee           int  NOT NULL DEFAULT 0,
  prize_pool          int  NOT NULL DEFAULT 0,
  max_participants    int,
  start_time          timestamptz NOT NULL,
  end_time            timestamptz NOT NULL,
  status              text NOT NULL DEFAULT 'upcoming'
                           CHECK (status IN ('upcoming','active','ended','paid_out','cancelled')),
  prize_distribution  jsonb NOT NULL DEFAULT '{"platform_fee_percent":10,"tiers":[{"top_percent":10,"share_percent":90}]}'::jsonb,
  created_by          uuid REFERENCES users(id),
  sponsor_name        text,
  created_at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_challenges_status ON challenges(status);
CREATE INDEX IF NOT EXISTS idx_challenges_end_time ON challenges(end_time);

CREATE TABLE IF NOT EXISTS challenge_participants (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at    timestamptz NOT NULL DEFAULT now(),
  final_rank   int,
  payout_amount int,
  UNIQUE (challenge_id, user_id)
);
CREATE INDEX IF NOT EXISTS idx_cp_challenge ON challenge_participants(challenge_id);
CREATE INDEX IF NOT EXISTS idx_cp_user ON challenge_participants(user_id);

-- Wallet
CREATE TABLE IF NOT EXISTS wallet_transactions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type             text NOT NULL CHECK (type IN ('credit','debit','fee','refund','withdrawal')),
  amount           int  NOT NULL CHECK (amount > 0),
  idempotency_key  text NOT NULL UNIQUE,
  reference_id     text,
  description      text NOT NULL,
  status           text NOT NULL DEFAULT 'completed'
                        CHECK (status IN ('completed','pending_approval','processing','rejected')),
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_wallet_txn_user ON wallet_transactions(user_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_wallet_txn_status ON wallet_transactions(status) WHERE status = 'pending_approval';

-- Leaderboard snapshots
CREATE TABLE IF NOT EXISTS leaderboard_snapshots (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  scope       text NOT NULL CHECK (scope IN ('global','city','challenge')),
  scope_id    text NOT NULL DEFAULT 'global',
  rank        int  NOT NULL,
  steps       int  NOT NULL,
  snapped_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_lb_snap_user ON leaderboard_snapshots(user_id, snapped_at DESC);

-- Anti-cheat
CREATE TABLE IF NOT EXISTS step_flags (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  step_log_id  uuid NOT NULL REFERENCES step_logs(id) ON DELETE CASCADE,
  reason       text NOT NULL,
  reviewed     boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- Social
CREATE TABLE IF NOT EXISTS friendships (
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id  uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, friend_id),
  CHECK (user_id <> friend_id)
);

-- Gamification
CREATE TABLE IF NOT EXISTS user_badges (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge_slug text NOT NULL,
  earned_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, badge_slug)
);
