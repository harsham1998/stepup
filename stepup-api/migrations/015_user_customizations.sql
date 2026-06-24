-- 015_user_customizations.sql
-- Run this in Supabase SQL editor: https://supabase.com/dashboard/project/ypadjymopdbypuneqmnb/editor

-- 1. Add user_id to gym_plan_exercises so users can have their own exercise lists
ALTER TABLE gym_plan_exercises ADD COLUMN IF NOT EXISTS user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
CREATE INDEX IF NOT EXISTS idx_gym_plan_exercises_user_id ON gym_plan_exercises(user_id);

-- 2. User workout schedule (day_of_week → plan_id mapping per user)
CREATE TABLE IF NOT EXISTS user_workout_schedules (
  user_id  UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  day_of_week INT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  plan_id  UUID NOT NULL REFERENCES gym_workout_plans(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, day_of_week)
);

-- 3. RLS for user_workout_schedules
ALTER TABLE user_workout_schedules ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can manage their own schedule"
  ON user_workout_schedules
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 4. RLS for user-specific gym_plan_exercises
-- Global exercises (user_id IS NULL) are readable by all
-- User exercises are readable/writable only by that user
-- The service role bypasses RLS so the API can read/write freely
ALTER TABLE gym_plan_exercises ENABLE ROW LEVEL SECURITY;

-- Allow reading global exercises (user_id IS NULL)
CREATE POLICY "Anyone can read global exercises"
  ON gym_plan_exercises
  FOR SELECT
  USING (user_id IS NULL);

-- Allow users to read/write their own exercises
CREATE POLICY "Users can manage their own exercises"
  ON gym_plan_exercises
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);
