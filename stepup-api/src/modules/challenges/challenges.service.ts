import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { logger } from '../../lib/logger';
import { ChallengeRow, ChallengeMissionRow, MissionProgress } from '../../types';

const _VALID_ACTIVITY_TYPES = new Set(['steps', 'walking', 'running', 'gym', 'outdoor', 'cycling']);

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

// Derive UI cadence from challenge duration so the frontend tab filter works
function _getCadence(startTime: string, endTime: string): string {
  const days = Math.round(
    (new Date(endTime).getTime() - new Date(startTime).getTime()) / 86_400_000,
  );
  if (days <= 1) return 'daily';
  if (days <= 7) return 'weekly';
  if (days <= 31) return 'monthly';
  return 'seasonal';
}

async function withParticipantCount(challenges: ChallengeRow[]) {
  const ids = challenges.map(c => c.id);
  if (ids.length === 0) return challenges;
  const { data } = await getSupabase()
    .from('challenge_participants')
    .select('challenge_id')
    .in('challenge_id', ids);
  const counts: Record<string, number> = {};
  for (const row of data ?? []) {
    counts[row.challenge_id] = (counts[row.challenge_id] ?? 0) + 1;
  }
  return challenges.map(c => ({
    ...c,
    // Override type with cadence key so Flutter tab filter works
    type: _getCadence(c.start_time, c.end_time),
    // Use sponsor_name column to store activity type without schema change
    activity_type: _VALID_ACTIVITY_TYPES.has(c.sponsor_name ?? '') ? c.sponsor_name! : 'steps',
    participant_count: counts[c.id] ?? 0,
  }));
}

export async function listMyChallenges(userId: string) {
  const db = getSupabase();
  const { data: participations, error: pErr } = await db
    .from('challenge_participants')
    .select('challenge_id')
    .eq('user_id', userId);
  if (pErr) throw new Error(pErr.message);
  const ids = (participations ?? []).map((p: any) => p.challenge_id);
  if (ids.length === 0) return [];
  const { data, error } = await db
    .from('challenges')
    .select('*')
    .in('id', ids)
    .order('start_time', { ascending: true });
  if (error) throw new Error(error.message);
  return withParticipantCount((data ?? []) as ChallengeRow[]);
}

export async function listChallenges(status?: string) {
  let query = getSupabase()
    .from('challenges')
    .select('*')
    .order('start_time', { ascending: true });
  if (status) query = query.eq('status', status);
  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return withParticipantCount((data ?? []) as ChallengeRow[]);
}

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

  try {
    const redis = getRedis();
    await redis.zadd(`leaderboard:challenge:${challengeId}`, 0, userId);
  } catch { /* Redis optional */ }

  return { joined: true, challenge_id: challengeId };
}

async function debitWalletForChallenge(
  userId: string,
  amount: number,
  challengeId: string,
  idempotencyKey: string,
) {
  const db = getSupabase();
  const { data: txns } = await db
    .from('wallet_transactions')
    .select('type, amount, status')
    .eq('user_id', userId)
    .neq('status', 'rejected');

  const balance = (txns ?? []).reduce((sum: number, t: { type: string; amount: number }) =>
    t.type === 'credit' ? sum + t.amount : sum - t.amount, 0);
  if (balance < amount) throw new Error('Insufficient wallet balance');

  const { error } = await db.from('wallet_transactions').insert({
    user_id: userId,
    type: 'debit',
    amount,
    idempotency_key: idempotencyKey,
    description: `Entry fee for challenge ${challengeId}`,
  });
  if (error && error.code !== '23505') throw new Error(error.message);
}

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

  let stepMap: Record<string, number> = {};
  if (isStepBased) {
    const { data: stepRows } = await db
      .from('user_daily_steps')
      .select('date, total_steps')
      .eq('user_id', userId)
      .gte('date', startDate)
      .lte('date', clampedEndDate)
      .order('date', { ascending: true });

    for (const row of stepRows ?? []) stepMap[row.date] = row.total_steps;
    current = Object.values(stepMap).reduce((s, v) => s + v, 0);

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
  const totalParticipants = (challenge as any).participant_count as number ?? 0;
  try {
    const redis = getRedis();
    const card = await redis.zcard(`leaderboard:challenge:${challengeId}`);
    if (card > 0) {
      const rankFromBottom = await redis.zrank(`leaderboard:challenge:${challengeId}`, userId);
      if (rankFromBottom !== null) rank = card - rankFromBottom;
    }
  } catch { /* Redis optional */ }

  // --- Mission progress for linked challenge missions ---
  const challengeMissions = await fetchChallengeMissions(challengeId);
  const missionProgress: MissionProgress[] = [];

  if (challengeMissions.length > 0) {
    const todayDate2 = new Date().toISOString().slice(0, 10);
    const todaySteps = isStepBased ? (stepMap[todayDate2] ?? 0) : 0;

    for (const m of challengeMissions) {
      const progressCurrent = m.type === 'daily' ? todaySteps : current;
      const isCompleted = progressCurrent >= m.target;
      missionProgress.push({
        mission_id: m.mission_id,
        title: m.title,
        target: m.target,
        current: progressCurrent,
        unit: m.unit,
        completed: isCompleted,
        xp_earned: isCompleted ? m.xp_reward + m.bonus_xp : 0,
        total_xp: m.xp_reward + m.bonus_xp,
      });
    }
  }

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
}

// Finds all active challenges past their end_time, marks them ended, and queues payout.
// Called by the challenge-ender cron in index.ts every 10 minutes.
export async function endExpiredChallenges() {
  const { schedulePayoutJob, processPayout } = await import('./payout.job');
  const db = getSupabase();
  const now = new Date().toISOString();

  const { data: expired, error } = await db
    .from('challenges')
    .select('id, title')
    .eq('status', 'active')
    .lt('end_time', now);

  if (error) { logger.error({ err: error }, 'endExpiredChallenges: query failed'); return; }
  if (!expired || expired.length === 0) return;

  for (const c of expired) {
    const { error: updateErr } = await db
      .from('challenges').update({ status: 'ended' }).eq('id', c.id);
    if (updateErr) {
      logger.error({ challengeId: c.id, err: updateErr }, 'Failed to mark challenge ended');
      continue;
    }
    try {
      await schedulePayoutJob(c.id, new Date());
      logger.info({ challengeId: c.id, title: c.title }, 'Challenge ended and payout queued');
    } catch (queueErr) {
      // BullMQ unavailable — run payout synchronously as fallback
      logger.warn({ challengeId: c.id, err: queueErr }, 'Queue unavailable, running payout synchronously');
      await processPayout(c.id).catch(err =>
        logger.error({ challengeId: c.id, err }, 'Synchronous payout failed')
      );
    }
  }
}
