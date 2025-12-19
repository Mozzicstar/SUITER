use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use serde_json::json;
use std::sync::Arc;

use crate::{models::Post, AppState};

pub async fn create_post(
    State(_state): State<Arc<AppState>>,
    Json(payload): Json<serde_json::Value>,
) -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Implement post creation
    (StatusCode::CREATED, Json(json!({
        "id": "0x...",
        "status": "created"
    })))
}

pub async fn get_post(
    State(_state): State<Arc<AppState>>,
    Path(_id): Path<String>,
) -> (StatusCode, Json<serde_json::Value>) {
    // TODO: Implement get post
    (StatusCode::OK, Json(json!({
        "id": "0x...",
        "author": "0x...",
        "level": 1,
        "attention_accumulated": 0
    })))
}

pub async fn get_feed(
    State(_state): State<Arc<AppState>>,
) -> (StatusCode, Json<Vec<serde_json::Value>>) {
    // TODO: Implement feed ranking
    (StatusCode::OK, Json(vec![]))
}
