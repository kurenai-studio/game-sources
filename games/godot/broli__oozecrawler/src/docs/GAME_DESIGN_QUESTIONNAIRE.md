# Oozecrawler — Game Design Questionnaire & Project Spec

This document tracks the core design decisions for **Oozecrawler**. As decisions are made, this file will serve as the single source of truth for the game's mechanics, architecture, and documentation.

---

## 1. Core Identity & Fantasy

* **Concept Pitch:**
  - *Question:* What is the elevator pitch for Oozecrawler?
  - *Status:* [Pending User Input]
  - *Candidate directions:*
    1. **Play as the Ooze:** You are an evolving, amorphous slime navigating hostile dungeons, absorbing biomass/matter, slipping through tight spaces, and expanding your abilities.
    2. **Dungeon Explorer:** You are an adventurer exploring an ancient facility or cavern overrun by oozing anomalies and biological horrors.
    3. **Symbiotic / Hybrid:** A dungeon crawler where you command or morph into different slime states.

* **Perspective & Dimensionality:**
  - *Question:* Is Oozecrawler 2D or 3D?
  - *Current Config:* Godot 4 project currently has `Jolt Physics (3D)` and `GL Compatibility` renderer configured in `project.godot`.
  - *Status:* [Pending User Input]
  - *Options:*
    - 2D Top-Down / Grid-based (Classic Roguelike / Zelda-like)
    - 2D Side-scroller / Metroidvania
    - 3D Top-Down / Isometric Action RPG
    - 3D First-Person Dungeon Crawler (Grid-based or free-movement)

---

## 2. Gameplay Loop & Systems

* **Genre Archetype:**
  - Roguelike / Roguelite (permadeath, procedural floors, relic/item synergies)
  - Action / Hack & Slash (fast-paced real-time combat)
  - Turn-based Tactical (positioning and elemental counters)
  - Puzzle Dungeon Crawler (physics and ooze deformation puzzles)

* **Signature Ooze Mechanics:**
  - **Growth & Mass:** Does size affect speed, health, damage, or the ability to pass through narrow barriers?
  - **Splitting & Recombining:** Can the player divide into multiple smaller units to trigger plates or distract enemies?
  - **Fluid Elements:** Acidic melting, sticky climbing, bouncy elasticity, flammable sludge?
  - **Absorption:** Absorbing fallen foes or minerals to gain temporary or permanent traits?

* **Progression & Run Loop:**
  - Run duration (short 15–20 min runs vs long multi-floor campaigns)
  - Meta-progression (permanent unlocks vs pure arcade skill)

---

## 3. Visual & Audio Direction

* **Visual Style:**
  - 2D Pixel Art / Sprite Sheets
  - 2D Vector / Hand-drawn Flat Art
  - Retro Low-Poly 3D / PSX aesthetic
  - Stylized Modern 3D
* **Tone & Theme:**
  - Dark, eerie bio-dungeon / cosmic horror
  - Quirky, colorful, arcade slime adventure
  - Sci-fi lab containment breach

---

## 4. Technical Architecture & Godot Engine Scope

* **Godot Target:** Godot 4.x (GDScript)
* **Target Platforms:** PC (Linux, Windows, macOS), Web (HTML5 export compatibility)
* **Key Godot Systems to Learn:**
  - Node composition & Scene tree best practices
  - Custom Signals & Event Bus pattern
  - State Machines for character & enemy behaviors
  - TileMaps / GridMaps / Procedural Generation
  - UI / HUD with responsive Control nodes
  - Audio management & sound effects
  - Save/Load system using Resources / JSON

---

## 5. Development Milestones

- [ ] **Milestone 0:** Project setup, Git workflow, repository documentation.
- [ ] **Milestone 1:** Core Player Controller (movement, basic collision, mass/health representation).
- [ ] **Milestone 2:** Dungeon Arena / Room Prototype (TileMap/GridMap & camera follow).
- [ ] **Milestone 3:** Core Mechanic Prototype (Ooze absorption/splitting/attack).
- [ ] **Milestone 4:** First Enemy AI & Damage System.
- [ ] **Milestone 5:** UI/HUD, Game Loop (Win/Loss/Restart state).
- [ ] **Milestone 6:** Polish, Sound FX, Shaders, and Export Build.
