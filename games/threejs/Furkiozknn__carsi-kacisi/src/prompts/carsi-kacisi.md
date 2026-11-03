# Arena round 5, game 4: Çarşı Kaçışı (rooftop runner) — built by Claude Haiku 5.5

```text
Build a single-file browser game (one index.html with inline CSS and JS) using Three.js r170 loaded as an ES
module from https://cdn.jsdelivr.net/npm/three@0.170.0/ (import map; addons from examples/jsm/).
A 3D rooftop platform-runner called "Çarşı Kaçışı" set on the domed roofs of a grand Istanbul covered bazaar.
Do not ask questions, build it end to end.

WORLD: rows of lead-grey domes, chimneys, skylights, wooden walkways, laundry lines between buildings, pigeons,
cats, minarets on the horizon and the Golden Horn in the distance at late afternoon. A bright, clear palette:
blue sky, warm stone, grey domes, one accent colour (#0F766E çini teal). Keep it simple and readable.

CORE MECHANIC: a third-person runner on hand-built short levels (not endless). The player is a young apprentice
chasing a cat that stole a ring from the jeweller. Run, jump, double jump, slide down dome sides (fast), swing or
slide on laundry lines, climb low ledges. Falling into the street sends you back to the last checkpoint. Collect
pieces of lokum (Turkish delight) along the way. Catch the cat at the end of each level.

CONTENT: 10 levels, each 60-120 seconds, getting harder (moving planks, breaking tiles, gusts of wind, pigeons
that fly up and block the view at night levels). Level data in one table in the code. Stars for time, lokum
collected and no falls. A level select map of the bazaar roofs.

CONTROLS: WASD / arrows move, Space jump, Shift slide, camera follows automatically (mouse drag can turn it);
touch: virtual stick, jump and slide buttons. The controls must feel tight: coyote time, jump buffering, no
sliding off edges by accident.

HUD: top bar (logo, level, time, lokum, stars, pause, sound, language), toasts, title, level map, level result,
ending where the ring goes back to the jeweller.

EXTRAS: footsteps on lead and wood, pigeon flaps, cat meows, a lively darbuka-and-clarinet loop, all
synthesised (CC0 one-shots from asset-forge allowed).
```

The shared rules in `_sablonlar/arena-round5-common.md` are appended to this prompt.
