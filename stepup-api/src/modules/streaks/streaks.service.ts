// stepup-api/src/modules/streaks/streaks.service.ts
import { getSupabase } from '../../lib/supabase';
import { DAILY_STEP_GOAL } from '../steps/xp.service';

const REVIVE_COST_COINS = 100;

type DayStatus = 'full' | 'partial' | 'none';

function classifyDay(steps: number): DayStatus {
  if (steps >= DAILY_STEP_GOAL) return 'full';
  if (steps >= DAILY_STEP_GOAL * 0.5) return 'partial';
  return 'none';
}

export async function evaluateStreak(userId: string) {
  const db = getSupabase();

  const today = new Date().toISOString().slice(0, 10);
  const threeDaysAgo = new Date();
  threeDaysAgo.setDate(threeDaysAgo.getDate() - 2);
  const fromDate = threeDaysAgo.toISOString().slice(0, 10);

  const { data: stepRows } = await db
    .from('user_daily_steps')
    .select('date, total_steps')
    .eq('user_id', userId)
    .gte('date', fromDate)
    .lte('date', today)
    .order('date', { ascending: true });

  const stepMap: Record<string, number> = {};
  for (const row of stepRows ?? []) stepMap[row.date] = row.total_steps;

  const { data: user } = await db
    .from('users')
    .select('streak_days, best_streak_days, partial_day_count')
    .eq('id', userId)
    .single();

  if (!user) return;

  const todaySteps = stepMap[today] ?? 0;
  const todayStatus = classifyDay(todaySteps);

  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yStr = yesterday.toISOString().slice(0, 10);

  const yStatus = classifyDay(stepMap[yStr] ?? 0);

  let newStreakDays = user.streak_days;
  let newPartialCount = user.partial_day_count ?? 0;
  let breakDate: string | null = null;

  if (todayStatus === 'full') {
    newStreakDays = user.streak_days + 1;
    newPartialCount = 0;
  } else if (todayStatus === 'partial') {
    newPartialCount = (user.partial_day_count ?? 0) + 1;
    if (newPartialCount >= 3) {
      newStreakDays = 0;
      newPartialCount = 0;
      breakDate = today;
    }
  } else {
    newPartialCount = 0;
    if (yStatus === 'none') {
      newStreakDays = 0;
      breakDate = today;
    }
  }

  const newBest = Math.max(user.best_streak_days ?? 0, newStreakDays);

  const update: Record<string, unknown> = {
    streak_days: newStreakDays,
    best_streak_days: newBest,
    partial_day_count: newPartialCount,
  };
  if (breakDate) update.streak_break_date = breakDate;

  await db.from('users').update(update).eq('id', userId);
}

export async function getStreakCalendar(userId: string, days = 60) {
  const db = getSupabase();

  const endDate = new Date().toISOString().slice(0, 10);
  const startDt = new Date();
  startDt.setDate(startDt.getDate() - (days - 1));
  const startDate = startDt.toISOString().slice(0, 10);

  const { data: stepRows } = await db
    .from('user_daily_steps')
    .select('date, total_steps')
    .eq('user_id', userId)
    .gte('date', startDate)
    .lte('date', endDate)
    .order('date', { ascending: true });

  const stepMap: Record<string, number> = {};
  for (const row of stepRows ?? []) stepMap[row.date] = row.total_steps;

  const result: Array<{ date: string; steps: number; status: string; streak_count: number }> = [];
  let rollingStreak = 0;
  let partialCount = 0;

  const cursor = new Date(startDt);
  cursor.setHours(0, 0, 0, 0);

  while (cursor.toISOString().slice(0, 10) <= endDate) {
    const d = cursor.toISOString().slice(0, 10);
    const steps = stepMap[d] ?? 0;
    const status = classifyDay(steps);

    if (status === 'full') {
      rollingStreak++;
      partialCount = 0;
    } else if (status === 'partial') {
      partialCount++;
      if (partialCount >= 3) { rollingStreak = 0; partialCount = 0; }
    } else {
      partialCount = 0;
      if (result.length > 0 && result[result.length - 1].status === 'none') {
        rollingStreak = 0;
      }
    }

    result.push({ date: d, steps, status, streak_count: rollingStreak });
    cursor.setDate(cursor.getDate() + 1);
  }

  return result;
}

export async function getStreakStatus(userId: string) {
  const db = getSupabase();

  const { data: user } = await db
    .from('users')
    .select('streak_days, coin_balance, best_streak_days, streak_break_date')
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
    best_streak_days: user?.best_streak_days ?? 0,
    streak_break_date: user?.streak_break_date ?? null,
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
    .select('coin_balance, streak_days, streak_break_date')
    .eq('id', userId)
    .single();

  if (!user || user.coin_balance < REVIVE_COST_COINS) {
    throw new Error(`Need ${REVIVE_COST_COINS} coins to revive streak`);
  }

  if (user.streak_break_date) {
    const breakDate = new Date(user.streak_break_date);
    const diffDays = Math.floor((Date.now() - breakDate.getTime()) / 86_400_000);
    if (diffDays > 2) throw new Error('Revive window expired (2 days after break)');
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
