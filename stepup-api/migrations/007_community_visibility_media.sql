-- Add visibility + media_urls to community_posts
ALTER TABLE community_posts
  ADD COLUMN IF NOT EXISTS visibility text NOT NULL DEFAULT 'everyone'
    CHECK (visibility IN ('everyone', 'followers', 'friends')),
  ADD COLUMN IF NOT EXISTS media_urls text[] NOT NULL DEFAULT '{}';

-- Feed index: visibility filter + created_at DESC sort
CREATE INDEX IF NOT EXISTS idx_community_posts_feed
  ON community_posts (visibility, created_at DESC);

-- Atomic like increment/decrement to avoid race conditions
CREATE OR REPLACE FUNCTION increment_post_likes(post_id uuid)
RETURNS void AS $$
  UPDATE community_posts SET likes = likes + 1 WHERE id = post_id;
$$ LANGUAGE SQL;

CREATE OR REPLACE FUNCTION decrement_post_likes(post_id uuid)
RETURNS void AS $$
  UPDATE community_posts SET likes = GREATEST(likes - 1, 0) WHERE id = post_id;
$$ LANGUAGE SQL;
