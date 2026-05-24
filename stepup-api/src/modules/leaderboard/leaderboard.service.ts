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

export async function getGlobalLeaderboard(limit = 100): Promise<LeaderboardEntry[]> {
  const today = new Date().toISOString().slice(0, 10);
  return parseRedisRanks(`leaderboard:global:${today}`, limit);
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
  if (!redis) return { rank: 0, steps: 0 };
  try {
    const today = new Date().toISOString().slice(0, 10);
    const key = `leaderboard:global:${today}`;
    const [rank, score] = await Promise.all([
      redis.zrevrank(key, userId),
      redis.zscore(key, userId),
    ]);
    return { rank: (rank ?? 0) + 1, steps: parseInt(score ?? '0', 10) };
  } catch {
    return { rank: 0, steps: 0 };
  }
}
