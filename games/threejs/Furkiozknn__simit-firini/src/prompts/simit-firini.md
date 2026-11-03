# Arena round 4, game 2: Simit Fırını (simit bakery tycoon) — built by Claude Sonnet 5.5

```text
Build a single-file browser game (one index.html with inline CSS and JS) using Three.js r170 loaded as an ES
module from https://cdn.jsdelivr.net/npm/three@0.170.0/ (import map; addons from examples/jsm/).
A 3D bakery-management game called "Simit Fırını" (simit bakery). Do not ask questions, build it end to end.

WORLD: a cut-away low-poly bakery on an old Istanbul street, seen from a tilted isometric camera: the dough table,
the wood-fired oven with a glowing mouth, the molasses and sesame trays, a shop window, and outside a sloped
cobbled street with tea houses, a ferry pier and a park. Warm toy-like look, flat shading, soft shadows, one
accent colour (#C2410C oven orange). Morning rush at dawn, slow noon, evening rush, night closing.

PRODUCTION CHAIN: flour + water -> knead dough -> shape rings -> dip in molasses -> roll in sesame -> bake ->
racks. Each step is a station staffed by workers (little instanced people) with speed and skill; the oven has
limited slots and burns simits if you leave them too long. Later products: poğaça, açma, çatal, pide with
their own recipes. Ingredients are bought from a supplier with fluctuating prices and arrive by van.

SALES: simit sellers (simitçi) carry trays on their heads to street spots (pier, school, park, office) and sell
by the hour; each spot has demand that follows the time of day and weather (rain = fewer buyers, cold = more
tea-house orders). Contracts from the tea houses and the school. Customers also buy in the shop.

GAME RULES: start with one oven, two workers and 300 lira. Each day: plan production, set prices, assign
simitçi to spots, upgrade stations, hire, buy a second oven, a delivery bike, a bigger shop. Wages and rent are
paid at night. Goal: become the most famous bakery of the street: reach 5,000 lira and a 4-star reputation by day
20; star rating, an endless mode afterwards. All recipes, prices and demand curves are data in one table;
balanced so a sensible player wins and a careless one goes bankrupt.

INTERACTION: click a station to see and upgrade it, drag workers between stations, click a street spot to assign
a simitçi, a planning panel for the day. Drag to pan, wheel/pinch to zoom, speed control (1x, 2x, 4x) and pause.

HUD: top bar (logo, day and clock, lira, reputation stars, weather, speed, pause, sound, language), station panel,
sales panel with a small chart, toasts, title, end-of-day summary, victory and bankruptcy screens.

EXTRAS: oven crackle, dough slaps, the simitçi's call, street chatter, rain, a cheerful clarinet-and-darbuka music
loop, all synthesised (CC0 one-shots from asset-forge allowed).
```

The shared rules in `_sablonlar/arena-round4-common.md` are appended to this prompt.
