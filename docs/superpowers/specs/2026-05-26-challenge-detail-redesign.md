# Challenge Detail Screen — Redesign + Full Implementation

**Date:** 2026-05-26  
**Design:** Design 2 "Split Dashboard" (selected by user)  
**Scope:** Flutter screen + Express API + DB migration  

---

## Goals

1. Redesign `challenge_detail_screen.dart` with Design 2 (Split Dashboard) for both before-joining and after-joining states.
2. Remove all manual check-in — activity syncs automatically from HealthKit/Health Connect.
3. Surface daily missions as an XP differentiator shown to all participants.
4. Support dynamic challenge modes: `individual`, `duo`, `group`, `team`.
5. Live leaderboard visible to everyone — all data from API, zero hardcoding.
6. Multiple users joining is reflected in participant counts and standings immediately.

---

## Design: Split Dashboard (Design 2)

### Before Joining

```
┌─────────────────────────────────┐
│ ← back                    Share │
│ ┌────── hero gradient ─────────┐ │
│ │ [DAILY] tag     👟 emoji     │ │
│ │ Daily Step Sprint            │ │
│ │ May 25 – May 26              │ │
│ │ [10k goal] [50¢ prize] [2d]  │ │
│ └──────────────────────────────┘ │
│                                  │
│ MODE: Individual / Group / Duo   │
│                                  │
│ DAILY MISSIONS (XP differentiator)│
│ ┌──────────────────────────────┐ │
│ │ 👟 Walk 10k Steps  +100 XP   │ │
│ │    +50 bonus XP in challenge │ │
│ ├──────────────────────────────┤ │
│ │ 💧 Log 2L Water    +50 XP   │ │
│ │    +25 bonus XP in challenge │ │
│ └──────────────────────────────┘ │
│                                  │
│ PRIZE DISTRIBUTION               │
│ 🥇 1st  ████████████ 20¢        │
│ 🥈 2nd  ████████     15¢        │
│ 🥉 3rd  ████         10¢        │
│ Top 50% ██           5¢         │
│                                  │
│ 😎🏃💪🎯 +138 more joined       │
│                                  │
│ [🔒 Unlock Now — 5¢]            │
└─────────────────────────────────┘
```

### After Joining

```
┌─────────────────────────────────┐
│ ←                 ● Live sync   │
│ Daily Step Sprint  Day 1 of 2   │
│                                  │
│  6,200  steps today              │
│  ████████████░░░░░░ 62% of 10k  │
│  3,800 steps remaining today    │
│                                  │
│ [#4 Rank][1d Left][1🔥][50¢]   │
│                                  │
│ Prize threshold (top 50%)        │
│ ████████████▲░░░░│ You qualify ✓│
│                                  │
│ DAILY MISSIONS                   │
│ 👟 Walk 10k  ████░░░  62%  +150XP│
│ 💧 2L Water  ██████ done +75XP  │
│                                  │
│ LIVE STANDINGS · 142 players     │
│ 🥇 Alex M.        9,800         │
│ 🥈 Sarah K.       8,400         │
│ 🥉 Jordan L.      7,100         │
│ ⭐ You            6,200  ←── you│
│  5  Maya R.       5,800         │
│                                  │
│ [View full leaderboard →]        │
└─────────────────────────────────┘
```

---

## Database Changes

### Migration: `010_challenge_modes_missions.sql`

```sql
-- 1. Add mode to challenges
ALTER TABLE challenges
  ADD COLUMN IF NOT EXISTS mode text NOT NULL DEFAULT 'individual'
    CHECK (mode IN ('individual', 'duo', 'group', 'team'));

-- 2. Link specific missions to a challenge (with bonus XP)
CREATE TABLE IF NOT EXISTS challenge_missions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  mission_id   uuid NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  bonus_xp     int  NOT NULL DEFAULT 0,
  UNIQUE (challenge_id, mission_id)
);
CREATE INDEX IF NOT EXISTS idx_challenge_missions_cid ON challenge_missions(challenge_id);

-- 3. Track per-user XP earned within a challenge (from missions)
CREATE TABLE IF NOT EXISTS challenge_participant_xp (
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES users(id)      ON DELETE CASCADE,
  xp_earned    int  NOT NULL DEFAULT 0,
  PRIMARY KEY (challenge_id, user_id)
);

-- 4. Store participant display info snapshot (name + avatar at join time)
ALTER TABLE challenge_participants
  ADD COLUMN IF NOT EXISTS display_name text,
  ADD COLUMN IF NOT EXISTS avatar_url   text;
```

### Existing Tables Used (no changes)

| Table | What we read |
|---|---|
| `challenges` | id, title, mode, step_goal, entry_fee, prize_pool, start_time, end_time, status, prize_distribution, sponsor_name (= activity_type) |
| `challenge_participants` | user_id, challenge_id, display_name, avatar_url |
| `challenge_missions` | bonus_xp per mission per challenge |
| `missions` | title, xp_reward, target, unit |
| `user_missions` | per-user progress on each mission |
| `user_daily_steps` | daily step counts for progress |
| `users` | display_name, avatar_url (populated at join) |
| Redis `leaderboard:challenge:{id}` | sorted set for rank |

---

## API Changes

### Enhanced `GET /challenges/:id`

Adds `mode`, `missions[]`, and full `prize_tiers[]` to existing response.

**New fields in response:**
```jsonc
{
  // ...existing fields...
  "mode": "individual",          // individual | duo | group | team
  "missions": [
    {
      "id": "uuid",
      "title": "Walk 10,000 Steps",
      "description": "Reach 10k steps today",
      "xp_reward": 100,          // base XP from missions table
      "bonus_xp": 50,            // extra XP for doing it within this challenge
      "target": 10000,
      "unit": "steps",
      "type": "daily"
    }
  ],
  "prize_tiers": [               // parsed from prize_distribution column
    { "top_percent": 10, "label": "Top 10%", "coins": 20 },
    { "top_percent": 50, "label": "Top 50%", "coins": 5 }
  ],
  "participant_count": 142       // already exists
}
```

### New `GET /challenges/:id/leaderboard`

Returns full live standings with display names.

**Response:**
```jsonc
{
  "your_rank": 4,         // null if not joined
  "total": 142,
  "updated_at": "2026-05-26T10:42:00Z",
  "participants": [
    {
      "rank": 1,
      "user_id": "uuid",
      "display_name": "Alex M.",
      "avatar_url": null,
      "current": 9800,          // steps or sessions
      "xp_earned": 300          // from challenge_participant_xp
    }
  ]
}
```

**Implementation:** Read all participants from Redis sorted set (`leaderboard:challenge:{id}`). Fall back to DB (`user_daily_steps` aggregate) if Redis is empty. Join with `challenge_participants` for display names.

### Enhanced `GET /challenges/:id/progress`

Adds `mission_progress[]` to existing response.

**New fields:**
```jsonc
{
  // ...existing fields (current, goal, percent, rank, etc.)...
  "mission_progress": [
    {
      "mission_id": "uuid",
      "title": "Walk 10,000 Steps",
      "target": 10000,
      "current": 6200,
      "unit": "steps",
      "completed": false,
      "xp_earned": 0,            // 0 until completed
      "total_xp": 150            // xp_reward + bonus_xp
    }
  ]
}
```

### `POST /challenges/:id/join` — Snapshot display info

When joining, snapshot `display_name` and `avatar_url` from `users` table into `challenge_participants` so leaderboard always has names even if profile changes.

---

## Flutter Changes

### New Models (in `shared/models/challenge.dart`)

```dart
class ChallengeMission {
  final String id, title, unit;
  final int xpReward, bonusXp, target;
  final String type; // daily | weekly
}

class MissionProgress {
  final String missionId, title, unit;
  final int target, current, totalXp, xpEarned;
  final bool completed;
}

class LeaderboardEntry {
  final int rank;
  final String userId, displayName;
  final String? avatarUrl;
  final int current, xpEarned;
}

class ChallengeLeaderboard {
  final int? yourRank;
  final int total;
  final List<LeaderboardEntry> participants;
}
```

**Updated `Challenge` model** — add:
- `mode: String` (individual/duo/group/team)
- `missions: List<ChallengeMission>`
- `prizeTiers: List<PrizeTier>` (top_percent, label, coins)

**Updated `ChallengeProgress` model** — add:
- `missionProgress: List<MissionProgress>`

### New Provider

```dart
// In challenges_provider.dart
final challengeLeaderboardProvider = FutureProvider.family<ChallengeLeaderboard, String>(
  (ref, id) async { ... GET /challenges/$id/leaderboard ... }
);
```

### Screen Rewrite: `challenge_detail_screen.dart`

Single screen, two states based on `joined` bool:

**State detection:** `myChallengesProvider` already tells us if joined. `challengeProgressProvider` returns `{joined: false}` if not joined.

**Before-joining layout** (widgets in order):
1. `_TopBar` — back + Share
2. `_HeroStrip` — gradient card with emoji, type pill, title, date, 3-stat row (goal/prize/duration), mode badge
3. `_MissionsSection` — "Daily Missions · Earn bonus XP" header + mission cards showing base XP + bonus XP chip
4. `_PrizeDistribution` — visual bar rows from `challenge.prizeTiers`
5. `_ParticipantsLine` — stacked avatars + count
6. `_PaidBanner` — if `challenge.isPaid`
7. `_JoinCTA` — primary button (lime or gold)

**After-joining layout** (widgets in order):
1. `_TopBar` — back + green "● Live sync" badge
2. Title + "Day X of Y" subtitle
3. `_StepsHero` — big step count + % label + linear progress bar + "X steps remaining"
4. `_StatsRow` — 4 boxes: rank, days left, streak, prize
5. `_PrizeThreshold` — bar showing your position vs prize cutoff
6. `_MissionsProgress` — each challenge mission with progress bar + XP earned
7. `_LiveLeaderboard` — top 3 + your row highlighted + neighbor below
8. Ghost button "View full leaderboard →" → push to existing leaderboard screen

**No check-in button anywhere.**

### Polling

Progress and leaderboard auto-refresh every 60 seconds using `ref.invalidate` + `Timer.periodic` while screen is mounted. This keeps standings live without websockets.

---

## Implementation Order

1. Write DB migration `010_challenge_modes_missions.sql`
2. Seed a few challenge_missions rows on existing active challenges
3. Update `challenges.service.ts` — `getChallenge()` joins missions, `getChallengeProgress()` adds mission_progress
4. Add `challengesRouter.get('/:id/leaderboard', ...)` + leaderboard service function
5. Update `POST /:id/join` to snapshot display_name/avatar_url
6. Update Flutter `Challenge` model + `ChallengeProgress` model
7. Add `challengeLeaderboardProvider`
8. Rewrite `challenge_detail_screen.dart` — before state
9. Rewrite `challenge_detail_screen.dart` — after state
10. Wire 60-second polling for live updates

---

## Out of Scope (this spec)

- Push notifications when someone overtakes you (future)
- Group/team challenge grouping logic (layout exists, team formation is a separate feature)
- Real-time websocket (polling at 60s is sufficient for now)
