import { getSupabase } from '../../lib/supabase';
import { getRazorpay } from '../../lib/razorpay';
import { getRedis } from '../../lib/redis';
import { v4 as uuid } from 'uuid';

export async function getBalance(userId: string) {
  const { data, error } = await getSupabase()
    .from('wallet_transactions')
    .select('type, amount')
    .eq('user_id', userId);
  if (error) throw new Error(error.message);

  const balance_paise = (data ?? []).reduce((sum: number, t: { type: string; amount: number }) =>
    t.type === 'credit' ? sum + t.amount : sum - t.amount, 0);
  return {
    balance_paise,
    balance_inr: (balance_paise / 100).toFixed(2),
  };
}

export async function getTransactions(userId: string, limit = 20) {
  const { data, error } = await getSupabase()
    .from('wallet_transactions')
    .select('id, type, amount, description, reference_id, created_at')
    .eq('user_id', userId)
    .order('created_at', { ascending: false })
    .limit(limit);
  if (error) throw new Error(error.message);
  return data ?? [];
}

export async function createDepositOrder(userId: string, amount_inr: number) {
  const amount_paise = Math.floor(amount_inr * 100);
  const order = await getRazorpay().orders.create({
    amount: amount_paise,
    currency: 'INR',
    receipt: `deposit_${userId}_${Date.now()}`,
  });
  return { order_id: order.id, amount: amount_paise, currency: 'INR', key_id: process.env.RAZORPAY_KEY_ID };
}

export async function creditWallet(userId: string, amount_paise: number, referenceId: string, description: string) {
  const { error } = await getSupabase().from('wallet_transactions').insert({
    user_id: userId,
    type: 'credit',
    amount: amount_paise,
    status: 'completed',
    idempotency_key: `deposit:${referenceId}`,
    reference_id: referenceId,
    description,
  });
  if (error && error.code !== '23505') throw new Error(error.message);
}

export async function requestWithdrawal(userId: string, amount_inr: number, upi_vpa: string) {
  const amount_paise = Math.floor(amount_inr * 100);

  const redis = getRedis();
  const lockKey = `wallet:withdraw:lock:${userId}`;
  const locked = await redis.set(lockKey, '1', 'EX', 30, 'NX');
  if (!locked) throw new Error('Withdrawal already in progress');

  try {
    const { balance_paise } = await getBalance(userId);
    if (balance_paise < amount_paise) throw new Error('Insufficient balance');

    const payoutId = uuid();
    const idempotencyKey = `withdraw:${userId}:${payoutId}`;

    // Insert pending debit
    const { error: debitErr } = await getSupabase().from('wallet_transactions').insert({
      user_id: userId,
      type: 'debit',
      amount: amount_paise,
      status: 'pending',
      idempotency_key: idempotencyKey,
      description: `UPI withdrawal to ${upi_vpa}`,
    });
    if (debitErr && debitErr.code !== '23505') throw new Error(debitErr.message);

    try {
      const payout = await (getRazorpay() as any).payouts.create({
        account_number: process.env.RAZORPAY_ACCOUNT_NUMBER,
        fund_account: { account_type: 'vpa', vpa: { address: upi_vpa } },
        amount: amount_paise,
        currency: 'INR',
        mode: 'UPI',
        purpose: 'payout',
        queue_if_low_balance: false,
        reference_id: payoutId,
      });

      // Mark debit as completed
      await getSupabase()
        .from('wallet_transactions')
        .update({ status: 'completed' })
        .eq('idempotency_key', idempotencyKey);

      return { success: true, reference: payout.id };
    } catch (payoutErr) {
      // Razorpay failed — mark debit as rejected (reverses the pending hold)
      await getSupabase()
        .from('wallet_transactions')
        .update({ status: 'rejected' })
        .eq('idempotency_key', idempotencyKey);
      throw payoutErr;
    }
  } finally {
    await redis.del(lockKey);
  }
}
