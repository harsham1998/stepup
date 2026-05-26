// stepup-api/src/modules/seasons/seasons.router.ts
import { Router, Request, Response, NextFunction } from 'express';
import { getCurrentSeason, getMySeasonResult, endSeason } from './seasons.service';

export const seasonsRouter = Router();

seasonsRouter.get('/current', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const season = await getCurrentSeason();
    if (!season) return res.status(404).json({ error: 'No active season' });
    res.json(season);
  } catch (err) { next(err); }
});

seasonsRouter.get('/:id/my-result', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const result = await getMySeasonResult(req.user!.id, String(req.params.id));
    if (!result) return res.status(404).json({ error: 'No result for this season' });
    res.json(result);
  } catch (err) { next(err); }
});

// Admin-only: protected by secret header
seasonsRouter.post('/:id/end', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const adminSecret = process.env.ADMIN_SECRET;
    if (adminSecret && req.headers['x-admin-secret'] !== adminSecret) {
      return res.status(403).json({ error: 'Forbidden' });
    }
    const result = await endSeason(String(req.params.id));
    res.json(result);
  } catch (err) { next(err); }
});
