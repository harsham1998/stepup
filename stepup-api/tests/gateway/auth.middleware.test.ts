import request from 'supertest';
import express from 'express';
import { authMiddleware } from '../../src/gateway/middleware/auth';

const app = express();
app.use(authMiddleware);
app.get('/test', (req, res) => res.json({ userId: req.user?.id }));

jest.mock('../../src/lib/supabase', () => ({
  getSupabase: () => ({
    auth: {
      getUser: jest.fn().mockImplementation((token: string) => {
        if (token === 'valid-token') {
          return { data: { user: { id: 'user-123', email: 'test@test.com', phone: null } }, error: null };
        }
        return { data: { user: null }, error: { message: 'Invalid token' } };
      }),
    },
  }),
}));

describe('authMiddleware', () => {
  it('returns 401 when Authorization header is missing', async () => {
    const res = await request(app).get('/test');
    expect(res.status).toBe(401);
  });

  it('returns 401 when token is invalid', async () => {
    const res = await request(app).get('/test').set('Authorization', 'Bearer bad-token');
    expect(res.status).toBe(401);
  });

  it('sets req.user and calls next when token is valid', async () => {
    const res = await request(app).get('/test').set('Authorization', 'Bearer valid-token');
    expect(res.status).toBe(200);
    expect(res.body.userId).toBe('user-123');
  });
});
