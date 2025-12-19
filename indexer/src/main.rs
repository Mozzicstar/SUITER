use anyhow::Result;
use sqlx::postgres::PgPoolOptions;
use sqlx::Row;
use std::env;
use tracing::{info, error};

mod sui_indexer;
mod feed_ranker;

#[tokio::main]
async fn main() -> Result<()> {
    // Initialize tracing
    tracing_subscriber::fmt()
        .with_env_filter(tracing_subscriber::EnvFilter::from_default_env())
        .init();

    info!("Starting SUITER Indexer...");

    // Load environment variables
    dotenv::dotenv().ok();
    let database_url = env::var("DATABASE_URL")
        .expect("DATABASE_URL must be set");
    let sui_rpc_url = env::var("SUI_RPC_URL")
        .unwrap_or_else(|_| "https://fullnode.testnet.sui.io:443".to_string());

    // Setup database connection pool
    let pool = PgPoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    info!("Connected to PostgreSQL");

    // Run migrations
    sqlx::query(
        r#"
        CREATE TABLE IF NOT EXISTS profiles (
            address VARCHAR PRIMARY KEY,
            reputation BIGINT NOT NULL DEFAULT 50,
            total_posts BIGINT NOT NULL DEFAULT 0,
            total_attention_earned BIGINT NOT NULL DEFAULT 0,
            joined_at TIMESTAMP NOT NULL DEFAULT NOW(),
            updated_at TIMESTAMP NOT NULL DEFAULT NOW()
        );
        
        CREATE TABLE IF NOT EXISTS posts (
            id VARCHAR PRIMARY KEY,
            author VARCHAR NOT NULL,
            content_hash VARCHAR NOT NULL,
            attention_accumulated BIGINT NOT NULL DEFAULT 0,
            level SMALLINT NOT NULL DEFAULT 1,
            created_at TIMESTAMP NOT NULL,
            updated_at TIMESTAMP NOT NULL DEFAULT NOW(),
            FOREIGN KEY (author) REFERENCES profiles(address)
        );
        
        CREATE TABLE IF NOT EXISTS attention_sessions (
            id VARCHAR PRIMARY KEY,
            reader VARCHAR NOT NULL,
            post_id VARCHAR NOT NULL,
            duration_ms BIGINT NOT NULL,
            reward BIGINT NOT NULL,
            claimed BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMP NOT NULL DEFAULT NOW(),
            FOREIGN KEY (reader) REFERENCES profiles(address),
            FOREIGN KEY (post_id) REFERENCES posts(id)
        );
        
        CREATE TABLE IF NOT EXISTS feed_rankings (
            post_id VARCHAR PRIMARY KEY,
            score DECIMAL(10,6) NOT NULL,
            level_weight DECIMAL(10,6),
            reputation_weight DECIMAL(10,6),
            attention_weight DECIMAL(10,6),
            trend_weight DECIMAL(10,6),
            computed_at TIMESTAMP NOT NULL DEFAULT NOW(),
            FOREIGN KEY (post_id) REFERENCES posts(id)
        );
        "#
    )
    .execute(&pool)
    .await?;

    info!("Database migrations completed");

    // Initialize indexer components
    let indexer = sui_indexer::SuiIndexer::new(sui_rpc_url, pool.clone());
    let ranker = feed_ranker::FeedRanker::new(pool.clone());

    // Start indexer task
    let indexer_handle = tokio::spawn(async move {
        if let Err(e) = indexer.run().await {
            error!("Indexer error: {}", e);
        }
    });

    // Start feed ranker task (updates every 5 minutes)
    let ranker_handle = tokio::spawn(async move {
        if let Err(e) = ranker.run().await {
            error!("Feed ranker error: {}", e);
        }
    });

    info!("SUITER Indexer running!");
    info!("RPC: {}", sui_rpc_url);
    info!("Database: {}", database_url);

    // Wait for tasks
    tokio::select! {
        _ = indexer_handle => info!("Indexer exited"),
        _ = ranker_handle => info!("Feed ranker exited"),
    }

    Ok(())
}
