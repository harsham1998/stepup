// stepup-api/src/modules/community/community.router.ts
import { Router, Request, Response } from 'express';
import { getFeed, createPost, likePost } from './community.service';

export const communityRouter = Router();

communityRouter.get('/feed', async (req: Request, res: Response) => {
  try {
    const page = parseInt((req.query['page'] as string) ?? '1', 10);
    res.json(await getFeed(req.user!.id, page));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// Canonical create-post endpoint
communityRouter.post('/posts', async (req: Request, res: Response) => {
  try {
    const { type = 'flex', content, visibility = 'everyone', media_urls = [], metadata = {} } = req.body;
    if (!content) return res.status(400).json({ error: 'content required' });
    res.json(await createPost(req.user!.id, type, content, visibility, media_urls, metadata));
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

// Legacy endpoint — kept for backwards compat
communityRouter.post('/flex', async (req: Request, res: Response) => {
  try {
    const { type = 'flex', content, visibility = 'everyone', media_urls = [], metadata = {} } = req.body;
    if (!content) return res.status(400).json({ error: 'content required' });
    res.json(await createPost(req.user!.id, type, content, visibility, media_urls, metadata));
  } catch (err: unknown) {
    res.status(400).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});

communityRouter.post('/posts/:id/like', async (req: Request, res: Response) => {
  try {
    res.json(await likePost(req.user!.id, req.params['id'] as string));
  } catch (err: unknown) {
    res.status(500).json({ error: err instanceof Error ? err.message : 'Internal error' });
  }
});
