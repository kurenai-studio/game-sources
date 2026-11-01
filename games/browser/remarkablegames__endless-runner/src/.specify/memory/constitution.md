<!--
SYNC IMPACT REPORT
==================
Version change: none → 1.0.0 (initial ratification)
Modified principles: N/A (initial creation)
Added sections:
  - Core Principles (5 principles for game development)
  - Code Quality Standards
  - Development Workflow
  - Governance
Removed sections: N/A
Templates requiring updates:
  - plan-template.md: ✅ No updates needed (Constitution Check section is generic)
  - spec-template.md: ✅ No updates needed (technology-agnostic)
  - tasks-template.md: ✅ No updates needed (structure is adaptable)
  - checklist-template.md: ✅ No updates needed (template is generic)
Follow-up TODOs: None
-->

# Endless Runner Constitution

## Core Principles

### I. Gameplay First

All development decisions prioritize player experience and game feel. Every feature
must enhance engagement, responsiveness, or fun factor.

**Non-negotiable rules:**

- Frame rate MUST remain stable at 60 FPS minimum on target platforms
- Input latency MUST be imperceptible (<100ms from input to visual feedback)
- Collision detection MUST be accurate and fair to the player
- Difficulty progression MUST feel challenging but achievable

**Rationale:** A game that doesn't feel good to play fails its primary purpose,
regardless of technical sophistication.

### II. Asset Optimization

All game assets MUST be optimized for web delivery without compromising visual
quality.

**Non-negotiable rules:**

- 3D models MUST use efficient geometry (low poly count where possible)
- Textures MUST be compressed and sized appropriately for their use case
- Audio files MUST use web-optimized formats (OGG/MP3) with reasonable bitrates
- Total initial load size SHOULD stay under 5MB for fast first paint

**Rationale:** Web games lose players to long load times. Optimization ensures
accessibility across varying network conditions and devices.

### III. TypeScript Strict Mode

All game code MUST be written in TypeScript with strict mode enabled. No
JavaScript files are permitted in `src/`.

**Non-negotiable rules:**

- No `any` types
- Implicit type inference is ok
- Enums or union types MUST be used for game states and constants

**Rationale:** Type safety catches bugs early, improves refactoring confidence,
and provides self-documenting code for future maintenance.

### IV. Babylon.js Best Practices

All Babylon.js code MUST follow selective imports and engine best practices to
minimize bundle size and maximize performance.

**Non-negotiable rules:**

- Import ONLY from specific module paths (e.g., `@babylonjs/core/Maths/math.vector`)
- NEVER use barrel imports from `@babylonjs/core`
- Meshes and materials MUST be disposed when no longer needed
- Scene cleanup MUST occur on scene transitions to prevent memory leaks

**Rationale:** Selective imports keep bundle sizes small. Proper disposal
prevents memory leaks that degrade performance over time.

### V. Iterative Development

Features MUST be developed in vertical slices: implement → playtest → refine.
No feature is complete until it feels right in actual gameplay.

**Non-negotiable rules:**

- New mechanics MUST be playtestable within the same development session
- Visual polish comes AFTER core mechanics are fun and stable
- Player feedback MUST inform iteration cycles before finalizing any feature
- Debug tools MUST be available to tweak values without code changes

**Rationale:** Game feel is discovered through play, not predetermined. Rapid
iteration ensures the game is fun, not just functional.

## Code Quality Standards

**Naming conventions:**

- Functions: camelCase (`takeDamage`, `isAlive`)
- Classes: PascalCase (`GameManager`, `Enemy`)
- Constants: UPPER_SNAKE_CASE (`PlayerConstants.MAX_HEALTH`)

**Linting requirements:**

- ESLint errors MUST be fixed before commit (`npm run lint:fix`)
- TypeScript MUST compile without errors (`npm run lint:tsc`)
- Prettier formatting MUST be applied consistently

**Import organization:**

- Babylon.js imports MUST be grouped and sorted by module path
- Local imports MUST use relative paths from `src/`
- External dependencies MUST be listed in `package.json`

## Development Workflow

**Branch strategy:**

- Feature branches MUST be prefixed with issue number (`###-feature-name`)
- Main branch MUST always be buildable and deployable
- Pull requests MUST pass lint and type check before merge

**Commit standards:**

- Commit messages MUST follow Conventional Commits format
- Each commit MUST represent a logical, testable unit of work
- WIP commits SHOULD be squashed before merging to main

**Build verification:**

- `npm run build` MUST succeed before any merge to main
- Production builds MUST be tested via `npm run preview` before release

## Governance

**Amendment process:**
Constitution amendments require:

1. Proposed change with clear rationale
2. Review against existing principles for conflicts
3. Documentation of version bump (MAJOR/MINOR/PATCH)
4. Update to this file with new amendment date

**Versioning policy:**

- MAJOR: Backward-incompatible changes (removing principles, redefining core rules)
- MINOR: New principles added or existing principles expanded
- PATCH: Clarifications, wording improvements, typo fixes

**Compliance review:**

- All PRs MUST be reviewed for constitution compliance
- Violations MUST be documented with justification if intentionally bypassed
- Quarterly review SHOULD assess whether principles remain relevant

**Version**: 1.0.0 | **Ratified**: 2026-03-16 | **Last Amended**: 2026-03-16
