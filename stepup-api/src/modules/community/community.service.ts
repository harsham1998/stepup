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

  // Single JOIN query — no N+1
  const { data: posts, error } = await db
    .from('community_posts')
    .select(`
      *,
      users!community_posts_user_id_fkey (
        id,
        name,
        avatar_url,
        league
      )
    `)
    .eq('visibility', 'everyone')
    .order('created_at', { ascending: false })
    .range(offset, offset + pageSize - 1);

  if (error || !posts || posts.length === 0) return [];

  const postIds = posts.map((p: any) => p.id);
  const { data: likes } = await db
    .from('community_post_likes')
    .select('post_id')
    .eq('user_id', userId)
    .in('post_id', postIds);

  const likedSet = new Set((likes ?? []).map((l: any) => l.post_id));

  return posts.map((p: any) => {
    const user = p.users as { name?: string; avatar_url?: string; league?: string } | null;
    return {
      id: p.id,
      user_id: p.user_id,
      type: p.type,
      content: p.content,
      visibility: p.visibility,
      media_urls: p.media_urls ?? [],
      likes: p.likes ?? 0,
      metadata: p.metadata,
      created_at: p.created_at,
      user_name: user?.name ?? 'Unknown',
      user_avatar: user?.avatar_url ?? null,
      user_league: user?.league ?? 'bronze',
      liked_by_me: likedSet.has(p.id),
      is_mine: p.user_id === userId,
    };
  });
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
    // Atomic decrement via DB function — no race condition
    await db.rpc('decrement_post_likes', { post_id: postId });
    return { liked: false };
  }

  await db.from('community_post_likes').insert({ post_id: postId, user_id: userId });
  // Atomic increment via DB function — no race condition
  await db.rpc('increment_post_likes', { post_id: postId });
  return { liked: true };
}
