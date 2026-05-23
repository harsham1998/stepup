import { createQueue, createWorker } from '../../lib/queue';
import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { logger } from '../../lib/logger';
import { PrizeDistribution, WalletTransaction } from '../../types';

const PAYOUT_QUEUE = 'challenge-payout';

export const payoutQueue = createQueue(PAYOUT_QUEUE);

export function startPayoutWorker() {
  createWorker(PAYOUT_QUEUE, async (job) => {
    await processPayout(job.data.challengeId);
  });
}

export async function schedulePayoutJob(challengeId: string, runAt: Date) {
  const delay = runAt.getTime() - Date.now();
  await payoutQueue.add('payout', { challengeId }, { delay: Math.max(delay, 0) });
}

export async function processPayout(challengeId: string) {
  const db = getSupabase();
  const redis = getRedis();

  const { data: challenge, error } = await db
    .from('challenges').select('*').eq('id', challengeId).single();
  if (error || !challenge) throw new Error(`Challenge ${challengeId} not found`);

  // Fix 4: paid_out guard — skip if already processed, reject if not ended
  if (challenge.status === 'paid_out') {
    logger.info({ challengeId }, 'Payout already processed, skipping');
    return;
  }
  if (challenge.status !== 'ended') {
    throw new Error(`Challenge ${challengeId} is not ended (status: ${challenge.status})`);
  }

  logger.info({ challengeId }, 'Processing payout');

  const lbKey = `leaderboard:challenge:${challengeId}`;
  const redisRanks = await redis.zrevrange(lbKey, 0, -1, 'WITHSCORES');

  const ranked: Array<{ userId: string; steps: number }> = [];
  for (let i = 0; i < redisRanks.length; i += 2) {
    // Fix 6: parseInt with radix
    ranked.push({ userId: redisRanks[i], steps: parseInt(redisRanks[i + 1], 10) });
  }

  const dist: PrizeDistribution = challenge.prize_distribution;
  const platformFee = Math.floor(challenge.prize_pool * dist.platform_fee_percent / 100);
  const distributablePool = challenge.prize_pool - platformFee;

  // Fix 5: type walletInserts properly
  const walletInserts: Omit<WalletTransaction, 'id' | 'created_at'>[] = [];

  // Fix 1: non-overlapping tier slices
  let prevCutoff = 0;
  for (const tier of dist.tiers) {
    const cutoff = Math.ceil(ranked.length * tier.top_percent / 100);
    const tierWinners = ranked.slice(prevCutoff, cutoff); // non-overlapping
    prevCutoff = cutoff;

    const tierPool = Math.floor(distributablePool * tier.share_percent / 100);
    const perWinner = tierWinners.length > 0 ? Math.floor(tierPool / tierWinners.length) : 0;

    for (let rank = 0; rank < tierWinners.length; rank++) {
      const winner = tierWinners[rank];
      walletInserts.push({
        user_id: winner.userId,
        type: 'credit',
        amount: perWinner,
        idempotency_key: `payout:${challengeId}:${winner.userId}`,
        reference_id: challengeId,
        description: `Challenge winnings — rank #${prevCutoff - tierWinners.length + rank + 1}`,
      });

      // Fix 3: check update errors
      const { error: updateErr } = await db.from('challenge_participants')
        .update({ final_rank: prevCutoff - tierWinners.length + rank + 1, payout_amount: perWinner })
        .eq('challenge_id', challengeId).eq('user_id', winner.userId);
      if (updateErr) throw new Error(`Failed to update participant rank: ${updateErr.message}`);
    }
  }

  if (walletInserts.length > 0) {
    // Fix 2: ignore 23505 duplicate key errors on retry
    const { error: wErr } = await db.from('wallet_transactions').insert(walletInserts);
    if (wErr && wErr.code !== '23505') throw new Error(`Wallet insert failed: ${wErr.message}`);
  }

  await db.from('challenges').update({ status: 'paid_out' }).eq('id', challengeId);
  logger.info({ challengeId, winners: walletInserts.length }, 'Payout complete');
}
