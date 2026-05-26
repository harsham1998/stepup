-- stepup-api/migrations/010_challenge_modes_missions.sql

-- 1. Dynamic challenge mode (individual players compete in all modes)
ALTER TABLE challenges
  ADD COLUMN IF NOT EXISTS mode text NOT NULL DEFAULT 'individual'
    CHECK (mode IN ('individual', 'duo', 'group', 'team'));

-- 2. Link missions to a challenge with bonus XP
CREATE TABLE IF NOT EXISTS challenge_missions (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  mission_id   uuid NOT NULL REFERENCES missions(id)   ON DELETE CASCADE,
  bonus_xp     int  NOT NULL DEFAULT 0,
  UNIQUE (challenge_id, mission_id)
);
CREATE INDEX IF NOT EXISTS idx_challenge_missions_cid ON challenge_missions(challenge_id);

-- 3. Accumulate XP earned per user within a challenge (from completing linked missions)
CREATE TABLE IF NOT EXISTS challenge_participant_xp (
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES users(id)      ON DELETE CASCADE,
  xp_earned    int  NOT NULL DEFAULT 0,
  PRIMARY KEY (challenge_id, user_id)
);

-- 4. Snapshot display info at join time so leaderboard names survive profile edits
ALTER TABLE challenge_participants
  ADD COLUMN IF NOT EXISTS display_name text,
  ADD COLUMN IF NOT EXISTS avatar_url   text;
