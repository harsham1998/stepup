// stepup-api/src/modules/reputation/reputation.router.ts
import { Router, Request, Response, NextFunction } from 'express';
import { calculateReputation } from './reputation.service';

export const reputationRouter = Router();

reputationRouter.get('/', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const data = await calculateReputation(req.user!.id);
    res.json(data);
  } catch (err) { next(err); }
});
