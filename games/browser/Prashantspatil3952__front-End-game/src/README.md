# live demo https://prashantspatil3952.github.io/front-End-game/

# front-End-game
EVOLVE — A polished offline HTML5 canvas game where a glowing sphere bounces inside a circular arena and gradually grows over time, leaving an evolving procedural ribbon trail. Built with vanilla HTML, CSS, and JavaScript with no libraries, CDNs, remote assets, or network dependencies.
# Offline Canvas Game

A polished, self-contained browser game inspired by the supplied circular bounce reference.

The project is intentionally built with **plain HTML, CSS, and JavaScript** so the exact same files can run with **no internet connection**. There are no CDN imports, package managers, external fonts, remote images, analytics scripts, or network requests.

## Features

- Production-style 9:16 presentation designed for mobile and desktop.
- Circular arena with crisp white boundary and subtle cyan bloom.
- Glossy cyan sphere with layered lighting, specular reflections, rim lighting, and pulse effects.
- Procedural, ribbon-like trail with a bright tube, inner core, repeated ribs, and live highlight seam.
- Bounce particles, impact ripples, sparkles, and controlled camera breathing.
- Progressive evolution: the ball and trail gradually increase their visual intensity as the bounce count rises.
- **Space = Pause / Resume**. Pausing freezes the simulation in its exact current position; it never restarts the run.
- Tap/click inside the game to boost the ball.
- `R` or the RESET button starts a fresh run.
- Automatic pause when the browser tab becomes hidden.
- Responsive rendering with device-pixel-ratio support.
- No external dependencies.

## Project structure

```text
EVOLVE/
├── index.html
├── style.css
├── game.js
└── README.md
```

## Run locally

### Simplest method

Open `index.html` directly in a modern browser.

### Local server

A local server is optional. For example:

```bash
python3 -m http.server 8080
```

Then open:

```text
http://localhost:8080/
```

The game itself does not depend on the server and does not make network requests.

## Controls

| Action | Control |
|---|---|
| Pause / Resume | `Space` |
| Boost | Tap / Click inside the arena |
| Reset | `R` or `RESET` |
| Resume while paused | Tap `RESUME`, tap the game, or press `Space` |

## Offline behavior

The game contains only local files:

- `index.html`
- `style.css`
- `game.js`

There are no `<script src="https://...">`, `<link href="https://...">`, remote images, remote audio files, or API calls. This keeps online and offline gameplay visually and mechanically identical.

## Performance notes

The renderer uses multiple canvas layers:

- **scene** — background, arena, trail body, and ball.
- **fx** — additive glow, particles, ripples, and bloom-like effects.
- **uiCanvas** — final vignette/overlay treatment.

The trail and particle counts are capped to keep the game responsive on mobile hardware. Canvas resolution follows `devicePixelRatio` but is capped at `2` for a better quality/performance balance.

## Customization

Most gameplay values are at the top of `game.js`, including:

- `MAX_TRAIL`
- `MAX_PARTICLES`
- initial ball velocity
- bounce speed growth
- maximum ball radius
- particle counts
- trail width
- glow intensity
- arena size

The visual theme can be changed through the CSS variables in `style.css`.

## GitHub repository description

**EVOLVE — A polished offline HTML5 canvas game where a glowing sphere bounces inside a circular arena, leaving an evolving procedural ribbon trail. Built with vanilla HTML, CSS, and JavaScript — no libraries, CDNs, or network dependencies.**

## Suggested GitHub topics

`html5` `canvas` `javascript` `css` `offline-game` `browser-game` `2d-game` `procedural-animation` `gamedev` `mobile-game`

## License

Choose the license that fits your project before publishing. If this is intended for commercial distribution, a permissive license such as MIT may be appropriate, but confirm that it matches your ownership and distribution requirements.

## Evolution system (updated)

The ball no longer grows only when it hits the wall. Its size now follows a smooth, time-based evolution curve and receives smaller secondary boosts from bounce milestones. This makes the change visible over a normal play session and keeps the motion cinematic rather than jumpy.

The visual evolution is synchronized across:

- ball radius
- trail/tube thickness
- cyan bloom size
- sphere rim/reflection intensity
- impact energy
- evolution meter
- stage flash effects

The growth is intentionally gradual and caps before the ball becomes large enough to break the arena composition.

## Pause behavior (updated)

Pressing `Space` freezes the simulation at the exact current frame. The ball does not teleport, reset, shrink, or lose its trail. Simulation time also stops while paused, so the evolution timer does not advance in the background.

Press `Space` again, tap the game, or press `RESUME` to continue from the same state.
