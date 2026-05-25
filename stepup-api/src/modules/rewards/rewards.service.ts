// stepup-api/src/modules/rewards/rewards.service.ts
import { getSupabase } from '../../lib/supabase';

export async function listRewards(category?: string) {
  const db = getSupabase();
  let q = db.from('rewards').select('*').eq('active', true).order('sort_order');
  if (category && category !== 'all') q = q.eq('category', category);
  const { data, error } = await q;
  if (error) throw new Error(error.message);
  return data ?? [];
}

export async function redeemReward(userId: string, rewardId: string) {
  const db = getSupabase();

  const { data: reward, error: rErr } = await db
    .from('rewards')
    .select('*')
    .eq('id', rewardId)
    .eq('active', true)
    .single();

  if (rErr || !reward) throw new Error('Reward not found');

  // Check user coin balance
  const { data: user } = await db
    .from('users')
    .select('coin_balance')
    .eq('id', userId)
    .single();

  if (!user || user.coin_balance < reward.coin_cost) {
    throw new Error('Insufficient coins');
  }

  // Debit coins
  const { error: debitErr } = await db
    .from('users')
    .update({ coin_balance: user.coin_balance - reward.coin_cost })
    .eq('id', userId);

  if (debitErr) throw new Error('Could not debit coins');

  // Reduce stock if limited
  if (reward.stock !== null) {
    const { error: stockErr } = await db
      .from('rewards')
      .update({ stock: reward.stock - 1, active: reward.stock - 1 > 0 })
      .eq('id', rewardId);
    if (stockErr) throw new Error('Could not update stock');
  }

  // Insert redemption
  const { data: redemption, error: redErr } = await db
    .from('reward_redemptions')
    .insert({ user_id: userId, reward_id: rewardId, coin_spent: reward.coin_cost, status: 'pending' })
    .select()
    .single();

  if (redErr) throw new Error(redErr.message);
  return { success: true, redemption };
}

export async function getRedemptions(userId: string) {
  const db = getSupabase();
  const { data } = await db
    .from('reward_redemptions')
    .select('*, rewards(title, brand, category, image_url)')
    .eq('user_id', userId)
    .order('created_at', { ascending: false });
  return data ?? [];
}
