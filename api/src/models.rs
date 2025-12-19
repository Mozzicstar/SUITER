use serde::{Deserialize, Serialize};

// ============ PROFILE MODELS ============

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Profile {
    pub address: String,
    pub reputation: i64,
    pub total_posts: i64,
    pub total_attention_earned: i64,
}

// ============ POST MODELS ============

#[derive(Debug, Serialize, Deserialize)]
pub struct CreatePostRequest {
    pub author: String,
    pub content_hash: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct Post {
    pub id: String,
    pub author: String,
    pub level: i16,
    pub attention_accumulated: i64,
    pub reply_count: i64,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct FeedPost {
    pub post: Post,
    pub author_reputation: i64,
    pub ranking_score: f64,
}

// ============ ATTENTION MODELS ============

#[derive(Debug, Serialize, Deserialize)]
pub struct StartSessionRequest {
    pub reader: String,
    pub post_id: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct AttentionSession {
    pub id: String,
    pub reader: String,
    pub post_id: String,
    pub duration_ms: i64,
    pub reward: i64,
    pub claimed: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct EndSessionRequest {
    pub duration_ms: i64,
}

// ============ TRUTH CLAIM MODELS ============

#[derive(Debug, Serialize, Deserialize)]
pub struct CreateClaimRequest {
    pub post_id: String,
    pub claimer: String,
    pub claim_text: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct TruthClaim {
    pub id: String,
    pub post_id: String,
    pub claimer: String,
    pub votes_yes: i64,
    pub votes_no: i64,
    pub resolved: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct VoteRequest {
    pub voter: String,
    pub vote: bool, // true = yes, false = no
}

// ============ DEBUG MODELS ============

#[derive(Debug, Serialize, Deserialize)]
pub struct HealthStatus {
    pub status: String,
    pub database: String,
    pub version: String,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct Stats {
    pub total_users: i64,
    pub total_posts: i64,
    pub total_attention_claimed: i64,
    pub avg_reputation: f64,
}
