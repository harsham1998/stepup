-- migrations/004_full_app_tables.sql

-- Coin balance on users
ALTER TABLE users ADD COLUMN IF NOT EXISTS coin_balance int NOT NULL DEFAULT 0;

-- ============================================================
-- LEAGUES
-- ============================================================
CREATE TABLE IF NOT EXISTS leagues (
  slug        text PRIMARY KEY,
  label       text NOT NULL,
  color_hex   text NOT NULL,
  xp_min      int  NOT NULL DEFAULT 0,
  xp_max      int,
  paid_only   boolean NOT NULL DEFAULT false,
  sort_order  int  NOT NULL
);

CREATE TABLE IF NOT EXISTS user_leagues (
  user_id      uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  league_slug  text NOT NULL REFERENCES leagues(slug),
  xp           int  NOT NULL DEFAULT 0,
  rank_in_tier int,
  season       int  NOT NULL DEFAULT 1,
  updated_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_leagues_slug ON user_leagues(league_slug, xp DESC);

INSERT INTO leagues (slug, label, color_hex, xp_min, xp_max, paid_only, sort_order) VALUES
  ('bronze',   'Bronze',   '#a86a3a',  0,     999,   false, 1),
  ('silver',   'Silver',   '#9aa3ad',  1000,  1999,  false, 2),
  ('gold',     'Gold',     '#d9a93a',  2000,  2999,  false, 3),
  ('platinum', 'Platinum', '#7ed4d4',  3000,  4999,  true,  4),
  ('diamond',  'Diamond',  '#a8c4ff',  5000,  9999,  true,  5),
  ('elite',    'Elite',    '#d4ff3a',  10000, NULL,  true,  6)
ON CONFLICT DO NOTHING;

-- ============================================================
-- MISSIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS missions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        text NOT NULL UNIQUE,
  title       text NOT NULL,
  description text NOT NULL,
  type        text NOT NULL CHECK (type IN ('daily','weekly','seasonal')),
  activity    text NOT NULL DEFAULT 'walk',
  target      int  NOT NULL,
  unit        text NOT NULL DEFAULT 'steps',
  coin_reward int  NOT NULL DEFAULT 0,
  xp_reward   int  NOT NULL DEFAULT 0,
  active      boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS user_missions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  mission_id   uuid NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  progress     int  NOT NULL DEFAULT 0,
  completed    boolean NOT NULL DEFAULT false,
  completed_at timestamptz,
  assigned_date date NOT NULL DEFAULT CURRENT_DATE,
  UNIQUE (user_id, mission_id, assigned_date)
);
CREATE INDEX IF NOT EXISTS idx_user_missions_user ON user_missions(user_id, assigned_date DESC);

INSERT INTO missions (slug, title, description, type, activity, target, unit, coin_reward, xp_reward) VALUES
  ('daily_walk_5k',   'Walk 5,000 Steps',       'Reach 5k steps today',          'daily',   'walk',  5000,  'steps',   20,  50),
  ('daily_walk_10k',  'Hit 10,000 Steps',        'Reach 10k steps today',         'daily',   'walk',  10000, 'steps',   50,  100),
  ('daily_gym',       'Gym Session',             'Log a gym session today',       'daily',   'gym',   1,     'session', 30,  60),
  ('weekly_streak',   '5-Day Streak',            'Stay active 5 days this week',  'weekly',  'walk',  5,     'days',    150, 300),
  ('weekly_70k',      '70,000 Steps This Week',  'Walk 70k steps this week',      'weekly',  'walk',  70000, 'steps',   200, 400),
  ('seasonal_summer', 'Summer Shred',            'Walk 500k steps this season',   'seasonal','walk',  500000,'steps',   1000,2000)
ON CONFLICT DO NOTHING;

-- ============================================================
-- RIVALS & BATTLES
-- ============================================================
CREATE TABLE IF NOT EXISTS rivals (
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rival_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, rival_id),
  CHECK (user_id <> rival_id)
);

CREATE TABLE IF NOT EXISTS battles (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenger_id uuid NOT NULL REFERENCES users(id),
  opponent_id   uuid NOT NULL REFERENCES users(id),
  start_time    timestamptz,
  end_time      timestamptz,
  duration_days int  NOT NULL DEFAULT 7,
  step_goal     int  NOT NULL DEFAULT 0,
  status        text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','ended','declined')),
  winner_id     uuid REFERENCES users(id),
  coin_wager    int  NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_battles_challenger ON battles(challenger_id);
CREATE INDEX IF NOT EXISTS idx_battles_opponent  ON battles(opponent_id);

-- ============================================================
-- REWARDS MARKETPLACE
-- ============================================================
CREATE TABLE IF NOT EXISTS rewards (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title       text NOT NULL,
  brand       text NOT NULL,
  category    text NOT NULL CHECK (category IN ('watch','shoes','protein','gym','voucher','wellness')),
  description text NOT NULL DEFAULT '',
  coin_cost   int  NOT NULL,
  stock       int,
  image_url   text,
  active      boolean NOT NULL DEFAULT true,
  sort_order  int  NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS reward_redemptions (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reward_id  uuid NOT NULL REFERENCES rewards(id),
  coin_spent int  NOT NULL,
  status     text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','fulfilled','cancelled')),
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_reward_redemptions_user ON reward_redemptions(user_id, created_at DESC);

INSERT INTO rewards (title, brand, category, description, coin_cost, sort_order) VALUES
  ('Running Shoes',        'Nike',        'shoes',   'Nike Air Zoom Pegasus',         5000, 1),
  ('Smartwatch',           'Noise',       'watch',   'Noise ColorFit Pro 4',          8000, 2),
  ('Whey Protein 1kg',     'MuscleBlaze', 'protein', 'MuscleBlaze Biozyme Whey',      3000, 3),
  ('Gym Membership 1mo',   'Cult.fit',    'gym',     '1 month Cult.fit membership',   4000, 4),
  ('Amazon Voucher ₹500',  'Amazon',      'voucher', 'Amazon shopping voucher',       1000, 5),
  ('Amazon Voucher ₹1000', 'Amazon',      'voucher', 'Amazon shopping voucher',       1800, 6),
  ('Premium Yoga Mat',     'Boldfit',     'wellness','Anti-slip TPE yoga mat',        2500, 7)
ON CONFLICT DO NOTHING;

-- ============================================================
-- BATTLE PASS
-- ============================================================
CREATE TABLE IF NOT EXISTS battle_passes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  season     int  NOT NULL UNIQUE,
  title      text NOT NULL,
  start_date date NOT NULL,
  end_date   date NOT NULL,
  tiers      jsonb NOT NULL DEFAULT '[]'::jsonb,
  active     boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS user_battle_pass (
  user_id       uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  season        int  NOT NULL,
  xp            int  NOT NULL DEFAULT 0,
  is_premium    boolean NOT NULL DEFAULT false,
  claimed_tiers jsonb NOT NULL DEFAULT '[]'::jsonb,
  PRIMARY KEY (user_id, season)
);

INSERT INTO battle_passes (season, title, start_date, end_date, tiers, active) VALUES
  (1, 'Summer Shred Season', '2026-06-01', '2026-08-31',
   '[
     {"level":1,"xp_required":0,   "free_reward":"50 coins",  "paid_reward":"100 coins"},
     {"level":2,"xp_required":500, "free_reward":"XP boost",  "paid_reward":"Amazon ₹100 voucher"},
     {"level":3,"xp_required":1500,"free_reward":"100 coins", "paid_reward":"Protein sample"},
     {"level":4,"xp_required":3000,"free_reward":"Badge",     "paid_reward":"250 coins"},
     {"level":5,"xp_required":5000,"free_reward":"500 coins", "paid_reward":"Cult.fit 1-week pass"}
   ]'::jsonb,
   true)
ON CONFLICT DO NOTHING;

-- ============================================================
-- STREAK SHIELDS
-- ============================================================
CREATE TABLE IF NOT EXISTS streak_shields (
  id       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id  uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  used_at  timestamptz NOT NULL DEFAULT now(),
  month    int  NOT NULL,
  type     text NOT NULL DEFAULT 'shield' CHECK (type IN ('shield','revive'))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_streak_shield_monthly ON streak_shields(user_id, month, type);

-- ============================================================
-- SUBSCRIPTIONS
-- ============================================================
CREATE TABLE IF NOT EXISTS subscription_plans (
  slug       text PRIMARY KEY,
  label      text NOT NULL,
  price_inr  int  NOT NULL DEFAULT 0,
  features   jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order int  NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_subscriptions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_slug       text NOT NULL REFERENCES subscription_plans(slug),
  status          text NOT NULL DEFAULT 'active' CHECK (status IN ('active','cancelled','expired')),
  razorpay_sub_id text,
  started_at      timestamptz NOT NULL DEFAULT now(),
  expires_at      timestamptz,
  UNIQUE (user_id)
);

INSERT INTO subscription_plans (slug, label, price_inr, features, sort_order) VALUES
  ('free',     'Free',     0,   '["Track all activities","Join free challenges","Bronze & Silver leagues"]', 1),
  ('beginner', 'Beginner', 149, '["Everything in Free","2 Paid challenges/month","Earn coins","Top 50% rewarded","Redeem for gift cards","Gold league access"]', 2),
  ('pro',      'Pro',      499, '["Everything in Beginner","Unlimited paid challenges","Platinum+ leagues","Streak shield (1/month)","Battle Pass premium","Priority payouts"]', 3)
ON CONFLICT DO NOTHING;

-- ============================================================
-- FITNESS REPUTATION
-- ============================================================
CREATE TABLE IF NOT EXISTS fitness_reputation (
  user_id              uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  fitness_score        int    NOT NULL DEFAULT 0,
  consistency_score    int    NOT NULL DEFAULT 0,
  elite_streak_days    int    NOT NULL DEFAULT 0,
  challenges_completed int    NOT NULL DEFAULT 0,
  challenges_won       int    NOT NULL DEFAULT 0,
  total_steps          bigint NOT NULL DEFAULT 0,
  updated_at           timestamptz NOT NULL DEFAULT now()
);

-- ============================================================
-- CUSTOM CHALLENGES
-- ============================================================
CREATE TABLE IF NOT EXISTS custom_challenges (
  id            uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id    uuid NOT NULL REFERENCES users(id),
  title         text NOT NULL,
  activity      text NOT NULL DEFAULT 'walk',
  difficulty    text NOT NULL CHECK (difficulty IN ('easy','medium','hard')),
  duration_days int  NOT NULL DEFAULT 7,
  frequency     text NOT NULL DEFAULT '',
  coin_reward   int  NOT NULL DEFAULT 0,
  share_code    text NOT NULL UNIQUE DEFAULT upper(substr(replace(gen_random_uuid()::text,'-',''),1,8)),
  status        text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','ended')),
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS custom_challenge_invites (
  challenge_id uuid NOT NULL REFERENCES custom_challenges(id) ON DELETE CASCADE,
  invitee_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status       text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined')),
  PRIMARY KEY (challenge_id, invitee_id)
);

-- ============================================================
-- COMMUNITY FEED
-- ============================================================
CREATE TABLE IF NOT EXISTS community_posts (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type       text NOT NULL CHECK (type IN ('flex','achievement','challenge_win','streak_milestone')),
  content    text NOT NULL,
  metadata   jsonb NOT NULL DEFAULT '{}'::jsonb,
  likes      int  NOT NULL DEFAULT 0,
  created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_community_posts_created ON community_posts(created_at DESC);

CREATE TABLE IF NOT EXISTS community_post_likes (
  post_id    uuid NOT NULL REFERENCES community_posts(id) ON DELETE CASCADE,
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  PRIMARY KEY (post_id, user_id)
);
