import { Router, Request, Response, NextFunction } from 'express';
import { getSupabase } from '../../lib/supabase';

export const levelsRouter = Router();

const LEVEL_TITLES: Record<number, string> = {
  1: 'Walker', 10: 'Mover', 20: 'Challenger', 35: 'Athlete', 50: 'Elite', 75: 'Legend', 100: 'Immortal'
};

function getLevelTitle(level: number): string {
  const breakpoints = [100, 75, 50, 35, 20, 10, 1];
  for (const bp of breakpoints) {
    if (level >= bp) return LEVEL_TITLES[bp];
  }
  return 'Walker';
}

function xpForNextLevel(level: number): number {
  return Math.floor(1000 * Math.pow(1.15, level - 1));
}

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
