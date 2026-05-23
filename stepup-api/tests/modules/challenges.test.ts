import request from 'supertest';
import express from 'express';
import { challengesRouter } from '../../src/modules/challenges/challenges.router';

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.user = { id: 'user-123' }; next(); });
app.use('/challenges', challengesRouter);

const mockChallenge = {
  id: 'ch-1', title: 'Weekend Warriors', type: 'paid_pool',
  step_goal: 10000, entry_fee: 5000, prize_pool: 225000,
  status: 'active',
  start_time: new Date().toISOString(),
  end_time: new Date(Date.now() + 86400000).toISOString(),
  max_participants: 100,
  prize_distribution: { platform_fee_percent: 10, tiers: [{ top_percent: 10, share_percent: 90 }] },
};

jest.mock('../../src/modules/challenges/challenges.service', () => ({
  listChallenges: jest.fn().mockResolvedValue([{
    id: 'ch-1', title: 'Weekend Warriors', type: 'paid_pool',
    step_goal: 10000, entry_fee: 5000, prize_pool: 225000,
    status: 'active',
    start_time: new Date().toISOString(),
    end_time: new Date(Date.now() + 86400000).toISOString(),
    max_participants: 100,
    prize_distribution: { platform_fee_percent: 10, tiers: [{ top_percent: 10, share_percent: 90 }] },
  }]),
  getChallenge: jest.fn().mockResolvedValue({
    id: 'ch-1', title: 'Weekend Warriors', type: 'paid_pool',
    step_goal: 10000, entry_fee: 5000, prize_pool: 225000,
    status: 'active',
    start_time: new Date().toISOString(),
    end_time: new Date(Date.now() + 86400000).toISOString(),
    max_participants: 100,
    prize_distribution: { platform_fee_percent: 10, tiers: [{ top_percent: 10, share_percent: 90 }] },
  }),
  joinChallenge: jest.fn().mockResolvedValue({ joined: true, challenge_id: 'ch-1' }),
}));

describe('GET /challenges', () => {
  it('returns challenge list', async () => {
    const res = await request(app).get('/challenges');
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(1);
    expect(res.body[0].title).toBe('Weekend Warriors');
  });
});

describe('GET /challenges/:id', () => {
  it('returns single challenge', async () => {
    const res = await request(app).get('/challenges/ch-1');
    expect(res.status).toBe(200);
    expect(res.body.id).toBe('ch-1');
  });
});

describe('POST /challenges/:id/join', () => {
  it('returns joined result', async () => {
    const res = await request(app).post('/challenges/ch-1/join');
    expect(res.status).toBe(200);
    expect(res.body.joined).toBe(true);
  });
});
