import request from 'supertest';
import express from 'express';
import { leaderboardRouter } from '../../src/modules/leaderboard/leaderboard.router';

const app = express();
app.use(express.json());
app.use((req, _res, next) => { (req as any).user = { id: 'user-123' }; next(); });
app.use('/leaderboard', leaderboardRouter);

jest.mock('../../src/modules/leaderboard/leaderboard.service', () => ({
  getGlobalLeaderboard: jest.fn().mockResolvedValue([
    { rank: 1, user_id: 'u1', name: 'Priya', steps: 18500, city: 'Mumbai' },
    { rank: 2, user_id: 'user-123', name: 'Harsha', steps: 12450, city: 'Hyderabad' },
  ]),
  getFriendsLeaderboard: jest.fn().mockResolvedValue([
    { rank: 1, user_id: 'user-123', name: 'Harsha', steps: 12450, city: 'Hyderabad' },
  ]),
  getCityLeaderboard: jest.fn().mockResolvedValue([]),
  getUserRank: jest.fn().mockResolvedValue({ rank: 2, steps: 12450 }),
}));

describe('GET /leaderboard/global', () => {
  it('returns ranked list with user rank highlighted', async () => {
    const res = await request(app).get('/leaderboard/global');
    expect(res.status).toBe(200);
    expect(res.body.entries).toHaveLength(2);
    expect(res.body.myRank).toEqual({ rank: 2, steps: 12450 });
  });
});

describe('GET /leaderboard/friends', () => {
  it('returns friends-only ranked list', async () => {
    const res = await request(app).get('/leaderboard/friends');
    expect(res.status).toBe(200);
    expect(res.body.entries).toHaveLength(1);
  });
});

describe('GET /leaderboard/city/:city', () => {
  it('returns city leaderboard entries', async () => {
    const res = await request(app).get('/leaderboard/city/Mumbai');
    expect(res.status).toBe(200);
    expect(res.body.entries).toEqual([]);
  });
});
