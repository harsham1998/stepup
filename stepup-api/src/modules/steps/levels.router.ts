import { Router, Request, Response, NextFunction } from 'express';
import { getSupabase } from '../../lib/supabase';
import { xpForNextLevel, getLevelTitle } from './xp.service';

export const levelsRouter = Router();

levelsRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.id;
    const { data, error } = await getSupabase()
      .from('user_levels')
      .select('*')
      .eq('user_id', userId)
      .maybeSingle();
    if (error) throw error;
    const row = data || { user_id: userId, xp: 0, level: 1, title: 'Walker' };
    const nextLevelXp = xpForNextLevel(row.level);
    const prevLevelXp = row.level > 1 ? xpForNextLevel(row.level - 1) : 0;
    res.json({
      ...row,
      title: getLevelTitle(row.level),
      xp_for_next_level: nextLevelXp,
      xp_in_current_level: row.xp - prevLevelXp,
      xp_needed: nextLevelXp - row.xp,
    });
  } catch (err) { next(err); }
});
