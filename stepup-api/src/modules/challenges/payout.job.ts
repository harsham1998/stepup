import { createQueue, createWorker } from '../../lib/queue';
import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';
import { logger } from '../../lib/logger';
import { PrizeDistribution, WalletTransaction } from '../../types';
import { notifyChallengePayout } from '../notifications/notifications.service';
import { awardXp } from '../steps/xp.service';

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

function getChallengeXp(
  challenge: { entry_fee: number; start_time: string; end_time: string },
  rankFromTop: number,
  totalParticipants: number,
): number {
  const isFree = challenge.entry_fee === 0;
  const durationDays = Math.round(
    (new Date(challenge.end_time).getTime() - new Date(challenge.start_time).getTime()) / 86_400_000,
  );
  if (isFree) return durationDays <= 1 ? 50 : 150;
  // Edge case: sole participant is automatically "top 10%"
  if (totalParticipants <= 1) return 400;
  // Paid: top 10% gets 400, top 50% gets 200, rest get 50 participation XP
  const topPercent = rankFromTop / totalParticipants;
  if (topPercent <= 0.10) return 400;
  if (topPercent <= 0.50) return 200;
  return 50;
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

  // Build ranked list: try Redis first, fall back to user_daily_steps from DB
  const ranked: Array<{ userId: string; steps: number }> = [];
  const lbKey = `leaderboard:challenge:${challengeId}`;

  try {
    const redisRanks = await redis.zrevrange(lbKey, 0, -1, 'WITHSCORES');
    for (let i = 0; i < redisRanks.length; i += 2) {
      ranked.push({ userId: redisRanks[i], steps: parseInt(redisRanks[i + 1], 10) });
    }
  } catch (_) { /* Redis unavailable — fall through to DB */ }

  if (ranked.length === 0) {
    logger.info({ challengeId }, 'Redis leaderboard empty — falling back to user_daily_steps');
    const startDate = challenge.start_time.slice(0, 10);
    const endDate = challenge.end_time.slice(0, 10);
    const { data: parts } = await db.from('challenge_participants')
      .select('user_id').eq('challenge_id', challengeId);
    const userIds = (parts ?? []).map((p: any) => p.user_id as string);
    const { data: stepRows } = await db.from('user_daily_steps')
      .select('user_id, total_steps')
      .in('user_id', userIds)
      .gte('date', startDate)
      .lte('date', endDate);
    const totals: Record<string, number> = {};
    for (const row of stepRows ?? []) {
      totals[row.user_id] = (totals[row.user_id] ?? 0) + row.total_steps;
    }
    for (const uid of userIds) {
      ranked.push({ userId: uid, steps: totals[uid] ?? 0 });
    }
    ranked.sort((a, b) => b.steps - a.steps);
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
        status: 'completed',
      });

      // Fix 3: check update errors
      const { error: updateErr } = await db.from('challenge_participants')
        .update({ final_rank: prevCutoff - tierWinners.length + rank + 1, payout_amount: perWinner })
        .eq('challenge_id', challengeId).eq('user_id', winner.userId);
      if (updateErr) throw new Error(`Failed to update participant rank: ${updateErr.message}`);

      // Fire-and-forget notification (non-blocking)
      notifyChallengePayout(winner.userId, perWinner, prevCutoff + rank + 1).catch(() => {});

      // Award XP based on challenge type and rank
      const xpAmount = getChallengeXp(challenge, prevCutoff - tierWinners.length + rank + 1, ranked.length);
      awardXp(winner.userId, xpAmount).catch(() => {});
    }
  }

  // Award participation XP to everyone not already in a prize tier
  const winnersSet = new Set(walletInserts.map(w => w.user_id));
  for (const participant of ranked) {
    if (!winnersSet.has(participant.userId)) {
      // For free challenges: same duration-based XP as winners
      // For paid challenges: 50 XP participation (outside top-50%)
      const participationXp = getChallengeXp(challenge, ranked.length + 1, ranked.length);
      awardXp(participant.userId, participationXp).catch(() => {});
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
