# Projectile Defense

A small side-scrolling shooter built with [Phaser 3](https://phaser.io), Vite and TypeScript. Your ship sits on the left edge; aliens fly in from the right. Shoot them before they reach you, and survive as long as you can while the spawn rate ramps up.

![screenshot](screenshot.png)

## Controls

| Input | Action |
|---|---|
| `Up` / `Down` or `W` / `S` | Move the ship |
| `Space` | Shoot (hold to auto-fire) |
| Touch devices | On-screen up/down buttons and a fire button appear automatically |
| `Space` / `Enter` on the game-over screen | Restart |

Your best score is saved in the browser (localStorage) and shown on the game-over screen.

## Player name

Pass a `name` query parameter to show a player name in the HUD and on the game-over screen:

```
http://localhost:8080/?name=Mervin
```

## Enemies

| Enemy | Speed | Hits to kill | Damage on reaching you | Points |
|---|---|---|---|---|
| Pink | medium | 2 | 2 | 10 |
| Blue | slow, bobs up and down | 4 | 1 | 12 |
| Green | fast, flickers | 1 | 2 | 8 |

You start with 10 health. Gameplay numbers live in [src/constants/gameplay.ts](src/constants/gameplay.ts).

## Development

Requires [Node.js](https://nodejs.org). Install with `yarn` (or `npm install`).

| Command | Description |
|---|---|
| `yarn dev` | Start the dev server on `http://localhost:8080` |
| `yarn build` | Production build into `dist/` |
| `yarn dev-nolog` / `yarn build-nolog` | Same, without the Phaser template's anonymous usage ping (`log.js`) |

### Project structure

| Path | Description |
|---|---|
| `src/main.ts` | Bootstraps the game and reads the `?name=` param |
| `src/game/main.ts` | Phaser config, scene list, responsive plugin registration |
| `src/game/scenes/` | `Preload` (assets) → `Game` (gameplay) → `GameOver` (overlay with best score) |
| `src/game/sprites/` | `Bullet` and the `Enemy` base class plus the three enemy types |
| `src/game/plugins/responsive-dimensions-plugin.ts` | Exposes scale factors relative to the 1280×620 base resolution |
| `src/constants/` | Base dimensions and gameplay tuning |
| `public/assets/` | Sprites, UI and audio, served as static files |

Releases: creating a `release/x.y.z` branch triggers a GitHub Action that writes that version into `package.json`.

## License

MIT
