// stepup-api/src/modules/social/social.router.ts
import { Router, Request, Response } from 'express';
import { getActivityFeed } from './social.service';

export const socialRouter = Router();

socialRouter.get('/activity-feed', async (req: Request, res: Response) => {
  try {
    const data = await getActivityFeed(req.user!.id);
    res.json(data);
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
