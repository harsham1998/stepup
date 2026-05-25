// stepup-api/src/modules/subscriptions/subscriptions.router.ts
import { Router, Request, Response } from 'express';
import { getPlans, getMySubscription, subscribe } from './subscriptions.service';

export const subscriptionsRouter = Router();

subscriptionsRouter.get('/plans', async (req: Request, res: Response) => {
  try {
    res.json(await getPlans());
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

subscriptionsRouter.get('/me', async (req: Request, res: Response) => {
  try {
    res.json(await getMySubscription(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

subscriptionsRouter.post('/subscribe', async (req: Request, res: Response) => {
  try {
    const { plan_slug } = req.body;
    if (!plan_slug) return res.status(400).json({ error: 'plan_slug required' });
    res.json(await subscribe(req.user!.id, plan_slug));
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
