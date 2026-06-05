# Friends System Design
**Date:** 2026-06-05  
**Status:** Approved

---

## Overview

Add a full friends system to StepUp: unique usernames, friend search, request/accept flow, friends competition in challenges, and surface friends activity on Home and Community screens.

---

## 1. Data Layer

### 1a. Username on users table

```sql
-- Migration: 20260605000017_username.sql
ALTER TABLE users ADD COLUMN username text UNIQUE;
CREATE INDEX idx_users_username ON users(lower(username));
```

Rules:
- 3–20 characters, letters/numbers/underscores only (`^[a-z0-9_]{3,20}$` after lowercasing)
- Unique, case-insensitive (stored lowercase)
- Required before user can send friend requests
- Existing users prompted to set username on next profile visit (non-blocking — no forced modal)

### 1b. friend_requests table

```sql
-- Migration: 20260605000018_friend_requests.sql
CREATE TABLE friend_requests (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status      text NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sender_id, receiver_id),
  CHECK (sender_id <> receiver_id)
);
CREATE INDEX idx_friend_requests_receiver ON friend_requests(receiver_id, status);
CREATE INDEX idx_friend_requests_sender ON friend_requests(sender_id, status);
```

Lifecycle:
- `pending` → sender waiting for response
- `accepted` → row inserted into existing `friendships` table (both directions), request row stays for audit
- `declined` → request row updated to `declined`. Re-request: `POST /friends/requests` checks for a declined row older than 7 days and updates it back to `pending` (upsert); if declined within 7 days, returns 429.

The existing `friendships` table is unchanged — it remains the source of truth for accepted friends.

---

## 2. API Endpoints

All endpoints are authenticated (JWT from Supabase Auth).

### Username

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/users/check-username?q=foo` | Returns `{ available: bool }`. Debounced from client at 500ms. |
| `PATCH` | `/profile` | Existing endpoint — accepts `username` field (already handles partial updates). |

### Friends Management

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/friends` | List accepted friends with name, username, avatar, XP, league, streak. |
| `GET` | `/friends/search?q=username` | Search users by username prefix (min 2 chars). Returns up to 10 results with friendship status (`none`, `pending_sent`, `pending_received`, `friends`). |
| `GET` | `/friends/requests` | Incoming pending requests with sender details. |
| `POST` | `/friends/requests` | Body: `{ receiver_id }`. Send friend request. 409 if already friends or request exists. |
| `PATCH` | `/friends/requests/:id` | Body: `{ action: "accept" \| "decline" }`. Accept inserts into `friendships` (both directions). |
| `DELETE` | `/friends/:friend_id` | Remove friend — deletes both directions from `friendships`. |

### Challenges Integration

| Method | Path | Description |
|--------|------|-------------|
| `GET` | `/challenges/:id/leaderboard` | Existing endpoint, add optional `?filter=friends` — returns only participants who are friends with the caller. |
| `POST` | `/challenges/:id/invite` | Body: `{ friend_ids: string[] }`. Sends in-app notification to each friend with a deep link to the challenge. |

---

## 3. Flutter — New Screens & Widgets

### 3a. Username field in ProfileEditScreen

- New `TextEditingController _usernameCtrl` added to `_ProfileEditFormState`
- Username stored and displayed lowercase; input auto-lowercases as user types
- Debounce 500ms after user stops typing → call `GET /users/check-username`
- Visual states:
  - **Idle** — neutral border, hint text `your_username`
  - **Typing** — border turns to `ink2` (neutral active), no spinner yet
  - **Checking** — slim progress indicator at bottom of field (not a blocking spinner)
  - **Available** — `voltLime` border + trailing "✓" icon
  - **Taken** — `red` border + trailing "✗" icon + suggestion chip below: *"Try @harsha99 or @harsha_fit ?"* — tapping auto-fills the suggestion
  - **Invalid format** — `red` border + inline hint `"3–20 chars, letters/numbers/underscores only"` — shown client-side instantly, no API call
- Save blocked only if username field is non-empty and status is not `available`
- Field is optional — user can save profile without a username; a subtle "Set username to find friends" nudge appears in the Friends Pulse section if username is unset
- Once set and saved, username is shown read-only (greyed field with a "Request change" link — not implemented in v1, just placeholder text)

### 3b. FriendsHubScreen (`/friends`)

New screen at route `/friends`. Clean header with back button, title "Friends", and a pending-request badge on the tab bar.

**Layout — single scroll with sticky search:**
- Search bar is always pinned at top (like Contacts app pattern)
- Below: tab strip — **My Friends** | **Requests (n)**
- No search results overlay; results replace the list content inline

**Search results (while query is active):**
- Skeleton rows while loading (2 shimmer rows — not a full-screen spinner)
- Each result: avatar, display name, `@username`, league badge
- Status button (trailing):
  - `+ Add Friend` (voltLime outlined) → fires POST, button immediately becomes `Pending ✓` (optimistic)
  - `Pending` (greyed, no tap) — request already sent
  - `Friends` (greyed check) — already connected
- "No results for @xyz" if search returns empty — no generic "try searching" filler

**My Friends tab:**
- Sorted by most recently active (last step sync date)
- Each row: avatar (with green dot if stepped today), name, @username, league, 🔥 streak count
- Swipe-to-reveal on each row: "Remove" (destructive red) — confirm dialog before DELETE
- Empty state: avatar illustration placeholder + "Search @username above to add your first friend"

**Requests tab:**
- Each row: avatar, name, @username, time ago ("2h ago")
- Two buttons: **Accept** (voltLime filled) | **Decline** (text button, no border)
- Accept → optimistic remove from list + `FriendsListProvider.invalidate()` + success haptic
- Decline → optimistic remove from list, silent (no confirmation dialog — too much friction)
- Empty state: "You're all caught up"

### 3c. Community screen — Friends section

Insert a `FriendsCommunityBanner` widget at the top of `CommunityScreen`, above the existing feed. Styled as a card consistent with the app's `surface` + `border` aesthetic — not a jarring banner.

```
┌──────────────────────────────────────────────┐
│ FRIENDS                           See All →  │
│ [avatar 🟢][avatar][avatar][+3]  · 2 requests│
└──────────────────────────────────────────────┘
```

- `FRIENDS` label matches the section header style used elsewhere in community
- Avatars stack with overlap (like AvatarGroup in design systems) — max 4 shown + overflow count
- Green dot on avatar = stepped today
- "2 requests" shown as a small amber pill — taps directly to Requests tab at `/friends`
- "See All →" header tap → `/friends` (My Friends tab)
- 0 friends state: replace avatar row with "Add your first friend and see their activity here"
- If username is not set: "Set a @username first →" links to `/profile/edit`

### 3d. Home screen — Friends Pulse

Existing `FriendsPulseSection` widget updated:
- Header row: "FRIENDS PULSE" label left, "Manage →" right (taps `/friends`) — if pending requests exist, "Manage" gets an amber dot badge
- Friends row: existing avatars + a `+` dashed-circle slot at the end → taps to `/friends`
- 0 friends state: collapse the avatar row entirely, show a single tappable row: "👥 Add friends to see their pulse here →"
- Username not set: replace Friends Pulse section with: "Set a @username to start adding friends →"

### 3e. Challenge Detail — Friends leaderboard filter

In `ChallengeDetailScreen`, the leaderboard section gets a filter toggle: **Everyone** | **Friends 👥**.

- Toggle uses the same pill-style selector pattern used elsewhere in the app (see league standings)
- "Friends 👥" calls `GET /challenges/:id/leaderboard?filter=friends`
- "Friends" tab is hidden (not shown as disabled) if user has 0 friends — avoids dead-end state
- If no friends in this challenge but user has friends: empty state with **"Invite Friends →"** button (goes to invite screen)
- Current user row highlighted as before

### 3f. Challenge Invite — Friends picker

`InviteFriendsScreen` redesigned. Two sections, separated by a divider:

**Section 1 — Invite from Friends** (new, appears first)
- Header: "INVITE FRIENDS"
- Each friend row: avatar, name, @username, checkbox (trailing)
- Friends already in the challenge show "In this challenge ✓" label instead of checkbox (greyed, non-selectable)
- "Send Invite (n)" CTA button at bottom — disabled until at least 1 checked; count updates live
- On send: fires `POST /challenges/:id/invite`, button shows "Sent ✓", reverts after 2s
- 0 friends state: "No friends yet — " with link to `/friends`

**Section 2 — Share Link** (existing, kept as fallback)
- Divider + "OR SHARE LINK" section label
- Copy link, WhatsApp, Telegram, More — exactly as before, unchanged

---

## 4. State Management (Riverpod)

New providers in `lib/features/friends/providers/friends_provider.dart`:

```dart
// List of accepted friends
final friendsListProvider = FutureProvider<List<Friend>>(...);

// Incoming pending requests
final friendRequestsProvider = FutureProvider<List<FriendRequest>>(...);

// Search results (family by query string)
final friendSearchProvider = FutureProvider.family<List<UserSearchResult>, String>(...);

// Friends in a specific challenge
final challengeFriendsLeaderboardProvider = FutureProvider.family<ChallengeLeaderboard, String>(...);

// Username availability (family by username string)
final usernameAvailabilityProvider = FutureProvider.family<UsernameAvailability, String>(...);
```

New models in `lib/features/friends/models/`:
- `friend.dart` — id, name, username, avatarUrl, xp, leagueSlug, streak
- `friend_request.dart` — id, senderId, senderName, senderUsername, senderAvatar, createdAt
- `user_search_result.dart` — friend model fields + `friendshipStatus` enum

---

## 5. Notifications

Leverage existing `NotificationService`:

| Trigger | Notification |
|---------|-------------|
| Friend request received | "**@username** sent you a friend request" — deep link to `/friends` (Requests tab) |
| Friend request accepted | "**@username** accepted your friend request 🎉" — deep link to `/friends` |
| Challenge invite | "**@username** invited you to join **Challenge Name** 🏆" — deep link to `/challenges/:id` |

Push sent via existing Supabase edge function + `NotificationService` pattern. No in-app notifications table exists yet — push-only for now.

---

## 6. RLS Policies

Defined in migration `20260605000018_friend_requests.sql`:

```sql
ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

-- Anyone authenticated can search users by username (id, name, username, avatar only)
-- Achieved via a security-definer function get_user_by_username(q text) — not direct table RLS.

-- Sender can insert their own requests
CREATE POLICY fr_insert ON friend_requests FOR INSERT
  WITH CHECK (sender_id = auth.uid());

-- Both sender and receiver can read their own rows
CREATE POLICY fr_select ON friend_requests FOR SELECT
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- Only receiver can update status (accept/decline)
CREATE POLICY fr_update ON friend_requests FOR UPDATE
  USING (receiver_id = auth.uid())
  WITH CHECK (receiver_id = auth.uid());
```

---

## 7. Routing

New routes added to `core/router.dart`:

```dart
GoRoute(path: '/friends', builder: (_, __) => const FriendsHubScreen()),
```

No additional subroutes needed.

---

## 8. Scope Boundaries

**In scope:**
- Username (add, validate, display)
- Friend requests (send, accept, decline)
- Friends list
- Friends search by username
- Challenge leaderboard friends filter
- Challenge in-app invite to friends
- Home Friends Pulse: "Manage" link + Add slot
- Community: friends banner widget

**Out of scope (future):**
- Blocking users
- Friend profile deep-dive screen (just name/avatar card for now)
- Friend activity feed (exists but tied to mock data — not changed here)
- Friends-only challenges (private challenge mode)
- Mutual friends display
