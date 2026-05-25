import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { getSupabase } from '../../lib/supabase';

export const activitiesRouter = Router();

const logSchema = z.object({
  activity_type: z.enum(['gym', 'yoga', 'sport', 'run', 'cycle', 'walk', 'mindfulness']),
  duration_minutes: z.number().int().min(1).max(600),
  intensity: z.enum(['low', 'medium', 'high']).optional(),
  calories_burned: z.number().int().optional(),
  notes: z.string().max(500).optional(),
  date: z.string().optional(), // ISO date string, defaults to today
});

// GET /activities?date=YYYY-MM-DD
activitiesRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.id;
    const date = (req.query.date as string) || new Date().toISOString().split('T')[0];
    const { data, error } = await getSupabase()
      .from('activities')
      .select('*')
      .eq('user_id', userId)
      .eq('date', date)
      .order('logged_at', { ascending: false });
    if (error) throw error;
    res.json(data);
  } catch (err) { next(err); }
});

// GET /activities/summary — today's summary per activity type
activitiesRouter.get('/summary', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.id;
    const date = (req.query.date as string) || new Date().toISOString().split('T')[0];
    const { data, error } = await getSupabase()
      .from('activities')
      .select('activity_type, duration_minutes, calories_burned')
      .eq('user_id', userId)
      .eq('date', date);
    if (error) throw error;
    // Group by type
    const summary: Record<string, { sessions: number; duration: number; calories: number }> = {};
    for (const row of (data || [])) {
      if (!summary[row.activity_type]) summary[row.activity_type] = { sessions: 0, duration: 0, calories: 0 };
      summary[row.activity_type].sessions++;
      summary[row.activity_type].duration += row.duration_minutes || 0;
      summary[row.activity_type].calories += row.calories_burned || 0;
    }
    res.json(summary);
  } catch (err) { next(err); }
});

// POST /activities
activitiesRouter.post('/', validateBody(logSchema), async (req: Request, res: Response, next: NextFunction) => {
  try {
    const userId = req.user!.id;
    const body = req.body;
    const date = body.date || new Date().toISOString().split('T')[0];
    const { data, error } = await getSupabase()
      .from('activities')
      .insert({ ...body, user_id: userId, date })
      .select()
      .single();
    if (error) throw error;
    res.status(201).json(data);
  } catch (err) { next(err); }
});
