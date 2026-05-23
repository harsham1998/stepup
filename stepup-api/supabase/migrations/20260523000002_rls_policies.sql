-- Enable RLS on all tables
ALTER TABLE users                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE step_logs              ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_daily_steps       ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges             ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions    ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard_snapshots  ENABLE ROW LEVEL SECURITY;
ALTER TABLE step_flags             ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships            ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges            ENABLE ROW LEVEL SECURITY;

-- Users: own row only
CREATE POLICY "users_own" ON users
  FOR ALL USING (auth.uid() = id);

-- Step logs: own rows only
CREATE POLICY "step_logs_own" ON step_logs
  FOR ALL USING (auth.uid() = user_id);

CREATE POLICY "user_daily_steps_own" ON user_daily_steps
  FOR ALL USING (auth.uid() = user_id);

-- Challenges: public read, service role write
CREATE POLICY "challenges_public_read" ON challenges
  FOR SELECT USING (true);

-- Challenge participants: own write + public read within a challenge
CREATE POLICY "cp_own_write" ON challenge_participants
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "cp_challenge_read" ON challenge_participants
  FOR SELECT USING (true);

-- Wallet: own rows only
CREATE POLICY "wallet_own" ON wallet_transactions
  FOR ALL USING (auth.uid() = user_id);

-- Leaderboard snapshots: public read
CREATE POLICY "lb_public_read" ON leaderboard_snapshots
  FOR SELECT USING (true);

-- Step flags: service role only (no user-facing policy needed)

-- Friendships: own rows
CREATE POLICY "friendships_own" ON friendships
  FOR ALL USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Badges: own read
CREATE POLICY "badges_own" ON user_badges
  FOR SELECT USING (auth.uid() = user_id);
