# Oozecrawler — Tutoring Roadmap & Curriculum

This curriculum is designed to teach game development in **Godot 4** from initial prototype to finished game. Every module combines conceptual understanding with hands-on implementation.

---

## Pedagogical Principles

1. **Composition over Inheritance:** Leverage Godot's node composition to build modular, reusable entities.
2. **Signals Up, Call Down:** Maintain decoupled architectures using Godot signals and custom event buses.
3. **Strict Single-Variable Iteration:** Implement one feature at a time, test it, verify it in the editor/runner, and commit.
4. **Self-Documenting Code:** Clean GDScript typing (`@export`, static types `: Vector2`, `: int`), comments, and clear naming.

---

## Phase 1: Foundations & Architecture
- **Lesson 1.1:** Understanding Godot's Scene Tree, Nodes, and Lifecycle (`_ready()`, `_process()`, `_physics_process()`).
- **Lesson 1.2:** GDScript 2.0 essentials: Static typing, `@export`, enums, signals, and custom classes (`class_name`).
- **Lesson 1.3:** Setting up Project Settings, Input Map actions, and Git workflow conventions.

## Phase 2: Player Controller & Movement
- **Lesson 2.1:** CharacterBody setup (2D or 3D based on project spec).
- **Lesson 2.2:** Smooth movement, acceleration, deceleration, and collision handling.
- **Lesson 2.3:** Camera tracking (Camera2D or Camera3D with smoothing and screen limits/shake).

## Phase 3: The "Ooze" Mechanics
- **Lesson 3.1:** Modeling dynamic state (Mass, Viscosity, Health, Size).
- **Lesson 3.2:** Squash & stretch animations / juice (using Tweens and Shaders).
- **Lesson 3.3:** Signature abilities (absorption, sliding, splitting, or elemental states).

## Phase 4: Environment & Dungeon Crawling
- **Lesson 4.1:** Level construction (TileMapLayer / GridMap).
- **Lesson 4.2:** Hazards, doors, collectible nutrients/orbs, and triggers.
- **Lesson 4.3:** Introduction to procedural dungeon generation or room transitions.

## Phase 5: Enemies, Combat & AI
- **Lesson 5.1:** State Machine architecture for enemies (Idle, Chase, Attack, Hurt, Die).
- **Lesson 5.2:** Hurtbox and Hitbox pattern for clean combat interactions.
- **Lesson 5.3:** Spawning and difficulty scaling.

## Phase 6: Game Loop & Interface
- **Lesson 6.1:** HUD design (Health/Mass bar, floor tracker, minimap).
- **Lesson 6.2:** Menus, pause screen, game over, and victory screens using Control nodes.
- **Lesson 6.3:** Game state manager and scene switching.

## Phase 7: Polish & Export
- **Lesson 7.1:** Audio buses, SFX triggering, and background music loops.
- **Lesson 7.2:** Visual polish: GPUParticles, screen shake, floating combat text.
- **Lesson 7.3:** Export presets for Linux, Windows, and Web.
