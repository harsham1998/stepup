// stepup-api/src/modules/challenges/custom.router.ts
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { createCustomChallenge, getByShareCode, inviteFriends } from './custom.service';

export const customChallengesRouter = Router();

const createSchema = z.object({
  title: z.string().min(3).max(100),
  activity: z.enum(['walk', 'gym', 'yoga', 'run', 'cycle', 'sport']),
  difficulty: z.enum(['easy', 'medium', 'hard']),
  duration_days: z.number().int().min(1).max(30),
  frequency: z.string().max(50).default(''),
});

customChallengesRouter.post('/', validateBody(createSchema), async (req: Request, res: Response) => {
  try {
    res.json(await createCustomChallenge(req.user!.id, req.body));
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

customChallengesRouter.get('/:code', async (req: Request, res: Response) => {
  try {
    res.json(await getByShareCode(req.params['code'] as string));
  } catch (err: unknown) {
    res.status(404).json({ error: 'Challenge not found' });
  }
});

customChallengesRouter.post('/:id/invite', async (req: Request, res: Response) => {
  try {
    const { user_ids } = req.body;
    if (!Array.isArray(user_ids) || user_ids.length === 0) {
      return res.status(400).json({ error: 'user_ids required' });
    }
    res.json(await inviteFriends(req.params['id'] as string, req.user!.id, user_ids));
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
