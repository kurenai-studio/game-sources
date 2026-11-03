# Arena round 4, game 3: Karagöz (shadow-puppet light puzzle) — built by Claude Opus 5.5

```text
Build a single-file browser game (one index.html with inline CSS and JS) using Three.js r170 loaded as an ES
module from https://cdn.jsdelivr.net/npm/three@0.170.0/ (import map; addons from examples/jsm/).
A 3D puzzle game called "Karagöz" about the traditional Turkish shadow theatre. Do not ask questions, build it
end to end.

WORLD: a small wooden shadow-theatre booth in a dim Ottoman coffee house at night. In front: a white cloth screen
(perde) lit from behind by an oil lamp. Behind the screen, on a little stage, the player places and moves
coloured translucent leather puppet pieces and props (Karagöz, Hacivat, a house, a tree, a boat, a donkey, a
djinn ...). Their cast shadows fall on the screen and are seen from the audience side. Two views: the backstage
(where you work) and the audience view (the result). Audience silhouettes in the foreground react with laughs and
applause. Warm lamp light, flat-shaded low-poly coffee house, one accent colour (#B91C1C puppet red).

PUZZLE MECHANIC: every scene shows a target picture outlined on the screen (a story moment, for example
"Hacivat greets Karagöz in front of the house"). Place, rotate and slide puppets on rails and move or dim lamps so
the coloured shadows match the target. Distance to the screen changes shadow size and sharpness; two lamps make two
shadows; coloured leather mixes colours on the cloth. Match is measured by rendering the screen to a small
offscreen target and comparing it with the target mask (show a live % match). A scene is solved at >= 90 %.

STORY: 24 scenes in 4 acts (mukaddime, muhavere, fasıl, bitiş), each act a classic short story with short witty
TR / EN dialogue lines between Karagöz and Hacivat that play when a scene is solved (text boxes, no voice).
New pieces and lamp types unlock per act; later scenes need moving puppets on a timed track (the shadow must hit
the target at the right moment). Stars per scene for few moves and no hints; hints cost a star. Scenes are data
in one table in the code (pieces, rails, lamps, target masks generated from a reference arrangement, so every
scene is provably solvable).

INTERACTION: drag pieces on their rails, scroll or two-finger twist to rotate, click a lamp to move or dim it, Tab
toggles backstage / audience view, Z undo, H hint, R reset scene. Works with mouse, touch and keyboard (arrow
keys move the selected piece).

HUD: top bar (logo, act and scene, match %, moves, stars, hint, pause, sound, language), piece tray, toasts,
title, act map with scene stars, scene result with the dialogue, ending.

EXTRAS: lamp flicker, cloth rustle, the traditional göstermelik intro, audience laughs, a ney-and-tef music loop,
all synthesised (CC0 one-shots from asset-forge allowed).
```

The shared rules in `_sablonlar/arena-round4-common.md` are appended to this prompt.
