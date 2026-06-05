// stepup-api/src/modules/friends/friends.router.ts
import { Router, Request, Response } from 'express';
import {
  listFriends, searchUsers, getFriendRequests,
  sendFriendRequest, respondToRequest, removeFriend,
  checkUsernameAvailable,
} from './friends.service';
import { notifyUser } from '../notifications/notifications.service';
import { getSupabase } from '../../lib/supabase';

export const friendsRouter = Router();

// GET /friends/check-username?q=foo
friendsRouter.get('/check-username', async (req: Request, res: Response) => {
  try {
    const q = ((req.query['q'] as string) ?? '').toLowerCase().trim();
    if (!/^[a-z0-9_]{3,20}$/.test(q)) return res.json({ available: false, reason: 'invalid_format' });
    const available = await checkUsernameAvailable(q, req.user!.id);
    res.json({ available });
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// GET /friends/search?q=username
friendsRouter.get('/search', async (req: Request, res: Response) => {
  try {
    const q = (req.query['q'] as string ?? '').trim();
    if (q.length < 2) return res.json([]);
    const results = await searchUsers(q, req.user!.id);
    res.json(results);
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// GET /friends/requests
friendsRouter.get('/requests', async (req: Request, res: Response) => {
  try {
    res.json(await getFriendRequests(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// GET /friends
friendsRouter.get('/', async (req: Request, res: Response) => {
  try {
    res.json(await listFriends(req.user!.id));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// POST /friends/requests  body: { receiver_id }
friendsRouter.post('/requests', async (req: Request, res: Response) => {
  try {
    const { receiver_id } = req.body as { receiver_id?: string };
    if (!receiver_id || !/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(receiver_id)) {
      return res.status(400).json({ error: 'receiver_id must be a valid UUID' });
    }
    await sendFriendRequest(req.user!.id, receiver_id);

    const { data: sender } = await getSupabase()
      .from('users').select('name, username').eq('id', req.user!.id).maybeSingle();
    const label = sender?.username ? `@${sender.username}` : (sender?.name ?? 'Someone');
    notifyUser(receiver_id, 'Friend Request', `${label} sent you a friend request`).catch(() => {});

    res.status(201).json({ ok: true });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status((err as any).statusCode ?? 500).json({ error: msg });
  }
});

// PATCH /friends/requests/:id  body: { action: 'accept' | 'decline' }
friendsRouter.patch('/requests/:id', async (req: Request, res: Response) => {
  try {
    const { action } = req.body as { action?: 'accept' | 'decline' };
    if (action !== 'accept' && action !== 'decline') {
      return res.status(400).json({ error: 'action must be accept or decline' });
    }
    const { sender_id } = await respondToRequest(req.params['id'] as string, req.user!.id, action);

    if (action === 'accept') {
      const { data: accepter } = await getSupabase()
        .from('users').select('name, username').eq('id', req.user!.id).maybeSingle();
      const label = accepter?.username ? `@${accepter.username}` : (accepter?.name ?? 'Someone');
      notifyUser(sender_id, 'Friend Request Accepted', `${label} accepted your friend request 🎉`).catch(() => {});
    }

    res.json({ ok: true });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : 'Internal error';
    res.status((err as any).statusCode ?? 500).json({ error: msg });
  }
});

// DELETE /friends/:friendId
friendsRouter.delete('/:friendId', async (req: Request, res: Response) => {
  try {
    await removeFriend(req.user!.id, req.params['friendId'] as string);
    res.json({ ok: true });
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
