import { Router, Request, Response } from 'express';
import { listChallenges, getChallenge, joinChallenge } from './challenges.service';

export const challengesRouter = Router();

challengesRouter.get('/', async (req: Request, res: Response) => {
  try {
    const status = req.query.status as string | undefined;
    const data = await listChallenges(status);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

challengesRouter.get('/:id', async (req: Request, res: Response) => {
  try {
    const data = await getChallenge(req.params['id'] as string);
    res.json(data);
  } catch {
    res.status(404).json({ error: 'Challenge not found' });
  }
});

challengesRouter.post('/:id/join', async (req: Request, res: Response) => {
  try {
    const result = await joinChallenge(req.user!.id, req.params['id'] as string);
    res.json(result);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    const status = msg.includes('balance') || msg.includes('full') || msg.includes('Already') ? 400 : 500;
    res.status(status).json({ error: msg });
  }
});
