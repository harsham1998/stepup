import axios from 'axios';
import crypto from 'crypto';
import { getSupabase } from '../../lib/supabase';

function twilioClient() {
  const accountSid = process.env.TWILIO_ACCOUNT_SID;
  const authToken = process.env.TWILIO_AUTH_TOKEN;
  const serviceSid = process.env.TWILIO_VERIFY_SERVICE_SID;
  if (!accountSid || !authToken || !serviceSid) {
    throw new Error('Twilio credentials not configured');
  }
  const auth = Buffer.from(`${accountSid}:${authToken}`).toString('base64');
  return { auth, serviceSid };
}

// Derives a stable server-only password from the user ID.
// Never exposed to the client — used purely to create Supabase sessions
// for phone-only users without a native admin.createSession method.
function derivedPassword(userId: string): string {
  const secret = process.env.SUPABASE_SERVICE_ROLE_KEY!;
  return crypto.createHmac('sha256', secret).update(userId).digest('hex');
}

export async function sendOtp(phone: string): Promise<{ success: boolean }> {
  const { auth, serviceSid } = twilioClient();
  const response = await axios.post(
    `https://verify.twilio.com/v2/Services/${serviceSid}/Verifications`,
    new URLSearchParams({ To: `+91${phone}`, Channel: 'sms' }),
    { headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/x-www-form-urlencoded' } },
  );
  if (response.data?.status !== 'pending') {
    throw new Error(`Twilio failed to send OTP: ${response.data?.status}`);
  }
  return { success: true };
}

export async function verifyOtp({ phone, otp }: { phone: string; otp: string }) {
  const { auth, serviceSid } = twilioClient();
  let twilioRes;
  try {
    twilioRes = await axios.post(
      `https://verify.twilio.com/v2/Services/${serviceSid}/VerificationCheck`,
      new URLSearchParams({ To: `+91${phone}`, Code: otp }),
      { headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/x-www-form-urlencoded' } },
    );
  } catch (err: any) {
    throw new Error(err.response?.data?.message ?? 'Invalid OTP');
  }
  if (twilioRes.data?.status !== 'approved') {
    throw new Error('Invalid OTP');
  }

  const supabase = getSupabase();

  // Create user if new, otherwise find existing user by phone
  const { data: createData } = await supabase.auth.admin.createUser({
    phone: `+91${phone}`,
    phone_confirm: true,
  });

  let userId = createData?.user?.id;

  if (!userId) {
    let page = 1;
    while (true) {
      const { data: list } = await supabase.auth.admin.listUsers({ page, perPage: 1000 });
      const match = list?.users?.find((u) => u.phone === `+91${phone}`);
      if (match) { userId = match.id; break; }
      if (!list?.users?.length || list.users.length < 1000) break;
      page++;
    }
    if (!userId) throw new Error('User not found after OTP verification');
  }

  // Set a server-derived password so we can get a session via signInWithPassword.
  // The password is deterministic and secret — only this server can compute it.
  const password = derivedPassword(userId);
  await supabase.auth.admin.updateUserById(userId, { password });

  // Exchange phone + password for a Supabase session
  const tokenRes = await fetch(
    `${process.env.SUPABASE_URL}/auth/v1/token?grant_type=password`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': process.env.SUPABASE_SERVICE_ROLE_KEY!,
        'Authorization': `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      },
      body: JSON.stringify({ phone: `+91${phone}`, password }),
    },
  );
  const tokenData = await tokenRes.json() as any;
  if (!tokenData.access_token) {
    throw new Error(tokenData.error_description ?? tokenData.msg ?? 'Failed to create session');
  }

  // Check if user has completed onboarding
  const { data: profile } = await supabase.from('users').select('id').eq('id', userId).maybeSingle();

  return {
    userId,
    isNewUser: !profile,
    session: {
      access_token: tokenData.access_token as string,
      refresh_token: tokenData.refresh_token as string,
    },
  };
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
