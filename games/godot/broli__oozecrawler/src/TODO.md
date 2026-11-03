# Oozecrawler — Project Tasks & Checklist

---

## 🎯 Phase 1: Launch MVP — Version 0.1 Beta (Current Focus)

A self-contained, playable release combining the physics-merge core with a 5-node mini-roguelite run and endless mode.

### 1. Board Core & Loss Conditions
- [x] Bottom kill plane (cleans up overflowed slimes and triggers Game Over)
- [ ] Fail condition: Flask Overflow (Endless) or Player HP reaching 0 (Dungeon Run)
- [ ] Tier Evolution HUD Chart (visual progression guide showing which tier merges into what)
- [ ] Study Reimplementing slime drops as a "cascading roll" system.

### 2. Turn Engine & Combat Bridge
- [ ] **Turn Cycle State Machine:**
  - `Player Turn` ➔ `Settling Phase` (physics quiescence) ➔ `Enemy Phase` ➔ `Turn Reset`
- [ ] **Action Point (AP) Economy:**
  - AP counter (e.g., 3 AP per turn; 1 drop = 1 AP)
  - "End Turn" button (locks dropper and initiates settling)
- [ ] **Stance Toggle (Attack / Defend):**
  - UI toggle button: `[Attack]` vs `[Defend]`
  - Attack stance: merges accumulate into **Damage Bank**
  - Defend stance: merges accumulate into **Shield Bank** (absorbs incoming damage, resets each turn)
- [ ] **Damage Engine:**
  - Formula: `Damage = ((Base + Flat) * ChainMult) * CritMult`
  - Base damage scaled by merged slime tier
  - Chain multiplier increments per cascade merge in the same drop
  - Critical strike roll check on drop

### 3. Enemy AI & Encounters
- [ ] **Deterministic Action Loop:**
  - `action_loop: Array[int]` sequence cycling with modulo indexing
  - Action dictionary mapping IDs to behaviors (HP Attack, Spawn Junk Slime)
- [ ] **Telegraphed Intent UI:**
  - Display icon above enemy indicating next turn's incoming action (Damage value or Hazard)
- [ ] **MVP Encounter Roster:**
  - **Normal Enemy:** 2-step loop (Step 1: Attack Player HP; Step 2: Drop 1 White Non-Mergeable Junk Slime)
  - **Mid-Boss:** Tuned HP pool and higher AP/damage output
  - **Final Boss:** Climax encounter triggering Run Victory upon defeat

### 4. 5-Node Map Route & Run Flow
- [ ] Linear node run progression: `Normal Enemy` ➔ `Event` ➔ `Shop` ➔ `Mid-Boss` ➔ `Boss`
- [ ] **Post-Combat Resolution:** Full flask clean reset + Gold reward payout
- [ ] **Shop Node:** Simple 3-item inventory (1 HP Healing Potion + 2 Passive Stat / Skill Cards)
- [ ] **Event Node:** Risk/reward 2-choice decision (Safe modest gain vs. Risky gamble with HP cost)
- [ ] Victory screen on Boss defeat; Defeat screen with run stats on death

### 5. Endless Mode, Visual Juice & Shell UI
- [ ] Title Screen with Mode Selection:
  - *Mini-Roguelite Run* (5-node dungeon crawl)
  - *Endless Mode* (Standard large beaker, high-score tracking)
- [ ] UI Polish: Add styled borders to HUD panels (Game Over title & stats)
- [ ] High-score persistence saved to `user://`
- [ ] **Procedural Corridor Background Animation:**
  - Dynamic stepping motion (step forward, turn corners, and path bifurcations on node transitions)
  - Tile details (cracks, moss, torchlight flicker)
- [ ] **Visual Juice & Effects:**
  - [x] Merge burst / party popper particles (`CPUParticles2D` / `GPUParticles2D`)
  - Squash-and-stretch body deformation on slime collisions
  - Floating combat/damage numbers rising on merges
  - Screen shake linked to critical hits or heavy impacts
- [ ] **Audio & SFX Polish (Sound Juice):**
  - Dropper release / slime drop sound
  - Slimes hitting each other (squishy bounce collision audio)
  - Slimes hitting the flask (glass wall impact audio)
  - Slime landing / settling audio


---

## ⚔️ Phase 2: Major Update 1 — Hero Classes & Skill Loadouts


- [ ] **Barbarian Class**
  - [ ] *Force Throw:* Downward launch impulse instead of passive gravity drop
  - [ ] *Quake Slam:* Vial impact impulse to settle stuck slimes
- [ ] **Wizard Class**
  - [ ] *Slime Magnetism:* Attractive magnetic force between identical adjacent tiers
  - [ ] *Transmutation:* Spells to shift slime tier up/down
- [ ] **Rogue Class**
  - [ ] *Slime Lubrication:* Compress collision hull temporarily to squeeze into gaps
  - [ ] *Swap Position:* Swap placement of two target slimes
  - [ ] *Sneak Drop:* Zero-bounce precision placement

---

## 🧪 Phase 3: Flask & Container Variations

- [ ] **Erlenmeyer (Conical) Flask:** Wide base with restrictive narrow neck
- [ ] **Test Tube:** Tall, narrow vertical column (punishing stacking)
- [ ] **Round-Bottom Flask:** Curved circular bowl rolling slimes toward center
- [ ] **Obstacle & Gimmick Flasks:**
  - [ ] Pegs and dividers that split and redirect drops (Plinko mechanics)
  - [ ] Double flasks (two adjacent flasks sharing a dropper entrance)

---

## 🗺️ Phase 4: Dungeon Crawl Roguelite Mode

- [ ] **Procedural Node Map**
  - [ ] *Slay the Spire*-style map with forks and node types
  - [ ] Combat, Elite, Mystery events, Alchemist Shop, Rest/Healing Shrines
- [ ] **Encounter & Enemy System**
  - [ ] RNG encounter selector
  - [ ] Bestiary tiers: Easy, Mid, and Bosses
  - [ ] Boss mechanics (unique/gimmick jars, disrupted physics)
  - [ ] Enemy Intent & Disruption (sludge drops, container shakes, wall constriction)
- [ ] **Turn-Based Combat & Resources**
  - [ ] Merges generate attack power and elemental triggers to damage monsters
  - [ ] Turn counter progression
  - [ ] Player resource tracking (HP, mana/energy, gold)
  - [ ] Healing shrines and resource restoration nodes
- [ ] **Cards & Relics System**
  - [ ] In-run consumable skill cards (Acid Vial, Centrifuge, Wildcards)
  - [ ] Acquisition: card shop purchases vs. combat drops
  - [ ] Passive run relics

---

## 🏆 Phase 5: Meta-Progression & Platform Support

- [ ] **Progression & Unlocks**
  - [ ] Cross-run currency to unlock starter flasks, perks, and class abilities
  - [ ] Card deck progression (pool partially locked; unlock full deck by leveling up)
- [ ] **Achievements System**
  - [ ] Milestone achievements (1st, 10th, 100th, 1000th merge, score tiers, etc.)
  - [ ] Secret achievements
  - [ ] Achievements dashboard UI (with filtering, sorting, and progress bars)
  - [ ] Online / platform leaderboards
  - [ ] Decoupled `AchievementManager` supporting local offline storage and platform integrations

---

## ✅ Completed Foundations

- [x] 11-Tier Slime progression & scaled physics parameters
- [x] Dual-buffer randomized QueueManager (`peek()` and fair distribution)
- [x] Custom procedural slime shader with eyes and radial gradients
- [x] Mouse-aimed dropper with trajectory line and preview slime
- [x] Alchemical flask container with procedural glass rendering
- [x] Procedural dungeon corridor background
- [x] Autoloaded Events bus and Score HUD
