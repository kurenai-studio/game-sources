# Mimic Sniper

A low-poly asymmetric Three.js game: one player is a black, spider-legged mimic that copies environmental props; the other is a stationary sniper watching from a distant vantage point.

## MVP

- Procedural six-legged mimic locomotion
- Nearby prop highlighting and instant disguise switching with poof VFX
- Stationary sniper camera with scope zoom, breathing sway, hold-breath control, recoil, hitscan shooting, ammo, and reload
- 90-second round state machine with sniper/mimic win conditions
- Low-poly industrial test map
- Core mechanics structured for later authoritative online multiplayer and matchmaking

> The current build exposes both roles on one client as a mechanical test harness. The product goal is online matchmaking, not local shared-machine play.

## Controls

| Control | Action |
|---|---|
| `WASD` | Move the mimic |
| `E` | Copy highlighted prop / reveal |
| Mouse | Aim sniper |
| Right mouse | Hold scope |
| Left mouse | Fire |
| `Shift` | Hold breath |
| `R` | Reload |

## Run

```bash
npm install
npm run dev
```

Open `http://localhost:5173`.

## Verify

```bash
npm test
npm run build
```

## Project research

The project-specific LLM Wiki lives in [`wiki/`](wiki/index.md), with mechanic research and implementation notes.

## Roadmap

1. Authoritative Node/WebSocket room server
2. Lobby codes and online matchmaking
3. Separate Mimic and Sniper clients
4. Server-side shot validation and movement snapshots
5. Additional maps, prop sets, sound, and balance passes

## License

MIT
