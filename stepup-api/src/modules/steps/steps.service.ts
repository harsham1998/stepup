import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { StepSyncPayload } from '../../types';
import { runAnticheatChecks } from './anticheat.service';

const SYNC_INTERVAL_MINUTES = 15;

export async function syncSteps(userId: string, payload: StepSyncPayload) {
  const flagReason = runAnticheatChecks(payload, SYNC_INTERVAL_MINUTES);
  const db = getSupabase();

  const { data: log, error: logErr } = await db
    .from('step_logs')
    .insert({
      user_id: userId,
      steps: payload.steps,
      synced_at: payload.syncedAt,
      source: payload.source,
      device_model: payload.deviceModel,
      os_version: payload.osVersion,
      flagged: flagReason !== null,
    })
    .select()
    .single();
  if (logErr) throw new Error(logErr.message);

  if (flagReason && log) {
    await db.from('step_flags').insert({
      user_id: userId,
      step_log_id: log.id,
      reason: flagReason,
    });
  }

  if (flagReason) return { accepted: false, steps: payload.steps, flagged: true };

  const today = new Date().toISOString().slice(0, 10);
  await db.rpc('increment_daily_steps', {
    p_user_id: userId,
    p_date: today,
    p_steps: payload.steps,
  });

  await updateLeaderboardsForUser(userId, payload.steps);

  // Award XP (fire-and-forget)
  import('./xp.service').then(({ awardStepXp }) => awardStepXp(userId, payload.steps)).catch(() => {});

  return { accepted: true, steps: payload.steps };
}

async function updateLeaderboardsForUser(userId: string, newSteps: number) {
  const redis = getRedis();
  const db = getSupabase();

  const { data: participations } = await db
    .from('challenge_participants')
    .select('challenge_id')
    .eq('user_id', userId);

  const today = new Date().toISOString().slice(0, 10);
  const globalKey = `leaderboard:global:${today}`;
  await redis.zincrby(globalKey, newSteps, userId);
  await redis.expire(globalKey, 60 * 60 * 48);

  for (const p of participations ?? []) {
    const key = `leaderboard:challenge:${p.challenge_id}`;
    await redis.zincrby(key, newSteps, userId);
  }
}
