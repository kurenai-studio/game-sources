---
title: Game Scope
created: 2026-07-11
updated: 2026-07-11
type: concept
tags: [game-loop, design, mechanic]
sources: []
---

# Game Scope: Mimic Sniper

## Elevator Pitch
Two-player asymmetric game. One player is a **Mimic** — a generative tentacled black blob that moves around an environment and can transform into objects it's looking at. The other player is a **Sniper** — stationary at a vantage point with a scoped rifle, trying to spot and eliminate the Mimic among disguised objects.

Think Prop Hunt meets Hitman sniper mode.

## Players

### The Mimic
- A floating sphere body with generative tentacle "legs" that animate during movement
- Black/dark aesthetic — absorbs light, eerie presence
- Can transform into nearby static objects (crates, barrels, rocks, furniture)
- While transformed: appears as the object but can still move (slowly) or remain perfectly still
- Transformation has a visual transition animation (blob morphs into target shape)
- Goal: survive for X rounds or reach an objective point

### The Sniper
- Stationary at a fixed vantage point (rooftop, hilltop, tower)
- Equipped with a scoped rifle — zoom in/out mechanic
- Must identify which objects are the Mimic in disguise and shoot
- Limited ammo or cooldown between shots (prevents spray-and-pray)
- Goal: eliminate the Mimic before time/objective expires

## Core Loop
1. Round starts — Mimic spawns, Sniper takes position
2. Mimic moves through environment, transforms into objects along the way
3. Sniper scans through scope, looking for tells (subtle movement, wrong proportions, unnatural behavior)
4. Sniper fires — if correct, Mimic is eliminated; if wrong, Mimic gets a hint/advantage
5. Round ends on elimination or timeout
6. Score tracking across rounds

## Key Mechanics to Research & Implement

### Mimic Mechanics
- [[mimic-movement]] — Floating sphere + generative tentacle locomotion
- [[mimic-transformation]] — Real-time mesh morphing into target objects
- [[mimic-stealth-tells]] — Subtle visual cues that give the Mimic away (for Sniper to exploit)

### Sniper Mechanics
- [[sniper-camera]] — Scope zoom, breathing sway, bullet drop, wind
- [[sniper-ballistics]] — Projectile physics, hit detection, reload
- [[sniper-ui]] — Crosshair, ammo counter, scope overlay, hit feedback

### Environment
- [[level-design]] — Low-poly environments with transformable objects and sniper vantage points
- [[object-library]] — Catalog of transformable objects (crates, barrels, rocks, etc.)

### Systems
- [[game-state-machine]] — Round flow: spawn → play → resolve → score
- [[multiplayer-architecture]] — Local co-op vs networked (WebRTC/WebSocket)
- [[performance-pi5]] — Pi 5 optimization targets (60fps on Chromium kiosk, 7GB RAM budget)

## Art Direction
- Low-poly aesthetic throughout
- Mimic: dark/void-like, absorbs light, tentacles are procedural
- Environment: muted desaturated palette with atmospheric haze
- Sniper scope: clean UI overlay, seafoam green (#7FB3A8) accent for ALLMIND branding
- Reference: [[art-direction]] (TBD — will refine based on brand kit)

## Win Conditions
**Mimic wins by:**
- Surviving the full round timer
- Reaching an objective point while disguised
- Sniper runs out of ammo

**Sniper wins by:**
- Eliminating the Mimic before timeout
- Correctly identifying and shooting the Mimic X times in a round

## Out of Scope (V1)
- Multiplayer over internet (local only for V1)
- Multiple maps (one environment to start)
- Story/narrative elements
- Sound design beyond basic SFX
- Mobile support

## Technical Constraints
- Raspberry Pi 5 (7GB RAM, ARM64, multi-threaded)
- Chromium kiosk mode — CSS-only UI preferred over script-heavy overlays
- Three.js r160+ via CDN or local bundle
- Target: 60fps at 1920x1080
