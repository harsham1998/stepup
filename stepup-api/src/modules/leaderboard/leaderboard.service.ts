import { getSupabase } from '../../lib/supabase';

function tryGetRedis() {
  try {
    const { getRedis } = require('../../lib/redis');
    return getRedis();
  } catch {
    return null;
  }
}

interface LeaderboardEntry {
  rank: number;
  user_id: string;
  name: string;
  city: string;
  steps: number;
}

async function enrichWithProfiles(rankedIds: string[]): Promise<Record<string, { name: string; city: string }>> {
  if (rankedIds.length === 0) return {};
  const { data } = await getSupabase().from('users').select('id, name, city').in('id', rankedIds);
  return Object.fromEntries((data ?? []).map((u: { id: string; name: string; city: string }) => [u.id, { name: u.name, city: u.city }]));
}

async function parseRedisRanks(key: string, limit = 100): Promise<LeaderboardEntry[]> {
  const redis = tryGetRedis();
  if (!redis) return [];
  try {
    const raw = await redis.zrevrange(key, 0, limit - 1, 'WITHSCORES');
    const ids: string[] = [];
    const scores: Record<string, number> = {};
    for (let i = 0; i < raw.length; i += 2) {
      ids.push(raw[i]);
      scores[raw[i]] = parseInt(raw[i + 1], 10);
    }
    const profiles = await enrichWithProfiles(ids);
    return ids.map((id, idx) => ({
      rank: idx + 1,
      user_id: id,
      steps: scores[id],
      name: profiles[id]?.name ?? 'Unknown',
      city: profiles[id]?.city ?? '',
    }));
  } catch {
    return [];
  }
}

// Falls back to leaderboard_snapshots (Supabase) when Redis has no data.
async function getGlobalFromSnapshots(limit = 100): Promise<LeaderboardEntry[]> {
  const { data } = await getSupabase()
    .from('leaderboard_snapshots')
    .select('user_id, rank, steps, users(name, city)')
    .eq('scope', 'global')
    .order('snapped_at', { ascending: false });

  // Deduplicate: keep the most recent snapshot per user
  const seen = new Set<string>();
  const deduped = (data ?? []).filter((row: any) => {
    if (seen.has(row.user_id)) return false;
    seen.add(row.user_id);
    return true;
  });

  return deduped
    .sort((a: any, b: any) => a.rank - b.rank)
    .slice(0, limit)
    .map((row: any, idx: number) => ({
      rank: idx + 1,
      user_id: row.user_id,
      steps: row.steps,
      name: (row.users as any)?.name ?? 'Unknown',
      city: (row.users as any)?.city ?? '',
    }));
}

export async function getGlobalLeaderboard(limit = 100): Promise<LeaderboardEntry[]> {
  const today = new Date().toISOString().slice(0, 10);
  const redisEntries = await parseRedisRanks(`leaderboard:global:${today}`, limit);
  if (redisEntries.length > 0) return redisEntries;
  return getGlobalFromSnapshots(limit);
}

export async function getCityLeaderboard(city: string, limit = 100): Promise<LeaderboardEntry[]> {
  const today = new Date().toISOString().slice(0, 10);
  return parseRedisRanks(`leaderboard:city:${city}:${today}`, limit);
}

export async function getFriendsLeaderboard(userId: string, limit = 50): Promise<LeaderboardEntry[]> {
  const { data: friends } = await getSupabase()
    .from('friendships')
    .select('friend_id')
    .eq('user_id', userId);
  const friendIds = (friends ?? []).map((f: { friend_id: string }) => f.friend_id);
  friendIds.push(userId);

  const all = await getGlobalLeaderboard(1000);
  const filtered = all.filter(e => friendIds.includes(e.user_id));
  return filtered.slice(0, limit).map((e, i) => ({ ...e, rank: i + 1 }));
}

export async function getUserRank(userId: string): Promise<{ rank: number; steps: number }> {
  const redis = tryGetRedis();
  if (redis) {
    try {
      const today = new Date().toISOString().slice(0, 10);
      const key = `leaderboard:global:${today}`;
      const [rank, score] = await Promise.all([
        redis.zrevrank(key, userId),
        redis.zscore(key, userId),
      ]);
      if (rank !== null) {
        return { rank: (rank ?? 0) + 1, steps: parseInt(score ?? '0', 10) };
      }
    } catch {}
  }
  // Fall back to snapshot data
  const { data } = await getSupabase()
    .from('leaderboard_snapshots')
    .select('rank, steps')
    .eq('user_id', userId)
    .eq('scope', 'global')
    .order('snapped_at', { ascending: false })
    .limit(1)
    .maybeSingle();
  return { rank: data?.rank ?? 0, steps: data?.steps ?? 0 };
}
