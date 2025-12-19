use anyhow::Result;
use sqlx::PgPool;
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
    pool: PgPool,
}

impl FeedRanker {
    pub fn new(pool: PgPool) -> Self {
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
            INSERT INTO feed_rankings (post_id, score, level_weight, reputation_weight, attention_weight, trend_weight)
            SELECT
                p.id,
                (
                    0.3 * (p.level::DECIMAL / 5.0) +
                    0.2 * (author_rep.reputation::DECIMAL / 100000.0) +
                    0.3 * (p.attention_accumulated::DECIMAL / 100000.0) +
                    0.2 * (CASE WHEN p.created_at > NOW() - INTERVAL '1 hour' THEN 1.0 ELSE 0.5 END)
                ) as final_score,
                0.3 * (p.level::DECIMAL / 5.0),
                0.2 * (author_rep.reputation::DECIMAL / 100000.0),
                0.3 * (p.attention_accumulated::DECIMAL / 100000.0),
                0.2 * (CASE WHEN p.created_at > NOW() - INTERVAL '1 hour' THEN 1.0 ELSE 0.5 END)
            FROM posts p
            LEFT JOIN profiles author_rep ON p.author = author_rep.address
            ON CONFLICT (post_id) DO UPDATE SET
                score = EXCLUDED.score,
                level_weight = EXCLUDED.level_weight,
                reputation_weight = EXCLUDED.reputation_weight,
                attention_weight = EXCLUDED.attention_weight,
                trend_weight = EXCLUDED.trend_weight,
                computed_at = NOW()
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
                row.get::<String, _>("post_id"),
                row.get::<f64, _>("score"),
            )
        }).collect())
    }
}
