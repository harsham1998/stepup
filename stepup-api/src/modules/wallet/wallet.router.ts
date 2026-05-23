import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { getBalance, getTransactions, createDepositOrder, requestWithdrawal } from './wallet.service';

export const walletRouter = Router();

const depositSchema = z.object({ amount_inr: z.number().min(10).max(50000) });
const withdrawSchema = z.object({
  amount_inr: z.number().min(10).max(100000),
  upi_vpa: z.string().regex(/^[\w.-]+@[\w]+$/, 'Invalid UPI VPA'),
});

walletRouter.get('/balance', async (req: Request, res: Response) => {
  try {
    const data = await getBalance(req.user!.id);
    res.json(data);
  } catch (err: unknown) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

walletRouter.get('/transactions', async (req: Request, res: Response) => {
  try {
    const data = await getTransactions(req.user!.id);
    res.json(data);
  } catch (err: unknown) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

walletRouter.post('/deposit/order', validateBody(depositSchema), async (req: Request, res: Response) => {
  try {
    const order = await createDepositOrder(req.user!.id, req.body.amount_inr);
    res.json(order);
  } catch (err: unknown) {
    res.status(500).json({ error: 'Internal server error' });
  }
});

walletRouter.post('/withdraw', validateBody(withdrawSchema), async (req: Request, res: Response) => {
  try {
    const result = await requestWithdrawal(req.user!.id, req.body.amount_inr, req.body.upi_vpa);
    res.json(result);
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Withdrawal failed' });
  }
});
