import 'dotenv/config';
import { createApp } from './app';
import { logger } from './lib/logger';
import { createQueue, createWorker } from './lib/queue';
import { recalculateLeagues } from './modules/steps/xp.service';
import { recalculateAllReputation } from './modules/reputation/reputation.service';

const PORT = Number(process.env.PORT ?? 3000);
const app = createApp();

app.listen(PORT, () => {
  logger.info({ port: PORT }, 'StepUp API started');
});

// Every Monday at midnight IST (UTC+5:30 -> Sunday 18:30 UTC)
const leagueQueue = createQueue('league-recalc');
createWorker('league-recalc', async () => { await recalculateLeagues(); });
leagueQueue.add('recalc', {}, { repeat: { pattern: '30 18 * * 0' } });

// Nightly reputation recalc at 2am IST (8:30pm UTC)
const reputationQueue = createQueue('reputation-recalc');
createWorker('reputation-recalc', async () => { await recalculateAllReputation(); });
reputationQueue.add('recalc', {}, { repeat: { pattern: '30 20 * * *' } });
