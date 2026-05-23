import { Router, Request, Response } from 'express';
import crypto from 'crypto';
import { creditWallet } from './wallet.service';
import { logger } from '../../lib/logger';

export const razorpayWebhookRouter = Router();

razorpayWebhookRouter.post('/', async (req: Request, res: Response) => {
  const secret = process.env.RAZORPAY_WEBHOOK_SECRET!;
  const signature = req.headers['x-razorpay-signature'] as string;
  const body = req.body as Buffer;

  const expectedSig = crypto.createHmac('sha256', secret).update(body).digest('hex');
  if (signature !== expectedSig) {
    res.status(400).json({ error: 'Invalid signature' });
    return;
  }

  const event = JSON.parse(body.toString());
  if (event.event === 'payment.captured') {
    const payment = event.payload.payment.entity;
    const userId = payment.notes?.user_id;
    if (!userId) { res.json({ ok: true }); return; }

    await creditWallet(userId, payment.amount, payment.id, 'Wallet deposit via Razorpay');
    logger.info({ userId, amount: payment.amount }, 'Wallet credited via webhook');
  }

  res.json({ ok: true });
});
