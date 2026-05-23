import { Request, Response, NextFunction } from 'express';
import { getRedis } from '../../lib/redis';

const WINDOW_SECONDS = 60;
const MAX_REQUESTS = 100;

export async function rateLimitMiddleware(req: Request, res: Response, next: NextFunction): Promise<void> {
  const userId = req.user?.id ?? req.ip;
  const key = `rate:${userId}`;
  const redis = getRedis();
  const current = await redis.incr(key);
  if (current === 1) await redis.expire(key, WINDOW_SECONDS);
  if (current > MAX_REQUESTS) {
    res.status(429).json({ error: 'Rate limit exceeded. Try again in a minute.' });
    return;
  }
  next();
}
