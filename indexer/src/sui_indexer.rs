use anyhow::Result;
use sqlx::SqlitePool;
use tracing::info;
use std::time::Duration;
use tokio::time::sleep;

/// Sui blockchain indexer
/// Listens to post creation, attention sessions, and reputation changes
pub struct SuiIndexer {
    rpc_url: String,
    pool: SqlitePool,
}

impl SuiIndexer {
    pub fn new(rpc_url: String, pool: SqlitePool) -> Self {
        SuiIndexer { rpc_url, pool }
    }

    pub async fn run(&self) -> Result<()> {
        info!("Starting Sui indexer loop...");

        loop {
            // Poll blockchain for events every 2 seconds
            if let Err(e) = self.index_events().await {
                tracing::error!("Error indexing events: {}", e);
            }

            sleep(Duration::from_secs(2)).await;
        }
    }

    async fn index_events(&self) -> Result<()> {
        // TODO: Query Sui RPC for events
        // 1. sui_getEvents (post creation, attention, reputation changes)
        // 2. Parse events
        // 3. Store in PostgreSQL
        // 4. Emit rankings update trigger

        // For now, this is a placeholder
        Ok(())
    }
}
