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

  const results = (leagues ?? []).map((ul: any) => ({
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
      try { await db.rpc('increment_coins', { uid: result.user_id, amount: result.coins_awarded }); } catch { /* best-effort */ }
    }
  }

  // Step 3: Soft-decay users.xp by tier_decay_pct
  const decayMultiplier = (100 - season.tier_decay_pct) / 100;
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
