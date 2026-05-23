import { createQueue, createWorker } from '../../lib/queue';
import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { logger } from '../../lib/logger';
import { PrizeDistribution } from '../../types';

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

  logger.info({ challengeId }, 'Processing payout');

  const lbKey = `leaderboard:challenge:${challengeId}`;
  const redisRanks = await redis.zrevrange(lbKey, 0, -1, 'WITHSCORES');

  const ranked: Array<{ userId: string; steps: number }> = [];
  for (let i = 0; i < redisRanks.length; i += 2) {
    ranked.push({ userId: redisRanks[i], steps: parseInt(redisRanks[i + 1]) });
  }

  const dist: PrizeDistribution = challenge.prize_distribution;
  const platformFee = Math.floor(challenge.prize_pool * dist.platform_fee_percent / 100);
  const distributablePool = challenge.prize_pool - platformFee;

  const walletInserts: object[] = [];

  for (const tier of dist.tiers) {
    const cutoff = Math.ceil(ranked.length * tier.top_percent / 100);
    const tierWinners = ranked.slice(0, cutoff);
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
        description: `Challenge winnings — rank #${rank + 1}`,
      });

      await db.from('challenge_participants')
        .update({ final_rank: rank + 1, payout_amount: perWinner })
        .eq('challenge_id', challengeId).eq('user_id', winner.userId);
    }
  }

  if (walletInserts.length > 0) {
    const { error: wErr } = await db.from('wallet_transactions').insert(walletInserts);
    if (wErr) throw new Error(`Wallet insert failed: ${wErr.message}`);
  }

  await db.from('challenges').update({ status: 'paid_out' }).eq('id', challengeId);
  logger.info({ challengeId, winners: walletInserts.length }, 'Payout complete');
}
