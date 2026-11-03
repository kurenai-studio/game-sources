# Arena round 6, game 1: Topkapı Gecesi (palace stealth) — built by Claude Opus 5.5

```text
Build a single-file browser game (one index.html with inline CSS and JS) using Three.js r170 loaded as an ES
module from https://cdn.jsdelivr.net/npm/three@0.170.0/ (import map; addons from examples/jsm/).
A 3D stealth game called "Topkapı Gecesi" set at night in an Ottoman palace. Do not ask questions, build it end
to end.

STORY: a famous diamond (call it "the spoon-maker's diamond" / "Kaşıkçı Elması") was swapped for a fake by a
thief inside the palace. You are a young palace page (iç oğlanı) who must sneak through the courts at night,
find clues, and put the real diamond back before dawn without being caught. Short TR / EN notes and dialogue.

WORLD: stylised low-poly Topkapı-like palace: courtyards with cypresses and fountains, colonnades with domed
porticoes, tiled pavilions (köşk) with blue-and-white çini walls, the treasury, kitchens with chimneys, the
harem corridors, a view over the Bosphorus with moonlight on the water. Moonlit blue night with warm lantern
pools of light; one accent colour (#C9A227 Ottoman gold). Readable silhouettes, props everywhere (carpets,
divans, braziers, chests, potted tulips).

CORE MECHANIC: real stealth.
- Guards (halberdiers, eunuch guards, a cook, a cat) patrol on routes, look around, and have vision cones that
  are visible on the ground. Light matters: in lantern light you are seen from far, in shadow only close up.
- Noise: running, stepping on gravel or knocking a vase makes sound rings guards investigate.
- Guard states: idle → suspicious (question mark, turns, walks to the last seen or heard spot) → alert (chases,
  calls others) → search → back to patrol.
- Player tools: crouch-walk, hide behind curtains and in chests, snuff out lanterns (they get relit by a passing
  guard later), throw a pebble to lure, a short dash.
- Caught = restart from the last checkpoint (quiet fountain).
- Light-and-shadow visibility meter in the HUD.

CONTENT: 9 night missions in 3 parts (the courts, the harem, the treasury), each with an optional objective
(collect a lost tulip bulb, read a secret letter, no alerts). Stars for no detection, time and optional
objectives. Mission data in one table; the guard routes must allow a clean solution, and the bot must find one.

INTERACTION: WASD / arrows move, Shift run, C or Ctrl crouch, E interact (hide, snuff, pick up), Q throw pebble,
mouse or drag to orbit the camera (third person, top-down-ish so cones read well); touch: stick plus buttons.

HUD: top bar (logo, mission, time to dawn, stars, pause, sound, language), visibility meter, objective list,
toasts, title, palace map with mission stars, mission result, ending at dawn on the Bosphorus.

EXTRAS: crickets, fountain trickle, footsteps on stone and carpet, guard murmurs (synthesised blips, no voice),
a soft ney-and-kanun night music that tenses up when you are seen, all synthesised (CC0 one-shots from
asset-forge allowed).
```

The shared rules in `_sablonlar/arena-round6-common.md` are appended to this prompt.
