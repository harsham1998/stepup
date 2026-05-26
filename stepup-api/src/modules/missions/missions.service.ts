// stepup-api/src/modules/missions/missions.service.ts
import { getSupabase } from '../../lib/supabase';
import { awardXp } from '../steps/xp.service';

export async function getMissions(userId: string, type: 'daily' | 'weekly' | 'seasonal') {
  const db = getSupabase();
  const today = new Date().toISOString().slice(0, 10);

  // Get all active missions of this type
  const { data: missions } = await db
    .from('missions')
    .select('*')
    .eq('type', type)
    .eq('active', true)
    .order('coin_reward', { ascending: false });

  if (!missions || missions.length === 0) return [];

  // Get user's progress for today
  const missionIds = missions.map(m => m.id);
  const { data: progress } = await db
    .from('user_missions')
    .select('*')
    .eq('user_id', userId)
    .in('mission_id', missionIds)
    .eq('assigned_date', today);

  const progressMap = Object.fromEntries((progress ?? []).map(p => [p.mission_id, p]));

  // Ensure user_missions rows exist for today
  const toInsert = missions
    .filter(m => !progressMap[m.id])
    .map(m => ({ user_id: userId, mission_id: m.id, assigned_date: today, progress: 0, completed: false }));

  if (toInsert.length > 0) {
    await db.from('user_missions').insert(toInsert);
    // Re-fetch progress after insert
    const { data: freshProgress } = await db
      .from('user_missions')
      .select('*')
      .eq('user_id', userId)
      .in('mission_id', missionIds)
      .eq('assigned_date', today);
    freshProgress?.forEach(p => { progressMap[p.mission_id] = p; });
  }

  return missions.map(m => ({
    id: m.id,
    slug: m.slug,
    title: m.title,
    description: m.description,
    type: m.type,
    activity: m.activity,
    target: m.target,
    unit: m.unit,
    coin_reward: m.coin_reward,
    xp_reward: m.xp_reward,
    progress: progressMap[m.id]?.progress ?? 0,
    completed: progressMap[m.id]?.completed ?? false,
    completed_at: progressMap[m.id]?.completed_at ?? null,
  }));
}

export async function syncMissionProgress(userId: string) {
  const db = getSupabase();
  const today = new Date().toISOString().slice(0, 10);

  // Get today's daily steps
  const { data: dailySteps } = await db
    .from('user_daily_steps')
    .select('total_steps')
    .eq('user_id', userId)
    .eq('date', today)
    .maybeSingle();

  const steps = dailySteps?.total_steps ?? 0;

  // Get all incomplete step-based daily missions for today
  const { data: userMissions } = await db
    .from('user_missions')
    .select('*, missions(*)')
    .eq('user_id', userId)
    .eq('assigned_date', today)
    .eq('completed', false);

  for (const um of userMissions ?? []) {
    const mission = (um as any).missions;
    if (!mission || mission.activity !== 'walk') continue;

    const newProgress = Math.min(steps, mission.target);
    const completed = newProgress >= mission.target;

    await db.from('user_missions').update({
      progress: newProgress,
      completed,
      completed_at: completed ? new Date().toISOString() : null,
    }).eq('id', um.id);

    if (completed) {
      await awardMissionReward(userId, mission.coin_reward, mission.xp_reward, db);
    }
  }
}

async function awardMissionReward(
  userId: string,
  coins: number,
  xp: number,
  db: ReturnType<typeof getSupabase>
) {
  if (coins > 0) {
    await db.rpc('increment_coins', { uid: userId, amount: coins });
  }
  if (xp > 0) {
    await awardXp(userId, xp);
  }
}
