module suiter::profile {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::math;

    // ============ CONSTANTS ============
    const MIN_REPUTATION: u64 = 50;
    const MAX_REPUTATION: u64 = 100_000;
    const DECAY_RATE: u64 = 95; // 95% retention per day (basis points)
    const REPUTATION_FLOOR: u64 = 50;
    const E_INVALID_REP: u64 = 1;

    // ============ STRUCTS ============
    
    /// User reputation object (soulbound to address)
    public struct Profile has key {
        id: UID,
        owner: address,
        reputation: u64,
        last_updated: u64,
        total_posts: u64,
        total_attention_earned: u64,
        joined_at: u64,
    }

    // ============ EVENTS ============
    
    public struct ProfileCreated has copy, drop {
        profile_id: ID,
        owner: address,
        timestamp: u64,
    }

    public struct ReputationUpdated has copy, drop {
        profile_id: ID,
        old_rep: u64,
        new_rep: u64,
        reason: vector<u8>,
    }

    public struct ReputationDecayed has copy, drop {
        profile_id: ID,
        old_rep: u64,
        new_rep: u64,
        days_inactive: u64,
    }

    // ============ PUBLIC FUNCTIONS ============

    /// Create a new profile for user
    public fun create_profile(ctx: &mut TxContext): Profile {
        let owner = tx_context::sender(ctx);
        let timestamp = tx_context::epoch_timestamp_ms(ctx) / 1000;
        
        let profile = Profile {
            id: object::new(ctx),
            owner,
            reputation: MIN_REPUTATION,
            last_updated: timestamp,
            total_posts: 0,
            total_attention_earned: 0,
            joined_at: timestamp,
        };

        let profile_id = object::id(&profile);
        sui::event::emit(ProfileCreated {
            profile_id,
            owner,
            timestamp,
        });

        profile
    }

    /// Add reputation (capped at MAX_REPUTATION)
    public fun add_reputation(profile: &mut Profile, amount: u64): u64 {
        let old_rep = profile.reputation;
        let new_rep = if (old_rep + amount > MAX_REPUTATION) {
            MAX_REPUTATION
        } else {
            old_rep + amount
        };
        
        profile.reputation = new_rep;

        if (new_rep == MAX_REPUTATION && old_rep < MAX_REPUTATION) {
            sui::event::emit(ReputationUpdated {
                profile_id: object::id(profile),
                old_rep,
                new_rep,
                reason: b"reputation_capped_at_max",
            });
        };

        new_rep
    }

    /// Remove reputation (floor at MIN_REPUTATION)
    public fun remove_reputation(profile: &mut Profile, amount: u64): u64 {
        let old_rep = profile.reputation;
        let new_rep = if (old_rep < amount) {
            MIN_REPUTATION
        } else if (old_rep - amount < MIN_REPUTATION) {
            MIN_REPUTATION
        } else {
            old_rep - amount
        };

        profile.reputation = new_rep;

        if (new_rep == MIN_REPUTATION && old_rep > MIN_REPUTATION) {
            sui::event::emit(ReputationUpdated {
                profile_id: object::id(profile),
                old_rep,
                new_rep,
                reason: b"reputation_floored_at_min",
            });
        };

        new_rep
    }

    /// Apply time-based decay: rep(t) = rep₀ × (0.95)^(days_inactive)
    public fun apply_decay(profile: &mut Profile, days_inactive: u64): u64 {
        if (days_inactive == 0) {
            return profile.reputation
        };

        let decay_multiplier = pow_u64(DECAY_RATE, days_inactive);
        let decayed_rep = (profile.reputation * decay_multiplier) / 10000;
        
        let final_rep = if (decayed_rep < MIN_REPUTATION) {
            MIN_REPUTATION
        } else {
            decayed_rep
        };

        let old_rep = profile.reputation;
        profile.reputation = final_rep;

        sui::event::emit(ReputationDecayed {
            profile_id: object::id(profile),
            old_rep,
            new_rep: final_rep,
            days_inactive,
        });

        final_rep
    }

    /// Get current reputation
    public fun get_reputation(profile: &Profile): u64 {
        profile.reputation
    }

    /// Get owner address
    public fun get_owner(profile: &Profile): address {
        profile.owner
    }

    /// Increment post counter
    public fun increment_posts(profile: &mut Profile) {
        profile.total_posts = profile.total_posts + 1;
    }

    /// Add to total attention earned
    public fun add_attention_earned(profile: &mut Profile, amount: u64) {
        profile.total_attention_earned = profile.total_attention_earned + amount;
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

    // ============ VIEW FUNCTIONS ============

    public fun view_profile(profile: &Profile): (address, u64, u64, u64) {
        (profile.owner, profile.reputation, profile.total_posts, profile.total_attention_earned)
    }
}
