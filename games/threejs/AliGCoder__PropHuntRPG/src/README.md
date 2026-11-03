# 🪵 PropHunt RPG

**Peer-to-peer prop hunt with persistent RPG skills, built on three.js r187 (WebGPU + TSL).**

Hide as a barrel. Hunt with an axe. Level up Woodcutting until you can disguise
as an oak tree in the middle of a forest. Your skills stay with your character
from round to round.

[![CI](https://github.com/AliGCoder/PropHuntRPG/actions/workflows/ci.yml/badge.svg)](https://github.com/AliGCoder/PropHuntRPG/actions/workflows/ci.yml)
[![Deploy](https://github.com/AliGCoder/PropHuntRPG/actions/workflows/pages.yml/badge.svg)](https://github.com/AliGCoder/PropHuntRPG/actions/workflows/pages.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

▶ **Play:** https://aligcoder.github.io/PropHuntRPG/

## Features

- **Prop hunt core**: hiders disguise as world props, hunters search and
  lose HP for hitting the wrong thing. Teams rotate every round.
- **Persistent skills**: Woodcutting, Mining, Fishing and Agility (levels 1–50), saved to your character.
- **Skills inside the round loop** (full design in [`docs/GAME_DESIGN.md`](docs/GAME_DESIGN.md)):
  - Levels unlock your **disguise wardrobe** (a Woodcutting-30 player can be a birch tree).
  - Pick a **Trade** each round. It sets your hunter tool and your ability on either team.
  - **Resource nodes**: hunters gather with the right tool and take no penalty, while
    hiders forage XP next to them but give off visible particles.
  - Small, capped perks so skill beats grind.
- **Peer-to-peer lobbies** over WebRTC (PeerJS). Share a 5-letter code, no game server needed.
- **Single player with bots** for practice and testing. Bots go through the same host
  code paths as real players.
- **three.js r187 features used**:
  - `WebGPURenderer` with automatic WebGL 2 fallback
  - `RenderPipeline` with GTAO, TRAA, MRT-based selective bloom and gameplay outlines
  - `SunLight` with cascaded shadow maps, `SkyMesh` with animated clouds and PMREM image-based lighting
  - TSL node materials for wind-swayed props, instanced grass that bends away from
    the player, and faceted water with depth colour and shoreline foam

## Quick start

```bash
npm install
npm run dev        # http://localhost:5173
npm test           # rules + full bot-round simulation (Node, no browser)
npm run build      # production build → dist/
```

Requires Node 20.19+ and a browser with WebGPU or WebGL 2.

## Controls

| Key | Action |
|-----|--------|
| WASD / Shift / Space | Move / sprint / jump |
| Mouse | Look (click the game to capture the mouse) |
| **E** | Disguise as the prop you're aiming at (hider) |
| **Click** | Swing tool / gather a resource node (hunter) |
| **F** (hold) | Forage next to a matching resource node (hider) |
| **Q** | Trade ability |
| **R** | Lock prop rotation |
| **T** | Taunt (+Agility XP, but everyone hears it) |
| **Tab** | Skills & wardrobe |
| **N** | Next player while spectating |

## Project layout

```
src/
  core/       EventEmitter, Input, seeded RNG & noise
  skills/     skill definitions, XP curve, CharacterStore (persistence)
  world/      Heightfield, PropCatalog (data), MapLayout (seeded placement), SpatialGrid
  game/       HostServer (authoritative sim), Bots, rules (all balance), abilities, GameSession (client)
  net/        protocol, ClientSession (state mirror + intents), Network (solo / host / join)
  render/     Renderer + RenderPipeline, Environment, TSL materials, PropFactory, terrain/water/grass
  entities/   PlayerView, CharacterModel, LocalController, CameraRig
  fx/         particles / rings / lines, procedural WebAudio SFX
  ui/         menu, lobby, HUD, skills panel (vanilla DOM + CSS)
tests/        node:test suites for rules and host simulation
docs/         GAME_DESIGN.md, ARCHITECTURE.md
```

How the pieces fit together is in [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md).

## Contributing

PRs welcome! See [CONTRIBUTING.md](CONTRIBUTING.md). Good first issues: new prop
types (pure data in `PropCatalog.js`), new abilities, map zones, UI polish.

## License

[MIT](LICENSE) © AliGCoder and contributors.
