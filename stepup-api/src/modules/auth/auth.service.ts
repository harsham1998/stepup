import axios from 'axios';
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
  let response;
  try {
    response = await axios.post(
      `https://verify.twilio.com/v2/Services/${serviceSid}/VerificationCheck`,
      new URLSearchParams({ To: `+91${phone}`, Code: otp }),
      { headers: { Authorization: `Basic ${auth}`, 'Content-Type': 'application/x-www-form-urlencoded' } },
    );
  } catch (err: any) {
    throw new Error(err.response?.data?.message ?? 'Invalid OTP');
  }
  if (response.data?.status !== 'approved') {
    throw new Error('Invalid OTP');
  }
  const { data, error } = await getSupabase().auth.admin.createUser({
    phone: `+91${phone}`,
    phone_confirm: true,
  });
  if (error && error.message !== 'A user with this phone number has already been registered') {
    throw new Error(error.message);
  }
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
