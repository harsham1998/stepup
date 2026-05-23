import { getSupabase } from '../../lib/supabase';
import { getRazorpay } from '../../lib/razorpay';
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
  const { balance_paise } = await getBalance(userId);
  if (balance_paise < amount_paise) throw new Error('Insufficient balance');

  const payoutId = uuid();
  const idempotencyKey = `withdraw:${userId}:${payoutId}`;

  const { error: debitErr } = await getSupabase().from('wallet_transactions').insert({
    user_id: userId,
    type: 'debit',
    amount: amount_paise,
    status: 'completed',
    idempotency_key: idempotencyKey,
    description: `UPI withdrawal to ${upi_vpa}`,
  });
  if (debitErr && debitErr.code !== '23505') throw new Error(debitErr.message);

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

  return { success: true, reference: payout.id };
}
