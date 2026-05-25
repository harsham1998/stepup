// stepup-api/src/modules/rewards/rewards.router.ts
import { Router, Request, Response } from 'express';
import { listRewards, redeemReward, getRedemptions } from './rewards.service';

export const rewardsRouter = Router();

rewardsRouter.get('/', async (req: Request, res: Response) => {
  try {
    const category = req.query['category'] as string | undefined;
    res.json(await listRewards(category));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

rewardsRouter.post('/:id/redeem', async (req: Request, res: Response) => {
  try {
    res.json(await redeemReward(req.user!.id, req.params['id'] as string));
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(msg.includes('Insufficient') || msg.includes('not found') ? 400 : 500).json({ error: msg });
  }
});

rewardsRouter.get('/redemptions', async (req: Request, res: Response) => {
  try {
    res.json(await getRedemptions(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
