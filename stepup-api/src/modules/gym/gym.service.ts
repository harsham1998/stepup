// stepup-api/src/modules/gym/gym.service.ts
import { getSupabase } from '../../lib/supabase';
import { awardXp } from '../steps/xp.service';
import { logger } from '../../lib/logger';

const XP_PER_SET = 10;
const XP_EXERCISE_BONUS = 25;
const XP_WORKOUT_COMPLETE = 150;
const XP_CARDIO_COMPLETE = 75;

const BASE_IMG = 'https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises';

const EXERCISE_IMAGE_MAP: Record<string, string> = {
  'Machine Chest Press':     'Cable_Chest_Press',
  'Incline Dumbbell Press':  'Incline_Dumbbell_Press',
  'Pec Deck Fly':            'Cable_Crossover',
  'Rope Pushdown':           'Cable_Incline_Pushdown',
  'Overhead Rope Extension': 'Cable_Rope_Overhead_Triceps_Extension',
  'Lat Pulldown':            'Close-Grip_Front_Lat_Pulldown',
  'Seated Cable Row':        'Seated_Cable_Rows',
  'Chest Supported Row':     'Lying_T-Bar_Row',
  'Face Pull':               'Face_Pull',
  'Machine Curl':            'Machine_Preacher_Curls',
  'Hammer Curl':             'Alternate_Hammer_Curl',
  'Barbell Squat':           'Barbell_Squat',
  'Romanian Deadlift':       'Romanian_Deadlift',
  'Leg Press':               'Calf_Press_On_The_Leg_Press_Machine',
  'Leg Extension':           'Leg_Extensions',
  'Leg Curl':                'Lying_Leg_Curls',
  'Standing Calf Raise':     'Rocking_Standing_Calf_Raise',
  'Machine Shoulder Press':  'Arnold_Dumbbell_Press',
  'Lateral Raise':           'Dumbbell_Lateral_Raise',
  'Plank':                   'Plank',
};

function exerciseImageUrl(name: string): string | null {
  const id = EXERCISE_IMAGE_MAP[name];
  return id ? `${BASE_IMG}/${id}/0.jpg` : null;
}

// ── Types ─────────────────────────────────────────────────────────────────────

export interface PlanExercise {
  id: string;
  name: string;
  target_muscles: string[];
  sets: number;
  reps_label: string;
  equipment: string;
  sort_order: number;
  gif_url: string | null;
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
        gif_url: exerciseImageUrl(e.name),
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
      gif_url: exerciseImageUrl(e.name),
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

  // Check if set already exists (to gate XP award)
  const { data: existingSet } = await db
    .from('gym_set_logs')
    .select('id')
    .eq('session_id', sessionId)
    .eq('exercise_id', exerciseId)
    .eq('set_number', setNumber)
    .maybeSingle();

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

  if (!existingSet) {
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

// ── Analytics ─────────────────────────────────────────────────────────────────

export async function getGymStats(userId: string) {
  const db = getSupabase();

  const { data: sessions } = await db
    .from('gym_sessions')
    .select('id, session_date, xp_awarded')
    .eq('user_id', userId)
    .not('completed_at', 'is', null)
    .order('session_date', { ascending: false });

  if (!sessions || sessions.length === 0) {
    return { totalSessions: 0, totalVolumeKg: 0, totalXp: 0, streak: 0 };
  }

  const sessionIds = sessions.map((s: any) => s.id);
  const { data: sets } = await db
    .from('gym_set_logs')
    .select('weight_kg, reps')
    .in('session_id', sessionIds);

  const totalVolumeKg = Math.round(
    (sets ?? []).reduce((sum: number, s: any) => sum + (s.weight_kg ?? 0) * (s.reps ?? 0), 0)
  );
  const totalXp = sessions.reduce((sum: number, s: any) => sum + (s.xp_awarded ?? 0), 0);

  // Consecutive-day streak ending today or yesterday
  const today = isoDate(new Date());
  const sortedDates = [...new Set(sessions.map((s: any) => s.session_date as string))].sort().reverse();
  let streak = 0;
  let expected = today;
  for (const d of sortedDates) {
    if (d === expected) {
      streak++;
      const prev = new Date(expected + 'T12:00:00Z');
      prev.setDate(prev.getDate() - 1);
      expected = isoDate(prev);
    } else break;
  }

  return { totalSessions: sessions.length, totalVolumeKg, totalXp, streak };
}

export async function getSessionHistory(userId: string, weeks: number = 8) {
  const db = getSupabase();
  const from = new Date();
  from.setDate(from.getDate() - weeks * 7);
  const fromStr = isoDate(from);

  const { data } = await db
    .from('gym_sessions')
    .select('session_date, xp_awarded, completed_at, gym_workout_plans(name, slug)')
    .eq('user_id', userId)
    .gte('session_date', fromStr)
    .order('session_date', { ascending: true });

  return (data ?? []).map((s: any) => ({
    date: s.session_date,
    xp: s.xp_awarded ?? 0,
    completed: s.completed_at !== null,
    planName: s.gym_workout_plans?.name ?? '',
    planSlug: s.gym_workout_plans?.slug ?? '',
  }));
}

export async function getExerciseHistory(
  userId: string,
  exerciseId: string,
): Promise<ExerciseHistoryEntry[]> {
  const db = getSupabase();

  const { data } = await db
    .from('gym_set_logs')
    .select('set_number, weight_kg, reps, gym_sessions!inner(session_date, user_id)')
    .filter('gym_sessions.user_id', 'eq', userId)
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
