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
  status: 'completed' | 'pending' | 'failed';
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

export interface LeagueRow {
  slug: string;
  label: string;
  color_hex: string;
  xp_min: number;
  xp_max: number | null;
  paid_only: boolean;
  sort_order: number;
}

export interface UserLeagueRow {
  user_id: string;
  league_slug: string;
  xp: number;
  rank_in_tier: number | null;
  season: number;
  updated_at: string;
}

export interface MissionRow {
  id: string;
  slug: string;
  title: string;
  description: string;
  type: 'daily' | 'weekly' | 'seasonal';
  activity: string;
  target: number;
  unit: string;
  coin_reward: number;
  xp_reward: number;
  active: boolean;
}

export interface UserMissionRow {
  id: string;
  user_id: string;
  mission_id: string;
  progress: number;
  completed: boolean;
  completed_at: string | null;
  assigned_date: string;
}

export interface BattleRow {
  id: string;
  challenger_id: string;
  opponent_id: string;
  start_time: string | null;
  end_time: string | null;
  duration_days: number;
  step_goal: number;
  status: 'pending' | 'active' | 'ended' | 'declined';
  winner_id: string | null;
  coin_wager: number;
  created_at: string;
}

export interface RewardRow {
  id: string;
  title: string;
  brand: string;
  category: string;
  description: string;
  coin_cost: number;
  stock: number | null;
  image_url: string | null;
  active: boolean;
  sort_order: number;
}

export interface BattlePassTier {
  level: number;
  xp_required: number;
  free_reward: string;
  paid_reward: string;
}

export interface CommunityPostRow {
  id: string;
  user_id: string;
  type: string;
  content: string;
  metadata: Record<string, unknown>;
  likes: number;
  created_at: string;
}
