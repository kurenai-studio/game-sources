# GOAL RUSH — Architecture

This document explains *why* the machine is built the way it is. The *what* is in the
code; every module header comment maps to a section here.

## Module map

```mermaid
flowchart LR
  subgraph React shell (Next.js)
    Page[page.tsx] --> GameCanvas
    Page --> Panels[HowToPlay / Paytable / Leaderboard]
    Leaderboard --> API[/api/leaderboard/]
    API --> DB[(Prisma + SQLite)]
  end
  subgraph Game engine (Phaser 3, framework-agnostic)
    GameCanvas -->|dynamic import| createGame
    createGame --> Boot[BootScene<br/>runtime atlas + field art]
    Boot --> Play[PlayScene]
    Play --> Physics[physics/: Ball, Flipper, Plunger,<br/>Bumper, Slingshot, DropTargetBank,<br/>Spinner, Saucer]
    Play --> Slots[slots/: rng + SlotMachine]
    Play --> UI[ui/: Hud + JackpotFx]
    Play --> State[state/: GameState bus]
    Play --> Audio[audio/: AudioKit]
    State -->|CustomEvent bridge| Leaderboard
  end
```

The `src/game/**` tree never imports React — it can be lifted into any Vite/Webpack
project unchanged. The React shell mounts it via `createGame(parent)` and talks to it
through two window `CustomEvent`s (`goalrush:gameover`, `goalrush:restart`), keeping
both worlds decoupled and independently testable.

## Physics design decisions

### 1. Fixed-timestep accumulator (refresh-rate independence)

Phaser's Matter integration calls `Engine.update` **once per rendered frame** with a
fixed 60 Hz delta — and its TimeStep *clamps* slow-frame deltas below ~30 fps. Two
consequences we refuse to accept: the ball would move twice as fast on a 120 Hz
display, and would enter slow motion on weak devices.

`PlayScene` therefore sets `matter.world.autoUpdate = false` and drives the engine
itself:

```ts
accumulator += min(realDelta, 750ms)           // performance.now() clock
while (accumulator >= 16.667ms && steps < 45) {
  controllers()          // flippers, spinner scoring, speed clamp
  matter.world.step(16.667ms)
  accumulator -= 16.667ms
}
```

Real-clock timing (`performance.now()`, not Phaser's smoothed delta) makes the physics
true to wall-clock time; sub-step clamping prevents the spiral of death after tab
switches. Net effect: identical ball behaviour at any frame rate, deterministic
feel for flipper timing.

### 2. Flippers: static-kinematic drive (arcade-exact)

Each bat is a **STATIC** body placed by hand every physics sub-step around its
world pivot — the engine never integrates it and the solver never pushes it.
Two things are painted per step:

```
angle += clamp(target − angle, −rate, +rate)      // 0.24 rad/step up ≈ 84 ms swing
Body.setPosition(bat, pivot + R·dir(angle), true)  // derives TRUE velocity from the delta
Body.setAngle(bat, angle, true)
if moving: setVelocity + setAngularVelocity       // tuned swing speed for the resolver
```

Why STATIC: Matter's collision resolver reads a body's velocity from its
**position history** (`position − positionPrev`), not from the velocity field.
A dynamic body that is re-placed every step is *additionally* integrated by
the engine — it ends up off-placement, and the next solver pass sees a
polluted, wobbling velocity (measured ±0.52 rad on a reproduction bench: the
erratic "flip sometimes fails" kicks). A static body is never integrated, so
the placement history is exact; the explicit `setVelocity/setAngularVelocity`
paint gives the resolver precisely the intended bat speed at every contact
point.

Why 0.24 rad/step placement: the per-step face sweep at the tip is ~15 px —
below the ball Ø (26 px) — so the moving face can never tunnel past the ball
(the earlier 0.72 rad/step design swept 45 px/step and regularly jumped over
contact entirely). The resolver-visible speed is tuned separately
(`FLIPPER.solverUp`) on a standalone Matter harness
(`scripts/flipper-kick-tuning.js`): clean face hits launch the ball at
12 px/step (pivot side, control) to 26 px/step (tip, full power).

This design was **empirically selected** after profiling on a reproduction
bench (`scripts/probe-*.ts`, raw matter-js):

| Approach | Result |
|---|---|
| Pin constraint + `setAngularVelocity` | Solver noise parks a freely rolling ball on a nearby incline (reproduced, bisected) |
| Pin constraint + PD torque | A dense pinned bat needs huge gains → spins out uncontrollably |
| Dynamic body re-placed per step | Engine double-integrates the placement; the resolver sees a polluted velocity → erratic kicks |
| **Static kinematic place-per-step** | 84 ms flips, rock-steady rest, exact solver velocity — every hit connects |

### 3. Launch lane — deliberately gate-less

Classic tables seal the lane mouth with a one-way wire gate. We tested a
hinged flap (pin constraint + travel clamps, later a physical rest post) and
removed it: in a 30 px mouth every rest-stop placement either wedged the ball
or obstructed the launch. Since a ball that re-enters the lane simply rests
on the plunger (re-launch, no drain, no soft-lock — and it is a rare bounce
anyway), the clean design is **no gate at all**. The dome's curvature already
carries launched balls left into the playfield.

### 4. Kicking elements

| Element | Behaviour |
|---|---|
| Pop bumper | static circle + velocity kick along the contact normal (12.5 px/tick), 90 ms cooldown, flash + particles + camera micro-shake |
| Slingshot | static triangle; kick along the fixed face normal, 110 ms cooldown |
| Spinner | free-spinning blade on a center pin; accumulated rotation scores per revolution — pure momentum transfer, no motor |
| Saucer | circular sensor; captures the ball (static + hidden), runs the slot sequence, ejects with a fixed impulse + recapture lockout |
| Drop targets | standing plates; a hit zeroes the body's collision mask (cheaper and safer than removing bodies), bank reset re-arms them |

### 5. Anti-tunneling

A 12–16 px wall can be skipped by a fast ball in discrete physics. Three layers of
protection: walls are thick and chamfered; the ball's speed is clamped each sub-step
(26 px/tick < ball Ø 26 + wall 12 tunnel threshold); and solver iteration counts are
raised (12 position / 8 velocity).

### 6. Tuning scale

The table is 540×960 px ≈ 1.15 m of a real machine. Gravity is scaled to the
along-slope component of a ~7° inclined playfield; frictionAir compounds per step
(0.0035 ≈ −0.2/s velocity decay) to emulate rolling losses on a waxed surface. The
plunger is tuned so ~80 % charge clears the lane — weak plunges fall back onto the
spring, exactly like a real machine.

## Rendering & assets

- **Runtime texture atlas** (`gfx/TextureFactory.ts`): every sprite is drawn with
  Canvas 2D at boot — soccer-ball shading, flippers, bumpers, 8 reel symbols, glow
  sprites — then shelf-packed into ONE 512-px canvas registered as the `atlas`
  texture with named frames. One GPU texture source, zero binary assets, zero
  licensing. This is spritesheet memory management in its purest form.
- **Single-sprite playfield** (`gfx/FieldPainter.ts`): stadium crowd, mow stripes,
  neon pitch lines, goal net and posts, HUD backing — all painted once into the
  `field` texture. The entire background costs one draw call.
- **Neon FX** via Phaser 3.60+ post-pipelines (`postFX.addGlow`) on the ball, bumpers
  and jackpot art, with graceful no-op on the canvas renderer. The jackpot light
  sweep is a single `Graphics` redrawn per frame — one batched primitive.
- **Particles**: Phaser 3.60 particle emitters (ball trail follows the body, bumper
  sparks explode on kick, jackpot confetti). Objects are created once and reused.

## Slot machine

- **Outcome decided up-front** (`slots/rng.ts`): one uniform stop index per reel via
  Web Crypto with rejection sampling (no modulo bias), then `evaluate()` produces the
  outcome. The reels are *animated to land* on it — the certified-slot model, and it
  makes anticipation logic trivial.
- **Reels**: each reel owns two prebuilt symbol columns (base + golden strips, which
  have different lengths) masked to a 3-row window; a spin scrolls a float position
  and a tween eases to the landing stop with an overshoot "clunk". Column swap on
  golden spins costs nothing.
- **Anticipation**: when reels 1–2 land on trophies, reel 3 spins 1.9 s longer with
  a pulsing glow + heartbeat SFX. Two-trophy losses are explicitly teased
  ("ONE TROPHY AWAY!") — the near-miss hook.
- **Safety net**: a 9 s force-finish timer guarantees the game can never soft-lock on
  a stuck tween.

## State & the React bridge

`GameState` is the single source of truth for the economy (credits, pot, balls,
multiplier). A Phaser `EventEmitter` fans out to the in-canvas HUD; two lifecycle
events are mirrored onto `window` as `CustomEvent`s for the React shell (game-over
dialog, restart button). React never touches game internals — the canvas world never
imports React.

## Performance budget (per frame at 60 fps)

| System | Cost |
|---|---|
| Matter step | 5 dynamic bodies + ~60 statics — trivial |
| Background | 1 sprite |
| Sprites | ~35 (table objects) + up to ~210 reel images (only during a spin) |
| Particles | pooled, ≤ ~120 alive |
| Text | 10 objects, updated only on discrete events |
| Physics sub-steps | 1 at 60 fps (accumulator only grows on slow frames) |

The dominant cost is WebGL batch submission of the reel columns during a spin; the
columns are static textures in one atlas, so they batch into a couple of draw calls.
