import { createClient } from '@supabase/supabase-js';
import { readFileSync } from 'fs';
import { resolve } from 'path';

// Load .env manually (no dotenv dependency needed)
try {
  const env = readFileSync(resolve('.env'), 'utf8');
  for (const line of env.split('\n')) {
    const m = line.match(/^([^#=]+)=(.*)$/);
    if (m) process.env[m[1].trim()] = m[2].trim();
  }
} catch {}

const SUPABASE_URL = process.env.SUPABASE_URL;
const SERVICE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY;
if (!SUPABASE_URL || !SERVICE_KEY) {
  console.error('Missing SUPABASE_URL or SUPABASE_SERVICE_ROLE_KEY in .env');
  process.exit(1);
}

const supabase = createClient(SUPABASE_URL, SERVICE_KEY, {
  auth: { persistSession: false }
});

// Existing users (from seed.mjs)
const USER_ID  = 'b88d7963-91ea-4cf8-97e0-51f40c2a68e4'; // Harsha
const HELPER_1 = 'aaaaaaaa-0000-4000-8000-000000000001'; // Rahul
const HELPER_2 = 'aaaaaaaa-0000-4000-8000-000000000002'; // Priya
const HELPER_3 = 'aaaaaaaa-0000-4000-8000-000000000003'; // Arjun

// 26 new mock users (IDs 04–29)
// Distributed so Harsha (6800 steps) lands at rank 12 of 30
// Cutoff = ceil(30 * 0.5) = 15
const MOCK_USERS = [
  { id: 'bbbbbbbb-0000-4000-8000-000000000004', email: 'mock04@seed.stepup.app', name: 'Aditya Kumar',    city: 'Delhi',       steps: 11800 }, // rank 2
  { id: 'bbbbbbbb-0000-4000-8000-000000000005', email: 'mock05@seed.stepup.app', name: 'Meera Sharma',    city: 'Bangalore',   steps: 11200 }, // rank 3
  { id: 'bbbbbbbb-0000-4000-8000-000000000006', email: 'mock06@seed.stepup.app', name: 'Vikram Patel',    city: 'Mumbai',      steps: 10500 }, // rank 4
  { id: 'bbbbbbbb-0000-4000-8000-000000000007', email: 'mock07@seed.stepup.app', name: 'Sneha Nair',      city: 'Chennai',     steps: 9000  }, // rank 6
  { id: 'bbbbbbbb-0000-4000-8000-000000000008', email: 'mock08@seed.stepup.app', name: 'Rohit Singh',     city: 'Hyderabad',   steps: 8700  }, // rank 7
  { id: 'bbbbbbbb-0000-4000-8000-000000000009', email: 'mock09@seed.stepup.app', name: 'Ananya Reddy',    city: 'Pune',        steps: 8200  }, // rank 9
  { id: 'bbbbbbbb-0000-4000-8000-000000000010', email: 'mock10@seed.stepup.app', name: 'Kiran Iyer',      city: 'Bangalore',   steps: 8000  }, // rank 10
  { id: 'bbbbbbbb-0000-4000-8000-000000000011', email: 'mock11@seed.stepup.app', name: 'Deepak Verma',    city: 'Delhi',       steps: 7950  }, // rank 11
  { id: 'bbbbbbbb-0000-4000-8000-000000000012', email: 'mock12@seed.stepup.app', name: 'Kavya Menon',     city: 'Hyderabad',   steps: 6600  }, // rank 13
  { id: 'bbbbbbbb-0000-4000-8000-000000000013', email: 'mock13@seed.stepup.app', name: 'Siddharth Joshi', city: 'Mumbai',      steps: 6400  }, // rank 14
  { id: 'bbbbbbbb-0000-4000-8000-000000000014', email: 'mock14@seed.stepup.app', name: 'Pooja Desai',     city: 'Surat',       steps: 6200  }, // rank 15 (cutoff)
  { id: 'bbbbbbbb-0000-4000-8000-000000000015', email: 'mock15@seed.stepup.app', name: 'Akash Gupta',     city: 'Jaipur',      steps: 5800  }, // rank 16
  { id: 'bbbbbbbb-0000-4000-8000-000000000016', email: 'mock16@seed.stepup.app', name: 'Divya Krishnan',  city: 'Kochi',       steps: 5500  }, // rank 17
  { id: 'bbbbbbbb-0000-4000-8000-000000000017', email: 'mock17@seed.stepup.app', name: 'Rajesh Nair',     city: 'Trivandrum',  steps: 5200  }, // rank 18
  { id: 'bbbbbbbb-0000-4000-8000-000000000018', email: 'mock18@seed.stepup.app', name: 'Shruti Pillai',   city: 'Coimbatore',  steps: 4900  }, // rank 19
  { id: 'bbbbbbbb-0000-4000-8000-000000000019', email: 'mock19@seed.stepup.app', name: 'Mihir Shah',      city: 'Ahmedabad',   steps: 4600  }, // rank 20
  { id: 'bbbbbbbb-0000-4000-8000-000000000020', email: 'mock20@seed.stepup.app', name: 'Riya Pandey',     city: 'Lucknow',     steps: 4300  }, // rank 21
  { id: 'bbbbbbbb-0000-4000-8000-000000000021', email: 'mock21@seed.stepup.app', name: 'Gaurav Tiwari',   city: 'Bhopal',      steps: 4000  }, // rank 22
  { id: 'bbbbbbbb-0000-4000-8000-000000000022', email: 'mock22@seed.stepup.app', name: 'Preethi Suresh',  city: 'Mysore',      steps: 3700  }, // rank 23
  { id: 'bbbbbbbb-0000-4000-8000-000000000023', email: 'mock23@seed.stepup.app', name: 'Nikhil Deshmukh', city: 'Nagpur',      steps: 3400  }, // rank 24
  { id: 'bbbbbbbb-0000-4000-8000-000000000024', email: 'mock24@seed.stepup.app', name: 'Sonali Kulkarni', city: 'Pune',        steps: 3100  }, // rank 25
  { id: 'bbbbbbbb-0000-4000-8000-000000000025', email: 'mock25@seed.stepup.app', name: 'Aman Gupta',      city: 'Chandigarh',  steps: 2800  }, // rank 26
  { id: 'bbbbbbbb-0000-4000-8000-000000000026', email: 'mock26@seed.stepup.app', name: 'Isha Jain',       city: 'Indore',      steps: 2500  }, // rank 27
  { id: 'bbbbbbbb-0000-4000-8000-000000000027', email: 'mock27@seed.stepup.app', name: 'Yash Malhotra',   city: 'Noida',       steps: 2200  }, // rank 28
  { id: 'bbbbbbbb-0000-4000-8000-000000000028', email: 'mock28@seed.stepup.app', name: 'Fatima Khan',     city: 'Lucknow',     steps: 1900  }, // rank 29
  { id: 'bbbbbbbb-0000-4000-8000-000000000029', email: 'mock29@seed.stepup.app', name: 'Binoy Thomas',    city: 'Kochi',       steps: 1500  }, // rank 30
];

// Full ranked list (all 30): sorted by steps desc
const ALL_ENTRIES = [
  { userId: HELPER_1, name: 'Rahul',  city: 'Hyderabad', steps: 12400 },
  ...MOCK_USERS.map(u => ({ userId: u.id, name: u.name, city: u.city, steps: u.steps })),
  { userId: USER_ID,  name: 'Harsha', city: 'Hyderabad', steps: 6800 },
  { userId: HELPER_2, name: 'Priya',  city: 'Hyderabad', steps: 7900 },
  { userId: HELPER_3, name: 'Arjun',  city: 'Mumbai',    steps: 9200 },
].sort((a, b) => b.steps - a.steps);

async function run(label, fn) {
  try {
    const { data, error } = await fn();
    if (error) {
      console.error(`❌ ${label}:`, error.message);
    } else {
      console.log(`✅ ${label}`);
    }
    return { data, error };
  } catch (e) {
    console.error(`❌ ${label}:`, e.message);
    return { data: null, error: e };
  }
}

async function ensureAuthUser(userId, email) {
  const { error } = await supabase.auth.admin.createUser({
    id: userId,
    email,
    email_confirm: true,
    password: 'Dummy_seed_pass_1!',
  });
  if (error && !error.message.includes('already been registered') && !error.message.includes('already exists')) {
    console.warn(`  ⚠️ Auth ${email}:`, error.message);
  }
}

// 1. Create auth users for all 26 mock users
console.log('\n── Creating auth users ──');
for (const u of MOCK_USERS) {
  await ensureAuthUser(u.id, u.email);
}
console.log('✅ Auth users done');

// 2. Upsert user profiles for all 26 mock users
console.log('\n── Upserting user profiles ──');
await run('Mock user profiles', () =>
  supabase.from('users').upsert(
    MOCK_USERS.map(u => ({
      id: u.id,
      name: u.name,
      city: u.city,
      xp: Math.round(u.steps * 0.18), // rough XP from steps
      streak_days: Math.floor(Math.random() * 14),
      league: u.steps > 9000 ? 'gold' : u.steps > 6000 ? 'silver' : 'bronze',
    })),
    { onConflict: 'id' }
  )
);

// 3. Insert leaderboard_snapshots for all 30 users
console.log('\n── Seeding leaderboard snapshots ──');
const snapshotRows = ALL_ENTRIES.map((e, idx) => ({
  user_id: e.userId,
  scope: 'global',
  scope_id: 'global',
  rank: idx + 1,
  steps: e.steps,
}));

// Delete old global snapshots for these users first (clean slate)
await supabase
  .from('leaderboard_snapshots')
  .delete()
  .eq('scope', 'global')
  .in('user_id', ALL_ENTRIES.map(e => e.userId));

await run(`Leaderboard snapshots (${snapshotRows.length} users)`, () =>
  supabase.from('leaderboard_snapshots').insert(snapshotRows)
);

// Print final ranking for verification
console.log('\n── Final leaderboard (top 15) ──');
ALL_ENTRIES.slice(0, 15).forEach((e, i) => {
  const marker = e.userId === USER_ID ? ' ← YOU' : '';
  console.log(`  #${String(i + 1).padStart(2)} ${e.steps.toLocaleString().padStart(6)} steps  ${e.name} (${e.city})${marker}`);
});
console.log(`  ... ${ALL_ENTRIES.length - 15} more entries`);
console.log('\nSeed complete!');
