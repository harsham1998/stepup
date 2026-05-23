// Capture mocks in module scope so they survive jest.mock hoisting
let mockInsert: jest.Mock;
let mockUpdate: jest.Mock;
let mockUpdateChain: { eq: jest.Mock; error: null };
let mockSingle: jest.Mock;

jest.mock('../../src/lib/supabase', () => {
  // These are re-initialised before each test via beforeEach; we create them
  // here so the factory closure captures the same references.
  mockInsert = jest.fn().mockResolvedValue({ error: null });
  mockUpdateChain = {
    eq: jest.fn().mockReturnThis(),
    error: null,
  };
  // attach a resolved-value shim so `await ...update(...).eq(...).eq(...)` works
  (mockUpdateChain as any).then = undefined; // not a thenable itself
  mockUpdate = jest.fn().mockReturnValue({
    eq: jest.fn().mockReturnValue({
      eq: jest.fn().mockResolvedValue({ error: null }),
    }),
  });

  mockSingle = jest.fn().mockResolvedValue({
    data: {
      id: 'ch-1',
      prize_pool: 90000,
      status: 'ended',
      prize_distribution: {
        platform_fee_percent: 10,
        tiers: [{ top_percent: 50, share_percent: 90 }],
      },
    },
    error: null,
  });

  return {
    getSupabase: () => ({
      from: jest.fn().mockImplementation((_table: string) => ({
        select: jest.fn().mockReturnThis(),
        eq: jest.fn().mockReturnThis(),
        single: mockSingle,
        update: mockUpdate,
        insert: mockInsert,
      })),
    }),
  };
});

jest.mock('../../src/lib/redis', () => ({
  getRedis: () => ({
    zrevrange: jest.fn().mockResolvedValue(['u1', '15000', 'u2', '12000']),
  }),
}));

import { processPayout } from '../../src/modules/challenges/payout.job';

describe('processPayout', () => {
  beforeEach(() => {
    jest.clearAllMocks();
    // Reset insert mock to its default success behaviour after clearAllMocks
    mockInsert.mockResolvedValue({ error: null });
    mockUpdate.mockReturnValue({
      eq: jest.fn().mockReturnValue({
        eq: jest.fn().mockResolvedValue({ error: null }),
      }),
    });
  });

  it('credits top 50% winner with correct amount', async () => {
    await processPayout('ch-1');

    // 2 participants, top 50% = 1 winner (u1)
    // prize_pool=90000, platform_fee=9000, distributable=81000
    // tier: top 50% gets 90% of distributable = 72900
    // 1 winner gets floor(72900/1) = 72900
    expect(mockInsert).toHaveBeenCalledTimes(1);
    expect(mockInsert).toHaveBeenCalledWith(
      expect.arrayContaining([
        expect.objectContaining({
          user_id: 'u1',
          type: 'credit',
          amount: 72900,
          idempotency_key: 'payout:ch-1:u1',
        }),
      ])
    );
  });

  it('skips processing if challenge is already paid_out', async () => {
    mockSingle.mockResolvedValueOnce({
      data: {
        id: 'ch-1',
        prize_pool: 90000,
        status: 'paid_out',
        prize_distribution: {
          platform_fee_percent: 10,
          tiers: [{ top_percent: 50, share_percent: 90 }],
        },
      },
      error: null,
    });

    await processPayout('ch-1');

    // Should have returned early — no wallet inserts should occur
    expect(mockInsert).not.toHaveBeenCalled();
  });
});
