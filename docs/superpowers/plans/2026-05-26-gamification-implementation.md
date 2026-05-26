# Gamification Overhaul Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire XP, Levels, Streak calendar, Fitness Reputation, and Seasons end-to-end from real API data, fixing existing bugs and adding missing logic.

**Architecture:** 4 independent layers executed in order. Layer 1 (XP Engine) is foundational — all later layers call the unified `awardXp()` function it introduces. Layers 2–4 add new DB columns, endpoints, and Flutter screens without breaking existing behaviour.

**Tech Stack:** Node.js + TypeScript (Express + Supabase) for API; Flutter + Riverpod (FutureProvider pattern) for mobile. No test framework exists — verification is via curl against `localhost:3000` and manual Flutter hot-reload checks.

**Get a test JWT:** In the Flutter app, open DevTools Network tab, copy the `Authorization: Bearer …` header from any API call. Save as `export TOKEN=<value>` in your shell.

---

## File Map

### Created
- `stepup-api/src/modules/reputation/reputation.service.ts`
- `stepup-api/src/modules/reputation/reputation.router.ts`
- `stepup-api/src/modules/seasons/seasons.service.ts`
- `stepup-api/src/modules/seasons/seasons.router.ts`
- `stepup/lib/features/profile/providers/xp_level_provider.dart`
- `stepup/lib/features/profile/providers/reputation_provider.dart`
- `stepup/lib/features/streaks/providers/streak_calendar_provider.dart`
- `stepup/lib/features/seasons/screens/season_rewards_screen.dart`
- `stepup/lib/shared/models/xp_level.dart`
- `stepup/lib/shared/models/reputation.dart`
- `stepup/lib/shared/models/streak_calendar_day.dart`

### Modified
- `stepup-api/src/modules/steps/xp.service.ts` — rewrite with unified `awardXp()`
- `stepup-api/src/modules/missions/missions.service.ts` — fix broken XP award
- `stepup-api/src/modules/challenges/payout.job.ts` — add challenge-win XP
- `stepup-api/src/modules/streaks/streaks.service.ts` — add `evaluateStreak`, calendar query, fix revive window
- `stepup-api/src/modules/streaks/streaks.router.ts` — add `/calendar` route
- `stepup-api/src/modules/steps/steps.service.ts` — hook `evaluateStreak` on sync
- `stepup-api/src/app.ts` — register reputation + seasons routers
- `stepup-api/src/index.ts` — register nightly reputation cron
- `stepup/lib/features/profile/screens/xp_level_screen.dart` — replace hardcoded with provider
- `stepup/lib/features/profile/screens/reputation_screen.dart` — replace hardcoded with provider
- `stepup/lib/features/streaks/screens/streak_screen.dart` — add calendar widget
- `stepup/lib/core/router.dart` — add `/season-rewards` route

---

## Layer 1 — XP Engine

---

### Task 1: Rewrite xp.service.ts with unified awardXp

**Files:**
- Modify: `stepup-api/src/modules/steps/xp.service.ts`

- [ ] **Step 1: Replace the entire file**

```typescript
// stepup-api/src/modules/steps/xp.service.ts
import { getSupabase } from '../../lib/supabase';

const DAILY_STEP_GOAL = 10_000;
export { DAILY_STEP_GOAL };

const LEVEL_TITLES: Record<number, string> = {
  1: 'Walker', 10: 'Mover', 20: 'Challenger', 35: 'Athlete', 50: 'Elite', 75: 'Legend', 100: 'Immortal',
};

function getLevelTitle(level: number): string {
  for (const bp of [100, 75, 50, 35, 20, 10, 1]) {
    if (level >= bp) return LEVEL_TITLES[bp];
  }
  return 'Walker';
}

export function xpForNextLevel(level: number): number {
  return Math.floor(1000 * Math.pow(1.15, level - 1));
}

export async function awardXp(userId: string, amount: number) {
  if (amount <= 0) return;
  const db = getSupabase();

  // Upsert user_levels row
  const { data: row } = await db
    .from('user_levels')
    .select('xp, level')
    .eq('user_id', userId)
    .maybeSingle();

  let { xp = 0, level = 1 } = row ?? {};
  const newXp = xp + amount;

  // Process level-ups
  let currentLevel = level;
  let tempXp = newXp;
  while (tempXp >= xpForNextLevel(currentLevel)) {
    currentLevel++;
    const coinReward = currentLevel * 10;
    // Award level-up coins (fire-and-forget, non-blocking)
    db.rpc('increment_coins', { uid: userId, amount: coinReward }).catch(() => {});
  }

  // Update user_levels
  await db.from('user_levels').upsert(
    { user_id: userId, xp: newXp, level: currentLevel, title: getLevelTitle(currentLevel) },
    { onConflict: 'user_id' },
  );

  // Keep users.xp in sync for league calculations
  await db.from('users').update({ xp: newXp }).eq('id', userId);
}

// Thin wrapper — keeps steps.service.ts working without changes
export async function awardStepXp(userId: string, steps: number) {
  const xp = Math.floor(steps / 1000) * 10;
  await awardXp(userId, xp);
}

// League recalc — called by the weekly cron in index.ts
const LEAGUE_THRESHOLDS = [
  { league: 'elite',    min_weekly_xp: 4000 },
  { league: 'gold',     min_weekly_xp: 1500 },
  { league: 'silver',   min_weekly_xp: 500  },
  { league: 'bronze',   min_weekly_xp: 0    },
];

export async function recalculateLeagues() {
  const db = getSupabase();
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  const since = sevenDaysAgo.toISOString().slice(0, 10);

  const { data: weeklySteps } = await db
    .from('user_daily_steps')
    .select('user_id, total_steps')
    .gte('date', since);

  const xpByUser: Record<string, number> = {};
  for (const row of weeklySteps ?? []) {
    xpByUser[row.user_id] = (xpByUser[row.user_id] ?? 0) + Math.floor(row.total_steps / 1000) * 10;
  }

  const { data: users } = await db.from('users').select('id');
  for (const user of users ?? []) {
    const weeklyXp = xpByUser[user.id] ?? 0;
    const league = LEAGUE_THRESHOLDS.find(t => weeklyXp >= t.min_weekly_xp)?.league ?? 'bronze';
    await db.from('users').update({ league }).eq('id', user.id);
  }
}
```

- [ ] **Step 2: Verify TypeScript compiles**

```bash
cd /Users/harsha/StepUp/stepup-api && npx tsc --noEmit
```
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add stepup-api/src/modules/steps/xp.service.ts
git commit -m "feat: unified awardXp with level-up coin rewards"
```

---

### Task 2: Fix broken mission XP award

**Files:**
- Modify: `stepup-api/src/modules/missions/missions.service.ts`

- [ ] **Step 1: Add import for awardXp at the top of the file**

Find the existing import block (it only imports `getSupabase`). Add:
```typescript
import { awardXp } from '../steps/xp.service';
```

- [ ] **Step 2: Replace the broken `awardMissionReward` function**

Find and replace the entire `awardMissionReward` function (it currently uses `db.rpc` inside `update`):

```typescript
async function awardMissionReward(
  userId: string,
  coins: number,
  xp: number,
  db: ReturnType<typeof getSupabase>
) {
  if (coins > 0) {
    await db.rpc('increment_coins', { uid: userId, amount: coins });
  }
  if (xp > 0) {
    await awardXp(userId, xp);
  }
}
```

- [ ] **Step 3: Verify TypeScript compiles**

```bash
cd /Users/harsha/StepUp/stepup-api && npx tsc --noEmit
```
Expected: no errors

- [ ] **Step 4: Commit**

```bash
git add stepup-api/src/modules/missions/missions.service.ts
git commit -m "fix: mission XP award now correctly calls awardXp"
```

---

### Task 3: Award XP on challenge completion

**Files:**
- Modify: `stepup-api/src/modules/challenges/payout.job.ts`

- [ ] **Step 1: Add import for awardXp**

Add at the top of payout.job.ts, after existing imports:
```typescript
import { awardXp } from '../steps/xp.service';
```

- [ ] **Step 2: Add XP award helper function**

Add this function before `processPayout`:

```typescript
function getChallengeXp(
  challenge: { entry_fee: number; start_time: string; end_time: string },
  rankFromTop: number,
  totalParticipants: number,
): number {
  const isFree = challenge.entry_fee === 0;
  const durationDays = Math.round(
    (new Date(challenge.end_time).getTime() - new Date(challenge.start_time).getTime()) / 86_400_000,
  );
  if (isFree) return durationDays <= 1 ? 50 : 150;
  // Paid: top 10% gets 400, top 50% gets 200, rest get 50 participation XP
  const topPercent = rankFromTop / Math.max(totalParticipants, 1);
  if (topPercent <= 0.10) return 400;
  if (topPercent <= 0.50) return 200;
  return 50;
}
```

- [ ] **Step 3: Call XP award inside the winner loop**

Inside `processPayout`, find the winner loop (`for (let rank = 0; rank < tierWinners.length; rank++)`). Add the XP award call immediately after the `notifyChallengePayout` line:

```typescript
      // Award XP based on challenge type and rank
      const xpAmount = getChallengeXp(challenge, prevCutoff - tierWinners.length + rank + 1, ranked.length);
      awardXp(winner.userId, xpAmount).catch(() => {});
```

- [ ] **Step 4: Also award participation XP to non-winning participants (optional, 50 XP)**

After the tier loop (after `walletInserts` is fully built), add:

```typescript
  // Award 50 XP participation to everyone not already awarded above
  const winnersSet = new Set(walletInserts.map(w => w.user_id));
  for (const participant of ranked) {
    if (!winnersSet.has(participant.userId)) {
      awardXp(participant.userId, 50).catch(() => {});
    }
  }
```

- [ ] **Step 5: Verify TypeScript compiles**

```bash
cd /Users/harsha/StepUp/stepup-api && npx tsc --noEmit
```

- [ ] **Step 6: Commit**

```bash
git add stepup-api/src/modules/challenges/payout.job.ts
git commit -m "feat: award XP on challenge completion (win + participation)"
```

---

### Task 4: Create Flutter XP level model and provider

**Files:**
- Create: `stepup/lib/shared/models/xp_level.dart`
- Create: `stepup/lib/features/profile/providers/xp_level_provider.dart`

- [ ] **Step 1: Create the XpLevel model**

```dart
// stepup/lib/shared/models/xp_level.dart
class XpLevel {
  final int xp, level, xpForNextLevel, xpInCurrentLevel, xpNeeded;
  final String title;

  const XpLevel({
    required this.xp,
    required this.level,
    required this.xpForNextLevel,
    required this.xpInCurrentLevel,
    required this.xpNeeded,
    required this.title,
  });

  factory XpLevel.fromJson(Map<String, dynamic> j) => XpLevel(
        xp: (j['xp'] as num? ?? 0).toInt(),
        level: (j['level'] as num? ?? 1).toInt(),
        xpForNextLevel: (j['xp_for_next_level'] as num? ?? 1000).toInt(),
        xpInCurrentLevel: (j['xp_in_current_level'] as num? ?? 0).toInt(),
        xpNeeded: (j['xp_needed'] as num? ?? 1000).toInt(),
        title: j['title'] as String? ?? 'Walker',
      );
}
```

- [ ] **Step 2: Create the provider**

```dart
// stepup/lib/features/profile/providers/xp_level_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/xp_level.dart';

final xpLevelProvider = FutureProvider<XpLevel>((ref) async {
  final data = await ApiClient.instance.get('/xp') as Map<String, dynamic>;
  return XpLevel.fromJson(data);
});
```

- [ ] **Step 3: Commit**

```bash
git add stepup/lib/shared/models/xp_level.dart stepup/lib/features/profile/providers/xp_level_provider.dart
git commit -m "feat: XpLevel model and xpLevelProvider"
```

---

### Task 5: Wire XP level screen to real API

**Files:**
- Modify: `stepup/lib/features/profile/screens/xp_level_screen.dart`

- [ ] **Step 1: Replace the entire screen with API-driven version**

```dart
// stepup/lib/features/profile/screens/xp_level_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/xp_level_provider.dart';
import '../../../shared/models/xp_level.dart';
import '../../../core/theme.dart';

class XpLevelScreen extends ConsumerWidget {
  const XpLevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(xpLevelProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) => Center(child: Text('Error: $e', style: AppTheme.label(13, color: AppTheme.ink2))),
          data: (xp) => _XpBody(xp: xp),
        ),
      ),
    );
  }
}

class _XpBody extends StatelessWidget {
  final XpLevel xp;
  const _XpBody({required this.xp});

  @override
  Widget build(BuildContext context) {
    final progress = xp.xpInCurrentLevel / xp.xpForNextLevel.clamp(1, double.maxFinite).toInt();
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
              ),
              Text('LV ${xp.level} → ${xp.level + 1}',
                  style: AppTheme.label(12, color: AppTheme.ink2)),
            ],
          ),
          const SizedBox(height: 16),
          Text('LEVEL', style: AppTheme.bigNum(22).copyWith(letterSpacing: 0.5)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: LinearGradient(colors: [
                AppTheme.voltLime.withValues(alpha: 0.10),
                AppTheme.amber.withValues(alpha: 0.04),
              ]),
            ),
            child: Row(children: [
              Container(
                width: 70, height: 70,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(colors: [AppTheme.voltLime, Color(0x33D4FF3A)]),
                ),
                child: Center(child: Text('${xp.level}', style: AppTheme.bigNum(32, color: AppTheme.bg))),
              ),
              const SizedBox(width: 16),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(xp.title.toUpperCase(),
                    style: AppTheme.bigNum(20, color: AppTheme.voltLime).copyWith(letterSpacing: 0.3)),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
                  ),
                ),
                const SizedBox(height: 6),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('${_fmt(xp.xp)} / ${_fmt(xp.xpForNextLevel)} XP',
                      style: AppTheme.label(10, color: AppTheme.ink2)),
                  Text('${_fmt(xp.xpNeeded)} to LV ${xp.level + 1}',
                      style: AppTheme.label(10, color: AppTheme.ink2)),
                ]),
              ])),
            ]),
          ),
          const SizedBox(height: 20),
          Text('LEVEL PATH',
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          ...[
            [1, 'Walker'], [10, 'Mover'], [20, 'Challenger'],
            [35, 'Athlete'], [50, 'Elite'], [75, 'Legend'], [100, 'Immortal'],
          ].map((row) {
            final lv = row[0] as int;
            final title = row[1] as String;
            final done = xp.level >= lv;
            final isCurrent = (lv <= xp.level) &&
                (lv == 100 || xp.level < ([1,10,20,35,50,75,100].firstWhere((b) => b > lv, orElse: () => 101)));
            return Opacity(
              opacity: done ? 1.0 : 0.55,
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isCurrent
                      ? AppTheme.voltLime.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.03),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCurrent ? AppTheme.voltLime.withValues(alpha: 0.4) : Colors.transparent,
                  ),
                ),
                child: Row(children: [
                  SizedBox(
                    width: 50,
                    child: Text('LV$lv',
                        style: AppTheme.bigNum(18, color: done ? AppTheme.voltLime : AppTheme.ink3)),
                  ),
                  Expanded(child: Text(title,
                      style: AppTheme.label(14, color: Colors.white)
                          .copyWith(fontWeight: FontWeight.w600))),
                  Icon(done ? Icons.check_circle_rounded : Icons.lock_rounded,
                      color: done ? AppTheme.voltLime : AppTheme.ink3, size: 18),
                ]),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }
}
```

- [ ] **Step 2: Hot-reload and navigate to `/profile/xp` in the app**

Verify: level number, title, and progress bar all show real API values (not 23/14200/21000).

- [ ] **Step 3: Commit**

```bash
git add stepup/lib/features/profile/screens/xp_level_screen.dart
git commit -m "feat: XP level screen wired to real API"
```

---

## Layer 2 — Streak v2

---

### Task 6: Add DB columns for streak tracking

- [ ] **Step 1: Run this SQL in the Supabase SQL editor**

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS best_streak_days INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS streak_break_date DATE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS partial_day_count INT DEFAULT 0;

-- Backfill best_streak_days from current streak_days for existing users
UPDATE users SET best_streak_days = streak_days WHERE best_streak_days = 0 AND streak_days > 0;
```

- [ ] **Step 2: Verify columns exist**

```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'users'
AND column_name IN ('best_streak_days', 'streak_break_date', 'partial_day_count');
```
Expected: 3 rows returned

- [ ] **Step 3: Commit note**

```bash
git commit --allow-empty -m "chore: add streak columns to users table (applied in Supabase)"
```

---

### Task 7: Rewrite streak evaluation logic

**Files:**
- Modify: `stepup-api/src/modules/streaks/streaks.service.ts`

- [ ] **Step 1: Add evaluateStreak function**

Add this function to `streaks.service.ts` (before `getStreakStatus`). Also add the import for `DAILY_STEP_GOAL` at the top:

```typescript
import { DAILY_STEP_GOAL } from '../steps/xp.service';
```

Then add the function:

```typescript
type DayStatus = 'full' | 'partial' | 'none';

function classifyDay(steps: number): DayStatus {
  if (steps >= DAILY_STEP_GOAL) return 'full';
  if (steps >= DAILY_STEP_GOAL * 0.5) return 'partial';
  return 'none';
}

export async function evaluateStreak(userId: string) {
  const db = getSupabase();

  // Fetch last 3 days of step data
  const today = new Date().toISOString().slice(0, 10);
  const threeDaysAgo = new Date();
  threeDaysAgo.setDate(threeDaysAgo.getDate() - 2);
  const fromDate = threeDaysAgo.toISOString().slice(0, 10);

  const { data: stepRows } = await db
    .from('user_daily_steps')
    .select('date, total_steps')
    .eq('user_id', userId)
    .gte('date', fromDate)
    .lte('date', today)
    .order('date', { ascending: true });

  const stepMap: Record<string, number> = {};
  for (const row of stepRows ?? []) stepMap[row.date] = row.total_steps;

  const { data: user } = await db
    .from('users')
    .select('streak_days, best_streak_days, partial_day_count')
    .eq('id', userId)
    .single();

  if (!user) return;

  const todaySteps = stepMap[today] ?? 0;
  const todayStatus = classifyDay(todaySteps);

  // Determine previous consecutive none days
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yStr = yesterday.toISOString().slice(0, 10);
  const dayBeforeYesterday = new Date();
  dayBeforeYesterday.setDate(dayBeforeYesterday.getDate() - 2);
  const dbyStr = dayBeforeYesterday.toISOString().slice(0, 10);

  const yStatus = classifyDay(stepMap[yStr] ?? 0);
  const dbyStatus = classifyDay(stepMap[dbyStr] ?? 0);

  let newStreakDays = user.streak_days;
  let newPartialCount = user.partial_day_count;
  let breakDate: string | null = null;

  if (todayStatus === 'full') {
    newStreakDays = user.streak_days + 1;
    newPartialCount = 0;
  } else if (todayStatus === 'partial') {
    newPartialCount = user.partial_day_count + 1;
    if (newPartialCount >= 3) {
      // 3 consecutive partials = break
      newStreakDays = 0;
      newPartialCount = 0;
      breakDate = today;
    }
  } else {
    // none
    newPartialCount = 0;
    if (yStatus === 'none') {
      // 2 consecutive none = break
      newStreakDays = 0;
      breakDate = today;
    }
  }

  const newBest = Math.max(user.best_streak_days ?? 0, newStreakDays);

  const update: Record<string, unknown> = {
    streak_days: newStreakDays,
    best_streak_days: newBest,
    partial_day_count: newPartialCount,
  };
  if (breakDate) update.streak_break_date = breakDate;

  await db.from('users').update(update).eq('id', userId);
}
```

- [ ] **Step 2: Update `getStreakStatus` to also return `partial_day_count` and `streak_break_date`**

Find the `getStreakStatus` function. In the `select` for the user, add the new columns:

```typescript
  const { data: user } = await db
    .from('users')
    .select('streak_days, coin_balance, best_streak_days, streak_break_date')
    .eq('id', userId)
    .single();
```

Add to the return object:
```typescript
    best_streak_days: user?.best_streak_days ?? 0,
    streak_break_date: user?.streak_break_date ?? null,
```

- [ ] **Step 3: Fix revive to check 2-day window**

In `reviveStreak`, update the user select to include `streak_break_date`:
```typescript
  const { data: user } = await db
    .from('users')
    .select('coin_balance, streak_days, streak_break_date')
    .eq('id', userId)
    .single();
```

Then after the existing coin check (`if (!user || user.coin_balance < REVIVE_COST_COINS)`), add the window check:
```typescript
  // Revive window: break must have occurred within 2 days
  if (user.streak_break_date) {
    const breakDate = new Date(user.streak_break_date);
    const diffDays = Math.floor((Date.now() - breakDate.getTime()) / 86_400_000);
    if (diffDays > 2) throw new Error('Revive window expired (2 days after break)');
  }
```

- [ ] **Step 4: Compile check**

```bash
cd /Users/harsha/StepUp/stepup-api && npx tsc --noEmit
```

- [ ] **Step 5: Commit**

```bash
git add stepup-api/src/modules/streaks/streaks.service.ts
git commit -m "feat: streak evaluation with partial/none break rules, revive window"
```

---

### Task 8: Add streak calendar endpoint

**Files:**
- Modify: `stepup-api/src/modules/streaks/streaks.service.ts`
- Modify: `stepup-api/src/modules/streaks/streaks.router.ts`

- [ ] **Step 1: Add `getStreakCalendar` to streaks.service.ts**

```typescript
export async function getStreakCalendar(userId: string, days = 60) {
  const db = getSupabase();

  const endDate = new Date().toISOString().slice(0, 10);
  const startDt = new Date();
  startDt.setDate(startDt.getDate() - (days - 1));
  const startDate = startDt.toISOString().slice(0, 10);

  const { data: stepRows } = await db
    .from('user_daily_steps')
    .select('date, total_steps')
    .eq('user_id', userId)
    .gte('date', startDate)
    .lte('date', endDate)
    .order('date', { ascending: true });

  const stepMap: Record<string, number> = {};
  for (const row of stepRows ?? []) stepMap[row.date] = row.total_steps;

  // Walk through each day and compute rolling streak_count
  const result: Array<{ date: string; steps: number; status: string; streak_count: number }> = [];
  let rollingStreak = 0;
  let partialCount = 0;

  const cursor = new Date(startDt);
  cursor.setHours(0, 0, 0, 0);

  while (cursor.toISOString().slice(0, 10) <= endDate) {
    const d = cursor.toISOString().slice(0, 10);
    const steps = stepMap[d] ?? 0;
    const status = classifyDay(steps);

    if (status === 'full') {
      rollingStreak++;
      partialCount = 0;
    } else if (status === 'partial') {
      partialCount++;
      if (partialCount >= 3) { rollingStreak = 0; partialCount = 0; }
    } else {
      partialCount = 0;
      // Simple approximation: reset streak on none days
      // (exact 2-consecutive check needs prev day context — handled in evaluateStreak)
      if (result.length > 0 && result[result.length - 1].status === 'none') {
        rollingStreak = 0;
      }
    }

    result.push({ date: d, steps, status, streak_count: rollingStreak });
    cursor.setDate(cursor.getDate() + 1);
  }

  return result;
}
```

- [ ] **Step 2: Add calendar route to streaks.router.ts**

In the router file, add after the existing routes:

```typescript
import { getStreakStatus, useShield, reviveStreak, evaluateStreak, getStreakCalendar } from './streaks.service';

streaksRouter.get('/calendar', async (req: Request, res: Response) => {
  try {
    const days = Math.min(Number(req.query.days ?? 60), 120);
    res.json(await getStreakCalendar(req.user!.id, days));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
```

- [ ] **Step 3: Test the endpoint**

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/streaks/calendar?days=30
```
Expected: JSON array of 30 objects with `date`, `steps`, `status`, `streak_count`

- [ ] **Step 4: Commit**

```bash
git add stepup-api/src/modules/streaks/streaks.service.ts stepup-api/src/modules/streaks/streaks.router.ts
git commit -m "feat: GET /streaks/calendar endpoint with rolling streak counts"
```

---

### Task 9: Hook evaluateStreak into step sync

**Files:**
- Modify: `stepup-api/src/modules/steps/steps.service.ts`

- [ ] **Step 1: Add import at the top of steps.service.ts**

```typescript
import { evaluateStreak } from '../streaks/streaks.service';
```

- [ ] **Step 2: Call evaluateStreak after updateLeaderboardsForUser**

In the `syncSteps` function, after the line:
```typescript
  await updateLeaderboardsForUser(userId, payload.steps);
```
Add:
```typescript
  // Evaluate streak after each sync (fire-and-forget)
  evaluateStreak(userId).catch(() => {});
```

- [ ] **Step 3: Compile and commit**

```bash
cd /Users/harsha/StepUp/stepup-api && npx tsc --noEmit
git add stepup-api/src/modules/steps/steps.service.ts
git commit -m "feat: evaluate streak on every step sync"
```

---

### Task 10: Flutter streak calendar widget

**Files:**
- Create: `stepup/lib/shared/models/streak_calendar_day.dart`
- Create: `stepup/lib/features/streaks/providers/streak_calendar_provider.dart`
- Modify: `stepup/lib/features/streaks/screens/streak_screen.dart`

- [ ] **Step 1: Create StreakCalendarDay model**

```dart
// stepup/lib/shared/models/streak_calendar_day.dart
class StreakCalendarDay {
  final String date, status;
  final int steps, streakCount;

  const StreakCalendarDay({
    required this.date,
    required this.status,
    required this.steps,
    required this.streakCount,
  });

  factory StreakCalendarDay.fromJson(Map<String, dynamic> j) => StreakCalendarDay(
        date: j['date'] as String,
        status: j['status'] as String? ?? 'none',
        steps: (j['steps'] as num? ?? 0).toInt(),
        streakCount: (j['streak_count'] as num? ?? 0).toInt(),
      );
}
```

- [ ] **Step 2: Create streak calendar provider**

```dart
// stepup/lib/features/streaks/providers/streak_calendar_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/streak_calendar_day.dart';

final streakCalendarProvider = FutureProvider<List<StreakCalendarDay>>((ref) async {
  final data = await ApiClient.instance.get('/streaks/calendar?days=60') as List<dynamic>;
  return data.map((e) => StreakCalendarDay.fromJson(e as Map<String, dynamic>)).toList();
});
```

- [ ] **Step 3: Add calendar widget to streak_screen.dart**

At the top of `streak_screen.dart`, add imports:
```dart
import '../providers/streak_calendar_provider.dart';
import '../../../shared/models/streak_calendar_day.dart';
```

In the `StreakScreen.build` method, also watch `streakCalendarProvider`:
```dart
final calendarAsync = ref.watch(streakCalendarProvider);
```

Pass it to `_StreakBody`:
```dart
data: (streak) => _StreakBody(
  streakDays: streak.streakDays,
  shieldAvailable: streak.shieldAvailable,
  calendarAsync: calendarAsync,
),
```

Update `_StreakBody` constructor and class to accept `calendarAsync`:
```dart
class _StreakBody extends StatelessWidget {
  final int streakDays;
  final bool shieldAvailable;
  final AsyncValue<List<StreakCalendarDay>> calendarAsync;
  const _StreakBody({
    required this.streakDays,
    required this.shieldAvailable,
    required this.calendarAsync,
  });
```

In `_StreakBody.build`, after the shield hero container and before the shield card, insert the calendar section:

```dart
        const SizedBox(height: 16),
        Text('ACTIVITY CALENDAR',
            style: AppTheme.label(10, color: AppTheme.ink2)
                .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 10),
        calendarAsync.when(
          loading: () => const SizedBox(height: 80,
              child: Center(child: CircularProgressIndicator(color: AppTheme.voltLime, strokeWidth: 2))),
          error: (_, __) => const SizedBox.shrink(),
          data: (days) => _StreakCalendar(days: days),
        ),
        const SizedBox(height: 14),
```

- [ ] **Step 4: Add `_StreakCalendar` widget at the bottom of streak_screen.dart**

```dart
class _StreakCalendar extends StatelessWidget {
  final List<StreakCalendarDay> days;
  const _StreakCalendar({required this.days});

  Color _colorFor(String status) {
    switch (status) {
      case 'full': return AppTheme.voltLime;
      case 'partial': return AppTheme.amber;
      default: return Colors.red.shade700;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show last 35 days in a 7-column grid
    final recent = days.length > 35 ? days.sublist(days.length - 35) : days;
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: recent.map((day) {
        final hasActivity = day.status != 'none' && day.steps > 0;
        return Tooltip(
          message: '${day.date}\n${day.steps} steps',
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: hasActivity
                  ? _colorFor(day.status).withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6),
            ),
            child: day.streakCount > 0 && day.status == 'full'
                ? Center(child: Text('${day.streakCount}',
                    style: TextStyle(color: AppTheme.bg, fontSize: 10, fontWeight: FontWeight.w800)))
                : null,
          ),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 5: Hot-reload and navigate to `/streaks`**

Verify: calendar grid appears below streak count, green/amber/red cells, streak numbers visible.

- [ ] **Step 6: Commit**

```bash
git add stepup/lib/shared/models/streak_calendar_day.dart \
        stepup/lib/features/streaks/providers/streak_calendar_provider.dart \
        stepup/lib/features/streaks/screens/streak_screen.dart
git commit -m "feat: streak calendar widget with 35-day grid from real API"
```

---

## Layer 3 — Fitness Reputation

---

### Task 11: Add DB columns for reputation

- [ ] **Step 1: Run in Supabase SQL editor**

```sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_score INT DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_updated_at TIMESTAMPTZ;
ALTER TABLE users ADD COLUMN IF NOT EXISTS reputation_snapshot_prev INT DEFAULT 0;
```

- [ ] **Step 2: Verify**

```sql
SELECT column_name FROM information_schema.columns
WHERE table_name = 'users'
AND column_name IN ('reputation_score', 'reputation_updated_at', 'reputation_snapshot_prev');
```
Expected: 3 rows

- [ ] **Step 3: Commit note**

```bash
git commit --allow-empty -m "chore: add reputation columns to users table (applied in Supabase)"
```

---

### Task 12: Create reputation service

**Files:**
- Create: `stepup-api/src/modules/reputation/reputation.service.ts`

- [ ] **Step 1: Create the service**

```typescript
// stepup-api/src/modules/reputation/reputation.service.ts
import { getSupabase } from '../../lib/supabase';
import { DAILY_STEP_GOAL } from '../steps/xp.service';

interface SubScores {
  consistency: number;
  challengeWins: number;
  streakDepth: number;
  activityMix: number;
  social: number;
}

async function computeSubScores(userId: string, db: ReturnType<typeof getSupabase>): Promise<SubScores> {
  const thirtyDaysAgo = new Date();
  thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
  const since = thirtyDaysAgo.toISOString().slice(0, 10);
  const today = new Date().toISOString().slice(0, 10);

  // 1. Consistency — active days in last 30 days
  const { data: stepRows } = await db
    .from('user_daily_steps')
    .select('total_steps')
    .eq('user_id', userId)
    .gte('date', since)
    .lte('date', today);

  let fullDays = 0, partialDays = 0;
  for (const row of stepRows ?? []) {
    if (row.total_steps >= DAILY_STEP_GOAL) fullDays++;
    else if (row.total_steps >= DAILY_STEP_GOAL * 0.5) partialDays++;
  }
  const consistency = Math.min((fullDays + partialDays * 0.5) / 30 * 100, 100);

  // 2. Challenge wins — top-50% finishes / total joined
  const { data: participations } = await db
    .from('challenge_participants')
    .select('final_rank, challenge_id')
    .eq('user_id', userId)
    .not('final_rank', 'is', null);

  let joined = participations?.length ?? 0;
  let wins = 0;
  for (const p of participations ?? []) {
    // Need total participants for each challenge to determine top 50%
    // Use a simple approximation: rank <= 5 is a win (fallback if no total)
    if (p.final_rank && p.final_rank <= 5) wins++;
  }
  // Better: fetch participant counts for each challenge
  if (joined > 0) {
    const challengeIds = [...new Set((participations ?? []).map(p => p.challenge_id))];
    const { data: counts } = await db
      .from('challenge_participants')
      .select('challenge_id')
      .in('challenge_id', challengeIds);
    const countMap: Record<string, number> = {};
    for (const c of counts ?? []) {
      countMap[c.challenge_id] = (countMap[c.challenge_id] ?? 0) + 1;
    }
    wins = (participations ?? []).filter(p => {
      const total = countMap[p.challenge_id] ?? 1;
      return p.final_rank && p.final_rank <= Math.ceil(total * 0.5);
    }).length;
  }
  const challengeWins = joined === 0 ? 0 : Math.min(wins / joined * 100, 100);

  // 3. Streak depth — current + best streak
  const { data: user } = await db
    .from('users')
    .select('streak_days, best_streak_days')
    .eq('id', userId)
    .single();
  const streak = user?.streak_days ?? 0;
  const best = user?.best_streak_days ?? streak;
  const streakDepth = Math.min((streak * 2 + best) / 90 * 100, 100);

  // 4. Activity mix — distinct activity types in last 30 days
  const { data: acts } = await db
    .from('activities')
    .select('activity_type')
    .eq('user_id', userId)
    .gte('date', since);
  const hasSteps = (stepRows?.length ?? 0) > 0 ? 1 : 0;
  const actTypes = new Set((acts ?? []).map((a: any) => a.activity_type));
  const hasGym = actTypes.has('gym') ? 1 : 0;
  const hasCycling = actTypes.has('cycle') ? 1 : 0;
  const hasOutdoor = actTypes.has('sport') ? 1 : 0;
  const activityMix = (hasSteps + hasGym + hasCycling + hasOutdoor) / 4 * 100;

  // 5. Social — posts + likes
  const { count: postCount } = await db
    .from('community_posts')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId);
  const { data: likesData } = await db
    .from('community_posts')
    .select('likes')
    .eq('user_id', userId);
  const totalLikes = (likesData ?? []).reduce((s: number, p: any) => s + (p.likes ?? 0), 0);
  const social = Math.min(((postCount ?? 0) + totalLikes / 10) / 20 * 100, 100);

  return { consistency, challengeWins, streakDepth, activityMix, social };
}

function computeFinalScore(s: SubScores): number {
  const weighted = s.consistency * 0.30 + s.challengeWins * 0.25 +
    s.streakDepth * 0.20 + s.activityMix * 0.15 + s.social * 0.10;
  return Math.round(weighted * 9);
}

export async function calculateReputation(userId: string) {
  const db = getSupabase();
  const scores = await computeSubScores(userId, db);
  const score = computeFinalScore(scores);

  // Save to users table
  await db.from('users').update({
    reputation_score: score,
    reputation_updated_at: new Date().toISOString(),
  }).eq('id', userId);

  // Compute percentile
  const { count: totalUsers } = await db
    .from('users')
    .select('*', { count: 'exact', head: true });
  const { count: higherCount } = await db
    .from('users')
    .select('*', { count: 'exact', head: true })
    .gt('reputation_score', score);
  const percentileRank = Math.round(((higherCount ?? 0) / Math.max(totalUsers ?? 1, 1)) * 100);

  // Monthly delta
  const { data: u } = await db
    .from('users')
    .select('reputation_snapshot_prev, best_streak_days')
    .eq('id', userId)
    .single();
  const monthlyDelta = score - (u?.reputation_snapshot_prev ?? 0);

  // Challenge stats
  const { data: parts } = await db
    .from('challenge_participants')
    .select('final_rank, challenge_id')
    .eq('user_id', userId);
  const { count: totalChallengesJoined } = await db
    .from('challenge_participants')
    .select('*', { count: 'exact', head: true })
    .eq('user_id', userId);

  return {
    score,
    breakdown: {
      consistency: Math.round(scores.consistency),
      challenge_wins: Math.round(scores.challengeWins),
      streak_depth: Math.round(scores.streakDepth),
      activity_mix: Math.round(scores.activityMix),
      social: Math.round(scores.social),
    },
    percentile_rank: percentileRank,
    monthly_delta: monthlyDelta,
    highlights: {
      best_streak_days: u?.best_streak_days ?? 0,
      total_challenges_joined: totalChallengesJoined ?? 0,
    },
  };
}

export async function recalculateAllReputation() {
  const db = getSupabase();
  const today = new Date();

  // On 1st of month: snapshot current scores before overwriting
  if (today.getDate() === 1) {
    await db.rpc('snapshot_reputation_scores').catch(() => {
      // Fallback if RPC doesn't exist: update snapshot from current score
      db.from('users').select('id, reputation_score').then(({ data }) => {
        for (const u of data ?? []) {
          db.from('users')
            .update({ reputation_snapshot_prev: u.reputation_score })
            .eq('id', u.id)
            .then(() => {});
        }
      });
    });
  }

  const { data: users } = await db
    .from('users')
    .select('id')
    .not('id', 'is', null);

  for (const user of users ?? []) {
    await calculateReputation(user.id).catch(() => {});
  }
}
```

- [ ] **Step 2: Compile check**

```bash
cd /Users/harsha/StepUp/stepup-api && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add stepup-api/src/modules/reputation/reputation.service.ts
git commit -m "feat: reputation service with 5-factor 0-900 score calculation"
```

---

### Task 13: Create reputation router and register it

**Files:**
- Create: `stepup-api/src/modules/reputation/reputation.router.ts`
- Modify: `stepup-api/src/app.ts`
- Modify: `stepup-api/src/index.ts`

- [ ] **Step 1: Create reputation router**

```typescript
// stepup-api/src/modules/reputation/reputation.router.ts
import { Router, Request, Response, NextFunction } from 'express';
import { calculateReputation } from './reputation.service';

export const reputationRouter = Router();

reputationRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await calculateReputation(req.user!.id);
    res.json(data);
  } catch (err) { next(err); }
});
```

- [ ] **Step 2: Register in app.ts**

Add import after the last existing import:
```typescript
import { reputationRouter } from './modules/reputation/reputation.router';
```

Add route after the `app.use('/achievements', achievementsRouter);` line:
```typescript
  app.use('/reputation', reputationRouter);
```

- [ ] **Step 3: Add nightly reputation cron to index.ts**

Add import:
```typescript
import { recalculateAllReputation } from './modules/reputation/reputation.service';
```

Add after the existing league queue setup:
```typescript
// Nightly at 2am IST (8:30pm UTC)
const reputationQueue = createQueue('reputation-recalc');
createWorker('reputation-recalc', async () => { await recalculateAllReputation(); });
reputationQueue.add('recalc', {}, { repeat: { pattern: '30 20 * * *' } });
```

- [ ] **Step 4: Test endpoint**

```bash
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/reputation
```
Expected: JSON with `score` (0–900), `breakdown`, `percentile_rank`, `monthly_delta`, `highlights`

- [ ] **Step 5: Commit**

```bash
git add stepup-api/src/modules/reputation/reputation.router.ts \
        stepup-api/src/app.ts \
        stepup-api/src/index.ts
git commit -m "feat: GET /reputation endpoint with nightly recalc cron"
```

---

### Task 14: Wire Flutter reputation screen to real API

**Files:**
- Create: `stepup/lib/features/profile/providers/reputation_provider.dart`
- Create: `stepup/lib/shared/models/reputation.dart`
- Modify: `stepup/lib/features/profile/screens/reputation_screen.dart`

- [ ] **Step 1: Create Reputation model**

```dart
// stepup/lib/shared/models/reputation.dart
class ReputationBreakdown {
  final int consistency, challengeWins, streakDepth, activityMix, social;
  const ReputationBreakdown({
    required this.consistency, required this.challengeWins,
    required this.streakDepth, required this.activityMix, required this.social,
  });
  factory ReputationBreakdown.fromJson(Map<String, dynamic> j) => ReputationBreakdown(
    consistency: (j['consistency'] as num? ?? 0).toInt(),
    challengeWins: (j['challenge_wins'] as num? ?? 0).toInt(),
    streakDepth: (j['streak_depth'] as num? ?? 0).toInt(),
    activityMix: (j['activity_mix'] as num? ?? 0).toInt(),
    social: (j['social'] as num? ?? 0).toInt(),
  );
}

class ReputationHighlights {
  final int bestStreakDays, totalChallengesJoined;
  const ReputationHighlights({required this.bestStreakDays, required this.totalChallengesJoined});
  factory ReputationHighlights.fromJson(Map<String, dynamic> j) => ReputationHighlights(
    bestStreakDays: (j['best_streak_days'] as num? ?? 0).toInt(),
    totalChallengesJoined: (j['total_challenges_joined'] as num? ?? 0).toInt(),
  );
}

class Reputation {
  final int score, percentileRank, monthlyDelta;
  final ReputationBreakdown breakdown;
  final ReputationHighlights highlights;

  const Reputation({
    required this.score, required this.percentileRank, required this.monthlyDelta,
    required this.breakdown, required this.highlights,
  });

  factory Reputation.fromJson(Map<String, dynamic> j) => Reputation(
    score: (j['score'] as num? ?? 0).toInt(),
    percentileRank: (j['percentile_rank'] as num? ?? 100).toInt(),
    monthlyDelta: (j['monthly_delta'] as num? ?? 0).toInt(),
    breakdown: ReputationBreakdown.fromJson(j['breakdown'] as Map<String, dynamic>? ?? {}),
    highlights: ReputationHighlights.fromJson(j['highlights'] as Map<String, dynamic>? ?? {}),
  );
}
```

- [ ] **Step 2: Create reputation provider**

```dart
// stepup/lib/features/profile/providers/reputation_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/reputation.dart';

final reputationProvider = FutureProvider<Reputation>((ref) async {
  final data = await ApiClient.instance.get('/reputation') as Map<String, dynamic>;
  return Reputation.fromJson(data);
});
```

- [ ] **Step 3: Rewrite reputation_screen.dart**

```dart
// stepup/lib/features/profile/screens/reputation_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/reputation_provider.dart';
import '../../../shared/models/reputation.dart';
import '../../../core/theme.dart';

class ReputationScreen extends ConsumerWidget {
  const ReputationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(reputationProvider);
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: async.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) => Center(child: Text('Error: $e', style: AppTheme.label(13, color: AppTheme.ink2))),
          data: (rep) => _ReputationBody(rep: rep),
        ),
      ),
    );
  }
}

class _ReputationBody extends StatelessWidget {
  final Reputation rep;
  const _ReputationBody({required this.rep});

  @override
  Widget build(BuildContext context) {
    final delta = rep.monthlyDelta;
    final deltaPositive = delta >= 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.border),
            ),
            child: Text('Public', style: AppTheme.label(11, color: AppTheme.ink2)),
          ),
        ]),
        const SizedBox(height: 16),
        Text('FITNESS REPUTATION', style: AppTheme.bigNum(22).copyWith(letterSpacing: 0.5)),
        const SizedBox(height: 20),

        // Score hero
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: RadialGradient(
              colors: [AppTheme.voltLime.withValues(alpha: 0.12), Colors.transparent],
              center: Alignment.topCenter, radius: 1.5,
            ),
          ),
          child: Column(children: [
            Text('${rep.score}', style: AppTheme.bigNum(84, color: AppTheme.voltLime)),
            const SizedBox(height: 8),
            Text('TOP ${rep.percentileRank}% NATIONALLY',
                style: AppTheme.label(11, color: AppTheme.ink2).copyWith(letterSpacing: 1.5)),
            const SizedBox(height: 6),
            Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                deltaPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                color: deltaPositive ? AppTheme.voltLime : Colors.red.shade400, size: 14,
              ),
              const SizedBox(width: 4),
              Text('${deltaPositive ? '+' : ''}$delta this month',
                  style: AppTheme.label(12, color: deltaPositive ? AppTheme.voltLime : Colors.red.shade400)),
            ]),
          ]),
        ),
        const SizedBox(height: 16),

        Text('BREAKDOWN', style: AppTheme.label(10, color: AppTheme.ink2)
            .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),

        ...[
          ['Consistency', rep.breakdown.consistency, AppTheme.voltLime],
          ['Challenge wins', rep.breakdown.challengeWins, AppTheme.voltLime],
          ['Streak depth', rep.breakdown.streakDepth, AppTheme.amber],
          ['Activity mix', rep.breakdown.activityMix, AppTheme.amber],
          ['Social', rep.breakdown.social, AppTheme.ink2],
        ].map((row) {
          final label = row[0] as String;
          final val = row[1] as int;
          final color = row[2] as Color;
          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(label, style: AppTheme.label(13, color: Colors.white)
                    .copyWith(fontWeight: FontWeight.w600)),
                Text('$val', style: AppTheme.bigNum(14, color: color)),
              ]),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  value: val / 100,
                  minHeight: 4,
                  backgroundColor: Colors.white.withValues(alpha: 0.06),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
            ]),
          );
        }),

        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _StatBox(icon: Icons.local_fire_department_rounded,
              value: '${rep.highlights.bestStreakDays}D', label: 'Best streak', color: AppTheme.voltLime)),
          const SizedBox(width: 10),
          Expanded(child: _StatBox(icon: Icons.emoji_events_rounded,
              value: '${rep.highlights.totalChallengesJoined}', label: 'Challenges', color: AppTheme.voltLime)),
          const SizedBox(width: 10),
          Expanded(child: _StatBox(icon: Icons.military_tech_rounded,
              value: 'TOP ${rep.percentileRank}%', label: 'National', color: AppTheme.voltLime)),
        ]),
      ]),
    );
  }
}

class _StatBox extends StatelessWidget {
  final IconData icon;
  final String value, label;
  final Color color;
  const _StatBox({required this.icon, required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(icon, color: color, size: 18),
      const SizedBox(height: 6),
      Text(value, style: AppTheme.bigNum(22)),
      const SizedBox(height: 2),
      Text(label, style: AppTheme.label(10, color: AppTheme.ink2)),
    ]),
  );
}
```

- [ ] **Step 4: Hot-reload and open `/profile/reputation`**

Verify: real score (0–900), real breakdown bars, real percentile, real monthly delta.

- [ ] **Step 5: Commit**

```bash
git add stepup/lib/shared/models/reputation.dart \
        stepup/lib/features/profile/providers/reputation_provider.dart \
        stepup/lib/features/profile/screens/reputation_screen.dart
git commit -m "feat: reputation screen wired to real API"
```

---

## Layer 4 — Seasons

---

### Task 15: Create seasons DB tables and seed Season 1

- [ ] **Step 1: Run in Supabase SQL editor**

```sql
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
```

- [ ] **Step 2: Verify**

```sql
SELECT name, start_date, end_date, status FROM seasons;
```
Expected: 1 row — Season 1: Foundation, active

- [ ] **Step 3: Commit note**

```bash
git commit --allow-empty -m "chore: create seasons + user_season_results tables, seed Season 1"
```

---

### Task 16: Create seasons service

**Files:**
- Create: `stepup-api/src/modules/seasons/seasons.service.ts`

- [ ] **Step 1: Create the file**

```typescript
// stepup-api/src/modules/seasons/seasons.service.ts
import { getSupabase } from '../../lib/supabase';

const TIER_COIN_REWARDS: Record<string, number> = {
  elite: 2000, diamond: 1000, platinum: 500, gold: 250, silver: 100, bronze: 25,
};

function xpToLeagueSlug(xp: number): string {
  if (xp >= 10000) return 'elite';
  if (xp >= 5000)  return 'diamond';
  if (xp >= 3000)  return 'platinum';
  if (xp >= 2000)  return 'gold';
  if (xp >= 1000)  return 'silver';
  return 'bronze';
}

export async function getCurrentSeason() {
  const db = getSupabase();
  const { data, error } = await db
    .from('seasons')
    .select('*')
    .eq('status', 'active')
    .maybeSingle();
  if (error) throw new Error(error.message);
  if (!data) return null;

  const endDate = new Date(data.end_date);
  const daysRemaining = Math.max(0, Math.ceil((endDate.getTime() - Date.now()) / 86_400_000));
  return { ...data, days_remaining: daysRemaining };
}

export async function getMySeasonResult(userId: string, seasonId: string) {
  const db = getSupabase();
  const { data, error } = await db
    .from('user_season_results')
    .select('*, seasons(name, start_date, end_date)')
    .eq('user_id', userId)
    .eq('season_id', seasonId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return data;
}

export async function endSeason(seasonId: string) {
  const db = getSupabase();

  const { data: season, error: sErr } = await db
    .from('seasons')
    .select('*')
    .eq('id', seasonId)
    .single();
  if (sErr || !season) throw new Error('Season not found');
  if (season.status !== 'active') throw new Error('Season is not active');

  // Step 1: Snapshot all users' current league into user_season_results
  const { data: leagues } = await db
    .from('user_leagues')
    .select('user_id, league_slug, xp, rank_in_tier');

  const results = (leagues ?? []).map(ul => ({
    user_id: ul.user_id,
    season_id: seasonId,
    final_league_slug: ul.league_slug,
    final_xp: ul.xp,
    rank_in_tier: ul.rank_in_tier,
    coins_awarded: TIER_COIN_REWARDS[ul.league_slug] ?? 0,
  }));

  if (results.length > 0) {
    await db.from('user_season_results').upsert(results, { onConflict: 'user_id,season_id', ignoreDuplicates: true });
  }

  // Step 2: Award coins based on final tier
  for (const result of results) {
    if (result.coins_awarded > 0) {
      await db.rpc('increment_coins', { uid: result.user_id, amount: result.coins_awarded }).catch(() => {});
    }
  }

  // Step 3: Soft-decay users.xp by tier_decay_pct, recalculate league slug
  const decayMultiplier = season.tier_decay_pct / 100;
  const { data: users } = await db.from('users').select('id, xp');
  for (const user of users ?? []) {
    const newXp = Math.floor((user.xp ?? 0) * decayMultiplier);
    const newSlug = xpToLeagueSlug(newXp);
    await db.from('users').update({ xp: newXp }).eq('id', user.id);
    await db.from('user_leagues').update({ xp: newXp, league_slug: newSlug })
      .eq('user_id', user.id);
  }

  // Step 4: Mark season ended
  await db.from('seasons').update({ status: 'ended' }).eq('id', seasonId);

  // Step 5: Activate next upcoming season if start_date <= today
  const today = new Date().toISOString().slice(0, 10);
  const { data: nextSeason } = await db
    .from('seasons')
    .select('id')
    .eq('status', 'upcoming')
    .lte('start_date', today)
    .order('start_date', { ascending: true })
    .limit(1)
    .maybeSingle();
  if (nextSeason) {
    await db.from('seasons').update({ status: 'active' }).eq('id', nextSeason.id);
  }

  return { ended: true, season_id: seasonId, users_processed: results.length };
}
```

- [ ] **Step 2: Compile check**

```bash
cd /Users/harsha/StepUp/stepup-api && npx tsc --noEmit
```

- [ ] **Step 3: Commit**

```bash
git add stepup-api/src/modules/seasons/seasons.service.ts
git commit -m "feat: seasons service (current, my-result, end-season logic)"
```

---

### Task 17: Create seasons router and register it

**Files:**
- Create: `stepup-api/src/modules/seasons/seasons.router.ts`
- Modify: `stepup-api/src/app.ts`

- [ ] **Step 1: Create seasons router**

```typescript
// stepup-api/src/modules/seasons/seasons.router.ts
import { Router, Request, Response, NextFunction } from 'express';
import { getCurrentSeason, getMySeasonResult, endSeason } from './seasons.service';

export const seasonsRouter = Router();

seasonsRouter.get('/current', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const season = await getCurrentSeason();
    if (!season) return res.status(404).json({ error: 'No active season' });
    res.json(season);
  } catch (err) { next(err); }
});

seasonsRouter.get('/:id/my-result', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await getMySeasonResult(req.user!.id, req.params.id);
    if (!result) return res.status(404).json({ error: 'No result for this season' });
    res.json(result);
  } catch (err) { next(err); }
});

// Admin-only: protected by secret header
seasonsRouter.post('/:id/end', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const adminSecret = process.env.ADMIN_SECRET;
    if (adminSecret && req.headers['x-admin-secret'] !== adminSecret) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const result = await endSeason(req.params.id);
    res.json(result);
  } catch (err) { next(err); }
});
```

- [ ] **Step 2: Register in app.ts**

Add import:
```typescript
import { seasonsRouter } from './modules/seasons/seasons.router';
```

Add route after `app.use('/reputation', reputationRouter);`:
```typescript
  app.use('/seasons', seasonsRouter);
```

- [ ] **Step 3: Test endpoints**

```bash
# Get current season
curl -H "Authorization: Bearer $TOKEN" http://localhost:3000/seasons/current
```
Expected: JSON with `name: "Season 1: Foundation"`, `status: "active"`, `days_remaining`

- [ ] **Step 4: Commit**

```bash
git add stepup-api/src/modules/seasons/seasons.router.ts stepup-api/src/app.ts
git commit -m "feat: seasons router (GET current, GET my-result, POST end)"
```

---

### Task 18: Flutter season rewards screen (hardcoded shell)

**Files:**
- Create: `stepup/lib/features/seasons/screens/season_rewards_screen.dart`
- Modify: `stepup/lib/core/router.dart`

- [ ] **Step 1: Create the screen**

```dart
// stepup/lib/features/seasons/screens/season_rewards_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme.dart';

class SeasonRewardsScreen extends StatelessWidget {
  const SeasonRewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('SEASON 1: FOUNDATION',
                  style: AppTheme.label(11, color: AppTheme.voltLime)
                      .copyWith(letterSpacing: 2, fontWeight: FontWeight.w800)),
              const SizedBox(height: 16),
              Text('SEASON ENDED', style: AppTheme.bigNum(36)),
              const SizedBox(height: 8),
              Text('Your final rank', style: AppTheme.label(13, color: AppTheme.ink2)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: AppTheme.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                ),
                child: Text('GOLD', style: AppTheme.bigNum(42, color: AppTheme.amber)),
              ),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Column(children: [
                  Text('Season Reward', style: AppTheme.label(11, color: AppTheme.ink2)),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Text('250', style: AppTheme.bigNum(48, color: AppTheme.voltLime)),
                    const SizedBox(width: 8),
                    const Icon(Icons.monetization_on_rounded, color: AppTheme.amber, size: 36),
                  ]),
                  Text('Coins added to your wallet',
                      style: AppTheme.label(11, color: AppTheme.ink2)),
                ]),
              ),
              const SizedBox(height: 28),
              Text('New season starting soon',
                  style: AppTheme.label(12, color: AppTheme.ink2)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () => context.go('/home'),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: AppTheme.voltLime,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text('Continue →',
                        style: AppTheme.label(15, color: AppTheme.bg)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Add import and route to router.dart**

Add import at top:
```dart
import '../features/seasons/screens/season_rewards_screen.dart';
```

Inside the `ShellRoute` routes list, add at the end (before the closing `]`):
```dart
        GoRoute(path: '/season-rewards', builder: (_, __) => const SeasonRewardsScreen()),
```

- [ ] **Step 3: Verify by navigating to `/season-rewards` in-app**

Push route from Flutter DevTools or add a temporary debug button. Screen should show the hardcoded gold tier rewards page.

- [ ] **Step 4: Commit**

```bash
git add stepup/lib/features/seasons/screens/season_rewards_screen.dart \
        stepup/lib/core/router.dart
git commit -m "feat: season rewards screen (hardcoded shell, API wiring deferred)"
```

---

## Final Verification

- [ ] **API smoke test: all new endpoints respond**

```bash
BASE=http://localhost:3000
H="Authorization: Bearer $TOKEN"
curl -s -H "$H" $BASE/xp | jq .level
curl -s -H "$H" $BASE/streaks/calendar | jq 'length'
curl -s -H "$H" $BASE/reputation | jq .score
curl -s -H "$H" $BASE/seasons/current | jq .name
```

- [ ] **TypeScript final check**

```bash
cd /Users/harsha/StepUp/stepup-api && npx tsc --noEmit
```
Expected: 0 errors

- [ ] **Final commit**

```bash
git add -A
git commit -m "chore: gamification overhaul complete — XP engine, streak v2, reputation, seasons"
```
