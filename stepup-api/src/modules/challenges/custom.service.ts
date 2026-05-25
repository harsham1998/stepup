// stepup-api/src/modules/challenges/custom.service.ts
import { getSupabase } from '../../lib/supabase';

const COIN_REWARDS: Record<string, number> = { easy: 60, medium: 200, hard: 500 };

export async function createCustomChallenge(
  creatorId: string,
  data: {
    title: string;
    activity: string;
    difficulty: 'easy' | 'medium' | 'hard';
    duration_days: number;
    frequency: string;
  }
) {
  const db = getSupabase();
  const coinReward = COIN_REWARDS[data.difficulty] ?? 60;

  const { data: challenge, error } = await db.from('custom_challenges').insert({
    creator_id: creatorId,
    title: data.title,
    activity: data.activity,
    difficulty: data.difficulty,
    duration_days: data.duration_days,
    frequency: data.frequency,
    coin_reward: coinReward,
    status: 'active',
  }).select().single();

  if (error) throw new Error(error.message);
  return challenge;
}

export async function getByShareCode(shareCode: string) {
  const db = getSupabase();
  const { data, error } = await db
    .from('custom_challenges')
    .select('*, users!creator_id(name, avatar_url)')
    .eq('share_code', shareCode)
    .single();
  if (error) throw new Error('Challenge not found');
  return data;
}

export async function inviteFriends(challengeId: string, creatorId: string, inviteeIds: string[]) {
  const db = getSupabase();

  // Verify creator owns challenge
  const { data: ch } = await db
    .from('custom_challenges')
    .select('creator_id')
    .eq('id', challengeId)
    .single();

  if (!ch || ch.creator_id !== creatorId) throw new Error('Not your challenge');

  const rows = inviteeIds.map(id => ({
    challenge_id: challengeId,
    invitee_id: id,
    status: 'pending',
  }));

  await db.from('custom_challenge_invites').upsert(rows, { onConflict: 'challenge_id,invitee_id', ignoreDuplicates: true });
  return { invited: inviteeIds.length };
}
