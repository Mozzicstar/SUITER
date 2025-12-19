use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use serde_json::json;
use std::sync::Arc;

use crate::AppState;

pub async fn create_claim(
    State(_state): State<Arc<AppState>>,
    Json(payload): Json<serde_json::Value>,
) -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Implement create claim
    (StatusCode::CREATED, Json(json!({
        "claim_id": "0x...",
        "status": "created"
    })))
}

pub async fn get_claim(
    State(_state): State<Arc<AppState>>,
    Path(_id): Path<String>,
) -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Implement get claim
    (StatusCode::OK, Json(json!({
        "id": "0x...",
        "votes_yes": 0,
        "votes_no": 0,
        "resolved": false
    })))
}

pub async fn vote(
    State(_state): State<Arc<AppState>>,
    Path(_id): Path<String>,
    Json(payload): Json<serde_json::Value>,
) -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Implement vote
    (StatusCode::OK, Json(json!({
        "votes_yes": 0,
        "votes_no": 0
    })))
}
