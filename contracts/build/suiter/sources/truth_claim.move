module suiter::truth_claim {
    use sui::object::{Self, UID, ID};
    use sui::tx_context::{Self, TxContext};

    // ============ CONSTANTS ============
    const MIN_REPUTATION_TO_VOTE: u64 = 50;
    const MIN_REPUTATION_TO_CLAIM: u64 = 100;
    const VOTING_PERIOD: u64 = 7 * 24 * 3600; // 7 days
    const CLAIM_THRESHOLD: u64 = 51; // 51% consensus needed

    // ============ STRUCTS ============

    public struct TruthClaim has key {
        id: UID,
        post_id: ID,
        claimer: address,
        claim_text: vector<u8>,
        created_at: u64,
        voting_end: u64,
        votes_yes: u64,
        votes_no: u64,
        voters: vector<address>,
        resolved: bool,
        accepted: bool,
    }

    // ============ EVENTS ============

    public struct ClaimCreated has copy, drop {
        claim_id: ID,
        post_id: ID,
        claimer: address,
        voting_end: u64,
    }

    public struct VoteCasted has copy, drop {
        claim_id: ID,
        voter: address,
        vote: bool, // true = yes, false = no
    }

    public struct ClaimResolved has copy, drop {
        claim_id: ID,
        accepted: bool,
        yes_votes: u64,
        no_votes: u64,
    }

    // ============ PUBLIC FUNCTIONS ============

    /// Create a new truth claim on a post
    public fun create_claim(
        post_id: ID,
        claimer: address,
        claim_text: vector<u8>,
        claimer_rep: u64,
        ctx: &mut TxContext,
    ): TruthClaim {
        assert!(claimer_rep >= MIN_REPUTATION_TO_CLAIM, 1);
        assert!(!claim_text.is_empty(), 2);

        let now = tx_context::epoch_timestamp_ms(ctx) / 1000;
        let voting_end = now + VOTING_PERIOD;

        let claim = TruthClaim {
            id: object::new(ctx),
            post_id,
            claimer,
            claim_text,
            created_at: now,
            voting_end,
            votes_yes: 0,
            votes_no: 0,
            voters: vector::empty(),
            resolved: false,
            accepted: false,
        };

        sui::event::emit(ClaimCreated {
            claim_id: object::id(&claim),
            post_id,
            claimer,
            voting_end,
        });

        claim
    }

    /// Cast a vote on a claim (quadratic: votes = floor(sqrt(rep)))
    public fun vote_on_claim(
        claim: &mut TruthClaim,
        voter: address,
        vote: bool,
        voter_rep: u64,
        current_time: u64,
    ): u64 {
        assert!(voter_rep >= MIN_REPUTATION_TO_VOTE, 1);
        assert!(current_time < claim.voting_end, 2);
        assert!(!has_voted(claim, voter), 3);

        // Quadratic voting: votes = floor(sqrt(rep))
        let voting_power = sqrt_u64(voter_rep);

        if (vote) {
            claim.votes_yes = claim.votes_yes + voting_power;
        } else {
            claim.votes_no = claim.votes_no + voting_power;
        };

        vector::push_back(&mut claim.voters, voter);

        sui::event::emit(VoteCasted {
            claim_id: object::id(claim),
            voter,
            vote,
        });

        voting_power
    }

    /// Resolve claim after voting period ends
    /// Returns true if claim accepted (yes > no)
    public fun resolve_claim(
        claim: &mut TruthClaim,
        current_time: u64,
    ): bool {
        assert!(!claim.resolved, 1);
        assert!(current_time >= claim.voting_end, 2);

        claim.resolved = true;
        let accepted = claim.votes_yes > claim.votes_no;
        claim.accepted = accepted;

        sui::event::emit(ClaimResolved {
            claim_id: object::id(claim),
            accepted,
            yes_votes: claim.votes_yes,
            no_votes: claim.votes_no,
        });

        accepted
    }

    /// Check if user already voted
    fun has_voted(claim: &TruthClaim, voter: address): bool {
        let mut i = 0;
        let len = vector::length(&claim.voters);
        
        while (i < len) {
            if (*vector::borrow(&claim.voters, i) == voter) {
                return true
            };
            i = i + 1;
        };
        
        false
    }

    /// Get claim vote counts
    public fun get_votes(claim: &TruthClaim): (u64, u64) {
        (claim.votes_yes, claim.votes_no)
    }

    /// Check if claim is accepted
    public fun is_accepted(claim: &TruthClaim): bool {
        claim.accepted
    }

    // ============ PRIVATE HELPERS ============

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
