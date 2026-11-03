# Developing Slowblue

How to run, test, measure and ship it. For what the game *is*, read the
[README](../README.md) and [GAME.md](GAME.md); for the rules the code follows, read
[CLAUDE.md](../CLAUDE.md) and [CONTRIBUTING.md](../CONTRIBUTING.md).

* [Run it](#run-it)
* [Commands](#commands)
* [How the code is laid out](#how-the-code-is-laid-out)
* [URL parameters](#url-parameters)
* [The admin surface](#the-admin-surface)
* [The debug panel](#the-debug-panel)
* [Local measurement](#local-measurement)

## Run it

You need a current Node LTS (it is developed on Node 22) and nothing else — there are no
runtime dependencies and no services.

```bash
npm install && npm run dev
```

Open the printed `http://<your-lan-ip>:5173` on a phone: the dev server binds to all
interfaces, because this is a game for a thumb and a desktop window lies about it.

## Commands

```bash
npm run dev        # dev server on all interfaces
npm run build      # typecheck + production build into dist/
npm run preview    # serve that build on :4173
npm run verify     # the gate: lint + typecheck + unit + build + e2e
npm test           # unit tests only, fast
npm run e2e        # mobile-viewport browser tests against the production build
npm run sweep      # balance sweeps: scripted players, minutes rather than seconds
npm run screens    # regenerate the documentation screenshots (the only thing that writes them)
npm run icons      # regenerate the PWA icons (no image dependencies)
npm run deploy     # publish dist/ to the gh-pages branch, by hand
```

The e2e suite previews the production build on **port 4173** and, by default, reuses a
server that is already answering there. That check can only ask whether *something* is
listening, not whether it is this game — so if another project is squatting the port, the
whole suite silently runs against the wrong page and times out five minutes at a time.
Move it out of the way, and build first:

```bash
npm run build && SLOWBLUE_E2E_PORT=4271 npm run e2e
```

Naming a port also turns reuse off, and the preview starts with `--strictPort`, so a
collision fails immediately instead of drifting to the next free port and leaving
`baseURL` pointing at whatever was already there.

`npm run verify` takes about a quarter of an hour, nearly all of it e2e, and three e2e
specs fail on a clean checkout — see [CONTRIBUTING.md](../CONTRIBUTING.md) for their names.

## How the code is laid out

TypeScript and Vite, no framework. Canvas 2D for every pixel (no WebGL, no post-processing),
Web Audio for every sound (nothing is a sample), Pointer Events for input, and a fixed
1/60 s simulation step with the render interpolated between steps.

| Directory | What lives there |
| --- | --- |
| `src/core/` | the fixed-step game loop, seeded RNG, math helpers, guarded `localStorage` |
| `src/sim/` | the headless simulation — swarm, flow fields, medium, obstacles, hunters, rescue rings, failure rules. No DOM, so every test and sweep can run it |
| `src/config/` | the authored campaign: every station and section of every act, the tuning table, the zones |
| `src/render/` | the Canvas 2D renderer, one file per act's picture, the banners and the closing films |
| `src/audio/` | procedural Web Audio: the mixer, the eight beds, and one physical-model file per voice |
| `src/meta/` | what survives a session: profile, campaign checkpoints, the circuit map's model |
| `src/ui/` | the DOM shell — title, circuit map, pause, game over — over the canvas |
| `src/input/` | pointer gestures to flow strokes |
| `src/platform/` | the PWA registration and the haptics driver seam |
| `src/debug/` | the admin surface and the debug panel, both behind a URL parameter |
| `src/telemetry/` | local-only run recording; nothing leaves the device |
| `src/brand/` | the studio ident that plays before the title |
| `tests/` | unit tests and headless playability probes (vitest) |
| `e2e/` | browser tests (Playwright) and the specs that take the review screenshots |
| `tools/` | balance sweeps, the icon generator, the deploy script |

[IMPLEMENTATION_NOTES.md](../IMPLEMENTATION_NOTES.md) has the file-by-file inventory and
the reasoning behind each mechanic.

## URL parameters

| Parameter | Effect |
| --- | --- |
| `?seed=12345` | The first run of the session plays that exact water |
| `?debug=1` | Show the tuning panel and the stats overlay (`d` toggles it from there). Asked for rather than assumed, in `npm run dev` exactly as in a build: most of the work here is looking at the picture, and it cannot be judged through forty sliders. |
| `?admin=1` | Show the admin surface (also `a` on a keyboard, always on in `npm run dev`) |
| `?act=air` | Boot straight into one act: `water`, `air`, `thin`, `orbit`, `reentry`, `rain`, `home`. A run opened this way advances no circuit and touches no record. |
| `?intro=summon` / `reveal` / `reduced` | Play that variant of the studio ident, even where it would not play on its own |
| `?skipIntro` | Skip the studio ident |

## The admin surface

Every authored thing in the game, one tap away, on the device it is being felt on. Three
tabs:

* **Stations** — all forty-two stations of all seven acts. One tap starts the run *on* that station:
  right act, right medium, right palette, right banner, from its first section.
* **Sections** — every authored section on its own, listed with what it carries (rings
  and which are mandatory, rotors and their strength, raptors). One tap
  opens a run on that section, so a narrows is a run that *starts* on a narrows.
* **Sounds** — every sound the engine makes, fired by hand: nineteen event cues, the seven
  act endings, and the bed voices of whichever of the eight beds is selected — only those,
  because a button that plays a whale while the orbit bed is up is a tool that lies about
  what the game does. They otherwise schedule themselves and cannot be *examined* by
  playing (a whale is once or twice a minute by design; an infrasound swell is once or
  twice in five). Over sliders for the bed, its arc, stereo position and ring-hold, because
  most of those sounds are parameterised by where you are rather than by what happened. The
  endings are their own group because they are the only sounds in the game you cannot
  otherwise hear without finishing a ten-minute act — and because they run up to fourteen
  seconds each, so they are worth playing one at a time.

The clock freezes while the sheet is open, a muted mixer track is marked as such (with one
button to bring them all back), and **a run started from here is never written to your
personal bests** — jumping to the last station and finishing it is not a campaign flown.

## The debug panel

Live sliders for all 30 physical parameters (flow strength, radius, decay, diffusion,
speed ceiling, turbulence, coupling, ambient strength and ramp, alignment, cohesion,
separation, avoidance, migration, speeds, accel, agent count, world speed, pressure ramp,
inertia per agent, rescue ring radius and commitment, vortex strength, hunter speed,
hunter water coupling, flight response). Plus: velocity-field and spatial-hash overlays,
FPS and frame time, seed replay, config export/import, defaults reset, slow motion and
pause, and telemetry export. Values persist in `localStorage`.

## Local measurement

Every run is recorded locally and can be exported as JSON from the panel: time to first
interaction, run length, restart latency, gesture count and mean length, gates cleared,
individuals rescued and lost, mean shoal spread, seed repeats, FPS and slow-frame ratio.
