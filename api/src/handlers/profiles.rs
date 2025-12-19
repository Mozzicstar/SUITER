use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use serde_json::json;
use std::sync::Arc;

use crate::AppState;

pub async fn get_profile(
    State(_state): State<Arc<AppState>>,
    Path(_address): Path<String>,
) -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Implement get profile
    (StatusCode::OK, Json(json!({
        "address": "0x...",
        "reputation": 50,
        "total_posts": 0,
        "total_attention_earned": 0
    })))
}

pub async fn get_reputation(
    State(_state): State<Arc<AppState>>,
    Path(_address): Path<String>,
) -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Implement get reputation
    (StatusCode::OK, Json(json!({
        "reputation": 50,
        "status": "normal"
    })))
}
