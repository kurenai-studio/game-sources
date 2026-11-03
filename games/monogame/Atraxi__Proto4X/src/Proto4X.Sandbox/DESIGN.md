# Sandbox Game Design — "Void Command" (working title)

A slim, space-skinned Age of Empires. Built in `Proto4X.Sandbox` to exercise
`MonoGameLibrary` under a real RTS workload. Deliberately small: one resource,
two unit types, one building, one enemy AI, one win condition.

## The loop

1. **Gather** — Miner ships fly to the nearest asteroid, mine for a few seconds,
   fly back to their station, deposit minerals. Fully automatic once built.
2. **Spend** — the station converts minerals into more Miners (economy) or
   Fighters (military), one at a time, on a build timer. A station can be given a
   **standing order** to keep making one kind indefinitely.
3. **Fight** — Fighters auto-engage the nearest enemy inside weapon range.
   Stations shoot back. The player directs Fighters with select + move orders.
4. **Win** — destroy the enemy station. Lose if yours dies.

That's the AoE skeleton — villagers, town centre, military, raze the enemy base —
with the 4X/factory ambitions of `Proto4X` proper deliberately left out.

## Controls

| Input | Effect |
|---|---|
| Left click | Select one of your units |
| Double click | Select every unit of that kind on the map |
| Left drag | Box-select your units |
| Shift + click/drag | Add to selection |
| Right click | Move order for everything selected (fans out into a ring), or set a **rally point** if a station is selected |
| `F` | Spawn a free fighter wave for every faction — load test only |
| `1` / `2` | Issue the selected unit's commands — see below |
| Shift + `1` / `2` | Set or clear a station's **standing order** for that ship |
| Arrow keys / `Z` `X` / scroll | Pan / rotate / zoom (engine `Camera`) |
| `Esc` | Quit |

Hotkeys are **per selection, not global**. What a key does depends on what you
have selected, exactly as in Age of Empires:

| Selected | `1` | `2` | Shift + the same key |
|---|---|---|---|
| Station | Queue a Miner (50) | Queue a Fighter (75) | Keep building that kind forever |
| Miner | Found a new station here (200 **and the miner**) | — | — |

Select several stations and they all queue, each charged separately. Select
several miners and press `1` and exactly one starts building, because the others
fail to afford it — the economy does the arbitration, so there are no
"who goes first" rules to write.

**Founding a station consumes the miner.** Expansion costs 200 minerals *and* a
worker, so it dips your income exactly when you commit and pays back only once
the new base is staffed. That is what makes expanding a decision rather than
something you do reflexively every time the mineral count crosses 200 — and it
gives the AI's expansion rules something real to be careful about, since the AI
plays the same mechanic.

Founding a station is also a movement decision: fly a miner to the asteroid field
you want worked, then build. A miner that arrives on a **player** order **waits
2.5 seconds** before giving itself a new job, so it's still where you put it when
you reach for the build key — without that pause it claimed the nearest rock and
turned around in the time it took to press `1`. The wait is a property of the
*order*, not the unit, so a miner running its own gather loop never pauses and
the economy runs at full speed.

New stations are drop-off points and shipyards immediately, so expanding is how
you scale mining. Set a station's rally point on an asteroid field and every
miner it builds goes straight to work there.

**Standing orders** (shift + a ship's hotkey) make a station re-queue that ship
whenever its queue runs dry, charged per ship as each one is queued rather than
up front. Hand-queued ships come first; the standing order picks up after them,
and simply waits when the minerals aren't there. Past the opening minutes the
interesting decision is *which* ship a base makes, not remembering to press the
key again every eight seconds. A station carrying one shows the ship it keeps
making below it, inside a broken ring — dashed rather than solid, because a solid
ring already means "progress" a few pixels further up.

## The map and the opponents

Three factions on a 6400×3600 map: you, and two AI factions that expand on their
own. Roughly 100 procedurally scattered asteroid fields, plus two guaranteed
fields next to each homeland so nobody starves on an unlucky seed.

**One miner per asteroid.** Claims are held as positions rather than entity
references, and every claim is gathered before any new one is handed out, so a
rock that's taken is invisible to the next miner looking for work. A miner
releases its rock while hauling, so nothing sits idle across the round trip.

The AI factions target their nearest *hostile* station rather than the player
specifically, so they will happily fight each other. Each new station they found
raises their miner target, which makes fleet growth super-linear — the point
being to generate real load without the player having to drive it.

**Stations repair themselves**, at 18/s against a fighter's 14 dps. One raider
achieves nothing; nine are a siege. Taking a station is meant to be a decision,
not an accumulation of pokes.

## The AI, in one place

The AI is spread over three systems, because each is scoped to a different
archetype query: `ExpansionAiSystem` (where the next station goes),
`EnemyProductionAiSystem` (what to spend on) and `EnemyFleetAiSystem` (where the
fighters go). The split is right; what it cost was answerability, since "why did
the enemy do that" meant reading three files and holding a dozen scattered
constants in your head. **Every rule and every number now lives in
`Game/AiDoctrine.cs`**, stated in prose and read by all three systems, so tuning
is one edit in one file.

It is a priority ladder — a faction takes the first rule that fires and ignores
the rest:

| # | Rule | Threshold |
|---|---|---|
| 1 | **Never lose the economy.** Below the miner floor, build miners out of any money, expansion fund included | 3 miners |
| 2 | **Defend.** A hostile ship near any of your stations recalls the whole fleet, overriding an attack already in flight | within 620 |
| 3 | **Expand whenever you can afford to.** Send the nearest spare miner to the frontier and spend it founding a base | 200 + 120 reserve, and >3 miners |
| 4 | **Staff the bases, then build a fleet.** Miners up to the target, everything above that on fighters | 5 miners/station, queue depth 2 |
| 5 | **Attack once massed.** Commit to a wave, break off when ground down | 8 fighters, +4 per extra station, cap 28 |

**Defence outranks attack**, and that ordering is the whole fix for factions
collapsing early. Without it the first faction to attack was also the first to
lose its undefended base, and a lost base means no production, so the game
decided itself in the first minute.

**Wave size scales with stations**, not miners. The threshold is really asking
"do I have enough surplus that leaving won't cost me a base", and both halves of
that scale with station count: more stations means more to defend *and* more
production to reach a bigger number. Scaling on miners would mean a richer
faction attacks *later*, which is backwards.

**There is no station cap, and the expansion fund is what makes that true.**
A faction saving for a station publishes the amount, and production won't spend
into it. Before that reservation existed, expansion only ever happened on income
that accumulated while every build queue was full — a side effect of queue depth
rather than a decision, so a faction with a wide economy would sink everything
into fighters and never found a second base.

**Expansion costs a miner**, exactly as it does for the player, which is why
rule 3 has a floor underneath it. Without one, a poor faction with two miners
could spend one on a base it then had no economy to staff.

**Expansion goes to the frontier, not the far corner.** Picking the asteroid
furthest from your own stations sounds like claiming the most ground and actually
means walking across the map into someone else's base. AI factions take the
*nearest* field that isn't already theirs, so territory grows outward in a ring.

**Minimum spacing, including against stations that don't exist yet.** A site must
be 900 from the faction's own stations *and* from any site one of its own miners
is already flying out to build, and 1100 from anyone else's — the player's
included. The second half of the first test is what actually stops clustering:
the AI dispatches a miner frames before the station exists, so checking only
against built stations let it found two bases on top of each other while the
first was still under construction. A faction runs one expansion at a time.

None of this binds the player, who may build anywhere, at any spacing. The
spacing rule is an AI competence floor, not a game rule; applied to the player it
would read as the UI refusing an order.

The frontier scan is a sweep over every asteroid against every station, so it
re-runs on a 0.75s cadence rather than every frame, and the cached answer is
re-checked against the spacing rules before anything acts on it.

## Instrumentation

A rolling frame-time graph sits in the top-right: one column per recent frame,
green under the 60fps budget, amber under 30fps, red over. An average FPS number
would hide the thing worth catching, which is the occasional long frame.

Known O(n²) sweeps, in the order they're expected to hurt: `SeparationSystem`
(every idle ship against every other, no early range rejection), then
`CombatSystem` (same shape, but range-limited). Both want a uniform spatial grid
when that day comes.

## No text, on purpose

The game renders **no text at all**, and this is a design constraint rather than an
engine limitation to be worked around. A game that is legible without words is a
better game once words are added, because text stops being the crutch that
explains mechanics the visuals failed to convey.

What that means in practice:

| Instead of | The game shows |
|---|---|
| "Miner — 50 minerals" | The miner's own sprite, in a slot, with a ring that fills as you approach 50 and closes when you can afford it |
| "Building: Fighter, 4s left" | A radial ring around the station, with the fighter's sprite above it |
| "3 queued" | Three pips under the station |
| "Press 1" | One pip under the slot; two pips for `2` |
| A unit list | A minimap of faction-coloured dots |

The rule of thumb: if a number is the answer, ask whether the player's actual
question was "how close am I" or "can I yet" — those have shapes, not digits.

The `Window.Title` line still carries raw counts, but it's now a debug readout
rather than the HUD. Victory and defeat are the last things still expressed in
words, and are the obvious next thing to design without them.

## Entity shapes

| Entity | Components |
|---|---|
| Miner | Position, Motion, MoveOrder, Faction, Health, Timer, Weapon(unarmed), Selectable, UnitType, Miner, Drawable |
| Fighter | Position, Motion, MoveOrder, Faction, Health, Weapon, Selectable, Drawable |
| Station | Position, Faction, Health, Timer, Weapon, Selectable, Station, Drawable |
| Asteroid | Position, Gatherable, Drawable |

## The one architectural decision that makes this possible

The engine currently offers **no way to learn an entity's id** — not from a chunk
index during iteration, and not from `GameWorld.AddEntity` (ids are assigned
later, inside `ProcessDeferredUpdates`). The previous sandbox build dodged this
with `const int PlayerEntityId = 0`, which obviously does not survive a game with
dozens of units.

So this design **never uses entity ids at all.** Everything that would normally
be an entity reference is instead either component state or a proximity query:

- **Selection** is a `bool` on a `Selectable` component, not a list of selected
  ids. Selecting and ordering become ordinary chunk iterations.
- **Targeting** is "nearest hostile in range", recomputed each frame, rather than
  a stored target id.
- **Miner ↔ asteroid ↔ station** links are nearest-position lookups against
  per-frame index snapshots, not references.
- **Production** pushes plain spawn *requests* onto a list that the game loop
  drains, so nothing needs the id of the ship it just built.

This turned out to be more ECS-idiomatic than an id-based design would have been,
so it is worth keeping even after the engine grows ids. See `ENGINE_REQUESTS.md`
for the gaps that forced it and the two that are still genuinely limiting.

## System order (per frame)

Index (asteroids, stations, fleet census) → player input (selection, orders,
build hotkeys) → expansion AI → miner AI → production AI → fleet AI → steering →
separation → movement integration → repair → combat → death → standing orders →
production. Then `Sandbox.OnUpdate` drains the spawn queue and updates the HUD.

Two orderings in there are load-bearing rather than incidental. Expansion runs
before production because production has to be told what the expansion fund is
before it decides what to spend. Repair runs before combat so healing applies to
last frame's damage and a station reduced to zero can't be topped back up before
`DeathSystem` sees it.

## Deliberately not in scope

Finite asteroids, building placement, multiple resources, unit collision/flocking,
fog of war, pathfinding around obstacles, more than one enemy, sound.
