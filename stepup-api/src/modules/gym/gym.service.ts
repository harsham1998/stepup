// stepup-api/src/modules/gym/gym.service.ts
import { getSupabase } from '../../lib/supabase';
import { awardXp } from '../steps/xp.service';
import { logger } from '../../lib/logger';

const XP_PER_SET = 10;
const XP_EXERCISE_BONUS = 25;
const XP_WORKOUT_COMPLETE = 150;
const XP_CARDIO_COMPLETE = 75;

// ── Types ─────────────────────────────────────────────────────────────────────

export interface PlanExercise {
  id: string;
  name: string;
  target_muscles: string[];
  sets: number;
  reps_label: string;
  equipment: string;
  sort_order: number;
}

export interface WorkoutPlan {
  id: string;
  slug: string;
  name: string;
  day_of_week: number;
  muscle_groups: string[];
  is_rest: boolean;
  exercises: PlanExercise[];
}

export interface WeekDay {
  day_of_week: number;        // 0=Sun … 6=Sat
  plan: WorkoutPlan | null;
  session_date: string;       // ISO date yyyy-mm-dd
  has_session: boolean;
  is_completed: boolean;
  xp_awarded: number;
}

export interface SetLog {
  id: string;
  exercise_id: string;
  set_number: number;
  weight_kg: number | null;
  reps: number | null;
  duration_secs: number | null;
  logged_at: string;
  xp_awarded: number;
}

export interface SessionWithLogs {
  id: string;
  plan_id: string;
  plan: WorkoutPlan;
  session_date: string;
  started_at: string;
  completed_at: string | null;
  xp_awarded: number;
  set_logs: SetLog[];
}

export interface ExerciseHistoryEntry {
  session_date: string;
  set_number: number;
  weight_kg: number | null;
  reps: number | null;
}

// ── Helpers ───────────────────────────────────────────────────────────────────

function isoDate(d: Date): string {
  return d.toISOString().slice(0, 10);
}

function startOfWeek(d: Date): Date {
  const day = d.getDay(); // 0=Sun
  const diff = d.getDate() - day + (day === 0 ? -6 : 1); // start on Mon
  const monday = new Date(d);
  monday.setDate(diff);
  monday.setHours(0, 0, 0, 0);
  return monday;
}

// ── Service functions ─────────────────────────────────────────────────────────

export async function getWeekPlan(userId: string): Promise<WeekDay[]> {
  const db = getSupabase();
  const today = new Date();
  const monday = startOfWeek(today);

  // Load all plans with exercises
  const { data: plans, error: plansErr } = await db
    .from('gym_workout_plans')
    .select('*, gym_plan_exercises(*)')
    .order('sort_order');

  if (plansErr) throw plansErr;

  // Build date list for this week Mon–Sun
  const weekDates: string[] = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(monday);
    d.setDate(monday.getDate() + i);
    return isoDate(d);
  });

  // Load sessions for this week
  const { data: sessions } = await db
    .from('gym_sessions')
    .select('session_date, completed_at, xp_awarded')
    .eq('user_id', userId)
    .in('session_date', weekDates);

  const sessionMap = Object.fromEntries((sessions ?? []).map(s => [s.session_date, s]));

  // Map each Mon-Sun day
  return weekDates.map((dateStr, idx) => {
    const dayOfWeek = (idx + 1) % 7; // Mon=1,...,Sun=0
    const plan = (plans ?? []).find(p => p.day_of_week === dayOfWeek) ?? null;
    const sess = sessionMap[dateStr];

    const exercises: PlanExercise[] = (plan?.gym_plan_exercises ?? [])
      .sort((a: any, b: any) => a.sort_order - b.sort_order)
      .map((e: any) => ({
        id: e.id,
        name: e.name,
        target_muscles: e.target_muscles ?? [],
        sets: e.sets,
        reps_label: e.reps_label,
        equipment: e.equipment,
        sort_order: e.sort_order,
      }));

    return {
      day_of_week: dayOfWeek,
      session_date: dateStr,
      has_session: !!sess,
      is_completed: !!sess?.completed_at,
      xp_awarded: sess?.xp_awarded ?? 0,
      plan: plan ? {
        id: plan.id,
        slug: plan.slug,
        name: plan.name,
        day_of_week: plan.day_of_week,
        muscle_groups: plan.muscle_groups ?? [],
        is_rest: plan.is_rest,
        exercises,
      } : null,
    };
  });
}

export async function getOrCreateSession(userId: string, date: string): Promise<SessionWithLogs> {
  const db = getSupabase();

  // Determine which plan belongs to this date's day of week
  const d = new Date(date + 'T12:00:00Z');
  const dow = d.getUTCDay(); // 0=Sun,1=Mon,...

  const { data: plan, error: planErr } = await db
    .from('gym_workout_plans')
    .select('*, gym_plan_exercises(*)')
    .eq('day_of_week', dow)
    .maybeSingle();

  if (planErr) throw planErr;
  if (!plan) throw new Error('No plan for this day');

  // Upsert session
  const { data: sess, error: sessErr } = await db
    .from('gym_sessions')
    .upsert(
      { user_id: userId, plan_id: plan.id, session_date: date },
      { onConflict: 'user_id,session_date', ignoreDuplicates: true }
    )
    .select()
    .maybeSingle();

  if (sessErr) throw sessErr;

  // Re-fetch to get the actual row (upsert may return null on ignoreDuplicates)
  const { data: row } = await db
    .from('gym_sessions')
    .select('*')
    .eq('user_id', userId)
    .eq('session_date', date)
    .single();

  if (!row) throw new Error('Session not found');

  // Load set logs
  const { data: logs } = await db
    .from('gym_set_logs')
    .select('*')
    .eq('session_id', row.id)
    .order('logged_at');

  const exercises: PlanExercise[] = (plan.gym_plan_exercises ?? [])
    .sort((a: any, b: any) => a.sort_order - b.sort_order)
    .map((e: any) => ({
      id: e.id,
      name: e.name,
      target_muscles: e.target_muscles ?? [],
      sets: e.sets,
      reps_label: e.reps_label,
      equipment: e.equipment,
      sort_order: e.sort_order,
    }));

  return {
    id: row.id,
    plan_id: plan.id,
    plan: {
      id: plan.id,
      slug: plan.slug,
      name: plan.name,
      day_of_week: plan.day_of_week,
      muscle_groups: plan.muscle_groups ?? [],
      is_rest: plan.is_rest,
      exercises,
    },
    session_date: row.session_date,
    started_at: row.started_at,
    completed_at: row.completed_at,
    xp_awarded: row.xp_awarded,
    set_logs: (logs ?? []).map((l: any) => ({
      id: l.id,
      exercise_id: l.exercise_id,
      set_number: l.set_number,
      weight_kg: l.weight_kg,
      reps: l.reps,
      duration_secs: l.duration_secs,
      logged_at: l.logged_at,
      xp_awarded: l.xp_awarded,
    })),
  };
}

export async function logSet(
  userId: string,
  sessionId: string,
  exerciseId: string,
  setNumber: number,
  weightKg: number | null,
  reps: number | null,
  durationSecs: number | null,
): Promise<SetLog> {
  const db = getSupabase();

  // Verify session belongs to user
  const { data: sess } = await db
    .from('gym_sessions')
    .select('id, completed_at')
    .eq('id', sessionId)
    .eq('user_id', userId)
    .maybeSingle();

  if (!sess) throw new Error('Session not found');
  if (sess.completed_at) throw new Error('Session already completed');

  // Upsert the set log
  const { data: log, error: logErr } = await db
    .from('gym_set_logs')
    .upsert(
      {
        session_id: sessionId,
        exercise_id: exerciseId,
        set_number: setNumber,
        weight_kg: weightKg,
        reps,
        duration_secs: durationSecs,
        xp_awarded: XP_PER_SET,
      },
      { onConflict: 'session_id,exercise_id,set_number' }
    )
    .select()
    .single();

  if (logErr) throw logErr;

  // Award XP for this set
  await awardXp(userId, XP_PER_SET);

  // Check if all sets for this exercise are now logged → award exercise bonus
  const { data: exercise } = await db
    .from('gym_plan_exercises')
    .select('sets')
    .eq('id', exerciseId)
    .single();

  if (exercise) {
    const { count } = await db
      .from('gym_set_logs')
      .select('*', { count: 'exact', head: true })
      .eq('session_id', sessionId)
      .eq('exercise_id', exerciseId);

    if ((count ?? 0) >= exercise.sets) {
      await awardXp(userId, XP_EXERCISE_BONUS);
    }
  }

  return {
    id: log.id,
    exercise_id: log.exercise_id,
    set_number: log.set_number,
    weight_kg: log.weight_kg,
    reps: log.reps,
    duration_secs: log.duration_secs,
    logged_at: log.logged_at,
    xp_awarded: log.xp_awarded,
  };
}

export async function deleteSet(
  userId: string,
  sessionId: string,
  exerciseId: string,
  setNumber: number,
): Promise<void> {
  const db = getSupabase();

  const { data: sess } = await db
    .from('gym_sessions')
    .select('id')
    .eq('id', sessionId)
    .eq('user_id', userId)
    .maybeSingle();

  if (!sess) throw new Error('Session not found');

  await db
    .from('gym_set_logs')
    .delete()
    .eq('session_id', sessionId)
    .eq('exercise_id', exerciseId)
    .eq('set_number', setNumber);
}

export async function completeSession(
  userId: string,
  sessionId: string,
): Promise<{ xp_awarded: number }> {
  const db = getSupabase();

  const { data: sess } = await db
    .from('gym_sessions')
    .select('*, gym_workout_plans(is_rest, slug)')
    .eq('id', sessionId)
    .eq('user_id', userId)
    .maybeSingle();

  if (!sess) throw new Error('Session not found');
  if (sess.completed_at) return { xp_awarded: 0 };

  const isCardio = sess.gym_workout_plans?.slug === 'cardio';
  const xp = isCardio ? XP_CARDIO_COMPLETE : XP_WORKOUT_COMPLETE;

  await db
    .from('gym_sessions')
    .update({ completed_at: new Date().toISOString(), xp_awarded: xp })
    .eq('id', sessionId);

  await awardXp(userId, xp);
  logger.info({ userId, sessionId, xp }, 'gym session completed');

  return { xp_awarded: xp };
}

export async function getExerciseHistory(
  userId: string,
  exerciseId: string,
): Promise<ExerciseHistoryEntry[]> {
  const db = getSupabase();

  const { data } = await db
    .from('gym_set_logs')
    .select('set_number, weight_kg, reps, gym_sessions!inner(session_date, user_id)')
    .eq('gym_sessions.user_id', userId)
    .eq('exercise_id', exerciseId)
    .order('logged_at', { ascending: false })
    .limit(60);

  return (data ?? []).map((r: any) => ({
    session_date: r.gym_sessions.session_date,
    set_number: r.set_number,
    weight_kg: r.weight_kg,
    reps: r.reps,
  }));
}
