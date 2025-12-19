use axum::{
    extract::{Path, Query},
    http::StatusCode,
    response::IntoResponse,
    routing::{get, post},
    Json, Router,
};
use serde::{Deserialize, Serialize};
use sqlx::SqlitePool;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use tracing::info;

mod handlers;
mod models;

/// Application state
pub struct AppState {
    pool: SqlitePool,
}

#[tokio::main]
async fn main() {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    info!("Starting SUITER API...");

    // Load environment variables
    dotenv::dotenv().ok();
    let database_url = std::env::var("DATABASE_URL").expect("DATABASE_URL must be set");

    // Setup database
    let pool = sqlx::sqlite::SqlitePoolOptions::new()
        .max_connections(10)
        .connect(&database_url)
        .await
        .expect("Failed to connect to database");

    let state = Arc::new(AppState { pool });

    // Build router
    let app = Router::new()
        // Post endpoints
        .route("/api/posts", post(handlers::posts::create_post))
        .route("/api/posts/:id", get(handlers::posts::get_post))
        .route("/api/posts/feed", get(handlers::posts::get_feed))
        
        // Profile endpoints
        .route("/api/profiles/:address", get(handlers::profiles::get_profile))
        .route("/api/profiles/:address/reputation", get(handlers::profiles::get_reputation))
        
        // Attention endpoints
        .route("/api/attention/session/start", post(handlers::attention::start_session))
        .route("/api/attention/session/:id/end", post(handlers::attention::end_session))
        .route("/api/attention/claim/:id", post(handlers::attention::claim_reward))
        
        // Truth claim endpoints
        .route("/api/claims", post(handlers::claims::create_claim))
        .route("/api/claims/:id", get(handlers::claims::get_claim))
        .route("/api/claims/:id/vote", post(handlers::claims::vote))
        
        // Debug endpoints
        .route("/api/debug/health", get(handlers::debug::health))
        .route("/api/debug/stats", get(handlers::debug::stats))
        
        .layer(CorsLayer::permissive())
        .with_state(state);

    // Start server
    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000")
        .await
        .expect("Failed to bind port 3000");

    info!("SUITER API listening on http://0.0.0.0:3000");

    axum::serve(listener, app)
        .await
        .expect("Server error");
}
