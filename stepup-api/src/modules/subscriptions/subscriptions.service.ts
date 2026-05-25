// stepup-api/src/modules/subscriptions/subscriptions.service.ts
import { getSupabase } from '../../lib/supabase';

export async function getPlans() {
  const db = getSupabase();
  const { data } = await db
    .from('subscription_plans')
    .select('*')
    .order('sort_order');
  return data ?? [];
}

export async function getMySubscription(userId: string) {
  const db = getSupabase();
  const { data } = await db
    .from('user_subscriptions')
    .select('*, subscription_plans(*)')
    .eq('user_id', userId)
    .eq('status', 'active')
    .maybeSingle();
  return data ?? { plan_slug: 'free', status: 'active' };
}

export async function subscribe(userId: string, planSlug: string) {
  const db = getSupabase();

  if (planSlug === 'free') {
    // Downgrade — cancel active subscription
    await db
      .from('user_subscriptions')
      .update({ status: 'cancelled' })
      .eq('user_id', userId)
      .eq('status', 'active');
    return { subscribed: true, plan_slug: 'free' };
  }

  // Upsert subscription (Razorpay billing handled separately in webhook)
  const { error } = await db.from('user_subscriptions').upsert({
    user_id: userId,
    plan_slug: planSlug,
    status: 'active',
    started_at: new Date().toISOString(),
  }, { onConflict: 'user_id' });

  if (error) throw new Error(error.message);
  return { subscribed: true, plan_slug: planSlug };
}
