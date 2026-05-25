// stepup-api/src/modules/battlepass/battlepass.service.ts
import { getSupabase } from '../../lib/supabase';
import { BattlePassTier } from '../../types';

export async function getCurrentBattlePass(userId: string) {
  const db = getSupabase();

  const { data: bp } = await db
    .from('battle_passes')
    .select('*')
    .eq('active', true)
    .single();

  if (!bp) return null;

  // Ensure user battle pass row
  const { data: existing } = await db
    .from('user_battle_pass')
    .select('*')
    .eq('user_id', userId)
    .eq('season', bp.season)
    .maybeSingle();

  const ubp = existing ?? await createUserBattlePass(userId, bp.season, db);

  const tiers = bp.tiers as BattlePassTier[];
  const claimedTiers = (ubp.claimed_tiers ?? []) as number[];

  const endDate = new Date(bp.end_date);
  const now = new Date();
  const daysRemaining = Math.max(0, Math.ceil((endDate.getTime() - now.getTime()) / 86400000));

  return {
    season: bp.season,
    title: bp.title,
    start_date: bp.start_date,
    end_date: bp.end_date,
    days_remaining: daysRemaining,
    user_xp: ubp.xp,
    is_premium: ubp.is_premium,
    claimed_tiers: claimedTiers,
    tiers: tiers.map(t => ({
      ...t,
      unlocked: ubp.xp >= t.xp_required,
      claimed: claimedTiers.includes(t.level),
    })),
  };
}

async function createUserBattlePass(userId: string, season: number, db: ReturnType<typeof getSupabase>) {
  await db.from('user_battle_pass').insert({ user_id: userId, season, xp: 0, is_premium: false, claimed_tiers: [] });
  return { xp: 0, is_premium: false, claimed_tiers: [] };
}

export async function claimTier(userId: string, level: number) {
  const db = getSupabase();

  const { data: bp } = await db.from('battle_passes').select('*').eq('active', true).single();
  if (!bp) throw new Error('No active battle pass');

  const { data: ubp } = await db
    .from('user_battle_pass')
    .select('*')
    .eq('user_id', userId)
    .eq('season', bp.season)
    .single();
  if (!ubp) throw new Error('Not enrolled in battle pass');

  const tiers = bp.tiers as BattlePassTier[];
  const tier = tiers.find(t => t.level === level);
  if (!tier) throw new Error('Tier not found');
  if (ubp.xp < tier.xp_required) throw new Error('Not enough XP to claim this tier');

  const claimed = (ubp.claimed_tiers ?? []) as number[];
  if (claimed.includes(level)) throw new Error('Already claimed');

  const reward = ubp.is_premium ? tier.paid_reward : tier.free_reward;
  const newClaimed = [...claimed, level];

  await db.from('user_battle_pass')
    .update({ claimed_tiers: newClaimed })
    .eq('user_id', userId)
    .eq('season', bp.season);

  // Award coins if reward mentions coins
  const coinMatch = reward.match(/(\d+)\s*coins?/i);
  if (coinMatch) {
    const coins = parseInt(coinMatch[1], 10);
    const { data: user } = await db.from('users').select('coin_balance').eq('id', userId).single();
    await db.from('users').update({ coin_balance: (user?.coin_balance ?? 0) + coins }).eq('id', userId);
  }

  return { claimed: true, tier: level, reward };
}
