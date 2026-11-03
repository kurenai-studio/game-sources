# Architecture

```
            ┌──────────────────────── browser (every player) ────────────────────────┐
            │                                                                         │
 input ──►  │  GameSession ──intents──► ClientSession ──send──► transport ─────────┐  │
            │      ▲   │                    ▲                                      │  │
            │      │   └─ render: Renderer, WorldView, PlayerView, Effects, HUD    │  │
            │      └──────── events / snapshots ─┘                                 │  │
            └──────────────────────────────────────────────────────────────────────┼──┘
                                                                                   │
              in-memory (solo / host's own client)  or  WebRTC DataChannel (PeerJS)│
                                                                                   ▼
                                ┌──────────── host only ────────────┐
                                │ HostServer (authoritative)        │
                                │  ├ MapLayout (seeded, pure data)  │
                                │  ├ rules.js / abilities.js        │
                                │  └ BotBrain × N (same intents)    │
                                └───────────────────────────────────┘
```

## Principles

1. **Simulation and rendering are separate.** `HostServer`, `MapLayout`,
   `rules`, `skills` and `Bots` never import three.js, so they run in Node
   tests (`npm test` plays full bot rounds headlessly).
2. **Data-driven content.** Props, abilities and skills are plain objects.
   Adding a prop means adding one entry to `PropCatalog.js`. The geometry,
   collision, unlocks and wardrobe UI all pick it up automatically.
3. **One code path for every mode.** Single player is a host with an
   in-memory link. Bots send the same intents as networked clients.
4. **Deterministic worlds.** Every peer builds the identical map from the
   host's seed, so the network only ever refers to props by index.
5. **Balance in one file.** Every number that affects fairness lives in
   `src/game/rules.js`.

## Message flow example: a hunter swings

1. `GameSession` raycasts from the crosshair, finds prop #212 within reach and
   calls `client.hit('prop', 212)`.
2. `HostServer#onHit` checks team, phase, swing cooldown and distance.
3. If the hunter's trade gathers that node type, the hit counts as a gather:
   XP goes to the hunter, a `gather` event goes to everyone, and the node may deplete.
   Otherwise the hunter takes the wrong-prop penalty (`damage` event).
4. Every client plays particles and SFX for the event. The hunter's own
   `ClientSession` receives an `xp` event and `CharacterStore.addXp` persists it.

## Rendering

`Renderer.buildPipeline` composes a TSL graph per quality tier:

| Tier   | Graph |
|--------|-------|
| high   | pre-pass (normal + velocity MRT) → GTAO → scene pass (AO via `builtinAOContext`, emissive MRT) → TRAA; + selective bloom + outline |
| medium | scene pass (MSAA ×4, emissive MRT); + selective bloom + outline |
| low    | scene pass; + outline |

All props share **one** `MeshStandardNodeMaterial`. Colour comes from vertex
colours, glow from a `glow` vertex attribute (which feeds the emissive MRT and
therefore bloom), and wind from a `sway` attribute combined with `modelPosition`
for per-object phase.

## Extending

- **New skill**: add to `skills.js` → give props that skill in `PropCatalog.js`
  → (optional) abilities in `abilities.js` → effect handling in
  `HostServer#onAbility`.
- **Dedicated server / anti-cheat**: `HostServer` is transport-agnostic, so it
  can run in Node behind WebSockets, with `CharacterStore` swapped for a
  server-backed profile.
- **Own signalling / TURN**: edit `peerOptions()` in `src/net/Network.js`.
