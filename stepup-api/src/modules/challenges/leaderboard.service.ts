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
      // Returns [member, score, member, score, ...]
      const raw = await redis.zrevrange(redisKey, 0, -1, 'WITHSCORES');
      for (let i = 0; i < raw.length; i += 2) {
        scores[raw[i]] = parseFloat(raw[i + 1]);
      }
    }
  } catch { /* Redis optional — fall through to DB */ }

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
