import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { ChallengeRow } from '../../types';

export async function listChallenges(status?: string): Promise<ChallengeRow[]> {
  let query = getSupabase()
    .from('challenges')
    .select('*')
    .order('start_time', { ascending: true });
  if (status) query = query.eq('status', status);
  const { data, error } = await query;
  if (error) throw new Error(error.message);
  return (data ?? []) as ChallengeRow[];
}

export async function getChallenge(id: string): Promise<ChallengeRow> {
  const { data, error } = await getSupabase()
    .from('challenges')
    .select('*')
    .eq('id', id)
    .single();
  if (error) throw new Error(error.message);
  return data as ChallengeRow;
}

export async function joinChallenge(userId: string, challengeId: string) {
  const db = getSupabase();
  const challenge = await getChallenge(challengeId);

  if (challenge.status !== 'active' && challenge.status !== 'upcoming') {
    throw new Error('Challenge is not open for joining');
  }

  if (challenge.max_participants) {
    const { count } = await db
      .from('challenge_participants')
      .select('*', { count: 'exact', head: true })
      .eq('challenge_id', challengeId);
    if ((count ?? 0) >= challenge.max_participants) throw new Error('Challenge is full');
  }

  const idempotencyKey = `challenge_join:${userId}:${challengeId}`;

  if (challenge.entry_fee > 0) {
    await debitWalletForChallenge(userId, challenge.entry_fee, challengeId, idempotencyKey);
  }

  const { error: joinErr } = await db
    .from('challenge_participants')
    .insert({ challenge_id: challengeId, user_id: userId });
  if (joinErr) {
    if (joinErr.code === '23505') throw new Error('Already joined this challenge');
    throw new Error(joinErr.message);
  }

  const redis = getRedis();
  await redis.zadd(`leaderboard:challenge:${challengeId}`, 0, userId);

  return { joined: true, challenge_id: challengeId };
}

async function debitWalletForChallenge(
  userId: string,
  amount: number,
  challengeId: string,
  idempotencyKey: string,
) {
  const db = getSupabase();
  const { data: txns } = await db
    .from('wallet_transactions')
    .select('type, amount')
    .eq('user_id', userId);

  const balance = (txns ?? []).reduce((sum: number, t: { type: string; amount: number }) =>
    t.type === 'credit' ? sum + t.amount : sum - t.amount, 0);
  if (balance < amount) throw new Error('Insufficient wallet balance');

  const { error } = await db.from('wallet_transactions').insert({
    user_id: userId,
    type: 'debit',
    amount,
    idempotency_key: idempotencyKey,
    description: `Entry fee for challenge ${challengeId}`,
  });
  if (error && error.code !== '23505') throw new Error(error.message);
}
