-- Monitoring queries for SUITER system

-- Monitor reputation distribution
SELECT
    address,
    reputation,
    total_posts,
    total_attention_earned,
    ROUND(EXTRACT(EPOCH FROM (NOW() - joined_at))/86400) as days_active
FROM profiles
ORDER BY reputation DESC
LIMIT 20;

-- Monitor post performance
SELECT
    p.id,
    p.author,
    p.level,
    p.attention_accumulated,
    COUNT(DISTINCT a.reader) as unique_readers,
    ROUND(EXTRACT(EPOCH FROM (NOW() - p.created_at))/3600) as hours_old
FROM posts p
LEFT JOIN attention_sessions a ON p.id = a.post_id
GROUP BY p.id, p.author, p.level, p.attention_accumulated, p.created_at
ORDER BY p.attention_accumulated DESC
LIMIT 20;

-- Monitor attention reward distribution
SELECT
    reader,
    COUNT(*) as sessions,
    SUM(reward) as total_reward,
    SUM(CASE WHEN claimed THEN 1 ELSE 0 END) as claimed_count,
    AVG(CASE WHEN claimed THEN 1 ELSE 0 END) * 100 as claim_rate
FROM attention_sessions
GROUP BY reader
ORDER BY total_reward DESC
LIMIT 20;

-- Monitor feed ranking quality
SELECT
    fr.post_id,
    fr.score,
    p.level,
    p.attention_accumulated,
    COUNT(DISTINCT a.reader) as reader_count
FROM feed_rankings fr
JOIN posts p ON fr.post_id = p.id
LEFT JOIN attention_sessions a ON p.id = a.post_id
ORDER BY fr.score DESC
LIMIT 20;

-- Monitor truth claim activity
SELECT
    tc.id,
    tc.post_id,
    tc.claimer,
    tc.votes_yes,
    tc.votes_no,
    CASE
        WHEN tc.votes_yes > tc.votes_no THEN 'YES'
        WHEN tc.votes_no > tc.votes_yes THEN 'NO'
        ELSE 'TIE'
    END as leading_vote,
    ROUND(EXTRACT(EPOCH FROM (COALESCE(tc.voting_end, NOW()) - NOW()))/3600) as hours_until_end
FROM truth_claims tc
WHERE NOT tc.resolved
ORDER BY tc.created_at DESC;

-- Monitor reputation changes (identify Sybil attacks)
SELECT
    address,
    reputation,
    CASE
        WHEN total_posts = 0 AND reputation > 50 THEN 'SUSPICIOUS'
        WHEN total_posts > 100 AND reputation < 100 THEN 'LOW_ENGAGEMENT'
        WHEN reputation > 80000 THEN 'HIGH_REP'
        ELSE 'NORMAL'
    END as status
FROM profiles
WHERE reputation != 50 OR total_posts > 0
ORDER BY reputation DESC;
