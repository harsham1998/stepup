import { Router, Request, Response, NextFunction } from 'express';
import { getSupabase } from '../../lib/supabase';

export const achievementsRouter = Router();

// GET /achievements — all achievements + which user has earned
achievementsRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.id;
    const [{ data: all, error: e1 }, { data: earned, error: e2 }] = await Promise.all([
      getSupabase().from('achievements').select('*').order('xp_reward'),
      getSupabase().from('user_achievements').select('achievement_id, earned_at').eq('user_id', userId),
    ]);
    if (e1) throw e1;
    if (e2) throw e2;
    const earnedIds = new Set((earned || []).map(e => e.achievement_id));
    const earnedMap = Object.fromEntries((earned || []).map(e => [e.achievement_id, e.earned_at]));
    res.json((all || []).map(a => ({
      ...a,
      earned: earnedIds.has(a.id),
      earned_at: earnedMap[a.id] || null,
    })));
  } catch (err) { next(err); }
});
