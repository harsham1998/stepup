// stepup-api/src/modules/leagues/leagues.router.ts
import { Router, Request, Response } from 'express';
import { getMyLeague, getStandings } from './leagues.service';

export const leaguesRouter = Router();

leaguesRouter.get('/me', async (req: Request, res: Response) => {
  try {
    const data = await getMyLeague(req.user!.id);
    res.json(data);
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

leaguesRouter.get('/standings', async (req: Request, res: Response) => {
  try {
    const page = parseInt((req.query['page'] as string) ?? '1', 10);
    const data = await getStandings(req.user!.id, page);
    res.json(data);
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
