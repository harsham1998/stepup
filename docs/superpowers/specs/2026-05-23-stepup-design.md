# StepUp — Design Spec
**Date:** 2026-05-23  
**Status:** Approved  
**Stack:** Flutter · Node.js (TypeScript) · Supabase · Redis  
**Target Market:** India (national launch)  
**Scale:** 100k+ users, real-money challenges from day 1

---

## 1. Product Overview

StepUp is a competitive wellness platform where users walk to win real money. Users join step challenges (free or paid-pool), compete on leaderboards, and withdraw winnings via UPI. The core retention loop is: **walk → rank up → win money → rejoin**.

### In-scope for v1
- User auth (Phone OTP, Google, Apple)
- Fitness tracking (Apple HealthKit, Google Health Connect)
- Paid pool challenges + free/sponsored challenges
- Global, friends, and city leaderboards with real-time updates
- Anti-cheat validation on step syncs
- In-app wallet with UPI deposit and withdrawal
- Gamification (XP, leagues, streaks, badges)
- Push notifications
- Admin dashboard (fraud analytics, challenge management, payout approvals)

### Out of scope for v1
- Corporate wellness / HR dashboard
- Insurance integrations
- Offline community events
- Smartwatch-native apps

---

## 2. Architecture

### Pattern: Modular Monolith

Single Node.js application with clean internal module boundaries. Chosen over microservices because:
- Ships in 4–5 weeks vs 8–10 weeks for microservices
- Handles 100k users with Redis caching and Supabase connection pooling
- Module boundaries mean individual services can be extracted when a specific module becomes the bottleneck — no rewrite required

### System Layers

```
┌─────────────────────────────────────────────────┐
│  Flutter App (iOS + Android)  │  Admin (React)  │
└────────────────┬────────────────────────────────┘
                 │ HTTPS / REST + Supabase Realtime
┌────────────────▼────────────────────────────────┐
│         Node.js API Gateway (Express)           │
│   JWT auth · Rate limiting · Request routing    │
└──┬──────────┬──────────┬──────────┬─────────────┘
   │          │          │          │
┌──▼──┐  ┌───▼───┐  ┌───▼───┐  ┌──▼────┐  ┌──────┐
│Auth │  │Chall- │  │Leader-│  │Wallet │  │Steps │
│     │  │enges  │  │board  │  │       │  │      │
└──┬──┘  └───┬───┘  └───┬───┘  └──┬────┘  └──┬───┘
   │          │          │          │           │
┌──▼──────────▼──────────▼──────────▼───────────▼──┐
│          Supabase (PostgreSQL + Realtime)         │
│              Redis (Upstash)                      │
│    Razorpay · Firebase FCM · MSG91 OTP            │
└───────────────────────────────────────────────────┘
```

---

## 3. Module Breakdown

### 3.1 Auth Module (`/modules/auth`)
- Phone OTP via MSG91 → Supabase Auth session
- Google Sign-In and Apple Sign-In via Supabase OAuth
- Profile creation: name, city, language preference (Telugu/Hindi/Tamil/Kannada/English), fitness goal tier
- JWT issued by Supabase Auth; validated at gateway on every request
- All endpoints: `POST /auth/otp/send`, `POST /auth/otp/verify`, `POST /auth/google`, `POST /auth/apple`, `PUT /auth/profile`

### 3.2 Steps Module (`/modules/steps`)
- Flutter background service syncs every 15 minutes from HealthKit (iOS) / Health Connect (Android)
- `POST /steps/sync` accepts raw step batch with device metadata (device model, OS version, sensor type)
- Anti-cheat pipeline (runs synchronously before writing):
  1. **Rate check:** >200 steps/min sustained → flag
  2. **Gap check:** >10k steps with no intermediate sync → flag
  3. **Device consistency:** step count without matching accelerometer data → flag
  4. Flagged syncs are written to `step_flags` table, excluded from leaderboard until reviewed; user not informed (silent flag)
- Valid steps written to `step_logs`, daily aggregate updated in `user_daily_steps`
- Triggers Redis ZADD update for all active challenges the user is enrolled in

### 3.3 Challenges Module (`/modules/challenges`)
- **Challenge types:** Daily free, weekly free, paid pool (₹10–₹5000 entry), sponsored free, team, city-vs-city
- **Create:** Admin-only endpoint `POST /challenges` with config: step_goal, duration_hours, entry_fee, max_participants, prize_distribution (e.g. top 10% split 80% of pool, platform takes 10%, sponsor 10%)
- **Join:** `POST /challenges/:id/join` — triggers wallet debit (entry fee) and inserts into `challenge_participants`; atomic DB transaction to prevent double-join or overpayment
- **Progress:** Real-time via Supabase Realtime subscription on `challenge_participants` table filtered by challenge_id
- **Payout:** BullMQ job scheduled at `end_time + 5 min`; fetches final ranks from Redis, cross-checks against Postgres `step_logs`, runs final anti-cheat sweep, credits winner wallets, queues Razorpay payouts
- Endpoints: `GET /challenges`, `GET /challenges/:id`, `POST /challenges/:id/join`, `GET /challenges/:id/leaderboard`

### 3.4 Leaderboard Module (`/modules/leaderboard`)
- Redis sorted sets as primary store: `leaderboard:global:daily`, `leaderboard:city:{city_id}:daily`, `leaderboard:challenge:{challenge_id}`
- Updated on every valid step sync via `ZADD` (score = cumulative steps, member = user_id)
- `GET /leaderboard/global` → reads Redis `ZREVRANK` + `ZREVRANGE`, enriches with user profiles from Supabase
- `GET /leaderboard/friends` → ZREVRANGE filtered to friend user_ids (friends fetched from `friendships` table)
- `GET /leaderboard/city/:city` → city-scoped sorted set
- Supabase Realtime subscription on `leaderboard_snapshots` triggers Flutter rank-change notifications
- Daily snapshot written to `leaderboard_snapshots` at midnight IST for historical league calculations
- **Friend management endpoints (part of this module):** `POST /friends/add` (by phone number search), `DELETE /friends/:id`, `GET /friends` — bidirectional friendship stored as two rows in `friendships`

### 3.5a Gamification Rules (XP + Leagues)
- **XP earned:** 10 XP per 1,000 steps/day, 50 XP for completing a challenge goal, 100 XP for finishing top 10, 25 XP per streak day milestone (7/14/21/30)
- **League thresholds (weekly XP):** Bronze 0–499 · Silver 500–1,499 · Gold 1,500–3,999 · Elite 4,000+
- League recalculated every Monday at midnight IST via BullMQ cron job; stored on `users.league`
- Badges awarded server-side when milestone conditions are met (e.g. 21-day streak, first win, top 3 finish); stored in `user_badges` table

### 3.5 Wallet Module (`/modules/wallet`)
- Every wallet operation writes an idempotent ledger entry to `wallet_transactions` (debit/credit/fee) with a unique `idempotency_key`
- Balance is always derived from the ledger sum (never stored as a mutable field) — prevents race conditions
- **Deposit:** Razorpay order created server-side → Flutter SDK collects payment → Razorpay webhook `POST /wallet/webhook/razorpay` confirms → ledger credit
- **Withdraw:** `POST /wallet/withdraw` with UPI VPA → validates KYC flag → Razorpay Payout API → ledger debit on success callback
- **KYC:** Users with cumulative withdrawals >₹10,000 must complete PAN verification (Razorpay KYC flow) per RBI guidelines
- Endpoints: `GET /wallet/balance`, `GET /wallet/transactions`, `POST /wallet/deposit/order`, `POST /wallet/withdraw`, `POST /wallet/webhook/razorpay`

---

## 4. Database Schema (Supabase / PostgreSQL)

```sql
-- Users
users (id uuid PK, phone text UNIQUE, name text, city text, language text,
       goal_tier text, xp int DEFAULT 0, streak_days int DEFAULT 0,
       league text DEFAULT 'bronze', avatar_url text, kyc_verified bool DEFAULT false,
       created_at timestamptz)

-- Step data
step_logs (id uuid PK, user_id uuid FK, steps int, synced_at timestamptz,
           source text, device_model text, flagged bool DEFAULT false)
user_daily_steps (user_id uuid FK, date date, total_steps int,
                  PRIMARY KEY (user_id, date))

-- Challenges
challenges (id uuid PK, title text, type text, step_goal int,
            entry_fee int DEFAULT 0, prize_pool int DEFAULT 0,
            max_participants int, start_time timestamptz, end_time timestamptz,
            status text DEFAULT 'upcoming', prize_distribution jsonb,
            created_by uuid FK, sponsor_name text)
challenge_participants (id uuid PK, challenge_id uuid FK, user_id uuid FK,
                        joined_at timestamptz, final_rank int, payout_amount int,
                        UNIQUE (challenge_id, user_id))

-- Wallet
wallet_transactions (id uuid PK, user_id uuid FK, type text, amount int,
                     idempotency_key text UNIQUE, reference_id text,
                     description text, created_at timestamptz)

-- Leaderboard snapshots (for leagues)
leaderboard_snapshots (id uuid PK, user_id uuid FK, scope text,
                       scope_id text, rank int, steps int, snapped_at timestamptz)

-- Anti-cheat flags
step_flags (id uuid PK, user_id uuid FK, step_log_id uuid FK,
            reason text, reviewed bool DEFAULT false, created_at timestamptz)

-- Social
friendships (user_id uuid FK, friend_id uuid FK, created_at timestamptz,
             PRIMARY KEY (user_id, friend_id))

-- Gamification
user_badges (id uuid PK, user_id uuid FK, badge_slug text, earned_at timestamptz,
             UNIQUE (user_id, badge_slug))
```

Row Level Security enabled on all tables. Users can only read/write their own rows except `challenges` (public read) and `leaderboard_snapshots` (public read).

---

## 5. Flutter App Structure

```
lib/
  main.dart
  app.dart                     # MaterialApp, router, theme
  core/
    supabase_client.dart
    router.dart                # GoRouter
    theme.dart                 # Dark neon theme tokens
  features/
    auth/                      # Login, OTP, onboarding screens
    home/                      # Dashboard screen
    challenges/                # List, detail, join flow
    leaderboard/               # Global, friends, city tabs
    wallet/                    # Balance, deposit, withdraw
    profile/                   # Stats, badges, settings
    steps/                     # Background sync service
  shared/
    widgets/                   # StepRingWidget, ChallengeCard, etc.
    providers/                 # Riverpod providers
```

**State management:** Riverpod for all async state (challenges list, wallet balance, leaderboard). BLoC for the challenge join flow (multi-step: select → pay → confirm) and step sync state machine.

**Background step sync:** `flutter_background_service` package. Polls HealthKit/Health Connect every 15 min. Batches and POSTs to `/steps/sync`. Works when app is killed on both iOS and Android.

---

## 6. Node.js Backend Structure

```
src/
  index.ts                     # Express app bootstrap
  gateway/
    middleware/auth.ts         # Supabase JWT verification
    middleware/rateLimit.ts    # 100 req/min per user via Redis
    middleware/validate.ts     # Zod schema validation
  modules/
    auth/
      auth.router.ts
      auth.service.ts
    steps/
      steps.router.ts
      steps.service.ts
      anticheat.service.ts
    challenges/
      challenges.router.ts
      challenges.service.ts
      payout.job.ts            # BullMQ worker
    leaderboard/
      leaderboard.router.ts
      leaderboard.service.ts   # Redis ZADD/ZREVRANGE ops
    wallet/
      wallet.router.ts
      wallet.service.ts
      razorpay.webhook.ts
  lib/
    supabase.ts                # Supabase admin client
    redis.ts                   # Upstash Redis client
    razorpay.ts                # Razorpay client
    queue.ts                   # BullMQ setup
    logger.ts                  # Pino logger
```

---

## 7. Key Non-Functional Requirements

| Concern | Decision |
|---|---|
| Leaderboard latency | Redis ZADD/ZRANGE < 5ms; Supabase Realtime push < 500ms |
| Step sync throughput | BullMQ processes 100k jobs/hour with 4 worker threads |
| Payment idempotency | Every wallet op has a unique `idempotency_key`; webhook retries are safe |
| Anti-cheat | Silent flagging; flagged users excluded from payout but not notified until review |
| KYC compliance | Razorpay KYC required for withdrawals >₹10k cumulative (RBI guideline) |
| Data security | RLS on all Supabase tables; JWT validated at gateway; no client can directly call DB |
| Offline support | Flutter caches last leaderboard and step count locally; syncs on reconnect |

---

## 8. Visual Design

- **Style:** Dark Neon (confirmed)
- **Primary:** `#6366f1` (indigo)
- **Accent:** `#8b5cf6` (violet), `#34d399` (green for money), `#fbbf24` (amber for rank), `#f472b6` (pink for streaks)
- **Background:** `#0c0c18`
- **Cards:** `rgba(255,255,255,0.04)` with `rgba(255,255,255,0.07)` borders
- **Typography:** System font, weights 400/600/700/900
- **Screens:** Splash, Login/OTP, Onboarding (goal setup), Home, Challenges, Leaderboard, Wallet, Profile

---

## 9. Deployment

| Service | Platform |
|---|---|
| Node.js API | Railway (auto-deploy from main branch) |
| Redis | Upstash (serverless Redis, free tier → paid at scale) |
| Database | Supabase cloud (Pro plan for Realtime + pgBouncer) |
| Flutter (production) | Google Play Store + Apple App Store |
| Flutter (beta testing) | Firebase App Distribution (testers install via link — equivalent to Expo Go for React Native) |
| Flutter (dev) | `flutter run` on device or simulator via Flutter DevTools |
| Admin dashboard | Vercel (React web app only) |
| CI/CD | GitHub Actions: lint → test → build APK/IPA → deploy API on merge to main |
| Error tracking | Sentry (both Flutter and Node.js) |

---

## 10. Out-of-Scope Decisions (documented to prevent scope creep)

- **No social feed** in v1 — challenge sharing is WhatsApp deeplinks only
- **No in-app chat** — community is external (WhatsApp groups)
- **No smartwatch app** — HealthKit/Health Connect covers watch data passively
- **No corporate dashboard** — entire HR/admin module deferred to v2
- **No AI coach** — personalization deferred to v2
- **No insurance integration** — v3+
