# THE UNDERLAY

A Daggerfall-style first-person co-op dungeon crawl that runs in the browser. Pixel-art billboards in a Three.js world, a night-shift grocery store overworld, five procedurally generated floors underneath it, and a server that owns every player's progress.

Up to 10 players share the overworld; parties of up to 3 go down together.

## How it's built
- `public/index.html` — the whole client (Three.js + PointerLockControls, vendored under `public/vendor/`)
- `server.js` — Colyseus game server: overworld room, five dungeon rooms, profile store (`profiles.json`), export/import endpoints
- `render.yaml` — one-click deploy blueprint for Render

## Run it locally
```
npm install
npm start
```
Open http://localhost:2567 — the server serves the client too.

## Controls
| | Move | Look | Attack | Interact |
|---|---|---|---|---|
| **Keyboard + mouse** | WASD | mouse (click to lock) / arrows | click or Space | E |
| **Touch** | left stick | drag right side | ATTACK | INTERACT |
| **Gamepad** | left stick | right stick | A / RT | X |

## The story
Talk to the night clerk. Clear floor 1 for the badge. Three seals on floors 2–4. The freezer on 5. Credits.

## Play
- **https://underlay.onrender.com** — server + client together (free tier: first load after idle takes ~30–60 s to wake)
- **https://michaelbegley.github.io/underlay/** — the same client on GitHub Pages, talking to the Render server

## Hosting
The server needs a Node host that keeps a WebSocket open (Render, Railway, Fly, a VPS). GitHub Pages can only host the client; it connects to whatever `SERVER_URL` points at in `public/index.html` (currently `wss://underlay.onrender.com`) (or `?server=wss://…` on the URL).

Free tiers sleep when idle — the first player of the evening waits ~30 s for the server to wake.

Set `EXPORT_TOKEN` in the environment to enable `/profiles/export` and `/profiles/import` (progress survives redeploys if you export first).

MIT licensed. Designed with DeepSeek; debugged, packaged and deployed with Claude.
