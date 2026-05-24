import { Router, Request, Response } from 'express';
import { getGlobalLeaderboard, getFriendsLeaderboard, getCityLeaderboard, getUserRank } from './leaderboard.service';

export const leaderboardRouter = Router();

leaderboardRouter.get('/global', async (req: Request, res: Response) => {
  try {
    const [entries, myRank] = await Promise.all([
      getGlobalLeaderboard(),
      getUserRank(req.user!.id),
    ]);
    res.json({ entries, myRank });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

leaderboardRouter.get('/friends', async (req: Request, res: Response) => {
  try {
    const entries = await getFriendsLeaderboard(req.user!.id);
    res.json({ entries });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

// /city/all returns global leaderboard; /city/:city returns city-specific
leaderboardRouter.get('/city/:city', async (req: Request, res: Response) => {
  try {
    const city = req.params['city'] as string;
    const entries = city === 'all'
      ? await getGlobalLeaderboard()
      : await getCityLeaderboard(city);
    res.json({ entries });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});
