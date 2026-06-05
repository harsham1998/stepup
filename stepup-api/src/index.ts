import 'dotenv/config';
import { createApp } from './app';
import { logger } from './lib/logger';
import { createQueue, createWorker } from './lib/queue';
import { recalculateLeagues } from './modules/steps/xp.service';
import { recalculateAllReputation } from './modules/reputation/reputation.service';
import { startPayoutWorker } from './modules/challenges/payout.job';
import { endExpiredChallenges } from './modules/challenges/challenges.service';

// Prevent unhandled rejections from crashing the process (e.g. BullMQ/Redis errors)
process.on('unhandledRejection', (reason) => {
  logger.warn({ reason }, 'Unhandled promise rejection — continuing');
});

const PORT = Number(process.env.PORT ?? 3000);
const app = createApp();

app.listen(PORT, () => {
  logger.info({ port: PORT }, 'StepUp API started');
});

// Background jobs require Redis — skip gracefully if not configured
if (process.env.UPSTASH_REDIS_URL && !process.env.UPSTASH_REDIS_URL.includes('your-upstash')) {
  try {
    // Payout worker: processes jobs enqueued by endExpiredChallenges
    startPayoutWorker();

    // Challenge ender: every 10 minutes, moves expired active challenges → ended + queues payout
    const challengeEnderQueue = createQueue('challenge-ender');
    createWorker('challenge-ender', async () => { await endExpiredChallenges(); });
    challengeEnderQueue.add('end-challenges', {}, { repeat: { every: 10 * 60 * 1000 } }).catch(() => {});

    const leagueQueue = createQueue('league-recalc');
    createWorker('league-recalc', async () => { await recalculateLeagues(); });
    leagueQueue.add('recalc', {}, { repeat: { pattern: '30 18 * * 0' } }).catch(() => {});

    const reputationQueue = createQueue('reputation-recalc');
    createWorker('reputation-recalc', async () => { await recalculateAllReputation(); });
    reputationQueue.add('recalc', {}, { repeat: { pattern: '30 20 * * *' } }).catch(() => {});
  } catch (err) {
    logger.warn({ err }, 'Background job setup failed — queues disabled');
  }
} else {
  logger.warn('UPSTASH_REDIS_URL not configured — background jobs disabled');
}
