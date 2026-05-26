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

  const joined = participations?.length ?? 0;
  let wins = 0;
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

  await db.from('users').update({
    reputation_score: score,
    reputation_updated_at: new Date().toISOString(),
  }).eq('id', userId);

  const { count: totalUsers } = await db
    .from('users')
    .select('*', { count: 'exact', head: true });
  const { count: higherCount } = await db
    .from('users')
    .select('*', { count: 'exact', head: true })
    .gt('reputation_score', score);
  const percentileRank = Math.round(((higherCount ?? 0) / Math.max(totalUsers ?? 1, 1)) * 100);

  const { data: u } = await db
    .from('users')
    .select('reputation_snapshot_prev, best_streak_days')
    .eq('id', userId)
    .single();
  const monthlyDelta = score - (u?.reputation_snapshot_prev ?? 0);

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

  if (today.getDate() === 1) {
    const { data: allUsers } = await db.from('users').select('id, reputation_score');
    for (const u of allUsers ?? []) {
      await db.from('users')
        .update({ reputation_snapshot_prev: u.reputation_score })
        .eq('id', u.id);
    }
  }

  const { data: users } = await db.from('users').select('id').not('id', 'is', null);
  for (const user of users ?? []) {
    await calculateReputation(user.id).catch(() => {});
  }
}
