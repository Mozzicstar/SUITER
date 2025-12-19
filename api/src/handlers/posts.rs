use axum::{
    extract::{Path, State},
    http::StatusCode,
    Json,
};
use serde_json::json;
use sqlx::Row;
use std::sync::Arc;
use uuid::Uuid;
use crate::{models::Post, AppState};

pub async fn create_post(
    State(state): State<Arc<AppState>>,
    Json(payload): Json<serde_json::Value>,
) -> (StatusCode, Json<serde_json::Value>) {
    let pool = &state.pool;

    let content = match payload.get("content_hash").and_then(|v| v.as_str()) {
        Some(s) if !s.trim().is_empty() => s.trim().to_string(),
        _ => {
            return (StatusCode::BAD_REQUEST, Json(json!({ "error": "content_hash required" })));
        }
    };

    let author = payload
        .get("author")
        .and_then(|v| v.as_str())
        .map(|s| s.to_string())
        .unwrap_or_else(|| "anonymous".to_string());

    let id = Uuid::new_v4().to_string();

    // Ensure profile exists
    if let Err(e) = sqlx::query(
        "INSERT OR IGNORE INTO profiles(address, reputation, total_posts, total_attention_earned, joined_at, updated_at) VALUES (?, 50, 0, 0, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    ).bind(&author).execute(pool).await {
        tracing::error!("Failed to ensure profile: {}", e);
    }

    // Insert post
    if let Err(e) = sqlx::query(
        "INSERT INTO posts(id, author, content_hash, attention_accumulated, level, created_at, updated_at) VALUES (?, ?, ?, 0, 1, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)"
    ).bind(&id).bind(&author).bind(&content).execute(pool).await {
        tracing::error!("Failed to insert post: {}", e);
        return (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({"error": "failed to insert post"})));
    }

    // Increment author's total_posts
    if let Err(e) = sqlx::query("UPDATE profiles SET total_posts = COALESCE(total_posts,0) + 1, updated_at = CURRENT_TIMESTAMP WHERE address = ?").bind(&author).execute(pool).await {
        tracing::error!("Failed to update profile count: {}", e);
    }

    (StatusCode::CREATED, Json(json!({ "id": id, "status": "created" })))
}

pub async fn get_post(
    State(state): State<Arc<AppState>>,
    Path(id): Path<String>,
) -> (StatusCode, Json<serde_json::Value>) {
    let pool = &state.pool;

    let row = sqlx::query("SELECT id, author, content_hash, level, attention_accumulated, created_at FROM posts WHERE id = ?")
        .bind(&id)
        .fetch_optional(pool)
        .await
        .map_err(|e| {
            tracing::error!("DB error: {}", e);
            e
        });

    match row {
        Ok(Some(r)) => {
            let obj = json!({
                "id": r.get::<String, _>("id"),
                "author": r.get::<String, _>("author"),
                "content_hash": r.get::<String, _>("content_hash"),
                "level": r.get::<i64, _>("level") as i64,
                "attention_accumulated": r.get::<i64, _>("attention_accumulated"),
                "created_at": r.get::<String, _>("created_at"),
            });
            (StatusCode::OK, Json(obj))
        }
        Ok(None) => (StatusCode::NOT_FOUND, Json(json!({ "error": "not found" }))),
        Err(_) => (StatusCode::INTERNAL_SERVER_ERROR, Json(json!({ "error": "db error" }))),
    }
}

pub async fn get_feed(
    State(state): State<Arc<AppState>>,
) -> (StatusCode, Json<Vec<serde_json::Value>>) {
    let pool = &state.pool;

    let rows = match sqlx::query("SELECT p.id, p.author, p.content_hash, p.level, p.attention_accumulated, CAST(COALESCE(fr.score,0.0) AS REAL) as score FROM posts p LEFT JOIN feed_rankings fr ON p.id = fr.post_id ORDER BY CAST(COALESCE(fr.score,0.0) AS REAL) DESC LIMIT 200")
        .fetch_all(pool).await {
            Ok(r) => r,
            Err(e) => {
                tracing::error!("Failed to fetch feed: {}", e);
                return (StatusCode::INTERNAL_SERVER_ERROR, Json(vec![]));
            }
        };

    let mut out = Vec::with_capacity(rows.len());
    for r in rows {
        let obj = json!({
            "id": r.get::<String, _>("id"),
            "author": r.get::<String, _>("author"),
            "content_hash": r.get::<String, _>("content_hash"),
            "level": r.get::<i64, _>("level") as i64,
            "attention_accumulated": r.get::<i64, _>("attention_accumulated"),
            "score": r.get::<f64, _>("score"),
        });
        out.push(obj);
    }

    (StatusCode::OK, Json(out))
}
