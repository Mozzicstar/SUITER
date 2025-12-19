#[cfg(test)]
module suiter::profile_tests {
    use suiter::profile::{Self, Profile};
    use sui::tx_context;

    #[test]
    fun test_create_profile() {
        let ctx = &mut tx_context::dummy();
        let profile = profile::create_profile(ctx);
        
        assert!(profile::get_reputation(&profile) == 50, 1); // MIN_REPUTATION
        assert!(profile::get_owner(&profile) == tx_context::sender(ctx), 2);
        
        let _ = profile;
    }

    #[test]
    fun test_add_reputation() {
        let ctx = &mut tx_context::dummy();
        let mut profile = profile::create_profile(ctx);
        
        let old_rep = profile::get_reputation(&profile);
        profile::add_reputation(&mut profile, 50);
        let new_rep = profile::get_reputation(&profile);
        
        assert!(new_rep == old_rep + 50, 1);
        
        let _ = profile;
    }

    #[test]
    fun test_reputation_capped_at_max() {
        let ctx = &mut tx_context::dummy();
        let mut profile = profile::create_profile(ctx);
        
        // Try to add more than MAX_REPUTATION
        profile::add_reputation(&mut profile, 200_000);
        
        assert!(profile::get_reputation(&profile) == 100_000, 1); // MAX_REPUTATION
        
        let _ = profile;
    }

    #[test]
    fun test_remove_reputation() {
        let ctx = &mut tx_context::dummy();
        let mut profile = profile::create_profile(ctx);
        
        profile::add_reputation(&mut profile, 100);
        let rep_before = profile::get_reputation(&profile);
        
        profile::remove_reputation(&mut profile, 50);
        let rep_after = profile::get_reputation(&profile);
        
        assert!(rep_after == rep_before - 50, 1);
        
        let _ = profile;
    }

    #[test]
    fun test_reputation_floored_at_min() {
        let ctx = &mut tx_context::dummy();
        let mut profile = profile::create_profile(ctx);
        
        profile::remove_reputation(&mut profile, 200);
        assert!(profile::get_reputation(&profile) == 50, 1); // MIN_REPUTATION
        
        let _ = profile;
    }
}
