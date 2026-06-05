import { Router, Request, Response } from 'express';
import { listChallenges, getChallenge, joinChallenge, listMyChallenges, getChallengeProgress, endExpiredChallenges } from './challenges.service';
import { getLeaderboard } from './leaderboard.service';
import { processPayout } from './payout.job';
import { getSupabase } from '../../lib/supabase';
import { notifyUser } from '../notifications/notifications.service';

export const challengesRouter = Router();

challengesRouter.get('/mine', async (req: Request, res: Response) => {
  try {
    const data = await listMyChallenges(req.user!.id);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

challengesRouter.get('/', async (req: Request, res: Response) => {
  try {
    const status = req.query.status as string | undefined;
    const data = await listChallenges(status);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

challengesRouter.get('/:id/leaderboard', async (req: Request, res: Response) => {
  try {
    let friendIds: string[] | undefined;
    if (req.query['filter'] === 'friends') {
      const { getFriendIds } = await import('../friends/friends.service');
      friendIds = await getFriendIds(req.user!.id);
    }
    const data = await getLeaderboard(req.params['id'] as string, req.user!.id, friendIds);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

challengesRouter.get('/:id/progress', async (req: Request, res: Response) => {
  try {
    const data = await getChallengeProgress(req.user!.id, req.params['id'] as string);
    res.json(data);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status(500).json({ error: msg });
  }
});

challengesRouter.get('/:id', async (req: Request, res: Response) => {
  try {
    const data = await getChallenge(req.params['id'] as string);
    res.json(data);
  } catch {
    res.status(404).json({ error: 'Challenge not found' });
  }
});

function requireAdmin(req: Request, res: Response): boolean {
  const secret = req.headers['x-admin-secret'];
  if (!secret || secret !== process.env.ADMIN_SECRET) {
    res.status(403).json({ error: 'Admin only' });
    return false;
  }
  return true;
}

// Admin: end all expired challenges + queue payouts
challengesRouter.post('/admin/end-expired', async (req: Request, res: Response) => {
  if (!requireAdmin(req, res)) return;
  try {
    await endExpiredChallenges();
    res.json({ ok: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// Admin: directly run payout for a specific challenge (end it first if needed)
challengesRouter.post('/admin/payout/:id', async (req: Request, res: Response) => {
  if (!requireAdmin(req, res)) return;
  const db = getSupabase();
  try {
    await db.from('challenges').update({ status: 'ended' })
      .eq('id', req.params['id']).eq('status', 'active');
    await processPayout(req.params['id'] as string);
    res.json({ ok: true });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

challengesRouter.post('/:id/join', async (req: Request, res: Response) => {
  try {
    const result = await joinChallenge(req.user!.id, req.params['id'] as string);
    res.json(result);
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    let status = 500;
    if (msg.includes('Already')) status = 409;
    else if (msg.includes('balance') || msg.includes('full')) status = 400;
    res.status(status).json({ error: msg });
  }
});

// POST /challenges/:id/invite  body: { friend_ids: string[] }
challengesRouter.post('/:id/invite', async (req: Request, res: Response) => {
  try {
    const { friend_ids } = req.body as { friend_ids?: string[] };
    if (!Array.isArray(friend_ids) || friend_ids.length === 0) {
      return res.status(400).json({ error: 'friend_ids required' });
    }
    const db = getSupabase();
    const [{ data: challenge }, { data: sender }] = await Promise.all([
      db.from('challenges').select('title').eq('id', req.params['id']!).maybeSingle(),
      db.from('users').select('name, username').eq('id', req.user!.id).maybeSingle(),
    ]);
    const label = sender?.username ? `@${sender.username}` : (sender?.name ?? 'Someone');
    const title = challenge?.title ?? 'a challenge';
    await Promise.all(
      friend_ids.map(fid =>
        notifyUser(fid, 'Challenge Invite', `${label} invited you to join "${title}" 🏆`).catch(() => {})
      )
    );
    res.json({ ok: true, invited: friend_ids.length });
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
