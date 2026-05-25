-- Activities: logged gym/yoga/sport/run/cycle sessions
create table if not exists activities (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  activity_type text not null check (activity_type in ('gym','yoga','sport','run','cycle','walk','mindfulness')),
  duration_minutes int not null default 0,
  intensity text check (intensity in ('low','medium','high')),
  calories_burned int,
  notes text,
  logged_at timestamptz not null default now(),
  date date not null default current_date
);
create index if not exists activities_user_date on activities(user_id, date);
alter table activities enable row level security;
create policy "users own activities" on activities for all using (auth.uid() = user_id);

-- Notifications
create table if not exists notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  type text not null default 'info',
  title text not null,
  body text not null,
  read boolean not null default false,
  data jsonb,
  created_at timestamptz not null default now()
);
create index if not exists notifications_user_unread on notifications(user_id, read, created_at desc);
alter table notifications enable row level security;
create policy "users own notifications" on notifications for all using (auth.uid() = user_id);

-- Achievements definitions (seeded below)
create table if not exists achievements (
  id text primary key,
  title text not null,
  description text not null,
  category text not null,
  icon text not null,
  xp_reward int not null default 0,
  coin_reward int not null default 0,
  requirement_type text not null,
  requirement_value int not null
);

-- User achievements earned
create table if not exists user_achievements (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id text not null references achievements(id),
  earned_at timestamptz not null default now(),
  unique(user_id, achievement_id)
);
alter table user_achievements enable row level security;
create policy "users own user_achievements" on user_achievements for all using (auth.uid() = user_id);

-- User levels / XP
create table if not exists user_levels (
  user_id uuid primary key references auth.users(id) on delete cascade,
  xp int not null default 0,
  level int not null default 1,
  title text not null default 'Walker',
  updated_at timestamptz not null default now()
);
alter table user_levels enable row level security;
create policy "users own user_levels" on user_levels for all using (auth.uid() = user_id);

-- Seed achievements
insert into achievements(id,title,description,category,icon,xp_reward,coin_reward,requirement_type,requirement_value) values
  ('first_step',    'First Step',      'Log your first activity',         'steps',  'walk',    50,  0,   'total_activities', 1),
  ('step_100k',     '100K Walker',     'Walk 100,000 total steps',        'steps',  'walk',   200, 50,  'total_steps',      100000),
  ('streak_7',      'Week Warrior',    'Achieve a 7-day streak',          'streak', 'flame',  100, 25,  'max_streak',       7),
  ('streak_30',     'Month Master',    'Achieve a 30-day streak',         'streak', 'flame',  500, 150, 'max_streak',       30),
  ('gym_10',        'Gym Regular',     'Log 10 gym sessions',             'gym',    'gym',    150, 40,  'gym_sessions',     10),
  ('challenge_5',   'Challenger',      'Complete 5 challenges',           'chal',   'trophy', 300, 100, 'challenges_done',  5),
  ('challenge_25',  'Challenge King',  'Complete 25 challenges',          'chal',   'trophy', 750, 300, 'challenges_done',  25),
  ('top50',         'Top Performer',   'Finish top 50% in a challenge',   'chal',   'star',   200, 75,  'top50_finishes',   1),
  ('coins_1000',    'Coin Collector',  'Earn 1,000 coins total',          'coins',  'coin',   100, 0,   'total_coins',      1000)
on conflict(id) do nothing;
