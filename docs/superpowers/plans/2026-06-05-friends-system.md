# Friends System Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a complete friends system — unique usernames, friend search/request/accept, and friends competition in challenges.

**Architecture:** Two DB migrations (username column + friend_requests table), a new `/friends` Express module, and six Flutter touchpoints (profile edit, friends hub screen, community banner, home pulse, challenge leaderboard filter, challenge invite picker).

**Tech Stack:** Node.js/Express/TypeScript (API), Supabase Postgres (DB), Flutter/Riverpod/GoRouter (mobile)

---

## File Map

### New Files
| Path | Purpose |
|------|---------|
| `stepup-api/supabase/migrations/20260605000017_username.sql` | Add username column to users |
| `stepup-api/supabase/migrations/20260605000018_friend_requests.sql` | friend_requests table + RLS |
| `stepup-api/src/modules/friends/friends.service.ts` | All friend business logic |
| `stepup-api/src/modules/friends/friends.router.ts` | REST endpoints for friends |
| `stepup/lib/features/friends/models/friend.dart` | Friend data model |
| `stepup/lib/features/friends/models/friend_request.dart` | FriendRequest data model |
| `stepup/lib/features/friends/models/user_search_result.dart` | UserSearchResult + FriendshipStatus |
| `stepup/lib/features/friends/providers/friends_provider.dart` | Riverpod providers |
| `stepup/lib/features/friends/screens/friends_hub_screen.dart` | Full friends hub screen |
| `stepup/lib/features/friends/widgets/friends_community_banner.dart` | Banner for community screen |

### Modified Files
| Path | Change |
|------|--------|
| `stepup-api/src/app.ts` | Mount friendsRouter at `/friends` |
| `stepup-api/src/modules/auth/auth.router.ts` | Add `username` to updateProfileSchema |
| `stepup-api/src/modules/challenges/leaderboard.service.ts` | Add `friendIds` optional filter |
| `stepup-api/src/modules/challenges/challenges.router.ts` | Add leaderboard filter passthrough + POST /:id/invite |
| `stepup/lib/core/router.dart` | Add `/friends` route |
| `stepup/lib/features/profile/screens/profile_edit_screen.dart` | Add username field with debounce validation |
| `stepup/lib/features/home/widgets/friends_pulse_section.dart` | Add Manage link + Add slot |
| `stepup/lib/features/community/screens/community_screen.dart` | Add FriendsCommunityBanner |
| `stepup/lib/features/challenges/providers/challenges_provider.dart` | Add challengeFriendsLeaderboardProvider |
| `stepup/lib/features/challenges/screens/challenge_detail_screen.dart` | Add Friends leaderboard tab |
| `stepup/lib/features/challenges/screens/invite_friends_screen.dart` | Add friends picker section |

---

## Task 1: DB Migration — username column

**Files:**
- Create: `stepup-api/supabase/migrations/20260605000017_username.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- stepup-api/supabase/migrations/20260605000017_username.sql
ALTER TABLE users ADD COLUMN IF NOT EXISTS username text;
ALTER TABLE users ADD CONSTRAINT users_username_unique UNIQUE (username);
CREATE INDEX IF NOT EXISTS idx_users_username ON users (lower(username));
```

- [ ] **Step 2: Run the migration against the local/dev Supabase**

```bash
cd stepup-api
node run_migration.cjs supabase/migrations/20260605000017_username.sql
```

Expected: no error output, exits 0.

- [ ] **Step 3: Commit**

```bash
git add stepup-api/supabase/migrations/20260605000017_username.sql
git commit -m "feat: add username column to users table"
```

---

## Task 2: DB Migration — friend_requests table

**Files:**
- Create: `stepup-api/supabase/migrations/20260605000018_friend_requests.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- stepup-api/supabase/migrations/20260605000018_friend_requests.sql
CREATE TABLE IF NOT EXISTS friend_requests (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status      text NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sender_id, receiver_id),
  CHECK (sender_id <> receiver_id)
);

CREATE INDEX IF NOT EXISTS idx_fr_receiver ON friend_requests(receiver_id, status);
CREATE INDEX IF NOT EXISTS idx_fr_sender   ON friend_requests(sender_id, status);

ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

-- Sender can insert their own requests
CREATE POLICY fr_insert ON friend_requests FOR INSERT
  WITH CHECK (sender_id = auth.uid());

-- Both sender and receiver can read their own rows
CREATE POLICY fr_select ON friend_requests FOR SELECT
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- Only receiver can update status (accept / decline)
CREATE POLICY fr_update ON friend_requests FOR UPDATE
  USING (receiver_id = auth.uid())
  WITH CHECK (receiver_id = auth.uid());
```

- [ ] **Step 2: Run the migration**

```bash
cd stepup-api
node run_migration.cjs supabase/migrations/20260605000018_friend_requests.sql
```

Expected: exits 0.

- [ ] **Step 3: Commit**

```bash
git add stepup-api/supabase/migrations/20260605000018_friend_requests.sql
git commit -m "feat: add friend_requests table with RLS"
```

---

## Task 3: Friends Service (API)

**Files:**
- Create: `stepup-api/src/modules/friends/friends.service.ts`

- [ ] **Step 1: Create the service file**

```typescript
// stepup-api/src/modules/friends/friends.service.ts
import { getSupabase } from '../../lib/supabase';

export interface Friend {
  id: string;
  name: string;
  username: string | null;
  avatar_url: string | null;
  xp: number;
  league_slug: string;
  streak_days: number;
}

export interface FriendRequest {
  id: string;
  sender_id: string;
  sender_name: string;
  sender_username: string | null;
  sender_avatar: string | null;
  created_at: string;
}

export type FriendshipStatus = 'none' | 'pending_sent' | 'pending_received' | 'friends';

export interface UserSearchResult extends Friend {
  friendship_status: FriendshipStatus;
  request_id: string | null;
}

export async function listFriends(userId: string): Promise<Friend[]> {
  const db = getSupabase();
  const { data: friendships, error } = await db
    .from('friendships')
    .select('friend_id')
    .eq('user_id', userId);
  if (error) throw new Error(error.message);

  const friendIds = (friendships ?? []).map((f: any) => f.friend_id as string);
  if (friendIds.length === 0) return [];

  const [{ data: users }, { data: leagues }] = await Promise.all([
    db.from('users').select('id, name, username, avatar_url, streak_days').in('id', friendIds),
    db.from('user_leagues').select('user_id, xp, league_slug').in('user_id', friendIds),
  ]);

  const leagueMap: Record<string, { xp: number; league_slug: string }> = {};
  for (const l of leagues ?? []) leagueMap[l.user_id] = l;

  return (users ?? []).map((u: any) => ({
    id: u.id,
    name: u.name,
    username: u.username ?? null,
    avatar_url: u.avatar_url ?? null,
    xp: leagueMap[u.id]?.xp ?? 0,
    league_slug: leagueMap[u.id]?.league_slug ?? 'bronze',
    streak_days: u.streak_days ?? 0,
  }));
}

export async function searchUsers(query: string, requestingUserId: string): Promise<UserSearchResult[]> {
  const db = getSupabase();
  const clean = query.toLowerCase().replace(/^@/, '').trim();
  if (clean.length < 2) return [];

  const { data: users, error } = await db
    .from('users')
    .select('id, name, username, avatar_url, streak_days')
    .ilike('username', `${clean}%`)
    .neq('id', requestingUserId)
    .limit(10);
  if (error) throw new Error(error.message);
  if (!users || users.length === 0) return [];

  const userIds = users.map((u: any) => u.id as string);

  const [{ data: myFriendships }, { data: sentReqs }, { data: receivedReqs }, { data: leagues }] = await Promise.all([
    db.from('friendships').select('friend_id').eq('user_id', requestingUserId).in('friend_id', userIds),
    db.from('friend_requests').select('id, receiver_id, status').eq('sender_id', requestingUserId).in('receiver_id', userIds),
    db.from('friend_requests').select('id, sender_id, status').eq('receiver_id', requestingUserId).in('sender_id', userIds),
    db.from('user_leagues').select('user_id, xp, league_slug').in('user_id', userIds),
  ]);

  const friendSet = new Set((myFriendships ?? []).map((f: any) => f.friend_id as string));
  const sentMap: Record<string, { id: string; status: string }> = {};
  for (const r of sentReqs ?? []) sentMap[r.receiver_id] = r;
  const receivedMap: Record<string, { id: string; status: string }> = {};
  for (const r of receivedReqs ?? []) receivedMap[r.sender_id] = r;
  const leagueMap: Record<string, { xp: number; league_slug: string }> = {};
  for (const l of leagues ?? []) leagueMap[l.user_id] = l;

  return users.map((u: any) => {
    let friendship_status: FriendshipStatus = 'none';
    let request_id: string | null = null;

    if (friendSet.has(u.id)) {
      friendship_status = 'friends';
    } else if (sentMap[u.id]?.status === 'pending') {
      friendship_status = 'pending_sent';
      request_id = sentMap[u.id].id;
    } else if (receivedMap[u.id]?.status === 'pending') {
      friendship_status = 'pending_received';
      request_id = receivedMap[u.id].id;
    }

    return {
      id: u.id,
      name: u.name,
      username: u.username ?? null,
      avatar_url: u.avatar_url ?? null,
      xp: leagueMap[u.id]?.xp ?? 0,
      league_slug: leagueMap[u.id]?.league_slug ?? 'bronze',
      streak_days: u.streak_days ?? 0,
      friendship_status,
      request_id,
    };
  });
}

export async function getFriendRequests(userId: string): Promise<FriendRequest[]> {
  const db = getSupabase();
  const { data, error } = await db
    .from('friend_requests')
    .select('id, sender_id, created_at')
    .eq('receiver_id', userId)
    .eq('status', 'pending')
    .order('created_at', { ascending: false });
  if (error) throw new Error(error.message);
  if (!data || data.length === 0) return [];

  const senderIds = data.map((r: any) => r.sender_id as string);
  const { data: senders } = await db
    .from('users')
    .select('id, name, username, avatar_url')
    .in('id', senderIds);

  const senderMap: Record<string, any> = {};
  for (const u of senders ?? []) senderMap[u.id] = u;

  return data.map((r: any) => ({
    id: r.id,
    sender_id: r.sender_id,
    sender_name: senderMap[r.sender_id]?.name ?? 'Unknown',
    sender_username: senderMap[r.sender_id]?.username ?? null,
    sender_avatar: senderMap[r.sender_id]?.avatar_url ?? null,
    created_at: r.created_at,
  }));
}

export async function sendFriendRequest(senderId: string, receiverId: string): Promise<void> {
  const db = getSupabase();

  const { data: existing } = await db
    .from('friendships')
    .select('friend_id')
    .eq('user_id', senderId)
    .eq('friend_id', receiverId)
    .maybeSingle();
  if (existing) throw Object.assign(new Error('Already friends'), { statusCode: 409 });

  const { data: existingReq } = await db
    .from('friend_requests')
    .select('id, status, created_at')
    .eq('sender_id', senderId)
    .eq('receiver_id', receiverId)
    .maybeSingle();

  if (existingReq) {
    if (existingReq.status === 'pending') throw Object.assign(new Error('Request already sent'), { statusCode: 409 });
    if (existingReq.status === 'declined') {
      const declinedAt = new Date(existingReq.created_at).getTime();
      if (declinedAt > Date.now() - 7 * 24 * 60 * 60 * 1000) {
        throw Object.assign(new Error('Cannot re-request within 7 days of decline'), { statusCode: 429 });
      }
      await db.from('friend_requests').update({ status: 'pending', created_at: new Date().toISOString() }).eq('id', existingReq.id);
      return;
    }
  }

  const { error } = await db.from('friend_requests').insert({ sender_id: senderId, receiver_id: receiverId });
  if (error) throw new Error(error.message);
}

export async function respondToRequest(requestId: string, respondingUserId: string, action: 'accept' | 'decline'): Promise<{ sender_id: string }> {
  const db = getSupabase();

  const { data: req, error: rErr } = await db
    .from('friend_requests')
    .select('id, sender_id, receiver_id, status')
    .eq('id', requestId)
    .eq('receiver_id', respondingUserId)
    .maybeSingle();
  if (rErr || !req) throw Object.assign(new Error('Request not found'), { statusCode: 404 });
  if (req.status !== 'pending') throw Object.assign(new Error('Request already handled'), { statusCode: 409 });

  await db.from('friend_requests').update({ status: action === 'accept' ? 'accepted' : 'declined' }).eq('id', requestId);

  if (action === 'accept') {
    await db.from('friendships').insert([
      { user_id: req.receiver_id, friend_id: req.sender_id },
      { user_id: req.sender_id, friend_id: req.receiver_id },
    ]);
  }

  return { sender_id: req.sender_id };
}

export async function removeFriend(userId: string, friendId: string): Promise<void> {
  const db = getSupabase();
  await Promise.all([
    db.from('friendships').delete().eq('user_id', userId).eq('friend_id', friendId),
    db.from('friendships').delete().eq('user_id', friendId).eq('friend_id', userId),
  ]);
}

export async function checkUsernameAvailable(username: string, excludeUserId: string): Promise<boolean> {
  const clean = username.toLowerCase().trim();
  const { data } = await getSupabase()
    .from('users')
    .select('id')
    .eq('username', clean)
    .neq('id', excludeUserId)
    .maybeSingle();
  return !data;
}

export async function getFriendIds(userId: string): Promise<string[]> {
  const { data } = await getSupabase()
    .from('friendships')
    .select('friend_id')
    .eq('user_id', userId);
  return (data ?? []).map((f: any) => f.friend_id as string);
}
```

- [ ] **Step 2: Commit**

```bash
git add stepup-api/src/modules/friends/friends.service.ts
git commit -m "feat: add friends service (list, search, requests, send, respond, remove)"
```

---

## Task 4: Friends Router (API)

**Files:**
- Create: `stepup-api/src/modules/friends/friends.router.ts`

- [ ] **Step 1: Create the router file**

```typescript
// stepup-api/src/modules/friends/friends.router.ts
import { Router, Request, Response } from 'express';
import {
  listFriends, searchUsers, getFriendRequests,
  sendFriendRequest, respondToRequest, removeFriend,
  checkUsernameAvailable,
} from './friends.service';
import { notifyUser } from '../notifications/notifications.service';
import { getSupabase } from '../../lib/supabase';

export const friendsRouter = Router();

// GET /friends/check-username?q=foo
friendsRouter.get('/check-username', async (req: Request, res: Response) => {
  try {
    const q = ((req.query['q'] as string) ?? '').toLowerCase().trim();
    if (!/^[a-z0-9_]{3,20}$/.test(q)) return res.json({ available: false, reason: 'invalid_format' });
    const available = await checkUsernameAvailable(q, req.user!.id);
    res.json({ available });
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// GET /friends/search?q=username
friendsRouter.get('/search', async (req: Request, res: Response) => {
  try {
    const q = (req.query['q'] as string ?? '').trim();
    if (q.length < 2) return res.json([]);
    const results = await searchUsers(q, req.user!.id);
    res.json(results);
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// GET /friends/requests
friendsRouter.get('/requests', async (req: Request, res: Response) => {
  try {
    res.json(await getFriendRequests(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// GET /friends
friendsRouter.get('/', async (req: Request, res: Response) => {
  try {
    res.json(await listFriends(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// POST /friends/requests  body: { receiver_id }
friendsRouter.post('/requests', async (req: Request, res: Response) => {
  try {
    const { receiver_id } = req.body as { receiver_id?: string };
    if (!receiver_id) return res.status(400).json({ error: 'receiver_id required' });
    await sendFriendRequest(req.user!.id, receiver_id);

    const { data: sender } = await getSupabase()
      .from('users').select('name, username').eq('id', req.user!.id).maybeSingle();
    const label = sender?.username ? `@${sender.username}` : (sender?.name ?? 'Someone');
    notifyUser(receiver_id, 'Friend Request', `${label} sent you a friend request`).catch(() => {});

    res.status(201).json({ ok: true });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status((err as any).statusCode ?? 500).json({ error: msg });
  }
});

// PATCH /friends/requests/:id  body: { action: 'accept' | 'decline' }
friendsRouter.patch('/requests/:id', async (req: Request, res: Response) => {
  try {
    const { action } = req.body as { action?: 'accept' | 'decline' };
    if (action !== 'accept' && action !== 'decline') {
      return res.status(400).json({ error: 'action must be accept or decline' });
    }
    const { sender_id } = await respondToRequest(req.params['id']!, req.user!.id, action);

    if (action === 'accept') {
      const { data: accepter } = await getSupabase()
        .from('users').select('name, username').eq('id', req.user!.id).maybeSingle();
      const label = accepter?.username ? `@${accepter.username}` : (accepter?.name ?? 'Someone');
      notifyUser(sender_id, 'Friend Request Accepted', `${label} accepted your friend request 🎉`).catch(() => {});
    }

    res.json({ ok: true });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status((err as any).statusCode ?? 500).json({ error: msg });
  }
});

// DELETE /friends/:friendId
friendsRouter.delete('/:friendId', async (req: Request, res: Response) => {
  try {
    await removeFriend(req.user!.id, req.params['friendId']!);
    res.json({ ok: true });
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
```

- [ ] **Step 2: Commit**

```bash
git add stepup-api/src/modules/friends/friends.router.ts
git commit -m "feat: add friends REST router"
```

---

## Task 5: Wire friends router into app.ts + add username to profile schema

**Files:**
- Modify: `stepup-api/src/app.ts`
- Modify: `stepup-api/src/modules/auth/auth.router.ts`

- [ ] **Step 1: Add friendsRouter import and mount in app.ts**

In `stepup-api/src/app.ts`, add the import after the socialRouter import line:

```typescript
import { friendsRouter } from './modules/friends/friends.router';
```

Then add the route mount after `app.use('/social', socialRouter);`:

```typescript
app.use('/friends', friendsRouter);
```

- [ ] **Step 2: Add username field to updateProfileSchema in auth.router.ts**

In `stepup-api/src/modules/auth/auth.router.ts`, find `updateProfileSchema` and add this field:

```typescript
username: z.string().regex(/^[a-z0-9_]{3,20}$/).optional().nullable(),
```

- [ ] **Step 3: Verify TypeScript compiles**

```bash
cd stepup-api && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 4: Commit**

```bash
git add stepup-api/src/app.ts stepup-api/src/modules/auth/auth.router.ts
git commit -m "feat: mount friends router, add username to profile schema"
```

---

## Task 6: Leaderboard friends filter + challenge invite endpoint

**Files:**
- Modify: `stepup-api/src/modules/challenges/leaderboard.service.ts`
- Modify: `stepup-api/src/modules/challenges/challenges.router.ts`

- [ ] **Step 1: Add optional friendIds parameter to getLeaderboard**

In `stepup-api/src/modules/challenges/leaderboard.service.ts`, change the function signature from:

```typescript
export async function getLeaderboard(
  challengeId: string,
  requestingUserId: string,
```

to:

```typescript
export async function getLeaderboard(
  challengeId: string,
  requestingUserId: string,
  friendIds?: string[],
```

Then immediately after `const allParticipants = participants ?? [];`, add:

```typescript
  // Filter to friends + self when requested
  const filteredParticipants = friendIds
    ? allParticipants.filter((p: any) => p.user_id === requestingUserId || friendIds.includes(p.user_id))
    : allParticipants;
```

Replace the rest of the function to use `filteredParticipants` instead of `allParticipants`:

Change `const total = allParticipants.length;` to:
```typescript
  const total = filteredParticipants.length;
  if (total === 0) {
    return { your_rank: null, total: 0, updated_at: new Date().toISOString(), participants: [] };
  }
  const userIds = filteredParticipants.map((p: any) => p.user_id as string);
```

And change the `.map` that builds `entries` from `allParticipants` to `filteredParticipants`.

- [ ] **Step 2: Update leaderboard route to pass friends filter**

In `stepup-api/src/modules/challenges/challenges.router.ts`, find the leaderboard GET handler and replace it:

```typescript
challengesRouter.get('/:id/leaderboard', async (req: Request, res: Response) => {
  try {
    let friendIds: string[] | undefined;
    if (req.query['filter'] === 'friends') {
      const { getFriendIds } = await import('../friends/friends.service');
      friendIds = await getFriendIds(req.user!.id);
    }
    const data = await getLeaderboard(req.params['id'] as string, req.user!.id, friendIds);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});
```

- [ ] **Step 3: Add challenge invite endpoint**

In `stepup-api/src/modules/challenges/challenges.router.ts`, add this after the `/:id/join` route. First add the import at the top of the file:

```typescript
import { notifyUser } from '../notifications/notifications.service';
```

Then add the endpoint:

```typescript
// POST /challenges/:id/invite  body: { friend_ids: string[] }
challengesRouter.post('/:id/invite', async (req: Request, res: Response) => {
  try {
    const { friend_ids } = req.body as { friend_ids?: string[] };
    if (!Array.isArray(friend_ids) || friend_ids.length === 0) {
      return res.status(400).json({ error: 'friend_ids required' });
    }
    const db = getSupabase();
    const [{ data: challenge }, { data: sender }] = await Promise.all([
      db.from('challenges').select('title').eq('id', req.params['id']!).maybeSingle(),
      db.from('users').select('name, username').eq('id', req.user!.id).maybeSingle(),
    ]);
    const label = sender?.username ? `@${sender.username}` : (sender?.name ?? 'Someone');
    const title = challenge?.title ?? 'a challenge';
    await Promise.all(
      friend_ids.map(fid =>
        notifyUser(fid, 'Challenge Invite', `${label} invited you to join "${title}" 🏆`).catch(() => {})
      )
    );
    res.json({ ok: true, invited: friend_ids.length });
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
```

- [ ] **Step 4: Verify TypeScript compiles**

```bash
cd stepup-api && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 5: Commit**

```bash
git add stepup-api/src/modules/challenges/leaderboard.service.ts stepup-api/src/modules/challenges/challenges.router.ts
git commit -m "feat: friends leaderboard filter + challenge invite endpoint"
```

---

## Task 7: Flutter models

**Files:**
- Create: `stepup/lib/features/friends/models/friend.dart`
- Create: `stepup/lib/features/friends/models/friend_request.dart`
- Create: `stepup/lib/features/friends/models/user_search_result.dart`

- [ ] **Step 1: Create friend.dart**

```dart
// stepup/lib/features/friends/models/friend.dart
class Friend {
  final String id;
  final String name;
  final String? username;
  final String? avatarUrl;
  final int xp;
  final String leagueSlug;
  final int streakDays;

  const Friend({
    required this.id,
    required this.name,
    this.username,
    this.avatarUrl,
    required this.xp,
    required this.leagueSlug,
    required this.streakDays,
  });

  factory Friend.fromJson(Map<String, dynamic> j) => Friend(
        id: j['id'] as String,
        name: j['name'] as String,
        username: j['username'] as String?,
        avatarUrl: j['avatar_url'] as String?,
        xp: (j['xp'] as num).toInt(),
        leagueSlug: j['league_slug'] as String? ?? 'bronze',
        streakDays: (j['streak_days'] as num?)?.toInt() ?? 0,
      );
}
```

- [ ] **Step 2: Create friend_request.dart**

```dart
// stepup/lib/features/friends/models/friend_request.dart
class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String? senderUsername;
  final String? senderAvatar;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    this.senderUsername,
    this.senderAvatar,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> j) => FriendRequest(
        id: j['id'] as String,
        senderId: j['sender_id'] as String,
        senderName: j['sender_name'] as String,
        senderUsername: j['sender_username'] as String?,
        senderAvatar: j['sender_avatar'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
      );
}
```

- [ ] **Step 3: Create user_search_result.dart**

```dart
// stepup/lib/features/friends/models/user_search_result.dart
import 'friend.dart';

enum FriendshipStatus { none, pendingSent, pendingReceived, friends }

class UserSearchResult extends Friend {
  final FriendshipStatus friendshipStatus;
  final String? requestId;

  const UserSearchResult({
    required super.id,
    required super.name,
    super.username,
    super.avatarUrl,
    required super.xp,
    required super.leagueSlug,
    required super.streakDays,
    required this.friendshipStatus,
    this.requestId,
  });

  factory UserSearchResult.fromJson(Map<String, dynamic> j) {
    final statusStr = j['friendship_status'] as String? ?? 'none';
    final status = switch (statusStr) {
      'pending_sent' => FriendshipStatus.pendingSent,
      'pending_received' => FriendshipStatus.pendingReceived,
      'friends' => FriendshipStatus.friends,
      _ => FriendshipStatus.none,
    };
    return UserSearchResult(
      id: j['id'] as String,
      name: j['name'] as String,
      username: j['username'] as String?,
      avatarUrl: j['avatar_url'] as String?,
      xp: (j['xp'] as num).toInt(),
      leagueSlug: j['league_slug'] as String? ?? 'bronze',
      streakDays: (j['streak_days'] as num?)?.toInt() ?? 0,
      friendshipStatus: status,
      requestId: j['request_id'] as String?,
    );
  }
}
```

- [ ] **Step 4: Commit**

```bash
git add stepup/lib/features/friends/models/
git commit -m "feat: add Friend, FriendRequest, UserSearchResult models"
```

---

## Task 8: Flutter providers

**Files:**
- Create: `stepup/lib/features/friends/providers/friends_provider.dart`
- Modify: `stepup/lib/features/challenges/providers/challenges_provider.dart`

- [ ] **Step 1: Create friends_provider.dart**

```dart
// stepup/lib/features/friends/providers/friends_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/challenge.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/user_search_result.dart';

final friendsListProvider = FutureProvider<List<Friend>>((ref) async {
  final data = await ApiClient.instance.get('/friends') as List;
  return data.map((j) => Friend.fromJson(j as Map<String, dynamic>)).toList();
});

final friendRequestsProvider = FutureProvider<List<FriendRequest>>((ref) async {
  final data = await ApiClient.instance.get('/friends/requests') as List;
  return data.map((j) => FriendRequest.fromJson(j as Map<String, dynamic>)).toList();
});

final friendSearchProvider = FutureProvider.family<List<UserSearchResult>, String>((ref, query) async {
  if (query.length < 2) return [];
  final data = await ApiClient.instance.get('/friends/search', {'q': query}) as List;
  return data.map((j) => UserSearchResult.fromJson(j as Map<String, dynamic>)).toList();
});

final challengeFriendsLeaderboardProvider = FutureProvider.family<ChallengeLeaderboard, String>((ref, challengeId) async {
  final data = await ApiClient.instance.get('/challenges/$challengeId/leaderboard', {'filter': 'friends'}) as Map<String, dynamic>;
  return ChallengeLeaderboard.fromJson(data);
});
```

- [ ] **Step 2: Commit**

```bash
git add stepup/lib/features/friends/providers/friends_provider.dart
git commit -m "feat: add friends Riverpod providers"
```

---

## Task 9: Username field in ProfileEditScreen

**Files:**
- Modify: `stepup/lib/features/profile/screens/profile_edit_screen.dart`

- [ ] **Step 1: Add username state to `_ProfileEditFormState`**

Find the controller declarations block (around line 47–51) and add after `_weightCtrl`:

```dart
  late final TextEditingController _usernameCtrl;
  Timer? _usernameDebounce;
  // idle | checking | available | taken | invalid
  String _usernameStatus = 'idle';
  String? _usernameInitial;
```

Add `import 'dart:async';` at the top of the file if not already present.

- [ ] **Step 2: Initialize and dispose the controller**

In `initState` (around line 86), after `_weightCtrl = TextEditingController(...)`:

```dart
    _usernameInitial = p['username'] as String? ?? '';
    _usernameCtrl = TextEditingController(text: _usernameInitial ?? '');
    _usernameCtrl.addListener(_onUsernameChanged);
```

In `dispose` (around line 115), after `_weightCtrl.dispose()`:

```dart
    _usernameCtrl.removeListener(_onUsernameChanged);
    _usernameCtrl.dispose();
    _usernameDebounce?.cancel();
```

- [ ] **Step 3: Add the debounced validation method**

Add this method inside `_ProfileEditFormState`, after `dispose`:

```dart
  void _onUsernameChanged() {
    final raw = _usernameCtrl.text;
    // Auto-lowercase as user types
    final lower = raw.toLowerCase();
    if (raw != lower) {
      _usernameCtrl.value = _usernameCtrl.value.copyWith(
        text: lower,
        selection: TextSelection.collapsed(offset: lower.length),
      );
      return;
    }
    // If empty or unchanged from saved value, reset to idle
    if (lower.isEmpty || lower == _usernameInitial) {
      _usernameDebounce?.cancel();
      setState(() => _usernameStatus = 'idle');
      return;
    }
    // Instant format validation
    final validFormat = RegExp(r'^[a-z0-9_]{3,20}$').hasMatch(lower);
    if (!validFormat) {
      _usernameDebounce?.cancel();
      setState(() => _usernameStatus = 'invalid');
      return;
    }
    setState(() => _usernameStatus = 'checking');
    _usernameDebounce?.cancel();
    _usernameDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final result = await ApiClient.instance.get('/friends/check-username', {'q': lower}) as Map<String, dynamic>;
        if (!mounted) return;
        setState(() => _usernameStatus = (result['available'] as bool) ? 'available' : 'taken');
      } catch (_) {
        if (mounted) setState(() => _usernameStatus = 'idle');
      }
    });
  }
```

- [ ] **Step 4: Block save when username is invalid**

In `_save()`, find the body map build and add the username field:

```dart
        if (_usernameCtrl.text.trim().isNotEmpty)
          'username': _usernameCtrl.text.trim(),
```

At the top of `_save()`, add the guard:

```dart
    if (_usernameStatus == 'taken' || _usernameStatus == 'invalid') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix your username before saving')),
      );
      return;
    }
```

- [ ] **Step 5: Add the username field to the form UI**

In the build method, find where `_nameCtrl` field is rendered. Add the username field immediately after the name field. Look for the pattern `AppTextField` or `TextFormField` for name and add:

```dart
const SizedBox(height: 12),
_UsernameField(ctrl: _usernameCtrl, status: _usernameStatus),
```

- [ ] **Step 6: Add `_UsernameField` widget at the bottom of the file**

```dart
class _UsernameField extends StatelessWidget {
  final TextEditingController ctrl;
  final String status;
  const _UsernameField({required this.ctrl, required this.status});

  @override
  Widget build(BuildContext context) {
    Color borderColor = AppTheme.border;
    Widget? trailing;

    switch (status) {
      case 'checking':
        trailing = const SizedBox(
          width: 14, height: 14,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.voltLime),
        );
      case 'available':
        borderColor = AppTheme.voltLime;
        trailing = const Icon(Icons.check_circle_rounded, color: AppTheme.voltLime, size: 18);
      case 'taken':
        borderColor = Color(0xFFFF4D4D);
        trailing = const Icon(Icons.cancel_rounded, color: Color(0xFFFF4D4D), size: 18);
      case 'invalid':
        borderColor = Color(0xFFFF4D4D);
      default:
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('USERNAME', style: AppTheme.label(10, color: AppTheme.ink3)
            .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(children: [
            Padding(
              padding: const EdgeInsets.only(left: 14),
              child: Text('@', style: AppTheme.label(14, color: AppTheme.ink2)),
            ),
            Expanded(
              child: TextField(
                controller: ctrl,
                style: AppTheme.label(14, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'your_username',
                  hintStyle: AppTheme.label(14, color: AppTheme.ink3),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                  suffixIcon: trailing != null ? Padding(padding: const EdgeInsets.only(right: 12), child: trailing) : null,
                  suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ),
            ),
          ]),
        ),
        if (status == 'invalid')
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text('3–20 chars · letters, numbers, underscores only',
                style: AppTheme.label(11, color: Color(0xFFFF4D4D))),
          ),
        if (status == 'taken')
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text('Username taken — try adding numbers or underscores',
                style: AppTheme.label(11, color: Color(0xFFFF4D4D))),
          ),
        if (status == 'available')
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 2),
            child: Text('Username available',
                style: AppTheme.label(11, color: AppTheme.voltLime)),
          ),
      ],
    );
  }
}
```

- [ ] **Step 7: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/features/profile/screens/profile_edit_screen.dart
```

Expected: no errors.

- [ ] **Step 8: Commit**

```bash
git add stepup/lib/features/profile/screens/profile_edit_screen.dart
git commit -m "feat: add username field with debounced validation to profile edit"
```

---

## Task 10: Friends Hub Screen

**Files:**
- Create: `stepup/lib/features/friends/screens/friends_hub_screen.dart`

- [ ] **Step 1: Create the full screen file**

```dart
// stepup/lib/features/friends/screens/friends_hub_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../models/friend.dart';
import '../models/friend_request.dart';
import '../models/user_search_result.dart';
import '../providers/friends_provider.dart';

class FriendsHubScreen extends ConsumerStatefulWidget {
  const FriendsHubScreen({super.key});

  @override
  ConsumerState<FriendsHubScreen> createState() => _FriendsHubScreenState();
}

class _FriendsHubScreenState extends ConsumerState<FriendsHubScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _searchCtrl.addListener(() {
      final q = _searchCtrl.text.trim();
      if (q != _query) setState(() => _query = q);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    final pendingCount = requestsAsync.whenOrNull(data: (list) => list.length) ?? 0;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: Column(children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(children: [
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Text('Friends', style: AppTheme.bigNum(20)),
            ]),
          ),
          const SizedBox(height: 12),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _query.isNotEmpty ? AppTheme.voltLime : AppTheme.border),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: AppTheme.label(14, color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search @username...',
                  hintStyle: AppTheme.label(14, color: AppTheme.ink3),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.ink2, size: 20),
                  suffixIcon: _query.isNotEmpty
                      ? GestureDetector(
                          onTap: () => _searchCtrl.clear(),
                          child: const Icon(Icons.close_rounded, color: AppTheme.ink2, size: 18),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Tab bar (hidden while searching)
          if (_query.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 36,
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TabBar(
                  controller: _tabs,
                  labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                  unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
                  labelColor: Colors.black,
                  unselectedLabelColor: AppTheme.ink2,
                  indicator: BoxDecoration(
                    color: AppTheme.voltLime,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  tabs: [
                    const Tab(text: 'My Friends'),
                    Tab(
                      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Text('Requests'),
                        if (pendingCount > 0) ...[
                          const SizedBox(width: 5),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF4D4D),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text('$pendingCount',
                                style: GoogleFonts.inter(
                                    fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ]),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 4),

          // Content
          Expanded(
            child: _query.isNotEmpty
                ? _SearchResults(query: _query, onRequestSent: () {
                    ref.invalidate(friendsListProvider);
                    ref.invalidate(friendRequestsProvider);
                  })
                : TabBarView(
                    controller: _tabs,
                    children: [
                      _FriendsTab(onRemove: () => ref.invalidate(friendsListProvider)),
                      _RequestsTab(onAction: () {
                        ref.invalidate(friendsListProvider);
                        ref.invalidate(friendRequestsProvider);
                      }),
                    ],
                  ),
          ),
        ]),
      ),
    );
  }
}

// ── Search Results ────────────────────────────────────────────────────────

class _SearchResults extends ConsumerWidget {
  final String query;
  final VoidCallback onRequestSent;
  const _SearchResults({required this.query, required this.onRequestSent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(friendSearchProvider(query));
    return resultsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => _SkeletonRow(),
      ),
      error: (_, __) => _EmptyState(text: 'Could not search right now'),
      data: (results) {
        if (results.isEmpty) {
          return _EmptyState(text: 'No results for @$query');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, i) => _SearchResultRow(
            result: results[i],
            onAction: () {
              ref.invalidate(friendSearchProvider(query));
              onRequestSent();
            },
          ),
        );
      },
    );
  }
}

class _SearchResultRow extends StatefulWidget {
  final UserSearchResult result;
  final VoidCallback onAction;
  const _SearchResultRow({required this.result, required this.onAction});

  @override
  State<_SearchResultRow> createState() => _SearchResultRowState();
}

class _SearchResultRowState extends State<_SearchResultRow> {
  bool _loading = false;

  Future<void> _sendRequest() async {
    setState(() => _loading = true);
    try {
      await ApiClient.instance.post('/friends/requests', {'receiver_id': widget.result.id});
      widget.onAction();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send request')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.result;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        _Avatar(avatarUrl: r.avatarUrl, name: r.name, radius: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(r.name, style: AppTheme.label(14, color: Colors.white)
                .copyWith(fontWeight: FontWeight.w600)),
            if (r.username != null)
              Text('@${r.username}', style: AppTheme.label(11, color: AppTheme.ink2)),
          ]),
        ),
        _leagueBadge(r.leagueSlug),
        const SizedBox(width: 10),
        _StatusButton(status: r.friendshipStatus, loading: _loading, onAdd: _sendRequest),
      ]),
    );
  }
}

class _StatusButton extends StatelessWidget {
  final FriendshipStatus status;
  final bool loading;
  final VoidCallback onAdd;
  const _StatusButton({required this.status, required this.loading, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const SizedBox(width: 20, height: 20,
          child: CircularProgressIndicator(strokeWidth: 1.5, color: AppTheme.voltLime));
    }
    switch (status) {
      case FriendshipStatus.none:
        return GestureDetector(
          onTap: onAdd,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppTheme.voltLime),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('+ Add', style: AppTheme.label(12, color: AppTheme.voltLime)
                .copyWith(fontWeight: FontWeight.w700)),
          ),
        );
      case FriendshipStatus.pendingSent:
        return Text('Pending', style: AppTheme.label(12, color: AppTheme.ink2));
      case FriendshipStatus.pendingReceived:
        return Text('Requested you', style: AppTheme.label(12, color: AppTheme.amber));
      case FriendshipStatus.friends:
        return const Icon(Icons.check_rounded, color: AppTheme.voltLime, size: 18);
    }
  }
}

// ── My Friends Tab ─────────────────────────────────────────────────────────

class _FriendsTab extends ConsumerWidget {
  final VoidCallback onRemove;
  const _FriendsTab({required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);
    return friendsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 5,
        itemBuilder: (_, __) => _SkeletonRow(),
      ),
      error: (_, __) => _EmptyState(text: 'Could not load friends'),
      data: (friends) {
        if (friends.isEmpty) {
          return _EmptyState(
            text: 'No friends yet',
            subtitle: 'Search by @username above to add people',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: friends.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, i) => _FriendRow(friend: friends[i], onRemove: () async {
            try {
              await ApiClient.instance.delete('/friends/${friends[i].id}');
              ref.invalidate(friendsListProvider);
              onRemove();
            } catch (_) {}
          }),
        );
      },
    );
  }
}

class _FriendRow extends StatelessWidget {
  final Friend friend;
  final VoidCallback onRemove;
  const _FriendRow({required this.friend, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(friend.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF4D4D).withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Text('Remove', style: TextStyle(color: Color(0xFFFF4D4D), fontWeight: FontWeight.w700)),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: AppTheme.surface,
            title: Text('Remove ${friend.name}?',
                style: AppTheme.label(16, color: Colors.white).copyWith(fontWeight: FontWeight.w700)),
            content: Text('They won\'t be notified.',
                style: AppTheme.label(13, color: AppTheme.ink2)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false),
                  child: Text('Cancel', style: AppTheme.label(13, color: AppTheme.ink2))),
              TextButton(onPressed: () => Navigator.pop(context, true),
                  child: Text('Remove', style: AppTheme.label(13, color: Color(0xFFFF4D4D)))),
            ],
          ),
        ) ?? false;
      },
      onDismissed: (_) => onRemove(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
        child: Row(children: [
          _Avatar(avatarUrl: friend.avatarUrl, name: friend.name, radius: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(friend.name, style: AppTheme.label(14, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600)),
              if (friend.username != null)
                Text('@${friend.username}', style: AppTheme.label(11, color: AppTheme.ink2)),
            ]),
          ),
          if (friend.streakDays > 0)
            Row(children: [
              const Text('🔥', style: TextStyle(fontSize: 12)),
              const SizedBox(width: 2),
              Text('${friend.streakDays}', style: AppTheme.label(11, color: Colors.white)),
              const SizedBox(width: 8),
            ]),
          _leagueBadge(friend.leagueSlug),
        ]),
      ),
    );
  }
}

// ── Requests Tab ───────────────────────────────────────────────────────────

class _RequestsTab extends ConsumerWidget {
  final VoidCallback onAction;
  const _RequestsTab({required this.onAction});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(friendRequestsProvider);
    return requestsAsync.when(
      loading: () => ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        itemBuilder: (_, __) => _SkeletonRow(),
      ),
      error: (_, __) => _EmptyState(text: 'Could not load requests'),
      data: (requests) {
        if (requests.isEmpty) {
          return _EmptyState(text: 'You\'re all caught up', subtitle: '');
        }
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: requests.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (ctx, i) => _RequestRow(
            request: requests[i],
            onAction: (action) async {
              try {
                await ApiClient.instance.patch('/friends/requests/${requests[i].id}', {'action': action});
                if (action == 'accept') {
                  HapticFeedback.mediumImpact();
                }
                ref.invalidate(friendRequestsProvider);
                onAction();
              } catch (_) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Action failed')));
                }
              }
            },
          ),
        );
      },
    );
  }
}

class _RequestRow extends StatelessWidget {
  final FriendRequest request;
  final void Function(String action) onAction;
  const _RequestRow({required this.request, required this.onAction});

  @override
  Widget build(BuildContext context) {
    final timeAgo = _timeAgo(request.createdAt);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(children: [
        _Avatar(avatarUrl: request.senderAvatar, name: request.senderName, radius: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(request.senderName, style: AppTheme.label(14, color: Colors.white)
                .copyWith(fontWeight: FontWeight.w600)),
            Text(
              request.senderUsername != null ? '@${request.senderUsername} · $timeAgo' : timeAgo,
              style: AppTheme.label(11, color: AppTheme.ink2),
            ),
          ]),
        ),
        GestureDetector(
          onTap: () => onAction('accept'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: AppTheme.voltLime,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('Accept', style: AppTheme.label(12, color: Colors.black)
                .copyWith(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => onAction('decline'),
          child: Text('Decline', style: AppTheme.label(12, color: AppTheme.ink2)),
        ),
      ]),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────

class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String name;
  final double radius;
  const _Avatar({this.avatarUrl, required this.name, required this.radius});

  @override
  Widget build(BuildContext context) {
    if (avatarUrl != null) {
      return CircleAvatar(radius: radius, backgroundImage: NetworkImage(avatarUrl!));
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppTheme.surface2,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: GoogleFonts.inter(fontSize: radius * 0.7, fontWeight: FontWeight.w700, color: AppTheme.voltLime),
      ),
    );
  }
}

Widget _leagueBadge(String slug) {
  final color = switch (slug) {
    'gold' => const Color(0xFFF5A623),
    'silver' => const Color(0xFF9E9E9E),
    'platinum' => const Color(0xFF00BCD4),
    _ => AppTheme.ink3,
  };
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.15),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: color.withValues(alpha: 0.4)),
    ),
    child: Text(
      slug[0].toUpperCase() + slug.substring(1),
      style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w700, color: color),
    ),
  );
}

class _SkeletonRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 58,
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.border),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  final String text;
  final String? subtitle;
  const _EmptyState({required this.text, this.subtitle});

  @override
  Widget build(BuildContext context) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(text, style: AppTheme.label(14, color: AppTheme.ink2)),
          if (subtitle != null && subtitle!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: AppTheme.label(12, color: AppTheme.ink3)),
          ],
        ]),
      );
}

String _timeAgo(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  return '${diff.inDays}d ago';
}
```

- [ ] **Step 2: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/features/friends/screens/friends_hub_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add stepup/lib/features/friends/screens/friends_hub_screen.dart
git commit -m "feat: add FriendsHubScreen with search, requests, and friends list"
```

---

## Task 11: Wire /friends route

**Files:**
- Modify: `stepup/lib/core/router.dart`

- [ ] **Step 1: Add import and route**

Add import at the top of `router.dart`:

```dart
import '../features/friends/screens/friends_hub_screen.dart';
```

Add route inside the authenticated routes block, after the `/rivals` routes:

```dart
GoRoute(path: '/friends', builder: (_, __) => const FriendsHubScreen()),
```

- [ ] **Step 2: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/core/router.dart
```

- [ ] **Step 3: Commit**

```bash
git add stepup/lib/core/router.dart
git commit -m "feat: add /friends route"
```

---

## Task 12: Friends Community Banner widget

**Files:**
- Create: `stepup/lib/features/friends/widgets/friends_community_banner.dart`
- Modify: `stepup/lib/features/community/screens/community_screen.dart`

- [ ] **Step 1: Create the banner widget**

```dart
// stepup/lib/features/friends/widgets/friends_community_banner.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme.dart';
import '../providers/friends_provider.dart';

class FriendsCommunityBanner extends ConsumerWidget {
  const FriendsCommunityBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsListProvider);
    final requestsAsync = ref.watch(friendRequestsProvider);
    final pendingCount = requestsAsync.whenOrNull(data: (list) => list.length) ?? 0;

    return GestureDetector(
      onTap: () => context.push('/friends'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.voltLime.withValues(alpha: 0.25),
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text('FRIENDS', style: GoogleFonts.inter(
                    fontSize: 10, fontWeight: FontWeight.w700,
                    color: AppTheme.ink2, letterSpacing: 1.2)),
                if (pendingCount > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppTheme.amber.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                    ),
                    child: Text('$pendingCount request${pendingCount > 1 ? 's' : ''}',
                        style: GoogleFonts.inter(
                            fontSize: 9, fontWeight: FontWeight.w700, color: AppTheme.amber)),
                  ),
                ],
              ]),
              const SizedBox(height: 8),
              friendsAsync.when(
                loading: () => const SizedBox(height: 28),
                error: (_, __) => Text('Add friends →',
                    style: AppTheme.label(12, color: AppTheme.voltLime)),
                data: (friends) {
                  if (friends.isEmpty) {
                    return Text('Find friends →',
                        style: AppTheme.label(12, color: AppTheme.voltLime));
                  }
                  return _AvatarRow(friends: friends.take(5).toList());
                },
              ),
            ]),
          ),
          const SizedBox(width: 8),
          Text('See All →', style: AppTheme.label(12, color: AppTheme.voltLime)),
        ]),
      ),
    );
  }
}

class _AvatarRow extends StatelessWidget {
  final List<dynamic> friends;
  const _AvatarRow({required this.friends});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 28,
      child: Stack(
        children: List.generate(friends.length + 1, (i) {
          if (i == friends.length) {
            return Positioned(
              left: i * 18.0,
              child: GestureDetector(
                onTap: () => context.push('/friends'),
                child: Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: AppTheme.surface2,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.bg, width: 1.5),
                  ),
                  child: const Icon(Icons.add_rounded, size: 14, color: AppTheme.voltLime),
                ),
              ),
            );
          }
          final f = friends[i];
          final url = f.avatarUrl as String?;
          final name = f.name as String;
          return Positioned(
            left: i * 18.0,
            child: Container(
              width: 28, height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppTheme.bg, width: 1.5),
              ),
              child: CircleAvatar(
                radius: 14,
                backgroundImage: url != null ? NetworkImage(url) : null,
                backgroundColor: AppTheme.surface2,
                child: url == null
                    ? Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700,
                            color: AppTheme.voltLime))
                    : null,
              ),
            ),
          );
        }),
      ),
    );
  }
}
```

- [ ] **Step 2: Insert banner into CommunityScreen**

In `stepup/lib/features/community/screens/community_screen.dart`, add the import:

```dart
import '../../friends/widgets/friends_community_banner.dart';
```

Then find the `Column(children: [` block inside the `SafeArea`. After the Stories row `SizedBox` and before the `Expanded` feed section, insert:

```dart
const FriendsCommunityBanner(),
```

- [ ] **Step 3: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/features/community/ lib/features/friends/widgets/
```

- [ ] **Step 4: Commit**

```bash
git add stepup/lib/features/friends/widgets/friends_community_banner.dart stepup/lib/features/community/screens/community_screen.dart
git commit -m "feat: add FriendsCommunityBanner to community screen"
```

---

## Task 13: Home Friends Pulse — Manage link + Add slot

**Files:**
- Modify: `stepup/lib/features/home/widgets/friends_pulse_section.dart`

- [ ] **Step 1: Add imports**

Add to the imports at the top of `friends_pulse_section.dart`:

```dart
import 'package:go_router/go_router.dart';
```

- [ ] **Step 2: Replace the header row**

Find the `Row` in the header that contains `'FRIENDS PULSE'` text and the standings text. Replace the entire `Padding` containing the header `Row` with:

```dart
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Container(
                width: 6, height: 6,
                decoration: const BoxDecoration(color: AppTheme.voltLime, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text('FRIENDS PULSE', style: GoogleFonts.inter(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: AppTheme.ink2, letterSpacing: 1.2)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.push('/friends'),
                child: Text('Manage →',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.voltLime)),
              ),
            ],
          ),
        ),
```

Note: the `build` method needs `BuildContext context` — verify `ConsumerWidget` gives it via `build(BuildContext context, WidgetRef ref)`.

- [ ] **Step 3: Replace `_EmptyFeed` with a friends-aware empty state**

Find where `_EmptyFeed()` is returned (in the `error:` and empty check). Replace the empty state to navigate to friends:

```dart
          error: (_, _) => _NoFriendsPrompt(),
```

And update the empty activities check:
```dart
          data: (activities) => activities.isEmpty
              ? _NoFriendsPrompt()
              : SizedBox( /* existing code */ ),
```

Add this widget at the bottom of the file:

```dart
class _NoFriendsPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/friends'),
      child: Container(
        height: 70,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTheme.border),
        ),
        child: Center(
          child: Text(
            '👥 Add friends to see their pulse here →',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.ink2),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/features/home/widgets/friends_pulse_section.dart
```

- [ ] **Step 5: Commit**

```bash
git add stepup/lib/features/home/widgets/friends_pulse_section.dart
git commit -m "feat: update FriendsPulseSection with Manage link and empty state CTA"
```

---

## Task 14: Challenge Detail — Friends leaderboard tab

**Files:**
- Modify: `stepup/lib/features/challenges/screens/challenge_detail_screen.dart`
- Modify: `stepup/lib/features/challenges/providers/challenges_provider.dart`

- [ ] **Step 1: No changes needed to challenges_provider.dart**

`challengeFriendsLeaderboardProvider` is imported directly from `friends_provider.dart` in the next step.

- [ ] **Step 2: Replace `_LiveLeaderboard` call with a tabbed widget**

In `challenge_detail_screen.dart`, find the leaderboard section inside `_AfterState`:

```dart
                leaderboardAsync.when(
                  loading: () => const SizedBox(...),
                  error: (e2, st) => const SizedBox.shrink(),
                  data: (lb) => _LiveLeaderboard(lb: lb),
                ),
```

Replace it with:

```dart
                _LeaderboardSection(challengeId: challengeId),
```

- [ ] **Step 3: Add `_LeaderboardSection` widget at the bottom of the file**

```dart
class _LeaderboardSection extends ConsumerStatefulWidget {
  final String challengeId;
  const _LeaderboardSection({required this.challengeId});

  @override
  ConsumerState<_LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends ConsumerState<_LeaderboardSection> {
  bool _friendsFilter = false;

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsListProvider);
    final hasFriends = friendsAsync.whenOrNull(data: (list) => list.isNotEmpty) ?? false;

    final leaderboardAsync = _friendsFilter
        ? ref.watch(challengeFriendsLeaderboardProvider(widget.challengeId))
        : ref.watch(challengeLeaderboardProvider(widget.challengeId));

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (hasFriends)
        Container(
          height: 32,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _friendsFilter = false),
              child: Container(
                decoration: BoxDecoration(
                  color: !_friendsFilter ? AppTheme.voltLime : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text('Everyone', style: AppTheme.label(11,
                      color: !_friendsFilter ? Colors.black : AppTheme.ink2)
                      .copyWith(fontWeight: !_friendsFilter ? FontWeight.w700 : FontWeight.normal)),
                ),
              ),
            )),
            Expanded(child: GestureDetector(
              onTap: () => setState(() => _friendsFilter = true),
              child: Container(
                decoration: BoxDecoration(
                  color: _friendsFilter ? AppTheme.voltLime : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Center(
                  child: Text('Friends 👥', style: AppTheme.label(11,
                      color: _friendsFilter ? Colors.black : AppTheme.ink2)
                      .copyWith(fontWeight: _friendsFilter ? FontWeight.w700 : FontWeight.normal)),
                ),
              ),
            )),
          ]),
        ),
      const SizedBox(height: 8),
      leaderboardAsync.when(
        loading: () => const SizedBox(
          height: 40,
          child: Center(child: CircularProgressIndicator(color: AppTheme.voltLime, strokeWidth: 1.5)),
        ),
        error: (_, __) => const SizedBox.shrink(),
        data: (lb) {
          if (_friendsFilter && lb.participants.isEmpty) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(children: [
                Text('None of your friends have joined yet',
                    style: AppTheme.label(12, color: AppTheme.ink2)),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => context.push('/challenges/${widget.challengeId}/invite'),
                  child: Text('Invite Friends →',
                      style: AppTheme.label(12, color: AppTheme.voltLime)
                          .copyWith(fontWeight: FontWeight.w700)),
                ),
              ]),
            );
          }
          return _LiveLeaderboard(lb: lb);
        },
      ),
    ]);
  }
}
```

Also add import at the top of challenge_detail_screen.dart (the file already imports `challenges_provider.dart` — just add the friends import):

```dart
import '../../friends/providers/friends_provider.dart' show challengeFriendsLeaderboardProvider, friendsListProvider;
```

- [ ] **Step 4: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/features/challenges/
```

- [ ] **Step 5: Commit**

```bash
git add stepup/lib/features/challenges/screens/challenge_detail_screen.dart stepup/lib/features/challenges/providers/challenges_provider.dart
git commit -m "feat: add Friends leaderboard filter tab to challenge detail"
```

---

## Task 15: Challenge Invite — Friends picker

**Files:**
- Modify: `stepup/lib/features/challenges/screens/invite_friends_screen.dart`

- [ ] **Step 1: Replace the file with the redesigned version**

Read the current file, then replace its `_InviteFriendsScreenState` class. The new version adds Section 1 (friends picker) above the existing Section 2 (share link). Replace the full file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../friends/models/friend.dart';
import '../../friends/providers/friends_provider.dart';

class InviteFriendsScreen extends ConsumerStatefulWidget {
  final String challengeId;
  const InviteFriendsScreen({required this.challengeId, super.key});

  @override
  ConsumerState<InviteFriendsScreen> createState() => _InviteFriendsScreenState();
}

class _InviteFriendsScreenState extends ConsumerState<InviteFriendsScreen> {
  Map<String, dynamic>? _challenge;
  bool _loading = true;
  final Set<String> _selected = {};
  bool _sending = false;
  bool _sent = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiClient.instance.get('/challenges/custom/${widget.challengeId}') as Map<String, dynamic>;
      setState(() { _challenge = data; _loading = false; });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  Future<void> _sendInvites() async {
    if (_selected.isEmpty) return;
    setState(() => _sending = true);
    try {
      await ApiClient.instance.post('/challenges/${widget.challengeId}/invite', {
        'friend_ids': _selected.toList(),
      });
      setState(() { _sent = true; _sending = false; });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) setState(() => _sent = false);
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to send invites')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareLink = 'stepup://join/${widget.challengeId}';
    final friendsAsync = ref.watch(friendsListProvider);

    return Scaffold(
      backgroundColor: AppTheme.bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: AppTheme.voltLime))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Header
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    GestureDetector(
                      onTap: () => context.pop(),
                      child: Text('← Back', style: AppTheme.label(13, color: AppTheme.ink2)),
                    ),
                    Text('2 / 2', style: AppTheme.label(11, color: AppTheme.ink2)),
                  ]),
                  const SizedBox(height: 12),
                  Text('INVITE', style: AppTheme.bigNum(28)),
                  Text('YOUR SQUAD', style: AppTheme.bigNum(28, color: AppTheme.voltLime)),
                  const SizedBox(height: 8),

                  // Challenge card
                  if (_challenge != null)
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.voltLime.withValues(alpha: 0.3)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.emoji_events_rounded, color: AppTheme.voltLime),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(_challenge!['title'] as String? ?? '',
                              style: AppTheme.label(14, color: Colors.white)
                                  .copyWith(fontWeight: FontWeight.w600)),
                          Text('${_challenge!['duration_days']}d · ${((_challenge!['difficulty'] as String?) ?? '').toUpperCase()}',
                              style: AppTheme.label(11)),
                        ])),
                        Text('+${_challenge!['coin_reward']}¢',
                            style: AppTheme.bigNum(16, color: AppTheme.amber)),
                      ]),
                    ),
                  const SizedBox(height: 20),

                  // ─── Section 1: Invite Friends ───────────────────────
                  Text('INVITE FRIENDS', style: AppTheme.label(10, color: AppTheme.ink3)
                      .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),

                  friendsAsync.when(
                    loading: () => const CircularProgressIndicator(color: AppTheme.voltLime, strokeWidth: 1.5),
                    error: (_, __) => Text('Could not load friends', style: AppTheme.label(12, color: AppTheme.ink2)),
                    data: (friends) {
                      if (friends.isEmpty) {
                        return GestureDetector(
                          onTap: () => context.push('/friends'),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: Text('No friends yet — tap to add friends →',
                                style: AppTheme.label(12, color: AppTheme.voltLime)),
                          ),
                        );
                      }
                      return _FriendPickerList(
                        friends: friends,
                        selected: _selected,
                        challengeId: widget.challengeId,
                        onToggle: (id) => setState(() {
                          _selected.contains(id) ? _selected.remove(id) : _selected.add(id);
                        }),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Send invite button
                  if (!friendsAsync.isLoading)
                    GestureDetector(
                      onTap: (_selected.isEmpty || _sending || _sent) ? null : _sendInvites,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: _sent
                              ? AppTheme.voltLime.withValues(alpha: 0.15)
                              : _selected.isEmpty
                                  ? AppTheme.surface
                                  : AppTheme.voltLime,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _sent ? AppTheme.voltLime : _selected.isEmpty ? AppTheme.border : AppTheme.voltLime,
                          ),
                        ),
                        child: Center(
                          child: _sending
                              ? const SizedBox(width: 18, height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : Text(
                                  _sent
                                      ? 'Sent ✓'
                                      : _selected.isEmpty
                                          ? 'Select friends to invite'
                                          : 'Send Invite (${_selected.length})',
                                  style: AppTheme.label(14,
                                      color: _sent
                                          ? AppTheme.voltLime
                                          : _selected.isEmpty
                                              ? AppTheme.ink2
                                              : Colors.black)
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ─── Section 2: Share Link (unchanged fallback) ───────
                  Row(children: [
                    Expanded(child: Divider(color: AppTheme.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text('OR SHARE LINK', style: AppTheme.label(10, color: AppTheme.ink3)
                          .copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                    ),
                    Expanded(child: Divider(color: AppTheme.border)),
                  ]),
                  const SizedBox(height: 12),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(children: [
                      Expanded(
                        child: Text(shareLink, style: AppTheme.label(12),
                            overflow: TextOverflow.ellipsis),
                      ),
                      GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: shareLink));
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Link copied!')));
                        },
                        child: const Icon(Icons.copy_rounded, color: AppTheme.voltLime, size: 20),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  Row(children: [
                    _ShareBtn(label: 'WhatsApp', icon: Icons.chat_rounded, color: const Color(0xFF25D366), onTap: () {}),
                    const SizedBox(width: 10),
                    _ShareBtn(label: 'Telegram', icon: Icons.send_rounded, color: const Color(0xFF2AABEE), onTap: () {}),
                    const SizedBox(width: 10),
                    _ShareBtn(label: 'More', icon: Icons.share_rounded, color: AppTheme.ink2, onTap: () {}),
                  ]),
                  const SizedBox(height: 20),
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        color: AppTheme.amber.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppTheme.amber.withValues(alpha: 0.4)),
                      ),
                      child: Center(
                        child: Text('Done — Go to Home',
                            style: AppTheme.label(14, color: AppTheme.amber)
                                .copyWith(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ]),
              ),
      ),
    );
  }
}

class _FriendPickerList extends ConsumerWidget {
  final List<Friend> friends;
  final Set<String> selected;
  final String challengeId;
  final void Function(String id) onToggle;
  const _FriendPickerList({
    required this.friends, required this.selected,
    required this.challengeId, required this.onToggle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lbAsync = ref.watch(challengeFriendsLeaderboardProvider(challengeId));
    final alreadyIn = lbAsync.whenOrNull(
      data: (lb) => lb.participants.map((p) => p.userId).toSet(),
    ) ?? <String>{};

    return Column(children: friends.map((f) {
      final inChallenge = alreadyIn.contains(f.id);
      final isSelected = selected.contains(f.id);
      return GestureDetector(
        onTap: inChallenge ? null : () => onToggle(f.id),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.voltLime.withValues(alpha: 0.1) : AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.voltLime : AppTheme.border,
            ),
          ),
          child: Row(children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: f.avatarUrl != null ? NetworkImage(f.avatarUrl!) : null,
              backgroundColor: AppTheme.surface2,
              child: f.avatarUrl == null
                  ? Text(f.name.isNotEmpty ? f.name[0].toUpperCase() : '?',
                      style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.voltLime))
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(f.name, style: AppTheme.label(13, color: Colors.white)
                  .copyWith(fontWeight: FontWeight.w600)),
              if (f.username != null)
                Text('@${f.username}', style: AppTheme.label(10, color: AppTheme.ink2)),
            ])),
            if (inChallenge)
              Text('In challenge ✓', style: AppTheme.label(10, color: AppTheme.ink2))
            else
              Container(
                width: 20, height: 20,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? AppTheme.voltLime : Colors.transparent,
                  border: Border.all(
                      color: isSelected ? AppTheme.voltLime : AppTheme.ink2, width: 1.5),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 12, color: Colors.black)
                    : null,
              ),
          ]),
        ),
      );
    }).toList());
  }
}

class _ShareBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _ShareBtn({required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(label, style: AppTheme.label(11, color: Colors.white)),
            ]),
          ),
        ),
      );
}
```

- [ ] **Step 2: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/features/challenges/screens/invite_friends_screen.dart
```

Expected: no errors.

- [ ] **Step 3: Commit**

```bash
git add stepup/lib/features/challenges/screens/invite_friends_screen.dart
git commit -m "feat: redesign InviteFriendsScreen with friends picker + send invite"
```

---

## Task 16: Final build check

- [ ] **Step 1: Run full Flutter analyze**

```bash
cd stepup && flutter analyze lib/
```

Expected: no errors.

- [ ] **Step 2: Verify API compiles**

```bash
cd stepup-api && npx tsc --noEmit
```

Expected: no errors.

- [ ] **Step 3: Build iOS release**

```bash
cd stepup && flutter build ios --release
```

Expected: build succeeds.

- [ ] **Step 4: Install on device**

```bash
xcrun devicectl device install app --device 00008120-001E6C6C0101A01E stepup/build/ios/iphoneos/Runner.app
```

- [ ] **Step 5: Final commit**

```bash
git add -A
git commit -m "feat: complete friends system — username, search, requests, challenge integration"
```
