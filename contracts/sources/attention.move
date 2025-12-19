module suiter::attention {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;

    // ============ CONSTANTS ============
    const REWARD_BASE: u64 = 100_000_000; // 0.1 SUI in MIST
    const SESSION_TIMEOUT_SECS: u64 = 600; // 10 minutes
    const MAX_SESSION_DURATION: u64 = 3600; // 1 hour max reward window
    const TIME_DECAY_RATE: u64 = 95; // 95% retention per 10 mins

    // ============ STRUCTS ============

    public struct AttentionSession has key {
        id: UID,
        reader: address,
        post_id: ID,
        started_at: u64,
        ended_at: u64,
        duration_ms: u64,
        reader_rep: u64,
        reward: u64,
        claimed: bool,
    }

    public struct AttentionPool has key {
        id: UID,
        balance: Balance<SUI>,
        total_rewarded: u64,
        session_count: u64,
    }

    // ============ EVENTS ============

    public struct SessionStarted has copy, drop {
        session_id: ID,
        reader: address,
        post_id: ID,
        timestamp: u64,
    }

    public struct SessionEnded has copy, drop {
        session_id: ID,
        duration_ms: u64,
        reward_calculated: u64,
    }

    public struct RewardClaimed has copy, drop {
        session_id: ID,
        amount: u64,
        recipient: address,
    }

    // ============ PUBLIC FUNCTIONS ============

    /// Start an attention session
    public fun start_session(
        reader: address,
        post_id: ID,
        reader_rep: u64,
        ctx: &mut TxContext,
    ): AttentionSession {
        let now = tx_context::epoch_timestamp_ms(ctx) / 1000;

        let session = AttentionSession {
            id: object::new(ctx),
            reader,
            post_id,
            started_at: now,
            ended_at: 0,
            duration_ms: 0,
            reader_rep,
            reward: 0,
            claimed: false,
        };

        sui::event::emit(SessionStarted {
            session_id: object::id(&session),
            reader,
            post_id,
            timestamp: now,
        });

        session
    }

    /// End session and calculate reward
    /// Formula: Reward = BASE × W_time × W_rep
    public fun end_session(
        session: &mut AttentionSession,
        current_timestamp: u64,
    ): u64 {
        let duration_ms = (current_timestamp - session.started_at) * 1000;
        
        if (duration_ms > MAX_SESSION_DURATION * 1000) {
            session.duration_ms = MAX_SESSION_DURATION * 1000;
        } else {
            session.duration_ms = duration_ms;
        };

        session.ended_at = current_timestamp;

        // Calculate time weight: decay after 10 minutes
        let time_intervals = session.duration_ms / (SESSION_TIMEOUT_SECS * 1000);
        let time_weight = pow_u64(TIME_DECAY_RATE, time_intervals);

        // Calculate reputation weight: sqrt(rep) / 100
        let mut rep_weight = sqrt_u64(session.reader_rep) / 100;
        if (rep_weight > 10000) { 
            rep_weight = 10000; 
        };

        // Final reward
        let reward = (REWARD_BASE * time_weight) / 10000;
        let reward = (reward * rep_weight) / 10000;

        session.reward = reward;

        sui::event::emit(SessionEnded {
            session_id: object::id(session),
            duration_ms: session.duration_ms,
            reward_calculated: reward,
        });

        reward
    }

    /// Claim reward from pool
    public fun claim_reward(
        session: &mut AttentionSession,
        pool: &mut AttentionPool,
    ): u64 {
        assert!(!session.claimed, 1);
        assert!(balance::value(&pool.balance) >= session.reward, 2);

        session.claimed = true;
        let amount = session.reward;
        pool.total_rewarded = pool.total_rewarded + amount;

        sui::event::emit(RewardClaimed {
            session_id: object::id(session),
            amount,
            recipient: session.reader,
        });

        amount
    }

    /// Initialize attention pool
    public fun create_pool(ctx: &mut TxContext): AttentionPool {
        AttentionPool {
            id: object::new(ctx),
            balance: balance::zero(),
            total_rewarded: 0,
            session_count: 0,
        }
    }

    /// Fund the pool
    public fun fund_pool(
        pool: &mut AttentionPool,
        amount: Balance<SUI>,
    ) {
        balance::join(&mut pool.balance, amount);
    }

    // ============ PRIVATE HELPERS ============

    fun pow_u64(base: u64, exponent: u64): u64 {
        let mut result: u64 = 10000;
        let mut current_base = base;
        let mut current_exp = exponent;

        while (current_exp > 0) {
            if (current_exp % 2 == 1) {
                result = (result * current_base) / 10000;
            };
            current_base = (current_base * current_base) / 10000;
            current_exp = current_exp / 2;
        };

        result
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

    // ============ VIEW FUNCTIONS ============

    public fun view_session(session: &AttentionSession): (address, u64, u64, u64, bool) {
        (session.reader, session.duration_ms, session.reader_rep, session.reward, session.claimed)
    }

    public fun pool_balance(pool: &AttentionPool): u64 {
        balance::value(&pool.balance)
    }
}
