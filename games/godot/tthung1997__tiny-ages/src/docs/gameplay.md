# Gameplay basics

Decided with the project owner. Everything numeric below is a target to tune, not a promise. The
simulation's current content (wood and food, three fixed villagers, the first slice's achievements) is
placeholder and does not yet follow these decisions; see "What this changes".

## Decisions

- **P1 The player's job is direction, not management.** Choices set where the group settles, what it
  learns and who it becomes. The player never manages resources or assigns work.
- **P2 Resources are context, not a number to watch.**
  - A choice shows what it needs. If the group cannot afford it yet, it reads as "we'll start when we
    have enough"; it waits and nothing fails.
  - Scarcity is told as story ("food is running low" in the journal) and can make a choice appear
    (hunt or forage). Exact stock lives in a details panel, never on the strip. The strip shows
    only a quiet **gauge** for wood and food: three pips (one lit is low, two fine, three plenty)
    and a small arrow while the stock is clearly rising or falling. No numbers, no rates.
  - Resources can also be hidden inputs to milestones (enough stone to learn knapping).
- **P3 Two rhythms of activity.** Something small every 10-20 real minutes (a speech bubble, a journal
  line, a visitor or an animal) and something meaningful every few hours (a decision). Away or not,
  there is always something to see when the player glances at the strip.
- **P4 Start with three villagers whose traits are random** (seeded, so a run is reproducible). Their
  names are not fixed; their traits shape which events they take part in and how those play out.
- **P5 The settlement can grow, and has limits that give, never break.** Villagers arrive through
  decisions while the camp has room (the age, its buildings and the group's answers set it) and the
  food to share. Everyone eats the same, but only foragers and hunters make food and they share the
  ground, so a bigger group has to spend more of its days on food; running short only moves what villagers do (more foraging, less wood and building), never
  hurts anyone. When the camp is full, a fork eases it: build out, or a family leaves to live
  elsewhere (nobody dies). Population is the clearest progress signal on a tiny strip. **A villager stands for the settlement's people; it is not a head count.** Each age has its own profile (a ceiling on arrivals, and what a villager eats and brings in), so later ages read as larger without drawing every person, and nobody already in the group is ever removed (docs/ages.md, "How many people the strip shows").
- **P6 Fire is found, not given.** The first age starts without fire: the cave is cold and dark at
  night. Finding and keeping fire is the first major milestone, reached in roughly the first hour.
- **P7 Achievements drive the ages.** One system: an achievement records something that happened,
  and some are major milestones. Unearned ones are hidden.
- **P8 Ages are gated by hidden requirements.** An age needs a set of milestones **and** a minimum
  time. The player is told neither in advance.
  - Milestones are real turning points between ages (fire, stone tools, farming, pottery, copper and
    bronze...), not every event.
  - A requirement can be met in more than one way, so choices shape the route (see `ages.md` G1).
  - The minimum time stops luck from rushing an age. It is measured in real time and is a few real
    days for the Cave Age (to tune).
  - Reaching an age is announced by a story beat; the player never sees a checklist.
- **P9 Time while the game is closed counts fully.** The world keeps living on the real clock, so
  closed or asleep is the same as running in the background: offline catch-up replays it. This is safe
  because decisions are the bottleneck: at most 3 queue up and then the world waits for the player, so
  being away can only run down the minimum-time clock and never skip content. Players who answer
  decisions often still progress faster, up to that floor. Rejected: counting only open time (stingy
  to casual players, mostly rewards leaving the game running) and a per-day cap on catch-up (a rule
  that makes progress harder to predict).
- **P10 Content budget.** About 25-30 questions for the five-day Cave Age (the buildings and milestones plus about 20 small story decisions; roughly 4-6 per workday), plus ambient lines and trait-driven variants
  (one authored event plays differently per villager). Visible consequences matter most: choices
  change buildings, props and clothing, so there is a reason to look.
- **P11 Light interaction.** Clicking a villager shows their name, traits and current thought. Resting
  the pointer on something in the world (a villager, a prop, a building, the fire, the river's life,
  a landmark) names it after a short pause: a small plate with the name only (a villager's role too),
  never on its own, no sound, and only for what is drawn, so the age gate stays hidden. The
  **Villagers** list in the menu shows the whole group at once: one row each with a full-body
  figure, name, traits and profession; picking a row opens that villager's panel.
- **P12 The strip shows almost nothing, always.** Permanently on screen there are only the wood and
  food gauges (P2), the bulb (when a decision waits), the journal book (with an unread dot), a
  small, quiet **gear** and a small **season glyph** (a sprout, a sun, a leaf or a snowflake: no
  number, no timer, no flashing; picking it opens Stores, which says "Late spring, rain" in
  words). Everything
  else is on demand: the gear (or a **right click on the strip**, as a shortcut) opens a short
  menu with the journal, **Villagers** (P11), **Achievements** (everything the group has earned, oldest
  first, each with an icon and the title it was earned under: only what is earned, no empty slots, no
  count or progress, since the age gate stays hidden; earning one stays quiet, the journal line is
  the moment), **Stores** (where the
  settlement is and the exact wood and food: the numbers P2 keeps off the
  strip), **Settings** (window mode, size, always on top, move to the next screen; remembered in
  its own file, separate from the save) and Quit. **Edit shortcuts** in Settings enables/disables
  and rebinds the window keys: **1/2/3** for Strip/Corner/Window and **-/+** (also `=` and
  numpad -/+) for size. Click a binding, then press a key (with optional modifiers); Esc cancels.
  Conflicts and navigation/developer keys are rejected with a message. Reset defaults restores
  all five bindings. Shortcuts work only while the game has keyboard focus, are on by default,
  and are saved with the window settings; disabling them leaves mouse controls and navigation
  intact. No counters, clocks or speed controls: time of
  day reads from the light, and time never pauses. The text overlay (day, stock, speed, the last
  journal line) and the dev keys (diagnostics, speed with `[ ]`, bot) are behind `--dev` (or `--hud`
  for the overlay alone), so they cannot block the desktop or tempt the player to watch numbers.
- **P13 A decision is a fork, not a favour.** (1) A decision is only asked while at least two of
  its answers can be picked right now (`EventDef.min_choices`, default 2); one answer is nothing to
  decide, so a question the group cannot afford is not asked at all. (2) There is no pass answer
  ("not now", "leave it"): ignoring the bulb is already "no" and costs nothing. Every answer does
  something, sets its own flag, and leads somewhere different, so the choice is *which direction*
  (build A or B, take this road or that), never "yes or no" to something free. (3) A cost may sit on
  an answer only when the other answer is not simply better. A decision already asked is never
  withdrawn because stock fell; it waits (P4). **Every decision follows this rule** (Cave and
  Settled): `test_decision_rules.gd` fails on a decision with fewer than two answers that each do
  something, or one that may be asked with one answer.
  A decision the world no longer has (removed in an update) is withdrawn from a loaded save instead of
  hanging there unanswerable. **Required things need a way that cannot be skipped**: a milestone
  decision's every answer gets there (one sooner, one slower or differently told), and a building is
  never the only road, so no sequence of choices blocks an age (tested over every order). A
  building decision with two buildings (Hut and Field) is a real fork: the one not chosen stays
  unbuilt, and its milestone has other routes.
  Stock no longer piles up: villagers barely gather what the group already has plenty of
  (`PLENTY_WEIGHT` 0.02, tested).
- **P14 Seasons and weather are forks, not punishments.** The year is four seasons of 20 game days
  (an 80-day year, about 27 real hours; `SimConfig.days_per_season`). Weather is random but seeded:
  each kind has a chance per tick that only opens in its season (or, for a flood, only while it
  rains) and a long cooldown, so a world replays the same and offline catch-up equals live play.
  Nothing is scheduled on a fixed day, and a given kind of fork comes about once a year at most.
  (1) **Harmful weather always touches both food and buildings**: a storm, drought, flood or
  tornado slows what the group brings in for a few days (a `WeatherDef` multiplier) and breaks a
  building it can reach, which then produces half until it is mended. Rain is scenery unless it
  causes a flood. (2) **Damage is a fork** (P13): set it right now with wood, or go another way
  (fish the pools, gather what fell, salvage) and let the villagers mend it by hand. Both answers
  do something; neither is "pass". (3) **Nothing waits on the player**: a spell and its slowdown
  end by themselves, and a damaged building is mended by the villagers after
  `SimConfig.self_repair_days` (6) whatever is answered. Nobody is hurt, nothing is lost for good
  and nothing flashes or sounds. (4) **An earlier answer can guard against it**: a raised bank, a
  stores ledge or a well turns the damaging fork into a calm journal line. (5) A story decision
  that names a season (a frost, the snowmelt, midsummer) waits for it. (6) What the player sees:
  the palette follows the season (with snow, blossom and leaves), **rain and snow are animated** (a
  storm and a flood reuse the rain), and the strip glyph says which season it is. **A drought and a
  tornado are drawn as nothing**: they show up only as their journal lines and decisions, and a
  broken building is told in the journal, not drawn. Art for them can come later.

## Safeguards for the gate

- **Fire cannot stall.** Both fire routes have a "not now" choice, and passing on either schedules the embers, which light the fire anyway (a little later). Tested for every seed.
- **Every age's requirements must be reachable.** `test_sim_gate.gd` plays from a cold start as a player who accepts everything and as one who passes on each question twice before accepting, and both must reach the next age. A player who refuses a milestone's decisions forever cannot progress; the decisions keep coming back.
- The gate is data (`EraDef.required_achievements`, `min_ticks_in_previous_era`, `turn_event`), and `ContentLibrary.validate()` rejects a gate that requires an achievement nothing grants.

## What this changes (still to do)

- **Done in the sim**: random seeded traits; no fire at the start, with the two fire routes and the embers fallback; achievements as the hidden gate with a minimum time; the age-turn event asks *how* to settle (field or herds), not whether; all six Cave → Settled milestones, each with more than one route; about 20 small story decisions and 25 ambient lines between the milestones; resource needs shown on choices; a leaner economy that hovers instead of piling up.
- **Still to do in the sim**: more trait-driven variants of one event; the answers do little beyond the journal and a flag, so later content should read those flags and change what is seen. The Settled Age's fill (24 story decisions, 23 ambient lines) is in; stores no longer pile up (P13).
- **View**: built: no fire glow or fire-pit piece until the fire is found, and a cave-mouth place to gather until then; clicking a villager shows their name, traits and thought (`ages.md` V9). Still to do: speech bubbles.
- **Open**: how many resources exist per age; whether the player can ever see a hint that something is still undiscovered. The Cave → Settled milestones are listed in `ages.md`.
