# StepUp — Full App Completion Spec
**Date:** 2026-05-25  
**Status:** Approved  
**Scope:** Complete all wireframe sections end-to-end (DB + API + Flutter)  
**Wireframe source:** `/wireframes/project/` (StepUp Wireframes.html, wireframes.jsx, wireframes-extra.jsx, wireframes-pro.jsx)

---

## 1. Overview

StepUp is a competitive fitness platform where users walk to win real money. This spec covers the completion of the full app matching the approved wireframes. Three parallel workstreams: database migrations, API modules, Flutter screens.

**What already exists:**
- Auth (phone OTP, Google, Apple), Splash, Onboarding, Profile setup
- Home screen (step ring, stats row, active challenges strip)
- Challenges (list, detail, join flow + wallet debit)
- Leaderboard (global + city, Redis-backed)
- Wallet (deposit via Razorpay, withdraw via UPI)
- Health screen (HealthKit / Health Connect, all activity types)
- Steps module (background sync, anti-cheat pipeline)
- Dark indigo theme

**What this spec adds:**
- Theme update (volt-lime + amber on deep navy-black, Big Shoulders Display + Inter fonts)
- League system (Bronze → Elite, XP, standings)
- Daily / Weekly / Seasonal Missions
- Rivals & Battles
- Custom challenge creation + invite friends
- Premium Rewards Marketplace
- Battle Pass
- Subscription / Plan picker
- Profile XP + Fitness Reputation
- Streak Protection (shield / revive)
- Community Feed (flex achievements)
- Updated tab bar: Home / Chal / Lead / Coins / Me

---

## 2. Design System

### Colors (exact hex from wireframes)
```
--bg:      #050510   /* deep navy-black */
--surface: #0d0d1a   /* card background */
--surface2: #13131f  /* elevated surface */
--ink:     #ffffff   /* primary text */
--ink-2:   #a3a3b3   /* secondary text */
--ink-3:   #4b5563   /* muted text */
--matcha:  #d4ff3a   /* volt-lime — active, XP, step ring, primary CTA */
--ochre:   #ffb547   /* amber gold — coins, wallet, money */
--border:  rgba(255,255,255,0.08)  /* subtle border */
```

### Typography
```
Big Shoulders Display (700/800/900) — headers, big numbers, tab labels, league names
Inter (400/500/600/700) — body text, descriptions, form fields
```

Add Google Fonts to pubspec.yaml: `google_fonts: ^6.2.1`

### Layout Tokens
```
borderRadius: 14px (cards), 10px (chips/pills), 999px (fully rounded buttons)
padding: 16px horizontal, 12px section gap
tabBar: solid #0d0d1a bg, no elevation, volt-lime active indicator
```

### Tab Bar
```
[home → Home] [trophy → Chal] [chart → Lead] [coin → Coins] [user → Me]
```
Routes: `/home`, `/challenges`, `/leaderboard`, `/coins`, `/profile`

---

## 3. Database Migrations

### 3.1 Leagues

```sql
CREATE TABLE IF NOT EXISTS leagues (
  slug        text PRIMARY KEY,  -- bronze/silver/gold/platinum/diamond/elite
  label       text NOT NULL,
  color_hex   text NOT NULL,
  xp_min      int  NOT NULL DEFAULT 0,
  xp_max      int,               -- NULL for elite (no cap)
  paid_only   boolean NOT NULL DEFAULT false,
  sort_order  int  NOT NULL
);

CREATE TABLE IF NOT EXISTS user_leagues (
  user_id      uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  league_slug  text NOT NULL REFERENCES leagues(slug),
  xp           int  NOT NULL DEFAULT 0,
  rank_in_tier int,
  season       int  NOT NULL DEFAULT 1,
  promoted_at  timestamptz,
  relegated_at timestamptz,
  updated_at   timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_user_leagues_slug ON user_leagues(league_slug, xp DESC);
```

Seed data:
```sql
INSERT INTO leagues (slug, label, color_hex, xp_min, xp_max, paid_only, sort_order) VALUES
  ('bronze',   'Bronze',   '#a86a3a',  0,     999,   false, 1),
  ('silver',   'Silver',   '#9aa3ad',  1000,  1999,  false, 2),
  ('gold',     'Gold',     '#d9a93a',  2000,  2999,  false, 3),
  ('platinum', 'Platinum', '#7ed4d4',  3000,  4999,  true,  4),
  ('diamond',  'Diamond',  '#a8c4ff',  5000,  9999,  true,  5),
  ('elite',    'Elite',    '#d4ff3a',  10000, NULL,  true,  6)
ON CONFLICT DO NOTHING;
```

### 3.2 Missions

```sql
CREATE TABLE IF NOT EXISTS missions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug        text NOT NULL UNIQUE,
  title       text NOT NULL,
  description text NOT NULL,
  type        text NOT NULL CHECK (type IN ('daily','weekly','seasonal')),
  activity    text NOT NULL DEFAULT 'walk',
  target      int  NOT NULL,           -- steps or minutes
  unit        text NOT NULL DEFAULT 'steps',
  coin_reward int  NOT NULL DEFAULT 0,
  xp_reward   int  NOT NULL DEFAULT 0,
  expires_at  timestamptz,
  active      boolean NOT NULL DEFAULT true
);

CREATE TABLE IF NOT EXISTS user_missions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  mission_id   uuid NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  progress     int  NOT NULL DEFAULT 0,
  completed    boolean NOT NULL DEFAULT false,
  completed_at timestamptz,
  assigned_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, mission_id, assigned_at)
);
CREATE INDEX IF NOT EXISTS idx_user_missions_user ON user_missions(user_id, assigned_at DESC);
```

### 3.3 Rivals & Battles

```sql
CREATE TABLE IF NOT EXISTS rivals (
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  rival_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, rival_id),
  CHECK (user_id <> rival_id)
);

CREATE TABLE IF NOT EXISTS battles (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenger_id uuid NOT NULL REFERENCES users(id),
  opponent_id   uuid NOT NULL REFERENCES users(id),
  start_time    timestamptz NOT NULL,
  end_time      timestamptz NOT NULL,
  step_goal     int  NOT NULL DEFAULT 0,  -- 0 = highest steps wins
  status        text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','active','ended','declined')),
  winner_id     uuid REFERENCES users(id),
  coin_wager    int  NOT NULL DEFAULT 0,
  created_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_battles_users ON battles(challenger_id, opponent_id);
```

### 3.4 Rewards Marketplace

```sql
CREATE TABLE IF NOT EXISTS rewards (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title        text NOT NULL,
  brand        text NOT NULL,
  category     text NOT NULL CHECK (category IN ('watch','shoes','protein','gym','voucher','wellness')),
  description  text NOT NULL DEFAULT '',
  coin_cost    int  NOT NULL,
  stock        int,                -- NULL = unlimited
  image_url    text,
  active       boolean NOT NULL DEFAULT true,
  sort_order   int  NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS reward_redemptions (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  reward_id   uuid NOT NULL REFERENCES rewards(id),
  coin_spent  int  NOT NULL,
  status      text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','fulfilled','cancelled')),
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_reward_redemptions_user ON reward_redemptions(user_id, created_at DESC);
```

### 3.5 Battle Pass

```sql
CREATE TABLE IF NOT EXISTS battle_passes (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  season     int  NOT NULL UNIQUE,
  title      text NOT NULL,
  start_date date NOT NULL,
  end_date   date NOT NULL,
  tiers      jsonb NOT NULL DEFAULT '[]'::jsonb,  -- [{level, xp_required, free_reward, paid_reward}]
  active     boolean NOT NULL DEFAULT false
);

CREATE TABLE IF NOT EXISTS user_battle_pass (
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  season     int  NOT NULL,
  xp         int  NOT NULL DEFAULT 0,
  is_premium boolean NOT NULL DEFAULT false,
  claimed_tiers jsonb NOT NULL DEFAULT '[]'::jsonb,  -- [level numbers claimed]
  PRIMARY KEY (user_id, season)
);
```

### 3.6 Streak Shields

```sql
CREATE TABLE IF NOT EXISTS streak_shields (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  used_at     timestamptz NOT NULL DEFAULT now(),
  month       int  NOT NULL,  -- YYYYMM
  type        text NOT NULL DEFAULT 'shield' CHECK (type IN ('shield','revive'))
);
CREATE UNIQUE INDEX IF NOT EXISTS idx_streak_shield_monthly ON streak_shields(user_id, month, type);
```

### 3.7 Subscriptions

```sql
CREATE TABLE IF NOT EXISTS subscription_plans (
  slug        text PRIMARY KEY,
  label       text NOT NULL,
  price_inr   int  NOT NULL DEFAULT 0,
  features    jsonb NOT NULL DEFAULT '[]'::jsonb,
  sort_order  int  NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS user_subscriptions (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id         uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_slug       text NOT NULL REFERENCES subscription_plans(slug),
  status          text NOT NULL DEFAULT 'active' CHECK (status IN ('active','cancelled','expired')),
  razorpay_sub_id text,
  started_at      timestamptz NOT NULL DEFAULT now(),
  expires_at      timestamptz,
  UNIQUE (user_id)  -- one active sub per user
);
```

Seed:
```sql
INSERT INTO subscription_plans (slug, label, price_inr, features, sort_order) VALUES
  ('free',      'Free',      0,   '["Track all activities","Join free challenges"]', 1),
  ('beginner',  'Beginner',  149, '["Everything in Free","2 Paid challenges/month","Earn coins","Top 50% rewarded","Redeem for gift cards"]', 2),
  ('pro',       'Pro',       499, '["Everything in Beginner","Unlimited paid challenges","Platinum+ leagues","Streak shield","Battle Pass premium","Priority payouts"]', 3)
ON CONFLICT DO NOTHING;
```

### 3.8 Fitness Reputation

```sql
CREATE TABLE IF NOT EXISTS fitness_reputation (
  user_id           uuid PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  fitness_score     int  NOT NULL DEFAULT 0,   -- 0–1000, computed weekly
  consistency_score int  NOT NULL DEFAULT 0,   -- 0–100, % of days active (30d)
  elite_streak_days int  NOT NULL DEFAULT 0,
  challenges_completed int NOT NULL DEFAULT 0,
  challenges_won    int  NOT NULL DEFAULT 0,
  total_steps       bigint NOT NULL DEFAULT 0,
  updated_at        timestamptz NOT NULL DEFAULT now()
);
```

### 3.9 Custom Challenges

```sql
CREATE TABLE IF NOT EXISTS custom_challenges (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  creator_id   uuid NOT NULL REFERENCES users(id),
  title        text NOT NULL,
  activity     text NOT NULL DEFAULT 'walk',
  difficulty   text NOT NULL CHECK (difficulty IN ('easy','medium','hard')),
  duration_days int NOT NULL DEFAULT 7,
  frequency    text NOT NULL DEFAULT '',   -- e.g. "4 sessions / week"
  coin_reward  int  NOT NULL DEFAULT 0,   -- system-generated based on difficulty
  share_code   text NOT NULL UNIQUE DEFAULT substr(gen_random_uuid()::text,1,8),
  status       text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft','active','ended')),
  created_at   timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS custom_challenge_invites (
  challenge_id uuid NOT NULL REFERENCES custom_challenges(id) ON DELETE CASCADE,
  invitee_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status       text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','accepted','declined')),
  PRIMARY KEY (challenge_id, invitee_id)
);
```

### 3.10 Community Feed

```sql
CREATE TABLE IF NOT EXISTS community_posts (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type        text NOT NULL CHECK (type IN ('flex','achievement','challenge_win','streak_milestone')),
  content     text NOT NULL,
  metadata    jsonb NOT NULL DEFAULT '{}'::jsonb,  -- steps, challenge name, badge slug, etc.
  likes       int  NOT NULL DEFAULT 0,
  created_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_community_posts_created ON community_posts(created_at DESC);
```

### 3.11 Coins Wallet Extension

Add `coin_balance` column to users table:
```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS coin_balance int NOT NULL DEFAULT 0;
```

Coins are separate from INR wallet — earned through challenges, missions, battle pass. Redeemable in rewards marketplace.

---

## 4. API Modules

### 4.1 Leagues Module (`/leagues`)
- `GET /leagues/me` → user's tier, XP, rank in tier, tier ladder with locked/unlocked state
- `GET /leagues/standings` → paginated standings for user's current tier (50 per page)
- `POST /leagues/sync` → internal cron trigger to recompute league placements weekly

### 4.2 Missions Module (`/missions`)
- `GET /missions/daily` → today's daily missions for the user (3 missions assigned daily at midnight)
- `GET /missions/weekly` → this week's weekly missions
- `GET /missions/seasonal` → active seasonal tournament missions
- `POST /missions/:id/complete` → trigger completion check (server validates against step_logs / user_missions)

### 4.3 Rivals Module (`/rivals`)
- `GET /rivals` → list of user's rivals with their current stats (steps, league, streak)
- `POST /rivals/:userId` → add rival
- `DELETE /rivals/:rivalId` → remove rival
- `GET /rivals/battles` → active and recent battles
- `POST /battles` → create battle (body: opponent_id, duration_days, coin_wager)
- `POST /battles/:id/respond` → accept or decline battle (body: accept: bool)

### 4.4 Rewards Module (`/rewards`)
- `GET /rewards` → list all active rewards (grouped by category)
- `GET /rewards/:id` → reward detail
- `POST /rewards/:id/redeem` → redeem with coins (atomic debit + insert redemption)
- `GET /rewards/redemptions` → user's redemption history

### 4.5 Battle Pass Module (`/battlepass`)
- `GET /battlepass/current` → active season, user's XP, tier progress, claimable rewards
- `POST /battlepass/claim/:level` → claim tier reward
- `POST /battlepass/upgrade` → upgrade to premium battle pass (triggers Razorpay)

### 4.6 Subscriptions Module (`/subscriptions`)
- `GET /subscriptions/plans` → list all plans
- `GET /subscriptions/me` → user's active subscription
- `POST /subscriptions/subscribe` → subscribe to a plan (Razorpay subscription)
- `POST /subscriptions/cancel` → cancel subscription

### 4.7 Community Module (`/community`)
- `GET /community/feed` → paginated global + friends feed (20 per page)
- `POST /community/flex` → post a flex (auto-triggered on challenge win/milestone, or manual)
- `POST /community/posts/:id/like` → like a post

### 4.8 Streaks Module (`/streaks`)
- `GET /streaks/status` → streak days, shield available this month, last active date
- `POST /streaks/shield` → use streak shield (premium only, max 1/month)
- `POST /streaks/revive` → pay coins to revive a broken streak

### 4.9 Custom Challenges (`/challenges/custom`)
- `POST /challenges/custom` → create custom challenge (body: title, activity, difficulty, duration_days, frequency)
  - Server computes coin_reward: easy=60, medium=200, hard=500
- `GET /challenges/custom/:shareCode` → get by share code (for invite links)
- `POST /challenges/custom/:id/invite` → invite friends (body: user_ids[])

### 4.10 Profile Extension (`/profile`)
- `GET /profile/:userId/reputation` → fitness_reputation for a user
- `PUT /profile/me` → update name, city, language, avatar_url, goal_tier

---

## 5. Flutter Screens

### 5.1 Theme Update
- Update `core/theme.dart` — new color constants, updated ColorScheme, font families via google_fonts
- Update `pubspec.yaml` — add google_fonts: ^6.2.1
- Update `core/router.dart` — rename tabs (Coins replaces Wallet), add new routes

### 5.2 New Routes
```
/home                    ← existing (updated design)
/challenges              ← existing
/challenges/:id          ← existing
/challenges/custom/new   ← new: custom challenge creation
/challenges/custom/:code ← new: join by share code
/leaderboard             ← existing (add league tab)
/leaderboard/league      ← new: league standings
/coins                   ← new: replaces /wallet tab
/coins/rewards           ← new: marketplace
/coins/battlepass        ← new: battle pass
/profile                 ← existing (updated with reputation)
/profile/subscription    ← new: plan picker
/missions                ← new: daily/weekly missions
/rivals                  ← new: rivals & battles
/community               ← new: community feed
/streaks                 ← new: streak protection
```

### 5.3 Screen Specifications

#### Home Screen (updated)
- Volt-lime step ring (SVG-style circular progress, Big Shoulders Display number inside)
- Greeting row: `Good morning, [Name]` + avatar circle + notification bell
- Step ring hero card (flat, no heavy border — NRC style open layout)
- Stats strip below ring: Rank / Streak (🔥) / League badge
- Daily Missions strip: 3 mission pills with progress (tap → /missions)
- Active challenges section (same as before, updated card style)

#### League Hub Screen (under Lead tab)
- Hero section: user's current tier badge (colored circle + medal icon), tier name, rank "X of Y in your league"
- XP progress bar toward next tier
- Tier ladder list: Bronze → Elite, locked tiers show lock icon, Platinum+ show PRO chip
- "Season N" chip in header

#### League Standings Screen
- Current user card highlighted in volt-lime
- Ranked list with promotion zone (top 25% green) and relegation zone (bottom 15% red dashed)
- Reset countdown: "Resets in Xd Yh"

#### Missions Screen
- Three sections: Daily / Weekly / Seasonal (horizontal tab switcher)
- Mission row: icon + title + progress bar + coin reward chip
- Completion animation: volt-lime checkmark, coin credit

#### Rivals Screen
- Header: "Rivals" + "Add rival" button (userPlus icon)
- Rival cards: avatar, name, league badge, current week steps, streak
- Active battle card (highlighted, shows time remaining, steps comparison)
- "Challenge" button on each rival card

#### Custom Challenge Screen
- Title input
- Activity chips: Walk / Gym / Yoga / Run / Cycle / Sport
- Difficulty: Easy (+60¢) / Medium (+200¢) / Hard (+500¢) — system shows live reward
- Duration chips: 3/7/14/21/30 days
- Frequency field
- Next → Invite friends screen

#### Invite Friends Screen
- Challenge summary card
- Share link + Copy + WhatsApp share
- Friend list with toggle-to-invite

#### Rewards Marketplace Screen
- Category filter chips: All / Watch / Shoes / Protein / Gym / Voucher
- Aspirational reward cards: brand name, product image, coin cost
- "Redeem" button (volt-lime when affordable, muted when not)
- User's coin balance in header

#### Battle Pass Screen
- Season title + days remaining
- Horizontal tier track with free/paid reward icons at each level
- User's position marker
- "Upgrade to Premium" CTA for free users

#### Subscription Screen (Plan Picker)
- Three plan cards: Free / Beginner (₹149/mo, recommended) / Pro (₹499/mo)
- Feature list per plan
- Razorpay flow for paid plans

#### Profile Screen (updated)
- Avatar + name + league badge + city
- Fitness Reputation section: fitness score (0–1000), consistency score (%), elite streak
- Stats row: total steps, challenges completed, challenges won
- Badges section: earned badge chips
- Subscription status + "Upgrade" CTA
- Settings: language, notification preferences

#### Streak Protection Screen
- Current streak display
- Shield status: "1 shield available this month" or "Used on [date]"
- Revive option: costs coins (e.g. 100¢ to revive broken streak)

#### Community Feed Screen
- Feed cards: avatar, name, post type badge (flex/win/streak), content, like count
- Post types: challenge win, streak milestone, flex achievement
- Like button

### 5.4 Coins Tab (replaces Wallet)
- Top section: INR wallet balance + coin balance side by side
- Two action rows: Deposit / Withdraw (INR), Earn / Redeem (Coins)
- Quick links to Rewards Marketplace + Battle Pass
- Recent wallet transactions

---

## 6. State Management

Keep Riverpod for all new providers. Pattern follows existing providers.

New providers:
```
leagueProvider       → AsyncNotifier, GET /leagues/me
missionsProvider     → AsyncNotifier, GET /missions/daily + weekly
rivalsProvider       → AsyncNotifier, GET /rivals
battlesProvider      → AsyncNotifier, GET /rivals/battles
rewardsProvider      → AsyncNotifier, GET /rewards
battlePassProvider   → AsyncNotifier, GET /battlepass/current
subscriptionProvider → AsyncNotifier, GET /subscriptions/me
communityProvider    → AsyncNotifier, GET /community/feed
streakProvider       → AsyncNotifier, GET /streaks/status
reputationProvider   → AsyncNotifier, GET /profile/me/reputation
```

---

## 7. Error Handling & Edge Cases

- **League locked tiers:** Frontend shows lock icon + PRO chip, tapping shows subscription CTA
- **Insufficient coins:** Redeem button disabled with tooltip "Not enough coins"
- **Battle declined:** Challenger gets notification, battle moves to `declined`
- **Streak shield used:** One per month — UI disables shield button after use, shows "Revive" option (costs coins)
- **Custom challenge invites:** Deep link via share code (`stepup://join/[code]`); if app not installed, web fallback
- **Offline:** All screens show cached data with "Last synced X ago" badge; step sync queued locally

---

## 8. Workstreams

**Workstream A — Database:**
1. Write all migration SQL files
2. Apply to Supabase (dev + prod)
3. Seed leagues, subscription_plans, sample rewards, sample missions

**Workstream B — API:**
1. New modules: leagues, missions, rivals, rewards, battlepass, subscriptions, community, streaks
2. Extend challenges module: custom challenges + invite
3. Extend profile module: reputation endpoint
4. Wire new routers into app.ts
5. Add new TypeScript types

**Workstream C — Flutter:**
1. Theme + pubspec + router update (blocks all other Flutter work — do first)
2. New providers (can be built in parallel after theme)
3. New screens (one per feature, after providers exist)
4. Wire Coins tab (replaces Wallet tab)
5. Integration: swap mock data for real API calls once Workstream B is done

---

## 9. Out of Scope for This Spec

- Admin dashboard updates (league management, mission creation UI)
- Smartwatch-native app
- Insurance integrations
- Corporate HR dashboard
- Push notification deep-link routing (existing FCM is sufficient for v1)
