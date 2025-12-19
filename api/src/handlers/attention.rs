use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use serde_json::json;
use std::sync::Arc;

use crate::AppState;

pub async fn start_session(
    State(_state): State<Arc<AppState>>,
    Json(payload): Json<serde_json::Value>,
) -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Implement start session
    (StatusCode::CREATED, Json(json!({
        "session_id": "0x...",
        "status": "started"
    })))
}

pub async fn end_session(
    State(_state): State<Arc<AppState>>,
    Path(_id): Path<String>,
    Json(payload): Json<serde_json::Value>,
) -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Implement end session
    (StatusCode::OK, Json(json!({
        "reward": 0,
        "claimed": false
    })))
}

pub async fn claim_reward(
    State(_state): State<Arc<AppState>>,
    Path(_id): Path<String>,
) -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Implement claim reward
    (StatusCode::OK, Json(json!({
        "amount": 0,
        "claimed": true
    })))
}
