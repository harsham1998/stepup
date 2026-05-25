// stepup-api/src/modules/community/community.service.ts
import { getSupabase } from '../../lib/supabase';

export async function getFeed(userId: string, page = 1) {
  const db = getSupabase();
  const pageSize = 20;
  const offset = (page - 1) * pageSize;

  const { data: posts } = await db
    .from('community_posts')
    .select('*')
    .order('created_at', { ascending: false })
    .range(offset, offset + pageSize - 1);

  if (!posts || posts.length === 0) return [];

  const userIds = [...new Set(posts.map(p => p.user_id))];
  const { data: users } = await db
    .from('users')
    .select('id, name, avatar_url, league')
    .in('id', userIds);

  const userMap = Object.fromEntries((users ?? []).map(u => [u.id, u]));

  // Check which posts the current user liked
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

export async function createPost(
  userId: string,
  type: string,
  content: string,
  metadata: Record<string, unknown> = {}
) {
  const db = getSupabase();
  const validTypes = ['flex', 'achievement', 'challenge_win', 'streak_milestone'];
  if (!validTypes.includes(type)) throw new Error('Invalid post type');

  const { data, error } = await db
    .from('community_posts')
    .insert({ user_id: userId, type, content, metadata })
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
    // Unlike
    await db.from('community_post_likes').delete().eq('post_id', postId).eq('user_id', userId);
    await db.from('community_posts').update({ likes: db.rpc('decrement', { row_id: postId }) as any }).eq('id', postId);
    return { liked: false };
  }

  await db.from('community_post_likes').insert({ post_id: postId, user_id: userId });
  const { data: post } = await db.from('community_posts').select('likes').eq('id', postId).single();
  await db.from('community_posts').update({ likes: (post?.likes ?? 0) + 1 }).eq('id', postId);
  return { liked: true };
}
