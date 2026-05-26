// stepup-api/src/modules/social/social.service.ts
import { getSupabase } from '../../lib/supabase';

export interface ActivityEvent {
  id: string;
  type: 'battle_lost' | 'league_overtake' | 'streak_milestone';
  friend_id: string;
  friend_name: string;
  friend_avatar: string | null;
  occurred_at: string;
  meta: Record<string, unknown>;
}

export async function getActivityFeed(userId: string): Promise<ActivityEvent[]> {
  const db = getSupabase();

  // Get friend IDs
  const { data: friendships } = await db
    .from('friendships')
    .select('friend_id')
    .eq('user_id', userId);

  const friendIds = (friendships ?? []).map(f => f.friend_id);
  if (friendIds.length === 0) return [];

  // Enrich friend profiles
  const { data: friends } = await db
    .from('users')
    .select('id, name, avatar_url, streak_days')
    .in('id', friendIds);

  const friendMap = Object.fromEntries((friends ?? []).map(u => [u.id, u]));

  const events: ActivityEvent[] = [];
  const cutoff = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000).toISOString();

  // Battles: where user lost to a friend (friend won)
  const { data: battles } = await db
    .from('battles')
    .select('id, challenger_id, opponent_id, winner_id, end_time, challenger_steps, opponent_steps')
    .eq('status', 'completed')
    .gte('end_time', cutoff)
    .or(`challenger_id.eq.${userId},opponent_id.eq.${userId}`);

  for (const b of battles ?? []) {
    const iChallenger = b.challenger_id === userId;
    const friendId = iChallenger ? b.opponent_id : b.challenger_id;
    if (!friendIds.includes(friendId)) continue;
    if (b.winner_id !== friendId) continue; // friend won, I lost

    const mySteps = iChallenger ? b.challenger_steps : b.opponent_steps;
    const friendSteps = iChallenger ? b.opponent_steps : b.challenger_steps;
    const friend = friendMap[friendId];

    events.push({
      id: `battle_${b.id}`,
      type: 'battle_lost',
      friend_id: friendId,
      friend_name: friend?.name ?? 'Unknown',
      friend_avatar: friend?.avatar_url ?? null,
      occurred_at: b.end_time,
      meta: { my_steps: mySteps, friend_steps: friendSteps },
    });
  }

  // League overtakes: friends whose user_leagues updated_at is recent and xp > mine
  const { data: myLeague } = await db
    .from('user_leagues')
    .select('xp')
    .eq('user_id', userId)
    .maybeSingle();

  const myXp = myLeague?.xp ?? 0;

  const { data: friendLeagues } = await db
    .from('user_leagues')
    .select('user_id, xp, updated_at')
    .in('user_id', friendIds)
    .gt('xp', myXp)
    .gte('updated_at', cutoff);

  for (const fl of friendLeagues ?? []) {
    const friend = friendMap[fl.user_id];
    events.push({
      id: `league_${fl.user_id}`,
      type: 'league_overtake',
      friend_id: fl.user_id,
      friend_name: friend?.name ?? 'Unknown',
      friend_avatar: friend?.avatar_url ?? null,
      occurred_at: fl.updated_at,
      meta: { friend_xp: fl.xp, my_xp: myXp, gap: fl.xp - myXp },
    });
  }

  // Streak milestones: friends who hit 7, 14, 30 day streaks recently
  const MILESTONE_DAYS = [7, 14, 21, 30, 60, 100];
  for (const f of friends ?? []) {
    if (MILESTONE_DAYS.includes(f.streak_days)) {
      events.push({
        id: `streak_${f.id}_${f.streak_days}`,
        type: 'streak_milestone',
        friend_id: f.id,
        friend_name: f.name ?? 'Unknown',
        friend_avatar: f.avatar_url ?? null,
        occurred_at: new Date().toISOString(),
        meta: { streak_days: f.streak_days },
      });
    }
  }

  // Sort by most recent first, cap at 20
  events.sort((a, b) => new Date(b.occurred_at).getTime() - new Date(a.occurred_at).getTime());
  return events.slice(0, 20);
}
