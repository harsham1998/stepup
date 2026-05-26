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
const d0 = new Date(NOW); d0.setHours(0, 0, 0, 0);
const d1 = (n) => { const d = new Date(d0); d.setDate(d.getDate() + n); return d; };
const iso = (d) => d.toISOString();

await run('Challenges — diverse set', () =>
  supabase.from('challenges').upsert([
    // ── DAILY (1-day duration) ─────────────────────────────────────────────
    { id: 'cccccccc-0000-4000-8000-000000000001', title: 'Daily Step Sprint',
      type: 'paid_pool',  step_goal: 10000, entry_fee: 500,  prize_pool: 5000,
      max_participants: 50, sponsor_name: 'steps',
      start_time: iso(d0), end_time: iso(d1(1)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000002', title: 'Morning 5K Rush',
      type: 'free_daily', step_goal: 5,     entry_fee: 0,    prize_pool: 3000,
      sponsor_name: 'running',
      start_time: iso(d0), end_time: iso(d1(1)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000011', title: 'Iron Hour',
      type: 'free_daily', step_goal: 1,     entry_fee: 0,    prize_pool: 2500,
      sponsor_name: 'gym',
      start_time: iso(d0), end_time: iso(d1(1)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000012', title: 'City Cycle Dash',
      type: 'free_daily', step_goal: 20,    entry_fee: 0,    prize_pool: 2000,
      sponsor_name: 'cycling',
      start_time: iso(d0), end_time: iso(d1(1)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000013', title: 'Sunrise Stroll',
      type: 'free_daily', step_goal: 8000,  entry_fee: 0,    prize_pool: 0,
      sponsor_name: 'walking',
      start_time: iso(d0), end_time: iso(d1(1)), status: 'active' },

    // ── WEEKLY (7-day duration) ────────────────────────────────────────────
    { id: 'cccccccc-0000-4000-8000-000000000004', title: 'Weekly Champion',
      type: 'free_weekly', step_goal: 50000, entry_fee: 0,   prize_pool: 12000,
      sponsor_name: 'steps',
      start_time: iso(d0), end_time: iso(d1(7)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000021', title: 'Century Ride',
      type: 'paid_pool',  step_goal: 100,   entry_fee: 500,  prize_pool: 20000,
      sponsor_name: 'cycling',
      start_time: iso(d0), end_time: iso(d1(7)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000022', title: '3×3 Grind',
      type: 'free_weekly', step_goal: 3,    entry_fee: 0,    prize_pool: 15000,
      sponsor_name: 'gym',
      start_time: iso(d0), end_time: iso(d1(7)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000023', title: 'Trail Blazer',
      type: 'paid_pool',  step_goal: 30,    entry_fee: 300,  prize_pool: 18000,
      sponsor_name: 'running',
      start_time: iso(d0), end_time: iso(d1(7)), status: 'active' },

    // ── MONTHLY (30-day duration) ──────────────────────────────────────────
    { id: 'cccccccc-0000-4000-8000-000000000031', title: 'Velo 500',
      type: 'paid_pool',  step_goal: 500,   entry_fee: 1000, prize_pool: 80000,
      sponsor_name: 'cycling',
      start_time: iso(d0), end_time: iso(d1(30)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000032', title: 'Gym Warrior',
      type: 'paid_pool',  step_goal: 20,    entry_fee: 500,  prize_pool: 65000,
      sponsor_name: 'gym',
      start_time: iso(d0), end_time: iso(d1(30)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000033', title: 'Step Master',
      type: 'team',       step_goal: 300000, entry_fee: 0,   prize_pool: 50000,
      sponsor_name: 'steps',
      start_time: iso(d0), end_time: iso(d1(30)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000034', title: 'Outdoor Champ',
      type: 'team',       step_goal: 8,     entry_fee: 0,    prize_pool: 45000,
      sponsor_name: 'outdoor',
      start_time: iso(d0), end_time: iso(d1(30)), status: 'active' },

    // ── SEASONAL (90-day duration) ─────────────────────────────────────────
    { id: 'cccccccc-0000-4000-8000-000000000041', title: 'Summer Sprint Cup',
      type: 'paid_pool',  step_goal: 200,   entry_fee: 5000, prize_pool: 500000,
      max_participants: 500, sponsor_name: 'running',
      start_time: iso(d0), end_time: iso(d1(90)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000042', title: 'Iron League S1',
      type: 'paid_pool',  step_goal: 80,    entry_fee: 3000, prize_pool: 300000,
      sponsor_name: 'gym',
      start_time: iso(d0), end_time: iso(d1(90)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000043', title: 'Monsoon Miles',
      type: 'city',       step_goal: 1000,  entry_fee: 10000, prize_pool: 800000,
      sponsor_name: 'cycling',
      start_time: iso(d0), end_time: iso(d1(90)), status: 'active' },
    { id: 'cccccccc-0000-4000-8000-000000000044', title: 'Grand Slam',
      type: 'city',       step_goal: 30,    entry_fee: 2000, prize_pool: 250000,
      sponsor_name: 'outdoor',
      start_time: iso(d0), end_time: iso(d1(90)), status: 'active' },
  ], { onConflict: 'id' })
);

// 6. Challenge participants — bulk seed across categories
const participantRows = [];
const CHALLENGE_IDS = [
  'cccccccc-0000-4000-8000-000000000001',
  'cccccccc-0000-4000-8000-000000000002',
  'cccccccc-0000-4000-8000-000000000011',
  'cccccccc-0000-4000-8000-000000000012',
  'cccccccc-0000-4000-8000-000000000013',
  'cccccccc-0000-4000-8000-000000000004',
  'cccccccc-0000-4000-8000-000000000021',
  'cccccccc-0000-4000-8000-000000000022',
  'cccccccc-0000-4000-8000-000000000023',
  'cccccccc-0000-4000-8000-000000000031',
  'cccccccc-0000-4000-8000-000000000032',
  'cccccccc-0000-4000-8000-000000000033',
  'cccccccc-0000-4000-8000-000000000034',
  'cccccccc-0000-4000-8000-000000000041',
  'cccccccc-0000-4000-8000-000000000042',
  'cccccccc-0000-4000-8000-000000000043',
  'cccccccc-0000-4000-8000-000000000044',
];
// User joined daily challenges 001 and 004 weekly
const USER_JOINED = ['cccccccc-0000-4000-8000-000000000001', 'cccccccc-0000-4000-8000-000000000004'];
for (const cid of USER_JOINED) {
  participantRows.push({ challenge_id: cid, user_id: USER_ID });
}
// Helpers spread across all challenges for realistic counts
const helperIds = [HELPER_1, HELPER_2, HELPER_3];
const helperJoins = {
  [HELPER_1]: ['000000000001','000000000002','000000000011','000000000021','000000000022','000000000031','000000000041'],
  [HELPER_2]: ['000000000001','000000000012','000000000004','000000000023','000000000032','000000000042'],
  [HELPER_3]: ['000000000002','000000000013','000000000021','000000000033','000000000034','000000000043','000000000044'],
};
for (const [uid, suffixes] of Object.entries(helperJoins)) {
  for (const s of suffixes) {
    participantRows.push({ challenge_id: `cccccccc-0000-4000-8000-${s}`, user_id: uid });
  }
}
await run('Challenge participants', () =>
  supabase.from('challenge_participants').upsert(participantRows, { onConflict: 'challenge_id,user_id' })
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
