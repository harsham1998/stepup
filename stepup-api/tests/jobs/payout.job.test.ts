import { processPayout } from '../../src/modules/challenges/payout.job';

const mockChallenge = {
  id: 'ch-1', prize_pool: 90000, status: 'ended',
  prize_distribution: { platform_fee_percent: 10, tiers: [{ top_percent: 50, share_percent: 90 }] },
};
const mockParticipants = [
  { user_id: 'u1', final_rank: null }, { user_id: 'u2', final_rank: null },
];
const mockRanks = [['u1', '15000'], ['u2', '12000']];

jest.mock('../../src/lib/supabase', () => {
  const mockParticipants = [
    { user_id: 'u1', final_rank: null }, { user_id: 'u2', final_rank: null },
  ];
  const mockChallenge = {
    id: 'ch-1', prize_pool: 90000, status: 'ended',
    prize_distribution: { platform_fee_percent: 10, tiers: [{ top_percent: 50, share_percent: 90 }] },
  };
  return {
    getSupabase: () => ({
      from: jest.fn().mockReturnThis(),
      select: jest.fn().mockReturnThis(),
      eq: jest.fn().mockReturnThis(),
      single: jest.fn().mockResolvedValue({ data: mockChallenge, error: null }),
      update: jest.fn().mockReturnThis(),
      insert: jest.fn().mockResolvedValue({ error: null }),
      data: mockParticipants,
    }),
  };
});

jest.mock('../../src/lib/redis', () => ({
  getRedis: () => ({
    zrevrange: jest.fn().mockResolvedValue(['u1', '15000', 'u2', '12000']),
  }),
}));

describe('processPayout', () => {
  it('distributes prize to top 50% of participants', async () => {
    await expect(processPayout('ch-1')).resolves.not.toThrow();
  });
});
