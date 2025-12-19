module suiter::reputation {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};

    // ============ CONSTANTS ============
    const BASE_GAIN: u64 = 10; // Base points per attention reward
    const BASE_LOSS: u64 = 5;  // Base points for post not gaining attention
    const DOUBT_THRESHOLD: u64 = 3; // Min votes to activate doubt
    const DOUBT_MULTIPLIER: u64 = 2; // Loss multiplier if doubted

    // ============ STRUCTS ============

    public struct ReputationLog has key {
        id: UID,
        user: address,
        total_gained: u64,
        total_lost: u64,
        event_count: u64,
    }

    // ============ EVENTS ============

    public struct ReputationGained has copy, drop {
        user: address,
        amount: u64,
        reason: vector<u8>,
    }

    public struct ReputationLost has copy, drop {
        user: address,
        amount: u64,
        reason: vector<u8>,
    }

    // ============ PUBLIC FUNCTIONS ============

    /// Calculate reputation gain from attention reward
    /// gain = BASE_GAIN × log(reward + 1)
    public fun calculate_attention_gain(attention_reward: u64): u64 {
        let log_reward = log_u64(attention_reward + 1);
        (BASE_GAIN * log_reward) / 10000
    }

    /// Calculate reputation loss for abandoned post
    /// loss = BASE_LOSS × sqrt(days_inactive)
    public fun calculate_abandonment_loss(days_inactive: u64): u64 {
        let sqrt_days = sqrt_u64(days_inactive as u64);
        (BASE_LOSS * sqrt_days) / 100
    }

    /// Calculate loss from doubt votes
    /// loss = BASE_LOSS × (1 + doubt_votes) × DOUBT_MULTIPLIER
    public fun calculate_doubt_loss(base_loss: u64, doubt_votes: u64): u64 {
        if (doubt_votes < DOUBT_THRESHOLD) {
            return 0
        };
        
        let loss = base_loss * (1 + doubt_votes) * DOUBT_MULTIPLIER;
        loss
    }

    // ============ PRIVATE HELPERS ============

    fun log_u64(n: u64): u64 {
        if (n <= 1) return 0;
        
        let mut result: u64 = 0;
        let mut x = n;
        
        while (x > 1) {
            x = x / 2;
            result = result + 1;
        };
        
        result * 10000
    }

    fun sqrt_u64(n: u64): u64 {
        if (n == 0) return 0;
        
        let mut x = n;
        let mut y = (x + 1) / 2;

        while (y < x) {
            x = y;
            y = (x + n / x) / 2;
        };

        x
    }
}
