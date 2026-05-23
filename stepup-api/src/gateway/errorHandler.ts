import { Request, Response, NextFunction } from 'express';
import { logger } from '../lib/logger';

export function errorHandler(err: Error, req: Request, res: Response, _next: NextFunction): void {
  logger.error({ err, url: req.url, method: req.method }, 'Unhandled error');
  res.status(500).json({ error: 'Internal server error' });
}
