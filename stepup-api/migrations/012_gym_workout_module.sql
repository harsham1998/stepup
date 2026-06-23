-- migrations/012_gym_workout_module.sql

-- Workout day plans (seeded, system-defined)
CREATE TABLE IF NOT EXISTS gym_workout_plans (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  slug         text NOT NULL UNIQUE,
  name         text NOT NULL,
  day_of_week  int  NOT NULL CHECK (day_of_week BETWEEN 0 AND 6), -- 0=Sun,1=Mon,...
  muscle_groups text[] NOT NULL DEFAULT '{}',
  is_rest      boolean NOT NULL DEFAULT false,
  sort_order   int NOT NULL
);

-- Exercises within each plan (ordered)
CREATE TABLE IF NOT EXISTS gym_plan_exercises (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  plan_id        uuid NOT NULL REFERENCES gym_workout_plans(id) ON DELETE CASCADE,
  name           text NOT NULL,
  target_muscles text[] NOT NULL DEFAULT '{}',
  sets           int  NOT NULL DEFAULT 3,
  reps_label     text NOT NULL DEFAULT '12', -- e.g. "10", "12-15", "45s"
  equipment      text NOT NULL DEFAULT 'machine',
  sort_order     int  NOT NULL
);
CREATE INDEX IF NOT EXISTS idx_gym_plan_exercises_plan ON gym_plan_exercises(plan_id, sort_order);

-- One session per user per calendar date
CREATE TABLE IF NOT EXISTS gym_sessions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plan_id      uuid NOT NULL REFERENCES gym_workout_plans(id),
  session_date date NOT NULL DEFAULT CURRENT_DATE,
  started_at   timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz,
  xp_awarded   int NOT NULL DEFAULT 0,
  UNIQUE (user_id, session_date)
);
CREATE INDEX IF NOT EXISTS idx_gym_sessions_user ON gym_sessions(user_id, session_date DESC);

-- Individual set logs
CREATE TABLE IF NOT EXISTS gym_set_logs (
  id             uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id     uuid NOT NULL REFERENCES gym_sessions(id) ON DELETE CASCADE,
  exercise_id    uuid NOT NULL REFERENCES gym_plan_exercises(id),
  set_number     int  NOT NULL,
  weight_kg      numeric(6,2),
  reps           int,
  duration_secs  int,
  logged_at      timestamptz NOT NULL DEFAULT now(),
  xp_awarded     int NOT NULL DEFAULT 10,
  UNIQUE (session_id, exercise_id, set_number)
);
CREATE INDEX IF NOT EXISTS idx_gym_set_logs_session ON gym_set_logs(session_id);
CREATE INDEX IF NOT EXISTS idx_gym_set_logs_exercise ON gym_set_logs(exercise_id, logged_at DESC);

-- ======================================================
-- SEED: Weekly Plan (Push/Pull/Legs/Push/Pull/Cardio/Rest)
-- ======================================================
INSERT INTO gym_workout_plans (slug, name, day_of_week, muscle_groups, is_rest, sort_order) VALUES
  ('push_a',  'Push Day A',  1, ARRAY['chest','shoulders','triceps'], false, 1),
  ('pull_a',  'Pull Day A',  2, ARRAY['back','biceps'], false, 2),
  ('legs',    'Leg Day',     3, ARRAY['quads','hamstrings','glutes','calves','core'], false, 3),
  ('push_b',  'Push Day B',  4, ARRAY['chest','shoulders','triceps'], false, 4),
  ('pull_b',  'Pull Day B',  5, ARRAY['back','biceps'], false, 5),
  ('cardio',  'Cardio',      6, ARRAY['cardio'], false, 6),
  ('rest',    'Rest Day',    0, ARRAY[]::text[], true, 7)
ON CONFLICT (slug) DO NOTHING;

-- Push Day A exercises
INSERT INTO gym_plan_exercises (plan_id, name, target_muscles, sets, reps_label, equipment, sort_order)
SELECT p.id, e.name, e.muscles, e.sets, e.reps, e.equip, e.ord
FROM gym_workout_plans p, (VALUES
  ('Machine Chest Press',    ARRAY['chest','front-delt'],          4, '10',    'machine', 1),
  ('Incline Dumbbell Press', ARRAY['upper-chest','front-delt'],    3, '12',    'dumbbell',2),
  ('Pec Deck Fly',           ARRAY['chest'],                       3, '15',    'machine', 3),
  ('Machine Shoulder Press', ARRAY['shoulders','triceps'],         3, '12',    'machine', 4),
  ('Lateral Raise',          ARRAY['side-delt'],                   4, '15',    'dumbbell',5),
  ('Rope Pushdown',          ARRAY['triceps'],                     3, '15',    'cable',   6),
  ('Overhead Rope Extension',ARRAY['long-head-triceps'],           3, '12',    'cable',   7)
) AS e(name, muscles, sets, reps, equip, ord)
WHERE p.slug = 'push_a'
ON CONFLICT DO NOTHING;

-- Pull Day A exercises
INSERT INTO gym_plan_exercises (plan_id, name, target_muscles, sets, reps_label, equipment, sort_order)
SELECT p.id, e.name, e.muscles, e.sets, e.reps, e.equip, e.ord
FROM gym_workout_plans p, (VALUES
  ('Lat Pulldown',          ARRAY['lats','biceps'],              4, '10',    'cable',   1),
  ('Seated Cable Row',      ARRAY['mid-back','lats'],            3, '12',    'cable',   2),
  ('Chest Supported Row',   ARRAY['upper-back','rear-delt'],     3, '12',    'machine', 3),
  ('Face Pull',             ARRAY['rear-delt','traps'],          3, '15',    'cable',   4),
  ('Machine Curl',          ARRAY['biceps'],                     3, '12',    'machine', 5),
  ('Hammer Curl',           ARRAY['biceps','brachialis'],        3, '12',    'dumbbell',6)
) AS e(name, muscles, sets, reps, equip, ord)
WHERE p.slug = 'pull_a'
ON CONFLICT DO NOTHING;

-- Leg Day exercises
INSERT INTO gym_plan_exercises (plan_id, name, target_muscles, sets, reps_label, equipment, sort_order)
SELECT p.id, e.name, e.muscles, e.sets, e.reps, e.equip, e.ord
FROM gym_workout_plans p, (VALUES
  ('Leg Press',            ARRAY['quads','glutes'],              4, '12',    'machine', 1),
  ('Barbell Squat',        ARRAY['quads','glutes','core'],       4, '8',     'barbell', 2),
  ('Romanian Deadlift',    ARRAY['hamstrings','glutes'],         3, '10',    'barbell', 3),
  ('Leg Curl',             ARRAY['hamstrings'],                  3, '12',    'machine', 4),
  ('Leg Extension',        ARRAY['quads'],                      3, '15',    'machine', 5),
  ('Standing Calf Raise',  ARRAY['calves'],                     4, '15',    'machine', 6),
  ('Plank',                ARRAY['core','abs'],                  3, '45s',   'bodyweight',7)
) AS e(name, muscles, sets, reps, equip, ord)
WHERE p.slug = 'legs'
ON CONFLICT DO NOTHING;

-- Push Day B exercises
INSERT INTO gym_plan_exercises (plan_id, name, target_muscles, sets, reps_label, equipment, sort_order)
SELECT p.id, e.name, e.muscles, e.sets, e.reps, e.equip, e.ord
FROM gym_workout_plans p, (VALUES
  ('Machine Chest Press',     ARRAY['chest','front-delt'],       4, '10',    'machine', 1),
  ('Incline Dumbbell Press',  ARRAY['upper-chest','front-delt'], 3, '10',    'dumbbell',2),
  ('Pec Deck Fly',            ARRAY['chest'],                    3, '15',    'machine', 3),
  ('Machine Shoulder Press',  ARRAY['shoulders','triceps'],      3, '12',    'machine', 4),
  ('Lateral Raise',           ARRAY['side-delt'],                4, '15',    'dumbbell',5),
  ('Overhead Rope Extension', ARRAY['long-head-triceps'],        3, '12',    'cable',   6),
  ('Rope Pushdown',           ARRAY['triceps'],                  3, '15',    'cable',   7)
) AS e(name, muscles, sets, reps, equip, ord)
WHERE p.slug = 'push_b'
ON CONFLICT DO NOTHING;

-- Pull Day B exercises
INSERT INTO gym_plan_exercises (plan_id, name, target_muscles, sets, reps_label, equipment, sort_order)
SELECT p.id, e.name, e.muscles, e.sets, e.reps, e.equip, e.ord
FROM gym_workout_plans p, (VALUES
  ('Lat Pulldown',         ARRAY['lats','biceps'],              4, '10',    'cable',   1),
  ('Seated Cable Row',     ARRAY['mid-back','lats'],            3, '12',    'cable',   2),
  ('Chest Supported Row',  ARRAY['upper-back','rear-delt'],     3, '12',    'machine', 3),
  ('Face Pull',            ARRAY['rear-delt','traps'],          3, '15',    'cable',   4),
  ('Machine Curl',         ARRAY['biceps'],                     3, '12',    'machine', 5),
  ('Hammer Curl',          ARRAY['biceps','brachialis'],        3, '12',    'dumbbell',6)
) AS e(name, muscles, sets, reps, equip, ord)
WHERE p.slug = 'pull_b'
ON CONFLICT DO NOTHING;

-- Cardio day (no exercises — logged as a single completion)
-- (cardio has no gym_plan_exercises rows — tracked via session completed_at only)
