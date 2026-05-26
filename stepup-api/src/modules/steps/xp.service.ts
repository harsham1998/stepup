// stepup-api/src/modules/steps/xp.service.ts
import { getSupabase } from '../../lib/supabase';

const DAILY_STEP_GOAL = 10_000;
export { DAILY_STEP_GOAL };

const LEVEL_TITLES: Record<number, string> = {
  1: 'Walker', 10: 'Mover', 20: 'Challenger', 35: 'Athlete', 50: 'Elite', 75: 'Legend', 100: 'Immortal',
};

function getLevelTitle(level: number): string {
  for (const bp of [100, 75, 50, 35, 20, 10, 1]) {
    if (level >= bp) return LEVEL_TITLES[bp];
  }
  return 'Walker';
}

export function xpForNextLevel(level: number): number {
  return Math.floor(1000 * Math.pow(1.15, level - 1));
}

export async function awardXp(userId: string, amount: number) {
  if (amount <= 0) return;
  const db = getSupabase();

  // Upsert user_levels row
  const { data: row } = await db
    .from('user_levels')
    .select('xp, level')
    .eq('user_id', userId)
    .maybeSingle();

  let { xp = 0, level = 1 } = row ?? {};
  const newXp = xp + amount;

  // Process level-ups
  let currentLevel = level;
  let tempXp = newXp;
  while (tempXp >= xpForNextLevel(currentLevel)) {
    currentLevel++;
    const coinReward = currentLevel * 10;
    // Award level-up coins (fire-and-forget, non-blocking)
    void db.rpc('increment_coins', { uid: userId, amount: coinReward });
  }

  // Update user_levels
  await db.from('user_levels').upsert(
    { user_id: userId, xp: newXp, level: currentLevel, title: getLevelTitle(currentLevel) },
    { onConflict: 'user_id' },
  );

  // Keep users.xp in sync for league calculations
  await db.from('users').update({ xp: newXp }).eq('id', userId);
}

// Thin wrapper — keeps steps.service.ts working without changes
export async function awardStepXp(userId: string, steps: number) {
  const xp = Math.floor(steps / 1000) * 10;
  await awardXp(userId, xp);
}

// League recalc — called by the weekly cron in index.ts
const LEAGUE_THRESHOLDS = [
  { league: 'elite',    min_weekly_xp: 4000 },
  { league: 'gold',     min_weekly_xp: 1500 },
  { league: 'silver',   min_weekly_xp: 500  },
  { league: 'bronze',   min_weekly_xp: 0    },
];

export async function recalculateLeagues() {
  const db = getSupabase();
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  const since = sevenDaysAgo.toISOString().slice(0, 10);

  const { data: weeklySteps } = await db
    .from('user_daily_steps')
    .select('user_id, total_steps')
    .gte('date', since);

  const xpByUser: Record<string, number> = {};
  for (const row of weeklySteps ?? []) {
    xpByUser[row.user_id] = (xpByUser[row.user_id] ?? 0) + Math.floor(row.total_steps / 1000) * 10;
  }

  const { data: users } = await db.from('users').select('id');
  for (const user of users ?? []) {
    const weeklyXp = xpByUser[user.id] ?? 0;
    const league = LEAGUE_THRESHOLDS.find(t => weeklyXp >= t.min_weekly_xp)?.league ?? 'bronze';
    await db.from('users').update({ league }).eq('id', user.id);
  }
}
