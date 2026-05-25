import { createClient } from '@supabase/supabase-js';

const SUPABASE_URL = 'https://ypadjymopdbypuneqmnb.supabase.co';
const SERVICE_KEY = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlwYWRqeW1vcGRieXB1bmVxbW5iIiwicm9sZSI6InNlcnZpY2Vfcm9sZSIsImlhdCI6MTc3OTU1MjUxOCwiZXhwIjoyMDk1MTI4NTE4fQ.Z29irA0aYgzOkWFNedB6FKBw_l5hzwlp4LUH32OfKzI';

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false }
});

const USER_ID = 'b88d7963-91ea-4cf8-97e0-51f40c2a68e4';
const NOW = new Date();
const TODAY = NOW.toISOString().split('T')[0];

async function run(label, fn) {
  const { data, error } = await fn();
  if (error) {
    console.error(`❌ ${label}:`, error.message);
  } else {
    console.log(`✅ ${label}`);
  }
  return { data, error };
}

// 1. User profile
await run('User profile', () =>
  supabase.from('users').upsert({
    id: USER_ID,
    phone: '918555849483',
    name: 'Harsha',
    city: 'Hyderabad',
    language: 'english',
    goal_tier: 'active',
    xp: 1240,
    streak_days: 7,
    league: 'silver',
    kyc_verified: false,
  }, { onConflict: 'id' })
);

// 2. Step logs (last 7 days)
const stepLogs = [];
for (let i = 6; i >= 0; i--) {
  const d = new Date(NOW);
  d.setDate(d.getDate() - i);
  const steps = [4200, 7800, 5500, 9100, 6200, 8300, 6800][6 - i];
  stepLogs.push({
    user_id: USER_ID,
    steps,
    synced_at: d.toISOString(),
    source: 'healthkit',
    device_model: 'iPhone17',
    os_version: '18.0',
  });
}
await run('Step logs', () => supabase.from('step_logs').upsert(stepLogs));

// 3. Daily steps aggregates
const dailySteps = [];
for (let i = 6; i >= 0; i--) {
  const d = new Date(NOW);
  d.setDate(d.getDate() - i);
  const dateStr = d.toISOString().split('T')[0];
  const steps = [4200, 7800, 5500, 9100, 6200, 8300, 6800][6 - i];
  dailySteps.push({ user_id: USER_ID, date: dateStr, total_steps: steps });
}
await run('Daily steps', () => supabase.from('user_daily_steps').upsert(dailySteps, { onConflict: 'user_id,date' }));

// 4. Helper users (for leaderboard/challenges)
const HELPER_1 = 'aaaaaaaa-0000-4000-8000-000000000001';
const HELPER_2 = 'aaaaaaaa-0000-4000-8000-000000000002';
const HELPER_3 = 'aaaaaaaa-0000-4000-8000-000000000003';

// Create helper auth users first via admin API
async function ensureAuthUser(userId, email) {
  const { error } = await supabase.auth.admin.createUser({
    id: userId,
    email,
    email_confirm: true,
    password: 'Dummy_seed_pass_1!',
  });
  if (error && !error.message.includes('already been registered')) {
    console.warn(`  ⚠️ Auth user ${email}:`, error.message);
  }
}

await ensureAuthUser(HELPER_1, 'seed1@auth.stepup.app');
await ensureAuthUser(HELPER_2, 'seed2@auth.stepup.app');
await ensureAuthUser(HELPER_3, 'seed3@auth.stepup.app');

await run('Helper users', () =>
  supabase.from('users').upsert([
    { id: HELPER_1, name: 'Rahul', city: 'Hyderabad', xp: 2100, streak_days: 14, league: 'gold' },
    { id: HELPER_2, name: 'Priya', city: 'Hyderabad', xp: 980, streak_days: 3, league: 'silver' },
    { id: HELPER_3, name: 'Arjun', city: 'Mumbai', xp: 1500, streak_days: 10, league: 'silver' },
  ], { onConflict: 'id' })
);

// 5. Challenges
const challengeStart = new Date(NOW);
challengeStart.setHours(0, 0, 0, 0);
const challengeEnd = new Date(challengeStart);
challengeEnd.setDate(challengeEnd.getDate() + 1);

const upcomingStart = new Date(NOW);
upcomingStart.setDate(upcomingStart.getDate() + 1);
upcomingStart.setHours(0, 0, 0, 0);
const upcomingEnd = new Date(upcomingStart);
upcomingEnd.setDate(upcomingEnd.getDate() + 1);

const weekEnd = new Date(challengeStart);
weekEnd.setDate(weekEnd.getDate() + 7);

const { data: challenges } = await run('Challenges', () =>
  supabase.from('challenges').upsert([
    {
      id: 'cccccccc-0000-4000-8000-000000000001',
      title: 'Daily Step Sprint',
      type: 'paid_pool',
      step_goal: 10000,
      entry_fee: 50,
      prize_pool: 500,
      max_participants: 50,
      start_time: challengeStart.toISOString(),
      end_time: challengeEnd.toISOString(),
      status: 'active',
    },
    {
      id: 'cccccccc-0000-4000-8000-000000000002',
      title: 'Free Daily Walk',
      type: 'free_daily',
      step_goal: 8000,
      entry_fee: 0,
      prize_pool: 0,
      start_time: challengeStart.toISOString(),
      end_time: challengeEnd.toISOString(),
      status: 'active',
    },
    {
      id: 'cccccccc-0000-4000-8000-000000000003',
      title: 'Weekend Warrior',
      type: 'paid_pool',
      step_goal: 70000,
      entry_fee: 100,
      prize_pool: 1200,
      max_participants: 100,
      start_time: upcomingStart.toISOString(),
      end_time: upcomingEnd.toISOString(),
      status: 'upcoming',
    },
    {
      id: 'cccccccc-0000-4000-8000-000000000004',
      title: 'Weekly Champion',
      type: 'free_weekly',
      step_goal: 50000,
      entry_fee: 0,
      prize_pool: 0,
      start_time: challengeStart.toISOString(),
      end_time: weekEnd.toISOString(),
      status: 'active',
    },
  ], { onConflict: 'id' })
);

// 6. Challenge participants
await run('Challenge participants', () =>
  supabase.from('challenge_participants').upsert([
    { challenge_id: 'cccccccc-0000-4000-8000-000000000001', user_id: USER_ID },
    { challenge_id: 'cccccccc-0000-4000-8000-000000000001', user_id: HELPER_1 },
    { challenge_id: 'cccccccc-0000-4000-8000-000000000001', user_id: HELPER_2 },
    { challenge_id: 'cccccccc-0000-4000-8000-000000000001', user_id: HELPER_3 },
    { challenge_id: 'cccccccc-0000-4000-8000-000000000002', user_id: USER_ID },
    { challenge_id: 'cccccccc-0000-4000-8000-000000000002', user_id: HELPER_1 },
    { challenge_id: 'cccccccc-0000-4000-8000-000000000004', user_id: USER_ID },
    { challenge_id: 'cccccccc-0000-4000-8000-000000000004', user_id: HELPER_2 },
  ], { onConflict: 'challenge_id,user_id' })
);

// 7. Wallet transactions
await run('Wallet transactions', () =>
  supabase.from('wallet_transactions').upsert([
    {
      id: 'wwwwwwww-0000-4000-8000-000000000001',
      user_id: USER_ID,
      type: 'credit',
      amount: 200,
      idempotency_key: 'seed-deposit-001',
      description: 'Welcome bonus',
      status: 'completed',
    },
    {
      id: 'wwwwwwww-0000-4000-8000-000000000002',
      user_id: USER_ID,
      type: 'debit',
      amount: 50,
      idempotency_key: 'seed-entry-001',
      reference_id: 'cccccccc-0000-4000-8000-000000000001',
      description: 'Entry fee: Daily Step Sprint',
      status: 'completed',
    },
    {
      id: 'wwwwwwww-0000-4000-8000-000000000003',
      user_id: USER_ID,
      type: 'credit',
      amount: 150,
      idempotency_key: 'seed-prize-001',
      description: 'Prize: 2nd place in Sprint challenge',
      status: 'completed',
    },
    {
      id: 'wwwwwwww-0000-4000-8000-000000000004',
      user_id: USER_ID,
      type: 'credit',
      amount: 500,
      idempotency_key: 'seed-deposit-002',
      description: 'Wallet top-up',
      status: 'completed',
    },
  ], { onConflict: 'id' })
);

// 8. Leaderboard snapshots
await run('Leaderboard snapshots', () =>
  supabase.from('leaderboard_snapshots').upsert([
    {
      id: 'llllllll-0000-4000-8000-000000000001',
      user_id: USER_ID,
      scope: 'global',
      scope_id: 'global',
      rank: 12,
      steps: 6800,
    },
    {
      id: 'llllllll-0000-4000-8000-000000000002',
      user_id: USER_ID,
      scope: 'city',
      scope_id: 'Hyderabad',
      rank: 3,
      steps: 6800,
    },
    {
      id: 'llllllll-0000-4000-8000-000000000003',
      user_id: HELPER_1,
      scope: 'global',
      scope_id: 'global',
      rank: 1,
      steps: 12400,
    },
    {
      id: 'llllllll-0000-4000-8000-000000000004',
      user_id: HELPER_2,
      scope: 'global',
      scope_id: 'global',
      rank: 8,
      steps: 7900,
    },
    {
      id: 'llllllll-0000-4000-8000-000000000005',
      user_id: HELPER_3,
      scope: 'global',
      scope_id: 'global',
      rank: 5,
      steps: 9200,
    },
  ], { onConflict: 'id' })
);

// 9. Badges
await run('Badges', () =>
  supabase.from('user_badges').upsert([
    { user_id: USER_ID, badge_slug: 'first_steps', earned_at: new Date(NOW.getTime() - 7 * 86400000).toISOString() },
    { user_id: USER_ID, badge_slug: 'streak_7', earned_at: NOW.toISOString() },
  ], { onConflict: 'user_id,badge_slug' })
);

console.log('\nSeed complete!');
