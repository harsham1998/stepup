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

  // Also block if receiver already sent us a pending request
  const { data: reverseReq } = await db
    .from('friend_requests')
    .select('id')
    .eq('sender_id', receiverId)
    .eq('receiver_id', senderId)
    .eq('status', 'pending')
    .maybeSingle();
  if (reverseReq) throw Object.assign(new Error('This user already sent you a friend request'), { statusCode: 409 });

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
  const { data, error } = await getSupabase()
    .from('friendships')
    .select('friend_id')
    .eq('user_id', userId);
  if (error) throw new Error(error.message);
  return (data ?? []).map((f: any) => f.friend_id as string);
}
