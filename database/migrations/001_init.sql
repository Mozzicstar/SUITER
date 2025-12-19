-- SUITER Database Schema
-- Core tables for SUITER system

-- User profiles with reputation
CREATE TABLE IF NOT EXISTS profiles (
    address VARCHAR(100) PRIMARY KEY,
    reputation BIGINT NOT NULL DEFAULT 50,
    total_posts BIGINT NOT NULL DEFAULT 0,
    total_attention_earned BIGINT NOT NULL DEFAULT 0,
    joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Posts created by users
CREATE TABLE IF NOT EXISTS posts (
    id VARCHAR(100) PRIMARY KEY,
    author VARCHAR(100) NOT NULL REFERENCES profiles(address),
    content_hash VARCHAR(100) NOT NULL,
    attention_accumulated BIGINT NOT NULL DEFAULT 0,
    level SMALLINT NOT NULL DEFAULT 1 CHECK (level >= 1 AND level <= 5),
    created_at TIMESTAMP NOT NULL,
    updated_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Attention sessions (reading a post)
CREATE TABLE IF NOT EXISTS attention_sessions (
    id VARCHAR(100) PRIMARY KEY,
    reader VARCHAR(100) NOT NULL REFERENCES profiles(address),
    post_id VARCHAR(100) NOT NULL REFERENCES posts(id),
    duration_ms BIGINT NOT NULL,
    reward BIGINT NOT NULL,
    claimed BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW(),
    claimed_at TIMESTAMP
);

-- Feed ranking scores
CREATE TABLE IF NOT EXISTS feed_rankings (
    post_id VARCHAR(100) PRIMARY KEY REFERENCES posts(id),
    score DECIMAL(10,6) NOT NULL,
    level_weight DECIMAL(10,6),
    reputation_weight DECIMAL(10,6),
    attention_weight DECIMAL(10,6),
    trend_weight DECIMAL(10,6),
    computed_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Truth claims on posts
CREATE TABLE IF NOT EXISTS truth_claims (
    id VARCHAR(100) PRIMARY KEY,
    post_id VARCHAR(100) NOT NULL REFERENCES posts(id),
    claimer VARCHAR(100) NOT NULL REFERENCES profiles(address),
    claim_text TEXT NOT NULL,
    votes_yes BIGINT NOT NULL DEFAULT 0,
    votes_no BIGINT NOT NULL DEFAULT 0,
    resolved BOOLEAN NOT NULL DEFAULT FALSE,
    accepted BOOLEAN,
    voting_end TIMESTAMP NOT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Creator lifeline support
CREATE TABLE IF NOT EXISTS creator_lifeines (
    id VARCHAR(100) PRIMARY KEY,
    recipient VARCHAR(100) NOT NULL REFERENCES profiles(address),
    total_received BIGINT NOT NULL DEFAULT 0,
    supporter_count BIGINT NOT NULL DEFAULT 0,
    active BOOLEAN NOT NULL DEFAULT TRUE,
    created_at TIMESTAMP NOT NULL DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_posts_author ON posts(author);
CREATE INDEX IF NOT EXISTS idx_posts_created ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_level ON posts(level DESC);
CREATE INDEX IF NOT EXISTS idx_attention_reader ON attention_sessions(reader);
CREATE INDEX IF NOT EXISTS idx_attention_post ON attention_sessions(post_id);
CREATE INDEX IF NOT EXISTS idx_attention_claimed ON attention_sessions(claimed);
CREATE INDEX IF NOT EXISTS idx_feed_score ON feed_rankings(score DESC);
CREATE INDEX IF NOT EXISTS idx_truth_claims_post ON truth_claims(post_id);
CREATE INDEX IF NOT EXISTS idx_truth_claims_resolved ON truth_claims(resolved);

-- Views for common queries
CREATE OR REPLACE VIEW posts_with_ranking AS
SELECT
    p.*,
    fr.score as ranking_score,
    a.reputation as author_reputation
FROM posts p
LEFT JOIN feed_rankings fr ON p.id = fr.post_id
LEFT JOIN profiles a ON p.author = a.address
ORDER BY COALESCE(fr.score, 0) DESC;
