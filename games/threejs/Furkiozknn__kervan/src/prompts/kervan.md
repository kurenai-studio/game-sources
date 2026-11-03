# Arena round 3, game 1: Kervan (Silk Road trade strategy) — built by Claude Opus 5.5

```text
Build a single-file browser game (one index.html with inline CSS and JS) using Three.js r170 loaded as an ES
module from https://cdn.jsdelivr.net/npm/three@0.170.0/ (import map; addons from examples/jsm if needed).
A 3D trade-strategy game called "Kervan" (Turkish for caravan). Do not ask questions, build it end to end.

WORLD: a low-poly tabletop map of a stylised Anatolian Silk Road at golden hour, built entirely in code, no
external models or textures: rolling steppe, a mountain pass, a river with a stone bridge, a salt lake, a desert
edge. Seven cities, each with its own silhouette (domes and minarets, a walled citadel, a harbour with ships, a
cave town in fairy chimneys), linked by roads; a caravanserai with a courtyard and arched gate on every long
road. Clean toy-like clay look, flat shading, soft shadows, one accent colour (#B45309 saffron) for selection
and UI highlights.

LIFE: your caravans (a lead merchant on a horse and a line of camels with bundles) walk the roads in real time,
stop at caravanserais at night, and their bundles visibly change with the cargo. Rival AI caravans trade too and
move prices. Every city produces and consumes goods (silk, spices, salt, copper, carpets, figs, ceramics) with
supply and demand that drift and react to what everyone sells. Seasons change the map (snow closes the mountain
pass in winter, spring floods slow the river crossing), bandits appear on roads you neglect, a plague or a
festival changes a city's demand for a while. Day and night cycle, lanterns in the caravanserais.

GAME RULES: start with one caravan of 3 camels and 200 akçe. Buy low, sell high, pay camel upkeep, hire
guards against bandits, buy more camels and more caravans, and build or upgrade caravanserais (they give
protection, cheaper upkeep and a little income). Each city has a reputation with you that unlocks better prices
and contracts ("deliver 20 carpets to the harbour before the first snow"). Goal: reach 10,000 akçe and 3
caravanserais before the end of year 5; a score and star rating for faster wins; an endless mode afterwards.
Prices, goods and contracts are data, readable in one table in the code. The economy must be balanced so that
a sensible player can win and a careless one goes broke.

INTERACTION: click a caravan to select it, click a city to send it (it follows the roads; show the route and
ETA), click a city to open its market (buy/sell sliders with live price impact). Drag to pan, wheel/pinch to
zoom, a speed control (1x, 2x, 4x) and pause.

HUD: top bar (logo, year and season, akçe, caravans, reputation summary, speed, pause, sound, language), a city
panel (goods table with prices and arrows, contracts), a caravan panel (cargo, camels, guards, route), a ledger
with a profit chart, toasts for events, title, year summary, victory and bankruptcy screens.

EXTRAS: camel bells and footsteps, a bazaar murmur in cities, wind on the steppe, a ney-and-frame-drum music
loop, all synthesised.
```

The shared rules in `_sablonlar/arena-round3-common.md` are appended to this prompt (structure, performance,
self-test, verification, delivery).
