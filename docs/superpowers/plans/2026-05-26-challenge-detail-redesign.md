# Challenge Detail Redesign — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the challenge detail screen (Design 2 "Split Dashboard") with auto-synced activity, daily missions showing bonus XP, dynamic challenge modes, and a live leaderboard — all data from API with no hardcoding.

**Architecture:** New DB migration adds `mode` to challenges and a `challenge_missions` join table. The API gains a `/leaderboard` endpoint and enriches existing endpoints with missions + prize tiers. The Flutter screen is fully rewritten into a two-state layout (before/after joining) with 60-second polling for live data.

**Tech Stack:** TypeScript/Express + Supabase (Postgres) + Redis (leaderboard sorted set) | Flutter/Riverpod (FutureProvider.family) | Google Fonts (Inter + BigShouldersDisplay)

---

## File Map

| Action | Path | Responsibility |
|--------|------|----------------|
| Create | `stepup-api/migrations/010_challenge_modes_missions.sql` | DB schema changes |
| Modify | `stepup-api/src/types/index.ts` | New TS types for leaderboard + missions |
| Modify | `stepup-api/src/modules/challenges/challenges.service.ts` | Enrich getChallenge, getChallengeProgress, joinChallenge |
| Create | `stepup-api/src/modules/challenges/leaderboard.service.ts` | Leaderboard query logic (isolated) |
| Modify | `stepup-api/src/modules/challenges/challenges.router.ts` | Add GET /:id/leaderboard route |
| Modify | `stepup-api/tests/modules/challenges.test.ts` | Tests for new endpoints + shapes |
| Modify | `stepup/lib/shared/models/challenge.dart` | New model classes + updated Challenge/ChallengeProgress |
| Modify | `stepup/lib/features/challenges/providers/challenges_provider.dart` | challengeLeaderboardProvider |
| Rewrite | `stepup/lib/features/challenges/screens/challenge_detail_screen.dart` | Design 2 before + after states |

---

## Task 1: DB Migration

**Files:**
- Create: `stepup-api/migrations/010_challenge_modes_missions.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- stepup-api/migrations/010_challenge_modes_missions.sql

-- 1. Dynamic challenge mode (individual players compete in all modes)
ALTER TABLE challenges
  ADD COLUMN IF NOT EXISTS mode text NOT NULL DEFAULT 'individual'
    CHECK (mode IN ('individual', 'duo', 'group', 'team'));

-- 2. Link missions to a challenge with bonus XP
CREATE TABLE IF NOT EXISTS challenge_missions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  mission_id   uuid NOT NULL REFERENCES missions(id)   ON DELETE CASCADE,
  bonus_xp     int  NOT NULL DEFAULT 0,
  UNIQUE (challenge_id, mission_id)
);
CREATE INDEX IF NOT EXISTS idx_challenge_missions_cid ON challenge_missions(challenge_id);

-- 3. Accumulate XP earned per user within a challenge (from completing linked missions)
CREATE TABLE IF NOT EXISTS challenge_participant_xp (
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES users(id)      ON DELETE CASCADE,
  xp_earned    int  NOT NULL DEFAULT 0,
  PRIMARY KEY (challenge_id, user_id)
);

-- 4. Snapshot display info at join time so leaderboard names survive profile edits
ALTER TABLE challenge_participants
  ADD COLUMN IF NOT EXISTS display_name text,
  ADD COLUMN IF NOT EXISTS avatar_url   text;
```

- [ ] **Step 2: Run migration against local / dev Supabase**

```bash
# Via Supabase CLI (run from stepup-api/)
npx supabase db push
# OR paste the SQL directly in the Supabase dashboard SQL editor
```

Expected: no errors, four DDL statements succeed.

- [ ] **Step 3: Seed challenge_missions on the existing active challenge(s)**

Open Supabase SQL editor and run (adjust IDs as needed — query first):

```sql
-- Find existing challenge IDs and mission IDs
SELECT id, title FROM challenges WHERE status = 'active' LIMIT 5;
SELECT id, slug, title FROM missions WHERE active = true LIMIT 10;

-- Then link missions to an active challenge (replace UUIDs with real ones)
INSERT INTO challenge_missions (challenge_id, mission_id, bonus_xp)
SELECT
  c.id,
  m.id,
  CASE m.slug
    WHEN 'daily_walk_10k' THEN 50
    WHEN 'daily_walk_5k'  THEN 25
    ELSE 20
  END
FROM challenges c
CROSS JOIN missions m
WHERE c.status = 'active'
  AND m.slug IN ('daily_walk_10k', 'daily_walk_5k', 'daily_gym')
ON CONFLICT DO NOTHING;
```

- [ ] **Step 4: Commit**

```bash
git add stepup-api/migrations/010_challenge_modes_missions.sql
git commit -m "feat: add challenge mode, challenge_missions, participant XP + display snapshot"
```

---

## Task 2: TypeScript Types

**Files:**
- Modify: `stepup-api/src/types/index.ts`

- [ ] **Step 1: Add new interfaces after the existing `ChallengeRow` interface**

Open `stepup-api/src/types/index.ts`. After the `PrizeDistribution` interface add:

```typescript
export interface ChallengeMissionRow {
  id: string;
  challenge_id: string;
  mission_id: string;
  bonus_xp: number;
  // joined from missions table:
  title: string;
  description: string;
  type: 'daily' | 'weekly' | 'seasonal';
  target: number;
  unit: string;
  xp_reward: number;
}

export interface PrizeTier {
  top_percent: number;
  label: string;
  coins: number;
}

export interface LeaderboardEntry {
  rank: number;
  user_id: string;
  display_name: string;
  avatar_url: string | null;
  current: number;
  xp_earned: number;
}

export interface MissionProgress {
  mission_id: string;
  title: string;
  target: number;
  current: number;
  unit: string;
  completed: boolean;
  xp_earned: number;
  total_xp: number;
}
```

Also update `ChallengeRow` to include `mode`:

```typescript
export interface ChallengeRow {
  id: string;
  title: string;
  type: 'free_daily' | 'free_weekly' | 'paid_pool' | 'sponsored' | 'team' | 'city';
  step_goal: number;
  entry_fee: number;
  prize_pool: number;
  max_participants: number;
  start_time: string;
  end_time: string;
  status: 'upcoming' | 'active' | 'ended' | 'paid_out';
  prize_distribution: PrizeDistribution;
  sponsor_name?: string;
  mode: 'individual' | 'duo' | 'group' | 'team';  // ← new
}
```

- [ ] **Step 2: Commit**

```bash
git add stepup-api/src/types/index.ts
git commit -m "feat: add ChallengeMissionRow, PrizeTier, LeaderboardEntry, MissionProgress types"
```

---

## Task 3: Enhance `getChallenge()` — Add Missions + Mode + Prize Tiers

**Files:**
- Modify: `stepup-api/src/modules/challenges/challenges.service.ts`

- [ ] **Step 1: Write the failing test first**

Open `stepup-api/tests/modules/challenges.test.ts`. Update the `getChallenge` mock and add a test:

```typescript
// At the top of the mock, update getChallenge to return missions + mode:
getChallenge: jest.fn().mockResolvedValue({
  id: 'ch-1', title: 'Weekend Warriors', type: 'paid_pool',
  mode: 'individual',
  step_goal: 10000, entry_fee: 5000, prize_pool: 225000,
  status: 'active',
  start_time: new Date().toISOString(),
  end_time: new Date(Date.now() + 86400000).toISOString(),
  max_participants: 100,
  prize_distribution: { platform_fee_percent: 10, tiers: [{ top_percent: 10, share_percent: 90 }] },
  missions: [
    { id: 'm-1', title: 'Walk 10k Steps', bonus_xp: 50, xp_reward: 100, target: 10000, unit: 'steps', type: 'daily', description: '' }
  ],
  prize_tiers: [{ top_percent: 10, label: 'Top 10%', coins: 20 }],
}),

// Add this test in the "GET /challenges/:id" describe block:
it('includes missions and prize_tiers in challenge detail', async () => {
  const res = await request(app).get('/challenges/ch-1');
  expect(res.status).toBe(200);
  expect(res.body.mode).toBe('individual');
  expect(Array.isArray(res.body.missions)).toBe(true);
  expect(res.body.missions[0]).toMatchObject({ bonus_xp: 50, xp_reward: 100 });
  expect(Array.isArray(res.body.prize_tiers)).toBe(true);
});
```

- [ ] **Step 2: Run test to confirm it fails (mock already returns right shape, so this tests the shape contract)**

```bash
cd stepup-api && npx jest tests/modules/challenges.test.ts --no-coverage 2>&1 | tail -20
```

Expected: passes (mock-based), establishes shape contract for future integration.

- [ ] **Step 3: Add helper to parse prize_distribution into prize_tiers array**

In `stepup-api/src/modules/challenges/challenges.service.ts`, add this helper near the top (after imports):

```typescript
function parsePrizeTiers(
  prizePool: number,
  prizeDist: { platform_fee_percent: number; tiers: Array<{ top_percent: number; share_percent: number }> },
): Array<{ top_percent: number; label: string; coins: number }> {
  const net = prizePool * (1 - prizeDist.platform_fee_percent / 100);
  return prizeDist.tiers.map(t => ({
    top_percent: t.top_percent,
    label: t.top_percent <= 1 ? '1st place' : t.top_percent <= 3 ? 'Top 3' : `Top ${t.top_percent}%`,
    coins: Math.floor((net * t.share_percent) / 100 / 100), // paise → coins (÷100)
  }));
}
```

- [ ] **Step 4: Add helper to fetch challenge missions**

In the same file, add after `parsePrizeTiers`:

```typescript
async function fetchChallengeMissions(challengeId: string): Promise<ChallengeMissionRow[]> {
  const { data, error } = await getSupabase()
    .from('challenge_missions')
    .select(`
      id, challenge_id, mission_id, bonus_xp,
      missions ( id, title, description, type, target, unit, xp_reward )
    `)
    .eq('challenge_id', challengeId);
  if (error) return [];
  return (data ?? []).map((row: any) => ({
    id: row.id,
    challenge_id: row.challenge_id,
    mission_id: row.mission_id,
    bonus_xp: row.bonus_xp,
    title: row.missions.title,
    description: row.missions.description,
    type: row.missions.type,
    target: row.missions.target,
    unit: row.missions.unit,
    xp_reward: row.missions.xp_reward,
  }));
}
```

Add `ChallengeMissionRow` to the import from `../../types`:

```typescript
import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { ChallengeRow, ChallengeMissionRow } from '../../types';
```

- [ ] **Step 5: Update `getChallenge()` to attach missions, mode, prize_tiers**

Replace the existing `getChallenge` function body:

```typescript
export async function getChallenge(id: string) {
  const { data, error } = await getSupabase()
    .from('challenges')
    .select('*')
    .eq('id', id)
    .single();
  if (error) throw new Error(error.message);
  const [enriched] = await withParticipantCount([data as ChallengeRow]);
  const missions = await fetchChallengeMissions(id);
  const prizeTiers = parsePrizeTiers(enriched.prize_pool, enriched.prize_distribution);
  return {
    ...enriched,
    missions,
    prize_tiers: prizeTiers,
  };
}
```

- [ ] **Step 6: Run tests**

```bash
cd stepup-api && npx jest tests/modules/challenges.test.ts --no-coverage 2>&1 | tail -20
```

Expected: all tests pass.

- [ ] **Step 7: Commit**

```bash
git add stepup-api/src/modules/challenges/challenges.service.ts \
        stepup-api/src/types/index.ts \
        stepup-api/tests/modules/challenges.test.ts
git commit -m "feat: getChallenge returns missions, mode, and prize_tiers"
```

---

## Task 4: Update `joinChallenge()` — Snapshot Display Info

**Files:**
- Modify: `stepup-api/src/modules/challenges/challenges.service.ts`

- [ ] **Step 1: Write the failing test**

Add to `tests/modules/challenges.test.ts` inside `describe('POST /challenges/:id/join')`:

```typescript
it('calls joinChallenge with the authenticated user id', async () => {
  const { joinChallenge } = require('../../src/modules/challenges/challenges.service');
  await request(app).post('/challenges/ch-1/join');
  expect(joinChallenge).toHaveBeenCalledWith('user-123', 'ch-1');
});
```

- [ ] **Step 2: Run test to confirm it passes (basic shape test)**

```bash
cd stepup-api && npx jest tests/modules/challenges.test.ts --no-coverage 2>&1 | tail -10
```

- [ ] **Step 3: Update `joinChallenge()` to snapshot user profile**

Find the upsert into `challenge_participants` (around line 117). Replace:

```typescript
  const { error: joinErr } = await db
    .from('challenge_participants')
    .upsert(
      { challenge_id: challengeId, user_id: userId },
      { onConflict: 'challenge_id,user_id', ignoreDuplicates: true },
    );
  if (joinErr) throw new Error(joinErr.message);
```

With:

```typescript
  // Snapshot display info so leaderboard names don't break after profile edits
  const { data: userRow } = await db
    .from('users')
    .select('name, avatar_url')
    .eq('id', userId)
    .maybeSingle();

  const { error: joinErr } = await db
    .from('challenge_participants')
    .upsert(
      {
        challenge_id: challengeId,
        user_id: userId,
        display_name: (userRow?.name as string | null) ?? 'Athlete',
        avatar_url: (userRow?.avatar_url as string | null) ?? null,
      },
      { onConflict: 'challenge_id,user_id', ignoreDuplicates: true },
    );
  if (joinErr) throw new Error(joinErr.message);

  // Initialise XP row so leaderboard can sort by XP too
  await db
    .from('challenge_participant_xp')
    .upsert(
      { challenge_id: challengeId, user_id: userId, xp_earned: 0 },
      { onConflict: 'challenge_id,user_id', ignoreDuplicates: true },
    );
```

- [ ] **Step 4: Run tests**

```bash
cd stepup-api && npx jest tests/modules/challenges.test.ts --no-coverage 2>&1 | tail -10
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add stepup-api/src/modules/challenges/challenges.service.ts
git commit -m "feat: snapshot display_name and avatar_url on challenge join"
```

---

## Task 5: Leaderboard Service + Route

**Files:**
- Create: `stepup-api/src/modules/challenges/leaderboard.service.ts`
- Modify: `stepup-api/src/modules/challenges/challenges.router.ts`
- Modify: `stepup-api/tests/modules/challenges.test.ts`

- [ ] **Step 1: Write the failing test**

Add to `tests/modules/challenges.test.ts`:

```typescript
// Add to the mock at top:
// In jest.mock block, add:
//   getLeaderboard: jest.fn().mockResolvedValue({
//     your_rank: 4, total: 142, updated_at: new Date().toISOString(),
//     participants: [
//       { rank: 1, user_id: 'u-1', display_name: 'Alex M.', avatar_url: null, current: 9800, xp_earned: 300 },
//       { rank: 4, user_id: 'user-123', display_name: 'You', avatar_url: null, current: 6200, xp_earned: 150 },
//     ],
//   }),

describe('GET /challenges/:id/leaderboard', () => {
  it('returns leaderboard with your_rank', async () => {
    const res = await request(app).get('/challenges/ch-1/leaderboard');
    expect(res.status).toBe(200);
    expect(typeof res.body.your_rank).toBe('number');
    expect(Array.isArray(res.body.participants)).toBe(true);
    expect(res.body.participants[0]).toMatchObject({ rank: 1, display_name: expect.any(String) });
  });
});
```

Update the mock block at the top of the test file to include `getLeaderboard`:

```typescript
jest.mock('../../src/modules/challenges/challenges.service', () => ({
  listChallenges: jest.fn().mockResolvedValue([/* existing */]),
  getChallenge: jest.fn().mockResolvedValue({/* existing with missions/mode */}),
  joinChallenge: jest.fn().mockResolvedValue({ joined: true, challenge_id: 'ch-1' }),
  listMyChallenges: jest.fn().mockResolvedValue([]),
  getChallengeProgress: jest.fn().mockResolvedValue({ joined: false }),
  getLeaderboard: jest.fn().mockResolvedValue({
    your_rank: 4,
    total: 142,
    updated_at: new Date().toISOString(),
    participants: [
      { rank: 1, user_id: 'u-1', display_name: 'Alex M.', avatar_url: null, current: 9800, xp_earned: 300 },
      { rank: 4, user_id: 'user-123', display_name: 'You', avatar_url: null, current: 6200, xp_earned: 150 },
    ],
  }),
}));
```

- [ ] **Step 2: Run test to confirm it fails (route doesn't exist yet)**

```bash
cd stepup-api && npx jest tests/modules/challenges.test.ts --no-coverage 2>&1 | grep -A 3 "leaderboard"
```

Expected: 404 — route not registered.

- [ ] **Step 3: Create `leaderboard.service.ts`**

Create `stepup-api/src/modules/challenges/leaderboard.service.ts`:

```typescript
import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { LeaderboardEntry } from '../../types';

export async function getLeaderboard(
  challengeId: string,
  requestingUserId: string,
): Promise<{
  your_rank: number | null;
  total: number;
  updated_at: string;
  participants: LeaderboardEntry[];
}> {
  const db = getSupabase();

  // --- 1. Pull all participants with their display info ---
  const { data: participants, error: pErr } = await db
    .from('challenge_participants')
    .select('user_id, display_name, avatar_url')
    .eq('challenge_id', challengeId);
  if (pErr) throw new Error(pErr.message);

  const allParticipants = participants ?? [];
  const total = allParticipants.length;
  if (total === 0) {
    return { your_rank: null, total: 0, updated_at: new Date().toISOString(), participants: [] };
  }

  const userIds = allParticipants.map((p: any) => p.user_id as string);

  // --- 2. Get scores from Redis if available, else fall back to DB ---
  let scores: Record<string, number> = {};
  try {
    const redis = getRedis();
    const redisKey = `leaderboard:challenge:${challengeId}`;
    const card = await redis.zcard(redisKey);
    if (card > 0) {
      // ZREVRANGE with scores — returns [member, score, member, score, ...]
      const raw = await redis.zrevrange(redisKey, 0, -1, 'WITHSCORES');
      for (let i = 0; i < raw.length; i += 2) {
        scores[raw[i]] = parseFloat(raw[i + 1]);
      }
    }
  } catch { /* Redis optional — fall through to DB */ }

  // Fall back to DB step aggregation if Redis was empty
  if (Object.keys(scores).length === 0) {
    const { data: steps } = await db
      .from('user_daily_steps')
      .select('user_id, total_steps')
      .in('user_id', userIds);
    for (const row of steps ?? []) {
      scores[row.user_id] = (scores[row.user_id] ?? 0) + (row.total_steps as number);
    }
  }

  // --- 3. Get XP earned per user in this challenge ---
  const { data: xpRows } = await db
    .from('challenge_participant_xp')
    .select('user_id, xp_earned')
    .eq('challenge_id', challengeId)
    .in('user_id', userIds);
  const xpMap: Record<string, number> = {};
  for (const row of xpRows ?? []) xpMap[row.user_id] = row.xp_earned;

  // --- 4. Build sorted entries ---
  const entries: LeaderboardEntry[] = allParticipants
    .map((p: any) => ({
      rank: 0,
      user_id: p.user_id as string,
      display_name: (p.display_name as string | null) ?? 'Athlete',
      avatar_url: p.avatar_url as string | null,
      current: scores[p.user_id] ?? 0,
      xp_earned: xpMap[p.user_id] ?? 0,
    }))
    .sort((a, b) => b.current - a.current || b.xp_earned - a.xp_earned)
    .map((e, i) => ({ ...e, rank: i + 1 }));

  const yourEntry = entries.find(e => e.user_id === requestingUserId);

  return {
    your_rank: yourEntry?.rank ?? null,
    total,
    updated_at: new Date().toISOString(),
    participants: entries,
  };
}
```

- [ ] **Step 4: Register the route in `challenges.router.ts`**

Open `stepup-api/src/modules/challenges/challenges.router.ts`. Add the import at the top:

```typescript
import { getLeaderboard } from './leaderboard.service';
```

Add the route **before** the `/:id` catch-all GET:

```typescript
challengesRouter.get('/:id/leaderboard', async (req: Request, res: Response) => {
  try {
    const data = await getLeaderboard(req.params['id'] as string, req.user!.id);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});
```

- [ ] **Step 5: Run tests**

```bash
cd stepup-api && npx jest tests/modules/challenges.test.ts --no-coverage 2>&1 | tail -20
```

Expected: all tests pass including the new leaderboard test.

- [ ] **Step 6: Commit**

```bash
git add stepup-api/src/modules/challenges/leaderboard.service.ts \
        stepup-api/src/modules/challenges/challenges.router.ts \
        stepup-api/tests/modules/challenges.test.ts
git commit -m "feat: GET /challenges/:id/leaderboard with Redis + DB fallback"
```

---

## Task 6: Enhance `getChallengeProgress()` — Add Mission Progress

**Files:**
- Modify: `stepup-api/src/modules/challenges/challenges.service.ts`

- [ ] **Step 1: Write the failing test**

Add to `tests/modules/challenges.test.ts`:

```typescript
// Update getChallengeProgress mock to include mission_progress:
getChallengeProgress: jest.fn().mockResolvedValue({
  joined: true,
  current: 6200, goal: 10000, percent: 0.62,
  totalDays: 2, daysPassed: 1, daysLeft: 1, dailyGoal: 5000,
  completedToday: false, dailyCheckins: [true],
  rank: 4, totalParticipants: 142,
  activityType: 'steps', prizePool: 22500,
  mission_progress: [
    {
      mission_id: 'm-1', title: 'Walk 10,000 Steps',
      target: 10000, current: 6200, unit: 'steps',
      completed: false, xp_earned: 0, total_xp: 150,
    }
  ],
}),

// Add test:
describe('GET /challenges/:id/progress', () => {
  it('returns mission_progress array', async () => {
    const res = await request(app).get('/challenges/ch-1/progress');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.mission_progress)).toBe(true);
    expect(res.body.mission_progress[0]).toMatchObject({
      mission_id: expect.any(String),
      total_xp: expect.any(Number),
    });
  });
});
```

- [ ] **Step 2: Run test to confirm it fails**

```bash
cd stepup-api && npx jest tests/modules/challenges.test.ts -t "mission_progress" --no-coverage 2>&1 | tail -10
```

- [ ] **Step 3: Add mission progress computation to `getChallengeProgress()`**

In `challenges.service.ts`, find the `getChallengeProgress` function. Before the final `return` statement, add:

```typescript
  // --- Mission progress for linked challenge missions ---
  const challengeMissions = await fetchChallengeMissions(challengeId);
  const missionProgress: MissionProgress[] = [];

  if (challengeMissions.length > 0 && isStepBased) {
    // For step-based missions: use today's steps as current
    const todaySteps = (() => {
      const todayDate = new Date().toISOString().slice(0, 10);
      if (!isStepBased) return 0;
      // stepMap was built earlier in this function
      return (stepMap as Record<string, number>)[todayDate] ?? 0;
    })();

    for (const m of challengeMissions) {
      const isCompleted = m.type === 'daily'
        ? todaySteps >= m.target
        : current >= m.target;
      missionProgress.push({
        mission_id: m.mission_id,
        title: m.title,
        target: m.target,
        current: m.type === 'daily' ? todaySteps : current,
        unit: m.unit,
        completed: isCompleted,
        xp_earned: isCompleted ? m.xp_reward + m.bonus_xp : 0,
        total_xp: m.xp_reward + m.bonus_xp,
      });
    }
  }
```

Also add the `MissionProgress` import to types:

```typescript
import { ChallengeRow, ChallengeMissionRow, MissionProgress } from '../../types';
```

Update the return statement to include `mission_progress`:

```typescript
  return {
    joined: true,
    current,
    goal: challenge.step_goal,
    percent: Math.min(1, current / Math.max(1, challenge.step_goal)),
    totalDays,
    daysPassed,
    daysLeft: Math.max(0, totalDays - daysPassed),
    dailyGoal,
    completedToday,
    dailyCheckins,
    rank,
    totalParticipants,
    activityType,
    prizePool: challenge.prize_pool,
    mission_progress: missionProgress,
  };
```

**Important:** `stepMap` must be accessible for the mission progress block. Hoist `stepMap` declaration out of the `if (isStepBased)` block so it's in scope:

Find:
```typescript
  if (isStepBased) {
    const { data: stepRows } = ...
    const stepMap: Record<string, number> = {};
```

Replace with:
```typescript
  let stepMap: Record<string, number> = {};
  if (isStepBased) {
    const { data: stepRows } = ...
```

And remove `const stepMap` inside the block (it's now the hoisted `let`).

- [ ] **Step 4: Run all challenge tests**

```bash
cd stepup-api && npx jest tests/modules/challenges.test.ts --no-coverage 2>&1 | tail -20
```

Expected: all pass.

- [ ] **Step 5: Commit**

```bash
git add stepup-api/src/modules/challenges/challenges.service.ts \
        stepup-api/src/types/index.ts \
        stepup-api/tests/modules/challenges.test.ts
git commit -m "feat: getChallengeProgress includes mission_progress per linked challenge mission"
```

---

## Task 7: Flutter Models Update

**Files:**
- Modify: `stepup/lib/shared/models/challenge.dart`

- [ ] **Step 1: Add new model classes at the bottom of the file**

Open `stepup/lib/shared/models/challenge.dart`. Add after the `ChallengeProgress` class:

```dart
class ChallengeMission {
  final String id;
  final String missionId;
  final String title;
  final String description;
  final String type;
  final int target;
  final String unit;
  final int xpReward;
  final int bonusXp;

  const ChallengeMission({
    required this.id,
    required this.missionId,
    required this.title,
    required this.description,
    required this.type,
    required this.target,
    required this.unit,
    required this.xpReward,
    required this.bonusXp,
  });

  int get totalXp => xpReward + bonusXp;

  factory ChallengeMission.fromJson(Map<String, dynamic> j) => ChallengeMission(
    id: j['id'] as String,
    missionId: j['mission_id'] as String,
    title: j['title'] as String,
    description: (j['description'] as String?) ?? '',
    type: (j['type'] as String?) ?? 'daily',
    target: (j['target'] as num).toInt(),
    unit: (j['unit'] as String?) ?? 'steps',
    xpReward: (j['xp_reward'] as num).toInt(),
    bonusXp: (j['bonus_xp'] as num).toInt(),
  );
}

class PrizeTier {
  final int topPercent;
  final String label;
  final int coins;

  const PrizeTier({required this.topPercent, required this.label, required this.coins});

  factory PrizeTier.fromJson(Map<String, dynamic> j) => PrizeTier(
    topPercent: (j['top_percent'] as num).toInt(),
    label: j['label'] as String,
    coins: (j['coins'] as num).toInt(),
  );
}

class MissionProgress {
  final String missionId;
  final String title;
  final int target;
  final int current;
  final String unit;
  final bool completed;
  final int xpEarned;
  final int totalXp;

  const MissionProgress({
    required this.missionId,
    required this.title,
    required this.target,
    required this.current,
    required this.unit,
    required this.completed,
    required this.xpEarned,
    required this.totalXp,
  });

  double get percent => target == 0 ? 0 : (current / target).clamp(0.0, 1.0);

  factory MissionProgress.fromJson(Map<String, dynamic> j) => MissionProgress(
    missionId: j['mission_id'] as String,
    title: j['title'] as String,
    target: (j['target'] as num).toInt(),
    current: (j['current'] as num).toInt(),
    unit: (j['unit'] as String?) ?? 'steps',
    completed: j['completed'] as bool,
    xpEarned: (j['xp_earned'] as num).toInt(),
    totalXp: (j['total_xp'] as num).toInt(),
  );
}

class LeaderboardEntry {
  final int rank;
  final String userId;
  final String displayName;
  final String? avatarUrl;
  final int current;
  final int xpEarned;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.displayName,
    this.avatarUrl,
    required this.current,
    required this.xpEarned,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j) => LeaderboardEntry(
    rank: (j['rank'] as num).toInt(),
    userId: j['user_id'] as String,
    displayName: (j['display_name'] as String?) ?? 'Athlete',
    avatarUrl: j['avatar_url'] as String?,
    current: (j['current'] as num).toInt(),
    xpEarned: (j['xp_earned'] as num).toInt(),
  );
}

class ChallengeLeaderboard {
  final int? yourRank;
  final int total;
  final String updatedAt;
  final List<LeaderboardEntry> participants;

  const ChallengeLeaderboard({
    this.yourRank,
    required this.total,
    required this.updatedAt,
    required this.participants,
  });

  factory ChallengeLeaderboard.fromJson(Map<String, dynamic> j) => ChallengeLeaderboard(
    yourRank: (j['your_rank'] as num?)?.toInt(),
    total: (j['total'] as num).toInt(),
    updatedAt: j['updated_at'] as String,
    participants: (j['participants'] as List)
        .map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}
```

- [ ] **Step 2: Update `Challenge` model to include `mode`, `missions`, `prizeTiers`**

In the `Challenge` class, add fields:

```dart
  final String mode;                    // individual | duo | group | team
  final List<ChallengeMission> missions;
  final List<PrizeTier> prizeTiers;
```

Update the constructor to require them:

```dart
  const Challenge({
    required this.id,
    required this.title,
    required this.type,
    required this.status,
    required this.activityType,
    required this.stepGoal,
    required this.entryFee,
    required this.prizePool,
    required this.participantCount,
    required this.startTime,
    required this.endTime,
    this.maxParticipants,
    this.mode = 'individual',               // ← new with default
    this.missions = const [],               // ← new with default
    this.prizeTiers = const [],             // ← new with default
  });
```

Update `Challenge.fromJson`:

```dart
  factory Challenge.fromJson(Map<String, dynamic> j) => Challenge(
    id: j['id'] as String,
    title: j['title'] as String,
    type: j['type'] as String,
    status: j['status'] as String,
    activityType: (j['activity_type'] as String?) ?? 'steps',
    stepGoal: (j['step_goal'] as num).toInt(),
    entryFee: (j['entry_fee'] as num).toInt(),
    prizePool: (j['prize_pool'] as num).toInt(),
    participantCount: (j['participant_count'] as num?)?.toInt() ?? 0,
    startTime: DateTime.parse(j['start_time'] as String),
    endTime: DateTime.parse(j['end_time'] as String),
    maxParticipants: (j['max_participants'] as num?)?.toInt(),
    mode: (j['mode'] as String?) ?? 'individual',
    missions: (j['missions'] as List? ?? [])
        .map((e) => ChallengeMission.fromJson(e as Map<String, dynamic>))
        .toList(),
    prizeTiers: (j['prize_tiers'] as List? ?? [])
        .map((e) => PrizeTier.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
```

Add `modeLabel` getter:

```dart
  String get modeLabel {
    switch (mode) {
      case 'duo':   return 'Duo';
      case 'group': return 'Group';
      case 'team':  return 'Team';
      default:      return 'Individual';
    }
  }
```

- [ ] **Step 3: Update `ChallengeProgress` to include `missionProgress`**

Add field to `ChallengeProgress`:

```dart
  final List<MissionProgress> missionProgress;
```

Update constructor:

```dart
  const ChallengeProgress({
    // ...existing fields...
    required this.missionProgress,    // ← new
  });
```

Update `ChallengeProgress.fromJson`:

```dart
  factory ChallengeProgress.fromJson(Map<String, dynamic> j) => ChallengeProgress(
    // ...existing fields...
    missionProgress: (j['mission_progress'] as List? ?? [])
        .map((e) => MissionProgress.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
```

- [ ] **Step 4: Verify Flutter compiles**

```bash
cd stepup && flutter analyze lib/shared/models/challenge.dart 2>&1 | tail -20
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add stepup/lib/shared/models/challenge.dart
git commit -m "feat: Flutter models — ChallengeMission, PrizeTier, MissionProgress, LeaderboardEntry, ChallengeLeaderboard"
```

---

## Task 8: Flutter Providers Update

**Files:**
- Modify: `stepup/lib/features/challenges/providers/challenges_provider.dart`

- [ ] **Step 1: Add leaderboard provider**

Open `stepup/lib/features/challenges/providers/challenges_provider.dart`. Add at the bottom:

```dart
final challengeLeaderboardProvider =
    FutureProvider.family<ChallengeLeaderboard, String>((ref, id) async {
  final data = await ApiClient.instance.get('/challenges/$id/leaderboard')
      as Map<String, dynamic>;
  return ChallengeLeaderboard.fromJson(data);
});
```

Add the import at the top (ChallengeLeaderboard is in challenge.dart):

The file already imports `challenge.dart` via `'../../../shared/models/challenge.dart'` — no additional import needed.

- [ ] **Step 2: Verify Flutter compiles**

```bash
cd stepup && flutter analyze lib/features/challenges/providers/ 2>&1 | tail -10
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add stepup/lib/features/challenges/providers/challenges_provider.dart
git commit -m "feat: add challengeLeaderboardProvider"
```

---

## Task 9: Rewrite Challenge Detail Screen — Before-Joining State

**Files:**
- Rewrite: `stepup/lib/features/challenges/screens/challenge_detail_screen.dart`

Replace the entire file content:

- [ ] **Step 1: Write the full screen file**

```dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/models/challenge.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';

class ChallengeDetailScreen extends ConsumerStatefulWidget {
  final String id;
  const ChallengeDetailScreen({required this.id, super.key});
  @override
  ConsumerState<ChallengeDetailScreen> createState() =>
      _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState
    extends ConsumerState<ChallengeDetailScreen> {
  bool _joining = false;
  bool _joined = false;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Refresh live data every 60 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      if (!mounted) return;
      ref.invalidate(challengeProgressProvider(widget.id));
      ref.invalidate(challengeLeaderboardProvider(widget.id));
    });
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _join(Challenge challenge) async {
    setState(() => _joining = true);
    try {
      await ApiClient.instance.post('/challenges/${widget.id}/join', {});
      if (!mounted) return;
      setState(() { _joining = false; _joined = true; });
      ref.invalidate(myChallengesProvider);
      ref.invalidate(challengeProgressProvider(widget.id));
      ref.invalidate(challengeLeaderboardProvider(widget.id));
    } catch (e) {
      if (!mounted) return;
      setState(() => _joining = false);
      final msg = e.toString().toLowerCase();
      if (msg.contains('already') || msg.contains('409')) {
        setState(() => _joined = true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(
            msg.contains('balance') ? 'Insufficient coins to join'
            : msg.contains('full')  ? 'This challenge is full'
            : 'Error joining: $e',
          )),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final challengeAsync = ref.watch(challengeDetailProvider(widget.id));
    final myAsync = ref.watch(myChallengesProvider);
    final alreadyJoined = myAsync.whenOrNull(
            data: (list) => list.any((c) => c.id == widget.id)) ??
        false;
    if (alreadyJoined && !_joined) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _joined = true);
      });
    }

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: challengeAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) =>
              Center(child: Text('$e', style: AppTheme.label(13))),
          data: (challenge) => _joined
              ? _AfterState(
                  challenge: challenge,
                  challengeId: widget.id,
                )
              : _BeforeState(
                  challenge: challenge,
                  joining: _joining,
                  onJoin: () => _join(challenge),
                ),
        ),
      ),
    );
  }
}

// ─────────────────────────── BEFORE STATE ────────────────────────────────

class _BeforeState extends StatelessWidget {
  final Challenge challenge;
  final bool joining;
  final VoidCallback onJoin;

  const _BeforeState({
    required this.challenge,
    required this.joining,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final cfg = challenge.activity;
    final days = challenge.endTime.difference(challenge.startTime).inDays + 1;
    final dateRange = '${_fmt(challenge.startTime)} – ${_fmt(challenge.endTime)}';

    return Column(children: [
      _TopBar(rightWidget: Text('Share', style: AppTheme.label(13, color: AppTheme.ink2))),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Hero gradient card ──
            _HeroCard(
              challenge: challenge,
              cfg: cfg,
              dateRange: dateRange,
              days: days,
            ),
            const SizedBox(height: 12),

            // ── Mode badge ──
            Row(children: [
              _Pill(
                label: challenge.modeLabel,
                color: AppTheme.ink2,
                bg: AppTheme.surface,
              ),
            ]),
            const SizedBox(height: 14),

            // ── Daily Missions (XP differentiator) ──
            if (challenge.missions.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Daily Missions',
                      style: AppTheme.label(11, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.voltLime.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.3)),
                    ),
                    child: Text('Earn bonus XP',
                        style: AppTheme.label(9, color: AppTheme.voltLime)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...challenge.missions.map((m) => _MissionPreviewCard(mission: m)),
              const SizedBox(height: 14),
            ],

            // ── Prize distribution ──
            if (challenge.prizeTiers.isNotEmpty) ...[
              Text('Prize breakdown',
                  style: AppTheme.label(11, color: AppTheme.ink2)
                      .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.4)),
              const SizedBox(height: 8),
              ...challenge.prizeTiers.map((t) => _PrizeTierRow(tier: t,
                  maxCoins: challenge.prizeTiers.map((x) => x.coins).reduce((a, b) => a > b ? a : b))),
              const SizedBox(height: 14),
            ],

            // ── Paid banner ──
            if (challenge.isPaid) ...[
              _PaidBanner(challenge: challenge),
              const SizedBox(height: 10),
            ],

            // ── Participant line ──
            Row(children: [
              const Text('👥', style: TextStyle(fontSize: 14)),
              const SizedBox(width: 6),
              Text(
                '${challenge.participantCount} participants',
                style: AppTheme.label(12, color: AppTheme.ink2),
              ),
            ]),
          ]),
        ),
      ),

      // ── Join CTA ──
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: GestureDetector(
          onTap: joining ? null : onJoin,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: challenge.isPaid ? AppTheme.amber : AppTheme.voltLime,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: joining
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.bg),
                    )
                  : Text(
                      challenge.isPaid
                          ? '🔓 Unlock Now — ${challenge.entryFeeCoins}'
                          : 'Join Challenge →',
                      style: AppTheme.label(15, color: AppTheme.bg)
                          .copyWith(fontWeight: FontWeight.w800),
                    ),
            ),
          ),
        ),
      ),
    ]);
  }

  static String _fmt(DateTime d) =>
      '${_months[d.month - 1]} ${d.day}';
  static const _months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
}

// ─────────────────────────── AFTER STATE ─────────────────────────────────

class _AfterState extends ConsumerWidget {
  final Challenge challenge;
  final String challengeId;

  const _AfterState({required this.challenge, required this.challengeId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(challengeProgressProvider(challengeId));
    final leaderboardAsync = ref.watch(challengeLeaderboardProvider(challengeId));

    return Column(children: [
      _TopBar(
        rightWidget: Row(children: [
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(
              color: Color(0xFF34D399), shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text('Live sync', style: AppTheme.label(10, color: const Color(0xFF34D399))),
        ]),
      ),
      Expanded(
        child: progressAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) =>
              Center(child: Text('$e', style: AppTheme.label(13))),
          data: (progress) {
            if (progress == null || !progress.joined) {
              return const Center(
                child: Text("Not joined yet",
                    style: TextStyle(color: AppTheme.ink2)),
              );
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // ── Title + day count ──
                Text(challenge.title,
                    style: AppTheme.bigNum(20)),
                Text(
                  'Day ${progress.daysPassed} of ${progress.totalDays} · ${progress.daysLeft} day${progress.daysLeft == 1 ? '' : 's'} left',
                  style: AppTheme.label(12, color: AppTheme.ink2),
                ),
                const SizedBox(height: 16),

                // ── Steps hero ──
                _StepsHero(progress: progress, challenge: challenge),
                const SizedBox(height: 12),

                // ── 4-stat row ──
                _StatsRow(progress: progress, challenge: challenge),
                const SizedBox(height: 12),

                // ── Prize threshold ──
                if (challenge.prizeTiers.isNotEmpty)
                  _PrizeThresholdBar(
                    progress: progress,
                    tiers: challenge.prizeTiers,
                  ),
                const SizedBox(height: 12),

                // ── Daily missions progress ──
                if (progress.missionProgress.isNotEmpty) ...[
                  Text('Daily Missions',
                      style: AppTheme.label(11, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  ...progress.missionProgress.map((mp) => _MissionProgressCard(mp: mp)),
                  const SizedBox(height: 12),
                ],

                // ── Live leaderboard ──
                leaderboardAsync.when(
                  loading: () => const SizedBox(
                    height: 40,
                    child: Center(child: CircularProgressIndicator(
                        color: AppTheme.voltLime, strokeWidth: 1.5)),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (lb) => _LiveLeaderboard(lb: lb),
                ),
                const SizedBox(height: 8),

                // ── View full leaderboard ──
                GestureDetector(
                  onTap: () => context.push('/leaderboard'),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Center(
                      child: Text('View full leaderboard →',
                          style: AppTheme.label(12, color: AppTheme.ink2)),
                    ),
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    ]);
  }
}

// ─────────────────────────── SHARED WIDGETS ──────────────────────────────

class _TopBar extends StatelessWidget {
  final Widget rightWidget;
  const _TopBar({required this.rightWidget});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
        ),
        rightWidget,
      ],
    ),
  );
}

class _HeroCard extends StatelessWidget {
  final Challenge challenge;
  final ActivityConfig cfg;
  final String dateRange;
  final int days;

  const _HeroCard({
    required this.challenge,
    required this.cfg,
    required this.dateRange,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cfg.colorA.withValues(alpha: 0.28),
            cfg.colorB.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: cfg.colorA.withValues(alpha: 0.25)),
      ),
      child: Stack(children: [
        Positioned(
          right: 12, bottom: 4,
          child: Text(cfg.emoji,
              style: TextStyle(fontSize: 80,
                  color: Colors.white.withValues(alpha: 0.08))),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Pill(label: challenge.type.toUpperCase(),
                  color: AppTheme.bg, bg: AppTheme.voltLime),
            ]),
            const SizedBox(height: 10),
            Text(challenge.title,
                style: AppTheme.bigNum(22).copyWith(fontStyle: FontStyle.italic),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(dateRange, style: AppTheme.label(11, color: AppTheme.ink2)),
            const SizedBox(height: 12),
            // 3-stat row
            Row(children: [
              _MiniStatBox(label: 'GOAL',    value: challenge.goalLabel),
              const SizedBox(width: 6),
              _MiniStatBox(label: 'PRIZE',   value: challenge.prizePoolCoins,
                  accent: AppTheme.amber),
              const SizedBox(width: 6),
              _MiniStatBox(label: 'DURATION', value: challenge.durationLabel),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _MiniStatBox extends StatelessWidget {
  final String label, value;
  final Color? accent;
  const _MiniStatBox({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: accent != null
            ? accent!.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
            color: accent != null
                ? accent!.withValues(alpha: 0.3)
                : Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(children: [
        Text(label,
            style: AppTheme.label(8, color: AppTheme.ink2)
                .copyWith(letterSpacing: 0.4)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTheme.bigNum(13, color: accent ?? Colors.white)
                .copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color, bg;
  const _Pill({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Text(label,
        style: AppTheme.label(9, color: color)
            .copyWith(fontWeight: FontWeight.w800, letterSpacing: 0.4)),
  );
}

class _MissionPreviewCard extends StatelessWidget {
  final ChallengeMission mission;
  const _MissionPreviewCard({required this.mission});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.border),
    ),
    child: Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(mission.title,
              style: AppTheme.label(12, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text('${mission.target} ${mission.unit}',
              style: AppTheme.label(10, color: AppTheme.ink2)),
        ]),
      ),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppTheme.voltLime.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.4)),
          ),
          child: Text('+${mission.totalXp} XP',
              style: AppTheme.label(10, color: AppTheme.voltLime)
                  .copyWith(fontWeight: FontWeight.w800)),
        ),
        if (mission.bonusXp > 0) ...[
          const SizedBox(height: 3),
          Text('+${mission.bonusXp} bonus',
              style: AppTheme.label(8, color: AppTheme.voltLime.withValues(alpha: 0.7))),
        ],
      ]),
    ]),
  );
}

class _PrizeTierRow extends StatelessWidget {
  final PrizeTier tier;
  final int maxCoins;
  const _PrizeTierRow({required this.tier, required this.maxCoins});

  @override
  Widget build(BuildContext context) {
    final frac = maxCoins == 0 ? 0.0 : (tier.coins / maxCoins).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
          width: 52,
          child: Text(tier.label,
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: frac,
              minHeight: 5,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('+${tier.coins}¢',
            style: AppTheme.label(10, color: AppTheme.voltLime)
                .copyWith(fontWeight: FontWeight.w800)),
      ]),
    );
  }
}

class _PaidBanner extends StatelessWidget {
  final Challenge challenge;
  const _PaidBanner({required this.challenge});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: AppTheme.amber.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: AppTheme.amber.withValues(alpha: 0.25)),
    ),
    child: Row(children: [
      const Icon(Icons.lock_rounded, color: AppTheme.amber, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Paid challenge',
            style: AppTheme.label(12, color: Colors.white)
                .copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text(
          'Entry: ${challenge.entryFeeCoins} · Prize pool: ${challenge.prizePoolCoins}',
          style: AppTheme.label(11, color: AppTheme.ink2),
        ),
      ])),
    ]),
  );
}

class _StepsHero extends StatelessWidget {
  final ChallengeProgress progress;
  final Challenge challenge;
  const _StepsHero({required this.progress, required this.challenge});

  @override
  Widget build(BuildContext context) {
    final pct = (progress.percent * 100).round();
    final remaining = (progress.goal - progress.current).clamp(0, progress.goal);
    final unit = ['gym', 'cycling', 'outdoor'].contains(progress.activityType)
        ? 'sessions'
        : 'steps';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _fmt(progress.current),
              style: AppTheme.bigNum(36, color: Colors.white),
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(unit,
                  style: AppTheme.label(12, color: AppTheme.ink2)),
            ),
            const Spacer(),
            Text('$pct%',
                style: AppTheme.bigNum(22, color: AppTheme.voltLime)),
          ],
        ),
        const SizedBox(height: 4),
        Text('today · ${_fmt(progress.goal)} goal',
            style: AppTheme.label(11, color: AppTheme.ink2)),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress.percent.clamp(0.0, 1.0),
            minHeight: 7,
            backgroundColor: Colors.white.withValues(alpha: 0.08),
            valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
          ),
        ),
        const SizedBox(height: 6),
        Text('$remaining more $unit to hit goal',
            style: AppTheme.label(10, color: AppTheme.ink2)),
      ]),
    );
  }

  static String _fmt(int n) =>
      n >= 1000 ? '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k' : '$n';
}

class _StatsRow extends StatelessWidget {
  final ChallengeProgress progress;
  final Challenge challenge;
  const _StatsRow({required this.progress, required this.challenge});

  @override
  Widget build(BuildContext context) => Row(children: [
    _StatBox(
      label: 'RANK',
      value: progress.rank != null ? '#${progress.rank}' : '—',
      accent: AppTheme.voltLime,
    ),
    const SizedBox(width: 6),
    _StatBox(
      label: 'DAYS LEFT',
      value: '${progress.daysLeft}d',
    ),
    const SizedBox(width: 6),
    _StatBox(
      label: 'STREAK',
      value: '${_streak(progress.dailyCheckins)}🔥',
      accent: AppTheme.voltLime,
    ),
    const SizedBox(width: 6),
    _StatBox(
      label: 'PRIZE',
      value: progress.prizePoolCoins,
      accent: AppTheme.amber,
    ),
  ]);

  static int _streak(List<bool> checkins) {
    var s = 0;
    for (var i = checkins.length - 1; i >= 0; i--) {
      if (!checkins[i]) break;
      s++;
    }
    return s;
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final Color? accent;
  const _StatBox({required this.label, required this.value, this.accent});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        color: accent != null
            ? accent!.withValues(alpha: 0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: accent != null
                ? accent!.withValues(alpha: 0.3)
                : AppTheme.border),
      ),
      child: Column(children: [
        Text(label,
            style: AppTheme.label(8, color: AppTheme.ink2)
                .copyWith(letterSpacing: 0.4)),
        const SizedBox(height: 3),
        Text(value,
            style: AppTheme.bigNum(13, color: accent ?? Colors.white)
                .copyWith(fontWeight: FontWeight.w900),
            textAlign: TextAlign.center),
      ]),
    ),
  );
}

class _PrizeThresholdBar extends StatelessWidget {
  final ChallengeProgress progress;
  final List<PrizeTier> tiers;
  const _PrizeThresholdBar({required this.progress, required this.tiers});

  @override
  Widget build(BuildContext context) {
    // Find the lowest threshold the user qualifies for
    final int totalParticipants = progress.totalParticipants;
    final int? rank = progress.rank;
    final qualifyingTier = rank == null || totalParticipants == 0
        ? null
        : tiers.where((t) {
            final cutoff = (t.topPercent / 100 * totalParticipants).ceil();
            return rank <= cutoff;
          }).fold<PrizeTier?>(null, (best, t) =>
              best == null || t.topPercent < best.topPercent ? t : best);

    final pct = progress.percent.clamp(0.0, 1.0);
    final qualified = qualifyingTier != null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.amber.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Prize threshold',
              style: AppTheme.label(11, color: AppTheme.ink2)),
          Text(
            qualified
                ? 'Earning ${qualifyingTier.coins}¢ ✓'
                : 'Not qualifying yet',
            style: AppTheme.label(11, color: qualified
                ? AppTheme.amber : AppTheme.ink2)
                .copyWith(fontWeight: FontWeight.w700),
          ),
        ]),
        const SizedBox(height: 8),
        Stack(children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.07),
              valueColor: const AlwaysStoppedAnimation(AppTheme.amber),
            ),
          ),
          // Mark the 50% threshold line
          Positioned(
            left: MediaQuery.of(context).size.width * 0.5 - 32 - 1,
            top: -2, bottom: -2,
            child: Container(width: 2,
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(1))),
          ),
        ]),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            rank != null ? '▲ You: #$rank' : 'Your rank: —',
            style: AppTheme.label(9,
                color: qualified ? AppTheme.voltLime : AppTheme.ink2)
                .copyWith(fontWeight: FontWeight.w700),
          ),
          Text('Top 50% threshold',
              style: AppTheme.label(9, color: AppTheme.ink2)),
        ]),
      ]),
    );
  }
}

class _MissionProgressCard extends StatelessWidget {
  final MissionProgress mp;
  const _MissionProgressCard({required this.mp});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 7),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(
      color: AppTheme.surface,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(
          color: mp.completed
              ? AppTheme.voltLime.withValues(alpha: 0.4)
              : AppTheme.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text(mp.title,
              style: AppTheme.label(12, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600)),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: mp.completed
                ? AppTheme.voltLime.withValues(alpha: 0.15)
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: mp.completed
                    ? AppTheme.voltLime.withValues(alpha: 0.5)
                    : AppTheme.border),
          ),
          child: Text(
            mp.completed ? '+${mp.totalXp} XP ✓' : '+${mp.totalXp} XP',
            style: AppTheme.label(10,
                    color: mp.completed ? AppTheme.voltLime : AppTheme.ink2)
                .copyWith(fontWeight: FontWeight.w800),
          ),
        ),
      ]),
      const SizedBox(height: 8),
      ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: mp.percent,
          minHeight: 5,
          backgroundColor: Colors.white.withValues(alpha: 0.07),
          valueColor: AlwaysStoppedAnimation(
              mp.completed ? AppTheme.voltLime : AppTheme.ink2),
        ),
      ),
      const SizedBox(height: 4),
      Text(
        '${mp.current} / ${mp.target} ${mp.unit}',
        style: AppTheme.label(9, color: AppTheme.ink2),
      ),
    ]),
  );
}

class _LiveLeaderboard extends StatelessWidget {
  final ChallengeLeaderboard lb;
  const _LiveLeaderboard({required this.lb});

  @override
  Widget build(BuildContext context) {
    // Show: top 3 + your row (if not already in top 3) + one below you
    final all = lb.participants;
    final yourRank = lb.yourRank;

    final Set<int> showRanks = {1, 2, 3};
    if (yourRank != null) {
      showRanks.add(yourRank);
      if (yourRank + 1 <= all.length) showRanks.add(yourRank + 1);
    }

    final rows = all.where((e) => showRanks.contains(e.rank)).toList()
      ..sort((a, b) => a.rank.compareTo(b.rank));

    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Live standings',
            style: AppTheme.label(11, color: Colors.white)
                .copyWith(fontWeight: FontWeight.w700)),
        Text('${lb.total} players',
            style: AppTheme.label(10, color: AppTheme.ink2)),
      ]),
      const SizedBox(height: 8),
      Container(
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Column(
          children: rows.map((e) {
            final isYou = e.rank == yourRank;
            return _LbRow(entry: e, isYou: isYou);
          }).toList(),
        ),
      ),
    ]);
  }
}

class _LbRow extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isYou;
  const _LbRow({required this.entry, required this.isYou});

  @override
  Widget build(BuildContext context) {
    final rankEmoji = entry.rank == 1
        ? '🏆'
        : entry.rank == 2
            ? '🥈'
            : entry.rank == 3
                ? '🥉'
                : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: isYou ? AppTheme.voltLime.withValues(alpha: 0.06) : null,
        border: Border(
          top: BorderSide(
              color: isYou
                  ? AppTheme.voltLime.withValues(alpha: 0.15)
                  : AppTheme.border,
              width: 0.5),
        ),
      ),
      child: Row(children: [
        SizedBox(
          width: 28,
          child: rankEmoji != null
              ? Text(rankEmoji, style: const TextStyle(fontSize: 14))
              : Text('#${entry.rank}',
                  style: AppTheme.label(11, color: AppTheme.ink2)
                      .copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            isYou ? 'You' : entry.displayName,
            style: AppTheme.label(12,
                    color: isYou ? AppTheme.voltLime : Colors.white)
                .copyWith(fontWeight: isYou ? FontWeight.w700 : FontWeight.w500),
          ),
        ),
        if (entry.xpEarned > 0) ...[
          Text('+${entry.xpEarned}XP',
              style: AppTheme.label(9, color: AppTheme.voltLime)
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
        ],
        Text(
          entry.current >= 1000
              ? '${(entry.current / 1000).toStringAsFixed(1)}k'
              : '${entry.current}',
          style: AppTheme.label(12,
                  color: isYou ? AppTheme.voltLime : AppTheme.ink2)
              .copyWith(fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}
```

- [ ] **Step 2: Verify Flutter analyzes clean**

```bash
cd stepup && flutter analyze lib/features/challenges/screens/challenge_detail_screen.dart 2>&1 | tail -20
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add stepup/lib/features/challenges/screens/challenge_detail_screen.dart
git commit -m "feat: rewrite challenge_detail_screen — Design 2 before/after states, missions, leaderboard, live sync"
```

---

## Task 10: Build + Smoke Test

- [ ] **Step 1: Run full API test suite**

```bash
cd stepup-api && npx jest --no-coverage 2>&1 | tail -30
```

Expected: all tests pass.

- [ ] **Step 2: Flutter full analyze**

```bash
cd stepup && flutter analyze 2>&1 | grep -E "error|warning" | head -20
```

Expected: no errors. Warnings about deprecated APIs are acceptable.

- [ ] **Step 3: Build iOS for device**

```bash
cd stepup && flutter build ios --release 2>&1 | tail -20
```

Expected: Build complete. No compilation errors.

- [ ] **Step 4: Install on device**

```bash
xcrun devicectl device install app --device 00008120-001E6C6C0101A01E \
  /Users/harsha/StepUp/stepup/build/ios/iphoneos/Runner.app
```

- [ ] **Step 5: Manual smoke test — Before state**

Open the Challenges tab → tap any active challenge.

Verify:
- [ ] Hero card shows title, date, correct emoji
- [ ] Mode badge shows (e.g. "Individual")
- [ ] "Daily Missions · Earn bonus XP" section appears with "+X XP" chips
- [ ] Prize breakdown bars render (if prize_tiers non-empty)
- [ ] Paid banner shows for paid challenges
- [ ] Participant count shows from API
- [ ] Join button is lime (free) or gold (paid)
- [ ] No "Check in today" button anywhere

- [ ] **Step 6: Manual smoke test — After state**

Join a challenge (or use one already joined). Tap it again.

Verify:
- [ ] "● Live sync" green badge in top right
- [ ] Step count shows (big number from API)
- [ ] Progress bar fills correctly
- [ ] 4-stat row: rank, days left, streak, prize pool
- [ ] Prize threshold bar renders
- [ ] Mission progress cards show with progress bars and XP chips
- [ ] Live leaderboard shows 4-5 rows; your row highlighted in lime
- [ ] "View full leaderboard →" ghost button at bottom
- [ ] No "Check in today" button

- [ ] **Step 7: Final commit**

```bash
git add -A
git commit -m "feat: challenge detail redesign — Design 2, missions XP, live leaderboard, dynamic mode"
```

---

## Self-Review

**Spec coverage check:**
- ✅ Design 2 "Split Dashboard" — Tasks 9
- ✅ No manual check-in — removed in Task 9, replaced with live sync badge
- ✅ Daily missions as XP differentiator — Tasks 3, 6, 9 (before + after states)
- ✅ Dynamic challenge mode field — Task 1 (migration), Task 7 (Flutter model + modeLabel getter)
- ✅ All data from API, no hardcoding — all providers hit real endpoints
- ✅ Multiple users joining visible — leaderboard endpoint + participant_count (Task 5)
- ✅ Live leaderboard for all participants — Task 5 (leaderboard.service.ts)
- ✅ Display name snapshot on join — Task 4
- ✅ Polling for live updates — Task 9 (60s Timer.periodic in initState)
- ✅ Prize threshold bar — Task 9 (_PrizeThresholdBar widget)
- ✅ Prize distribution breakdown (before state) — Task 9 (_PrizeTierRow)

**No placeholders found.**

**Type consistency check:**
- `ChallengeMission.fromJson` reads `mission_id`, `xp_reward`, `bonus_xp` — matches API response from `fetchChallengeMissions` (Task 3)
- `MissionProgress.fromJson` reads `mission_id`, `total_xp`, `xp_earned` — matches API return in Task 6
- `ChallengeLeaderboard.fromJson` reads `your_rank`, `total`, `participants` — matches `getLeaderboard` return shape (Task 5)
- `LeaderboardEntry.fromJson` reads `user_id`, `display_name`, `current`, `xp_earned` — matches Task 5 `LeaderboardEntry` TS type
- `_StatsRow._streak` reads `progress.dailyCheckins` — exists on `ChallengeProgress` model
- `_PrizeThresholdBar` reads `progress.totalParticipants`, `progress.rank` — both exist on `ChallengeProgress`
