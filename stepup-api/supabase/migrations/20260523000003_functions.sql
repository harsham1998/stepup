CREATE OR REPLACE FUNCTION increment_daily_steps(p_user_id uuid, p_date date, p_steps int)
RETURNS void LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO user_daily_steps (user_id, date, total_steps)
  VALUES (p_user_id, p_date, p_steps)
  ON CONFLICT (user_id, date)
  DO UPDATE SET total_steps = user_daily_steps.total_steps + EXCLUDED.total_steps;
END;
$$;
