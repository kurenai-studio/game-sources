# Simulation core

Status: **first slice built and tested**, headless, no UI. Code is in `game/scripts/sim/`, authored content in `game/resources/sim/`, tests in `game/tests/`. Conventions for working on it are in `.github/copilot-instructions.md`.

## Decisions

| Decision | Choice | Notes |
|---|---|---|
| Ending | **None.** Open-ended, with chapter milestones (Camp → Hamlet → Village) as soft endings | Milestones are not built yet. |
| Pace | **1 game day = 20 real minutes**, one tunable constant (`SimConfig.real_seconds_per_game_day`) | A tick is one game hour (50 real seconds). Decision frequency comes from accumulated resources, not the clock, so a long coding session is never punished. |
| Villager autonomy | **Coarse**: each villager has an activity (rest, gather, forage, build, socialize, wander, away, and hunt once the group has chosen to hunt); the sim does no path-finding, the view animates it | Traits only bias choices. |
| Persistence | The whole world is one `Resource` saved to `user://`, with a last-seen timestamp | Loading runs script references in the file; only load saves this game wrote. |
| Events | Authored data (`EventDef` + conditions + effects), never code | Anything that can happen is an event template; the sim only decides when. |
| Failure | **Nothing can go wrong.** Decisions wait forever; being away is never punished; nobody starves, dies or leaves unasked, and there is no timer (the group does eat, but running out of food only changes what villagers do) | Directly from the MVP concept. |

## How it works

- `Simulation.advance_ticks(n)` steps the world exactly; `advance_real_time(now)` turns wall-clock time into ticks, which is also offline catch-up. Catching up for N ticks is guaranteed identical to ticking N times (tested). Catch-up is capped (`max_catch_up_ticks`, default one game year) so a months-long absence cannot stall start-up.
- Each tick: villagers work or sleep → construction progresses (and damaged buildings are mended once their time is up) → the group eats → plants grow → the weather's spell ends if its time is up → the camp's room is recounted → scheduled events fire (dropped if their `requires` no longer hold) → at most one new event is rolled from the eligible templates → the era gate is checked.
- An event with choices opens a **pending decision**; it waits until the player resolves it. Choices can require resources, buildings or flags, and a decision never opens if none of its choices are available. The same decision never stacks up, and there is a cap (`max_pending_decisions`) and a cooldown between openings. If the world moves past a pending decision (the fire was lit another way), the sim **withdraws** it; waiting for resources or a later day never does.
- **Consequences** are scheduled events (`SCHEDULE_EVENT`) or flags that later events require, so choices ripple forward ("Theo found a seed → you planted it → it flowered → a rare butterfly came").
- All randomness uses one seeded RNG saved with the world, so a seed plus actions reproduces a world exactly.

## The first slice (content)

Re-themed as the **Cave Age** (see [ages](ages.md)), with the turn into the **Settled Age**.

- 5 eras (Cave, Settled, Bronze, Iron, Classical), 3 starting villagers drawn at random per world from pools of 24 names, 4 traits and 3 looks (always at least one curious one), 10 buildings and about 540 events (see `ages.md` for the Bronze Age's: the turn, the building fork, 24 milestone roads, 23 story decisions and 27 one-line moments, and for the Iron Age's: the turn, the building fork, 27 milestone roads, 27 story decisions and 30 one-line moments, and for the Classical Age's: the turn, 19 milestone roads, 21 story decisions and 34 one-line moments), 1 plant, 7 kinds of weather. Of the events, 17 are the Cave Age milestones, the fire story, the exploration chain and rain; 11 are the Settled Age's six milestones (their routes); 22 are the small story decisions that fill the Cave Age (see `ages.md`, "between the milestones") and 24 those of the Settled Age; 6 are growth and food decisions (arrivals, a crowded camp, a lean spring; see `ages.md`, "Population and food"); 12 are weather (see "Seasons and weather" below); 28 are Cave Age one-line journal moments, 23 the Settled Age's and 8 mark the seasons.
- Cave Age buildings: Lookout, Drying Rack, Knapping Spot. Settled Age buildings: Field, Hut (they only appear once settled). Bronze Age buildings: Smithy, Trading Post (a fork, like the Hut and the Field), Quay. Iron Age buildings: Bloomery, Granary (a fork again). The Classical Age adds no building: its milestones put pieces on the world and fold older ones into them.
- **The world starts without fire.** A curious villager may find a burning tree, or an industrious one may strike a spark; passing on either lights the fire anyway via embers. Nothing can be built until there is fire.
- The chain: fire → build the Lookout → a curious villager asks to scout the western forest → they return with a seed → you plant it → it flowers → a rare butterfly visits.
- **The Settled Age is gated** (`EraSystem`, `EraDef`): it needs all six milestones (Fire, Stone Tools, Enough to Eat, Shared Stories, A Bigger Group, Unexpected Garden; each has more than one route, see `ages.md`) plus **8640 ticks (5 real days)** in the Cave Age. The player is shown none of this. When the gate opens, the age-turn event asks *how* to settle (by the field, or where the herds winter), and either answer advances the era.
- Era-gated content uses `ERA_AT_LEAST` conditions on the era's `order`; `ERA_DAYS_AT_LEAST` counts days since the current age began, so an age's own pacing does not depend on how long the last one took; `ADVANCE_ERA` moves forward only. The Settled Age's gate out is its six milestones (staged by `SETTLED_DAY`) plus 8640 ticks; the turn event *The metal's road* asks how to work the green stone and either answer opens the Bronze Age. The Bronze Age's gate out is its six milestones (staged by `BRONZE_DAY`) plus 8640 ticks; the turn event *A harder fire* asks how to work the dark stone and either answer opens the Iron Age. The Iron Age has no gate out yet (the game is open-ended); its six milestones are staged by `IRON_DAY` and are the gate of the Classical Age, whose turn event *A seat at the table* asks how the town takes its place among cities and either answer opens it. The Classical Age's six milestones are staged by `CLASSICAL_DAY`; it has no gate out (a Medieval Age is only a direction, `ages.md`, "Medieval: the direction"). **Representative villagers:** each age has a profile on its `EraDef` (a ceiling on arrivals, and what a villager eats and brings in), so a villager stands for the settlement's people instead of counting them; `SimConfig.max_villagers` (14) is only the global safety net (`ages.md`, "How many people the strip shows").
- Names and numbers are placeholders from the MVP doc's examples. It plays end to end for every tested seed, for players who accept everything and for players who pass on things first.

## Pacing findings (bot answering every decision immediately)

Measured with `tools/sim_timeline.gd` at 20 real minutes per day:

- Fire is found at about **18 real minutes**, and after that the first decisions follow.
- With the milestones **staged** (one table, `UNLOCK_DAY` in `tools/build_sim_content.gd`: Stone Tools from game day 18, Enough to Eat 54, Shared Stories 108, A Bigger Group 162, the seed chain 216; 72 game days per real day), a bot that answers instantly earns them at roughly **6.5 h**, **18 h**, **36 h**, **56 h** and **73 h** of real time, then the Settled Age opens at 5 days. The buildings that would grant a milestone early are staged too.
- The spread is right and the gaps are now filled: the small story decisions and journal moments (`ages.md`, "between the milestones") leave a bot that answers at once with about **29 questions** across the five days, never more than about **9 real hours** apart, and a journal line roughly every 20 real minutes. `tools/sim_timeline.gd` prints the questions, the longest wait and the stock every 30 days.
- **The economy** was far too generous (thousands of wood by day 400). It is now leaner: `gather_rate` 0.06, building costs 8-14 wood, building output about a tenth of before, and a **comfortable stock** (`SimConfig.comfortable_stock`, 40): once a store reaches it villagers rarely gather that resource and buildings stop adding to it. Stock now hovers and ends the age at roughly 100-200 of each, with several choices that spend it (frost, shelter, river, feast, the traveller). A test keeps it under 300.
- The earlier slice-only findings (kept for the record): by day 30 the old stockpile was hundreds of wood and food with nothing to spend on, because there were no resource sinks and only three buildings.

The target from the pacing discussion is roughly one decision per 1-2 hours of working, about 4-6 on a normal workday.

## Seasons and weather (issue #8)

The rules are gameplay.md P14; this is how they are built.

- **The calendar** is `SimConfig`: `days_per_season` (20) and `first_season` (a new world starts in spring), read through `season_at(tick)` and `day_of_season(tick)`; `Season` names the four. `SimCondition.SEASON_IS` tests it. A decision asked in its season is not withdrawn when the season turns (`is_decision_stale` treats the season, the weather and "a building weather can reach" as passing conditions, like a stock or a day).
- **Weather is state**: `WorldState.weather` (a `WeatherDef` id, or `&""` for clear), `weather_started_tick`, `weather_until_tick`; old saves load clear. A `WeatherDef` (`resources/sim/weathers/`) has a span in days, a `food_multiplier`, a `wood_multiplier` and a `then` (a tornado leaves wreckage). `SET_WEATHER` starts one (`amount` 0 draws the span from `Simulation.rng`); `WeatherSystem` ends it and starts what follows; `Simulation.food_multiplier()` and `wood_multiplier()` scale foraging, hunting, wood cutting and the food and wood a building makes. `weather_changed` is the signal the view could use; it reads the world instead.
- **Damage**: `BuildingDef.tags` say what weather can reach (`river`: the Field and the Drying Rack; `dry`: the same; `exposed`: the Lookout, the Hut and the Rack); `BuildingState.damaged` is saved. `DAMAGE_BUILDING` breaks one undamaged completed building that has a tag (an empty key: any), picked with `Simulation.rng`, and writes the journal line; `REPAIR_BUILDING` mends them. `ConstructionSystem` gives a damaged building `SimConfig.damaged_output` (half) and mends it after `self_repair_days` (6). `HAS_BUILDING_TAG` and `HAS_DAMAGED_BUILDING` are the conditions; housing is not affected.
- **Content** (`tools/build_sim_content.gd`, `_weather_events`): rain (spring, autumn; scenery); the **flood** only while it rains: `river_over_its_banks` (a fork) or `river_over_the_reeds` (no building to reach: food slower), or a calm line (`bank_holds`, `ledge_stays_dry`) when an earlier answer guards; a summer **storm** fork (`thunder_storm`) or `storm_passes`; a summer **drought** fork (`dry_summer`), `dry_summer_quiet`, or `well_keeps_green` when there is a well; an autumn **tornado** fork in the Settled Age only (`tornado`, rare, can break any building; the funnel lasts a day and the wreckage slows food for 4-6 more); winter snowfall; and two quiet lines per season. Each fork is damage plus two ways on: set it right now with wood (`_mend_now`), or take the other road and let it mend (`_mend_later`: some food or wood meanwhile). `FLOOD_CHANCE`, `STORM_CHANCE`, `DROUGHT_CHANCE` and `TORNADO_CHANCE` are the pacing knobs; they come to about two forks a year across all kinds (measured with `tools/sim_timeline.gd`). A fork is not asked while the first answer is unaffordable (P13), so a poor group has the weather without the question.
- **Story that names a season waits for it** (`SEASON_IS`): the first hard frost, the first snow, the snowmelt river (Cave) and the flood (Settled), a wet summer, midsummer, a lean spring, before winter, calves in the spring, a cold night, and the frost and geese lines. Settled ones count days into the age, so one that misses its season waits for the next (at most 60 game days).
- **The tide and the river forks** (issue #9; `docs/ages.md` V13). The tide is `SimConfig.tide_at(tick)`, a pure function of the tick (no state, no saving, catch-up is identical), tested through `SimCondition.TIDE_LOW`, which `is_decision_stale` treats as passing. **Cave:** "The sea has gone out" (`low_tide_stones` / `low_tide_log`, day 215, asked at low tide once a crossing is laid): shellfish (+5 food) or driftwood (+5 wood). **Settled:** "A boat for the river" (day 160 into the age): a dugout (6 wood, +6 food) or a reed raft (+3 food); "Fish on the turn of the tide" (`fish_on_the_turn_*`, day 218, low tide, crossing): a stone weir (6 wood, +8 food) or baskets (+4 food). Quiet lines for each answer and for low tide itself. Tests: `test_sim_tide.gd`.
- **Tests**: `test_sim_weather.gd` (calendar, spells, multipliers, damage and self-repair, saves, catch-up, the forks, the season gating, rarity) and `test_view_weather.gd`.

## Not built yet

- Settlement stages and the "A Beginning" milestone.
- Relationships and friendship events; more traits and skills; the 15–25 event templates from the MVP.
- Wildlife, visitors, expeditions to other places; the settlement/wilderness balance.
- The view and the play-loop UI (the bulb, decision, journal and "while you were away" panels) are built on top of the sim without it knowing; see `ages.md` (V1-V7).

## Open questions

- How long should the first arc really take, and how many decisions per workday feels right? (Playtest with the timeline tool, then tune `SimConfig` and costs.)
- Should the player be able to see or influence villager activity, or is it purely ambient?
- What is the first milestone's trigger (building count, population, a specific building)?
