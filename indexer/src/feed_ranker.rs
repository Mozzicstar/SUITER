use anyhow::Result;
use sqlx::{SqlitePool, Row};
use tracing::info;
use std::time::Duration;
use tokio::time::sleep;

/// Feed ranking engine
/// Computes post rankings every 5 minutes using:
/// score = 0.3*L + 0.2*R + 0.3*V + 0.2*T
/// where:
/// - L: Post level (1-5)
/// - R: Author reputation weight
/// - V: Attention velocity
/// - T: Trend score (recent attention spike)
pub struct FeedRanker {
    pool: SqlitePool,
}

impl FeedRanker {
    pub fn new(pool: SqlitePool) -> Self {
        FeedRanker { pool }
    }

    pub async fn run(&self) -> Result<()> {
        info!("Starting feed ranker loop...");

        loop {
            if let Err(e) = self.update_rankings().await {
                tracing::error!("Error updating rankings: {}", e);
            }

            // Update every 5 minutes
            sleep(Duration::from_secs(300)).await;
        }
    }

    async fn update_rankings(&self) -> Result<()> {
        info!("Computing feed rankings...");

        // Formula: score = 0.3*L + 0.2*R + 0.3*V + 0.2*T
        let query = r#"
            INSERT INTO feed_rankings (id, post_id, score, level_score, reputation_score, attention_score, time_score, calculated_at)
            SELECT
                'fr_' || p.id,
                p.id,
                (
                    0.3 * (CAST(p.level AS REAL) / 5.0) +
                    0.2 * (CAST(COALESCE(author_rep.reputation, 50) AS REAL) / 100000.0) +
                    0.3 * (CAST(p.attention_accumulated AS REAL) / 100000.0) +
                    0.2 * (CASE WHEN p.created_at > datetime('now', '-1 hour') THEN 1.0 ELSE 0.5 END)
                ) as final_score,
                0.3 * (CAST(p.level AS REAL) / 5.0),
                0.2 * (CAST(COALESCE(author_rep.reputation, 50) AS REAL) / 100000.0),
                0.3 * (CAST(p.attention_accumulated AS REAL) / 100000.0),
                0.2 * (CASE WHEN p.created_at > datetime('now', '-1 hour') THEN 1.0 ELSE 0.5 END),
                CAST(strftime('%s', 'now') AS INTEGER)
            FROM posts p
            LEFT JOIN profiles author_rep ON p.author = author_rep.address
            ON CONFLICT (id) DO UPDATE SET
                score = EXCLUDED.score,
                level_score = EXCLUDED.level_score,
                reputation_score = EXCLUDED.reputation_score,
                attention_score = EXCLUDED.attention_score,
                time_score = EXCLUDED.time_score,
                calculated_at = EXCLUDED.calculated_at
        "#;

        sqlx::query(query).execute(&self.pool).await?;

        info!("Rankings updated successfully");
        Ok(())
    }

    /// Get top N posts by ranking
    pub async fn get_top_posts(&self, limit: i64) -> Result<Vec<(String, f64)>> {
        let rows = sqlx::query(
            r#"
            SELECT post_id, score
            FROM feed_rankings
            ORDER BY score DESC
            LIMIT $1
            "#
        )
        .bind(limit)
        .fetch_all(&self.pool)
        .await?;

        Ok(rows.into_iter().map(|row| {
            (
                row.get::<String, _>(0),
                row.get::<f64, _>(1),
            )
        }).collect())
    }
}
