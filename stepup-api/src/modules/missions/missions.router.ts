// stepup-api/src/modules/missions/missions.router.ts
import { Router, Request, Response } from 'express';
import { getMissions, completeHealthMission } from './missions.service';

export const missionsRouter = Router();

missionsRouter.get('/daily', async (req: Request, res: Response) => {
  try {
    const data = await getMissions(req.user!.id, 'daily');
    res.json(data);
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

missionsRouter.get('/weekly', async (req: Request, res: Response) => {
  try {
    const data = await getMissions(req.user!.id, 'weekly');
    res.json(data);
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

missionsRouter.get('/seasonal', async (req: Request, res: Response) => {
  try {
    const data = await getMissions(req.user!.id, 'seasonal');
    res.json(data);
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

missionsRouter.post('/health/complete', async (req: Request, res: Response) => {
  try {
    const { missionId } = req.body as { missionId: string };
    const result = await completeHealthMission(req.user!.id, missionId);
    res.json(result);
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
