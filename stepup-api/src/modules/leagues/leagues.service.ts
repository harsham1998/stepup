// stepup-api/src/modules/leagues/leagues.service.ts
import { getSupabase } from '../../lib/supabase';

const TIERS = ['bronze','silver','gold','platinum','diamond','elite'];

export async function getMyLeague(userId: string) {
  const db = getSupabase();

  // Ensure user_leagues row exists
  const { data: existing } = await db
    .from('user_leagues')
    .select('*')
    .eq('user_id', userId)
    .maybeSingle();

  const userLeague = existing ?? await createUserLeague(userId, db);

  // Get all tier definitions
  const { data: allLeagues } = await db
    .from('leagues')
    .select('*')
    .order('sort_order');

  // Get user's current tier definition
  const currentTier = (allLeagues ?? []).find(l => l.slug === userLeague.league_slug)!;
  const xpForNext = currentTier.xp_max ?? (currentTier.xp_min + 1000);

  // Count total users in this tier for rank display
  const { count: totalInTier } = await db
    .from('user_leagues')
    .select('*', { count: 'exact', head: true })
    .eq('league_slug', userLeague.league_slug);

  // Get user profile for subscription check
  const { data: sub } = await db
    .from('user_subscriptions')
    .select('plan_slug')
    .eq('user_id', userId)
    .eq('status', 'active')
    .maybeSingle();

  const isPro = sub?.plan_slug === 'pro';

  return {
    league_slug: userLeague.league_slug,
    label: currentTier.label,
    color_hex: currentTier.color_hex,
    xp: userLeague.xp,
    xp_min: currentTier.xp_min,
    xp_for_next: xpForNext,
    rank_in_tier: userLeague.rank_in_tier ?? 1,
    total_in_tier: totalInTier ?? 1,
    season: userLeague.season,
    tier_ladder: (allLeagues ?? []).map(l => ({
      ...l,
      locked: l.paid_only && !isPro,
      is_current: l.slug === userLeague.league_slug,
    })),
  };
}

async function createUserLeague(userId: string, db: ReturnType<typeof getSupabase>) {
  const { data: user } = await db
    .from('users')
    .select('xp')
    .eq('id', userId)
    .single();

  const xp = user?.xp ?? 0;
  const slug = xpToLeagueSlug(xp);

  await db.from('user_leagues').upsert({
    user_id: userId,
    league_slug: slug,
    xp,
    season: 1,
    updated_at: new Date().toISOString(),
  }, { onConflict: 'user_id' });

  return { league_slug: slug, xp, rank_in_tier: null, season: 1 };
}

function xpToLeagueSlug(xp: number): string {
  if (xp >= 10000) return 'elite';
  if (xp >= 5000)  return 'diamond';
  if (xp >= 3000)  return 'platinum';
  if (xp >= 2000)  return 'gold';
  if (xp >= 1000)  return 'silver';
  return 'bronze';
}

export async function getFriendsStandings(userId: string) {
  const db = getSupabase();

  // Get friend IDs
  const { data: friendships } = await db
    .from('friendships')
    .select('friend_id')
    .eq('user_id', userId);

  const friendIds = (friendships ?? []).map(f => f.friend_id);
  const allIds = [userId, ...friendIds];

  // Get league entries for user + friends
  const { data: rows } = await db
    .from('user_leagues')
    .select('user_id, xp, league_slug')
    .in('user_id', allIds);

  if (!rows || rows.length === 0) return { entries: [], my_rank: 1 };

  // Sort by XP descending
  rows.sort((a, b) => b.xp - a.xp);

  const userIds = rows.map(r => r.user_id);
  const { data: users } = await db
    .from('users')
    .select('id, name, avatar_url, streak_days')
    .in('id', userIds);

  const userMap = Object.fromEntries((users ?? []).map(u => [u.id, u]));
  const myXp = rows.find(r => r.user_id === userId)?.xp ?? 0;

  const entries = rows.map((r, i) => ({
    rank: i + 1,
    user_id: r.user_id,
    name: userMap[r.user_id]?.name ?? 'Unknown',
    avatar_url: userMap[r.user_id]?.avatar_url ?? null,
    streak_days: userMap[r.user_id]?.streak_days ?? 0,
    xp: r.xp,
    league_slug: r.league_slug,
    is_me: r.user_id === userId,
    xp_gap: r.user_id === userId ? 0 : r.xp - myXp,
  }));

  const myRank = entries.find(e => e.is_me)?.rank ?? 1;

  return { entries, my_rank: myRank };
}

export async function getStandings(userId: string, page = 1) {
  const db = getSupabase();
  const pageSize = 50;
  const offset = (page - 1) * pageSize;

  // Find user's tier
  const { data: ul } = await db
    .from('user_leagues')
    .select('league_slug')
    .eq('user_id', userId)
    .maybeSingle();

  const leagueSlug = ul?.league_slug ?? 'bronze';

  const { data: rows } = await db
    .from('user_leagues')
    .select('user_id, xp, rank_in_tier')
    .eq('league_slug', leagueSlug)
    .order('xp', { ascending: false })
    .range(offset, offset + pageSize - 1);

  if (!rows || rows.length === 0) return { league_slug: leagueSlug, entries: [], page };

  // Enrich with user names
  const userIds = rows.map(r => r.user_id);
  const { data: users } = await db
    .from('users')
    .select('id, name, avatar_url, streak_days')
    .in('id', userIds);

  const userMap = Object.fromEntries((users ?? []).map(u => [u.id, u]));

  const entries = rows.map((r, i) => ({
    rank: offset + i + 1,
    user_id: r.user_id,
    name: userMap[r.user_id]?.name ?? 'Unknown',
    avatar_url: userMap[r.user_id]?.avatar_url ?? null,
    streak_days: userMap[r.user_id]?.streak_days ?? 0,
    xp: r.xp,
    is_me: r.user_id === userId,
  }));

  const { count: total } = await db
    .from('user_leagues')
    .select('*', { count: 'exact', head: true })
    .eq('league_slug', leagueSlug);

  return { league_slug: leagueSlug, entries, page, total_in_league: total ?? 0 };
}
