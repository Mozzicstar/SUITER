module suiter::post {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};

    // ============ CONSTANTS ============
    const LEVEL_1_THRESHOLD: u64 = 0;      // Any post starts at L1
    const LEVEL_2_THRESHOLD: u64 = 1_000;  // 1k attention
    const LEVEL_3_THRESHOLD: u64 = 5_000;  // 5k attention
    const LEVEL_4_THRESHOLD: u64 = 25_000; // 25k attention
    const LEVEL_5_THRESHOLD: u64 = 100_000; // 100k attention

    // ============ STRUCTS ============

    public struct Post has key {
        id: UID,
        author: address,
        content_hash: vector<u8>,
        attention_accumulated: u64,
        level: u8,
        created_at: u64,
        last_leveled_up: u64,
        reply_count: u64,
    }

    // ============ EVENTS ============

    public struct PostCreated has copy, drop {
        post_id: ID,
        author: address,
        content_hash: vector<u8>,
        timestamp: u64,
    }

    public struct AttentionAdded has copy, drop {
        post_id: ID,
        amount: u64,
        new_total: u64,
    }

    public struct PostLeveledUp has copy, drop {
        post_id: ID,
        old_level: u8,
        new_level: u8,
        attention: u64,
    }

    // ============ PUBLIC FUNCTIONS ============

    /// Create a new post
    public fun create_post(
        author: address,
        content_hash: vector<u8>,
        ctx: &mut TxContext,
    ): Post {
        assert!(!content_hash.is_empty(), 1);
        
        let timestamp = tx_context::epoch_timestamp_ms(ctx) / 1000;
        let post = Post {
            id: object::new(ctx),
            author,
            content_hash,
            attention_accumulated: 0,
            level: 1,
            created_at: timestamp,
            last_leveled_up: timestamp,
            reply_count: 0,
        };

        sui::event::emit(PostCreated {
            post_id: object::id(&post),
            author,
            content_hash,
            timestamp,
        });

        post
    }

    /// Add attention to post and auto-level up if thresholds met
    public fun add_attention(post: &mut Post, amount: u64): u8 {
        let old_attention = post.attention_accumulated;
        post.attention_accumulated = post.attention_accumulated + amount;
        let new_attention = post.attention_accumulated;

        let old_level = post.level;
        let new_level = calculate_level(new_attention);

        if (new_level > old_level) {
            post.level = new_level;

            sui::event::emit(PostLeveledUp {
                post_id: object::id(post),
                old_level,
                new_level,
                attention: new_attention,
            });
        };

        sui::event::emit(AttentionAdded {
            post_id: object::id(post),
            amount,
            new_total: new_attention,
        });

        post.level
    }

    /// Get current post level
    public fun get_level(post: &Post): u8 {
        post.level
    }

    /// Get attention accumulated
    public fun get_attention(post: &Post): u64 {
        post.attention_accumulated
    }

    /// Increment reply counter
    public fun add_reply(post: &mut Post) {
        post.reply_count = post.reply_count + 1;
    }

    /// Get reply count
    public fun get_reply_count(post: &Post): u64 {
        post.reply_count
    }

    /// Get author address
    public fun get_author(post: &Post): address {
        post.author
    }

    /// Get post content hash
    public fun get_content_hash(post: &Post): vector<u8> {
        post.content_hash
    }

    // ============ PRIVATE HELPERS ============

    fun calculate_level(attention: u64): u8 {
        if (attention >= LEVEL_5_THRESHOLD) {
            5
        } else if (attention >= LEVEL_4_THRESHOLD) {
            4
        } else if (attention >= LEVEL_3_THRESHOLD) {
            3
        } else if (attention >= LEVEL_2_THRESHOLD) {
            2
        } else {
            1
        }
    }

    // ============ VIEW FUNCTIONS ============

    public fun view_post(post: &Post): (address, u64, u8, u64) {
        (post.author, post.attention_accumulated, post.level, post.reply_count)
    }

    public fun get_level_threshold(level: u8): u64 {
        if (level == 1) {
            LEVEL_1_THRESHOLD
        } else if (level == 2) {
            LEVEL_2_THRESHOLD
        } else if (level == 3) {
            LEVEL_3_THRESHOLD
        } else if (level == 4) {
            LEVEL_4_THRESHOLD
        } else if (level == 5) {
            LEVEL_5_THRESHOLD
        } else {
            0
        }
    }
}
