import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { sendOtp, verifyOtp, upsertProfile } from './auth.service';

export const authRouter = Router();

const sendOtpSchema = z.object({
  phone: z.string().regex(/^\d{10}$/, 'Must be a 10-digit phone number'),
});

const verifyOtpSchema = z.object({
  phone: z.string().regex(/^\d{10}$/),
  otp: z.string().length(4),
});

const profileSchema = z.object({
  name: z.string().min(1).max(100),
  city: z.string().min(1).max(100),
  language: z.enum(['english', 'hindi', 'telugu', 'tamil', 'kannada']),
  goal_tier: z.enum(['casual', 'active', 'champion', 'elite']),
});

authRouter.post('/otp/send', validateBody(sendOtpSchema), async (req: Request, res: Response) => {
  try {
    const result = await sendOtp(req.body.phone);
    res.json(result);
  } catch {
    res.status(500).json({ error: 'Failed to send OTP' });
  }
});

authRouter.post('/otp/verify', validateBody(verifyOtpSchema), async (req: Request, res: Response) => {
  try {
    const result = await verifyOtp({ phone: req.body.phone, otp: req.body.otp });
    res.json(result);
  } catch {
    res.status(401).json({ error: 'Invalid OTP' });
  }
});

authRouter.put('/profile', validateBody(profileSchema), async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const result = await upsertProfile(userId, req.body);
    res.json(result);
  } catch {
    res.status(500).json({ error: 'Failed to update profile' });
  }
});
