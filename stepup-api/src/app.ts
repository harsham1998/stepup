// stepup-api/src/app.ts
import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { authMiddleware } from './gateway/middleware/auth';
import { rateLimitMiddleware } from './gateway/middleware/rateLimit';
import { errorHandler } from './gateway/errorHandler';
import { authRouter } from './modules/auth/auth.router';
import { stepsRouter } from './modules/steps/steps.router';
import { challengesRouter } from './modules/challenges/challenges.router';
import { customChallengesRouter } from './modules/challenges/custom.router';
import { leaderboardRouter } from './modules/leaderboard/leaderboard.router';
import { walletRouter } from './modules/wallet/wallet.router';
import { razorpayWebhookRouter } from './modules/wallet/razorpay.webhook';
import { leaguesRouter } from './modules/leagues/leagues.router';
import { missionsRouter } from './modules/missions/missions.router';
import { rivalsRouter } from './modules/rivals/rivals.router';
import { rewardsRouter } from './modules/rewards/rewards.router';
import { battlepassRouter } from './modules/battlepass/battlepass.router';
import { subscriptionsRouter } from './modules/subscriptions/subscriptions.router';
import { communityRouter } from './modules/community/community.router';
import { streaksRouter } from './modules/streaks/streaks.router';
import { activitiesRouter } from './modules/activities/activities.router';
import { notificationsRouter } from './modules/notifications/notifications.router';
import { achievementsRouter } from './modules/achievements/achievements.router';
import { levelsRouter } from './modules/steps/levels.router';
import { reputationRouter } from './modules/reputation/reputation.router';
import { seasonsRouter } from './modules/seasons/seasons.router';
import { socialRouter } from './modules/social/social.router';
import { friendsRouter } from './modules/friends/friends.router';
import { bodyVitalsRouter } from './modules/body-vitals/body_vitals.router';

export function createApp() {
  const app = express();
  app.use(helmet());
  app.use(cors({ origin: process.env.CORS_ORIGIN ?? '*' }));
  app.use(express.json());

  // Public routes
  app.get('/health', (_req, res) => res.json({ status: 'ok', version: '3' }));
  app.use('/auth', authRouter);
  app.post('/wallet/webhook/razorpay',
    express.raw({ type: 'application/json' }),
    razorpayWebhookRouter
  );

  // Protected routes
  app.use(authMiddleware);
  app.use(rateLimitMiddleware);
  app.use('/steps', stepsRouter);
  app.use('/challenges/custom', customChallengesRouter);
  app.use('/challenges', challengesRouter);
  app.use('/leaderboard', leaderboardRouter);
  app.use('/wallet', walletRouter);
  app.use('/leagues', leaguesRouter);
  app.use('/missions', missionsRouter);
  app.use('/rivals', rivalsRouter);
  app.use('/rewards', rewardsRouter);
  app.use('/battlepass', battlepassRouter);
  app.use('/subscriptions', subscriptionsRouter);
  app.use('/community', communityRouter);
  app.use('/streaks', streaksRouter);
  app.use('/activities', activitiesRouter);
  app.use('/notifications', notificationsRouter);
  app.use('/achievements', achievementsRouter);
  app.use('/xp', levelsRouter);
  app.use('/reputation', reputationRouter);
  app.use('/seasons', seasonsRouter);
  app.use('/social', socialRouter);
  app.use('/friends', friendsRouter);
  app.use('/body-vitals', bodyVitalsRouter);

  app.use(errorHandler);
  return app;
}
