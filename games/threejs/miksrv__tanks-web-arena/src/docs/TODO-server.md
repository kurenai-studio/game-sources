# TODO: client-server

Deferred (discussion of 2026-10-27). The goal is for fun: with a server → online battle with ranks and progression; without a server → local play without ranks but with local progression (changed 2026-10-28, see [TODO-progression.md](TODO-progression.md)). 2–4 live players per battle, the remaining slots are filled with bots. The server is our own VPS with Docker.

## Architecture

- A single battle simulation (`sim`) that runs both in the browser and on the server. The client talks to it through a `Transport` interface:
  - `LocalTransport` — the simulation in a Web Worker, exchange via `postMessage` (snapshots as transferable `ArrayBuffer`). Offline, no ranks.
  - `SocketTransport` — the same simulation on the server, WebSocket. Ranked battle.
  - `InProcessTransport` — fallback: direct calls in the main thread, no serialization (debugging, Worker problems).
- Npm workspaces: `sim` (no rendering and no DOM) / `client` (rendering, HUD, sound, input, interpolation) / `server` (rooms, matchmaking, accounts, DB). The compiler enforces the boundaries.
- Authoritative server: the client sends only input (throttle, steering, aim point, fire, shell type, consumable). Invisible enemies do not make it into the snapshot — honest spotting.
- The map is distributed as a seed; generation must be strictly deterministic.

## What to rework in the code

- [ ] `Tank` owns `TankView`: the simulation reads the scene graph — barrel direction from `view.group.updateMatrixWorld` in `Tank.fire` (`src/tank/tank.ts`), `hullTop` from the view. Separate state from visuals, compute the barrel mathematically.
- [ ] World generation: separate colliders and heights from meshes (`world/buildings`, `world/props`, `world/terrain`). The Worker computes the map and passes ready height arrays to the main thread so as not to generate twice.
- [ ] Map determinism by seed: check `Math.random` in `world/terrain/terrain.ts` (and everything that affects the layout).
- [ ] Battle effects (`combatFeedback`, particles, sound) are called directly from the simulation → switch to events ("penetration at point X, damage Y").
- [ ] Split `game.ts` into `ServerMatch` (fixed tick, no rendering) and `ClientGame` (input, rendering, interpolation).
- [ ] Gun marker, penetration chance under the cursor, artillery ellipse — compute on the client from the latest snapshot, not from the live `Tank`.

## Netcode

- Tick: 60 Hz locally, 30 Hz on the server; snapshots at 20–30 Hz, only visible tanks (a few KB/s per player).
- Client-side prediction of the player's own tank + reconciliation with the server (can be disabled locally).
- Interpolation of other tanks (~100 ms buffer online, less locally); visual interpolation of the player's own tank between ticks.
- Lag compensation for hits: the server rewinds target positions by the shooter's ping.
- Camera and reticle stay on the client and are instant; a shot waits for the next tick.

## Server and deployment

- A single Node Docker container: WebSocket (`ws`) + serving the client's static files.
- SQLite on a volume: accounts, rating, XP, unlocked tanks, battle history.
- Caddy in front of the container — automatic HTTPS (a page served over https will not open `ws://`). Everything in `docker-compose`.
- Protocol version check on connect («обнови страницу» (refresh the page)).
- A room with an invite code, or a queue "wait N seconds → fill with bots"; bots live on the server.

## Ranks and progression (online only)

- Account: nickname + password, token in `localStorage`.
- XP per battle (damage, spotting, assist, victory) → unlocking tank research trees.
- Rating: Glicko-2 or Elo from the battle outcome, adjusted for personal contribution (meaningful even with a single live player).
- Statistics: win rate, average damage, medals.

## Stages

1. Separate `sim` from rendering, deterministic map, events instead of direct effect calls, `LocalTransport` + Worker. The game works as it does now.
2. `server/` in Docker, rooms, input → snapshots without prediction.
3. Netcode: prediction, interpolation, lag compensation.
4. Accounts, SQLite, XP, rating, research trees.
5. Deployment on a VPS with Caddy.

## Open questions

- Battle format with live players: co-op against bots, PvP, or a choice when creating the room?
- One shared rating or separate ratings for PvP and co-op?
- A domain for the VPS (Caddy needs one for the certificate); if none — `sslip.io` / DuckDNS.

## Client load in local mode

Slightly more work overall (serialization, interpolation, a second copy of the heights and colliders — a few MB), but all the logic — bots, spotting, ballistics, collisions — moves out of the main thread into the Worker. Frame time in the main thread will go down, and the micro-freezes from recomputing bot positions will go away.
