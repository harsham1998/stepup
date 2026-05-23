import axios from 'axios';
import { getSupabase } from '../../lib/supabase';

export async function sendOtp(phone: string): Promise<{ success: boolean }> {
  const authKey = process.env.MSG91_AUTH_KEY!;
  const templateId = process.env.MSG91_TEMPLATE_ID!;
  await axios.post('https://control.msg91.com/api/v5/otp', null, {
    params: { template_id: templateId, mobile: `91${phone}`, authkey: authKey },
  });
  return { success: true };
}

export async function verifyOtp({ phone, otp }: { phone: string; otp: string }) {
  const authKey = process.env.MSG91_AUTH_KEY!;
  await axios.get('https://control.msg91.com/api/v5/otp/verify', {
    params: { mobile: `91${phone}`, otp, authkey: authKey },
  });
  const { data, error } = await getSupabase().auth.signInWithOtp({ phone: `+91${phone}` });
  if (error) throw new Error(error.message);
  return data;
}

export async function upsertProfile(userId: string, profile: {
  name: string;
  city: string;
  language: string;
  goal_tier: string;
}) {
  const { data, error } = await getSupabase()
    .from('users')
    .upsert({ id: userId, ...profile }, { onConflict: 'id' })
    .select()
    .single();
  if (error) throw new Error(error.message);
  return data;
}
