import { Router, Request, Response } from 'express';
import { listChallenges, getChallenge, joinChallenge, listMyChallenges, getChallengeProgress } from './challenges.service';
import { getLeaderboard } from './leaderboard.service';

export const challengesRouter = Router();

challengesRouter.get('/mine', async (req: Request, res: Response) => {
  try {
    const data = await listMyChallenges(req.user!.id);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

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

challengesRouter.get('/:id/leaderboard', async (req: Request, res: Response) => {
  try {
    const data = await getLeaderboard(req.params['id'] as string, req.user!.id);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

challengesRouter.get('/:id/progress', async (req: Request, res: Response) => {
  try {
    const data = await getChallengeProgress(req.user!.id, req.params['id'] as string);
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
    let status = 500;
    if (msg.includes('Already')) status = 409;
    else if (msg.includes('balance') || msg.includes('full')) status = 400;
    res.status(status).json({ error: msg });
  }
});
