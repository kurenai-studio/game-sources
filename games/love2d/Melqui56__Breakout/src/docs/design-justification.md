# Design justification

Rationale behind every architectural decision. This is the text that
**substantiates the UML** (criterion C1 of the assignment): each class, each
relationship and each pattern exists because of an explicit reason.

## 1. Why object-oriented modeling before implementation

The goal is to model the game *before* coding it. OOP lets us describe the
domain in terms of **who knows what** and **who talks to whom**, so the logic
stays maintainable and extensible as the game grows. The UML is the contract;
the Lua code follows it.

## 2. Entities and single responsibility

Each class does one job and knows only its own data:

| Class | Single responsibility |
|---|---|
| `Ball` | Movement and rendering of the projectile |
| `Paddle` | Player-controlled platform (input-driven movement) |
| `Brick` | A destructible block (state: alive/hp) |
| `Level` | The set of bricks and level completion |
| `Game` | Orchestration: state machine, score, lives, collisions |
| `UI` | Presentation of score, lives, level and messages |

**Why `Game` is the only orchestrator:** if entities decided game flow, a
change in rules would ripple through every class. Keeping flow in `Game`
means `Ball`, `Paddle` and `Level` can be tested and reused in isolation.

## 3. Relationships (UML)

- **Composition** (`Game *-- Ball/Paddle/Level`): the game creates and owns
  these entities; they do not exist without it. When the game restarts, they
  are recreated — the classic "part-of" lifetime.
- **Aggregation** (`Level o-- Brick`, `Game o-- UI`): `Level` groups bricks
  but bricks are not permanently owned by one level (they could be shared or
  moved); `UI` is a collaborator that can be swapped.
- **Association** (`Ball ..> Paddle/Brick`): `Ball` asks for collision
  checks; `Paddle ..> Game` models input intent flowing to the orchestrator.

These choices were made because they mirror the real object lifetimes:
entities live and die with the game, while the UI and bricks have looser
ownership.

## 4. Why a finite state machine (FSM)

Game flow is naturally discrete: *title → play → pause → game over*. An FSM
makes the transitions **explicit and event-driven**, so rules such as "pausing
stops time" or "game over after the last life" are visible in one place and
cannot happen accidentally. Edge cases are modeled as first-class events:

- Ball lost with lives remaining → back to `play`
- Ball lost with zero lives → `gameover`
- All bricks destroyed → next level
- `P` while playing → `pause`; `P` again → resume

## 5. Why a delta-time driven loop

The loop is **input → update → render**, and every time-dependent value is
multiplied by `dt`. This decouples movement from frame rate: the game runs at
the same speed at 60 FPS or 144 FPS, and logic never lives inside `draw()`.

## 6. Why Lua + LÖVE

- Lua is small and fast; its prototype/OOP model fits a compact game like
  Breakout without heavyweight frameworks.
- LÖVE is a batteries-included 2D engine (graphics, input, audio) that
  bundles Lua — so the delivered project runs with zero extra dependencies.
- The one-class-per-file convention keeps the UML and the code in sync.

## 7. Deliberately deferred

Collisions are implemented with simple **AABB vs circle** checks in `Game`.
Physics, particles, sound and assets are intentionally out of scope for the
skeleton so the architecture remains the focus.