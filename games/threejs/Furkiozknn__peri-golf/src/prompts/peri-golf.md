# Arena round 3, game 3: Peri Golf (mini golf in Cappadocia) — built by Claude Fable 5.1

```text
Build a single-file browser game (one index.html with inline CSS and JS) using Three.js r170 loaded as an ES
module from https://cdn.jsdelivr.net/npm/three@0.170.0/ (import map; addons from examples/jsm if needed).
A 3D physics mini-golf game called "Peri Golf" set among the fairy chimneys of Cappadocia. Do not ask questions,
build it end to end.

WORLD: 12 hand-designed holes on terraces between fairy chimneys, cave houses, a pigeon valley, an
underground-city tunnel, a pottery workshop, a vineyard and a rim at sunrise with hot-air balloons drifting
overhead. Each hole is a sculpted course with soft tuff-stone walls, slopes, bumps, ramps, bridges and moving
obstacles (a turning pottery wheel, a rolling stone door from the underground city, swinging lanterns, a donkey
that crosses the path). Built entirely in code, no external models or textures. Warm sunrise palette, flat
shading with soft shadows, one accent colour (#E85D4A balloon red).

LIFE: balloons rise and drift, pigeons take off when the ball passes, lanterns sway, the sun climbs from hole
1 to hole 12 so the light warms and the shadows shorten.

GAME RULES: real ball physics written in the game (no physics library): rolling friction, slopes, wall bounces
with restitution, ramps and jumps, sand and grass zones with different friction, water hazards with a one-stroke
penalty and reset, moving obstacles that push the ball. Par per hole, strokes, score card with birdie/par/bogey,
a total over 12 holes, a ghost line of your best shot, three challenge stars per hole (under par, a hidden
grape to collect, a trick shot). Course unlocked hole by hole; best card saved.

INTERACTION: drag back from the ball to aim and set the power (a trajectory preview for the first bounce),
release to shoot; a camera that orbits the ball, a top-down overview toggle, keyboard aim with arrows and
power with Space hold. Touch-friendly.

HUD: top bar (logo, hole n/12, par, strokes, total, pause, sound, language), the power meter, a score card,
hole intro cards with the hole name and a fly-over, toasts, title, end-of-course card with stars.

EXTRAS: ball clicks and rolls that depend on the surface, wind, balloon burners, pigeons, a calm saz-and-strings
music loop, all synthesised.
```

The shared rules in `_sablonlar/arena-round3-common.md` are appended to this prompt.
