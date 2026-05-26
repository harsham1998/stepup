import { Router, Request, Response } from 'express';
import { z } from 'zod';
import { validateBody } from '../../gateway/middleware/validate';
import { authMiddleware } from '../../gateway/middleware/auth';
import {
  sendOtp,
  verifyOtp,
  getProfile,
  getProfileSummary,
  getEditProfile,
  upsertProfile,
  updateProfile,
  updateAvatar,
} from './auth.service';

export const authRouter = Router();

const sendOtpSchema = z.object({
  phone: z.string().regex(/^\d{10}$/, 'Must be a 10-digit phone number'),
});

const verifyOtpSchema = z.object({
  phone: z.string().regex(/^\d{10}$/),
  otp: z.string().length(6),
});

// Used during onboarding — city is optional (users often skip it)
const profileSchema = z.object({
  name: z.string().min(1).max(100),
  city: z.string().max(100).optional().default(''),
  language: z.enum(['english', 'hindi', 'telugu', 'tamil', 'kannada']),
  goal_tier: z.enum(['casual', 'active', 'champion', 'elite']),
  avatar_url: z.string().url().optional(),
  onboarding_completed: z.boolean().optional().default(true),
});

// Used by the profile edit screen — all fields optional, partial update
const updateProfileSchema = z.object({
  name: z.string().min(1).max(100).optional(),
  bio: z.string().max(200).optional(),
  city: z.string().max(100).optional(),
  language: z.enum(['english', 'hindi', 'telugu', 'tamil', 'kannada']).optional(),
  dob: z.string().regex(/^\d{4}-\d{2}-\d{2}$/).optional().nullable(),
  height_cm: z.number().int().min(50).max(300).optional().nullable(),
  weight_kg: z.number().min(20).max(500).optional().nullable(),
  sex: z.enum(['male', 'female', 'other', 'prefer_not_to_say']).optional().nullable(),
  units: z.enum(['metric', 'imperial']).optional(),
  fitness_level: z.enum(['beginner', 'intermediate', 'advanced']).optional().nullable(),
  primary_goal: z.enum(['lose_weight', 'build_muscle', 'stay_active', 'endurance']).optional().nullable(),
  step_goal: z.number().int().min(1000).max(50000).optional(),
  preferred_workout_time: z.enum(['morning', 'afternoon', 'evening', 'night']).optional().nullable(),
  workout_days_per_week: z.number().int().min(1).max(7).optional().nullable(),
  activity_types: z.array(z.string()).optional(),
  push_notifications: z.boolean().optional(),
  show_on_leaderboard: z.boolean().optional(),
  profile_visibility: z.enum(['public', 'friends', 'private']).optional(),
});

const avatarSchema = z.object({
  avatar_url: z.string().url(),
});

authRouter.post('/otp/send', validateBody(sendOtpSchema), async (req: Request, res: Response) => {
  try {
    const result = await sendOtp(req.body.phone);
    res.json(result);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Failed to send OTP';
    res.status(500).json({ error: message });
  }
});

authRouter.post('/otp/verify', validateBody(verifyOtpSchema), async (req: Request, res: Response) => {
  try {
    const result = await verifyOtp({ phone: req.body.phone, otp: req.body.otp });
    res.json(result);
  } catch (err) {
    const message = err instanceof Error ? err.message : 'Invalid OTP';
    res.status(401).json({ error: message });
  }
});

authRouter.get('/profile', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const data = await getProfile(userId);
    if (!data) return res.status(404).json({ error: 'Profile not found' });
    res.json(data);
  } catch {
    res.status(500).json({ error: 'Failed to fetch profile' });
  }
});

// Full profile summary for the profile screen
authRouter.get('/profile/summary', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const data = await getProfileSummary(userId);
    if (!data) return res.status(404).json({ error: 'Profile not found' });
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Failed to fetch profile summary' });
  }
});

// All editable fields for the edit screen, including phone/email from auth
authRouter.get('/profile/edit', authMiddleware, async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const data = await getEditProfile(userId);
    res.json(data);
  } catch (err) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Failed to fetch edit profile' });
  }
});

// Onboarding save
authRouter.put('/profile', authMiddleware, validateBody(profileSchema), async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const result = await upsertProfile(userId, req.body);
    res.json(result);
  } catch {
    res.status(500).json({ error: 'Failed to update profile' });
  }
});

// Profile edit screen — partial update
authRouter.patch('/profile', authMiddleware, validateBody(updateProfileSchema), async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const result = await updateProfile(userId, req.body);
    res.json(result);
  } catch (err) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Failed to update profile' });
  }
});

// Called after Flutter uploads the image directly to Supabase Storage
authRouter.patch('/profile/avatar', authMiddleware, validateBody(avatarSchema), async (req: Request, res: Response) => {
  try {
    const userId = (req.user as { id: string }).id;
    const result = await updateAvatar(userId, req.body.avatar_url);
    res.json(result);
  } catch {
    res.status(500).json({ error: 'Failed to update avatar' });
  }
});
