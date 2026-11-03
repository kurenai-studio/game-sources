# Arena round 5, game 1: Kapadokya Balonu (hot-air balloon wind puzzle) — built by Claude Opus 5.5

```text
Build a single-file browser game (one index.html with inline CSS and JS) using Three.js r170 loaded as an ES
module from https://cdn.jsdelivr.net/npm/three@0.170.0/ (import map; addons from examples/jsm/).
A 3D flight-navigation game called "Kapadokya Balonu" about piloting a hot-air balloon over Cappadocia at
sunrise. Do not ask questions, build it end to end.

WORLD: a low-poly Cappadocia valley: fairy chimneys (peribacaları) with dark caps, cave-house windows carved in
the rock, vineyards and apricot orchards, a winding river, a village with a mosque and a launch field. Dozens of
other balloons drift in the sky (instanced, varied stripe colours). Dawn sky gradient that turns from violet to
gold as the flight goes on; long soft shadows. Flat-shaded, warm sandstone palette, one accent colour (#E8590C
balloon orange).

CORE MECHANIC: you never steer sideways. You only control the burner (heat: climb) and the parachute vent
(cool: descend). The wind changes direction and speed with altitude in clearly visible layers (drifting mist
streaks and other balloons show each layer). To travel, pick the layer that blows where you want to go. Real
feel: the envelope heats and cools with lag, so altitude changes are slow and must be planned; fuel (propane)
is limited; the basket can touch treetops and chimneys (damage, passenger fright).

GOALS: each flight has targets: fly low over a marked spot, drop a marker on a cross, photograph a landmark
from a given height, pick up a passenger on a hilltop, and land softly on the trailer field before fuel runs out
(landing score for speed and distance). Show a wind compass with the layers stacked by altitude (live readout),
an altimeter, a vario (climb rate), fuel and envelope temperature.

CONTENT: 12 flights in 3 regions (Göreme, Uçhisar, Ihlara-like canyon), each with its own wind table and
weather (calm dawn, gusty, morning fog, thermal bubbles at noon). Stars per flight for goals met, fuel left and
landing softness. Flights are data in one table; every flight must be completable by the bot.

INTERACTION: hold Space / mouse / touch button for the burner, hold V or the vent button to descend; camera
orbit with drag, zoom with wheel or pinch, C cycles chase / basket / map view, F takes the photo, D drops the
marker.

HUD: top bar (logo, flight, goals, fuel, stars, pause, sound, language), altitude / wind ladder on the side,
toasts, title, region map with flight stars, flight result with a landing report, ending with a group photo.

EXTRAS: burner roar and flame light on the envelope, birds, dawn call to prayer far away as a soft pad (no real
recording), bağlama-like plucked melody, all synthesised (CC0 one-shots from asset-forge allowed).
```

The shared rules in `_sablonlar/arena-round5-common.md` are appended to this prompt.
