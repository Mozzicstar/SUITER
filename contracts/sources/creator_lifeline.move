module suiter::creator_lifeline {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};
    use sui::balance::{Self, Balance};
    use sui::sui::SUI;
    use sui::coin;
    use sui::transfer;

    // ============ CONSTANTS ============
    const MIN_SUPPORT_AMOUNT: u64 = 10_000_000; // 0.01 SUI
    const MAX_DAILY_SUPPORT: u64 = 100_000_000_000; // 100 SUI per day
    const LIFELINE_THRESHOLD: u64 = 50; // Min reputation to receive lifeline

    // ============ STRUCTS ============

    public struct LifelineSupport has key {
        id: UID,
        recipient: address,
        total_received: u64,
        supporter_count: u64,
        last_updated: u64,
        active: bool,
    }

    public struct SupportTransaction has key {
        id: UID,
        supporter: address,
        recipient: address,
        amount: u64,
        timestamp: u64,
    }

    // ============ EVENTS ============

    public struct SupportSent has copy, drop {
        supporter: address,
        recipient: address,
        amount: u64,
        timestamp: u64,
    }

    public struct LifelineCreated has copy, drop {
        recipient: address,
        created_at: u64,
    }

    // ============ PUBLIC FUNCTIONS ============

    /// Create lifeline for creator (requires min reputation)
    public fun create_lifeline(
        recipient: address,
        recipient_rep: u64,
        ctx: &mut TxContext,
    ): LifelineSupport {
        assert!(recipient_rep >= LIFELINE_THRESHOLD, 1);

        let now = tx_context::epoch_timestamp_ms(ctx) / 1000;
        let lifeline = LifelineSupport {
            id: object::new(ctx),
            recipient,
            total_received: 0,
            supporter_count: 0,
            last_updated: now,
            active: true,
        };

        sui::event::emit(LifelineCreated {
            recipient,
            created_at: now,
        });

        lifeline
    }

    /// Send support to creator
    public fun send_support(
        lifeline: &mut LifelineSupport,
        supporter: address,
        amount: Balance<SUI>,
        ctx: &mut TxContext,
    ) {
        assert!(lifeline.active, 1);
        assert!(balance::value(&amount) >= MIN_SUPPORT_AMOUNT, 2);

        let support_amount = balance::value(&amount);
        lifeline.total_received = lifeline.total_received + support_amount;
        lifeline.supporter_count = lifeline.supporter_count + 1;
        lifeline.last_updated = tx_context::epoch_timestamp_ms(ctx) / 1000;

        sui::event::emit(SupportSent {
            supporter,
            recipient: lifeline.recipient,
            amount: support_amount,
            timestamp: lifeline.last_updated,
        });

        // Transfer SUI to recipient
        transfer::public_transfer(coin::from_balance(amount, ctx), lifeline.recipient);
        // This would require proper implementation with coin handling
    }

    /// Deactivate lifeline
    public fun deactivate_lifeline(lifeline: &mut LifelineSupport) {
        lifeline.active = false;
    }

    /// Get total support received
    public fun get_total_support(lifeline: &LifelineSupport): u64 {
        lifeline.total_received
    }

    /// Get supporter count
    public fun get_supporter_count(lifeline: &LifelineSupport): u64 {
        lifeline.supporter_count
    }

    // ============ VIEW FUNCTIONS ============

    public fun view_lifeline(lifeline: &LifelineSupport): (address, u64, u64, bool) {
        (lifeline.recipient, lifeline.total_received, lifeline.supporter_count, lifeline.active)
    }
}
