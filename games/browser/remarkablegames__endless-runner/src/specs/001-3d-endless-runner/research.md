# Research: 3D Endless Runner Game

**Feature**: 001-3d-endless-runner
**Date**: 2026-03-16
**Purpose**: Resolve technical unknowns and document best practices for implementation

---

## Technical Decisions

### Decision 1: Game State Machine Architecture

**What was chosen**: Enum-based state machine with explicit transitions

**Rationale**:

- TypeScript enums provide type safety for game states (Start, Running, Paused, GameOver)
- Explicit state transitions prevent invalid state combinations
- Easy to add state entry/exit hooks for UI updates, audio, and gameplay logic
- Aligns with Constitution Principle III (TypeScript Strict Mode)

**Alternatives considered**:

- String literal union types: Less explicit, harder to iterate over states
- State pattern (OOP): Over-engineered for 5 simple states
- XState library: Adds dependency for simple state machine

---

### Decision 2: Lane System Implementation

**What was chosen**: Fixed lane positions with lerped transitions

**Rationale**:

- 3 discrete lanes at fixed X positions (e.g., -2, 0, 2 world units)
- Lane switches use linear interpolation (lerp) for smooth visual transitions
- Player always occupies exactly one lane at a time
- Simplifies collision detection (lane-based spatial partitioning)

**Alternatives considered**:

- Free horizontal movement: Harder to balance, less predictable gameplay
- Grid-based snapping: Jerky visual appearance without interpolation
- Procedural lane positions: Unnecessary complexity for fixed 3-lane design

---

### Decision 3: Input Handling (First-Input-Wins)

**What was chosen**: Input queue with first-input priority and lockout

**Rationale**:

- First directional input locks out subsequent inputs until released
- Prevents accidental diagonal inputs from conflicting key presses
- Simple to implement with Babylon.js action managers
- Provides predictable, deterministic player control

**Alternatives considered**:

- Input buffering: Adds complexity, not needed for arcade-style gameplay
- Last-input-wins: Feels unresponsive, ignores player intent
- Simultaneous input combination: Conflicts with lane-based design

---

### Decision 4: Jump and Duck Mechanics

**What was chosen**: Animation-based vertical actions with collision boxes

**Rationale**:

- Jump: Player mesh moves up on Y-axis, returns via gravity or fixed duration
- Duck: Player mesh scales down or plays slide animation, reduced collision height
- Separate collision boxes for standing, jumping, and ducking states
- Clear visual feedback for obstacle avoidance windows

**Alternatives considered**:

- Physics-based jumping: Overkill for arcade gameplay, harder to tune
- Binary up/down states: Less polished feel
- No vertical movement: Would eliminate 2 of 4 directional inputs

---

### Decision 5: Obstacle Spawning System

**What was chosen**: Pattern-based obstacle pools with distance-based spawning

**Rationale**:

- Obstacles spawn ahead of player at fixed distance (allows 1+ second reaction per SC-004)
- Predefined patterns ensure fair, playable obstacle combinations
- Object pooling for performance (reuse obstacle meshes instead of create/destroy)
- Patterns selected based on run duration for progressive difficulty

**Alternatives considered**:

- Pure random spawning: Can create impossible situations
- Hand-crafted sequences: Limited replayability
- Procedural generation: Over-engineered for MVP scope

---

### Decision 6: Progressive Difficulty Scaling

**What was chosen**: Time-based scaling with linear interpolation

**Rationale**:

- Speed increases every 30 seconds (SC-008): Linear or exponential curve from base to max
- Obstacle density increases over 3 minutes to maximum (SC-009)
- Difficulty parameters stored in config for easy tuning
- Separate multipliers for speed and density allow fine-grained balancing

**Alternatives considered**:

- Distance-based scaling: Rewards slow play, less predictable
- Wave-based difficulty: Sudden spikes feel unfair
- Player performance adaptive: Harder to test and balance

---

### Decision 7: Collision Detection

**What was chosen**: Bounding box intersection testing

**Rationale**:

- Babylon.js provides built-in `intersectsMesh()` for bounding box checks
- Axis-aligned bounding boxes (AABB) sufficient for lane-based obstacles
- Per-frame collision check in game loop (60 FPS = 16.6ms frame budget, SC-003 requires <50ms)
- Separate trigger zones for "near miss" feedback if desired later

**Alternatives considered**:

- Sphere collision: Less accurate for boxy obstacles
- Mesh-precise collision: Overkill, performance cost
- Physics engine (Cannon.js, Ammo.js): Unnecessary dependency for simple boxes

---

### Decision 8: Score/Distance Display

**What was chosen**: Distance-based score with HTML overlay

**Rationale**:

- Score = distance traveled (simple, intuitive metric)
- Babylon.js GUI or HTML overlay for UI (HTML easier to style, responsive)
- Update every frame or fixed interval (<100ms delay per SC-007)
- Final score displayed on game over screen

**Alternatives considered**:

- Time-based score: Rewards survival over skill
- Coin collection: Adds complexity not in spec
- Babylon.js GUI: More integrated but harder to style quickly

---

### Decision 9: Asset Management

**What was chosen**: Minimal placeholder geometry with Babylon.js primitives

**Rationale**:

- MVP uses built-in Babylon.js primitives (BoxBuilder, CylinderBuilder)
- No external asset loading for initial implementation
- Materials use simple colors for visual distinction
- Easy to replace with optimized 3D models later

**Alternatives considered**:

- GLTF models from start: Adds asset pipeline complexity
- Procedural meshes: Unnecessary for simple shapes
- Asset loading system: Over-engineered for MVP

---

### Decision 10: Scene and Resource Cleanup

**What was chosen**: Explicit disposal on state transitions

**Rationale**:

- Obstacles disposed when out of view or on game over
- Scene `onBeforeRender` observable for game loop
- Explicit `dispose()` calls on mesh, materials when no longer needed
- Aligns with Constitution Principle IV (Babylon.js Best Practices)

**Alternatives considered**:

- Garbage collection reliance: Memory leaks in Babylon.js
- Object pooling only: More complex, optimize after profiling
- Scene reset on restart: Simpler but loses potential for future features

---

## Best Practices Summary

### Babylon.js Specific

1. **Selective imports**: Always import from `@babylonjs/core/Engines/engine`, `@babylonjs/core/Maths/math.vector`, etc.
2. **Engine disposal**: Call `engine.dispose()` on page unload
3. **Render loop**: Use `engine.runRenderLoop()` with scene registration
4. **Observables**: Use Babylon.js observables for event-driven architecture
5. **Instancing**: Use `createInstance()` for repeated obstacles (performance)

### TypeScript Specific

1. **Strict mode**: `strict: true` in tsconfig.json (already configured)
2. **No `any`**: Use proper types for all variables and function signatures
3. **Const enums**: Use for game state enums (compile to constants)
4. **Type guards**: Use for runtime type narrowing where needed

### Performance Optimization

1. **Object pooling**: Reuse obstacle instances instead of create/destroy
2. **Frustum culling**: Babylon.js handles automatically
3. **LOD (Level of Detail)**: Not needed for MVP (simple geometry)
4. **Texture atlasing**: Not needed for MVP (solid colors)
5. **Draw calls**: Minimize by sharing materials

---

## Unresolved Questions

**None** - All technical unknowns resolved through research and alignment with project constitution.
