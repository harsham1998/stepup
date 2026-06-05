-- stepup-api/supabase/migrations/20260605000018_friend_requests.sql
CREATE TABLE IF NOT EXISTS friend_requests (
  id          uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  sender_id   uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  receiver_id uuid NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status      text NOT NULL DEFAULT 'pending'
              CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at  timestamptz NOT NULL DEFAULT now(),
  UNIQUE (sender_id, receiver_id),
  CHECK (sender_id <> receiver_id)
);

CREATE INDEX IF NOT EXISTS idx_fr_receiver ON friend_requests(receiver_id, status);
CREATE INDEX IF NOT EXISTS idx_fr_sender   ON friend_requests(sender_id, status);

ALTER TABLE friend_requests ENABLE ROW LEVEL SECURITY;

-- Sender can insert their own requests
CREATE POLICY fr_insert ON friend_requests FOR INSERT
  WITH CHECK (sender_id = auth.uid());

-- Both sender and receiver can read their own rows
CREATE POLICY fr_select ON friend_requests FOR SELECT
  USING (sender_id = auth.uid() OR receiver_id = auth.uid());

-- Only receiver can update status (accept / decline)
CREATE POLICY fr_update ON friend_requests FOR UPDATE
  USING (receiver_id = auth.uid())
  WITH CHECK (receiver_id = auth.uid());
