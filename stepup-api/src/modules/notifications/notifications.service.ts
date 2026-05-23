import { getSupabase } from '../../lib/supabase';
import { sendPush } from '../../lib/fcm';
import { logger } from '../../lib/logger';

export async function notifyUser(userId: string, title: string, body: string) {
  const { data: user } = await getSupabase()
    .from('users').select('fcm_token').eq('id', userId).single();
  if (!user?.fcm_token) return;
  try {
    await sendPush(user.fcm_token, title, body);
  } catch (err) {
    logger.warn({ userId, err }, 'FCM push failed');
  }
}

export async function notifyChallengePayout(userId: string, amount_paise: number, rank: number) {
  const inr = (amount_paise / 100).toFixed(0);
  await notifyUser(userId, 'You won!', `Rank #${rank} -- Rs.${inr} credited to your wallet`);
}

export async function notifyRankChange(userId: string, newRank: number, direction: 'up' | 'down') {
  const arrow = direction === 'up' ? 'UP' : 'DOWN';
  await notifyUser(userId, 'Rank changed', `${arrow} You are now #${newRank} on the leaderboard`);
}
