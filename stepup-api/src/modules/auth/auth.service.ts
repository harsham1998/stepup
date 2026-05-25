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
    // Supabase strips the leading '+' when storing phone numbers
    const normalizedPhone = `91${phone}`;
    let page = 1;
    while (true) {
      const { data: list } = await supabase.auth.admin.listUsers({ page, perPage: 1000 });
      const match = list?.users?.find((u) => {
        const stored = (u.phone ?? '').replace(/^\+/, '');
        return stored === normalizedPhone;
      });
      if (match) { userId = match.id; break; }
      if (!list?.users?.length || list.users.length < 1000) break;
      page++;
    }
    if (!userId) throw new Error('User not found after OTP verification');
  }

  // Use a synthetic email + server-derived password to create a Supabase session.
  // This avoids requiring "Phone logins" to be enabled in Supabase dashboard.
  const syntheticEmail = `phone_${userId}@auth.stepup.app`;
  const password = derivedPassword(userId);
  await supabase.auth.admin.updateUserById(userId, {
    email: syntheticEmail,
    email_confirm: true,
    password,
  });

  // Exchange email + password for a Supabase session
  const tokenRes = await fetch(
    `${process.env.SUPABASE_URL}/auth/v1/token?grant_type=password`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'apikey': process.env.SUPABASE_SERVICE_ROLE_KEY!,
        'Authorization': `Bearer ${process.env.SUPABASE_SERVICE_ROLE_KEY}`,
      },
      body: JSON.stringify({ email: syntheticEmail, password }),
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

export async function getProfile(userId: string) {
  const { data, error } = await getSupabase()
    .from('users')
    .select()
    .eq('id', userId)
    .maybeSingle();
  if (error) throw new Error(error.message);
  return data;
}

export async function getProfileSummary(userId: string) {
  const db = getSupabase();
  const today = new Date().toISOString().slice(0, 10);

  // Monday of current week
  const now = new Date();
  const dayOfWeek = now.getDay(); // 0=Sun
  const diffToMonday = (dayOfWeek === 0 ? -6 : 1 - dayOfWeek);
  const monday = new Date(now);
  monday.setDate(now.getDate() + diffToMonday);
  const mondayStr = monday.toISOString().slice(0, 10);

  const [userRes, missionsRes, progressRes, rivalsRes, weekStepsRes, challengesRes, achievementsRes] = await Promise.all([
    db.from('users').select('id,name,phone,city,avatar_url,streak_days,xp,league,coin_balance,goal_tier,created_at').eq('id', userId).maybeSingle(),
    db.from('missions').select('id').eq('type', 'daily').eq('active', true),
    db.from('user_missions').select('completed').eq('user_id', userId).eq('assigned_date', today),
    db.from('rivals').select('rival_id', { count: 'exact', head: true }).eq('user_id', userId),
    db.from('user_daily_steps').select('date,total_steps').eq('user_id', userId).gte('date', mondayStr).order('date'),
    db.from('challenge_participants')
      .select('challenge_id', { count: 'exact', head: true })
      .eq('user_id', userId)
      .in('challenge_id',
        db.from('challenges').select('id').eq('status', 'active') as any
      ),
    db.from('user_achievements').select('id', { count: 'exact', head: true }).eq('user_id', userId),
  ]);

  if (userRes.error) throw new Error(userRes.error.message);

  const totalMissions = missionsRes.data?.length ?? 0;
  const completedMissions = (progressRes.data ?? []).filter(m => m.completed).length;

  // Build a full Mon–Sun array (today's ring is partial)
  const weekDays = Array.from({ length: 7 }, (_, i) => {
    const d = new Date(monday);
    d.setDate(monday.getDate() + i);
    return d.toISOString().slice(0, 10);
  });
  const stepMap = Object.fromEntries((weekStepsRes.data ?? []).map(r => [r.date, r.total_steps]));
  const weekSteps = weekDays.map(date => ({ date, steps: stepMap[date] ?? 0 }));

  return {
    ...userRes.data,
    missions_today: { completed: completedMissions, total: totalMissions },
    rivals_count: rivalsRes.count ?? 0,
    challenges_active: challengesRes.count ?? 0,
    achievements_earned: achievementsRes.count ?? 0,
    week_steps: weekSteps,
  };
}

export async function upsertProfile(userId: string, profile: {
  name: string;
  city: string;
  language: string;
  goal_tier: string;
  avatar_url?: string;
}) {
  const { data, error } = await getSupabase()
    .from('users')
    .upsert({ id: userId, ...profile }, { onConflict: 'id' })
    .select()
    .single();
  if (error) throw new Error(error.message);
  return data;
}

export async function updateAvatar(userId: string, avatarUrl: string) {
  const { data, error } = await getSupabase()
    .from('users')
    .update({ avatar_url: avatarUrl })
    .eq('id', userId)
    .select('avatar_url')
    .single();
  if (error) throw new Error(error.message);
  return data;
}
