use anyhow::Result;
use sqlx::sqlite::SqlitePoolOptions;
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
    let pool = SqlitePoolOptions::new()
        .max_connections(5)
        .connect(&database_url)
        .await?;

    info!("Connected to SQLite");

    // Tables already exist in suiter.db - just verify connection
    let _result = sqlx::query("SELECT COUNT(*) FROM profiles")
        .fetch_one(&pool)
        .await;
    
    match _result {
        Ok(_) => info!("Database tables verified"),
        Err(_) => {
            info!("Tables not found - they should be created via migrations");
        }
    }

    info!("Database initialized");

    // Initialize indexer components
    let indexer = sui_indexer::SuiIndexer::new(sui_rpc_url.clone(), pool.clone());
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
