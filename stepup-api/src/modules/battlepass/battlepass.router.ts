// stepup-api/src/modules/battlepass/battlepass.router.ts
import { Router, Request, Response } from 'express';
import { getCurrentBattlePass, claimTier } from './battlepass.service';

export const battlepassRouter = Router();

battlepassRouter.get('/current', async (req: Request, res: Response) => {
  try {
    const data = await getCurrentBattlePass(req.user!.id);
    res.json(data ?? { active: false });
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

battlepassRouter.post('/claim/:level', async (req: Request, res: Response) => {
  try {
    const level = parseInt(req.params['level'] as string, 10);
    res.json(await claimTier(req.user!.id, level));
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(400).json({ error: msg });
  }
});
