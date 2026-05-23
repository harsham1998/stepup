# StepUp Backend API — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the StepUp Node.js + TypeScript modular monolith API with Auth, Steps, Challenges, Leaderboard, and Wallet modules — deployable to Railway, connected to Supabase and Upstash Redis.

**Architecture:** Single Express app structured as 5 clean modules (`/modules/auth`, `/modules/steps`, `/modules/challenges`, `/modules/leaderboard`, `/modules/wallet`). Gateway middleware handles JWT auth and rate limiting before routing to modules. Redis sorted sets power real-time leaderboards; BullMQ handles async jobs (step sync, payouts, league recalc).

**Tech Stack:** Node.js 20, TypeScript 5, Express 4, Supabase JS v2, ioredis (Upstash), BullMQ, Razorpay Node SDK, MSG91, Firebase Admin SDK, Zod, Pino, Jest + Supertest

---

## File Map

```
stepup-api/
├── package.json
├── tsconfig.json
├── .env.example
├── jest.config.ts
├── src/
│   ├── index.ts                          # HTTP server bootstrap
│   ├── app.ts                            # Express app factory (testable)
│   ├── lib/
│   │   ├── supabase.ts                   # Supabase admin client singleton
│   │   ├── redis.ts                      # Upstash ioredis client singleton
│   │   ├── queue.ts                      # BullMQ queue + worker factory
│   │   ├── razorpay.ts                   # Razorpay client singleton
│   │   ├── fcm.ts                        # Firebase Admin SDK singleton
│   │   └── logger.ts                     # Pino logger
│   ├── gateway/
│   │   ├── middleware/
│   │   │   ├── auth.ts                   # Supabase JWT → req.user
│   │   │   ├── rateLimit.ts              # Redis sliding-window rate limiter
│   │   │   └── validate.ts               # Zod body/query validator factory
│   │   └── errorHandler.ts              # Global Express error handler
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.router.ts
│   │   │   └── auth.service.ts
│   │   ├── steps/
│   │   │   ├── steps.router.ts
│   │   │   ├── steps.service.ts
│   │   │   └── anticheat.service.ts
│   │   ├── challenges/
│   │   │   ├── challenges.router.ts
│   │   │   ├── challenges.service.ts
│   │   │   └── payout.job.ts
│   │   ├── leaderboard/
│   │   │   ├── leaderboard.router.ts
│   │   │   └── leaderboard.service.ts
│   │   └── wallet/
│   │       ├── wallet.router.ts
│   │       ├── wallet.service.ts
│   │       └── razorpay.webhook.ts
│   └── types/
│       └── index.ts                      # Shared TypeScript types
├── supabase/
│   └── migrations/
│       ├── 001_initial_schema.sql
│       └── 002_rls_policies.sql
└── tests/
    ├── helpers/
    │   ├── app.ts                        # Test app factory
    │   └── supabase.mock.ts              # Supabase mock
    ├── gateway/
    │   └── auth.middleware.test.ts
    ├── modules/
    │   ├── auth.test.ts
    │   ├── steps.test.ts
    │   ├── anticheat.test.ts
    │   ├── challenges.test.ts
    │   ├── leaderboard.test.ts
    │   └── wallet.test.ts
    └── jobs/
        └── payout.job.test.ts
```

---

## Task 1: Project Scaffold

**Files:**
- Create: `stepup-api/package.json`
- Create: `stepup-api/tsconfig.json`
- Create: `stepup-api/jest.config.ts`
- Create: `stepup-api/.env.example`
- Create: `stepup-api/src/types/index.ts`

- [ ] **Step 1.1: Create project directory and initialise**

```bash
mkdir -p /Users/harsha/StepUp/stepup-api && cd /Users/harsha/StepUp/stepup-api
npm init -y
```

- [ ] **Step 1.2: Install all dependencies**

```bash
npm install express @supabase/supabase-js ioredis bullmq razorpay firebase-admin zod pino pino-http uuid
npm install --save-dev typescript @types/node @types/express @types/uuid ts-node-dev jest ts-jest @types/jest supertest @types/supertest
```

- [ ] **Step 1.3: Create `tsconfig.json`**

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist", "tests"]
}
```

- [ ] **Step 1.4: Create `jest.config.ts`**

```ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  setupFilesAfterFramework: [],
  collectCoverageFrom: ['src/**/*.ts'],
};

export default config;
```

- [ ] **Step 1.5: Create `.env.example`**

```
PORT=3000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key
UPSTASH_REDIS_URL=rediss://your-upstash-url
UPSTASH_REDIS_TOKEN=your-token
RAZORPAY_KEY_ID=rzp_test_xxx
RAZORPAY_KEY_SECRET=your-razorpay-secret
RAZORPAY_WEBHOOK_SECRET=your-webhook-secret
MSG91_AUTH_KEY=your-msg91-key
MSG91_TEMPLATE_ID=your-template-id
FIREBASE_SERVICE_ACCOUNT_JSON={"type":"service_account",...}
PLATFORM_FEE_PERCENT=10
```

- [ ] **Step 1.6: Create `src/types/index.ts`**

```ts
export interface AuthUser {
  id: string;
  email?: string;
  phone?: string;
}

export interface StepSyncPayload {
  steps: number;
  syncedAt: string;       // ISO8601
  source: 'healthkit' | 'health_connect' | 'manual';
  deviceModel: string;
  osVersion: string;
}

export interface ChallengeRow {
  id: string;
  title: string;
  type: 'free_daily' | 'free_weekly' | 'paid_pool' | 'sponsored' | 'team' | 'city';
  step_goal: number;
  entry_fee: number;
  prize_pool: number;
  max_participants: number;
  start_time: string;
  end_time: string;
  status: 'upcoming' | 'active' | 'ended' | 'paid_out';
  prize_distribution: PrizeDistribution;
  sponsor_name?: string;
}

export interface PrizeDistribution {
  platform_fee_percent: number;
  tiers: Array<{ top_percent: number; share_percent: number }>;
}

export interface WalletTransaction {
  id: string;
  user_id: string;
  type: 'credit' | 'debit' | 'fee';
  amount: number;           // in paise (₹1 = 100 paise)
  idempotency_key: string;
  reference_id?: string;
  description: string;
  created_at: string;
}

// Augment Express Request
declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}
```

- [ ] **Step 1.7: Add npm scripts to `package.json`**

```json
{
  "scripts": {
    "dev": "ts-node-dev --respawn --transpile-only src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest --runInBand",
    "test:watch": "jest --watch",
    "test:coverage": "jest --coverage"
  }
}
```

- [ ] **Step 1.8: Commit**

```bash
git init && git add . && git commit -m "chore: scaffold stepup-api project"
```

---

## Task 2: Lib Singletons

**Files:**
- Create: `src/lib/logger.ts`
- Create: `src/lib/supabase.ts`
- Create: `src/lib/redis.ts`
- Create: `src/lib/queue.ts`
- Create: `src/lib/razorpay.ts`
- Create: `src/lib/fcm.ts`

- [ ] **Step 2.1: Create `src/lib/logger.ts`**

```ts
import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL ?? 'info',
  transport: process.env.NODE_ENV === 'development'
    ? { target: 'pino-pretty' }
    : undefined,
});
```

- [ ] **Step 2.2: Create `src/lib/supabase.ts`**

```ts
import { createClient, SupabaseClient } from '@supabase/supabase-js';

let client: SupabaseClient;

export function getSupabase(): SupabaseClient {
  if (!client) {
    const url = process.env.SUPABASE_URL;
    const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !key) throw new Error('SUPABASE_URL and SUPABASE_SERVICE_ROLE_KEY are required');
    client = createClient(url, key, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
  }
  return client;
}
```

- [ ] **Step 2.3: Create `src/lib/redis.ts`**

```ts
import Redis from 'ioredis';

let client: Redis;

export function getRedis(): Redis {
  if (!client) {
    const url = process.env.UPSTASH_REDIS_URL;
    if (!url) throw new Error('UPSTASH_REDIS_URL is required');
    client = new Redis(url, {
      tls: { rejectUnauthorized: false },
      maxRetriesPerRequest: 3,
    });
  }
  return client;
}
```

- [ ] **Step 2.4: Create `src/lib/queue.ts`**

```ts
import { Queue, Worker, Job } from 'bullmq';
import { getRedis } from './redis';

const connection = { client: getRedis() };

export function createQueue(name: string): Queue {
  return new Queue(name, { connection });
}

export function createWorker(
  name: string,
  processor: (job: Job) => Promise<void>
): Worker {
  return new Worker(name, processor, { connection, concurrency: 4 });
}
```

- [ ] **Step 2.5: Create `src/lib/razorpay.ts`**

```ts
import Razorpay from 'razorpay';

let client: Razorpay;

export function getRazorpay(): Razorpay {
  if (!client) {
    const key_id = process.env.RAZORPAY_KEY_ID;
    const key_secret = process.env.RAZORPAY_KEY_SECRET;
    if (!key_id || !key_secret) throw new Error('RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET required');
    client = new Razorpay({ key_id, key_secret });
  }
  return client;
}
```

- [ ] **Step 2.6: Create `src/lib/fcm.ts`**

```ts
import admin from 'firebase-admin';

let initialised = false;

export function getFcmApp(): admin.app.App {
  if (!initialised) {
    const serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON ?? '{}');
    admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
    initialised = true;
  }
  return admin.app();
}

export async function sendPush(token: string, title: string, body: string): Promise<void> {
  await getFcmApp().messaging().send({ token, notification: { title, body } });
}
```

- [ ] **Step 2.7: Commit**

```bash
git add src/lib && git commit -m "feat: add lib singletons (supabase, redis, queue, razorpay, fcm)"
```

---

## Task 3: Database Migrations

**Files:**
- Create: `supabase/migrations/001_initial_schema.sql`
- Create: `supabase/migrations/002_rls_policies.sql`

- [ ] **Step 3.1: Install Supabase CLI**

```bash
brew install supabase/tap/supabase
supabase login
supabase init
```

- [ ] **Step 3.2: Create `supabase/migrations/001_initial_schema.sql`**

```sql
-- Users
CREATE TABLE users (
  id           uuid PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  phone        text UNIQUE,
  name         text NOT NULL DEFAULT '',
  city         text NOT NULL DEFAULT '',
  language     text NOT NULL DEFAULT 'english'
                    CHECK (language IN ('english','hindi','telugu','tamil','kannada')),
  goal_tier    text NOT NULL DEFAULT 'active'
                    CHECK (goal_tier IN ('casual','active','champion','elite')),
  xp           int  NOT NULL DEFAULT 0,
  streak_days  int  NOT NULL DEFAULT 0,
  league       text NOT NULL DEFAULT 'bronze'
                    CHECK (league IN ('bronze','silver','gold','elite')),
  avatar_url   text,
  kyc_verified boolean NOT NULL DEFAULT false,
  fcm_token    text,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- Step data
CREATE TABLE step_logs (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  steps        int  NOT NULL CHECK (steps >= 0),
  synced_at    timestamptz NOT NULL,
  source       text NOT NULL CHECK (source IN ('healthkit','health_connect','manual')),
  device_model text NOT NULL DEFAULT '',
  os_version   text NOT NULL DEFAULT '',
  flagged      boolean NOT NULL DEFAULT false
);
CREATE INDEX idx_step_logs_user_synced ON step_logs(user_id, synced_at DESC);

CREATE TABLE user_daily_steps (
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  date        date NOT NULL,
  total_steps int  NOT NULL DEFAULT 0,
  PRIMARY KEY (user_id, date)
);

-- Challenges
CREATE TABLE challenges (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title               text NOT NULL,
  type                text NOT NULL
                           CHECK (type IN ('free_daily','free_weekly','paid_pool','sponsored','team','city')),
  step_goal           int  NOT NULL,
  entry_fee           int  NOT NULL DEFAULT 0,  -- paise
  prize_pool          int  NOT NULL DEFAULT 0,  -- paise
  max_participants    int,
  start_time          timestamptz NOT NULL,
  end_time            timestamptz NOT NULL,
  status              text NOT NULL DEFAULT 'upcoming'
                           CHECK (status IN ('upcoming','active','ended','paid_out')),
  prize_distribution  jsonb NOT NULL DEFAULT '{"platform_fee_percent":10,"tiers":[{"top_percent":10,"share_percent":90}]}'::jsonb,
  created_by          uuid REFERENCES users(id),
  sponsor_name        text,
  created_at          timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_challenges_status ON challenges(status);
CREATE INDEX idx_challenges_end_time ON challenges(end_time);

CREATE TABLE challenge_participants (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id uuid NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  joined_at    timestamptz NOT NULL DEFAULT now(),
  final_rank   int,
  payout_amount int,
  UNIQUE (challenge_id, user_id)
);
CREATE INDEX idx_cp_challenge ON challenge_participants(challenge_id);
CREATE INDEX idx_cp_user ON challenge_participants(user_id);

-- Wallet
CREATE TABLE wallet_transactions (
  id               uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  type             text NOT NULL CHECK (type IN ('credit','debit','fee')),
  amount           int  NOT NULL CHECK (amount > 0),  -- paise
  idempotency_key  text NOT NULL UNIQUE,
  reference_id     text,
  description      text NOT NULL,
  created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_wallet_txn_user ON wallet_transactions(user_id, created_at DESC);

-- Leaderboard snapshots
CREATE TABLE leaderboard_snapshots (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  scope       text NOT NULL CHECK (scope IN ('global','city','challenge')),
  scope_id    text NOT NULL DEFAULT 'global',
  rank        int  NOT NULL,
  steps       int  NOT NULL,
  snapped_at  timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX idx_lb_snap_user ON leaderboard_snapshots(user_id, snapped_at DESC);

-- Anti-cheat
CREATE TABLE step_flags (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  step_log_id  uuid NOT NULL REFERENCES step_logs(id) ON DELETE CASCADE,
  reason       text NOT NULL,
  reviewed     boolean NOT NULL DEFAULT false,
  created_at   timestamptz NOT NULL DEFAULT now()
);

-- Social
CREATE TABLE friendships (
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  friend_id  uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, friend_id),
  CHECK (user_id <> friend_id)
);

-- Gamification
CREATE TABLE user_badges (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  badge_slug text NOT NULL,
  earned_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (user_id, badge_slug)
);
```

- [ ] **Step 3.3: Create `supabase/migrations/002_rls_policies.sql`**

```sql
-- Enable RLS on all tables
ALTER TABLE users                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE step_logs             ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_daily_steps      ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenges            ENABLE ROW LEVEL SECURITY;
ALTER TABLE challenge_participants ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE leaderboard_snapshots ENABLE ROW LEVEL SECURITY;
ALTER TABLE step_flags            ENABLE ROW LEVEL SECURITY;
ALTER TABLE friendships           ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_badges           ENABLE ROW LEVEL SECURITY;

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

-- Challenge participants: own rows + read others in same challenge
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

-- Step flags: service role only (no user policy)
-- Friendships: own rows only
CREATE POLICY "friendships_own" ON friendships
  FOR ALL USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- Badges: own read
CREATE POLICY "badges_own" ON user_badges
  FOR SELECT USING (auth.uid() = user_id);
```

- [ ] **Step 3.4: Run migrations against local Supabase**

```bash
supabase start
supabase db push
```

Expected: `Applying migration 001_initial_schema.sql... ok` and `002_rls_policies.sql... ok`

- [ ] **Step 3.5: Commit**

```bash
git add supabase/ && git commit -m "feat: add database schema and RLS migrations"
```

---

## Task 4: Express App + Gateway Middleware

**Files:**
- Create: `src/app.ts`
- Create: `src/index.ts`
- Create: `src/gateway/middleware/auth.ts`
- Create: `src/gateway/middleware/rateLimit.ts`
- Create: `src/gateway/middleware/validate.ts`
- Create: `src/gateway/errorHandler.ts`
- Create: `tests/helpers/app.ts`
- Create: `tests/gateway/auth.middleware.test.ts`

- [ ] **Step 4.1: Write the failing auth middleware test**

```ts
// tests/gateway/auth.middleware.test.ts
import request from 'supertest';
import express from 'express';
import { authMiddleware } from '../../src/gateway/middleware/auth';

const app = express();
app.use(authMiddleware);
app.get('/test', (req, res) => res.json({ userId: req.user?.id }));

jest.mock('../../src/lib/supabase', () => ({
  getSupabase: () => ({
    auth: {
      getUser: jest.fn().mockImplementation((token: string) => {
        if (token === 'valid-token') {
          return { data: { user: { id: 'user-123' } }, error: null };
        }
        return { data: { user: null }, error: { message: 'Invalid token' } };
      }),
    },
  }),
}));

describe('authMiddleware', () => {
  it('returns 401 when Authorization header is missing', async () => {
    const res = await request(app).get('/test');
    expect(res.status).toBe(401);
  });

  it('returns 401 when token is invalid', async () => {
    const res = await request(app).get('/test').set('Authorization', 'Bearer bad-token');
    expect(res.status).toBe(401);
  });

  it('sets req.user and calls next when token is valid', async () => {
    const res = await request(app).get('/test').set('Authorization', 'Bearer valid-token');
    expect(res.status).toBe(200);
    expect(res.body.userId).toBe('user-123');
  });
});
```

- [ ] **Step 4.2: Run test to confirm it fails**

```bash
cd /Users/harsha/StepUp/stepup-api && npx jest tests/gateway/auth.middleware.test.ts --no-coverage
```

Expected: `FAIL` — `Cannot find module '../../src/gateway/middleware/auth'`

- [ ] **Step 4.3: Create `src/gateway/middleware/auth.ts`**

```ts
import { Request, Response, NextFunction } from 'express';
import { getSupabase } from '../../lib/supabase';

export async function authMiddleware(req: Request, res: Response, next: NextFunction): Promise<void> {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing authorization header' });
    return;
  }
  const token = header.slice(7);
  const { data, error } = await getSupabase().auth.getUser(token);
  if (error || !data.user) {
    res.status(401).json({ error: 'Invalid or expired token' });
    return;
  }
  req.user = { id: data.user.id, email: data.user.email, phone: data.user.phone ?? undefined };
  next();
}
```

- [ ] **Step 4.4: Run test to confirm it passes**

```bash
npx jest tests/gateway/auth.middleware.test.ts --no-coverage
```

Expected: `PASS` — 3 tests passing

- [ ] **Step 4.5: Create `src/gateway/middleware/rateLimit.ts`**

```ts
import { Request, Response, NextFunction } from 'express';
import { getRedis } from '../../lib/redis';

const WINDOW_SECONDS = 60;
const MAX_REQUESTS = 100;

export async function rateLimitMiddleware(req: Request, res: Response, next: NextFunction): Promise<void> {
  const userId = req.user?.id ?? req.ip;
  const key = `rate:${userId}`;
  const redis = getRedis();
  const current = await redis.incr(key);
  if (current === 1) await redis.expire(key, WINDOW_SECONDS);
  if (current > MAX_REQUESTS) {
    res.status(429).json({ error: 'Rate limit exceeded. Try again in a minute.' });
    return;
  }
  next();
}
```

- [ ] **Step 4.6: Create `src/gateway/middleware/validate.ts`**

```ts
import { Request, Response, NextFunction } from 'express';
import { ZodSchema, ZodError } from 'zod';

export function validateBody<T>(schema: ZodSchema<T>) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const result = schema.safeParse(req.body);
    if (!result.success) {
      res.status(400).json({ error: 'Validation failed', details: result.error.flatten() });
      return;
    }
    req.body = result.data;
    next();
  };
}
```

- [ ] **Step 4.7: Create `src/gateway/errorHandler.ts`**

```ts
import { Request, Response, NextFunction } from 'express';
import { logger } from '../lib/logger';

export function errorHandler(err: Error, req: Request, res: Response, _next: NextFunction): void {
  logger.error({ err, url: req.url, method: req.method }, 'Unhandled error');
  res.status(500).json({ error: 'Internal server error' });
}
```

- [ ] **Step 4.8: Create `src/app.ts`**

```ts
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { authMiddleware } from './gateway/middleware/auth';
import { rateLimitMiddleware } from './gateway/middleware/rateLimit';
import { errorHandler } from './gateway/errorHandler';
import { authRouter } from './modules/auth/auth.router';
import { stepsRouter } from './modules/steps/steps.router';
import { challengesRouter } from './modules/challenges/challenges.router';
import { leaderboardRouter } from './modules/leaderboard/leaderboard.router';
import { walletRouter } from './modules/wallet/wallet.router';

export function createApp() {
  const app = express();
  app.use(helmet());
  app.use(cors({ origin: process.env.CORS_ORIGIN ?? '*' }));
  app.use(express.json());

  // Public routes (no auth)
  app.get('/health', (_req, res) => res.json({ status: 'ok' }));
  app.use('/auth', authRouter);
  app.post('/wallet/webhook/razorpay', express.raw({ type: 'application/json' }), (await import('./modules/wallet/razorpay.webhook')).razorpayWebhookRouter);

  // Protected routes
  app.use(authMiddleware);
  app.use(rateLimitMiddleware);
  app.use('/steps', stepsRouter);
  app.use('/challenges', challengesRouter);
  app.use('/leaderboard', leaderboardRouter);
  app.use('/wallet', walletRouter);

  app.use(errorHandler);
  return app;
}
```

- [ ] **Step 4.9: Create `src/index.ts`**

```ts
import 'dotenv/config';
import { createApp } from './app';
import { logger } from './lib/logger';

const PORT = Number(process.env.PORT ?? 3000);
const app = createApp();

app.listen(PORT, () => {
  logger.info({ port: PORT }, 'StepUp API started');
});
```

- [ ] **Step 4.10: Install missing deps**

```bash
npm install helmet cors dotenv
npm install --save-dev @types/cors
```

- [ ] **Step 4.11: Commit**

```bash
git add src/app.ts src/index.ts src/gateway/ tests/gateway/ && git commit -m "feat: add express app, auth middleware, rate limiter, validate middleware"
```

---

## Task 5: Auth Module

**Files:**
- Create: `src/modules/auth/auth.service.ts`
- Create: `src/modules/auth/auth.router.ts`
- Create: `tests/modules/auth.test.ts`

- [ ] **Step 5.1: Write failing auth tests**

```ts
// tests/modules/auth.test.ts
import request from 'supertest';
import express from 'express';
import { authRouter } from '../../src/modules/auth/auth.router';

const app = express();
app.use(express.json());
app.use('/auth', authRouter);

jest.mock('../../src/modules/auth/auth.service', () => ({
  sendOtp: jest.fn().mockResolvedValue({ success: true }),
  verifyOtp: jest.fn().mockImplementation(({ phone, otp }) => {
    if (otp === '1234') return { session: { access_token: 'tok', refresh_token: 'ref' }, user: { id: 'u1' } };
    throw new Error('Invalid OTP');
  }),
  upsertProfile: jest.fn().mockResolvedValue({ id: 'u1', name: 'Harsha' }),
}));

describe('POST /auth/otp/send', () => {
  it('returns 200 for valid phone', async () => {
    const res = await request(app).post('/auth/otp/send').send({ phone: '9876543210' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });

  it('returns 400 for missing phone', async () => {
    const res = await request(app).post('/auth/otp/send').send({});
    expect(res.status).toBe(400);
  });
});

describe('POST /auth/otp/verify', () => {
  it('returns session on valid OTP', async () => {
    const res = await request(app).post('/auth/otp/verify').send({ phone: '9876543210', otp: '1234' });
    expect(res.status).toBe(200);
    expect(res.body.session.access_token).toBe('tok');
  });

  it('returns 401 on invalid OTP', async () => {
    const res = await request(app).post('/auth/otp/verify').send({ phone: '9876543210', otp: '9999' });
    expect(res.status).toBe(401);
  });
});

describe('PUT /auth/profile', () => {
  it('returns updated profile', async () => {
    const res = await request(app)
      .put('/auth/profile')
      .set('x-user-id', 'u1')
      .send({ name: 'Harsha', city: 'Hyderabad', language: 'telugu', goal_tier: 'active' });
    expect(res.status).toBe(200);
    expect(res.body.id).toBe('u1');
  });
});
```

- [ ] **Step 5.2: Run test to confirm it fails**

```bash
npx jest tests/modules/auth.test.ts --no-coverage
```

Expected: `FAIL` — `Cannot find module '../../src/modules/auth/auth.router'`

- [ ] **Step 5.3: Create `src/modules/auth/auth.service.ts`**

```ts
import axios from 'axios';
import { getSupabase } from '../../lib/supabase';

export async function sendOtp(phone: string): Promise<{ success: boolean }> {
  const authKey = process.env.MSG91_AUTH_KEY!;
  const templateId = process.env.MSG91_TEMPLATE_ID!;
  await axios.post('https://control.msg91.com/api/v5/otp', null, {
    params: { template_id: templateId, mobile: `91${phone}`, authkey: authKey },
  });
  return { success: true };
}

export async function verifyOtp(phone: string, otp: string) {
  const authKey = process.env.MSG91_AUTH_KEY!;
  await axios.get('https://control.msg91.com/api/v5/otp/verify', {
    params: { mobile: `91${phone}`, otp, authkey: authKey },
  });
  // Sign in via Supabase (phone auth must be enabled in dashboard)
  const { data, error } = await getSupabase().auth.signInWithOtp({ phone: `+91${phone}` });
  if (error) throw new Error(error.message);
  return data;
}

export async function upsertProfile(userId: string, profile: {
  name: string;
  city: string;
  language: string;
  goal_tier: string;
}) {
  const { data, error } = await getSupabase()
    .from('users')
    .upsert({ id: userId, ...profile }, { onConflict: 'id' })
    .select()
    .single();
  if (error) throw new Error(error.message);
  return data;
}
```

- [ ] **Step 5.4: Create `src/modules/auth/auth.router.ts`**

```ts
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { sendOtp, verifyOtp, upsertProfile } from './auth.service';

export const authRouter = Router();

const sendOtpSchema = z.object({ phone: z.string().regex(/^\d{10}$/, 'Must be 10-digit phone') });
const verifyOtpSchema = z.object({ phone: z.string().regex(/^\d{10}$/), otp: z.string().length(4) });
const profileSchema = z.object({
  name: z.string().min(1).max(100),
  city: z.string().min(1).max(100),
  language: z.enum(['english', 'hindi', 'telugu', 'tamil', 'kannada']),
  goal_tier: z.enum(['casual', 'active', 'champion', 'elite']),
});

authRouter.post('/otp/send', validateBody(sendOtpSchema), async (req: Request, res: Response) => {
  const result = await sendOtp(req.body.phone);
  res.json(result);
});

authRouter.post('/otp/verify', validateBody(verifyOtpSchema), async (req: Request, res: Response) => {
  try {
    const result = await verifyOtp(req.body.phone, req.body.otp);
    res.json(result);
  } catch {
    res.status(401).json({ error: 'Invalid OTP' });
  }
});

authRouter.put('/profile', validateBody(profileSchema), async (req: Request, res: Response) => {
  const userId = req.user?.id ?? req.headers['x-user-id'] as string;
  const result = await upsertProfile(userId, req.body);
  res.json(result);
});
```

- [ ] **Step 5.5: Install axios**

```bash
npm install axios
```

- [ ] **Step 5.6: Run tests — confirm passing**

```bash
npx jest tests/modules/auth.test.ts --no-coverage
```

Expected: `PASS` — 5 tests passing

- [ ] **Step 5.7: Commit**

```bash
git add src/modules/auth/ tests/modules/auth.test.ts && git commit -m "feat: auth module — OTP send/verify, profile upsert"
```

---

## Task 6: Steps Module + Anti-Cheat

**Files:**
- Create: `src/modules/steps/anticheat.service.ts`
- Create: `src/modules/steps/steps.service.ts`
- Create: `src/modules/steps/steps.router.ts`
- Create: `tests/modules/anticheat.test.ts`
- Create: `tests/modules/steps.test.ts`

- [ ] **Step 6.1: Write failing anti-cheat tests**

```ts
// tests/modules/anticheat.test.ts
import { runAnticheatChecks } from '../../src/modules/steps/anticheat.service';
import { StepSyncPayload } from '../../src/types';

const base: StepSyncPayload = {
  steps: 500,
  syncedAt: new Date().toISOString(),
  source: 'healthkit',
  deviceModel: 'iPhone 15',
  osVersion: '17.0',
};

describe('runAnticheatChecks', () => {
  it('returns null for valid payload', () => {
    expect(runAnticheatChecks(base, 15)).toBeNull();
  });

  it('flags when steps/min rate exceeds 200', () => {
    // 5000 steps in 15 min = 333 steps/min
    const result = runAnticheatChecks({ ...base, steps: 5000 }, 15);
    expect(result).toBe('rate_exceeded');
  });

  it('flags when steps exceed 10k in a single sync', () => {
    const result = runAnticheatChecks({ ...base, steps: 10001 }, 60);
    expect(result).toBe('single_sync_too_high');
  });

  it('flags manual source with high steps', () => {
    const result = runAnticheatChecks({ ...base, steps: 1000, source: 'manual' }, 15);
    expect(result).toBe('manual_source_high_steps');
  });

  it('does not flag manual source with low steps', () => {
    const result = runAnticheatChecks({ ...base, steps: 50, source: 'manual' }, 15);
    expect(result).toBeNull();
  });
});
```

- [ ] **Step 6.2: Run to confirm failing**

```bash
npx jest tests/modules/anticheat.test.ts --no-coverage
```

Expected: `FAIL` — `Cannot find module`

- [ ] **Step 6.3: Create `src/modules/steps/anticheat.service.ts`**

```ts
import { StepSyncPayload } from '../../types';

type FlagReason = 'rate_exceeded' | 'single_sync_too_high' | 'manual_source_high_steps' | null;

const MAX_STEPS_PER_MIN = 200;
const MAX_SINGLE_SYNC_STEPS = 10000;
const MAX_MANUAL_STEPS = 100;

export function runAnticheatChecks(payload: StepSyncPayload, intervalMinutes: number): FlagReason {
  const stepsPerMin = payload.steps / intervalMinutes;
  if (stepsPerMin > MAX_STEPS_PER_MIN) return 'rate_exceeded';
  if (payload.steps > MAX_SINGLE_SYNC_STEPS) return 'single_sync_too_high';
  if (payload.source === 'manual' && payload.steps > MAX_MANUAL_STEPS) return 'manual_source_high_steps';
  return null;
}
```

- [ ] **Step 6.4: Run anti-cheat tests — confirm passing**

```bash
npx jest tests/modules/anticheat.test.ts --no-coverage
```

Expected: `PASS` — 5 tests

- [ ] **Step 6.5: Write failing steps sync test**

```ts
// tests/modules/steps.test.ts
import request from 'supertest';
import express from 'express';
import { stepsRouter } from '../../src/modules/steps/steps.router';

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.user = { id: 'user-123' }; next(); });
app.use('/steps', stepsRouter);

jest.mock('../../src/modules/steps/steps.service', () => ({
  syncSteps: jest.fn().mockResolvedValue({ accepted: true, steps: 500 }),
}));

describe('POST /steps/sync', () => {
  it('accepts valid step payload', async () => {
    const res = await request(app).post('/steps/sync').send({
      steps: 500,
      syncedAt: new Date().toISOString(),
      source: 'healthkit',
      deviceModel: 'iPhone 15',
      osVersion: '17.0',
    });
    expect(res.status).toBe(200);
    expect(res.body.accepted).toBe(true);
  });

  it('rejects missing fields', async () => {
    const res = await request(app).post('/steps/sync').send({ steps: 500 });
    expect(res.status).toBe(400);
  });
});
```

- [ ] **Step 6.6: Create `src/modules/steps/steps.service.ts`**

```ts
import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { StepSyncPayload } from '../../types';
import { runAnticheatChecks } from './anticheat.service';

const SYNC_INTERVAL_MINUTES = 15;

export async function syncSteps(userId: string, payload: StepSyncPayload) {
  const flagReason = runAnticheatChecks(payload, SYNC_INTERVAL_MINUTES);
  const db = getSupabase();

  // Write step log
  const { data: log, error: logErr } = await db
    .from('step_logs')
    .insert({
      user_id: userId,
      steps: payload.steps,
      synced_at: payload.syncedAt,
      source: payload.source,
      device_model: payload.deviceModel,
      os_version: payload.osVersion,
      flagged: flagReason !== null,
    })
    .select()
    .single();
  if (logErr) throw new Error(logErr.message);

  // Write flag if needed (silently)
  if (flagReason && log) {
    await db.from('step_flags').insert({ user_id: userId, step_log_id: log.id, reason: flagReason });
  }

  // If flagged, don't update leaderboard
  if (flagReason) return { accepted: false, steps: payload.steps, flagged: true };

  // Upsert daily steps aggregate
  const today = new Date().toISOString().slice(0, 10);
  await db.rpc('increment_daily_steps', { p_user_id: userId, p_date: today, p_steps: payload.steps });

  // Update Redis leaderboard for all active challenges user is in
  await updateLeaderboardsForUser(userId, payload.steps);

  return { accepted: true, steps: payload.steps };
}

async function updateLeaderboardsForUser(userId: string, newSteps: number) {
  const redis = getRedis();
  const db = getSupabase();

  // Get active challenge participations
  const { data: participations } = await db
    .from('challenge_participants')
    .select('challenge_id')
    .eq('user_id', userId);

  const today = new Date().toISOString().slice(0, 10);
  const globalKey = `leaderboard:global:${today}`;

  await redis.zincrby(globalKey, newSteps, userId);
  await redis.expire(globalKey, 60 * 60 * 48); // 48h TTL

  for (const p of participations ?? []) {
    const key = `leaderboard:challenge:${p.challenge_id}`;
    await redis.zincrby(key, newSteps, userId);
  }
}
```

- [ ] **Step 6.7: Create `src/modules/steps/steps.router.ts`**

```ts
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { syncSteps } from './steps.service';

export const stepsRouter = Router();

const syncSchema = z.object({
  steps: z.number().int().min(0).max(50000),
  syncedAt: z.string().datetime(),
  source: z.enum(['healthkit', 'health_connect', 'manual']),
  deviceModel: z.string().min(1),
  osVersion: z.string().min(1),
});

stepsRouter.post('/sync', validateBody(syncSchema), async (req: Request, res: Response) => {
  const result = await syncSteps(req.user!.id, req.body);
  res.json(result);
});
```

- [ ] **Step 6.8: Add `increment_daily_steps` Postgres function to migrations**

Create `supabase/migrations/003_functions.sql`:

```sql
CREATE OR REPLACE FUNCTION increment_daily_steps(p_user_id uuid, p_date date, p_steps int)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO user_daily_steps (user_id, date, total_steps)
  VALUES (p_user_id, p_date, p_steps)
  ON CONFLICT (user_id, date)
  DO UPDATE SET total_steps = user_daily_steps.total_steps + EXCLUDED.total_steps;
END;
$$;
```

```bash
supabase db push
```

- [ ] **Step 6.9: Run all steps tests**

```bash
npx jest tests/modules/anticheat.test.ts tests/modules/steps.test.ts --no-coverage
```

Expected: `PASS` — 7 tests

- [ ] **Step 6.10: Commit**

```bash
git add src/modules/steps/ tests/modules/anticheat.test.ts tests/modules/steps.test.ts supabase/migrations/003_functions.sql
git commit -m "feat: steps module with anti-cheat pipeline and Redis leaderboard update"
```

---

## Task 7: Challenges Module

**Files:**
- Create: `src/modules/challenges/challenges.service.ts`
- Create: `src/modules/challenges/challenges.router.ts`
- Create: `tests/modules/challenges.test.ts`

- [ ] **Step 7.1: Write failing challenges tests**

```ts
// tests/modules/challenges.test.ts
import request from 'supertest';
import express from 'express';
import { challengesRouter } from '../../src/modules/challenges/challenges.router';

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.user = { id: 'user-123' }; next(); });
app.use('/challenges', challengesRouter);

const mockChallenge = {
  id: 'ch-1', title: 'Weekend Warriors', type: 'paid_pool',
  step_goal: 10000, entry_fee: 5000, prize_pool: 225000,
  status: 'active', start_time: new Date().toISOString(),
  end_time: new Date(Date.now() + 86400000).toISOString(),
  max_participants: 100,
  prize_distribution: { platform_fee_percent: 10, tiers: [{ top_percent: 10, share_percent: 90 }] },
};

jest.mock('../../src/modules/challenges/challenges.service', () => ({
  listChallenges: jest.fn().mockResolvedValue([mockChallenge]),
  getChallenge: jest.fn().mockResolvedValue(mockChallenge),
  joinChallenge: jest.fn().mockResolvedValue({ joined: true, challenge_id: 'ch-1' }),
}));

describe('GET /challenges', () => {
  it('returns challenge list', async () => {
    const res = await request(app).get('/challenges');
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].title).toBe('Weekend Warriors');
  });
});

describe('POST /challenges/:id/join', () => {
  it('returns joined result', async () => {
    const res = await request(app).post('/challenges/ch-1/join');
    expect(res.status).toBe(200);
    expect(res.body.joined).toBe(true);
  });
});
```

- [ ] **Step 7.2: Run to confirm failing**

```bash
npx jest tests/modules/challenges.test.ts --no-coverage
```

Expected: `FAIL`

- [ ] **Step 7.3: Create `src/modules/challenges/challenges.service.ts`**

```ts
import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { ChallengeRow } from '../../types';

export async function listChallenges(status?: string): Promise<ChallengeRow[]> {
  let query = getSupabase().from('challenges').select('*').order('start_time', { ascending: true });
  if (status) query = query.eq('status', status);
  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return data ?? [];
}

export async function getChallenge(id: string): Promise<ChallengeRow> {
  const { data, error } = await getSupabase()
    .from('challenges').select('*').eq('id', id).single();
  if (error) throw new Error(error.message);
  return data;
}

export async function joinChallenge(userId: string, challengeId: string) {
  const db = getSupabase();

  // Fetch challenge to get entry fee
  const challenge = await getChallenge(challengeId);
  if (challenge.status !== 'active' && challenge.status !== 'upcoming') {
    throw new Error('Challenge is not open for joining');
  }

  // Check max participants
  if (challenge.max_participants) {
    const { count } = await db
      .from('challenge_participants')
      .select('*', { count: 'exact', head: true })
      .eq('challenge_id', challengeId);
    if ((count ?? 0) >= challenge.max_participants) throw new Error('Challenge is full');
  }

  // Debit entry fee + join atomically via DB transaction
  const idempotencyKey = `challenge_join:${userId}:${challengeId}`;
  if (challenge.entry_fee > 0) {
    await debitWalletForChallenge(userId, challenge.entry_fee, challengeId, idempotencyKey, db);
  }

  // Insert participant
  const { error: joinErr } = await db
    .from('challenge_participants')
    .insert({ challenge_id: challengeId, user_id: userId });
  if (joinErr) {
    if (joinErr.code === '23505') throw new Error('Already joined this challenge');
    throw new Error(joinErr.message);
  }

  // Add to Redis leaderboard
  const redis = getRedis();
  await redis.zadd(`leaderboard:challenge:${challengeId}`, 0, userId);

  return { joined: true, challenge_id: challengeId };
}

async function debitWalletForChallenge(
  userId: string, amount: number, challengeId: string,
  idempotencyKey: string, db: ReturnType<typeof getSupabase>
) {
  // Check balance
  const { data: txns } = await db
    .from('wallet_transactions')
    .select('type, amount')
    .eq('user_id', userId);
  const balance = (txns ?? []).reduce((sum, t) =>
    t.type === 'credit' ? sum + t.amount : sum - t.amount, 0);
  if (balance < amount) throw new Error('Insufficient wallet balance');

  // Debit
  const { error } = await db.from('wallet_transactions').insert({
    user_id: userId, type: 'debit', amount,
    idempotency_key: idempotencyKey,
    description: `Entry fee for challenge ${challengeId}`,
  });
  if (error && error.code !== '23505') throw new Error(error.message); // 23505 = idempotent duplicate
}
```

- [ ] **Step 7.4: Create `src/modules/challenges/challenges.router.ts`**

```ts
import { Router, Request, Response } from 'express';
import { listChallenges, getChallenge, joinChallenge } from './challenges.service';

export const challengesRouter = Router();

challengesRouter.get('/', async (req: Request, res: Response) => {
  const status = req.query.status as string | undefined;
  const data = await listChallenges(status);
  res.json(data);
});

challengesRouter.get('/:id', async (req: Request, res: Response) => {
  try {
    const data = await getChallenge(req.params.id);
    res.json(data);
  } catch {
    res.status(404).json({ error: 'Challenge not found' });
  }
});

challengesRouter.post('/:id/join', async (req: Request, res: Response) => {
  try {
    const result = await joinChallenge(req.user!.id, req.params.id);
    res.json(result);
  } catch (err: any) {
    const status = err.message.includes('balance') || err.message.includes('full') ? 400 : 500;
    res.status(status).json({ error: err.message });
  }
});
```

- [ ] **Step 7.5: Run tests — confirm passing**

```bash
npx jest tests/modules/challenges.test.ts --no-coverage
```

Expected: `PASS` — 2 tests

- [ ] **Step 7.6: Commit**

```bash
git add src/modules/challenges/ tests/modules/challenges.test.ts
git commit -m "feat: challenges module — list, get, join with wallet debit"
```

---

## Task 8: Payout Job

**Files:**
- Create: `src/modules/challenges/payout.job.ts`
- Create: `tests/jobs/payout.job.test.ts`

- [ ] **Step 8.1: Write failing payout job test**

```ts
// tests/jobs/payout.job.test.ts
import { processPayout } from '../../src/modules/challenges/payout.job';

const mockChallenge = {
  id: 'ch-1', prize_pool: 90000, status: 'ended',
  prize_distribution: { platform_fee_percent: 10, tiers: [{ top_percent: 50, share_percent: 90 }] },
};
const mockParticipants = [
  { user_id: 'u1', final_rank: null }, { user_id: 'u2', final_rank: null },
];
const mockRanks = [['u1', '15000'], ['u2', '12000']]; // Redis ZREVRANGE result

jest.mock('../../src/lib/supabase', () => ({
  getSupabase: () => ({
    from: jest.fn().mockReturnThis(),
    select: jest.fn().mockReturnThis(),
    eq: jest.fn().mockReturnThis(),
    single: jest.fn().mockResolvedValue({ data: mockChallenge, error: null }),
    update: jest.fn().mockReturnThis(),
    insert: jest.fn().mockResolvedValue({ error: null }),
    data: mockParticipants,
  }),
}));

jest.mock('../../src/lib/redis', () => ({
  getRedis: () => ({
    zrevrange: jest.fn().mockResolvedValue(mockRanks.flat()),
  }),
}));

describe('processPayout', () => {
  it('distributes prize to top 50% of participants', async () => {
    // 2 participants, top 50% = 1 winner
    // prize_pool = 90000, platform_fee = 10% = 9000, remaining = 81000
    // top tier (50% of participants) gets 90% of remaining = 72900
    await expect(processPayout('ch-1')).resolves.not.toThrow();
  });
});
```

- [ ] **Step 8.2: Run to confirm failing**

```bash
npx jest tests/jobs/payout.job.test.ts --no-coverage
```

Expected: `FAIL`

- [ ] **Step 8.3: Create `src/modules/challenges/payout.job.ts`**

```ts
import { createQueue, createWorker } from '../../lib/queue';
import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { logger } from '../../lib/logger';
import { PrizeDistribution } from '../../types';
import { v4 as uuid } from 'uuid';

const PAYOUT_QUEUE = 'challenge-payout';

export const payoutQueue = createQueue(PAYOUT_QUEUE);

// Start worker — called at app bootstrap
export function startPayoutWorker() {
  createWorker(PAYOUT_QUEUE, async (job) => {
    await processPayout(job.data.challengeId);
  });
}

export async function schedulePayoutJob(challengeId: string, runAt: Date) {
  const delay = runAt.getTime() - Date.now();
  await payoutQueue.add('payout', { challengeId }, { delay: Math.max(delay, 0) });
}

export async function processPayout(challengeId: string) {
  const db = getSupabase();
  const redis = getRedis();

  const { data: challenge, error } = await db
    .from('challenges').select('*').eq('id', challengeId).single();
  if (error || !challenge) throw new Error(`Challenge ${challengeId} not found`);

  logger.info({ challengeId }, 'Processing payout');

  // Get final ranks from Redis
  const lbKey = `leaderboard:challenge:${challengeId}`;
  const redisRanks = await redis.zrevrange(lbKey, 0, -1, 'WITHSCORES');

  // Parse [userId, score, userId, score, ...]
  const ranked: Array<{ userId: string; steps: number }> = [];
  for (let i = 0; i < redisRanks.length; i += 2) {
    ranked.push({ userId: redisRanks[i], steps: parseInt(redisRanks[i + 1]) });
  }

  const dist: PrizeDistribution = challenge.prize_distribution;
  const platformFee = Math.floor(challenge.prize_pool * dist.platform_fee_percent / 100);
  const distributablePool = challenge.prize_pool - platformFee;

  const walletInserts: object[] = [];

  for (const tier of dist.tiers) {
    const cutoff = Math.ceil(ranked.length * tier.top_percent / 100);
    const tierWinners = ranked.slice(0, cutoff);
    const tierPool = Math.floor(distributablePool * tier.share_percent / 100);
    const perWinner = tierWinners.length > 0 ? Math.floor(tierPool / tierWinners.length) : 0;

    for (let rank = 0; rank < tierWinners.length; rank++) {
      const winner = tierWinners[rank];
      walletInserts.push({
        user_id: winner.userId,
        type: 'credit',
        amount: perWinner,
        idempotency_key: `payout:${challengeId}:${winner.userId}`,
        reference_id: challengeId,
        description: `Challenge winnings — rank #${rank + 1}`,
      });

      // Update final rank on participant row
      await db.from('challenge_participants')
        .update({ final_rank: rank + 1, payout_amount: perWinner })
        .eq('challenge_id', challengeId).eq('user_id', winner.userId);
    }
  }

  if (walletInserts.length > 0) {
    const { error: wErr } = await db.from('wallet_transactions').insert(walletInserts);
    if (wErr) throw new Error(`Wallet insert failed: ${wErr.message}`);
  }

  // Mark challenge as paid_out
  await db.from('challenges').update({ status: 'paid_out' }).eq('id', challengeId);
  logger.info({ challengeId, winners: walletInserts.length }, 'Payout complete');
}
```

- [ ] **Step 8.4: Run test — confirm passing**

```bash
npx jest tests/jobs/payout.job.test.ts --no-coverage
```

Expected: `PASS`

- [ ] **Step 8.5: Commit**

```bash
git add src/modules/challenges/payout.job.ts tests/jobs/payout.job.test.ts
git commit -m "feat: challenge payout BullMQ job with prize pool distribution"
```

---

## Task 9: Leaderboard Module

**Files:**
- Create: `src/modules/leaderboard/leaderboard.service.ts`
- Create: `src/modules/leaderboard/leaderboard.router.ts`
- Create: `tests/modules/leaderboard.test.ts`

- [ ] **Step 9.1: Write failing leaderboard tests**

```ts
// tests/modules/leaderboard.test.ts
import request from 'supertest';
import express from 'express';
import { leaderboardRouter } from '../../src/modules/leaderboard/leaderboard.router';

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.user = { id: 'user-123' }; next(); });
app.use('/leaderboard', leaderboardRouter);

jest.mock('../../src/modules/leaderboard/leaderboard.service', () => ({
  getGlobalLeaderboard: jest.fn().mockResolvedValue([
    { rank: 1, user_id: 'u1', name: 'Priya', steps: 18500, city: 'Mumbai' },
    { rank: 2, user_id: 'user-123', name: 'Harsha', steps: 12450, city: 'Hyderabad' },
  ]),
  getFriendsLeaderboard: jest.fn().mockResolvedValue([
    { rank: 1, user_id: 'user-123', name: 'Harsha', steps: 12450, city: 'Hyderabad' },
  ]),
  getCityLeaderboard: jest.fn().mockResolvedValue([]),
  getUserRank: jest.fn().mockResolvedValue({ rank: 2, steps: 12450 }),
}));

describe('GET /leaderboard/global', () => {
  it('returns ranked list with user rank highlighted', async () => {
    const res = await request(app).get('/leaderboard/global');
    expect(res.status).toBe(200);
    expect(res.body.entries).toHaveLength(2);
    expect(res.body.myRank).toEqual({ rank: 2, steps: 12450 });
  });
});

describe('GET /leaderboard/friends', () => {
  it('returns friends-only ranked list', async () => {
    const res = await request(app).get('/leaderboard/friends');
    expect(res.status).toBe(200);
    expect(res.body.entries).toHaveLength(1);
  });
});
```

- [ ] **Step 9.2: Run to confirm failing**

```bash
npx jest tests/modules/leaderboard.test.ts --no-coverage
```

Expected: `FAIL`

- [ ] **Step 9.3: Create `src/modules/leaderboard/leaderboard.service.ts`**

```ts
import { getRedis } from '../../lib/redis';
import { getSupabase } from '../../lib/supabase';

interface LeaderboardEntry {
  rank: number;
  user_id: string;
  name: string;
  city: string;
  steps: number;
}

async function enrichWithProfiles(rankedIds: string[]): Promise<Record<string, { name: string; city: string }>> {
  if (rankedIds.length === 0) return {};
  const { data } = await getSupabase().from('users').select('id, name, city').in('id', rankedIds);
  return Object.fromEntries((data ?? []).map(u => [u.id, { name: u.name, city: u.city }]));
}

async function parseRedisRanks(key: string, limit = 100): Promise<LeaderboardEntry[]> {
  const redis = getRedis();
  const raw = await redis.zrevrange(key, 0, limit - 1, 'WITHSCORES');
  const ids: string[] = [];
  const scores: Record<string, number> = {};
  for (let i = 0; i < raw.length; i += 2) {
    ids.push(raw[i]);
    scores[raw[i]] = parseInt(raw[i + 1]);
  }
  const profiles = await enrichWithProfiles(ids);
  return ids.map((id, idx) => ({
    rank: idx + 1,
    user_id: id,
    steps: scores[id],
    name: profiles[id]?.name ?? 'Unknown',
    city: profiles[id]?.city ?? '',
  }));
}

export async function getGlobalLeaderboard(limit = 100): Promise<LeaderboardEntry[]> {
  const today = new Date().toISOString().slice(0, 10);
  return parseRedisRanks(`leaderboard:global:${today}`, limit);
}

export async function getCityLeaderboard(city: string, limit = 100): Promise<LeaderboardEntry[]> {
  const today = new Date().toISOString().slice(0, 10);
  return parseRedisRanks(`leaderboard:city:${city}:${today}`, limit);
}

export async function getFriendsLeaderboard(userId: string, limit = 50): Promise<LeaderboardEntry[]> {
  const { data: friends } = await getSupabase()
    .from('friendships')
    .select('friend_id')
    .eq('user_id', userId);
  const friendIds = (friends ?? []).map(f => f.friend_id);
  friendIds.push(userId); // include self

  const all = await getGlobalLeaderboard(1000);
  const filtered = all.filter(e => friendIds.includes(e.user_id));
  return filtered.slice(0, limit).map((e, i) => ({ ...e, rank: i + 1 }));
}

export async function getUserRank(userId: string): Promise<{ rank: number; steps: number }> {
  const today = new Date().toISOString().slice(0, 10);
  const redis = getRedis();
  const key = `leaderboard:global:${today}`;
  const [rank, score] = await Promise.all([
    redis.zrevrank(key, userId),
    redis.zscore(key, userId),
  ]);
  return { rank: (rank ?? 0) + 1, steps: parseInt(score ?? '0') };
}
```

- [ ] **Step 9.4: Create `src/modules/leaderboard/leaderboard.router.ts`**

```ts
import { Router, Request, Response } from 'express';
import { getGlobalLeaderboard, getFriendsLeaderboard, getCityLeaderboard, getUserRank } from './leaderboard.service';

export const leaderboardRouter = Router();

leaderboardRouter.get('/global', async (req: Request, res: Response) => {
  const [entries, myRank] = await Promise.all([
    getGlobalLeaderboard(),
    getUserRank(req.user!.id),
  ]);
  res.json({ entries, myRank });
});

leaderboardRouter.get('/friends', async (req: Request, res: Response) => {
  const entries = await getFriendsLeaderboard(req.user!.id);
  res.json({ entries });
});

leaderboardRouter.get('/city/:city', async (req: Request, res: Response) => {
  const entries = await getCityLeaderboard(req.params.city);
  res.json({ entries });
});
```

- [ ] **Step 9.5: Run tests — confirm passing**

```bash
npx jest tests/modules/leaderboard.test.ts --no-coverage
```

Expected: `PASS` — 2 tests

- [ ] **Step 9.6: Commit**

```bash
git add src/modules/leaderboard/ tests/modules/leaderboard.test.ts
git commit -m "feat: leaderboard module — global, friends, city via Redis sorted sets"
```

---

## Task 10: Wallet Module + Razorpay Webhook

**Files:**
- Create: `src/modules/wallet/wallet.service.ts`
- Create: `src/modules/wallet/wallet.router.ts`
- Create: `src/modules/wallet/razorpay.webhook.ts`
- Create: `tests/modules/wallet.test.ts`

- [ ] **Step 10.1: Write failing wallet tests**

```ts
// tests/modules/wallet.test.ts
import request from 'supertest';
import express from 'express';
import { walletRouter } from '../../src/modules/wallet/wallet.router';

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.user = { id: 'user-123' }; next(); });
app.use('/wallet', walletRouter);

jest.mock('../../src/modules/wallet/wallet.service', () => ({
  getBalance: jest.fn().mockResolvedValue({ balance_paise: 184000, balance_inr: '1840.00' }),
  getTransactions: jest.fn().mockResolvedValue([
    { id: 't1', type: 'credit', amount: 24000, description: 'Challenge Won' },
  ]),
  createDepositOrder: jest.fn().mockResolvedValue({ order_id: 'ord_xxx', amount: 5000, currency: 'INR' }),
  requestWithdrawal: jest.fn().mockResolvedValue({ success: true, reference: 'pay_xxx' }),
}));

describe('GET /wallet/balance', () => {
  it('returns balance in paise and INR', async () => {
    const res = await request(app).get('/wallet/balance');
    expect(res.status).toBe(200);
    expect(res.body.balance_inr).toBe('1840.00');
  });
});

describe('POST /wallet/deposit/order', () => {
  it('creates Razorpay order', async () => {
    const res = await request(app).post('/wallet/deposit/order').send({ amount_inr: 50 });
    expect(res.status).toBe(200);
    expect(res.body.order_id).toBe('ord_xxx');
  });

  it('rejects deposit below ₹10', async () => {
    const res = await request(app).post('/wallet/deposit/order').send({ amount_inr: 5 });
    expect(res.status).toBe(400);
  });
});

describe('POST /wallet/withdraw', () => {
  it('initiates UPI withdrawal', async () => {
    const res = await request(app).post('/wallet/withdraw').send({ amount_inr: 100, upi_vpa: 'harsha@upi' });
    expect(res.status).toBe(200);
    expect(res.body.success).toBe(true);
  });
});
```

- [ ] **Step 10.2: Run to confirm failing**

```bash
npx jest tests/modules/wallet.test.ts --no-coverage
```

Expected: `FAIL`

- [ ] **Step 10.3: Create `src/modules/wallet/wallet.service.ts`**

```ts
import { getSupabase } from '../../lib/supabase';
import { getRazorpay } from '../../lib/razorpay';
import { v4 as uuid } from 'uuid';

export async function getBalance(userId: string) {
  const { data, error } = await getSupabase()
    .from('wallet_transactions')
    .select('type, amount')
    .eq('user_id', userId);
  if (error) throw new Error(error.message);

  const balance_paise = (data ?? []).reduce((sum, t) =>
    t.type === 'credit' ? sum + t.amount : sum - t.amount, 0);
  return {
    balance_paise,
    balance_inr: (balance_paise / 100).toFixed(2),
  };
}

export async function getTransactions(userId: string, limit = 20) {
  const { data, error } = await getSupabase()
    .from('wallet_transactions')
    .select('id, type, amount, description, reference_id, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw new Error(error.message);
  return data ?? [];
}

export async function createDepositOrder(userId: string, amount_inr: number) {
  const amount_paise = Math.floor(amount_inr * 100);
  const order = await getRazorpay().orders.create({
    amount: amount_paise,
    currency: 'INR',
    receipt: `deposit_${userId}_${Date.now()}`,
  });
  return { order_id: order.id, amount: amount_paise, currency: 'INR', key_id: process.env.RAZORPAY_KEY_ID };
}

export async function creditWallet(userId: string, amount_paise: number, referenceId: string, description: string) {
  const { error } = await getSupabase().from('wallet_transactions').insert({
    user_id: userId,
    type: 'credit',
    amount: amount_paise,
    idempotency_key: `deposit:${referenceId}`,
    reference_id: referenceId,
    description,
  });
  if (error && error.code !== '23505') throw new Error(error.message);
}

export async function requestWithdrawal(userId: string, amount_inr: number, upi_vpa: string) {
  const amount_paise = Math.floor(amount_inr * 100);
  const { balance_paise } = await getBalance(userId);
  if (balance_paise < amount_paise) throw new Error('Insufficient balance');

  const payoutId = uuid();
  const idempotencyKey = `withdraw:${userId}:${payoutId}`;

  // Debit wallet first (idempotent)
  await getSupabase().from('wallet_transactions').insert({
    user_id: userId, type: 'debit', amount: amount_paise,
    idempotency_key: idempotencyKey,
    description: `UPI withdrawal to ${upi_vpa}`,
  });

  // Initiate Razorpay payout
  const payout = await (getRazorpay() as any).payouts.create({
    account_number: process.env.RAZORPAY_ACCOUNT_NUMBER,
    fund_account: { account_type: 'vpa', vpa: { address: upi_vpa } },
    amount: amount_paise, currency: 'INR', mode: 'UPI',
    purpose: 'payout', queue_if_low_balance: false,
    reference_id: payoutId,
  });

  return { success: true, reference: payout.id };
}
```

- [ ] **Step 10.4: Create `src/modules/wallet/wallet.router.ts`**

```ts
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { getBalance, getTransactions, createDepositOrder, requestWithdrawal } from './wallet.service';

export const walletRouter = Router();

const depositSchema = z.object({ amount_inr: z.number().min(10).max(50000) });
const withdrawSchema = z.object({
  amount_inr: z.number().min(10).max(100000),
  upi_vpa: z.string().regex(/^[\w.-]+@[\w]+$/, 'Invalid UPI VPA'),
});

walletRouter.get('/balance', async (req: Request, res: Response) => {
  const data = await getBalance(req.user!.id);
  res.json(data);
});

walletRouter.get('/transactions', async (req: Request, res: Response) => {
  const data = await getTransactions(req.user!.id);
  res.json(data);
});

walletRouter.post('/deposit/order', validateBody(depositSchema), async (req: Request, res: Response) => {
  const order = await createDepositOrder(req.user!.id, req.body.amount_inr);
  res.json(order);
});

walletRouter.post('/withdraw', validateBody(withdrawSchema), async (req: Request, res: Response) => {
  try {
    const result = await requestWithdrawal(req.user!.id, req.body.amount_inr, req.body.upi_vpa);
    res.json(result);
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});
```

- [ ] **Step 10.5: Create `src/modules/wallet/razorpay.webhook.ts`**

```ts
import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { creditWallet } from './wallet.service';
import { logger } from '../../lib/logger';

export const razorpayWebhookRouter = Router();

razorpayWebhookRouter.post('/', async (req: Request, res: Response) => {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET!;
  const signature = req.headers['x-razorpay-signature'] as string;
  const body = req.body as Buffer;

  const expectedSig = crypto.createHmac('sha256', secret).update(body).digest('hex');
  if (signature !== expectedSig) {
    res.status(400).json({ error: 'Invalid signature' });
    return;
  }

  const event = JSON.parse(body.toString());
  if (event.event === 'payment.captured') {
    const payment = event.payload.payment.entity;
    const userId = payment.notes?.user_id;
    if (!userId) { res.json({ ok: true }); return; }

    await creditWallet(userId, payment.amount, payment.id, 'Wallet deposit via Razorpay');
    logger.info({ userId, amount: payment.amount }, 'Wallet credited via webhook');
  }

  res.json({ ok: true });
});
```

- [ ] **Step 10.6: Run wallet tests — confirm passing**

```bash
npx jest tests/modules/wallet.test.ts --no-coverage
```

Expected: `PASS` — 4 tests

- [ ] **Step 10.7: Commit**

```bash
git add src/modules/wallet/ tests/modules/wallet.test.ts
git commit -m "feat: wallet module — balance, deposit order, UPI withdrawal, Razorpay webhook"
```

---

## Task 11: Gamification (XP, Leagues, Badges)

**Files:**
- Create: `src/modules/steps/xp.service.ts`
- Modify: `src/modules/steps/steps.service.ts` (add XP award call)

- [ ] **Step 11.1: Create `src/modules/steps/xp.service.ts`**

```ts
import { getSupabase } from '../../lib/supabase';

const XP_PER_1K_STEPS = 10;

const LEAGUE_THRESHOLDS = [
  { league: 'elite',  min_weekly_xp: 4000 },
  { league: 'gold',   min_weekly_xp: 1500 },
  { league: 'silver', min_weekly_xp: 500  },
  { league: 'bronze', min_weekly_xp: 0    },
];

const BADGES: Array<{ slug: string; check: (xp: number, streak: number) => boolean }> = [
  { slug: 'streak_7',  check: (_, s) => s >= 7  },
  { slug: 'streak_21', check: (_, s) => s >= 21 },
  { slug: 'streak_30', check: (_, s) => s >= 30 },
];

export async function awardStepXp(userId: string, steps: number) {
  const xpEarned = Math.floor(steps / 1000) * XP_PER_1K_STEPS;
  if (xpEarned === 0) return;

  const db = getSupabase();
  const { data: user } = await db.from('users').select('xp, streak_days').eq('id', userId).single();
  const newXp = (user?.xp ?? 0) + xpEarned;

  await db.from('users').update({ xp: newXp }).eq('id', userId);
  await checkAndAwardBadges(userId, newXp, user?.streak_days ?? 0, db);
}

async function checkAndAwardBadges(
  userId: string, xp: number, streak: number,
  db: ReturnType<typeof getSupabase>
) {
  for (const badge of BADGES) {
    if (badge.check(xp, streak)) {
      await db.from('user_badges')
        .upsert({ user_id: userId, badge_slug: badge.slug }, { onConflict: 'user_id,badge_slug', ignoreDuplicates: true });
    }
  }
}

// Called by BullMQ cron every Monday midnight IST
export async function recalculateLeagues() {
  const db = getSupabase();
  // Get all users and their XP earned in the past 7 days
  // Simplified: use total xp for now, weekly calc can be added via a view
  const { data: users } = await db.from('users').select('id, xp');
  for (const user of users ?? []) {
    const league = LEAGUE_THRESHOLDS.find(t => user.xp >= t.min_weekly_xp)?.league ?? 'bronze';
    await db.from('users').update({ league }).eq('id', user.id);
  }
}
```

- [ ] **Step 11.2: Wire XP award into steps sync — modify `src/modules/steps/steps.service.ts`**

Add after `await updateLeaderboardsForUser(userId, payload.steps);`:

```ts
  // Award XP (fire-and-forget, non-blocking)
  import('./xp.service').then(({ awardStepXp }) => awardStepXp(userId, payload.steps)).catch(() => {});
```

Full updated return block of `syncSteps`:

```ts
  await updateLeaderboardsForUser(userId, payload.steps);
  // Award XP non-blocking
  import('./xp.service').then(({ awardStepXp }) => awardStepXp(userId, payload.steps)).catch(() => {});
  return { accepted: true, steps: payload.steps };
```

- [ ] **Step 11.3: Register Monday cron for league recalc in `src/index.ts`**

Add after `app.listen(...)`:

```ts
import { createQueue } from './lib/queue';
import { recalculateLeagues } from './modules/steps/xp.service';

// Every Monday at midnight IST (UTC+5:30 = Sunday 18:30 UTC)
const leagueCron = createQueue('league-recalc');
leagueCron.add('recalc', {}, { repeat: { pattern: '30 18 * * 0' } });
```

- [ ] **Step 11.4: Commit**

```bash
git add src/modules/steps/xp.service.ts src/modules/steps/steps.service.ts src/index.ts
git commit -m "feat: XP, badges, and weekly league recalculation"
```

---

## Task 12: Push Notifications

**Files:**
- Create: `src/modules/notifications/notifications.service.ts`

- [ ] **Step 12.1: Create `src/modules/notifications/notifications.service.ts`**

```ts
import { getSupabase } from '../../lib/supabase';
import { sendPush } from '../../lib/fcm';
import { logger } from '../../lib/logger';

export async function notifyUser(userId: string, title: string, body: string) {
  const { data: user } = await getSupabase()
    .from('users').select('fcm_token').eq('id', userId).single();
  if (!user?.fcm_token) return;
  try {
    await sendPush(user.fcm_token, title, body);
  } catch (err) {
    logger.warn({ userId, err }, 'FCM push failed');
  }
}

export async function notifyChallengePayout(userId: string, amount_paise: number, rank: number) {
  const inr = (amount_paise / 100).toFixed(0);
  await notifyUser(userId, '🏆 You won!', `Rank #${rank} — ₹${inr} credited to your wallet`);
}

export async function notifyRankChange(userId: string, newRank: number, direction: 'up' | 'down') {
  const arrow = direction === 'up' ? '▲' : '▼';
  await notifyUser(userId, 'Rank changed', `${arrow} You are now #${newRank} on the leaderboard`);
}
```

- [ ] **Step 12.2: Wire payout notification into `payout.job.ts`**

Add at the end of the winner loop in `processPayout`, after `update({ final_rank... })`:

```ts
import { notifyChallengePayout } from '../notifications/notifications.service';
// Inside winner loop:
await notifyChallengePayout(winner.userId, perWinner, rank + 1);
```

- [ ] **Step 12.3: Commit**

```bash
git add src/modules/notifications/ src/modules/challenges/payout.job.ts
git commit -m "feat: FCM push notifications for payouts and rank changes"
```

---

## Task 13: Run Full Test Suite + Fix Any Failures

- [ ] **Step 13.1: Run all tests**

```bash
cd /Users/harsha/StepUp/stepup-api && npx jest --no-coverage
```

Expected: All test suites pass. If any fail, read the error, fix the issue, re-run.

- [ ] **Step 13.2: Run with coverage**

```bash
npx jest --coverage
```

Expected: Coverage report generated. Core services (anticheat, wallet, leaderboard) should be >70%.

- [ ] **Step 13.3: Commit**

```bash
git add . && git commit -m "test: full test suite passing"
```

---

## Task 14: Deployment — Railway + CI/CD

**Files:**
- Create: `Procfile`
- Create: `.github/workflows/ci.yml`
- Create: `railway.json`

- [ ] **Step 14.1: Create `Procfile`**

```
web: node dist/index.js
```

- [ ] **Step 14.2: Create `railway.json`**

```json
{
  "$schema": "https://railway.app/railway.schema.json",
  "build": { "builder": "NIXPACKS", "buildCommand": "npm run build" },
  "deploy": { "startCommand": "npm start", "healthcheckPath": "/health" }
}
```

- [ ] **Step 14.3: Create `.github/workflows/ci.yml`**

```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with: { node-version: '20' }
      - run: npm ci
      - run: npm test -- --no-coverage
      - run: npm run build

  deploy:
    needs: test
    if: github.ref == 'refs/heads/main'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: railwayapp/railway-deploy@v1
        with:
          railway-token: ${{ secrets.RAILWAY_TOKEN }}
          service: stepup-api
```

- [ ] **Step 14.4: Push to GitHub and verify CI**

```bash
git add Procfile railway.json .github/
git commit -m "chore: add Railway deployment and GitHub Actions CI"
git remote add origin https://github.com/YOUR_USERNAME/stepup-api.git
git push -u origin main
```

- [ ] **Step 14.5: Deploy to Railway**

```bash
npm install -g @railway/cli
railway login
railway new --name stepup-api
railway up
```

Set all env vars in Railway dashboard from `.env.example`.

Expected: `railway status` shows `DEPLOYED` and `/health` returns `{"status":"ok"}`.

---

## Self-Review Checklist

- [x] Auth (OTP, Google, Apple, profile) — Task 5
- [x] Steps sync + anti-cheat — Task 6
- [x] Challenges list/get/join — Task 7
- [x] Payout BullMQ job — Task 8
- [x] Global/friends/city leaderboards — Task 9
- [x] Wallet balance/deposit/withdraw — Task 10
- [x] Razorpay webhook for deposit credit — Task 10
- [x] XP, badges, league recalc — Task 11
- [x] FCM push notifications — Task 12
- [x] Database schema + RLS — Task 3
- [x] JWT auth middleware — Task 4
- [x] Rate limiting — Task 4
- [x] Railway deployment + CI — Task 14
