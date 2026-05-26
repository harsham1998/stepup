-- Extended profile fields for edit screen
ALTER TABLE users
  ADD COLUMN IF NOT EXISTS bio                    text NOT NULL DEFAULT '',
  ADD COLUMN IF NOT EXISTS dob                    date,
  ADD COLUMN IF NOT EXISTS height_cm              int,
  ADD COLUMN IF NOT EXISTS weight_kg              numeric(5,1),
  ADD COLUMN IF NOT EXISTS sex                    text
                                                  CHECK (sex IN ('male','female','other','prefer_not_to_say')),
  ADD COLUMN IF NOT EXISTS units                  text NOT NULL DEFAULT 'metric'
                                                  CHECK (units IN ('metric','imperial')),
  ADD COLUMN IF NOT EXISTS fitness_level          text
                                                  CHECK (fitness_level IN ('beginner','intermediate','advanced')),
  ADD COLUMN IF NOT EXISTS primary_goal           text
                                                  CHECK (primary_goal IN ('lose_weight','build_muscle','stay_active','endurance')),
  ADD COLUMN IF NOT EXISTS step_goal              int NOT NULL DEFAULT 10000,
  ADD COLUMN IF NOT EXISTS preferred_workout_time text
                                                  CHECK (preferred_workout_time IN ('morning','afternoon','evening','night')),
  ADD COLUMN IF NOT EXISTS workout_days_per_week  int
                                                  CHECK (workout_days_per_week BETWEEN 1 AND 7),
  ADD COLUMN IF NOT EXISTS activity_types         text[] NOT NULL DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS push_notifications     boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS show_on_leaderboard    boolean NOT NULL DEFAULT true,
  ADD COLUMN IF NOT EXISTS profile_visibility     text NOT NULL DEFAULT 'public'
                                                  CHECK (profile_visibility IN ('public','friends','private')),
  ADD COLUMN IF NOT EXISTS onboarding_completed   boolean NOT NULL DEFAULT false;

-- Backfill: existing rows with a name already set have completed onboarding
UPDATE users SET onboarding_completed = true WHERE name != '' AND name IS NOT NULL;
