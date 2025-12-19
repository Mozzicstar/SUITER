use axum::{
    http::StatusCode,
    Json,
};
use serde_json::json;

pub async fn health() -> (StatusCode, Json<serde_json::Value>) {
    (StatusCode::OK, Json(json!({
        "status": "healthy",
        "version": "0.1.0",
        "database": "connected"
    })))
}

pub async fn stats() -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Query actual stats from database
    (StatusCode::OK, Json(json!({
        "total_users": 0,
        "total_posts": 0,
        "total_attention_claimed": 0,
        "avg_reputation": 50.0
    })))
}
