// stepup-api/src/modules/rivals/rivals.service.ts
import { getSupabase } from '../../lib/supabase';
import { getRedis } from '../../lib/redis';

export async function getRivals(userId: string) {
  const db = getSupabase();
  const { data: rivalRows } = await db
    .from('rivals')
    .select('rival_id')
    .eq('user_id', userId);

  if (!rivalRows || rivalRows.length === 0) return [];

  const rivalIds = rivalRows.map(r => r.rival_id);
  const { data: users } = await db
    .from('users')
    .select('id, name, avatar_url, streak_days, league')
    .in('id', rivalIds);

  const today = new Date().toISOString().slice(0, 10);
  const mondayDate = getMondayDate();

  // Get week steps for each rival
  const enriched = await Promise.all((users ?? []).map(async u => {
    const { data: weekData } = await db
      .from('user_daily_steps')
      .select('total_steps')
      .eq('user_id', u.id)
      .gte('date', mondayDate);
    const weekSteps = (weekData ?? []).reduce((s, r) => s + r.total_steps, 0);

    const { data: todayData } = await db
      .from('user_daily_steps')
      .select('total_steps')
      .eq('user_id', u.id)
      .eq('date', today)
      .maybeSingle();

    return {
      user_id: u.id,
      name: u.name,
      avatar_url: u.avatar_url,
      league: u.league,
      streak_days: u.streak_days,
      week_steps: weekSteps,
      today_steps: todayData?.total_steps ?? 0,
    };
  }));

  return enriched;
}

export async function addRival(userId: string, rivalId: string) {
  const db = getSupabase();
  if (userId === rivalId) throw new Error('Cannot rival yourself');

  const { error } = await db.from('rivals').insert({ user_id: userId, rival_id: rivalId });
  if (error) {
    if (error.code === '23505') throw new Error('Already rivals');
    throw new Error(error.message);
  }
  return { added: true };
}

export async function removeRival(userId: string, rivalId: string) {
  const db = getSupabase();
  await db.from('rivals').delete().eq('user_id', userId).eq('rival_id', rivalId);
  return { removed: true };
}

export async function getBattles(userId: string) {
  const db = getSupabase();
  const { data } = await db
    .from('battles')
    .select('*')
    .or(`challenger_id.eq.${userId},opponent_id.eq.${userId}`)
    .order('created_at', { ascending: false })
    .limit(20);

  if (!data || data.length === 0) return [];

  const allUserIds = [...new Set(data.flatMap(b => [b.challenger_id, b.opponent_id]))];
  const { data: users } = await db.from('users').select('id,name,avatar_url').in('id', allUserIds);
  const userMap = Object.fromEntries((users ?? []).map(u => [u.id, u]));

  // Get step counts for active battles
  const activeBattles = data.filter(b => b.status === 'active');
  const battleSteps: Record<string, { challenger: number; opponent: number }> = {};

  for (const b of activeBattles) {
    const startDate = b.start_time?.slice(0, 10) ?? '';
    const [cSteps, oSteps] = await Promise.all([
      getBattleSteps(b.challenger_id, startDate, db),
      getBattleSteps(b.opponent_id, startDate, db),
    ]);
    battleSteps[b.id] = { challenger: cSteps, opponent: oSteps };
  }

  return data.map(b => ({
    ...b,
    challenger_name: userMap[b.challenger_id]?.name ?? 'Unknown',
    opponent_name: userMap[b.opponent_id]?.name ?? 'Unknown',
    challenger_avatar: userMap[b.challenger_id]?.avatar_url ?? null,
    opponent_avatar: userMap[b.opponent_id]?.avatar_url ?? null,
    challenger_steps: battleSteps[b.id]?.challenger ?? 0,
    opponent_steps: battleSteps[b.id]?.opponent ?? 0,
  }));
}

async function getBattleSteps(
  userId: string,
  fromDate: string,
  db: ReturnType<typeof getSupabase>
): Promise<number> {
  if (!fromDate) return 0;
  const { data } = await db
    .from('user_daily_steps')
    .select('total_steps')
    .eq('user_id', userId)
    .gte('date', fromDate);
  return (data ?? []).reduce((s, r) => s + r.total_steps, 0);
}

export async function createBattle(
  challengerId: string,
  opponentId: string,
  durationDays: number,
  coinWager: number
) {
  const db = getSupabase();
  if (challengerId === opponentId) throw new Error('Cannot battle yourself');

  const { data, error } = await db.from('battles').insert({
    challenger_id: challengerId,
    opponent_id: opponentId,
    duration_days: durationDays,
    coin_wager: coinWager,
    status: 'pending',
  }).select().single();

  if (error) throw new Error(error.message);
  return data;
}

export async function respondToBattle(userId: string, battleId: string, accept: boolean) {
  const db = getSupabase();
  const { data: battle } = await db
    .from('battles')
    .select('*')
    .eq('id', battleId)
    .eq('opponent_id', userId)
    .eq('status', 'pending')
    .single();

  if (!battle) throw new Error('Battle not found or not pending');

  if (!accept) {
    await db.from('battles').update({ status: 'declined' }).eq('id', battleId);
    return { status: 'declined' };
  }

  const now = new Date();
  const endTime = new Date(now);
  endTime.setDate(endTime.getDate() + battle.duration_days);

  await db.from('battles').update({
    status: 'active',
    start_time: now.toISOString(),
    end_time: endTime.toISOString(),
  }).eq('id', battleId);

  return { status: 'active', start_time: now.toISOString(), end_time: endTime.toISOString() };
}

function getMondayDate(): string {
  const d = new Date();
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  d.setDate(diff);
  return d.toISOString().slice(0, 10);
}
