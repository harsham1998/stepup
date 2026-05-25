// stepup-api/src/modules/streaks/streaks.service.ts
import { getSupabase } from '../../lib/supabase';

const REVIVE_COST_COINS = 100;

export async function getStreakStatus(userId: string) {
  const db = getSupabase();

  const { data: user } = await db
    .from('users')
    .select('streak_days, coin_balance')
    .eq('id', userId)
    .single();

  const monthKey = getMonthKey();

  const { data: shields } = await db
    .from('streak_shields')
    .select('*')
    .eq('user_id', userId)
    .eq('month', monthKey);

  const shieldUsed = (shields ?? []).some(s => s.type === 'shield');
  const reviveUsed = (shields ?? []).some(s => s.type === 'revive');

  // Check if streak is "at risk" (no steps logged yesterday)
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().slice(0, 10);

  const { data: ySteps } = await db
    .from('user_daily_steps')
    .select('total_steps')
    .eq('user_id', userId)
    .eq('date', yesterdayStr)
    .maybeSingle();

  const streakAtRisk = !ySteps || ySteps.total_steps < 1000;

  return {
    streak_days: user?.streak_days ?? 0,
    streak_at_risk: streakAtRisk,
    shield_available: !shieldUsed,
    shield_used_this_month: shieldUsed,
    revive_available: !reviveUsed,
    revive_cost_coins: REVIVE_COST_COINS,
    coin_balance: user?.coin_balance ?? 0,
    month_key: monthKey,
  };
}

export async function useShield(userId: string) {
  const db = getSupabase();
  const monthKey = getMonthKey();

  // Check subscription (must be pro)
  const { data: sub } = await db
    .from('user_subscriptions')
    .select('plan_slug')
    .eq('user_id', userId)
    .eq('status', 'active')
    .maybeSingle();

  if (!sub || sub.plan_slug !== 'pro') {
    throw new Error('Streak shield requires Pro subscription');
  }

  const { error } = await db.from('streak_shields').insert({
    user_id: userId,
    month: monthKey,
    type: 'shield',
  });

  if (error) {
    if (error.code === '23505') throw new Error('Shield already used this month');
    throw new Error(error.message);
  }

  return { shield_used: true, month: monthKey };
}

export async function reviveStreak(userId: string) {
  const db = getSupabase();
  const monthKey = getMonthKey();

  const { data: user } = await db
    .from('users')
    .select('coin_balance, streak_days')
    .eq('id', userId)
    .single();

  if (!user || user.coin_balance < REVIVE_COST_COINS) {
    throw new Error(`Need ${REVIVE_COST_COINS} coins to revive streak`);
  }

  const { error: shieldErr } = await db.from('streak_shields').insert({
    user_id: userId,
    month: monthKey,
    type: 'revive',
  });

  if (shieldErr) {
    if (shieldErr.code === '23505') throw new Error('Already revived this month');
    throw new Error(shieldErr.message);
  }

  // Debit coins + restore streak
  await db.from('users').update({
    coin_balance: user.coin_balance - REVIVE_COST_COINS,
    streak_days: Math.max(1, user.streak_days),
  }).eq('id', userId);

  return { revived: true, coins_spent: REVIVE_COST_COINS };
}

function getMonthKey(): number {
  const d = new Date();
  return d.getFullYear() * 100 + (d.getMonth() + 1);
}
