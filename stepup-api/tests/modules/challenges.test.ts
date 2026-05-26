import request from 'supertest';
import express from 'express';
import { challengesRouter } from '../../src/modules/challenges/challenges.router';

const app = express();
app.use(express.json());
app.use((req, _res, next) => { req.user = { id: 'user-123' }; next(); });
app.use('/challenges', challengesRouter);

jest.mock('../../src/modules/challenges/leaderboard.service', () => ({
  getLeaderboard: jest.fn().mockResolvedValue({
    your_rank: 4,
    total: 142,
    updated_at: new Date().toISOString(),
    participants: [
      { rank: 1, user_id: 'u-1', display_name: 'Alex M.', avatar_url: null, current: 9800, xp_earned: 300 },
      { rank: 4, user_id: 'user-123', display_name: 'You', avatar_url: null, current: 6200, xp_earned: 150 },
    ],
  }),
}));

jest.mock('../../src/modules/challenges/challenges.service', () => ({
  listChallenges: jest.fn().mockResolvedValue([{
    id: 'ch-1', title: 'Weekend Warriors', type: 'paid_pool',
    mode: 'individual',
    step_goal: 10000, entry_fee: 5000, prize_pool: 225000,
    status: 'active',
    start_time: new Date().toISOString(),
    end_time: new Date(Date.now() + 86400000).toISOString(),
    max_participants: 100,
    prize_distribution: { platform_fee_percent: 10, tiers: [{ top_percent: 10, share_percent: 90 }] },
    missions: [],
    prize_tiers: [],
  }]),
  getChallenge: jest.fn().mockResolvedValue({
    id: 'ch-1', title: 'Weekend Warriors', type: 'paid_pool',
    mode: 'individual',
    step_goal: 10000, entry_fee: 5000, prize_pool: 225000,
    status: 'active',
    start_time: new Date().toISOString(),
    end_time: new Date(Date.now() + 86400000).toISOString(),
    max_participants: 100,
    prize_distribution: { platform_fee_percent: 10, tiers: [{ top_percent: 10, share_percent: 90 }] },
    missions: [
      { id: 'm-1', mission_id: 'm-1', title: 'Walk 10k Steps', bonus_xp: 50, xp_reward: 100, target: 10000, unit: 'steps', type: 'daily', description: '' },
    ],
    prize_tiers: [{ top_percent: 10, label: 'Top 10%', coins: 20 }],
  }),
  joinChallenge: jest.fn().mockResolvedValue({ joined: true, challenge_id: 'ch-1' }),
  listMyChallenges: jest.fn().mockResolvedValue([]),
  getChallengeProgress: jest.fn().mockResolvedValue({
    joined: true,
    current: 6200, goal: 10000, percent: 0.62,
    totalDays: 2, daysPassed: 1, daysLeft: 1, dailyGoal: 5000,
    completedToday: false, dailyCheckins: [true],
    rank: 4, totalParticipants: 142,
    activityType: 'steps', prizePool: 22500,
    mission_progress: [
      {
        mission_id: 'm-1', title: 'Walk 10,000 Steps',
        target: 10000, current: 6200, unit: 'steps',
        completed: false, xp_earned: 0, total_xp: 150,
      },
    ],
  }),
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

  it('includes missions and prize_tiers in challenge detail', async () => {
    const res = await request(app).get('/challenges/ch-1');
    expect(res.status).toBe(200);
    expect(res.body.mode).toBe('individual');
    expect(Array.isArray(res.body.missions)).toBe(true);
    expect(res.body.missions[0]).toMatchObject({ bonus_xp: 50, xp_reward: 100 });
    expect(Array.isArray(res.body.prize_tiers)).toBe(true);
  });
});

describe('POST /challenges/:id/join', () => {
  it('returns joined result', async () => {
    const res = await request(app).post('/challenges/ch-1/join');
    expect(res.status).toBe(200);
    expect(res.body.joined).toBe(true);
  });
});

describe('GET /challenges/:id/progress', () => {
  it('returns mission_progress array', async () => {
    const res = await request(app).get('/challenges/ch-1/progress');
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body.mission_progress)).toBe(true);
    expect(res.body.mission_progress[0]).toMatchObject({
      mission_id: expect.any(String),
      total_xp: expect.any(Number),
    });
  });
});

describe('GET /challenges/:id/leaderboard', () => {
  it('returns leaderboard with your_rank', async () => {
    const res = await request(app).get('/challenges/ch-1/leaderboard');
    expect(res.status).toBe(200);
    expect(typeof res.body.your_rank).toBe('number');
    expect(Array.isArray(res.body.participants)).toBe(true);
    expect(res.body.participants[0]).toMatchObject({ rank: 1, display_name: expect.any(String) });
  });
});
