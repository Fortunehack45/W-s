-- ==============================================================================
-- W's PLATFORM: FULL PRODUCTION DATABASE SCHEMA
-- Migration: 001_initial_schema.sql
-- ==============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- 1. Profiles & Social Graph
CREATE TABLE IF NOT EXISTS profiles (
    id UUID PRIMARY KEY,
    username TEXT NOT NULL UNIQUE CHECK (username ~ '^[a-z0-9_]{3,30}$'),
    display_name TEXT NOT NULL CHECK (char_length(display_name) >= 1 AND char_length(display_name) <= 50),
    avatar_url TEXT DEFAULT '',
    bio TEXT DEFAULT '' CHECK (char_length(bio) <= 300),
    video_count INTEGER NOT NULL DEFAULT 0 CHECK (video_count >= 0),
    followers_count INTEGER NOT NULL DEFAULT 0 CHECK (followers_count >= 0),
    following_count INTEGER NOT NULL DEFAULT 0 CHECK (following_count >= 0),
    net_w_earned BIGINT NOT NULL DEFAULT 0, -- Lifetime Net Realized W's Gained + Royalties
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    premium_expires_at TIMESTAMPTZ,
    verified_followers_count INTEGER NOT NULL DEFAULT 0 CHECK (verified_followers_count >= 0),
    total_watch_minutes BIGINT NOT NULL DEFAULT 0 CHECK (total_watch_minutes >= 0),
    is_monetization_approved BOOLEAN NOT NULL DEFAULT FALSE,
    restriction_status TEXT NOT NULL DEFAULT 'normal' CHECK (restriction_status IN ('normal', 'under_review', 'shadowbanned', 'restricted', 'suspended')),
    restricted_until TIMESTAMPTZ,
    bot_risk_score REAL NOT NULL DEFAULT 0.0 CHECK (bot_risk_score >= 0.0 AND bot_risk_score <= 100.0),
    is_suspended BOOLEAN NOT NULL DEFAULT FALSE,
    privacy_settings JSONB NOT NULL DEFAULT '{"is_private": false, "allow_comments": true, "allow_chat": true}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS user_relationships (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    actor_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    target_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    relationship_type TEXT NOT NULL CHECK (relationship_type IN ('follow', 'block', 'mute')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (actor_id, target_id, relationship_type),
    CHECK (actor_id != target_id)
);

CREATE INDEX IF NOT EXISTS idx_user_rel_actor ON user_relationships(actor_id, relationship_type);
CREATE INDEX IF NOT EXISTS idx_user_rel_target ON user_relationships(target_id, relationship_type);

-- 2. Authoritative W's Wallet & Double-Entry Ledger
CREATE TABLE IF NOT EXISTS wallet_accounts (
    user_id UUID PRIMARY KEY REFERENCES profiles(id) ON DELETE CASCADE,
    available_w BIGINT NOT NULL DEFAULT 0 CHECK (available_w >= 0),
    reserved_w BIGINT NOT NULL DEFAULT 0 CHECK (reserved_w >= 0),
    earned_w_balance BIGINT NOT NULL DEFAULT 0 CHECK (earned_w_balance >= 0),
    purchased_w_balance BIGINT NOT NULL DEFAULT 0 CHECK (purchased_w_balance >= 0),
    version BIGINT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (available_w + reserved_w = earned_w_balance + purchased_w_balance)
);

CREATE TABLE IF NOT EXISTS wallet_ledger (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN (
        'signup_bonus', 'promotional_reward', 'achievement',
        'verified_purchase', 'video_w_stake', 'video_w_unstake',
        'creator_video_royalty', 'auction_bid_reserve', 'auction_bid_release',
        'auction_settlement_debit', 'auction_settlement_credit',
        'platform_fee', 'refund', 'admin_correction'
    )),
    point_amount BIGINT NOT NULL, -- positive for credit, negative for debit
    balance_source TEXT NOT NULL CHECK (balance_source IN (
        'signup_bonus', 'earned', 'purchased', 'marketplace_escrow'
    )),
    reference_type TEXT NOT NULL,
    reference_id TEXT NOT NULL,
    idempotency_key TEXT NOT NULL UNIQUE,
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_wallet_ledger_user ON wallet_ledger(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS purchase_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    provider TEXT NOT NULL CHECK (provider IN ('google_play', 'apple_app_store', 'stripe', 'sandbox')),
    provider_transaction_id TEXT NOT NULL,
    product_id TEXT NOT NULL,
    w_amount BIGINT NOT NULL CHECK (w_amount > 0),
    currency TEXT NOT NULL CHECK (char_length(currency) = 3),
    amount_cents BIGINT NOT NULL CHECK (amount_cents > 0),
    status TEXT NOT NULL DEFAULT 'created' CHECK (status IN (
        'created', 'pending', 'verified', 'credited', 'failed', 'cancelled', 'refunded', 'disputed'
    )),
    raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    verified_at TIMESTAMPTZ,
    credited_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (provider, provider_transaction_id)
);

-- 3. Social Videos, Metrics & Canonical Video Chat
CREATE TABLE IF NOT EXISTS videos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    creator_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL CHECK (char_length(title) >= 1 AND char_length(title) <= 150),
    description TEXT NOT NULL DEFAULT '' CHECK (char_length(description) <= 2000),
    video_url TEXT NOT NULL DEFAULT '',
    thumbnail_url TEXT NOT NULL DEFAULT '',
    duration_seconds REAL NOT NULL DEFAULT 0.0 CHECK (duration_seconds >= 0.0),
    provider_asset_id TEXT NOT NULL DEFAULT '',
    status TEXT NOT NULL DEFAULT 'draft' CHECK (status IN (
        'draft', 'uploading', 'processing', 'pending_review', 'published', 'rejected', 'removed', 'failed'
    )),
    view_count BIGINT NOT NULL DEFAULT 0 CHECK (view_count >= 0),
    like_count BIGINT NOT NULL DEFAULT 0 CHECK (like_count >= 0),
    comment_count BIGINT NOT NULL DEFAULT 0 CHECK (comment_count >= 0),
    share_count BIGINT NOT NULL DEFAULT 0 CHECK (share_count >= 0),
    published_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_videos_feed ON videos(status, published_at DESC) WHERE status = 'published';

CREATE TABLE IF NOT EXISTS video_likes (
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, video_id)
);

CREATE TABLE IF NOT EXISTS video_views (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    viewer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    watch_duration_seconds REAL NOT NULL DEFAULT 0.0 CHECK (watch_duration_seconds >= 0.0),
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    is_counted BOOLEAN NOT NULL DEFAULT TRUE, -- Automatically FALSE if viewer is restricted/bot-flagged
    ip_hash TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_video_views_dedup ON video_views(video_id, viewer_id, created_at DESC);

CREATE TABLE IF NOT EXISTS comments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    parent_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) >= 1 AND char_length(content) <= 1000),
    like_count INTEGER NOT NULL DEFAULT 0 CHECK (like_count >= 0),
    is_deleted BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Canonical Video Chat Rooms (Exactly One Per Video)
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    video_id UUID NOT NULL UNIQUE REFERENCES videos(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    is_archived BOOLEAN NOT NULL DEFAULT FALSE,
    message_count BIGINT NOT NULL DEFAULT 0 CHECK (message_count >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    reply_to_id UUID REFERENCES chat_messages(id) ON DELETE SET NULL,
    content TEXT NOT NULL CHECK (char_length(content) >= 1 AND char_length(content) <= 500),
    idempotency_key TEXT NOT NULL UNIQUE,
    is_moderated BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_chat_messages_room ON chat_messages(room_id, created_at ASC);

-- Reposts, Saves & Search History
CREATE TABLE IF NOT EXISTS video_reposts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, video_id)
);

CREATE INDEX IF NOT EXISTS idx_video_reposts_user ON video_reposts(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS video_saves (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, video_id)
);

CREATE TABLE IF NOT EXISTS user_search_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    query_text TEXT NOT NULL CHECK (char_length(query_text) >= 1 AND char_length(query_text) <= 200),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_user_search_history ON user_search_history(user_id, created_at DESC);

-- Direct Messaging (1-on-1 DMs) & Daily Streaks
CREATE TABLE IF NOT EXISTS direct_chat_threads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    current_streak_days INTEGER NOT NULL DEFAULT 0 CHECK (current_streak_days >= 0),
    longest_streak_days INTEGER NOT NULL DEFAULT 0 CHECK (longest_streak_days >= 0),
    last_message_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    last_streak_date DATE DEFAULT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user1_id, user2_id),
    CHECK (user1_id < user2_id)
);

CREATE TABLE IF NOT EXISTS direct_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    thread_id UUID NOT NULL REFERENCES direct_chat_threads(id) ON DELETE CASCADE,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    content TEXT NOT NULL CHECK (char_length(content) >= 1 AND char_length(content) <= 2000),
    idempotency_key TEXT NOT NULL UNIQUE,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_direct_messages_thread ON direct_messages(thread_id, created_at ASC);

-- 4. Dynamic Video W's Momentum Pools & Linear Bonding Curve
CREATE TABLE IF NOT EXISTS video_w_pools (
    video_id UUID PRIMARY KEY REFERENCES videos(id) ON DELETE CASCADE,
    current_w_count BIGINT NOT NULL DEFAULT 0 CHECK (current_w_count >= 0), -- Public displayed active W's
    reserve_balance BIGINT NOT NULL DEFAULT 0 CHECK (reserve_balance >= 0), -- Authoritative pool backing
    total_shares BIGINT NOT NULL DEFAULT 0 CHECK (total_shares >= 0),
    base_price_w BIGINT NOT NULL DEFAULT 1 CHECK (base_price_w > 0),
    slope_scaled BIGINT NOT NULL DEFAULT 100, -- 0.01 scaled by 10,000 for integer precision
    creator_royalty_bps INTEGER NOT NULL DEFAULT 200 CHECK (creator_royalty_bps >= 0 AND creator_royalty_bps <= 1000), -- 2% = 200 bps
    total_volume_w BIGINT NOT NULL DEFAULT 0 CHECK (total_volume_w >= 0),
    version BIGINT NOT NULL DEFAULT 1,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS video_w_positions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    shares_owned BIGINT NOT NULL DEFAULT 0 CHECK (shares_owned >= 0),
    w_cost_basis BIGINT NOT NULL DEFAULT 0 CHECK (w_cost_basis >= 0),
    total_w_realized_pnl BIGINT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, video_id)
);

CREATE TABLE IF NOT EXISTS video_w_pool_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    tx_type TEXT NOT NULL CHECK (tx_type IN ('stake_buy', 'unstake_sell')),
    w_amount BIGINT NOT NULL CHECK (w_amount > 0),
    shares_amount BIGINT NOT NULL CHECK (shares_amount > 0),
    share_price_snapshot BIGINT NOT NULL,
    creator_royalty_w BIGINT NOT NULL DEFAULT 0,
    idempotency_key TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_video_w_pool_tx_video ON video_w_pool_transactions(video_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_video_w_pool_tx_user ON video_w_pool_transactions(user_id, created_at DESC);

-- 5. Collectible Digital Cards & Auction Marketplace
CREATE TABLE IF NOT EXISTS card_definitions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    description TEXT NOT NULL DEFAULT '',
    rarity TEXT NOT NULL CHECK (rarity IN ('common', 'rare', 'epic', 'legendary')),
    artwork_url TEXT NOT NULL,
    series TEXT NOT NULL,
    version INTEGER NOT NULL DEFAULT 1 CHECK (version >= 1),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    listing_eligible BOOLEAN NOT NULL DEFAULT TRUE,
    total_minted INTEGER NOT NULL DEFAULT 0 CHECK (total_minted >= 0),
    metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS card_instances (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_definition_id UUID NOT NULL REFERENCES card_definitions(id) ON DELETE RESTRICT,
    owner_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    serial_number INTEGER NOT NULL CHECK (serial_number > 0),
    status TEXT NOT NULL DEFAULT 'owned' CHECK (
        status IN ('owned', 'listed', 'transfer_pending', 'retired')
    ),
    acquisition_method TEXT NOT NULL CHECK (
        acquisition_method IN ('initial_award', 'achievement', 'milestone', 'streak_milestone', 'auction_purchase', 'admin_grant')
    ),
    acquired_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (card_definition_id, serial_number)
);

CREATE INDEX IF NOT EXISTS idx_card_instances_owner ON card_instances(owner_id, status);

CREATE TABLE IF NOT EXISTS card_listings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_instance_id UUID NOT NULL REFERENCES card_instances(id) ON DELETE RESTRICT,
    seller_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    minimum_bid BIGINT NOT NULL CHECK (minimum_bid > 0),
    current_highest_bid BIGINT DEFAULT NULL CHECK (current_highest_bid IS NULL OR current_highest_bid >= minimum_bid),
    current_highest_bidder UUID DEFAULT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    status TEXT NOT NULL DEFAULT 'active' CHECK (
        status IN ('scheduled', 'active', 'completed', 'cancelled', 'no_bids', 'needs_recovery')
    ),
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    bid_count INTEGER NOT NULL DEFAULT 0 CHECK (bid_count >= 0),
    fee_percentage NUMERIC(5,2) NOT NULL DEFAULT 5.00 CHECK (fee_percentage >= 0.00 AND fee_percentage <= 20.00),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (ends_at > starts_at)
);

CREATE UNIQUE INDEX IF NOT EXISTS idx_unique_active_listing_per_card 
ON card_listings (card_instance_id) 
WHERE status IN ('scheduled', 'active', 'needs_recovery');

CREATE TABLE IF NOT EXISTS card_bids (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    listing_id UUID NOT NULL REFERENCES card_listings(id) ON DELETE CASCADE,
    bidder_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    amount BIGINT NOT NULL CHECK (amount > 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (
        status IN ('active', 'outbid', 'won', 'refunded', 'cancelled')
    ),
    idempotency_key TEXT NOT NULL UNIQUE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS card_bid_reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    bid_id UUID NOT NULL REFERENCES card_bids(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    listing_id UUID NOT NULL REFERENCES card_listings(id) ON DELETE CASCADE,
    amount BIGINT NOT NULL CHECK (amount > 0),
    status TEXT NOT NULL DEFAULT 'reserved' CHECK (
        status IN ('reserved', 'settled', 'released')
    ),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS card_ownership_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    card_instance_id UUID NOT NULL REFERENCES card_instances(id) ON DELETE CASCADE,
    from_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    to_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
    transfer_type TEXT NOT NULL CHECK (
        transfer_type IN ('mint', 'auction_settlement', 'admin_transfer')
    ),
    reference_id TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- 6. Native In-App Advertising Platform
CREATE TABLE IF NOT EXISTS ad_campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    advertiser_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    video_id UUID NOT NULL REFERENCES videos(id) ON DELETE CASCADE,
    campaign_name TEXT NOT NULL CHECK (char_length(campaign_name) >= 1 AND char_length(campaign_name) <= 100),
    headline TEXT NOT NULL DEFAULT '',
    call_to_action_url TEXT NOT NULL DEFAULT '',
    budget_cents BIGINT NOT NULL CHECK (budget_cents > 0),
    spent_cents BIGINT NOT NULL DEFAULT 0 CHECK (spent_cents >= 0),
    cpm_bid_cents BIGINT NOT NULL DEFAULT 50 CHECK (cpm_bid_cents > 0),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('draft', 'pending_review', 'active', 'paused', 'completed')),
    target_criteria JSONB NOT NULL DEFAULT '{}'::jsonb,
    starts_at TIMESTAMPTZ NOT NULL,
    ends_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    CHECK (ends_at > starts_at)
);

CREATE TABLE IF NOT EXISTS ad_impressions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID NOT NULL REFERENCES ad_campaigns(id) ON DELETE CASCADE,
    viewer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    watch_duration_seconds REAL NOT NULL DEFAULT 0.0,
    is_completed BOOLEAN NOT NULL DEFAULT FALSE,
    clicked_cta BOOLEAN NOT NULL DEFAULT FALSE,
    cost_charged_cents REAL NOT NULL DEFAULT 0.0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_ad_campaigns_active ON ad_campaigns(status, ends_at) WHERE status = 'active';

-- 7. Anti-Bot Detection & In-App Moderation Appeals
CREATE TABLE IF NOT EXISTS bot_detection_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES profiles(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL CHECK (event_type IN ('bot_views', 'bot_comments', 'bot_likes', 'bot_impressions', 'rapid_ip_burst')),
    severity_score REAL NOT NULL CHECK (severity_score >= 0.0 AND severity_score <= 100.0),
    ip_address TEXT DEFAULT '',
    device_fingerprint TEXT DEFAULT '',
    details JSONB NOT NULL DEFAULT '{}'::jsonb,
    action_taken TEXT NOT NULL CHECK (action_taken IN ('logged', 'throttled', 'quarantined', 'restricted', 'suspended')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_bot_events_user ON bot_detection_events(user_id, created_at DESC);

CREATE TABLE IF NOT EXISTS moderation_appeals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    restriction_reason TEXT NOT NULL,
    appeal_message TEXT NOT NULL CHECK (char_length(appeal_message) >= 10 AND char_length(appeal_message) <= 2000),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'under_review', 'approved', 'rejected')),
    reviewer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
    resolution_notes TEXT DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    resolved_at TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_moderation_appeals_user ON moderation_appeals(user_id, created_at DESC);

-- 8. Row Level Security Policies
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Profiles readable by all" ON profiles FOR SELECT USING (true);
CREATE POLICY "Users update own profile" ON profiles FOR UPDATE USING (auth.uid() = id);

ALTER TABLE wallet_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own wallet account" ON wallet_accounts FOR SELECT USING (auth.uid() = user_id);

ALTER TABLE wallet_ledger ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own ledger entries" ON wallet_ledger FOR SELECT USING (auth.uid() = user_id);

ALTER TABLE video_w_pools ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Video W pools readable by all" ON video_w_pools FOR SELECT USING (true);

ALTER TABLE video_w_positions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users read own video positions" ON video_w_positions FOR SELECT USING (auth.uid() = user_id);

ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Chat rooms readable by all" ON chat_rooms FOR SELECT USING (true);

ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Chat messages readable by all" ON chat_messages FOR SELECT USING (true);
