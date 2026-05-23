import { Request, Response, NextFunction } from 'express';
import { getSupabase } from '../../lib/supabase';

export async function authMiddleware(req: Request, res: Response, next: NextFunction): Promise<void> {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'Missing authorization header' });
    return;
  }
  const token = header.slice(7);
  const { data, error } = await getSupabase().auth.getUser(token);
  if (error || !data.user) {
    res.status(401).json({ error: 'Invalid or expired token' });
    return;
  }
  req.user = {
    id: data.user.id,
    email: data.user.email ?? undefined,
    phone: data.user.phone ?? undefined,
  };
  next();
}
