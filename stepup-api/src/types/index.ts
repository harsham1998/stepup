export interface AuthUser {
  id: string;
  email?: string;
  phone?: string;
}

export interface StepSyncPayload {
  steps: number;
  syncedAt: string;       // ISO8601
  source: 'healthkit' | 'health_connect' | 'manual';
  deviceModel: string;
  osVersion: string;
}

export interface ChallengeRow {
  id: string;
  title: string;
  type: 'free_daily' | 'free_weekly' | 'paid_pool' | 'sponsored' | 'team' | 'city';
  step_goal: number;
  entry_fee: number;
  prize_pool: number;
  max_participants: number;
  start_time: string;
  end_time: string;
  status: 'upcoming' | 'active' | 'ended' | 'paid_out';
  prize_distribution: PrizeDistribution;
  sponsor_name?: string;
}

export interface PrizeDistribution {
  platform_fee_percent: number;
  tiers: Array<{ top_percent: number; share_percent: number }>;
}

export interface WalletTransaction {
  id: string;
  user_id: string;
  type: 'credit' | 'debit' | 'fee';
  amount: number;           // in paise (₹1 = 100 paise)
  idempotency_key: string;
  reference_id?: string;
  description: string;
  created_at: string;
}

// Augment Express Request
declare global {
  namespace Express {
    interface Request {
      user?: AuthUser;
    }
  }
}
