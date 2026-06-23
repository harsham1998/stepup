// stepup-api/src/modules/gym/gym.router.ts
import { Router, Request, Response } from 'express';
import {
  getWeekPlan,
  getOrCreateSession,
  logSet,
  deleteSet,
  completeSession,
  getExerciseHistory,
  getGymStats,
  getSessionHistory,
} from './gym.service';

export const gymRouter = Router();

// GET /gym/week
gymRouter.get('/week', async (req: Request, res: Response) => {
  try {
    res.json(await getWeekPlan(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// GET /gym/session/:date  (date = yyyy-mm-dd)
gymRouter.get('/session/:date', async (req: Request, res: Response) => {
  try {
    const date = req.params['date'] as string;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(date)) return res.status(400).json({ error: 'Invalid date' });
    res.json(await getOrCreateSession(req.user!.id, date));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// POST /gym/session/:sessionId/sets
// body: { exercise_id, set_number, weight_kg?, reps?, duration_secs? }
gymRouter.post('/session/:sessionId/sets', async (req: Request, res: Response) => {
  try {
    const sessionId = req.params['sessionId'] as string;
    const { exercise_id, set_number, weight_kg, reps, duration_secs } = req.body as {
      exercise_id: string;
      set_number: number;
      weight_kg?: number;
      reps?: number;
      duration_secs?: number;
    };
    if (!exercise_id || !set_number) return res.status(400).json({ error: 'exercise_id and set_number required' });
    const log = await logSet(req.user!.id, sessionId, exercise_id, set_number, weight_kg ?? null, reps ?? null, duration_secs ?? null);
    res.json(log);
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// DELETE /gym/session/:sessionId/sets/:exerciseId/:setNumber
gymRouter.delete('/session/:sessionId/sets/:exerciseId/:setNumber', async (req: Request, res: Response) => {
  try {
    const { sessionId, exerciseId, setNumber } = req.params as { sessionId: string; exerciseId: string; setNumber: string };
    await deleteSet(req.user!.id, sessionId, exerciseId, parseInt(setNumber, 10));
    res.json({ ok: true });
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// POST /gym/session/:sessionId/complete
gymRouter.post('/session/:sessionId/complete', async (req: Request, res: Response) => {
  try {
    const result = await completeSession(req.user!.id, req.params['sessionId'] as string);
    res.json(result);
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// GET /gym/stats
gymRouter.get('/stats', async (req: Request, res: Response) => {
  try {
    res.json(await getGymStats(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// GET /gym/history?weeks=8
gymRouter.get('/history', async (req: Request, res: Response) => {
  try {
    const weeks = Math.min(parseInt((req.query['weeks'] as string) ?? '8', 10), 52);
    res.json(await getSessionHistory(req.user!.id, isNaN(weeks) ? 8 : weeks));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// GET /gym/exercise/:exerciseId/history
gymRouter.get('/exercise/:exerciseId/history', async (req: Request, res: Response) => {
  try {
    res.json(await getExerciseHistory(req.user!.id, req.params['exerciseId'] as string));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
