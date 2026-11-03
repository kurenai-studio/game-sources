# Kerno Crawler — Game Design Document (GDD)
*Yet Another Dungeon Crawler Story*

## 1. High Concept & Elevator Pitch
**Kerno Crawler** is a 2D fantasy physics-merge roguelite—a **"Suika Game meets Dungeon Crawler"**. Dungeons are alien, extra-planar structures invading the world. Defeated dungeon beasts dissolve, leaving behind indestructible foreign anchors called **Kernoj** (cores). 

Adventurers carry customized planar containers (Barbarian iron cages, Wizard alchemical cylinders, Rogue collector rigs) into the dungeon. Under the laws of foreign physics, identical Kernoj share extreme surface tension: when brought into contact, they violently snap together (**Planar Cohesion / Fusion**) into larger, denser, and more radiant cores. In **Infinite Mode**, players practice high-score fusion runs. In **Dungeon Crawl Mode**, the energy released from these surface tension fusions is channeled into combat stances (Attack / Defend) to defeat dungeon monsters across 5-node procedural runs.

---

## 2. Core Pillars
1. **Resonant Physical Cohesion:** Indestructible, crystalline Kernoj that roll, clink, and snap together into larger radiant spheres via extreme foreign surface tension.
2. **Dual-Mode Synergy:** 
   - *Infinite Mode:* High-score driven training and sandbox fusion.
   - *Roguelite Crawl:* Tactical turn-based combat powered by fusion energy banks.
   - Cross-mode rewards keep both modes relevant.
3. **Class Identity & Planar Rigs:** Distinct playstyles (kinetic force throws, arcane harmonic magnets, precision compression drops) with unique class containers.
4. **Wry Anime/Fantasy Tone:** An eccentric mentor (the "Professor") providing comedic, pragmatic commentary on the absurdity of the extra-planar dungeon invasion.

---

## 3. Game Modes

### A. Infinite Normal Mode
- **Rules:** Continuous slime dropping into a chosen flask geometry.
- **Fail Condition:** Slimes stay above the top overflow limit line for more than 2–3 seconds.
- **HUD:** Current Score, High Score, Next Slime, Next+1 Slime, Slime Evolution Chart.
- **Meta Role:** Practice mechanics, complete general achievements, farm base perks for Roguelite mode.

### B. Dungeon Crawl Roguelite Mode
- **Rules:** Stage-by-stage dungeon run against enemies (e.g., Goblins, Skeletons, Alchemists, Dungeon Mimics).
- **Turn Loop:**
  - **Player Phase:** Player spends Action Points (AP) to drop slimes.
  - **Stance Toggle:** Players toggle between `[Attack Stance]` (merges bank damage) and `[Defense Stance]` (merges bank shield).
  - **Damage Engine:** `Damage = ((Base + Flat) * ChainMult) * CritMult`.
  - **Settling Phase:** Input locks briefly while physics bodies come to rest.
  - **Enemy Phase:** Enemy executes its telegraphed action from its deterministic `action_loop` (HP attack or board hazard).
  - **Turn Reset:** AP and temporary shield refresh.
- **Run Progression:** 
  - Standard 5-node route for MVP: `Normal Enemy` ➔ `Event` ➔ `Shop` ➔ `Mid-Boss` ➔ `Boss`.
  - Full board reset and gold payout between encounters.


---

## 4. Class Archetypes & Abilities

| Class | Throw / Core Trait | Special Ability / Spell | Playstyle Theme |
| :--- | :--- | :--- | :--- |
| **Barbarian** | Extra throw force / heavy slam | *Quake Slam:* Shakes container to settle merges | High momentum, brute-force compaction |
| **Wizard** | Controlled gentle drop | *Slime Magnetism:* Attracts matching tier slimes | High synergy, tactical combo setups |
| **Rogue** | Slime lubrication | *Squeeze:* Drops compress or slip between small gaps | Precision drops, recovery from high stacks |

---

## 5. Slime Evolution Hierarchy (Tiers 1 to 10)

Slimes vary in color, radius, mass, elasticity, and translucency:
1. **Tier 1 — Droplet** (Tiny, lime green, bouncy)
2. **Tier 2 — Bloblet** (Small, cyan, lively)
3. **Tier 3 — Glob** (Medium-small, bright yellow)
4. **Tier 4 — Sludge** (Medium, orange, sticky bounce)
5. **Tier 5 — Ooze** (Medium-large, magenta)
6. **Tier 6 — Gel** (Large, royal purple, jelly-like)
7. **Tier 7 — Muck** (Bulky, crimson red)
8. **Tier 8 — Slime Knight** (Very large, sapphire blue, core visible)
9. **Tier 9 — Primordial Mass** (Huge, deep amethyst)
10. **Tier 10 — Royal King Ooze** (Screen-filling golden crowned behemoth)

---

## 6. Achievement & Platform Architecture

To support **Steam Achievements** and **Mobile Services** seamlessly:
- Dedicated **`AchievementManager`** autoload with decoupled abstract interfaces:
  - Local JSON storage for offline play / Godot standalone.
  - Pluggable backend for Steamworks (`GodotSteam`) and Google Play / Apple Game Center.
- Tracks:
  - Slime Merge Milestones (e.g., "Merge 100 Tier 1s", "Create your first King Ooze")
  - Score Thresholds ("Scored 3,000 in Infinite Mode")
  - Class Masteries ("Clear Floor 5 as Rogue without overflowing")
