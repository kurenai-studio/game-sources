# The background — a city under attack

Level 1 runs four minutes or more, and for all four the player is looking at the same 208 px column.
The background has to carry that without ever being the reason a bullet was missed. It is last in
the priority order of [`05-legibility-rules.md`](05-legibility-rules.md) on purpose: it has the most
pixels and the least to say.

This page fixes what it is made of, how fast each part moves and what is allowed to happen in it. It
does not fix tile art, because at this resolution the background is built from a small set of
repeating pieces and the pieces are worth nothing without the rules that place them.

## Four layers, and the numbers that keep them apart

Everything is in pixels at 480x270 and in pixels per second. Scroll is downward, so the world moves
down the screen while the ship flies up it.

| Layer | Speed | Tile | Colours | Holds |
|---|---|---|---|---|
| 0 — sky | 0 | full screen, one gradient | B1, B2, N1 | the void behind everything |
| 1 — far | 6 px/s | 96 x 96 | B2, B3, N2, N3 | skyline, hills, the orbital limb later in the campaign |
| 2 — mid | 14 px/s | 64 x 64 | N2, N3, B2, T1, W1 | blocks of city, roads, water |
| 3 — near | 30 px/s | 48 x 48 | N1, N2, N3 | rooftops, the layer the ship flies over |

**The near layer is the plainest and it is the darkest.** That inverts the instinct — the closest
thing should be the most detailed — and it is R8 doing its job: detail belongs where it moves
slowly. A rooftop crossing the screen in nine seconds with texture on it is a rooftop the player's
eye keeps checking.

**Nothing scrolls at 40 px/s or faster.** The slowest enemy in the level moves at roughly that, and
R9 says a background layer that reaches gameplay speed reads as gameplay whatever colour it is. The
30 px/s of layer 3 leaves a clear margin, and it is the number to change first if the level ever
feels static — never by raising it past the enemy.

**Adjacent areas differ by at most two ramp steps** (R7). In practice: a wall is N2, the roof on it
is N3, and there is no N1 next to either. The contrast the eye is offered inside the background is
always smaller than the contrast between the background and anything that kills.

## Level 1 in four sections

The fourteen-beat sequence of `../planning/04-campaign-and-levels.md` sits on four background
sections. Each has its own palette weighting, and the acceptance criterion of this phase — enemy
fire distinguishable from **every** background in the level — is checked once per section, on the
real build, not once on a representative screenshot.

| Section | Beats | Reads as | Weighted toward |
|---|---|---|---|
| A — outskirts | take-off, calm, first enemies | night, empty, low | B1, B2, N1 |
| B — the city | formations, new archetypes | dense blocks, lit windows | N2, N3, T1, with W1 embers |
| C — the burning district | escalation, the two carriers | the city on fire below | W1, W2 rising, N1 falling |
| D — above it all | rest, the boss | the fire behind and below, sky opening | B1, B2, N2 |

Section C is the dangerous one and it is dangerous by construction: it is the only place the
background is warm, and the explosions, the muzzle flashes and the pickups are warm too. Two
protections, both mechanical rather than remembered:

- **W2 is the ceiling for fire in the background** — `L*` 36.3, well under the 45 the palette
  allows and 22 points under W3, which is where a sprite's fire starts. Background fire is a glow;
  sprite fire is a flame. They never meet in the middle.
- **The burning is under the horizon.** Fire lives in layers 1 and 2 and never in layer 3, so it is
  always slow, always distant and never next to the ship.

Section D exists because the boss needs a quiet background and because four minutes of city is four
minutes of the same thing. It is also where the level gets its shape: the player climbs out of what
was burning.

## Ambient events

The invasion is told by things happening in the background, not by dialogue
(`../planning/04-campaign-and-levels.md`). Four events, and the same four rules apply to all of
them.

| Event | Layer | What it is |
|---|---|---|
| Human aircraft | 1 | a 9x5 silhouette crossing, N3 on B2, four seconds end to end |
| Ground defence | 2 | a 1 px N4 tracer rising three or four screen-heights away, fading before mid-screen |
| Distant explosion | 1 or 2 | a W1 to W2 bloom over 0.5 s, no outline, no W3 |
| Collapsing building | 2 | a tower losing its top over 1.5 s, ending 6 px shorter |

The rules, which are R10 made specific:

1. **Background-legal colours only.** Never W3, W4, F1 or N7 — those belong to things that are
   happening *to* the player.
2. **Never in the reserved band.** Hues 320-350 are enemy fire in every stage of the campaign, and
   an ambient event that borrowed them would teach the player to ignore magenta.
3. **Never in the middle third of the playfield**, horizontally — x 69 to 139 in playfield
   coordinates, where the player spends most of the level.
4. **At most one at a time**, and none at all while the boss is on screen. A background that is
   busy during the fight is a background competing with the tell.

## Destructible structures are not background

They use `structure-*` from [`02-sprite-sizes.md`](02-sprite-sizes.md), they are drawn from the
**gameplay** set in human metal, and they scroll with the near layer. That is the whole distinction
and it has to survive at a glance: if a building can be shot, it is made of the colours everything
shootable is made of, and if it cannot, it is made of the colours nothing shootable is made of. A
player who wastes half a magazine on scenery learned that rule the expensive way.

## How this gets checked

`palette/lint-art.py <png> background` on every tile as it is finished — a background tile that
reached for a gameplay colour is invisible until the level runs and something disappears behind it.
Then the section sweep of [`05-legibility-rules.md`](05-legibility-rules.md): a screenshot of each of
the four sections at peak density, greyscaled and squinted at. Bullets first, ship second, enemies
third. If the background survives instead, R7 was broken somewhere in that section.
