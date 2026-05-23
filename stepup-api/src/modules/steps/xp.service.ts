import { getSupabase } from '../../lib/supabase';

const XP_PER_1K_STEPS = 10;

const LEAGUE_THRESHOLDS = [
  { league: 'elite',  min_xp: 4000 },
  { league: 'gold',   min_xp: 1500 },
  { league: 'silver', min_xp: 500  },
  { league: 'bronze', min_xp: 0    },
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
  userId: string, xp: number, streak: number,
  db: ReturnType<typeof getSupabase>,
) {
  for (const badge of BADGES) {
    if (badge.check(xp, streak)) {
      await db.from('user_badges').upsert(
        { user_id: userId, badge_slug: badge.slug },
        { onConflict: 'user_id,badge_slug', ignoreDuplicates: true },
      );
    }
  }
}

export async function recalculateLeagues() {
  const db = getSupabase();
  const { data: users } = await db.from('users').select('id, xp');
  for (const user of users ?? []) {
    const league = LEAGUE_THRESHOLDS.find(t => user.xp >= t.min_xp)?.league ?? 'bronze';
    await db.from('users').update({ league }).eq('id', user.id);
  }
}
