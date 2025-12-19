# SUITER – Sui SocialFi Protocol

**Building a social protocol where attention earns, truth has cost, and reputation has weight.**

---

## Quick Start

1. **Understand the design**: Read this README (~5 min)
2. **Implement everything**: Follow [SPECIFICATION.md](SPECIFICATION.md) (~1500 lines)
3. **Debug issues**: Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) (~200 lines)

---

## Core Vision

**Sui SocialFi** reimagines social media by treating posts, attention, reputation, and truth as **on-chain, composable objects**.

- **Non-generic social**: Not a Twitter clone, but a protocol
- **Sui-native**: Leverages object-centric architecture
- **Anti-spam**: Reputation-weighted actions
- **Composable**: Posts usable by other apps & protocols
- **Economically aligned**: Creators, readers, communities earn fairly
- **Scalable**: Hybrid on-chain/off-chain feed ranking

---

## Key Concepts

### Living Posts
Posts evolve through 5 levels as they accumulate attention. Each level unlocks new features (media, monetization, NFT minting, governance).

### Reputation Over Followers
Influence is earned via contribution & accountability, not follower count. Reputation is soulbound and decays when inactive.

### Attention Mining
Reading is a first-class action with verified rewards. Readers earn based on duration × reputation × post quality.

### Truth With Stakes
Optional truth claims require stakeholders. Claims resolved via 7-day quadratic voting. False claims have 10x penalties.

### Creator Lifeline
Communities can collectively stake and support creators with monthly payouts (5% annual yield).

---

## System Architecture

```
Frontend (Next.js)
    ↓
Wallet Adapter (Sui)
    ↓
RPC Calls / Indexer
    ↓
Move Smart Contracts
    ↓
Sui Object Store
```

**On-chain**: Posts, profiles, reputation, attention sessions
**Off-chain**: Feed ranking, indexing, caching

---

## Implementation Timeline

| Phase | Duration | Deliverable |
|-------|----------|---|
| **Phase 1** | Week 1 | All Move contracts compile & test pass |
| **Phase 2** | Week 2-3 | Rust indexer catches up, API responds |
| **Phase 3** | Week 3 | NextJS frontend E2E working |
| **Phase 4** | Week 4 | Production deployment with monitoring |

---

## Documentation

- **[SPECIFICATION.md](SPECIFICATION.md)** — Complete technical spec (all formulas, contracts, APIs, debugging)
- **[QUICK_REFERENCE.md](QUICK_REFERENCE.md)** — Cheat sheet (debug commands, error codes, constants)

---

## Key Numbers

**Reputation**: 50–100,000 (soulbound, decays ~0.086%/day)

**Post Levels**: 1→2→3→4→5 at (1k, 5k, 25k, 100k) attention points

**Attention Rewards**: 10 base points × time weight × rep weight × quality weight

**Time Thresholds**: 10s min, 10m optimal, 60m max (diminishing returns)

**Quadratic Voting**: voting_power = reputation^(2/3)

**Creator Payouts**: 5% annual yield on staked SUI

---

## Success Metrics

✓ Attention time per post increasing
✓ Reputation distribution fair (Gini < 0.4)
✓ Creator retention > 80%
✓ Spam rate < 5%
✓ API latency < 500ms (p95)
✓ Feed ranking quality improving

---

## For Developers

1. Clone repo
2. Read [SPECIFICATION.md](SPECIFICATION.md) for complete spec
3. Implement Move contracts (modules 1-6)
4. Deploy Rust indexer
5. Launch NextJS frontend
6. Use [QUICK_REFERENCE.md](QUICK_REFERENCE.md) when debugging

---

**Status**: Specifications Complete & Ready for Implementation
**Last Updated**: December 18, 2024
* Activity deadline
* Reward rules

Purpose:

* Incentivize consistency
* Protect supporters

---

## 6. Core Mechanics

### 6.1 Attention Mining Formula

**Precise Definition:**

```
BaseReward = T(s) × R(reader) × Q(post)

where:
  T(s) = Time weight function
        = 1.0 for 0 < s ≤ 300s (5 min)
        = 0.5 × e^(-(s-300)/600) for s > 300s
        (exponential decay, half-life 10min)
  
  R(reader) = (reader_rep / max_rep)^0.5
             (square-root weighting to reduce whale dominance)
  
  Q(post) = (attention_pool_size / initial_pool)^0.1
           (log-scale, diminishing returns)
```

**Anti-Gaming Mechanisms:**
- Session randomness: Browser sends cryptographic commitment hash before reading
- Max 10 attention sessions per user per 24h
- Reward linearly decays to 0 after 30 min engagement

**Reward Split:**
* Creator: 50%
* Reader: 30%
* Attention Pool: 20%

**Finality:** All rewards settled on-chain after 24h cooldown (prevents flash attacks)

---

### 6.2 Post Evolution Logic

Post level increases when thresholds are met:

* Attention accumulated
* Reputation‑weighted interactions
* Truth score (if applicable)

---

### 6.3 Token‑Locked Conversations

Posts define reply constraints:

* Minimum reputation
* NFT ownership
* Creator token ownership

Benefits:

* Spam prevention
* High‑signal discussions

---

## 7. Feed Ranking Algorithm (Off‑Chain)

Rank Score =

* Post Level
* Creator Reputation
* Attention Velocity
* Truth Score
* Reader Affinity

No follower count is used.

---

## 8. Security & Abuse Prevention

* Reputation decay
* Diminishing attention rewards
* Sybil resistance via reputation weighting
* Stake slashing for false claims

---

## 9. MVP Scope (30 Days)

### Phase 1

* Profile object
* Post object
* Create/read posts

### Phase 2

* Attention sessions
* Post leveling (L1–L3)

### Phase 3

* Reputation system
* Token‑locked replies

### Phase 4

* Minimal frontend
* Testnet deployment

---

## 10. Future Extensions

* DAO governance via L5 posts
* Cross‑app post composition
* Advanced reputation markets
* Mobile client

---

## 11. Success Metrics

* Average attention time per post
* Reputation distribution fairness
* Creator retention
* Spam rate

---

## 12. Summary

Sui SocialFi is not a social app.

It is a **social protocol** where:

* Attention earns
* Truth has cost
* Reputation has weight
* Content lives as assets

Built only because Sui makes it possible.
