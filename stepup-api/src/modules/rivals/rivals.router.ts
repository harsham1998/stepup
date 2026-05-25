// stepup-api/src/modules/rivals/rivals.router.ts
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { getRivals, addRival, removeRival, getBattles, createBattle, respondToBattle } from './rivals.service';

export const rivalsRouter = Router();

rivalsRouter.get('/', async (req: Request, res: Response) => {
  try {
    res.json(await getRivals(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

rivalsRouter.post('/:rivalId', async (req: Request, res: Response) => {
  try {
    res.json(await addRival(req.user!.id, req.params['rivalId'] as string));
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(msg.includes('Already') ? 409 : 400).json({ error: msg });
  }
});

rivalsRouter.delete('/:rivalId', async (req: Request, res: Response) => {
  try {
    res.json(await removeRival(req.user!.id, req.params['rivalId'] as string));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

rivalsRouter.get('/battles', async (req: Request, res: Response) => {
  try {
    res.json(await getBattles(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

const battleSchema = z.object({
  opponent_id: z.string().uuid(),
  duration_days: z.number().int().min(1).max(30).default(7),
  coin_wager: z.number().int().min(0).max(10000).default(0),
});

rivalsRouter.post('/battles', validateBody(battleSchema), async (req: Request, res: Response) => {
  try {
    const { opponent_id, duration_days, coin_wager } = req.body;
    res.json(await createBattle(req.user!.id, opponent_id, duration_days, coin_wager));
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

rivalsRouter.post('/battles/:id/respond', validateBody(z.object({ accept: z.boolean() })), async (req: Request, res: Response) => {
  try {
    res.json(await respondToBattle(req.user!.id, req.params['id'] as string, req.body.accept));
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
