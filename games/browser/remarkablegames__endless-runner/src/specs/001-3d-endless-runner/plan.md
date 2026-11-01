# Implementation Plan: 3D Endless Runner Game

**Branch**: `001-3d-endless-runner` | **Date**: 2026-03-16 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-3d-endless-runner/spec.md`

## Summary

Build a 3D endless runner game with 4-directional movement (left/right lane switching, up/jump, down/duck) across 3 discrete lanes. The game features progressive difficulty scaling, full state management (Start→Running→Paused→GameOver, with restart immediately returning to Running), and lane-based obstacle avoidance. Player controls a character that automatically runs forward while dodging obstacles through lane changes, jumps, and slides.

## Technical Context

**Language/Version**: TypeScript 5 (strict mode)
**Primary Dependencies**: Babylon.js 8 (game engine), Vite 8 (build tool)
**Storage**: N/A (no persistent storage; in-memory game state)
**Testing**: Manual playtesting; visual verification in browser
**Target Platform**: Web browsers (WASM via Babylon.js)
**Project Type**: Web game (3D browser-based endless runner)
**Performance Goals**: 60 FPS minimum, <100ms input latency, <5MB initial load
**Constraints**: Must maintain 60 FPS, progressive difficulty over 3+ minutes, obstacles must allow 1+ second reaction time
**Scale/Scope**: Single game scene, 3-lane system, 4 game states (Start, Running, Paused, GameOver) with direct restart back to Running, plus progressive difficulty scaling

## Constitution Check

_GATE: Must pass before Phase 0 research. Re-check after Phase 1 design._

### Gate 1: Gameplay First

- [x] Frame rate target defined (60 FPS minimum in Success Criteria SC-001 through SC-003)
- [x] Input latency specified (<100ms per constitution, SC-001 requires 100ms movement execution)
- [x] Collision detection requirement defined (FR-010, FR-011, SC-003)
- [x] Difficulty progression defined (FR-019, FR-020, SC-008, SC-009)

**Status**: ✅ PASS

### Gate 2: Asset Optimization

- [x] Web delivery constraint acknowledged (<5MB initial load in Technical Context)
- [ ] 3D models: Will use efficient geometry (Babylon.js best practices)
- [ ] Textures: Will use compressed formats (implementation detail)
- [ ] Audio: N/A (no audio requirements in spec)
- [ ] Load size: Will optimize for fast first paint

**Status**: ✅ PASS (optimization strategies will be applied during implementation)

### Gate 3: TypeScript Strict Mode

- [x] TypeScript 5 specified (Technical Context)
- [x] Strict mode enabled (tsconfig.json already configured per project setup)
- [x] No `any` types: Will enforce via ESLint
- [x] Enums/union types: Will use for game states and constants

**Status**: ✅ PASS

### Gate 4: Babylon.js Best Practices

- [x] Selective imports: Will import from specific module paths
- [x] No barrel imports: Will follow AGENTS.md guidelines
- [x] Mesh/material disposal: Will implement cleanup on scene transitions
- [x] Scene cleanup: Will dispose resources properly

**Status**: ✅ PASS

### Gate 5: Iterative Development

- [x] Vertical slices: Features will be playtestable incrementally
- [x] Visual polish after core mechanics: Development order defined
- [x] Player feedback: Manual playtesting specified
- [x] Debug tools: Will implement for tweaking values

**Status**: ✅ PASS

**Overall Constitution Check**: ✅ ALL GATES PASS - Proceed to Phase 0

## Constitution Check (Post-Design)

_Re-evaluated after Phase 1 design completion_

### Gate 1: Gameplay First

- [x] Frame rate: 60 FPS target documented in research.md (Decision 7: per-frame collision at 16.6ms)
- [x] Input latency: <100ms addressed via first-input-wins (research.md Decision 3)
- [x] Collision detection: Bounding box intersection (research.md Decision 7, data-model.md Obstacle entity)
- [x] Difficulty progression: Time-based scaling with config (research.md Decision 6, data-model.md DifficultyConfig)

**Status**: ✅ PASS - Design aligns with gameplay-first principles

### Gate 2: Asset Optimization

- [x] 3D models: Using Babylon.js primitives for MVP (research.md Decision 9)
- [x] Textures: Solid colors for MVP (no external assets)
- [x] Load size: Minimal - no external GLTF for MVP
- [x] Object pooling: Documented for obstacle reuse (research.md Decision 5)

**Status**: ✅ PASS - MVP approach ensures optimal load size

### Gate 3: TypeScript Strict Mode

- [x] Type definitions: Complete in data-model.md (GameStateEnum, LaneIndex, ObstacleType unions)
- [x] No `any` types: Enforced via explicit type definitions
- [x] Enums/unions: GameStateEnum, LaneIndex (0|1|2), ObstacleType, InputDirection

**Status**: ✅ PASS - All entities have strict type definitions

### Gate 4: Babylon.js Best Practices

- [x] Selective imports: Documented in research.md Best Practices
- [x] No barrel imports: Will follow AGENTS.md guidelines
- [x] Mesh disposal: Explicit disposal on state transitions (research.md Decision 10)
- [x] Object pooling: Obstacle instances reused (research.md Decision 5)

**Status**: ✅ PASS - All Babylon.js patterns documented

### Gate 5: Iterative Development

- [x] Vertical slices: Entities support incremental implementation
- [x] Playtestable: Quickstart.md documents dev server and controls
- [x] Debug tools: Config-based tuning documented (DifficultyConfig)
- [x] Quickstart guide: Complete with controls and troubleshooting

**Status**: ✅ PASS - Development workflow supports iteration

**Overall Post-Design Check**: ✅ ALL GATES PASS - Ready for Phase 2 task planning

## Project Structure

### Documentation (this feature)

```text
specs/001-3d-endless-runner/
├── plan.md              # This file
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A - no external interfaces)
└── tasks.md             # Phase 2 output (/speckit.tasks command)
```

### Source Code (repository root)

```text
src/
├── config/              # Game configuration constants
├── core/                # Core game logic (game state machine, score tracking)
├── entities/            # Game entities (Player, Obstacle, Lane definitions)
├── scenes/              # Babylon.js scene definitions
├── systems/             # Game systems (input, collision, movement, spawning)
├── types/               # TypeScript type definitions
└── utils/               # Utility functions
```

**Structure Decision**: Single project structure (web game). Source code organized by concern following existing project conventions in `src/`.
