import { getSupabase } from '../../lib/supabase';

const XP_PER_1K_STEPS = 10;

const LEAGUE_THRESHOLDS = [
  { league: 'elite',  min_weekly_xp: 4000 },
  { league: 'gold',   min_weekly_xp: 1500 },
  { league: 'silver', min_weekly_xp: 500  },
  { league: 'bronze', min_weekly_xp: 0    },
];

const BADGES: Array<{ slug: string; check: (xp: number, streak: number) => boolean }> = [
  { slug: 'streak_7',  check: (_xp, s) => s >= 7  },
  { slug: 'streak_21', check: (_xp, s) => s >= 21 },
  { slug: 'streak_30', check: (_xp, s) => s >= 30 },
];

export async function awardStepXp(userId: string, steps: number) {
  const xpEarned = Math.floor(steps / 1000) * XP_PER_1K_STEPS;
  if (xpEarned === 0) return;

  const db = getSupabase();
  const { data: user } = await db.from('users').select('xp, streak_days').eq('id', userId).single();
  const newXp = (user?.xp ?? 0) + xpEarned;

  await db.from('users').update({ xp: newXp }).eq('id', userId);
  await checkAndAwardBadges(userId, newXp, user?.streak_days ?? 0, db);
}

async function checkAndAwardBadges(
  userId: string,
  xp: number,
  streak: number,
  db: ReturnType<typeof getSupabase>
) {
  for (const badge of BADGES) {
    if (badge.check(xp, streak)) {
      await db.from('user_badges')
        .upsert(
          { user_id: userId, badge_slug: badge.slug, earned_at: new Date().toISOString() },
          { onConflict: 'user_id,badge_slug', ignoreDuplicates: true }
        );
    }
  }
}

export async function recalculateLeagues() {
  const db = getSupabase();
  const sevenDaysAgo = new Date();
  sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
  const since = sevenDaysAgo.toISOString().slice(0, 10);

  // Get weekly steps per user from user_daily_steps
  const { data: weeklySteps } = await db
    .from('user_daily_steps')
    .select('user_id, total_steps')
    .gte('date', since);

  // Aggregate steps per user and compute weekly XP
  const xpByUser: Record<string, number> = {};
  for (const row of weeklySteps ?? []) {
    const xp = Math.floor(row.total_steps / 1000) * 10;
    xpByUser[row.user_id] = (xpByUser[row.user_id] ?? 0) + xp;
  }

  // Get all users to reset league for inactive users too
  const { data: users } = await db.from('users').select('id');
  for (const user of users ?? []) {
    const weeklyXp = xpByUser[user.id] ?? 0;
    const league = LEAGUE_THRESHOLDS.find(t => weeklyXp >= t.min_weekly_xp)?.league ?? 'bronze';
    await db.from('users').update({ league }).eq('id', user.id);
  }
}
