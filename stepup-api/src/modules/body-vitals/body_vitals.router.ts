// stepup-api/src/modules/body-vitals/body_vitals.router.ts
import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { logVitals, getHistory, getSummary, setGoal } from './body_vitals.service';

export const bodyVitalsRouter = Router();

const logSchema = z.object({
  weight_kg:          z.number().positive().max(500).optional(),
  bmi:                z.number().positive().max(100).optional(),
  visceral_fat_level: z.number().int().min(1).max(30).optional(),
  muscle_percentage:  z.number().min(0).max(100).optional(),
}).refine(
  d => Object.values(d).some(v => v !== undefined),
  { message: 'At least one vital must be provided' },
);

const goalSchema = z.object({
  goal_weight_kg: z.number().positive().max(500).optional(),
  goal_bmi:       z.number().positive().max(100).optional(),
});

bodyVitalsRouter.post('/log', validateBody(logSchema), async (req: Request, res: Response) => {
  try {
    res.json(await logVitals(req.user!.id, req.body));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

bodyVitalsRouter.get('/history', async (req: Request, res: Response) => {
  try {
    const days = Math.min(Number(req.query.days ?? 42), 365);
    res.json(await getHistory(req.user!.id, days));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

bodyVitalsRouter.get('/summary', async (req: Request, res: Response) => {
  try {
    res.json(await getSummary(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

bodyVitalsRouter.put('/goal', validateBody(goalSchema), async (req: Request, res: Response) => {
  try {
    res.json(await setGoal(req.user!.id, req.body));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
