// stepup-api/src/modules/streaks/streaks.router.ts
import { Router, Request, Response } from 'express';
import { getStreakStatus, useShield, reviveStreak } from './streaks.service';

export const streaksRouter = Router();

streaksRouter.get('/status', async (req: Request, res: Response) => {
  try {
    res.json(await getStreakStatus(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

streaksRouter.post('/shield', async (req: Request, res: Response) => {
  try {
    res.json(await useShield(req.user!.id));
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(400).json({ error: msg });
  }
});

streaksRouter.post('/revive', async (req: Request, res: Response) => {
  try {
    res.json(await reviveStreak(req.user!.id));
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(400).json({ error: msg });
  }
});
