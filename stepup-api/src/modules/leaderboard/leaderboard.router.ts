import { Router, Request, Response } from 'express';
import { getGlobalLeaderboard, getFriendsLeaderboard, getCityLeaderboard, getUserRank } from './leaderboard.service';

export const leaderboardRouter = Router();

leaderboardRouter.get('/global', async (req: Request, res: Response) => {
  const [entries, myRank] = await Promise.all([
    getGlobalLeaderboard(),
    getUserRank(req.user!.id),
  ]);
  res.json({ entries, myRank });
});

leaderboardRouter.get('/friends', async (req: Request, res: Response) => {
  const entries = await getFriendsLeaderboard(req.user!.id);
  res.json({ entries });
});

leaderboardRouter.get('/city/:city', async (req: Request, res: Response) => {
  const entries = await getCityLeaderboard(req.params['city'] as string);
  res.json({ entries });
});
