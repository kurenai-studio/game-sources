# Data Model: 3D Endless Runner Game

**Feature**: 001-3d-endless-runner
**Date**: 2026-03-16
**Purpose**: Define entities, fields, relationships, and validation rules from feature specification

---

## Core Entities

### GameState

Represents the current state of the game session.

**Fields**:

- `state`: GameStateEnum - Current game state (Start, Running, Paused, GameOver)
- `score`: number - Distance traveled in current run
- `startTime`: number - Timestamp when current run began
- `pauseTime`: number | null - Timestamp when game was paused (null if not paused)
- `isRunning`: boolean - Derived: true if state === Running

**Validation Rules**:

- `score` MUST be >= 0
- `pauseTime` MUST be null when state is Running
- `startTime` MUST be set when state transitions to Running

**State Transitions**:

```
Start → Running (on start game)
Running → Paused (on pause input)
Paused → Running (on resume input)
Running → GameOver (on collision)
GameOver → Running (on restart)
```

---

### Player

Represents the player character entity.

**Fields**:

- `currentLane`: LaneIndex (0, 1, 2) - Current lane position (0=left, 1=center, 2=right)
- `targetLane`: LaneIndex (0, 1, 2) - Target lane for smooth transitions
- `isJumping`: boolean - True when player is in jump state
- `isDucking`: boolean - True when player is in duck/slide state
- `jumpProgress`: number (0-1) - Normalized jump animation progress
- `duckProgress`: number (0-1) - Normalized duck animation progress
- `verticalPosition`: number - Y-axis offset from ground (0 = ground level)
- `targetVerticalPosition`: number - Target Y-axis position for interpolation

**Validation Rules**:

- `currentLane` MUST be 0, 1, or 2
- `isJumping` and `isDucking` CANNOT both be true simultaneously
- `jumpProgress` MUST be 0 when `isJumping` is false
- `duckProgress` MUST be 0 when `isDucking` is false
- `verticalPosition` MUST be >= 0 (cannot go below ground)

**State Transitions**:

- Lane change: `currentLane` → `targetLane` with lerp interpolation
- Jump: `isJumping=true` → animate up → animate down → `isJumping=false`
- Duck: `isDucking=true` → animate down → animate up → `isDucking=false`

---

### Lane

Represents a discrete horizontal position in the game world.

**Fields**:

- `index`: LaneIndex (0, 1, 2) - Lane identifier
- `xPosition`: number - World X coordinate for this lane
- `isLeftmost`: boolean - True if index === 0
- `isRightmost`: boolean - True if index === 2
- `isCenter`: boolean - True if index === 1

**Validation Rules**:

- Exactly 3 lanes MUST exist per game session
- Lane indices MUST be consecutive (0, 1, 2)
- `xPosition` values MUST be evenly spaced (e.g., -2, 0, 2)

**Relationships**:

- Left neighbor: Lane at `index - 1` (undefined if isLeftmost)
- Right neighbor: Lane at `index + 1` (undefined if isRightmost)

---

### Obstacle

Represents an environmental hazard in the player's path.

**Fields**:

- `id`: string - Unique identifier
- `lane`: LaneIndex (0, 1, 2) - Lane where obstacle is positioned
- `type`: ObstacleType - Type of obstacle (Ground, Airborne)
- `zPosition`: number - Forward distance from player (negative = ahead)
- `isActive`: boolean - True if obstacle is in play area
- `requiresJump`: boolean - True if obstacle requires jump to avoid
- `requiresDuck`: boolean - True if obstacle requires duck to avoid
- `requiresLaneChange`: boolean - True if obstacle requires lane switch to avoid

**Validation Rules**:

- `lane` MUST be 0, 1, or 2
- `zPosition` MUST be negative (ahead of player) while active
- At least one of `requiresJump`, `requiresDuck`, `requiresLaneChange` MUST be true
- Obstacle MUST be avoidable via at least one valid player action

**Obstacle Types**:

- **Ground**: Requires jump or lane change (e.g., barrier on ground)
- **Airborne**: Requires duck or lane change (e.g., low-hanging obstacle)
- **FullLane**: Requires lane change only (e.g., wall blocking entire lane)

---

### ObstaclePattern

Represents a predefined arrangement of obstacles for spawning.

**Fields**:

- `id`: string - Unique pattern identifier
- `obstacles`: ObstacleSpawn[] - Array of obstacles to spawn
- `minRunDuration`: number - Minimum run time before pattern can appear
- `difficulty`: number (0-1) - Pattern difficulty rating

**ObstacleSpawn**:

- `laneOffset`: number - Relative lane offset from player (0 = same lane)
- `zOffset`: number - Relative Z distance from spawn point
- `type`: ObstacleType

**Validation Rules**:

- Pattern MUST be avoidable (not all 3 lanes blocked at same Z)
- `minRunDuration` MUST be >= 0
- `difficulty` MUST be between 0 and 1

---

### DifficultyConfig

Represents the progressive difficulty scaling parameters.

**Fields**:

- `baseSpeed`: number - Starting forward speed (world units per second)
- `maxSpeed`: number - Maximum forward speed cap
- `speedIncreaseInterval`: number - Seconds between speed increases (30 per SC-008)
- `speedIncreaseAmount`: number - Speed added per interval
- `baseDensity`: number - Starting obstacle spawn rate (obstacles per second)
- `maxDensity`: number - Maximum obstacle spawn rate
- `densityRampDuration`: number - Seconds to reach max density (180 per SC-009)

**Validation Rules**:

- `baseSpeed` MUST be > 0
- `maxSpeed` MUST be >= `baseSpeed`
- `speedIncreaseInterval` MUST be > 0
- `baseDensity` MUST be > 0
- `maxDensity` MUST be >= `baseDensity`
- `densityRampDuration` MUST be > 0

**Derived Values**:

- `currentSpeed`: Interpolated from `baseSpeed` to `maxSpeed` based on run duration
- `currentDensity`: Interpolated from `baseDensity` to `maxDensity` based on run duration

---

## Type Definitions

```typescript
// Enum for game states
enum GameStateEnum {
  Start = 'START',
  Running = 'RUNNING',
  Paused = 'PAUSED',
  GameOver = 'GAME_OVER',
}

// Lane index type
type LaneIndex = 0 | 1 | 2;

// Obstacle type union
type ObstacleType = 'GROUND' | 'AIRBORNE' | 'FULL_LANE';

// Input direction union
type InputDirection = 'LEFT' | 'RIGHT' | 'UP' | 'DOWN';

// Player action union
type PlayerAction = 'LANE_CHANGE' | 'JUMP' | 'DUCK' | 'NONE';
```

---

## Relationships

```
GameState ──contains──> Player
GameState ──tracks──> score (number)
GameState ──manages──> Obstacle[] (active obstacles)
Player ──occupies──> Lane (currentLane)
Obstacle ──positionedIn──> Lane
ObstaclePattern ──contains──> ObstacleSpawn[]
DifficultyConfig ──controls──> speed, density over time
```

---

## Validation Rules Summary

### From Functional Requirements

- **FR-002**: Exactly 3 lanes (enforced by LaneIndex type)
- **FR-007/FR-008**: Lane boundary checks (currentLane cannot go below 0 or above 2)
- **FR-010**: Collision detection (Player intersects Obstacle bounding box)
- **FR-011**: Game over on collision (GameState transitions to GameOver)
- **FR-014**: First-input-wins (input lockout during active action)
- **FR-018**: Pause freezes all state updates (score, obstacles, player movement)
- **FR-019/FR-020**: Progressive scaling (DifficultyConfig interpolation)

### From Success Criteria

- **SC-001**: Input response <100ms (player action initiation)
- **SC-003**: Collision detection <50ms (per-frame check at 60 FPS = 16.6ms)
- **SC-004**: 1+ second reaction time (obstacle spawn zPosition ensures visibility)
- **SC-006**: 100% boundary enforcement (LaneIndex type + validation)
- **SC-008**: Speed increase every 30 seconds (DifficultyConfig.speedIncreaseInterval)
- **SC-009**: Max density by 3 minutes (DifficultyConfig.densityRampDuration = 180)

---

## State Machine Diagram

```
┌─────────────┐
│   Start     │
└──────┬──────┘
       │ Start Game
       ▼
┌─────────────┐      ┌─────────────┐
│   Running   │◄────►│   Paused    │
└──────┬──────┘      └─────────────┘
       │
       │ Collision
       ▼
┌─────────────┐
│  Game Over  │
└──────┬──────┘
       │ Restart
       ▼
┌─────────────┐
│   Running   │
└─────────────┘
```
