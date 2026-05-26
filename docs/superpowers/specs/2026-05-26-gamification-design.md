# Gamification Overhaul — Design Spec
**Date:** 2026-05-26  
**Approach:** Layered (4 independent layers, each shippable independently)

---

## Overview

Full-stack gamification system connecting XP, Levels, Tiers, Fitness Reputation, Streaks, Coins, and Seasons. All Flutter screens currently use hardcoded data; this spec wires everything to real API endpoints and adds missing backend logic.

---

## Layer 1 — XP Engine

### XP Sources

| Source | Amount | Trigger |
|---|---|---|
| Steps | 10 XP per 1,000 steps | On step sync (existing, keep) |
| Daily mission complete | `mission.xp_reward` from DB | On mission completion (fix broken award) |
| Weekly mission complete | `mission.xp_reward` from DB | On mission completion |
| Free daily challenge — any finish | 50 XP | In payout.job.ts after coin payout |
| Free weekly challenge — any finish | 150 XP | In payout.job.ts after coin payout |
| Paid challenge — top 50% finish | 200 XP | In payout.job.ts after coin payout |
| Paid challenge — top 10% finish | 400 XP | In payout.job.ts after coin payout |

### Bug Fix: `awardMissionReward`

Current code in `missions.service.ts` does:
```typescript
await db.from('users').update({
  xp: db.rpc('increment', { ... }) as any
}).eq('id', userId);
```
This is invalid — `db.rpc(...)` returns a query builder, not a value. Fix by calling `db.rpc('increment_xp', { uid: userId, amount: xp })` directly (same pattern as `increment_coins`), or by fetching current XP and updating with `xp + amount`.

### Level-Up Coin Reward (new)

- Formula: `level × 10 coins` awarded when XP crosses a level threshold
- Level 5 → 50 coins, Level 20 → 200 coins, Level 50 → 500 coins
- A `checkLevelUp(userId, oldXp, newXp, db)` function runs after every XP award
- Coin reward credited via existing `increment_coins` RPC
- No DB schema change needed — uses existing `users.coin_balance` and `user_levels` tables

### XP Award Flow (all sources)

```
awardXp(userId, amount, source) →
  1. Fetch current user_levels row (xp, level)
  2. Compute new_xp = xp + amount
  3. Loop: while new_xp >= xpForNextLevel(level) → level++, award level×10 coins
  4. Update user_levels SET xp=new_xp, level=new_level
  5. Update users SET xp=new_xp (kept in sync for league calculations)
```

### Flutter Changes

- `xp_level_screen.dart` — remove all hardcoded constants; add `xpLevelProvider` (FutureProvider) → `GET /steps/levels`
- `home_screen.dart` — add XP bar widget using `xpLevelProvider`
- New level-up overlay: full-screen celebration modal shown when level increases, displaying new level name + coin reward amount

---

## Layer 2 — Streak v2

### Daily Step Goal

Fixed at **10,000 steps** (user-configurable goal can be added later without changing this logic).

### Activity Classification (per calendar day)

| Status | Steps | Behaviour |
|---|---|---|
| **Full** | ≥ 10,000 (100% of goal) | Streak maintained, resets partial counter |
| **Partial** | 5,000–9,999 (50–99% of goal) | Neutral; 3 consecutive = break |
| **None** | < 5,000 (< 50% of goal) | 2 consecutive = break |

### Streak Break Rules

- **Rule 1:** 2 consecutive `None` days → streak breaks on the second day
- **Rule 2:** 3 consecutive `Partial` days → streak breaks on the third day
- **Safe reset:** any `Full` day resets the partial-day counter to 0
- Streak counter increments only on `Full` days; `Partial` days hold the current count

### Streak Evaluation (runs nightly + on step sync)

```
evaluateStreak(userId, date):
  1. Fetch last 3 days of step data from user_daily_steps
  2. Classify each day as Full / Partial / None
  3. Apply break rules
  4. If break: set users.streak_days = 0, record break date
  5. If Full today: increment users.streak_days, update users.best_streak_days if new high
```

### Calendar API — new endpoint

`GET /streaks/calendar?days=60`

Returns array of day objects for the last N days:
```json
[
  {
    "date": "2026-05-26",
    "steps": 11240,
    "status": "full",
    "streak_count": 14
  }
]
```

`streak_count` is the rolling streak value on that specific day (0 after a break, incremented on Full days). This lets the calendar render the streak number inside each cell.

### Monthly Restore (unchanged logic, 2× total)

| Type | Who | Cost | Limit | Effect |
|---|---|---|---|---|
| Shield | Pro only | Free | 1× per month | Treats one `None` day as `Partial` (prevents Rule 1 break) |
| Revive | Anyone | 100 coins | 1× per month | Restores streak after a break; window = 2 days after break |

Total = max 2 restores per calendar month.

### `streak_shields` table

Existing table covers both types via `type: 'shield' | 'revive'`. No schema change needed.

### `users` table additions

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS best_streak_days INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_break_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS partial_day_count INT DEFAULT 0;
```

### Flutter Changes

- `streak_screen.dart` — add calendar widget (60-day grid) using `GET /streaks/calendar`; calendar design is a placeholder (green/amber/red cells), visual polish is a separate task
- `streak_provider.dart` — add `streakCalendarProvider` FutureProvider

---

## Layer 3 — Fitness Reputation

### Score Range: 0–900

Same scale as a credit score. Five sub-scores each 0–100, weighted and multiplied by 9 to produce the final 0–900 value.

### Sub-Score Formulas

| Sub-score | Weight | Formula (0–100) | Window |
|---|---|---|---|
| Consistency | 30% | `(full_days + partial_days × 0.5) / 30 × 100` | Last 30 days |
| Challenge wins | 25% | `top_50pct_finishes / max(challenges_joined, 1) × 100` | All time |
| Streak depth | 20% | `min((current_streak × 2 + best_streak) / 90 × 100, 100)` | Current |
| Activity mix | 15% | `distinct_activity_types / 4 × 100` (types: steps, gym, cycling, outdoor) | Last 30 days |
| Social | 10% | `min((posts_count + likes_received / 10) / 20 × 100, 100)` | All time |

**Final score:** `(C×0.30 + CW×0.25 + SD×0.20 + AM×0.15 + S×0.10) × 9`

### Additional API Fields

- `percentile` — user's rank among all users with a score, expressed as top-N% (e.g. "TOP 8%")
- `monthly_delta` — difference between current score and `reputation_snapshot_prev`
- `highlights` — `{ best_streak_days, total_challenges_joined, top_50pct_finishes }`
- `breakdown` — each sub-score with its raw value (0–100) for progress bars

### DB Changes

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_score INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_updated_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_snapshot_prev INT DEFAULT 0;
-- best_streak_days already added in Layer 2
```

### Recalculation Strategy

- Nightly cron job: `recalculateReputation(userId)` for all active users
- On-demand: `GET /reputation` recalculates if `reputation_updated_at` is > 24h old
- On 1st of each month: copy `reputation_score` → `reputation_snapshot_prev` before recalculating

### New Module: `reputation`

- `stepup-api/src/modules/reputation/reputation.router.ts` — `GET /reputation`
- `stepup-api/src/modules/reputation/reputation.service.ts` — `calculateReputation(userId)`, `recalculateAll()`

### Flutter Changes

- `reputation_screen.dart` — remove hardcoded values; add `reputationProvider` → `GET /reputation`
- All 5 sub-score progress bars driven by `breakdown` object from API
- Score hero shows real score, percentile, and monthly delta

---

## Layer 4 — Seasons

### DB Schema

```sql
CREATE TABLE seasons (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name            TEXT NOT NULL,
  start_date      DATE NOT NULL,
  end_date        DATE NOT NULL,
  status          TEXT NOT NULL DEFAULT 'upcoming', -- upcoming | active | ended
  tier_decay_pct  INT NOT NULL DEFAULT 50,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE user_season_results (
  id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id           UUID REFERENCES users(id),
  season_id         UUID REFERENCES seasons(id),
  final_league_slug TEXT NOT NULL,
  final_xp          INT NOT NULL,
  rank_in_tier      INT,
  coins_awarded     INT DEFAULT 0,
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, season_id)
);
```

### Seed Data (Season 1)

```sql
INSERT INTO seasons (name, start_date, end_date, status)
VALUES ('Season 1: Foundation', '2026-05-26', '2026-07-25', 'active');
```

### Season End Logic (triggered by `POST /seasons/:id/end`, admin only)

1. **Snapshot** — insert one `user_season_results` row per user with their current `league_slug`, `xp`, and `rank_in_tier`
2. **Award coins** by final tier: Elite→2000, Diamond→1000, Platinum→500, Gold→250, Silver→100, Bronze→25
3. **Tier soft-decay** — `users.xp = floor(users.xp × (tier_decay_pct / 100))`, then recalculate `user_leagues.league_slug` from new XP value. `user_levels.xp` (lifetime XP for levels and reputation) is **not touched**.
4. **Mark season ended** — `UPDATE seasons SET status='ended'`
5. **Activate next** — if a `status='upcoming'` season exists with `start_date <= today`, set it to `active`

### Tier Decay Example (50% default)

| Final tier | Final XP | Carried XP | New tier |
|---|---|---|---|
| Elite | 10,000 | 5,000 | Diamond |
| Diamond | 6,000 | 3,000 | Platinum |
| Platinum | 3,500 | 1,750 | Silver |
| Gold | 2,200 | 1,100 | Silver |
| Silver | 1,200 | 600 | Bronze |
| Bronze | 400 | 200 | Bronze |

### API Endpoints

| Method | Path | Auth | Description |
|---|---|---|---|
| `GET` | `/seasons/current` | User | Active season info (name, start, end, days_remaining) |
| `GET` | `/seasons/:id/my-result` | User | User's result for a past season |
| `POST` | `/seasons/:id/end` | Admin | Triggers end-of-season logic |

### Flutter: Season Rewards Screen (hardcoded shell)

- New screen `season_rewards_screen.dart` — shows season name, user's final tier badge, coins awarded, "New season starting" message
- All values hardcoded for now; API wiring deferred
- Route: `/season-rewards` — shown automatically when a season ends (push from notification or on app launch if unseen result exists)

---

## Cross-Cutting Concerns

### Unified XP Award Function

All XP sources (steps, missions, challenges) must go through a single `awardXp(userId, amount, source)` function to ensure:
- Level-up check runs on every award
- `users.xp` and `user_levels.xp` stay in sync
- Level-up coins are never double-awarded

### `users` Table — columns used across layers

| Column | Layer | Purpose |
|---|---|---|
| `xp` | 1, 4 | League-season XP (resets on season end decay) |
| `coin_balance` | 1, 2, 4 | Coin balance |
| `streak_days` | 2 | Current streak count |
| `best_streak_days` | 2, 3 | All-time best streak (for reputation) |
| `partial_day_count` | 2 | Rolling partial-day counter (reset on Full day) |
| `streak_break_date` | 2 | Date of last break (for revive window check) |
| `reputation_score` | 3 | Cached reputation score |
| `reputation_snapshot_prev` | 3 | Previous month's score for delta |
| `reputation_updated_at` | 3 | Last recalculation timestamp |

### `user_levels` Table — lifetime XP (never reset)

| Column | Purpose |
|---|---|
| `user_id` | FK to users |
| `xp` | Cumulative lifetime XP (for levels and reputation) |
| `level` | Current level (1–100) |

---

## Implementation Order

1. **Layer 1 (XP Engine)** — fix mission bug, add unified `awardXp()`, add challenge-win XP in payout job, wire Flutter XP screen
2. **Layer 2 (Streak v2)** — add DB columns, new streak evaluation logic, `/streaks/calendar` endpoint, Flutter calendar widget
3. **Layer 3 (Reputation)** — new `reputation` module, nightly cron, wire Flutter reputation screen
4. **Layer 4 (Seasons)** — create tables, seed Season 1, season-end service, admin endpoint, Flutter shell screen

Each layer is independently deployable. Layers 3 and 4 can be worked in parallel once Layer 1 is complete.
