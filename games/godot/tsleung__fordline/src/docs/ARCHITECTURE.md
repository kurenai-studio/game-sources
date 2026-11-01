# Fordline — architecture

How the game grows without breaking: a core engine, a few modules that add
whole mechanics, and packs of content. Every module and pack is a two-way
door: take it out and everything else plays exactly as before. The suite
checks that against recorded battles on every run.

This is the design, written before the code moves. The migration at the
end says how the code gets here, one reversible step at a time.

## The rules

1. **The core engine plays the first game.** The campaign and the
   open-field quick battles of both eras need no module.
2. **Dormant rules are core; whole mechanics are modules.** A rule that
   data switches on stays in the core and costs nothing when off: a unit
   trait (line infantry forms square), a schedule (forces arriving at an
   hour), a number (pace, how much a rout costs), a field bigger than the
   screen (the camera follows). A mechanic that brings its own state,
   orders, AI behaviour and things on screen is a module: fortifications
   today, the command layer for collaborative generals next.
3. **Packs are data.** Scenarios, maps and eras live in packs: constants
   that name kinds, map kinds and modules by id and hold no functions.
4. **One writer, and modules return effects.** Only the battle's step
   changes battle state. A module's sim hooks are pure: given a read-only
   view of the battle and the module's own state, they return the module's
   next state and a list of effects (wound these men, blast this place,
   raise this force, emit this event), which the battle applies through its
   own functions.
5. **Fail when the battle is built, never silently.** A pack whose module
   is not loaded; a kind, map kind or scenario key nothing provides; a kind
   whose role no commander handles; two modules claiming one order or event
   type: each is an error when the battle is built. An order of an unknown
   type is an error when given. The suite builds every scenario.
6. **A hook is added when a module needs it**, with a test showing the core
   unchanged.
7. **One clock.** The battle advances in steps of `Battle.STEP` everywhere:
   on screen, in the suite and in the balance studies. A game measured at
   one step and played at another is a different game; see Migration.

## The layers

```
  packs     campaign · medieval · pike_shot · sieges · gettysburg · waterloo
                │          │          │          │          │          │
  modules       ·          ·          ·   fortifications    ·          ·
                          (command, air, naval, supply … later)
                │          │          │          │          │          │
  core      battle · regiment · kinds · combat · terrain · ai · seats
            · layers · screen · hud
```

Dependencies point down only. The core never names a module. A module uses
the core and the modules it lists. A pack names everything by id.

## The core

The battle and its step, regiments, kinds, combat, morale, flags and
resolve; the terrain queries; seeded maps (rivers, fords, bridges, hills,
woods, roads) and hand-drawn ones (ridges, towns, streams); the AI
commander; the campaign; rally, barrage and forced march; and the screen:
tap, the arrow drag, pause, speed, the HUD.

**Kinds are data.** A kind is an id ("pikes", "line"), its stats, a role
(foot, shot, archers, horse, guns, general), traits (`square`,
`bayonet`) and a look (soldiers in a block; later, a crew on a hull). The
AI and combat read roles and traits, never ids, so a pack can add a kind
with no code, and a role nothing handles fails at build time. Nothing to
convert: no campaign is saved between sessions today, only stars and the
best score.

**Seats and the commander loop.** One pure loop runs a battle: each seat (a
commander over some of a side's regiments) is asked for orders at its
interval, the orders are stamped with the step they belong to, and the
battle steps. The screen, the suite and the balance studies all use this
loop, so what is measured is what is played. A quick battle has two seats,
you and the enemy AI; a division on its own command is a third;
collaborative generals are more. Because orders are plain values stamped
with their step, a battle is its scenario, its seed and its order log:
enough to replay it, attach it to a bug report, or one day send it between
players.

**Each side has a home and its own abilities.** A side's home edge is
data, not "the bottom of the map", so a landing comes from the sea and a
strike from its own rear. Each side has its own abilities and cooldowns,
so an AI or an allied seat can call a barrage.

**Layers.** The core keeps a list of map layers, each a thing that draws
over the ground and can be switched on and off. With none registered, the
switch is hidden. Ground height, anti-air coverage and supply lines are
layers that modules add.

Dormant until data asks for them:

- **Formation shape.** A regiment is in line or in square. Kinds with the
  `square` trait form square against horse; the geometry (width, depth,
  reach, slots) reads the shape, so nothing outside the regiment needs to
  know.
- **Arrivals.** A scenario may list forces that come on by road at an hour.
- **Orders from above.** A regiment may carry a division, objectives and an
  hour before which it holds; the AI reads them, and they are empty in every
  quick battle.
- **Flights.** Everything fired is one thing in flight: arrows, shot,
  cannonballs, barrage shells. A flight has today's values (source, target
  regiment or place, duration, damage, shock, whether pace scales it) and
  an `ext` slot where a module keeps its own (homing, what can engage it, a
  landing ring). Guns may fire at a place rather than a regiment;
  fortifications uses that to batter gates.
- **The camera and the clock.** The field pans and zooms, with a minimap,
  only when it is bigger than the screen. The clock shows an hour of the
  day only when the scenario gives a starting hour.
- **Rule numbers**: `pace`, `rout_scale`, `flag_drain`, `dusk_time`,
  `deadline`, `deadline_flags`, `veterancy`.

**Dice.** The simulation's random numbers come from the battle's generator
and nothing else draws on it: the scatter of arrows on screen is seeded
from the flight, not the battle. Each module gets its own generator,
seeded from the battle's seed and the module's id, so adding a module to a
pack never reshuffles another's dice.

## Modules

A module is a folder, `modules/<id>/`, whose `module.gd` extends `Module`,
listed once in `modules/registry.gd`. Today there is one; the rest are
designed and wait for a pack that needs them:

| Module | Adds | Needs |
|---|---|---|
| `fortifications` | castles as a map kind: walls, gates, the moat; ramming, bombarding, the garrison | — |
| `command` (next) | sending divisions off on their own command, allied generals, dispatches | — |
| `air` (later) | drones and missiles, interceptors and anti-air, jamming, aircraft on missions; see Air below | — |
| `naval` (later) | ships as units on the water, coasts and shallows, landings, fire from the sea; see Navies below | — |
| `supply` (later) | supply lines from depots; out of supply, reloads and nerve suffer | — |

## The module contract

```gdscript
class_name Module
extends RefCounted
## A whole mechanic the core does not have. Every hook has a default that
## does nothing, so a module fills in only what it needs.

var id := ""
var requires: Array[String] = []       # other modules, by id
var map_kinds: Array[String] = []      # map kinds it can build ("fortress")
var spec_keys: Array[String] = []      # scenario keys it owns
var orders: Array[String] = []         # order types, named "<id>.<type>"
var events: Array[String] = []         # event types, named the same way
var intro := ""                        # one line, shown the first time a player meets it
```

Each hook below exists because fortifications or command needs it, except
`in_flight`, `layers` and `actions`, which air adds. Each runs at the place
in the step the code runs today.

**Building a battle**

| Hook | Purpose |
|---|---|
| `make_map(kind, rng) -> Terrain` | build a map kind it provides (the castle's ground, walls and flags) |
| `make_state(spec) -> Variant` | its own starting state, kept at `battle.ext[id]` (the gates' strength) |

A map a module builds carries `TerrainFeature`s that the core terrain
queries ask, given the battle so a feature can read its module's state (a
gate that is down no longer walls). Each query says how features combine:
height takes the highest, cover and speed the lowest, blocking and walls
any. The core's terrain view, briefing preview and minimap all draw
features, so a castle shows everywhere without them knowing it is a
castle. A map with no features answers from the core alone, as it does
now.

**The step** (pure: each takes the module's state and a read-only view of
the battle, and returns the next state and effects)

| Hook | Where | Purpose |
|---|---|---|
| `apply_order(state, view, order)` | orders | an order type it owns ("fortifications.bombard") |
| `after_melee(state, view, dt)` | between melee and fatigue | ramming |
| `in_flight(state, view, dt)` | after flights move, before any lands | interception, drones steering (air) |
| `on_landed(state, view, hit)` | when a flight lands | gate damage |

The effects are a short fixed list the battle knows how to apply:
`wound`, `blast`, `morale`, `raise` (a force arrives), `order`, `launch`
(a flight), `event`. A module that needs a new kind of effect is adding a
hook (rule 6).

**The AI** (the core commander calls these for each regiment, in registry
order, before the regiment's own role)

| Hook | Purpose |
|---|---|
| `ai_context(view, team, ctx) -> ctx` | change what the whole side wants (a garrison forms across its gate) |
| `ai_order(view, team, r, ctx) -> Variant` | an order, `Module.PASS` (let the role decide) or `Module.HOLD` (no order) |

**The screen** (the screen calls these; the battle never does)

| Hook | Purpose |
|---|---|
| `on_tap(screen, at) -> bool` | a tap on empty field it takes (a gate; a flag, for command) |
| `react(screen, event)` | effects and notices for its events |
| `draw_marks(view, battle)` | marks over the regiments (a gate's damage; a division's own-command diamond) |
| `layers() -> Array[Layer]` | map layers it adds (anti-air coverage, air) |
| `actions(screen) -> Array` | buttons for the bottom bar's one module slot (aim a strike, air) |
| `describe(battle, r) -> String` | its words in the selection readout |

**Per-regiment state.** A module keeps what it knows about a regiment in its
own state, keyed by regiment id (which gate a battery is battering), not in
fields on `Regiment`. `Regiment` holds only core data.

**The screen stays calm.** Modules get places, not the whole screen: marks
over the field, layers behind a switch, one slot in the bottom bar, a line
in the selection readout, notices in the toast column. A module's `intro`
is shown once, the first time a player meets it, so the core game still
needs almost no introduction.

## Commanders

A commander turns a battle into orders for one seat. The core AI is one,
and it runs every module's AI hooks before its own roles, so a commander
built on it serves every module without knowing they exist. If a module
ever needs something only a commander can do (a strategy module asking an
AI in the army's seat for a plan), it will list the methods it needs, and
every commander in a seat it governs is checked when the battle is built,
with a default (the historical plan) so nobody has to write one. That is
designed, not built: no module needs it yet.

## Packs

```gdscript
const PACK := {
	"id": "sieges", "name": "Sieges", "menu": "quick",
	"modules": ["fortifications"],
	"scenarios": [STORM, LAST_KEEP, BREACH],
}
```

Packs are listed in `packs/registry.gd` (a web build cannot scan folders).
`menu` says where a pack's scenarios appear: the campaign, quick battle by
era, or grand battles. A scenario's keys are read through one checked
accessor, so a misspelt or unowned key is an error naming it, and its map
kind must be a core one or one its modules provide. If a pack's module is
not loaded, the pack is left out of the menus and the suite says so.

## Staying stable

- **Recorded battles.** The suite fights fixed battles through the one
  commander loop: the campaign on three seeds, every quick scenario, the
  sieges, and Gettysburg and Waterloo through the whole day. It compares
  each winner, time, losses and flags with the recording for the platform
  it runs on (`tests/golden-macos.txt`, `tests/golden-linux.txt`). A
  battle is deterministic on one platform, but the maths library's last
  bits differ between platforms, and the knife edge grows them into a
  different battle: on 1 November 2026, 21 of 44 battles came out
  differently on CI's Linux than on macOS. So each platform keeps its own
  recording, and the studies, which measure many battles, are what holds
  across platforms, including the web build players run. A change that moves any of them fails until the
  file is updated in the same commit, so every balance change is a visible,
  deliberate diff.
- **Modules don't leak.** A pack that lists a module whose data its
  scenarios don't use must fight exactly as the core does; and the packs
  that use several modules are recorded together, so modules are tested in
  company.
- **Every scenario is built** with its pack's modules and every commander.
- **A time budget.** The suite times the step on the largest battle and
  fails past a budget, worst step as well as average, so a phone stays
  smooth at 4×.
- **Each module tests itself** in `modules/<id>/test.gd`.

## Migration

Each step is one commit that keeps every check the same and can be
reverted alone. A step that must move recorded battles says so, and moves
them once, deliberately.

Steps 1 and 2 are done (1 November 2026).

1. **One clock and one loop.** The commander loop and seats in the core,
   stepping at `Battle.STEP`; the screen, the suite and the balance studies
   all use it; orders logged by step; cosmetic random numbers off the
   battle's generator. This changes outcomes: today the tests step at 1/15
   s and the game at 1/30, and 6 of the 15 campaign battles change winner
   between them. DESIGN.md's tables are measured again.
2. **Record the battles** through that loop, on the CI platform, and add the
   comparison and the time budget to the suite.
3. **Kinds as data**, with roles, traits and looks; doctrine keyed by kind
   id; the build-time check that every role is handled.
4. **The dormant rules, one commit each**: formation shape; one list of
   flights; each side's home and abilities; held flags written one way
   (`own_flags` a list in every spec); unknown orders an error; the checked
   spec accessor.
5. **Packs**: scenarios and eras into pack files and the registry; the
   menus and briefings read packs.
6. **The contract**: `Module`, effects, `TerrainFeature`, layers, the hook
   calls, the build-time checks.
7. **Fortifications** out of the core: its map kind and features, gate
   state in its own state, bombard as fire at a place, ramming and gate
   damage as effects, the garrison behind the AI hooks, the gate tap and
   marks behind the screen hooks. Its own generator moves the siege
   recordings once.
8. **Command** as a module: sending a division to a flag creates a seat in
   the core loop; the module is the tap, the marks and the words.

After that, new mechanics start as modules. The steps touch the same core
files, so they run one after another in one session.

## Solving the game: search and learning

The studies need many battles, and a stronger AI needs to try plans before
it commits to one. What that costs today, and what would make it cheaper.

**Today.** A quick battle is 3,000–6,000 steps of a third to one
millisecond: one to five seconds of computer time. A plan search of forty
plans on three dice takes about six minutes on one core; ten cores run ten.
That is enough for searching plans and for studies of a few thousand
battles. Reinforcement learning, which wants hundreds of thousands of
battles at least, would take days per experiment.

**What makes it cheaper, most value for least cost first:**

1. **Decisions as plans, at a person's pace.** The plan search already
   shows the useful space: each block to a flag, held back, or on the
   line, decided every so often rather than every 0.75 s. That shrinks
   what a search or a learner must choose from to a few options per block,
   and it is also how a person plays. Cost: low; the AI already executes
   objectives.
2. **Soldiers as a view, not the simulation.** Today each soldier is
   simulated and his place matters: which men fall first, what a cannonball
   hits. Simulating each regiment as a whole (men as a count, a blast's
   toll from how much of the block it covers) would cut about a quarter of
   each step, take away much of the knife edge (one dropped order flipping
   a battle), and leave a state of a few numbers per regiment that a
   search or a learner can read. The screen still draws every soldier.
   Cost: moderate, and every recorded battle moves once.
3. **A faster core.** Porting the battle step to native code would make it
   tens of times faster. The recorded battles would be its specification:
   the port is done when they all come out the same. Cost: high; worth it
   only if learning becomes the plan.

**The recommendation.** No learning yet. Build a planner that searches
plans during the battle (re-plan every twenty seconds, try a handful of
plans a short way ahead from the current state, pick the best) once soldiers
are a view and a battle can be copied cheaply. It is the stronger AI, the
honest ceiling for balance, and the teacher a learner would need later.

## Air: a worked example

How drones, missiles and interceptors would enter, to check the contract
before it is built.

**Air is things in flight between ground units, never units in the air.**
Every drone, missile, shell and interceptor is fired from the ground at a
regiment or a place, flies, and lands or is stopped. Nothing in the air
holds a flag, and no aircraft fight each other. Every decision stays a
ground decision, and the one-tap orders stay enough:

- where your anti-air stands, since its reach is a ring on the map;
- how close your blocks stand, since massing is both firepower and a
  target;
- what to fire at what, and when to spend the expensive round;
- whether to be somewhere else when the countdown ends.

**Weapons are values, not special cases.** Every weapon sits on a few
shared axes: speed, homing, area, whether it can be shot down, warning
time, cost. The counters follow from the numbers.

| In flight | Fired by | Speed and warning | Can be stopped by | Notes |
|---|---|---|---|---|
| shell | a gun, at a place, on or off the field | arc, seconds; landing ring | close-in guns and lasers, in range, at a rate | counter-battery finds the gun |
| mortar bomb | a mortar team, over cover | high arc, a few seconds; ring | the same | fires over houses and hills |
| railgun round | a railgun, straight | almost instant; no warning | nothing | long reload; the precise, narrow end |
| FPV drone | a drone team, at a regiment | slow (horse pace), homes | any block's guns close in, anti-air guns, interceptor drones; jamming | fibre-optic ones ignore jamming but keep within a ring of their team |
| loitering munition | a drone team, at an area | slow; waits for a target | the same | a decoy draws it off |
| one-way drone, cruise missile | off the field, from its side's edge | minutes in history, seconds in play; ring | interceptor drones, guns, missiles | comes in waves, with decoys |
| ballistic or hypersonic | off the field | fast; a second's warning or none | only the long-range tier, at a low rate | effectively unstoppable without that tier |

**Interception is a rate, not a roll.** An interceptor has a ring, the
tags it can engage, the fastest thing it can catch, how many flights it can
engage at once, how long each one takes, and a magazine. A flight it can
engage inside its ring is stopped once it has been engaged for that long.
Too many at once and the rest get through. So failure is "I can't kill
those fast enough", never "I can't kill that"; saturation and decoys work
by themselves, and the dice stay out of it, which Fordline's own luck
study argues for. A
slower interceptor catches a faster flight only while it is still coming
in, which puts pickets forward.

**Jamming is a zone.** Radio drones that fly into an enemy jammer's ring
drift and drop; your own falter in your own ring. Fibre drones are immune
and stay on their leash.

**Aircraft are flights that come back.** A drone or a missile is spent; a
sortie returns and rearms. Aircraft are a side's wings, each a resource
given a mission, as in Supreme Commander, where you direct the effort and
never fly the dogfight:

- **Strike** a place: the wing flies in from its side's edge, drops its
  munitions (flights of their own) and turns for home.
- **Cover** an area: the wing becomes a moving interceptor ring that
  engages only aircraft, at its rate.
- **Escort** a strike: its cover ring travels with it.

Who owns the sky is then whose rings are where, and it reads as a layer on
the map: denied, contested, open. Over open sky a strike arrives quickly
and surely; through enemy rings each ring spends its rate on the sortie,
which may be turned back or lost, or must drop from outside the rings with
weapons that can themselves be shot down. Winning the air is a ground
decision: push your anti-air forward, or kill theirs to open the sky. A
grand battle can simply give the sky to one side as a scenario value: then
the other side's arrivals come slower by day, as German reserves did in
Normandy.

**Effects lean to nerve.** A strike costs more morale and stamina than men,
so air shapes where blocks will stand rather than deleting them: air that
removes a garrison would make a siege a walk.

**What it takes:** from the core, flights with an `ext` slot, each side's
home edge and abilities, layers, and kinds as data (drone teams, anti-air,
jammers, mortars, railguns); from the contract, `in_flight` to steer,
intercept and fly sorties, `on_landed`, its own state for magazines, wings
and jammers, `ai_order` for launchers and anti-air, `draw_marks` for
countdowns, `layers` for coverage and the sky, `actions` and `on_tap` to aim
a strike or set a wing's mission.

**Left out on purpose:**
- Aircraft you steer, and dogfights. A wing is given a mission, not flown.
- Seeing and being seen. The map shows everything; reconnaissance drones
  and fog of war are not planned.
- Cost exchange as an economy. It is the scoreboard, not the fun. At
  most, magazines carry over between campaign battles.
- Real flight times. Warning is scaled to seconds of play: a grand battle's
  hour is 78 seconds.

## Navies: a worked example

**If it holds space, it is a unit; if it only passes through, it is a
flight.** Aircraft pass through, so they are flights. Ships hold water, so
they are units, commanded with the same one-tap orders as a regiment: tap
to select, tap to move, drag an arrow to stand and face, tap an enemy to
fire on it.

**Where they belong.** Battles where land and sea meet: a landing, a river
with gunboats, guns supporting the shore. A battle of fleets alone would be
a different game and is left out. First candidates in eras the game
already has: Vicksburg (river gunboats, with the rifles) and Quebec in 1759
(the landing below the cliffs and the battle on the Plains of Abraham, with
line infantry).

**What a ship is.** A kind with a domain: water instead of land. It moves
only on water, it has a lot of strength and turns slowly, and its look
comes from its kind: a hull under its crew. Its weapons are flights like
everyone's: long guns that fire at a place for the shore; on later ships,
an escort's anti-air ring that moves with it, and a carrier's wings.

**The sea is three kinds of water and nothing else:** deep (any ship),
shallows (boats and landing craft only; a visible lighter colour) and the
coast. No currents, tides or wind (DESIGN.md, pillar 6).

**Landings are arrivals by sea.** A force comes in landing craft along a
sea lane from its side's home edge, and becomes regiments on the beach it
reaches; craft hit on the way lose men, as anything does.

**What it takes:** from the core, as dormant rules, a domain on regiments
(land unless a kind says water) that the terrain's blocking and speed
answer for, the hull look, and the grid router, which moves from
fortifications to the core once a second user (the sea) needs it; from the
contract, `make_map` for coastlines and shallows, `ai_order` for ships
(keep station, support the shore), `react` for their effects. Landings use
the core's arrivals with a sea lane. No new hook.
