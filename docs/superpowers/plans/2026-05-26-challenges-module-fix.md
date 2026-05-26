# Challenges Module Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the challenges module end-to-end — join reliability, real-time progress tracking from the database, and a live check-in screen.

**Architecture:** Add a `GET /challenges/:id/progress` API endpoint that computes user progress from `user_daily_steps` (steps/walking/running) or `activities` (gym/cycling/outdoor), expose it via a Riverpod provider in Flutter, and wire the check-in screen and My Challenges progress bar to that provider. Fix the join flow to use upsert (idempotent), auto-create missing user rows on join, fix Express routing order, and invalidate stale providers after join.

**Tech Stack:** TypeScript/Express (API), Supabase (Postgres + service role), Redis (leaderboard ranking), Dart/Flutter, Riverpod (state), GoRouter (navigation).

---

## File Map

| File | Action | Purpose |
|---|---|---|
| `stepup-api/src/modules/challenges/challenges.service.ts` | Modify | Add `getChallengeProgress()`, fix `joinChallenge()` upsert, add user-row guard |
| `stepup-api/src/modules/challenges/challenges.router.ts` | Modify | Add `GET /:id/progress` route |
| `stepup-api/src/app.ts` | Modify | Fix routing order: `/challenges/custom` before `/challenges` |
| `stepup/lib/shared/models/challenge.dart` | Modify | Add `ChallengeProgress` model |
| `stepup/lib/features/challenges/providers/challenges_provider.dart` | Modify | Add `challengeProgressProvider` |
| `stepup/lib/features/challenges/screens/challenge_checkin_screen.dart` | Rewrite | Load real challenge + progress; show live check-in state |
| `stepup/lib/features/challenges/screens/challenges_screen.dart` | Modify | `_MyChallengeTile` — use actual progress from provider, not day math |
| `stepup/lib/features/challenges/screens/challenge_detail_screen.dart` | Modify | Invalidate providers after successful join |

---

## Task 1: Fix Express routing order (`app.ts`)

**Files:**
- Modify: `stepup-api/src/app.ts:47`

The line `app.use('/challenges/custom', customChallengesRouter)` is mounted *after* `app.use('/challenges', challengesRouter)`. Express matches `/challenges/custom` against `challengesRouter` first, where `/:id` catches `custom` as an ID. Custom challenge routes are unreachable.

- [ ] **Step 1: Swap the two lines so `/challenges/custom` is registered first**

Open `stepup-api/src/app.ts`. Find this block:
```ts
  app.use('/challenges', challengesRouter);
  app.use('/challenges/custom', customChallengesRouter);
```
Replace it with:
```ts
  app.use('/challenges/custom', customChallengesRouter);
  app.use('/challenges', challengesRouter);
```

- [ ] **Step 2: Commit**
```bash
git add stepup-api/src/app.ts
git commit -m "fix: mount /challenges/custom before /challenges so custom routes aren't swallowed by /:id"
```

---

## Task 2: Fix `joinChallenge` — upsert + user-row guard

**Files:**
- Modify: `stepup-api/src/modules/challenges/challenges.service.ts`

Two bugs:
1. `.insert()` is not idempotent — other users see raw DB error if they somehow already have a participant row. Use `.upsert()`.
2. `challenge_participants.user_id` FK references `users(id)`. If a user authenticated via Supabase Auth but never got a row inserted into `users`, the FK fails. We guard by upserting a minimal `users` row before joining.

- [ ] **Step 1: Replace the `joinChallenge` function body in `challenges.service.ts`**

Find the function starting at line 79 and replace the entire body with:

```ts
export async function joinChallenge(userId: string, challengeId: string) {
  const db = getSupabase();
  const challenge = await getChallenge(challengeId);

  if (challenge.status !== 'active' && challenge.status !== 'upcoming') {
    throw new Error('Challenge is not open for joining');
  }

  if (challenge.max_participants) {
    const { count } = await db
      .from('challenge_participants')
      .select('*', { count: 'exact', head: true })
      .eq('challenge_id', challengeId);
    if ((count ?? 0) >= challenge.max_participants) throw new Error('Challenge is full');
  }

  // Guard: ensure user row exists (auth user may not have a users profile row yet)
  await db.from('users').upsert(
    { id: userId },
    { onConflict: 'id', ignoreDuplicates: true },
  );

  // Check for existing participation before billing
  const { data: existing } = await db
    .from('challenge_participants')
    .select('id')
    .eq('challenge_id', challengeId)
    .eq('user_id', userId)
    .maybeSingle();

  if (existing) throw new Error('Already joined this challenge');

  const idempotencyKey = `challenge_join:${userId}:${challengeId}`;

  if (challenge.entry_fee > 0) {
    await debitWalletForChallenge(userId, challenge.entry_fee, challengeId, idempotencyKey);
  }

  const { error: joinErr } = await db
    .from('challenge_participants')
    .upsert(
      { challenge_id: challengeId, user_id: userId },
      { onConflict: 'challenge_id,user_id', ignoreDuplicates: true },
    );
  if (joinErr) throw new Error(joinErr.message);

  try {
    const redis = getRedis();
    await redis.zadd(`leaderboard:challenge:${challengeId}`, 0, userId);
  } catch { /* Redis optional */ }

  return { joined: true, challenge_id: challengeId };
}
```

- [ ] **Step 2: Commit**
```bash
git add stepup-api/src/modules/challenges/challenges.service.ts
git commit -m "fix: joinChallenge uses upsert + guards missing users row to prevent FK violation"
```

---

## Task 3: Add `getChallengeProgress` to the service

**Files:**
- Modify: `stepup-api/src/modules/challenges/challenges.service.ts`

Progress logic per activity type:
- `steps` / `walking` / `running` → sum `user_daily_steps.total_steps` for days in [start_time, end_time]
- `gym` → count `activities` rows with `activity_type = 'gym'`
- `cycling` → count `activities` rows with `activity_type = 'cycle'`
- `outdoor` → count `activities` rows with `activity_type = 'sport'`

Daily check-in: for each day from `start_time` to today, determine if the user met their daily target. For steps: `daily_steps >= dailyGoal`. For sessions: any activity logged that day.

- [ ] **Step 1: Add the `getChallengeProgress` export at the bottom of `challenges.service.ts`**

```ts
export async function getChallengeProgress(userId: string, challengeId: string) {
  const db = getSupabase();

  const { data: participation } = await db
    .from('challenge_participants')
    .select('joined_at')
    .eq('challenge_id', challengeId)
    .eq('user_id', userId)
    .maybeSingle();

  if (!participation) return { joined: false };

  const challenge = await getChallenge(challengeId);
  const activityType = (challenge as any).activity_type as string;

  const startDate = challenge.start_time.slice(0, 10);
  const endDate = challenge.end_time.slice(0, 10);
  const now = new Date();
  const todayDate = now.toISOString().slice(0, 10);
  const clampedEndDate = endDate < todayDate ? endDate : todayDate;

  const totalDays = Math.max(
    1,
    Math.round(
      (new Date(challenge.end_time).getTime() - new Date(challenge.start_time).getTime()) /
        86_400_000,
    ),
  );
  const daysPassed = Math.min(
    totalDays,
    Math.max(
      0,
      Math.round((now.getTime() - new Date(challenge.start_time).getTime()) / 86_400_000),
    ),
  );
  const dailyGoal = Math.round(challenge.step_goal / totalDays);

  let current = 0;
  let dailyCheckins: boolean[] = [];

  const isStepBased = ['steps', 'walking', 'running'].includes(activityType);

  if (isStepBased) {
    const { data: stepRows } = await db
      .from('user_daily_steps')
      .select('date, total_steps')
      .eq('user_id', userId)
      .gte('date', startDate)
      .lte('date', clampedEndDate)
      .order('date', { ascending: true });

    const stepMap: Record<string, number> = {};
    for (const row of stepRows ?? []) stepMap[row.date] = row.total_steps;
    current = Object.values(stepMap).reduce((s, v) => s + v, 0);

    // Build per-day checkin array from start to today
    const cursor = new Date(challenge.start_time);
    cursor.setHours(0, 0, 0, 0);
    while (cursor.toISOString().slice(0, 10) <= clampedEndDate) {
      const d = cursor.toISOString().slice(0, 10);
      dailyCheckins.push((stepMap[d] ?? 0) >= dailyGoal);
      cursor.setDate(cursor.getDate() + 1);
    }
  } else {
    const activityFilter: Record<string, string> = {
      gym: 'gym',
      cycling: 'cycle',
      outdoor: 'sport',
    };
    const dbType = activityFilter[activityType] ?? activityType;

    const { data: actRows } = await db
      .from('activities')
      .select('date')
      .eq('user_id', userId)
      .eq('activity_type', dbType)
      .gte('date', startDate)
      .lte('date', clampedEndDate)
      .order('date', { ascending: true });

    const daysWithActivity = new Set((actRows ?? []).map((r: any) => r.date as string));
    current = daysWithActivity.size;

    const cursor = new Date(challenge.start_time);
    cursor.setHours(0, 0, 0, 0);
    while (cursor.toISOString().slice(0, 10) <= clampedEndDate) {
      const d = cursor.toISOString().slice(0, 10);
      dailyCheckins.push(daysWithActivity.has(d));
      cursor.setDate(cursor.getDate() + 1);
    }
  }

  const completedToday = dailyCheckins.length > 0 && dailyCheckins[dailyCheckins.length - 1];

  let rank: number | null = null;
  let totalParticipants = (challenge as any).participant_count as number ?? 0;
  try {
    const redis = getRedis();
    const card = await redis.zcard(`leaderboard:challenge:${challengeId}`);
    if (card > 0) {
      const rankFromBottom = await redis.zrank(`leaderboard:challenge:${challengeId}`, userId);
      if (rankFromBottom !== null) rank = card - rankFromBottom;
    }
  } catch { /* Redis optional */ }

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
  };
}
```

- [ ] **Step 2: Commit**
```bash
git add stepup-api/src/modules/challenges/challenges.service.ts
git commit -m "feat: add getChallengeProgress — computes real per-user challenge progress from DB"
```

---

## Task 4: Add `GET /challenges/:id/progress` route

**Files:**
- Modify: `stepup-api/src/modules/challenges/challenges.router.ts`

- [ ] **Step 1: Import `getChallengeProgress` and add the route**

At the top of `challenges.router.ts`, update the import:
```ts
import { listChallenges, getChallenge, joinChallenge, listMyChallenges, getChallengeProgress } from './challenges.service';
```

Add this route **before** the `GET /:id` route (so `/:id/progress` is matched first):
```ts
challengesRouter.get('/:id/progress', async (req: Request, res: Response) => {
  try {
    const data = await getChallengeProgress(req.user!.id, req.params['id'] as string);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});
```

Full file after edit:
```ts
import { Router, Request, Response } from 'express';
import { listChallenges, getChallenge, joinChallenge, listMyChallenges, getChallengeProgress } from './challenges.service';

export const challengesRouter = Router();

challengesRouter.get('/mine', async (req: Request, res: Response) => {
  try {
    const data = await listMyChallenges(req.user!.id);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

challengesRouter.get('/', async (req: Request, res: Response) => {
  try {
    const status = req.query.status as string | undefined;
    const data = await listChallenges(status);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

challengesRouter.get('/:id/progress', async (req: Request, res: Response) => {
  try {
    const data = await getChallengeProgress(req.user!.id, req.params['id'] as string);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

challengesRouter.get('/:id', async (req: Request, res: Response) => {
  try {
    const data = await getChallenge(req.params['id'] as string);
    res.json(data);
  } catch {
    res.status(404).json({ error: 'Challenge not found' });
  }
});

challengesRouter.post('/:id/join', async (req: Request, res: Response) => {
  try {
    const result = await joinChallenge(req.user!.id, req.params['id'] as string);
    res.json(result);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    let status = 500;
    if (msg.includes('Already')) status = 409;
    else if (msg.includes('balance') || msg.includes('full')) status = 400;
    res.status(status).json({ error: msg });
  }
});
```

- [ ] **Step 2: Commit**
```bash
git add stepup-api/src/modules/challenges/challenges.router.ts
git commit -m "feat: add GET /challenges/:id/progress endpoint"
```

---

## Task 5: Add `ChallengeProgress` model in Flutter

**Files:**
- Modify: `stepup/lib/shared/models/challenge.dart`

- [ ] **Step 1: Add `ChallengeProgress` class at the bottom of `challenge.dart`**

Append after the `ActivityConfig` class:

```dart
class ChallengeProgress {
  final bool joined;
  final int current;
  final int goal;
  final double percent;
  final int totalDays;
  final int daysPassed;
  final int daysLeft;
  final int dailyGoal;
  final bool completedToday;
  final List<bool> dailyCheckins;
  final int? rank;
  final int totalParticipants;
  final String activityType;
  final int prizePool;

  const ChallengeProgress({
    required this.joined,
    required this.current,
    required this.goal,
    required this.percent,
    required this.totalDays,
    required this.daysPassed,
    required this.daysLeft,
    required this.dailyGoal,
    required this.completedToday,
    required this.dailyCheckins,
    required this.rank,
    required this.totalParticipants,
    required this.activityType,
    required this.prizePool,
  });

  factory ChallengeProgress.fromJson(Map<String, dynamic> j) => ChallengeProgress(
        joined: j['joined'] as bool,
        current: (j['current'] as num).toInt(),
        goal: (j['goal'] as num).toInt(),
        percent: (j['percent'] as num).toDouble(),
        totalDays: (j['totalDays'] as num).toInt(),
        daysPassed: (j['daysPassed'] as num).toInt(),
        daysLeft: (j['daysLeft'] as num).toInt(),
        dailyGoal: (j['dailyGoal'] as num).toInt(),
        completedToday: j['completedToday'] as bool,
        dailyCheckins: (j['dailyCheckins'] as List).map((e) => e as bool).toList(),
        rank: (j['rank'] as num?)?.toInt(),
        totalParticipants: (j['totalParticipants'] as num).toInt(),
        activityType: (j['activityType'] as String?) ?? 'steps',
        prizePool: (j['prizePool'] as num).toInt(),
      );

  String get prizePoolCoins => '${prizePool ~/ 100}¢';
}
```

- [ ] **Step 2: Commit**
```bash
git add stepup/lib/shared/models/challenge.dart
git commit -m "feat: add ChallengeProgress model"
```

---

## Task 6: Add `challengeProgressProvider` in Flutter

**Files:**
- Modify: `stepup/lib/features/challenges/providers/challenges_provider.dart`

- [ ] **Step 1: Add the import and provider**

Replace the entire file contents:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/challenge.dart';

final activeChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final data = await ApiClient.instance.get('/challenges', {'status': 'active'}) as List;
  return data.map((j) => Challenge.fromJson(j as Map<String, dynamic>)).toList();
});

final myChallengesProvider = FutureProvider<List<Challenge>>((ref) async {
  final data = await ApiClient.instance.get('/challenges/mine') as List;
  return data.map((j) => Challenge.fromJson(j as Map<String, dynamic>)).toList();
});

final challengeDetailProvider = FutureProvider.family<Challenge, String>((ref, id) async {
  final data = await ApiClient.instance.get('/challenges/$id') as Map<String, dynamic>;
  return Challenge.fromJson(data);
});

final challengeProgressProvider = FutureProvider.family<ChallengeProgress?, String>((ref, id) async {
  final data = await ApiClient.instance.get('/challenges/$id/progress') as Map<String, dynamic>;
  if (data['joined'] == false) return null;
  return ChallengeProgress.fromJson(data);
});
```

- [ ] **Step 2: Commit**
```bash
git add stepup/lib/features/challenges/providers/challenges_provider.dart
git commit -m "feat: add challengeProgressProvider"
```

---

## Task 7: Fix `_MyChallengeTile` — real progress bar

**Files:**
- Modify: `stepup/lib/features/challenges/screens/challenges_screen.dart`

Currently `_MyChallengeTile` computes `pct = daysPassed / days` (calendar time). It should show actual progress from `challengeProgressProvider`.

`_MyChallengeTile` is a `StatelessWidget` and sits inside a `ListView` built from `_MyChallengesView`, which is a `StatefulWidget`. We need to make `_MyChallengeTile` a `ConsumerWidget` so it can watch the progress provider.

- [ ] **Step 1: Add `flutter_riverpod` import to `challenges_screen.dart`**

The import is already there (`package:flutter_riverpod/flutter_riverpod.dart`) — verify it's present at the top. Also add the challenges_provider import if not present:
```dart
import '../providers/challenges_provider.dart';
```
Both are already imported. No change needed here.

- [ ] **Step 2: Replace `_MyChallengeTile` with a `ConsumerWidget`**

Find the `_MyChallengeTile` class (starts around line 684) and replace it entirely with:

```dart
class _MyChallengeTile extends ConsumerWidget {
  final Challenge challenge;
  final bool highlight;
  const _MyChallengeTile({required this.challenge, required this.highlight});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(challengeProgressProvider(challenge.id));
    final cfg = challenge.activity;

    final days = challenge.endTime.difference(challenge.startTime).inDays.clamp(1, 9999);
    final daysPassed = DateTime.now().difference(challenge.startTime).inDays.clamp(0, days);

    final double pct = progressAsync.whenOrNull(
          data: (p) => p?.percent,
        ) ??
        (daysPassed / days).clamp(0.0, 1.0);

    final String progressLabel = progressAsync.whenOrNull(
          data: (p) {
            if (p == null) return 'Day $daysPassed/$days';
            if (['gym', 'cycling', 'outdoor'].contains(p.activityType)) {
              return '${p.current}/${p.goal} sessions · Day $daysPassed/$days';
            }
            final cur = p.current >= 1000
                ? '${(p.current / 1000).toStringAsFixed(1)}k'
                : '${p.current}';
            final goal = p.goal >= 1000
                ? '${(p.goal / 1000).toStringAsFixed(0)}k'
                : '${p.goal}';
            return '$cur/$goal steps · Day $daysPassed/$days';
          },
        ) ??
        'Day $daysPassed/$days';

    return GestureDetector(
      onTap: () => context.push('/challenges/${challenge.id}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            height: 130,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: cfg.colorA.withValues(alpha: 0.2)),
                Image.asset(
                  _activityImageAsset(challenge.activityType, challenge.id),
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => const SizedBox(),
                ),
                Container(color: Colors.black.withValues(alpha: 0.52)),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.3, 1.0],
                      colors: [
                        Colors.transparent,
                        cfg.colorA.withValues(alpha: 0.6),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        _CardBadge(
                          label: cfg.label.toUpperCase(),
                          bgColor: cfg.colorA.withValues(alpha: 0.85),
                          textColor: Colors.white,
                        ),
                        const Spacer(),
                        _CardBadge(
                          label: '${(pct * 100).round()}%',
                          bgColor: pct >= 1.0
                              ? AppTheme.voltLime
                              : Colors.white.withValues(alpha: 0.2),
                          textColor: pct >= 1.0 ? AppTheme.bg : Colors.white,
                        ),
                      ]),
                      const Spacer(),
                      Text(
                        challenge.title,
                        style: AppTheme.bigNum(17).copyWith(fontStyle: FontStyle.italic),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(3),
                            child: LinearProgressIndicator(
                              value: pct,
                              minHeight: 4,
                              backgroundColor: Colors.white.withValues(alpha: 0.15),
                              valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(progressLabel,
                            style: AppTheme.label(10,
                                color: Colors.white.withValues(alpha: 0.7))),
                        const SizedBox(width: 8),
                        Text(challenge.prizePoolCoins,
                            style: AppTheme.label(10, color: AppTheme.amber)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**
```bash
git add stepup/lib/features/challenges/screens/challenges_screen.dart
git commit -m "feat: _MyChallengeTile shows real progress from API, not calendar time"
```

---

## Task 8: Rewrite `ChallengeCheckinScreen` with real data

**Files:**
- Rewrite: `stepup/lib/features/challenges/screens/challenge_checkin_screen.dart`

The screen receives `id` (challenge ID). It needs to watch both `challengeDetailProvider(id)` and `challengeProgressProvider(id)` to show real data.

- [ ] **Step 1: Replace the entire file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/challenges_provider.dart';
import '../../../core/theme.dart';

class ChallengeCheckinScreen extends ConsumerWidget {
  final String id;
  const ChallengeCheckinScreen({required this.id, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeDetailProvider(id));
    final progressAsync = ref.watch(challengeProgressProvider(id));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: challengeAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) => Center(child: Text('$e', style: AppTheme.label(13))),
          data: (challenge) => progressAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
            error: (e, _) => Center(child: Text('$e', style: AppTheme.label(13))),
            data: (progress) {
              if (progress == null) {
                return Center(
                  child: Text("You haven't joined this challenge.",
                      style: AppTheme.label(14, color: AppTheme.ink2)),
                );
              }
              return _CheckinBody(challenge: challenge, progress: progress);
            },
          ),
        ),
      ),
    );
  }
}

class _CheckinBody extends StatelessWidget {
  final dynamic challenge;
  final dynamic progress;

  const _CheckinBody({required this.challenge, required this.progress});

  @override
  Widget build(BuildContext context) {
    // We import Challenge and ChallengeProgress via the provider file
    final c = challenge as dynamic;
    final p = progress as dynamic;

    final int totalDays = p.totalDays as int;
    final int daysPassed = p.daysPassed as int;
    final bool completedToday = p.completedToday as bool;
    final List<bool> checkins = List<bool>.from(p.dailyCheckins as List);

    // Build a week-window: last 7 days (or fewer if challenge < 7 days)
    final windowSize = totalDays.clamp(1, 7);
    final windowStart = (daysPassed - windowSize + 1).clamp(0, daysPassed);
    final windowCheckins = checkins.length >= windowStart + windowSize
        ? checkins.sublist(windowStart, windowStart + windowSize)
        : checkins.length > windowStart
            ? checkins.sublist(windowStart)
            : <bool>[];

    final weekDayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final progressPct = p.percent as double;
    final int currentVal = p.current as int;
    final int goalVal = p.goal as int;
    final String actType = p.activityType as String;
    final int prizePool = p.prizePool as int;

    String progressText;
    if (['gym', 'cycling', 'outdoor'].contains(actType)) {
      progressText = '$currentVal / $goalVal sessions';
    } else {
      final cur = currentVal >= 1000
          ? '${(currentVal / 1000).toStringAsFixed(1)}k'
          : '$currentVal';
      final goal =
          goalVal >= 1000 ? '${(goalVal / 1000).toStringAsFixed(0)}k' : '$goalVal';
      progressText = '$cur / $goal steps';
    }

    return Padding(
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
              Text('Day $daysPassed of $totalDays',
                  style: AppTheme.label(13, color: AppTheme.ink2)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Check in', style: AppTheme.bigNum(28)),
          const SizedBox(height: 4),
          Text(
            '${c.title} · today\'s status',
            style: AppTheme.label(13, color: AppTheme.ink2),
          ),
          const SizedBox(height: 24),

          // Status circle
          Center(
            child: Column(children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completedToday
                      ? AppTheme.voltLime.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: completedToday ? AppTheme.voltLime : AppTheme.border,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    completedToday ? '✓' : '○',
                    style: AppTheme.bigNum(
                      44,
                      color: completedToday ? AppTheme.voltLime : AppTheme.ink2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                completedToday ? 'Done today!' : 'Not yet today',
                style: AppTheme.bigNum(22),
              ),
              const SizedBox(height: 4),
              Text(
                progressText,
                style: AppTheme.label(12, color: AppTheme.ink2),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 16),

          Text('Recent days',
              style: AppTheme.label(11, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 10),

          // Week strip
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(windowSize, (i) {
              final isDone = i < windowCheckins.length && windowCheckins[i];
              final isToday = i == windowCheckins.length - 1;

              Color borderColor;
              Color bgColor;
              Color textColor;
              String label;

              if (isDone) {
                borderColor = AppTheme.voltLime;
                bgColor = AppTheme.voltLime;
                textColor = AppTheme.bg;
                label = '✓';
              } else if (isToday) {
                borderColor = AppTheme.voltLime;
                bgColor = AppTheme.voltLime.withValues(alpha: 0.2);
                textColor = AppTheme.voltLime;
                label = '●';
              } else {
                borderColor = AppTheme.ink3;
                bgColor = Colors.transparent;
                textColor = AppTheme.ink3;
                label = '';
              }

              final dayIdx = (windowStart + i) % 7;
              return Column(children: [
                Text(weekDayLabels[dayIdx],
                    style: AppTheme.label(10, color: AppTheme.ink2)),
                const SizedBox(height: 4),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(label,
                        style: AppTheme.label(13, color: textColor)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]);
            }),
          ),

          // Overall progress bar
          const SizedBox(height: 20),
          Text('Overall progress',
              style: AppTheme.label(11, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPct,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(progressText, style: AppTheme.label(11, color: AppTheme.ink2)),
              Text('${(progressPct * 100).round()}%',
                  style: AppTheme.label(11, color: AppTheme.voltLime)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),

          const Spacer(),

          // Reward banner
          if (prizePool > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Finish in top 50% to earn',
                      style: AppTheme.label(12, color: AppTheme.ink2)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('+${prizePool ~/ 100} ¢',
                        style: AppTheme.bigNum(12, color: AppTheme.amber)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/leaderboard'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('View challenge leaderboard →',
                  style: AppTheme.label(13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Fix the `_CheckinBody` to use proper typed imports**

The `_CheckinBody` above uses `dynamic` to avoid circular issues. Replace the `_CheckinBody` widget to use the proper types. Add these imports at the top of the file:

```dart
import '../../../shared/models/challenge.dart';
```

Then update `_CheckinBody`:

```dart
class _CheckinBody extends StatelessWidget {
  final Challenge challenge;
  final ChallengeProgress progress;

  const _CheckinBody({required this.challenge, required this.progress});
```

And remove all the `as dynamic` / `as int` / `as bool` / `as List` casts, using direct field access instead (`progress.totalDays`, `progress.daysPassed`, etc.).

The complete corrected file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/challenges_provider.dart';
import '../../../shared/models/challenge.dart';
import '../../../core/theme.dart';

class ChallengeCheckinScreen extends ConsumerWidget {
  final String id;
  const ChallengeCheckinScreen({required this.id, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final challengeAsync = ref.watch(challengeDetailProvider(id));
    final progressAsync = ref.watch(challengeProgressProvider(id));

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: challengeAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
          error: (e, _) => Center(child: Text('$e', style: AppTheme.label(13))),
          data: (challenge) => progressAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppTheme.voltLime)),
            error: (e, _) => Center(child: Text('$e', style: AppTheme.label(13))),
            data: (progress) {
              if (progress == null) {
                return Center(
                  child: Text("You haven't joined this challenge.",
                      style: AppTheme.label(14, color: AppTheme.ink2)),
                );
              }
              return _CheckinBody(challenge: challenge, progress: progress);
            },
          ),
        ),
      ),
    );
  }
}

class _CheckinBody extends StatelessWidget {
  final Challenge challenge;
  final ChallengeProgress progress;

  const _CheckinBody({required this.challenge, required this.progress});

  @override
  Widget build(BuildContext context) {
    final int totalDays = progress.totalDays;
    final int daysPassed = progress.daysPassed;
    final bool completedToday = progress.completedToday;
    final List<bool> checkins = progress.dailyCheckins;

    final windowSize = totalDays.clamp(1, 7);
    final windowStart = (daysPassed - windowSize + 1).clamp(0, daysPassed);
    final windowCheckins = checkins.length >= windowStart + windowSize
        ? checkins.sublist(windowStart, windowStart + windowSize)
        : checkins.length > windowStart
            ? checkins.sublist(windowStart)
            : <bool>[];

    final weekDayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    final progressPct = progress.percent;
    final int currentVal = progress.current;
    final int goalVal = progress.goal;
    final String actType = progress.activityType;
    final int prizePool = progress.prizePool;

    String progressText;
    if (['gym', 'cycling', 'outdoor'].contains(actType)) {
      progressText = '$currentVal / $goalVal sessions';
    } else {
      final cur = currentVal >= 1000
          ? '${(currentVal / 1000).toStringAsFixed(1)}k'
          : '$currentVal';
      final goal =
          goalVal >= 1000 ? '${(goalVal / 1000).toStringAsFixed(0)}k' : '$goalVal';
      progressText = '$cur / $goal steps';
    }

    return Padding(
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
              Text('Day $daysPassed of $totalDays',
                  style: AppTheme.label(13, color: AppTheme.ink2)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Check in', style: AppTheme.bigNum(28)),
          const SizedBox(height: 4),
          Text(
            '${challenge.title} · today\'s status',
            style: AppTheme.label(13, color: AppTheme.ink2),
          ),
          const SizedBox(height: 24),

          Center(
            child: Column(children: [
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completedToday
                      ? AppTheme.voltLime.withValues(alpha: 0.08)
                      : Colors.white.withValues(alpha: 0.04),
                  border: Border.all(
                    color: completedToday ? AppTheme.voltLime : AppTheme.border,
                    width: 3,
                  ),
                ),
                child: Center(
                  child: Text(
                    completedToday ? '✓' : '○',
                    style: AppTheme.bigNum(
                      44,
                      color: completedToday ? AppTheme.voltLime : AppTheme.ink2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                completedToday ? 'Done today!' : 'Not yet today',
                style: AppTheme.bigNum(22),
              ),
              const SizedBox(height: 4),
              Text(
                progressText,
                style: AppTheme.label(12, color: AppTheme.ink2),
                textAlign: TextAlign.center,
              ),
            ]),
          ),
          const SizedBox(height: 24),
          Divider(color: Colors.white.withValues(alpha: 0.08)),
          const SizedBox(height: 16),

          Text('Recent days',
              style: AppTheme.label(11, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 10),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(windowSize, (i) {
              final isDone = i < windowCheckins.length && windowCheckins[i];
              final isToday = i == windowCheckins.length - 1;

              Color borderColor;
              Color bgColor;
              Color textColor;
              String label;

              if (isDone) {
                borderColor = AppTheme.voltLime;
                bgColor = AppTheme.voltLime;
                textColor = AppTheme.bg;
                label = '✓';
              } else if (isToday) {
                borderColor = AppTheme.voltLime;
                bgColor = AppTheme.voltLime.withValues(alpha: 0.2);
                textColor = AppTheme.voltLime;
                label = '●';
              } else {
                borderColor = AppTheme.ink3;
                bgColor = Colors.transparent;
                textColor = AppTheme.ink3;
                label = '';
              }

              final dayIdx = (windowStart + i) % 7;
              return Column(children: [
                Text(weekDayLabels[dayIdx],
                    style: AppTheme.label(10, color: AppTheme.ink2)),
                const SizedBox(height: 4),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColor,
                    border: Border.all(color: borderColor),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(label,
                        style: AppTheme.label(13, color: textColor)
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]);
            }),
          ),

          const SizedBox(height: 20),
          Text('Overall progress',
              style: AppTheme.label(11, color: AppTheme.ink2)
                  .copyWith(fontWeight: FontWeight.w700, letterSpacing: 0.6)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progressPct,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: const AlwaysStoppedAnimation(AppTheme.voltLime),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(progressText, style: AppTheme.label(11, color: AppTheme.ink2)),
              Text('${(progressPct * 100).round()}%',
                  style: AppTheme.label(11, color: AppTheme.voltLime)
                      .copyWith(fontWeight: FontWeight.w700)),
            ],
          ),

          const Spacer(),

          if (prizePool > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppTheme.amber.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.amber.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Finish in top 50% to earn',
                      style: AppTheme.label(12, color: AppTheme.ink2)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('+${prizePool ~/ 100} ¢',
                        style: AppTheme.bigNum(12, color: AppTheme.amber)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/leaderboard'),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('View challenge leaderboard →',
                  style: AppTheme.label(13, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Commit**
```bash
git add stepup/lib/features/challenges/screens/challenge_checkin_screen.dart
git commit -m "feat: rewrite ChallengeCheckinScreen with real API data — live progress, check-in days, prize"
```

---

## Task 9: Invalidate providers after join

**Files:**
- Modify: `stepup/lib/features/challenges/screens/challenge_detail_screen.dart`

After a successful join, `myChallengesProvider` and `challengeProgressProvider` must be invalidated so the data refreshes without restarting the app.

- [ ] **Step 1: Add the import and invalidation to `_join()` in `challenge_detail_screen.dart`**

Add the provider import at the top of the file (it may already be there):
```dart
import '../providers/challenges_provider.dart';
```

Find the `_join()` method. After `setState(() { _joining = false; _joined = true; })`, add invalidations:

```dart
Future<void> _join() async {
  setState(() => _joining = true);
  try {
    await ApiClient.instance.post('/challenges/${widget.id}/join', {});
    if (mounted) {
      setState(() {
        _joining = false;
        _joined = true;
      });
      ref.invalidate(myChallengesProvider);
      ref.invalidate(challengeProgressProvider(widget.id));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Joined! Good luck 🏆')),
      );
    }
  } catch (e) {
    if (!mounted) return;
    setState(() => _joining = false);
    final msg = e.toString().toLowerCase();
    if (msg.contains('already') || msg.contains('409')) {
      setState(() => _joined = true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You're already in this challenge!")),
      );
    } else if (msg.contains('balance')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Insufficient coins to join')),
      );
    } else if (msg.contains('full')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This challenge is full')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
}
```

- [ ] **Step 2: Commit**
```bash
git add stepup/lib/features/challenges/screens/challenge_detail_screen.dart
git commit -m "fix: invalidate myChallengesProvider and challengeProgressProvider after join"
```

---

## Task 10: Final verification

- [ ] **Step 1: Build the API in TypeScript**
```bash
cd /Users/harsha/StepUp/stepup-api && npx tsc --noEmit
```
Expected: zero type errors.

- [ ] **Step 2: Check Flutter compiles**
```bash
cd /Users/harsha/StepUp/stepup && flutter analyze lib/features/challenges/ lib/shared/models/challenge.dart
```
Expected: zero errors.

- [ ] **Step 3: Manually verify join from the app**
Build and install (from memory: `flutter build ios --release` then `xcrun devicectl device install app --device 00008120-001E6C6C0101A01E`). Open the app, go to a challenge you haven't joined, tap Join. It should:
1. Succeed without error
2. The challenge immediately appears in My → Active tab (provider invalidated)
3. Progress bar shows 0% (not a day-based percentage)

- [ ] **Step 4: Verify check-in screen**
Tap a joined challenge → "Check in today →". The screen should show:
- Real challenge title (not hardcoded "7-Day Gym Consistency")
- Real day count (e.g. "Day 1 of 7")
- Status circle showing ✓ if you've met today's goal, ○ if not
- Week strip with real checked/unchecked days
- Overall progress bar with actual step count

- [ ] **Step 5: Final commit tag**
```bash
git tag challenges-module-fix
```
