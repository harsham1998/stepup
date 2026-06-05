// stepup-api/src/modules/body-vitals/body_vitals.service.ts
import { getSupabase } from '../../lib/supabase';
import { awardXp } from '../steps/xp.service';

export interface VitalsPayload {
  weight_kg?: number;
  bmi?: number;
  visceral_fat_level?: number;
  muscle_percentage?: number;
}

export interface GoalPayload {
  goal_weight_kg?: number;
  goal_bmi?: number;
}

/** Log today's vitals. Upserts by (user_id, date). Awards +10 XP once per day. */
export async function logVitals(userId: string, payload: VitalsPayload) {
  const db = getSupabase();
  const today = new Date().toISOString().slice(0, 10);

  const { error } = await db.from('body_vitals_entries').upsert(
    {
      user_id: userId,
      date: today,
      ...(payload.weight_kg !== undefined && { weight_kg: payload.weight_kg }),
      ...(payload.bmi !== undefined && { bmi: payload.bmi }),
      ...(payload.visceral_fat_level !== undefined && { visceral_fat_level: payload.visceral_fat_level }),
      ...(payload.muscle_percentage !== undefined && { muscle_percentage: payload.muscle_percentage }),
      updated_at: new Date().toISOString(),
    },
    { onConflict: 'user_id,date' },
  );
  if (error) throw new Error(error.message);

  // Award +10 XP once per calendar day
  const { error: xpLogErr } = await db
    .from('body_vitals_xp_log')
    .insert({ user_id: userId, date: today });

  // xpLogErr code '23505' = unique violation = already awarded today → skip
  if (!xpLogErr) {
    await awardXp(userId, 10);
  } else if (xpLogErr.code !== '23505') {
    throw new Error(xpLogErr.message);
  }

  return { success: true, xp_awarded: !xpLogErr };
}

/** Return history for the last `days` days (for heatmap). */
export async function getHistory(userId: string, days = 42) {
  const db = getSupabase();
  const since = new Date();
  since.setDate(since.getDate() - days);
  const sinceStr = since.toISOString().slice(0, 10);

  const { data, error } = await db
    .from('body_vitals_entries')
    .select('date, weight_kg, bmi, visceral_fat_level, muscle_percentage')
    .eq('user_id', userId)
    .gte('date', sinceStr)
    .order('date', { ascending: true });

  if (error) throw new Error(error.message);
  return data ?? [];
}

/** Summary: latest entry + earliest entry in range + goal. */
export async function getSummary(userId: string) {
  const db = getSupabase();

  const { data: entries, error: eErr } = await db
    .from('body_vitals_entries')
    .select('date, weight_kg, bmi, visceral_fat_level, muscle_percentage')
    .eq('user_id', userId)
    .order('date', { ascending: false })
    .limit(30);
  if (eErr) throw new Error(eErr.message);

  const { data: goal, error: gErr } = await db
    .from('body_vitals_goals')
    .select('goal_weight_kg, goal_bmi')
    .eq('user_id', userId)
    .maybeSingle();
  if (gErr) throw new Error(gErr.message);

  // Logging streak: consecutive days ending today with an entry
  const today = new Date().toISOString().slice(0, 10);
  let streak = 0;
  const dateSet = new Set((entries ?? []).map((e: { date: string }) => e.date));
  for (let i = 0; i < 365; i++) {
    const d = new Date();
    d.setDate(d.getDate() - i);
    if (!dateSet.has(d.toISOString().slice(0, 10))) break;
    streak++;
  }

  const latest = entries?.[0] ?? null;
  const earliest = entries?.[entries.length - 1] ?? null;

  return {
    latest,
    earliest,
    goal: goal ?? null,
    logging_streak: streak,
    logged_today: latest?.date === today,
  };
}

/** Set or update user's body goal. */
export async function setGoal(userId: string, payload: GoalPayload) {
  const db = getSupabase();
  const { error } = await db.from('body_vitals_goals').upsert(
    { user_id: userId, ...payload, updated_at: new Date().toISOString() },
    { onConflict: 'user_id' },
  );
  if (error) throw new Error(error.message);
  return { success: true };
}
