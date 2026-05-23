import express from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { authMiddleware } from './gateway/middleware/auth';
import { rateLimitMiddleware } from './gateway/middleware/rateLimit';
import { errorHandler } from './gateway/errorHandler';
import { authRouter } from './modules/auth/auth.router';
import { stepsRouter } from './modules/steps/steps.router';
import { challengesRouter } from './modules/challenges/challenges.router';
import { leaderboardRouter } from './modules/leaderboard/leaderboard.router';
import { walletRouter } from './modules/wallet/wallet.router';
import { razorpayWebhookRouter } from './modules/wallet/razorpay.webhook';

export function createApp() {
  const app = express();
  app.use(helmet());
  app.use(cors({ origin: process.env.CORS_ORIGIN ?? '*' }));
  app.use(express.json());

  // Public routes
  app.get('/health', (_req, res) => res.json({ status: 'ok', version: '2' }));
  app.use('/auth', authRouter);
  app.post('/wallet/webhook/razorpay',
    express.raw({ type: 'application/json' }),
    razorpayWebhookRouter
  );

  // Protected routes
  app.use(authMiddleware);
  app.use(rateLimitMiddleware);
  app.use('/steps', stepsRouter);
  app.use('/challenges', challengesRouter);
  app.use('/leaderboard', leaderboardRouter);
  app.use('/wallet', walletRouter);

  app.use(errorHandler);
  return app;
}
