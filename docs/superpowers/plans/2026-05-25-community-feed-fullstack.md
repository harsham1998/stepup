# Community Feed Full-Stack Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Wire up the community feed end-to-end — DB migration for visibility + media URLs, API expansion for new post types and visibility filtering, Flutter model/provider updates, Create Post screen, and home screen integration.

**Architecture:** Supabase Postgres gains two new columns on `community_posts` (`visibility` enum, `media_urls` text[]). The Express API's `getFeed` respects visibility and `createPost` accepts the new fields. Flutter gets an updated model, a `CreatePostNotifier`, a full Create Post screen (Strava Pulse aesthetic), and the community FAB wired through to post submission.

**Tech Stack:** Supabase Postgres (migration via SQL), TypeScript/Express (Railway), Flutter + Riverpod (Dart)

---

## File Map

| File | Action |
|---|---|
| `stepup-api/src/modules/community/community.service.ts` | Modify — expand post types, visibility filter in getFeed, accept visibility + media_urls in createPost |
| `stepup-api/src/modules/community/community.router.ts` | Modify — POST `/community/posts` route (rename from `/flex`), accept visibility + media_urls |
| `stepup/lib/shared/models/community_post.dart` | Modify — add `visibility`, `mediaUrls` fields |
| `stepup/lib/features/community/providers/community_provider.dart` | Modify — add `CreatePostNotifier` + `createPostProvider` |
| `stepup/lib/features/community/screens/create_post_screen.dart` | Create — new screen (Strava Pulse design) |
| `stepup/lib/features/community/screens/community_screen.dart` | Modify — add FAB, navigate to create post, invalidate feed on return |
| `stepup/lib/core/router.dart` | Modify — add `/community/create` route |
| `stepup/lib/features/home/screens/home_screen.dart` | Modify — add "Post" shortcut in community section header |

---

### Task 1: DB Migration — add visibility + media_urls columns

**Files:**
- Create: `stepup-api/migrations/007_community_visibility_media.sql`

- [ ] **Step 1: Write the migration SQL**

```sql
-- stepup-api/migrations/007_community_visibility_media.sql
ALTER TABLE community_posts
  ADD COLUMN IF NOT EXISTS visibility text NOT NULL DEFAULT 'everyone'
    CHECK (visibility IN ('everyone', 'followers', 'friends')),
  ADD COLUMN IF NOT EXISTS media_urls text[] NOT NULL DEFAULT '{}';
```

- [ ] **Step 2: Run it in Supabase SQL editor (or via psql)**

Open the Supabase dashboard → SQL Editor → paste and run the migration. Confirm both columns appear in the `community_posts` table schema.

Expected: no error, columns visible in Table Editor with correct defaults.

- [ ] **Step 3: Verify existing rows have defaults**

```sql
SELECT id, visibility, media_urls FROM community_posts LIMIT 5;
```

Expected: all existing rows show `visibility = 'everyone'`, `media_urls = {}`

- [ ] **Step 4: Commit the SQL file**

```bash
git add stepup-api/migrations/007_community_visibility_media.sql
git commit -m "db: add visibility and media_urls to community_posts"
```

---

### Task 2: API — expand createPost + visibility filter in getFeed

**Files:**
- Modify: `stepup-api/src/modules/community/community.service.ts`
- Modify: `stepup-api/src/modules/community/community.router.ts`

- [ ] **Step 1: Update `community.service.ts` — expand valid types, accept visibility + media_urls in createPost**

Replace the entire file with:

```typescript
// stepup-api/src/modules/community/community.service.ts
import { getSupabase } from '../../lib/supabase';

const VALID_TYPES = [
  'flex', 'achievement', 'challenge_win', 'streak_milestone',
  'photo', 'progress', 'gym', 'nutrition', 'milestone',
];

export async function getFeed(userId: string, page = 1) {
  const db = getSupabase();
  const pageSize = 20;
  const offset = (page - 1) * pageSize;

  const { data: posts } = await db
    .from('community_posts')
    .select('*')
    .eq('visibility', 'everyone')
    .order('created_at', { ascending: false })
    .range(offset, offset + pageSize - 1);

  if (!posts || posts.length === 0) return [];

  const userIds = [...new Set(posts.map(p => p.user_id))];
  const { data: users } = await db
    .from('users')
    .select('id, name, avatar_url, league')
    .in('id', userIds);

  const userMap = Object.fromEntries((users ?? []).map(u => [u.id, u]));

  const postIds = posts.map(p => p.id);
  const { data: likes } = await db
    .from('community_post_likes')
    .select('post_id')
    .eq('user_id', userId)
    .in('post_id', postIds);

  const likedSet = new Set((likes ?? []).map(l => l.post_id));

  return posts.map(p => ({
    ...p,
    user_name: userMap[p.user_id]?.name ?? 'Unknown',
    user_avatar: userMap[p.user_id]?.avatar_url ?? null,
    user_league: userMap[p.user_id]?.league ?? 'bronze',
    liked_by_me: likedSet.has(p.id),
    is_mine: p.user_id === userId,
  }));
}

export async function getMyFeed(userId: string, page = 1) {
  const db = getSupabase();
  const pageSize = 20;
  const offset = (page - 1) * pageSize;

  const { data: posts } = await db
    .from('community_posts')
    .select('*')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .range(offset, offset + pageSize - 1);

  if (!posts || posts.length === 0) return [];

  const postIds = posts.map(p => p.id);
  const { data: likes } = await db
    .from('community_post_likes')
    .select('post_id')
    .eq('user_id', userId)
    .in('post_id', postIds);

  const likedSet = new Set((likes ?? []).map(l => l.post_id));

  const { data: user } = await db
    .from('users')
    .select('id, name, avatar_url, league')
    .eq('id', userId)
    .single();

  return posts.map(p => ({
    ...p,
    user_name: user?.name ?? 'Unknown',
    user_avatar: user?.avatar_url ?? null,
    user_league: user?.league ?? 'bronze',
    liked_by_me: likedSet.has(p.id),
    is_mine: true,
  }));
}

export async function createPost(
  userId: string,
  type: string,
  content: string,
  visibility: string = 'everyone',
  mediaUrls: string[] = [],
  metadata: Record<string, unknown> = {}
) {
  const db = getSupabase();
  if (!VALID_TYPES.includes(type)) throw new Error('Invalid post type');
  const validVisibility = ['everyone', 'followers', 'friends'];
  if (!validVisibility.includes(visibility)) throw new Error('Invalid visibility');

  const { data, error } = await db
    .from('community_posts')
    .insert({
      user_id: userId,
      type,
      content,
      visibility,
      media_urls: mediaUrls,
      metadata,
    })
    .select()
    .single();

  if (error) throw new Error(error.message);
  return data;
}

export async function likePost(userId: string, postId: string) {
  const db = getSupabase();

  const { data: existing } = await db
    .from('community_post_likes')
    .select('post_id')
    .eq('post_id', postId)
    .eq('user_id', userId)
    .maybeSingle();

  if (existing) {
    await db.from('community_post_likes').delete().eq('post_id', postId).eq('user_id', userId);
    await db.from('community_posts').update({ likes: db.rpc('decrement', { row_id: postId }) as any }).eq('id', postId);
    return { liked: false };
  }

  await db.from('community_post_likes').insert({ post_id: postId, user_id: userId });
  const { data: post } = await db.from('community_posts').select('likes').eq('id', postId).single();
  await db.from('community_posts').update({ likes: (post?.likes ?? 0) + 1 }).eq('id', postId);
  return { liked: true };
}
```

- [ ] **Step 2: Update `community.router.ts` — rename `/flex` to `/posts`, add my-feed route**

Replace the entire file with:

```typescript
// stepup-api/src/modules/community/community.router.ts
import { Router, Request, Response } from 'express';
import { getFeed, getMyFeed, createPost, likePost } from './community.service';

export const communityRouter = Router();

communityRouter.get('/feed', async (req: Request, res: Response) => {
  try {
    const page = parseInt((req.query['page'] as string) ?? '1', 10);
    res.json(await getFeed(req.user!.id, page));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

communityRouter.get('/my-posts', async (req: Request, res: Response) => {
  try {
    const page = parseInt((req.query['page'] as string) ?? '1', 10);
    res.json(await getMyFeed(req.user!.id, page));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// Keep /flex for backwards compat, and add /posts as the canonical endpoint
communityRouter.post('/posts', async (req: Request, res: Response) => {
  try {
    const { type = 'flex', content, visibility = 'everyone', media_urls = [], metadata = {} } = req.body;
    if (!content) return res.status(400).json({ error: 'content required' });
    res.json(await createPost(req.user!.id, type, content, visibility, media_urls, metadata));
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

communityRouter.post('/flex', async (req: Request, res: Response) => {
  try {
    const { type = 'flex', content, visibility = 'everyone', media_urls = [], metadata = {} } = req.body;
    if (!content) return res.status(400).json({ error: 'content required' });
    res.json(await createPost(req.user!.id, type, content, visibility, media_urls, metadata));
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

communityRouter.post('/posts/:id/like', async (req: Request, res: Response) => {
  try {
    res.json(await likePost(req.user!.id, req.params['id'] as string));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
```

- [ ] **Step 3: Build and deploy API**

```bash
cd stepup-api && npm run build
```

Expected: no TypeScript errors. Then push to Railway (or it auto-deploys on git push).

- [ ] **Step 4: Test with curl**

```bash
# Replace TOKEN with a real Supabase session token
curl -X POST https://stepup-production-ebd2.up.railway.app/community/posts \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"type":"gym","content":"Test post","visibility":"everyone","media_urls":[]}'
```

Expected: JSON response with the created post including `visibility: "everyone"` and `media_urls: []`.

- [ ] **Step 5: Commit**

```bash
git add stepup-api/src/modules/community/
git commit -m "feat: expand community API — visibility filter, new post types, /posts endpoint"
```

---

### Task 3: Flutter Model — add visibility + mediaUrls

**Files:**
- Modify: `stepup/lib/shared/models/community_post.dart`

- [ ] **Step 1: Update `CommunityPost` model**

Replace the entire file with:

```dart
class CommunityPost {
  final String id, userId, userName, type, content;
  final String? userAvatar, userLeague;
  final int likes;
  final bool likedByMe, isMine;
  final DateTime createdAt;
  final String visibility;
  final List<String> mediaUrls;

  const CommunityPost({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.content,
    this.userAvatar,
    this.userLeague,
    required this.likes,
    required this.likedByMe,
    required this.isMine,
    required this.createdAt,
    this.visibility = 'everyone',
    this.mediaUrls = const [],
  });

  factory CommunityPost.fromJson(Map<String, dynamic> j) => CommunityPost(
    id: j['id'] as String,
    userId: j['user_id'] as String,
    userName: j['user_name'] as String? ?? 'Unknown',
    type: j['type'] as String,
    content: j['content'] as String,
    userAvatar: j['user_avatar'] as String?,
    userLeague: j['user_league'] as String?,
    likes: (j['likes'] as num? ?? 0).toInt(),
    likedByMe: j['liked_by_me'] as bool? ?? false,
    isMine: j['is_mine'] as bool? ?? false,
    createdAt: DateTime.parse(j['created_at'] as String),
    visibility: j['visibility'] as String? ?? 'everyone',
    mediaUrls: (j['media_urls'] as List<dynamic>?)
        ?.map((e) => e as String)
        .toList() ?? [],
  );
}
```

- [ ] **Step 2: Run Flutter analyze to confirm no breakage**

```bash
cd stepup && flutter analyze lib/shared/models/community_post.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add stepup/lib/shared/models/community_post.dart
git commit -m "feat: add visibility and mediaUrls to CommunityPost model"
```

---

### Task 4: Flutter Provider — CreatePostNotifier

**Files:**
- Modify: `stepup/lib/features/community/providers/community_provider.dart`

- [ ] **Step 1: Replace provider file with feed provider + create post notifier**

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../../shared/models/community_post.dart';

final communityFeedProvider = FutureProvider<List<CommunityPost>>((ref) async {
  final data = await ApiClient.instance.get('/community/feed') as List;
  return data.map((j) => CommunityPost.fromJson(j as Map<String, dynamic>)).toList();
});

class CreatePostState {
  final bool isLoading;
  final String? error;
  final bool success;
  const CreatePostState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });
  CreatePostState copyWith({bool? isLoading, String? error, bool? success}) =>
      CreatePostState(
        isLoading: isLoading ?? this.isLoading,
        error: error,
        success: success ?? this.success,
      );
}

class CreatePostNotifier extends StateNotifier<CreatePostState> {
  CreatePostNotifier() : super(const CreatePostState());

  Future<void> submit({
    required String type,
    required String content,
    required String visibility,
    List<String> mediaUrls = const [],
  }) async {
    state = state.copyWith(isLoading: true, error: null, success: false);
    try {
      await ApiClient.instance.post('/community/posts', {
        'type': type,
        'content': content,
        'visibility': visibility,
        'media_urls': mediaUrls,
      });
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void reset() => state = const CreatePostState();
}

final createPostProvider =
    StateNotifierProvider.autoDispose<CreatePostNotifier, CreatePostState>(
  (_) => CreatePostNotifier(),
);
```

- [ ] **Step 2: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/features/community/providers/community_provider.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add stepup/lib/features/community/providers/community_provider.dart
git commit -m "feat: add CreatePostNotifier provider for community post submission"
```

---

### Task 5: Flutter UI — Create Post Screen

**Files:**
- Create: `stepup/lib/features/community/screens/create_post_screen.dart`

- [ ] **Step 1: Create the file**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/community_provider.dart';
import '../../../core/theme.dart';

class CreatePostScreen extends ConsumerStatefulWidget {
  const CreatePostScreen({super.key});

  @override
  ConsumerState<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends ConsumerState<CreatePostScreen> {
  final _captionCtrl = TextEditingController();
  String _selectedType = 'flex';
  String _visibility = 'everyone';

  static const _types = [
    ('flex', 'Flex', '💪'),
    ('gym', 'Gym', '🏋️'),
    ('progress', 'Progress', '📈'),
    ('nutrition', 'Nutrition', '🥗'),
    ('achievement', 'Achievement', '🏅'),
    ('milestone', 'Milestone', '⭐'),
  ];

  static const _visibilityOptions = [
    ('everyone', 'Everyone', Icons.public_rounded),
    ('followers', 'Followers', Icons.people_rounded),
    ('friends', 'Friends', Icons.group_rounded),
  ];

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final caption = _captionCtrl.text.trim();
    if (caption.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add a caption to post')),
      );
      return;
    }
    await ref.read(createPostProvider.notifier).submit(
          type: _selectedType,
          content: caption,
          visibility: _visibility,
        );
    if (!mounted) return;
    final state = ref.read(createPostProvider);
    if (state.success) {
      ref.invalidate(communityFeedProvider);
      context.pop();
    } else if (state.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final createState = ref.watch(createPostProvider);
    final isLoading = createState.isLoading;

    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text('New Post',
            style: AppTheme.bigNum(18).copyWith(fontStyle: FontStyle.italic)),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: AppTheme.voltLime, strokeWidth: 2))
                : GestureDetector(
                    onTap: _submit,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppTheme.voltLime,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('Post',
                          style: AppTheme.label(13,
                                  color: AppTheme.bg)
                              .copyWith(fontWeight: FontWeight.w800)),
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Post type chips
          Text('POST TYPE',
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _types.map((t) {
              final (val, label, emoji) = t;
              final selected = _selectedType == val;
              return GestureDetector(
                onTap: () => setState(() => _selectedType = val),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected
                        ? AppTheme.voltLime.withValues(alpha: 0.12)
                        : AppTheme.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppTheme.voltLime
                          : AppTheme.border,
                    ),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(emoji, style: const TextStyle(fontSize: 14)),
                    const SizedBox(width: 6),
                    Text(label,
                        style: AppTheme.label(13,
                                color: selected
                                    ? AppTheme.voltLime
                                    : Colors.white)
                            .copyWith(fontWeight: FontWeight.w600)),
                  ]),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Caption
          Text('CAPTION',
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: TextField(
              controller: _captionCtrl,
              maxLines: 5,
              maxLength: 280,
              style: AppTheme.label(14, color: Colors.white),
              decoration: InputDecoration(
                hintText:
                    'What\'s on your mind? Tag @friends to shout them out...',
                hintStyle: AppTheme.label(14, color: AppTheme.ink2),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(14),
                counterStyle: AppTheme.label(11, color: AppTheme.ink2),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Audience
          Text('AUDIENCE',
              style: AppTheme.label(10, color: AppTheme.ink2)
                  .copyWith(letterSpacing: 1.2)),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: Column(
              children: _visibilityOptions.asMap().entries.map((entry) {
                final i = entry.key;
                final (val, label, icon) = entry.value;
                final selected = _visibility == val;
                return Column(children: [
                  if (i != 0)
                    Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.06)),
                  GestureDetector(
                    onTap: () => setState(() => _visibility = val),
                    behavior: HitTestBehavior.opaque,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      child: Row(children: [
                        Icon(icon,
                            color: selected
                                ? AppTheme.voltLime
                                : AppTheme.ink2,
                            size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(label,
                              style: AppTheme.label(14,
                                      color: selected
                                          ? Colors.white
                                          : AppTheme.ink2)
                                  .copyWith(fontWeight: FontWeight.w600)),
                        ),
                        if (selected)
                          const Icon(Icons.check_rounded,
                              color: AppTheme.voltLime, size: 18),
                      ]),
                    ),
                  ),
                ]);
              }).toList(),
            ),
          ),

          const SizedBox(height: 40),
        ]),
      ),
    );
  }
}
```

- [ ] **Step 2: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/features/community/screens/create_post_screen.dart
```

Expected: no issues.

- [ ] **Step 3: Commit**

```bash
git add stepup/lib/features/community/screens/create_post_screen.dart
git commit -m "feat: add CreatePostScreen with post type, caption, and audience picker"
```

---

### Task 6: Wire up router + FAB in community screen

**Files:**
- Modify: `stepup/lib/core/router.dart`
- Modify: `stepup/lib/features/community/screens/community_screen.dart`

- [ ] **Step 1: Add route to router.dart**

In [router.dart](stepup/lib/core/router.dart), find the line:

```dart
import '../features/community/screens/community_screen.dart';
```

Add below it:

```dart
import '../features/community/screens/create_post_screen.dart';
```

Then find:

```dart
GoRoute(path: '/community',      builder: (_, __) => const CommunityScreen()),
```

Replace with:

```dart
GoRoute(
  path: '/community',
  builder: (_, __) => const CommunityScreen(),
  routes: [
    GoRoute(
      path: 'create',
      builder: (_, __) => const CreatePostScreen(),
    ),
  ],
),
```

- [ ] **Step 2: Add FAB to CommunityScreen**

In [community_screen.dart](stepup/lib/features/community/screens/community_screen.dart), change the `Scaffold` to add a `floatingActionButton`. Find:

```dart
      body: SafeArea(
```

Add `floatingActionButton` to the `Scaffold`:

```dart
    return Scaffold(
      backgroundColor: AppTheme.bg,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/community/create');
          ref.invalidate(communityFeedProvider);
        },
        backgroundColor: AppTheme.voltLime,
        child: const Icon(Icons.add_rounded, color: Color(0xFF050510)),
      ),
      body: SafeArea(
```

- [ ] **Step 3: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/features/community/ lib/core/router.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add stepup/lib/core/router.dart stepup/lib/features/community/screens/community_screen.dart
git commit -m "feat: add FAB + /community/create route to community screen"
```

---

### Task 7: Home screen — community section post shortcut

**Files:**
- Modify: `stepup/lib/features/home/screens/home_screen.dart`

- [ ] **Step 1: Update the community section header to include a Post button**

In [home_screen.dart](stepup/lib/features/home/screens/home_screen.dart), find the community section block:

```dart
            _SectionRow(
              title: 'Community',
              onSeeAll: () => context.push('/community'),
            ),
```

Replace with:

```dart
            _SectionRow(
              title: 'Community',
              onSeeAll: () => context.push('/community'),
              trailing: GestureDetector(
                onTap: () async {
                  await context.push('/community/create');
                  ref.invalidate(communityFeedProvider);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.voltLime,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.add_rounded, size: 14, color: Color(0xFF050510)),
                    const SizedBox(width: 4),
                    Text('Post',
                        style: AppTheme.label(12, color: AppTheme.bg)
                            .copyWith(fontWeight: FontWeight.w800)),
                  ]),
                ),
              ),
            ),
```

- [ ] **Step 2: Check if `_SectionRow` supports a `trailing` parameter**

Read the `_SectionRow` widget in [home_screen.dart](stepup/lib/features/home/screens/home_screen.dart). Find its class definition with:

```bash
grep -n "_SectionRow" stepup/lib/features/home/screens/home_screen.dart
```

If `_SectionRow` only has `title` and `onSeeAll`, update its class to also accept `trailing`:

```dart
class _SectionRow extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final Widget? trailing;
  const _SectionRow({required this.title, this.onSeeAll, this.trailing});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(title, style: AppTheme.bigNum(18).copyWith(fontStyle: FontStyle.italic)),
      Row(mainAxisSize: MainAxisSize.min, children: [
        if (trailing != null) ...[trailing!, const SizedBox(width: 10)],
        if (onSeeAll != null)
          GestureDetector(
            onTap: onSeeAll,
            child: Text('See all',
                style: AppTheme.label(13, color: AppTheme.ink2)),
          ),
      ]),
    ],
  );
}
```

> Note: Check the actual `_SectionRow` implementation first — it may already have a `trailing` param or differ in structure. Adapt accordingly without changing the visual appearance of other section rows.

- [ ] **Step 3: Run Flutter analyze**

```bash
cd stepup && flutter analyze lib/features/home/screens/home_screen.dart
```

Expected: no issues.

- [ ] **Step 4: Commit**

```bash
git add stepup/lib/features/home/screens/home_screen.dart
git commit -m "feat: add Post shortcut button to home screen community section"
```

---

### Task 8: Integration smoke test

- [ ] **Step 1: Run the app**

```bash
cd stepup && flutter run
```

- [ ] **Step 2: Test the golden path**

1. Open the app → Home screen → verify Community section loads posts from API
2. Tap the "Post" button in the Community section header → CreatePostScreen opens
3. Select a post type (e.g. "Gym"), write a caption, pick "Everyone" visibility
4. Tap "Post" → app should navigate back, community feed refreshes with new post visible
5. Navigate to Community tab → post appears at the top of the feed with correct type badge

- [ ] **Step 3: Test visibility setting**

1. Create a post with "Friends" visibility
2. On the feed, confirm the post does NOT appear (since the API's `getFeed` only shows `everyone` posts to the public feed)
3. This is correct — the user will only see their own friends-visibility posts when a personal feed / profile page is implemented

- [ ] **Step 4: Commit any fixes**

Fix any issues found during smoke test and commit with `fix:` prefix.
