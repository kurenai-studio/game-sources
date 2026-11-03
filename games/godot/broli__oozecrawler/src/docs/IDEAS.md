# Kerno Crawler — Mechanics, Skills & Feature Ideas Backlog
*Yet Another Dungeon Crawler Story*

This document collects gameplay ideas, lore foundations, class traits, utility skills, and procedural dungeon concepts.

---

## 0. Lore & World Foundation
* **Kernoj (Singular: Kerno):** Indestructible planar anchors left behind when otherworldly dungeon beasts fall in combat. Their extreme surface tension prevents ordinary physical destruction and forces like-density cores to snap together upon contact.
* **Planar Cohesion (Fusion):** When two identical Kernoj collide, their surface tension collapses them into a single larger, denser, higher-tier core, releasing a pulse of harvestable combat energy.
* **Planar Containers:** Hero-specific rigs used to hold and compress Kernoj (Barbarian slag cage, Wizard arcane cylinder, Rogue collector canister).
* **The Mentor:** An eccentric, irreverent researcher ("The Professor") studying the extra-planar invasion with pragmatic humor.

---

## 1. Class-Specific Mechanics & Passives

* **Barbarian (Kinetic / Heavy Impact):**
  - **Force Throw:** Instead of passively dropping slimes under gravity, throws them downward with downward linear velocity/impulse.
  - **Crush:** Heavy drops cause stronger shockwaves, unsettling jammed slimes.

* **Rogue (Infiltration / Viscosity):**
  - **Slime Lubrication / Phase:** Temporarily or passively reduces collision hull radius on dropping slimes, allowing them to squeeze between narrow gaps and slip toward the bottom of the container.
  - **Sneak Drop:** Reduced bounce or silent placement.

* **Wizard (Arcane Control / Magnetism):**
  - **Slime Magnetism:** Applies an attractive force between slimes of the identical tier within a certain radius, reducing physics randomness and guiding combos.
  - **Transmutation:** Arcane alterations to slime properties.

---

## 2. Utility Skills & Manipulation Abilities

* **Merge Radius Amplification:**
  - Skill/perk that inflates merge detection radius by $X\%$ without inflating the physical collision body, allowing slimes to merge before touching.
* **Slime Swap:**
  - Targeted active: Player clicks two slimes to swap their positions inside the vial.
* **Targeted Dissolve (Destroy):**
  - Targeted active: Click and destroy a single problematic slime that is blocking a critical merge.
* **Tier Transmutation (+ / -):**
  - Targeted active: Target a slime to increment (+1) or decrement (-1) its tier.
* **Vial Shake / Quake:**
  - Active ability: Jostles the entire container with a burst of impulse, helping settled slimes find adjacent matches.

---

## 3. Consumable Cards / Item System

* **Mario Party / Board Game Style Items:**
  - Instead of (or in addition to) static cooldown skills, items drop randomly or appear as playable consumable cards.
  - Examples:
    - *Acid Vial:* Melts bottom-most obstacle.
    - *Centrifuge Card:* Temporarily spins/re-sorts container.
    - *Wildcard Slime:* Merges with any slime tier.

---

## 4. Roguelite Crawl Mode (Post-Infinite Core Implementation)

* **Node-Based Path Selection:**
  - Procedural map routing (inspired by *Slay the Spire* / *FTL*).
  - Branching paths with distinct node types:
    - **Combat Encounter:** Fight monsters by triggering merges to attack.
    - **Elite / Miniboss:** High health, container hazard attacks (e.g., throwing toxic sludge into your vial).
    - **Mystery Events:** Alchemical experiments, gamble slimes for relics, risk-reward dialogue.
    - **Alchemist Shop:** Purchase consumable cards, passive relics, and flask upgrades using run currency.
    - **Rest Site:** Brew potions, upgrade class skills.

---

## 5. Flask / Vial Geometry Variations (Class Perks & Crawl Modifiers)

* **Alternative Container Shapes:**
  - **Erlenmeyer (Conical) Flask:** Narrow neck opening, broad stable base (easier early merges, tight top).
  - **Test Tube:** Tall, narrow vertical column (punishing stacking, requires high precision).
  - **Round-Bottom Flask:** Curved circular bowl causing slimes to roll toward center point.
  - **Funnel / Hourglass:** Two chambers connected by a restrictive choke point.
  - **Internal Obstacles / Pachinko Pegs:** Fixed central pins that split and redirect falling slimes.
* **Unlock & Usage:**
  - Class-specific starter containers (e.g., Alchemist uses conical, Barbarian uses wide cauldron).
  - Dungeon room modifiers / curses in Crawl mode.

---

## 6. Damage Formula & Card Modifier Synergies

Formula: `Damage = ((Base + Flat) * ChainMult) * CritMult`

* **Flat Value Modifiers:**
  - *"Slimes count as one tier higher"* (increases base tier value).
  - *"Each merge gains a flat +X damage bonus"*.
* **Chain Multiplier Modifiers:**
  - *"Each chain begins at +1x base multiplier"*.
  - *"Next chain persists across an extra drop before resetting"*.
* **Critical Hit Modifiers:**
  - Drop-based crit roll checks.
  - Fighter/Barbarian trait: *"Double critical hit chance"*.
* **Class Attack Cards:**
  - Ranger: *"Shoot an arrow that destroys 1 selected slime; that slime's tier value is added directly into the next chain"*.

---

## 7. Enemy Disruption Mechanics Backlog

* **Junk / Toxic Slimes:**
  - Spawns un-mergeable slimes (e.g., solid white or transparent alpha) to waste flask volume.
* **Internal Peg Placement:**
  - Enemy inserts unmovable pins/pegs inside the container to divide flow and disrupt combos.
* **Slime Targeting & Debuffs:**
  - Target the highest-tier slime on the board and decrement its tier or dissolve it.
  - *Freeze:* Freezes a slime in place, preventing merging until thawed via a player skill or adjacent heat effect.

---

## 8. Run Modifiers & Meta Progression Backlog

* **Persistent Board Malus (Curse Modifier):**
  - Advanced difficulty modifier where the flask is NOT reset between fights on the same map, forcing the player to manage long-term clutter.
* **Endless Mode Loadout Selection:**
  - As classes, cards, and traits are unlocked through Crawl mode, players can customize a starting loadout for Endless / High Score attempts.

