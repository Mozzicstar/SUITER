# Sui SocialFi Protocol – Design Document

## 1. Overview

**Sui SocialFi** is a next‑generation social protocol built on the Sui blockchain. It reimagines social media by treating posts, attention, reputation, and truth as **on‑chain, composable objects**. The system is designed to eliminate fake engagement, reward genuine attention, and align creators, readers, and communities economically.

> Core thesis: *Attention, reputation, and truth should be provable, valuable, and composable.*

---

## 2. Design Goals

1. **Non‑Generic Social** – Not a Twitter clone
2. **Sui‑Native** – Leverage object‑centric architecture
3. **Anti‑Spam / Anti‑Bot** – Reputation‑weighted actions
4. **Composable** – Posts usable by other apps
5. **Economically Aligned** – Attention and truth are rewarded
6. **Scalable** – Hybrid on‑chain/off‑chain feed

---

## 3. Core Concepts

### 3.1 Living Posts

Posts are not static text. They:

* Evolve over time
* Accumulate value
* Unlock capabilities

### 3.2 Attention Mining

Reading is a **first‑class action**, not passive consumption.

### 3.3 Reputation > Followers

Influence is earned via contribution and accountability.

### 3.4 Truth With Stakes

Claims require skin‑in‑the‑game.

---

## 4. System Architecture

### 4.1 High‑Level Architecture

Frontend (Next.js)
↓
Sui Wallet Adapter
↓
Sui RPC / Indexer
↓
Move Smart Contracts
↓
Sui Object Store

### 4.2 Hybrid Feed Strategy

* **On‑chain**: Posts, reputation, attention sessions
* **Off‑chain**: Feed assembly, ranking, caching

---

## 5. Core On‑Chain Objects

### 5.1 Profile Object

Represents identity and reputation.

Fields:

* UID
* Owner address
* Reputation score (soulbound)
* Creator token capability (optional)
* Activity metadata

Purpose:

* Identity
* Access control
* Feed weighting

---

### 5.2 Post Object (Living Asset)

Fields:

* UID
* Author
* Immutable content hash
* Creation timestamp
* Post level (1–5)
* Attention pool
* Stake pool (optional)
* Access rules
* NFT capability (locked/unlocked)

Post Levels:

1. Text only
2. Media unlocked
3. Monetization enabled
4. NFT mintable
5. Governance enabled

---

### 5.3 AttentionSession Object

Represents verified reading.

Fields:

* UID
* Reader address
* Post reference
* Start timestamp
* Duration
* Validity flag

Used for:

* Attention mining
* Reputation calculation
* Feed ranking

---

### 5.4 Reputation Object (Soulbound)

Properties:

* Non‑transferable
* Decays over time
* Weighted by reputation of contributors

Sources of reputation:

* High‑quality posts
* Attention earned
* Truth claims resolved positively

---

### 5.5 TruthClaim Object

Optional extension of a post.

Fields:

* Post reference
* Creator stake
* Claim deadline
* Resolution status
* Community voting weights

Outcomes:

* True → reward + reputation
* False → stake slashed + reputation loss

---

### 5.6 Creator Lifeline Object

Community‑backed commitment contract.

Fields:

* Creator address
* Supporter stakes
* Activity deadline
* Reward rules

Purpose:

* Incentivize consistency
* Protect supporters

---

## 6. Core Mechanics

### 6.1 Attention Mining Formula

Reward = Time × ReaderRep × PostQuality

Reward Split:

* Creator: 50%
* Reader: 30%
* Attention Pool: 20%

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
