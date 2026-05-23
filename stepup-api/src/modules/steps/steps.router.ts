import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { syncSteps } from './steps.service';

export const stepsRouter = Router();

const syncSchema = z.object({
  steps: z.number().int().min(0).max(50000),
  syncedAt: z.string().datetime(),
  source: z.enum(['healthkit', 'health_connect', 'manual']),
  deviceModel: z.string().min(1),
  osVersion: z.string().min(1),
});

stepsRouter.post('/sync', validateBody(syncSchema), async (req: Request, res: Response) => {
  try {
    const result = await syncSteps(req.user!.id, req.body);
    res.json(result);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});
