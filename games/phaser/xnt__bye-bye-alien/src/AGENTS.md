# AGENTS.md — Bye Bye Alien

## Project overview

Side-scrolling 2D space shooter built with **Phaser 3** + **TypeScript** + **Vite**.
A start screen lets the player choose one of four ships before launching into battle
against alien saucers, asteroid obstacles, and a boss mothership.
A timed UFO-disguise power-up temporarily maxes out all stats.
All textures are procedurally generated — there are zero image assets.

## Tech stack

- **Runtime:** Phaser 3 (Arcade Physics)
- **Language:** TypeScript (strict mode)
- **Bundler:** Vite 7
- **Tests:** Vitest 4 with `@vitest/coverage-v8`
- **Deploy:** GitHub Pages via `.github/workflows/deploy.yml`

## Project structure

```
src/
├── main.ts                # Phaser game bootstrap (parent: #game div)
├── config/
│   ├── game.ts            # Central numeric constants (dimensions, speeds, HP, etc.)
│   ├── game.test.ts       # Tests for game constants
│   ├── ships.ts           # ShipStats interface, 4 ship definitions, POWERUP_STATS
│   └── ships.test.ts      # Tests for ship definitions
├── entities/
│   ├── Player.ts          # Player ship (extends Arcade.Sprite)
│   ├── Player.test.ts     # Unit tests (Phaser mocked)
│   ├── Alien.ts           # Regular alien enemy (extends Arcade.Sprite)
│   ├── Alien.test.ts      # Unit tests (Phaser mocked)
│   ├── Boss.ts            # Boss mothership (extends Arcade.Sprite)
│   └── Boss.test.ts       # Unit tests (Phaser mocked)
├── scenes/
│   ├── StartScene.ts      # Ship-selection start screen (runs first)
│   └── GameScene.ts       # Main gameplay scene — spawning, collisions, HUD, game over
└── utils/
    ├── textures.ts        # Procedural texture generation for all sprites
    └── textures.test.ts   # Tests for texture generation (Phaser mocked)
```

## Commands

| Command                | Description                       |
|------------------------|-----------------------------------|
| `npm run dev`          | Start Vite dev server (port 3000) |
| `npm run build`        | Type-check + production build     |
| `npm test`             | Run tests once                    |
| `npm run test:watch`   | Run tests in watch mode           |
| `npm run test:coverage`| Run tests with coverage report    |
| `npm run preview`      | Preview production build          |

## Key conventions

### Game orientation

The game scrolls **left-to-right**:
- Player is on the **left**, facing right, shoots rightward (+X velocity).
- Enemies spawn from the **right** edge and move leftward (-X velocity).
- Stars scroll right-to-left.
- Boss enters from the right and patrols vertically.

### Phaser collision callbacks

Phaser's `physics.overlap()` can pass callback arguments in **either order**.
Always use `instanceof` checks to identify which object is which.
Never assume `objA` is the bullet and `objB` is the target.

```typescript
// ✅ Correct
if (objA instanceof Alien) {
  alien = objA;
  bullet = objB as Phaser.Physics.Arcade.Sprite;
} else {
  alien = objB as unknown as Alien;
  bullet = objA as Phaser.Physics.Arcade.Sprite;
}

// ❌ Wrong — will crash when Phaser swaps argument order
const bullet = objA as Phaser.Physics.Arcade.Sprite;
const alien = objB as unknown as Alien;
```

### Bullet pools

Bullets use Phaser's `Arcade.Group` with `maxSize` for object pooling.
When recycling a bullet from the pool, **always unconditionally re-enable** the physics body:

```typescript
// ✅ Correct
(bullet.body as Phaser.Physics.Arcade.Body).enable = true;

// ❌ Wrong — short-circuit prevents re-enabling disabled bodies
bullet.body?.enable && ((bullet.body as Phaser.Physics.Arcade.Body).enable = true);
```

### Scenes

There are two scenes, loaded in this order in `main.ts`:

1. **`StartScene`** — ship-selection screen. Shows cards for the four ships
   (F-35, Valkyrie, Titan, Spectre) with stat bars and bullet previews.
   Navigate with ←/→ or A/D keys, confirm with ENTER/SPACE, or click a card.
   Passes the chosen `ShipKey` to `GameScene` via `this.scene.start('GameScene', { ship })`.

2. **`GameScene`** — main gameplay. Receives the ship choice in `init(data)`,
   spawns the player, aliens, obstacles, power-up, and boss. Handles all
   collisions, HUD, and game-over flow. After game over the player can press
   R (or tap) to restart with the same ship, or Q to return to `StartScene`.

### Ship selection

`config/ships.ts` exports:
- `ShipStats` interface (name, description, textureKey, bulletTextureKey, speed,
  handling, damage, hp, fireRate, bulletSpeed).
- `SHIP_KEYS` — `['f35', 'valkyrie', 'titan', 'spectre'] as const`.
- `SHIPS` — a `Record<ShipKey, ShipStats>` with the four ship definitions.
- `POWERUP_STATS` — maxed-out `ShipStats` used during the UFO-disguise power-up.

### Power-up system

- A UFO-disguise power-up pickup spawns at `POWERUP_SPAWN_TIME` (20 s) and
  drifts leftward at `POWERUP_SPEED`.
- On collection the player's stats, texture, and bullet pool swap to
  `POWERUP_STATS` for `POWERUP_DURATION` (10 s), with a HUD countdown bar.
- When the timer expires, `Player.deactivatePowerUp()` restores base stats,
  texture, HP, and the original bullet pool.

### Boss (mothership) behaviour

- A "⚠ MOTHERSHIP INCOMING ⚠" warning flashes 5 s before `BOSS_SPAWN_TIME` (30 s).
- Boss spawns off-screen right and slides left at `BOSS_SPEED` until reaching
  `targetX = 680`, then patrols vertically between y = 80 and `GAME_HEIGHT − 80`.
- Boss fires **aimed** bullets toward the player's current position.
- Below 50 % HP the boss switches to a **3-way spread** pattern (angles −0.25, 0, +0.25 rad).
- Defeating the boss awards 2 000 points and triggers the win state.

### Obstacles

`OBSTACLE_COUNT` (8) static asteroid sprites are placed randomly at scene
creation. They block the player (collider) and destroy player bullets (overlap).

### Textures

All sprites are procedurally generated in `src/utils/textures.ts`.
No PNG/image files exist. The `generateTextures()` function is idempotent
(guarded by `this.textures.exists('f35')` in both `StartScene.create()` and
`GameScene.create()`).
When adding new entities, add a texture generator function there.

### Entity pattern

Every entity (Player, Alien, Boss) extends `Phaser.Physics.Arcade.Sprite` and:
1. Calls `scene.add.existing(this)` and `scene.physics.add.existing(this)` in the constructor.
2. Implements `update(time, delta)` for per-frame logic.
3. Has a `takeDamage(amount)` method — returns `boolean` (`true` if killed) for
   Alien and Boss; returns `void` for Player (use `player.isDead()` instead).
4. Manages its own firing via a `fire(time, bulletGroup)` method (enemies) or private `fire(time)` (player).
5. Player additionally has `activatePowerUp(stats)` / `deactivatePowerUp()` for the power-up system.

### Tests

- Test files are co-located: `foo.ts` → `foo.test.ts` in the same directory.
- Use `describe` / `it` / `expect` from Vitest.
- Entity classes (`Player`, `Alien`, `Boss`) and `textures.ts` are unit-tested
  via Phaser mocks (see `vi.mock('phaser', …)` in each test file).
- Scene code depends on full Phaser runtime and is currently **not unit-tested**.
- Config modules (`config/game.ts`, `config/ships.ts`) are tested.

### Build & deploy

- `npm run build` runs `tsc --noEmit` then `vite build` → outputs to `dist/`.
- Vite `base` is set conditionally: `/bye-bye-alien/` in GitHub Actions, `/` locally.
- The GitHub Actions workflow (`.github/workflows/deploy.yml`) deploys `dist/` to GitHub Pages on push to `main`.

### HTML structure

The game canvas is rendered inside `<div id="game">` (set via `parent: 'game'` in the Phaser config).
A `<footer>` inside that div is absolutely positioned at the bottom, overlaying the canvas.

## Path aliases

`@/` maps to `src/` (configured in both `tsconfig.json` and `vite.config.ts`).

```typescript
import { Player } from '@/entities/Player';
```
