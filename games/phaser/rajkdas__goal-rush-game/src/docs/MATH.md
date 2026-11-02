# GOAL RUSH — Slot mathematics (PAR sheet)

This is the complete, auditable math model of the *Stadium Slots* component. The
executable source of truth is [`src/game/config/slots.config.ts`](../src/game/config/slots.config.ts);
`bun scripts/rtp-simulation.ts` regenerates [`RTP-RESULTS.md`](RTP-RESULTS.md) from it
(exact combinatorics cross-checked with 2,000,000 Monte-Carlo spins per mode).

> **Virtual credits only.** GOAL RUSH is an arcade prototype; there is no
> real-money play, no purchases, and no player-losing design goal. The RTP framing
> below exists to hold the math to a professional slot standard.

## 1. Reel strips (base game)

Each reel is a physical strip of 64 stops; a spin draws **one stop index per reel,
uniformly**. Symbol probabilities therefore emerge from strip composition.

| Symbol | Reel 1 | Reel 2 | Reel 3 | P(r1) | P(r2) | P(r3) |
|---|---|---|---|---|---|---|
| Soccer Ball | 18 | 18 | 18 | 0.2813 | 0.2813 | 0.2813 |
| Golden Boot | 16 | 16 | 16 | 0.2500 | 0.2500 | 0.2500 |
| Keeper Glove | 12 | 12 | 12 | 0.1875 | 0.1875 | 0.1875 |
| Team Jersey | 9 | 9 | 9 | 0.1406 | 0.1406 | 0.1406 |
| Yellow Card | 4 | 4 | 4 | 0.0625 | 0.0625 | 0.0625 |
| Stadium Star | 3 | 3 | 3 | 0.0469 | 0.0469 | 0.0469 |
| Ref Whistle | 1 | 1 | 1 | 0.0156 | 0.0156 | 0.0156 |
| Championship Trophy | 1 | 1 | 1 | 0.0156 | 0.0156 | 0.0156 |
| **Total stops** | **64** | **64** | **64** | | | |

Strip order within a reel is deterministic (seeded shuffle) and does not affect
single-line probabilities; it only affects on-screen realism.

## 2. Paytable (single center payline — ANY pair pays)

| Symbol | ×3 pays | Any pair pays |
|---|---|---|
| Soccer Ball | 250 | 40 |
| Golden Boot | 400 | 45 |
| Keeper Glove | 550 | 65 |
| Team Jersey | 800 | 95 |
| Yellow Card | 1,000 | 135 |
| Stadium Star | 1,200 | 170 |
| Ref Whistle | 2,000 | 260 |
| Championship Trophy | **PROGRESSIVE JACKPOT** | 450 |

Any two matching symbols anywhere on the payline (reels 1-2, 2-3 or 1-3) pay the
pair value; three-of-a-kind supersedes the pair. Every symbol pays on a pair —
no dead outcomes. The two-trophy pair pays **and** plays the “ONE TROPHY AWAY”
near-miss presentation.

**OFFSIDE** — a losing spin (blank line that is not a trophy near-miss) is flagged
by the referee with probability 0.35 (`OFFSIDE_PROBABILITY`): the reel panel
shows OFFSIDE! and the table wipes the G-O-A-L multiplier. A miss is a risk,
not a dead pause.

## 3. Golden Reels (skill-earned bonus)

Clearing the four drop-target bank awards a **Golden Spin** played on modified strips
where trophy counts are multiplied by 47 (keeping ≈ 1-in-13 jackpot odds after the
base strips were concentrated):

| Reel | Trophy stops | Total stops | P(trophy) |
|---|---|---|---|
| 1 | 47 | 110 | 0.4273 |
| 2 | 47 | 110 | 0.4273 |
| 3 | 47 | 110 | 0.4273 |

P(jackpot | golden) = 0.4273³ ≈ **7.80 % → 1 in 13**.

Golden spins are *earned* (clear the four drop targets — a ball that rolls the bank
clears it in one shot), putting the jackpot within reach of a session while the
base-game odds keep the dream rare.

## 4. Verified results

Exact probabilities from strip composition; Monte-Carlo over 2M spins per mode
(full tables in [`RTP-RESULTS.md`](RTP-RESULTS.md)):

| Mode | Paying-hit frequency | RTP excl. jackpot¹ | Jackpot odds |
|---|---|---|---|
| Base | **51.42 %** | 446.65 %² | 1 in 262,144 |
| Golden | **57.90 %** | 1,546.02 %² | **1 in 13** |

¹ Against the **nominal spin cost of 10 credits** — an accounting convention so the
math can be compared with a conventional slot. In GOAL RUSH spins are *earned* by
pinball play; no credit is deducted for a spin.
² Above 100 % **by design**: spins are a reward loop, not a wager. The generous
return is the point — over half of spins pay, pair wins are sized to feel like
real wins, and the blank lines still carry the OFFSIDE risk/reward beat.

## 5. Progressive jackpot

| Rule | Value |
|---|---|
| Seed | 500 credits |
| Growth | +2 bumper, +1 slingshot, +1 spinner rev, +3 drop target, +1 lane letter, +10 GOAL complete, +5 saucer |
| Win condition | Three trophies on the payline |
| On win | Player receives the full pot; pot resets to seed |

The pot persists across sessions (`localStorage`) and its growth rate is bounded by
table-event frequency, so it self-balances between jackpot hits.

## 6. Multiplier interaction

Spelling G·O·A·L in the rollover lanes raises the win multiplier (×2 … ×5, resets on
ball loss or an OFFSIDE flag). The multiplier applies to **line wins only** (not the
jackpot pot). At ×5 every line win pays five-fold — the skill premium, mirroring how
real pinball machines pay better multipliers to better players.

## 7. RNG integrity

- Entropy: `crypto.getRandomValues` (Web Crypto) with **rejection sampling** — every
  stop index is exactly uniform (no modulo bias). `Math.random` is only a fallback.
- Draw model: one independent uniform stop per reel, decided **before** any
  animation begins; reels are animated to land on the result. Presentation can never
  influence the outcome.
- Reproducibility: the PAR sheet and the golden-strip generator use a documented
  seeded PRNG (mulberry32), so every number in this document can be regenerated.
