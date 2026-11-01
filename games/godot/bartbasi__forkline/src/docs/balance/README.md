# Balance reports

Owner: balance-analyst. Reports are dated: `region1-2026-10-23.md`, `region1-2026-10-24.md`, and so on. Raw numbers are
in `raw/<date>/`, one JSON file per job, so every number in a report can be checked.

## How the bots work

Battles have no randomness (ARCHITECTURE 3.1), so a level plus the player's choices gives one
result. The bots search over the choices. Every random draw comes from a generator seeded from a
number printed in the report, so a run can be repeated.

A **strategy** is: which tower on which spot (any of the six towers, Bells and Bakeries included),
which upgrades and in what order, which tier 3 path, a targeting mode for each attacking tower,
which sockets get gates (as many as the level or Twist gives), when to call waves early, and
whether to buy during waves. The bot buys strictly in its order and waits when the next item costs
too much. It uses only the public `Battle` API (`place_tower`, `upgrade_tower`, `set_aim`,
`place_gate`, `start_next_wave`, `step`, `result`).

Six kinds of runs (exhaust came with the 2026-10-24 report, plain with the B1 bots):

- **spread**: random strategies in three styles, each played on Normal and on Relaxed.
  - casual: a tower on every spot, no upgrades, usually no gate, never calls early.
  - typical: most spots, some upgrades, a gate or none, never calls early.
  - skilled: any number of spots, any upgrades, targeting, early calls.
  Random strategies are worse than a thinking player. Read the rates as a floor, and use them to
  compare levels, not as a prediction of how people will do.
- **search**: a seeded search for good strategies. It starts from random ones, then copies the best
  with one to three small edits. Fitness is a win first, then star 2, then star 3, then lives left.
  `only=` limits the towers it may use. `only=solo:sling_post` is one attacking tower plus every
  Bell and Bakery the level offers, which is the "no super tower" search of RULES 12.6 (run at least
  2500 builds). Finding a three-star win proves one exists. Finding none does not prove there is
  none, so the reports give how many builds were tried.
- **recipes**: a dozen plain recipes a new player might follow, such as "a Sling Post on every
  spot, then one upgrade each". Nothing in them is random. These sixteen recipes are the region 1
  recipes of the 2026-10-23 and 2026-10-24 reports and use only Sling Posts and Catapults.
- **plain**: the plain mixed recipe of RULES 12.6, exactly as written there (`Bot.plain_recipe`). It
  ranks the spots by road seen within 2.5 tiles, puts one Bakery on the spot with the most
  neighboring spots (when it has 2 or more), one Bell on the third spot (the fourth if the Bakery
  has the third), and gives the other spots the level's attacking towers in turn: Sling Post,
  Catapult, Longbow, Firework (only on levels whose waves bring flyers, or a boss that flies or
  releases flyers). It builds everything, then upgrades everything to tier 2 (Bakery last each
  time), and from region 2 on takes every attacker to tier 3 on its first path. It is played once
  for every gate placement that seals no entrance (none included), on Normal and on Relaxed. Best
  placement is the win with the most lives, else the loss that clears the most waves. The result
  also holds the wave sizes (a Puffball counts as itself plus its Puffs) and the largest wave.
  The region comes from the level id (`r2_l3` is region 2). `compare_old=1` plays the old region 1
  recipe too and lists any difference. On region 1 it finds none.
- **exhaust**: every static build of at most N towers (`max_towers=`), with every spot choice, upgrade
  depth, tier 3 path, purchase order, aim, gate choice, buying during waves or not, and early calls
  off or on. It runs in shards (`shard=K shards=N`). A miss here is a proof for that family of builds,
  not a sample. Used on 1-3, where the star 3 limits the tower count.

**Twists.** `twist=1` on any mode plays the level with its Twist (`level.twist_effects`, passed to
`Battle.create`). A banned tower is not offered to the bot, the gates in hand are what the Twist
leaves, and a Twist's fixed gates are already placed. Twists have no stars, so the search only
asks for a win, then lives. The bots read the level's own Twist, so a Twist that the sim refuses
stops the run with exit code 2.

**Added for the 2026-10-25 campaign pass.**

- `mode=need`: no plays. Works out the flyer cost and the walker cost of a level (count times lives, bosses included) and
  which lone attackers RULES 12.6 says need a search. A tower that cannot hit flyers needs none when the flyers cost 6 lives
  or more; the Firework Tower needs none when the walkers do.
- `stop_dry=N` on a search: stop when N builds are tried and none has won (RULES 12.6: 2500 of the 6000). The result says
  `stopped_dry`. `run_pass_post.sh` plays a dry search in full when its partner won something.
- `mode=replay from=FILE,FILE pick=best_win|three_star_best|top|all`: plays strategies saved in search results again, on the level
  as it is now. It takes every what-if the other modes take (`level_file=`, `towers=`, `enemies=`, `stat=`, `tweak=`,
  `twist=1`, `relaxed=1`) and `max_tier=N` (no tower above tier N). `from=plain` plays the plain recipe at every gate
  placement. Each row has the saved result next to the new one, lives lost by creature type (`leaks`, and `leaks_wave` by the
  wave the creature came from), kills, and for every flying boss its health a quarter, a half and three quarters of the
  way along its line and how it ended. A cheap first screen for any what-if: no search is needed.
- `mode=plain max_tier=N`: the plain recipe with no tower above tier N.
- `Bot.play(..., watch)`: a play that records events. It only reads, so a watched play gives the same result as an unwatched one.
- `run_special.sh` parts: 1 (every level watched, random play under every Twist, tier caps on 3-4 and 3-5), 2 (the saved
  champions of 3-4 to 3-6 watched), 3 (any-tower searches with the banned tower left out, for 3-4 and 4-2: the plain any-tower
  search misses builds that avoid a tower), 4 (longer Twist searches), 5 (the 3-4 champions at tiers 3, 2 and 1).
  `run_whatif_b3.sh` plays star 3 what-ifs on the failing levels (2500 build screens), and with `CHECKS=1` the 6000 build checks
  of the rules a report recommends. A 2500 build screen can miss (3-2 "at most 5 towers" in the 2026-10-25 report).
  Do not overwrite a script while a copy of it is running: bash reads it as it goes.
- `run_pass.sh` now follows RULES 12.6 as revised by G2 (two lone searches of 6000 builds per attacker that needs one,
  stopping at 2500 when dry), takes `SEED_SHIFT`, and can run as several workers on one folder (a lock folder per job).
  `run_pass_post.sh` does what needs the first jobs: dry pairs in full, determinism again in a new process, timing.
  `run_special.sh` has the extra jobs of the 2026-10-25 report (who costs the lives, the Moon Moth, Dusk Moths, random play
  under every Twist). `summary.gd pass=1` prints every table, special ones included.

Two more tools: `benchmark.gd` times each tick, and `run.gd mode=det` plays the same things twice
(and once with a save and load in the middle of a wave) and checks the results match.

**Added for the 2026-10-26 recheck (B4b, `campaign-2026-10-26.md`).** `mode=need` also reads the level's star 3: a tower it bans gets no lone
search ("it can never earn star 3"), and `all_three_only` is the `only=` value of the "All three stars" search (`any`, or the towers the ban
leaves). `run_pass.sh` takes that value from the need file and takes `SKIP_SOLO=1` (no lone searches, for a re-run of levels whose lone searches
stand). `run_pass_post.sh` adds two 6000 build searches (`ID_search_twist_deep_a/b.json`, bases 772000 and 774000) for a Twist whose 1500 build
search won nothing, and `summary.gd` reads them. Raw folder `raw/2026-10-26-b4b/`; seeds `SEED_SHIFT=200000`.

## Runs and the daily (task B2)

Reports: `runs-<date>.md`. Raw numbers: `raw/<date>-b2/`. The run bots drive `RunSession` (ARCHITECTURE 3.3) and
choose cards as well as towers. They are in `run_bot.gd`, and the runner is `runs.gd`.

A **run strategy** has three parts. A pick style: `towers` (a tower card first, then a perk, a spare gate, an economy
card, a risk card last), `economy` (economy first, but a tower card while the run has fewer than 2 kinds of tower), `risk`
(a risk card whenever one is offered) or `random` (any offered card). A build style: `wide` (new towers first, up to 4 plus
0.7 per wave started) or `tall` (upgrades first, 2 plus 1 per 4 waves). Early calls, off or on (from wave 4, when 6 or fewer
creatures are on the map). Together that is 16 named strategies (`towers_wide`, `towers_wide_early`, and so on). All of
them place gates on the socket that puts the most build spots within 2.5 tiles of the walking route, buy during waves as
gold comes in, and sell one tower only to make room for a tower type they have never built. Within a kind, the card is
chosen by the bot's own generator, seeded from the run seed and the strategy id. A tower is chosen by the lowest count over
weight (Sling Post 1.5, Catapult 1.0, Longbow 1.0, Firework 0.7, Bell 0.8 up to 2, Bakery 0.8 up to 1, each weight
changed by 0.7 to 1.3 times per bot). Spots are ranked by the road they see, as in the plain recipe (RULES 12.6).

A **random strategy** (`mode=search` and the extra tries of `mode=daily`) takes a random order of the five card kinds, a
random pace (`base` 2 to 6 towers plus `rate` 0.1 to 1.0 per wave) and a random early call habit. They are seeded from the
run seed, so the same seed always tries the same strategies in the same order.

Modes of `runs.gd`:

- `rates`: the 16 named strategies on run seeds `first` to `first + count - 1`, with `pool=base` (no unlocks: the 22 base
  cards) or `pool=all` (every card), and `relaxed=0` or `1`. Run `i` has the seed `i * 2654435761 mod 2^32`.
- `search`: `n` random strategies on each run seed. A seed is "winnable" when one of them wins.
- `daily`: day `n` is 2026-10-25 plus `n` days, with the seed YYYYMMDD, Normal, every card. The 16 named strategies play it,
  and a day none wins gets up to `extra` random strategies.
- `det`: for 50 seeds and 50 days, the map and waves built twice; the same play twice; a play saved and loaded again (through
  JSON text, the way a saved game is read) in the middle of a wave; and a play saved and loaded with a draft open, which
  must show the same offers. All must end in equal battle and run state. A second process must give the same chain hash.
- `risk`: one strategy plays seeds with a saved battle before each wave. Each saved wave is then played again with each
  risk card on it, on the same towers, and the peak creatures, lives lost and gold gained are recorded.
- `static`: the stacks (each top, middle and bottom that fit), and the creatures each pack wave spawns with each risk card.
- `cardvalue`: a random-picking strategy plays seeds; before each pick the state is saved, each of the 3 offered cards is taken in
  turn, and the run is played on to its end by the same strategy. A card's gain is its result less the average of the 3 offered.
- `deep`: `days=2026-11-11,... n=400` plays `n` random strategies on each named day (the days that were left unwon).
- `boss=ironshell` on `rates` and `daily` plays only the seeds (days) whose run has that boss (used to play Ironshell again after a
  stat change).
- `bakery_min=1`: a bot builds a Bakery that reaches only one other spot (the default is 2, as in the plain recipe).
- `tweak=strength_step:8,strength_start:100,start_gold:300,gates:1,tea_break:5` changes those `run.json` numbers, or the lives Tea
  Break gives, in memory only.

`run_runs.sh` is the job list and its seeds. `runs_summary.gd dir=PATH` prints the report's tables from the raw folder (`part=det|rates|search|length|waves|boss|maps|towers|cards|daily|risk|cardvalue|whatif|ironshell|lives`). Jobs added by hand are in `extra_jobs.txt` of the raw folder.
Length at 1x is the wave time plus 15 s for each build phase, the same rule as for levels (RULES 12.5).

## Second run and daily report (task B4)

Report: `runs-2026-10-25.md`. Raw numbers: `raw/2026-10-25-b4/`. Job list: `run_b4.sh` (phase A, then phase B from what A shows). The
tables come from `runs_summary.gd dir=PATH part=b4` (or one part: `bars`, `boss`, `fair`, `forced`, `cardbar`, `riskfair`,
`lengthb4`, `detb4`, `dailyb4`, `whatifb4`; `flags` prints the phase B job lines, with `OUTDIR` in place of the folder).

Bot changes (TUNING_RUNS 3.5). The numbers of the 2026-10-24 report need `bakery_from=0 perk_fit=0` to repeat on the same data.

- `bakery_from=W` (default 9): a bot builds no Bakery until W waves have started (G3's `FL_BAKERY_WAIT=9`). 0 is the B2 rule.
- `perk_fit=1` (default): a bot passes on a sidegrade perk whose cost falls on the tier 3 path it will take (its path is fixed by its
  seeded tastes): Volley with Giant Bow, Twin Pebbles with Stone Sling, Long Fuse with Skyrocket, Frost Chime with Night Bell, Spice Rack
  with Grand Oven. If every offered card is such a perk, it takes one anyway. `perk_fit=0` picks blind, as in B2.
- `boss_aim=1`: every attacking tower aims at Strong when the boss wave starts (a what-if, off in the report's bars).
- `mode=rates` also takes `stack=TOP,MIDDLE,BOTTOM` (every seed plays on that stack, its own packs and boss), `pack=ID` (the pack replaces the
  seed's pack of its band) and `stop=N` (the play ends when N waves have started and none is on the map; the row has `stopped`). A forced
  session is built through public calls only: `MapAssembler.build`, `Battle.create`, `RunSession.from_data` with no picks.
- `pool=plus:id,id` is the base cards and those unlock cards (what-ifs for the every-card gap). `perk_fit=2` passes on every sidegrade perk of the list.
- `run_b4.sh` phases: A (the main run), B (forced packs, what-ifs, from `runs_summary.gd part=flags`), C (all 42 stacks forced onto seeds 1 to 200,
  from `part=allstacks`), D (`perk_fit=2` with every card). Natural seeds give a stack 2 to 10 seeds and missed a wall, so run C after any segment change.
- `mode=search list=3,5,9` searches only those run seeds. `mode=det days=N day_from=K` plays N dailies from day K; a save that a load
  refuses is recorded in the row (`wave_refused`, `draft_refused`) and the play counts as a failure.

## Confirmation run and the largest wave (task B5)

Report: `runs-2026-10-27.md`. Raw numbers: `raw/2026-10-27-b5/`. The job lists are `run_b4.sh` (phases A, C, D, with the job files `jobs_A.txt`,
`jobs_C_extra.txt` and `jobs_D_extra.txt` in the raw folder; D is the whole-run check of the `mid_eye` stacks, `full_stack_*.json`) and `run_perf.sh`.
`runs_summary.gd ... part=b4` prints every table (it now includes `fullstacks` and `perf`). The bars table reports the best strategy and a
segment with their standard errors, and a card gain over +5 that is within one standard error of it is marked as noise (TUNING_RUNS 9.6).

The benchmark's largest wave (ARCHITECTURE 9.4, B5):

- `perf_cases.gd` lists how many creatures every wave spawns, with no play: campaign levels and Twists, and every run pack wave with each risk
  card (`jobs=N` also prints the `perf_peak.gd` job lines for the biggest run waves).
- `perf_peak.gd` finds the most crowded moment of one case. `level=ID [twist=1] seeds=S targets=K` or `run=PACK wave=N card=ID seeds=S`. A bot plays
  to the build phase before the target wave (a run takes the risk card for it, whether or not a draft offers it: `RunBot.play` has
  `force_risk`, `stop_before` and `return_state`), the wave starts and the next wave is called early as soon as the game allows. It keeps the play with
  the most live creatures at once and times its tail 5 times (median mean and 99th percentile, all ticks and ticks with 50 creatures or more).
  `save=DIR` writes that build phase as a saved game through `SaveStore`, reads it back through a new store, checks it, and copies
  `game_level.json` or `game_run.json` to DIR. `seed0=S seeds=1 wave=N` (and `first=I seeds=1 strategy=ID` for a run) plays one earlier result again,
  for timings on a quiet machine.
- `run_perf.sh` is the job list: every level and Twist, and the biggest run waves. `PREFIX=perf2 LEVEL_SEEDS=300 TARGETS=3 RUN_SEEDS=25` is the wider round.

## The expansion bots (task B6)

Report: `b6-trial-2026-10-28.md`. The bots now play regions 5 to 8 and the content tiers of runs and the daily. Nothing here changes a result at
tier 0 or on regions 1 to 4: the same command lines give the same files (see "Checking the bots after a change", and the report's section 1).

- **Distances by node.** `RoadMap.distances()` is indexed by node (ARCHITECTURE 14.3). `Bot.steps_left()` reads a creature's steps left to the base
  by node, and a walker on a bridge uses the node it is heading to. No bot reads a distance by cell any more.
- **`describe()`.** A map with a map feature (T, X, P, Q or a slide arrow) marks a gate with `*` (X is the bridge) and letters its spots A, C to F,
  H to O, R, S, U to W, Y, Z, then a to d, which are no grid character. A map with no feature is described as before (gate `X`, spots A to X).
- **The plain mixed recipe for regions 5 to 8** (RULES 12.6): spots ranked by road seen outside tunnels (a tunnel tile is not counted; the same count
  ranks the spots of the run bots and the weights of the random strategies); the Scarecrow on the fifth spot (the sixth when the Bakery has the fifth);
  attackers in turn Sling Post, Pumpkin Catapult, Longbow Loft, Bramble Cottage, Snow Fort, Firework Tower, Moth Lantern, with the Firework Tower and
  the Moth Lantern only on a level whose waves bring flyers; tier 3 on each attacker's first path (Wild Bramble, Big Snowball, Beacon Lantern); Bells,
  Scarecrows and Bakeries stay at tier 2.
- **Lone searches.** `only=solo:bramble_cottage` and `only=solo:snow_fort` work like the other four. The Scarecrow is a support tower, so every lone
  search holds it (the Bell and Bakery too), and it needs no search of its own. A tower that cannot hit flyers needs no search where flyers in the wave
  data cost 6 lives or more; the Firework Tower and the Moth Lantern need none where walkers cost 6 lives or more (`mode=need`, unchanged: it reads
  `hits_ground` and `hits_air`). A pulse tower takes no aim (`set_aim` refuses it), so its aim stays First in every strategy and two builds that differ
  only in it are not counted twice.
- **Run bots.** `opts["tier"]` (`runs.gd tier=N`) passes the content tier to `RunSession.start`, to a forced map and to `MapAssembler.plan`; the pool
  is `pool(counters, tier)` or `card_ids(tier)`. The four new towers have bot weights of their own (`NEW_WEIGHT`), drawn from a second generator, so a
  tier 0 run draws what it always did. The Scarecrow is support: capped at 2, built after the top two spots like the Bell, upgraded after the attackers.
- **Reports by tier.** `runs.gd tier=N` writes the same files as before, plus `"tier": N` when N is above 0. `runs_summary.gd dir=... tier=N` reads
  the bosses, packs and segments of that tier and below, so every bar of RULES 14.8 and 15 reads at that tier (job lines it prints carry `tier=N`).
  `run_b6.sh RT` is the job list for tiers 1 to 4.
- **Fixtures.** The real files hold no data for regions 5 to 8 yet. `fixture=1` (on `run.gd`, `runs.gd`, `benchmark.gd`, `perf_peak.gd`, `perf_cases.gd`,
  `summary.gd`, `runs_summary.gd`, `run_pass.sh`, `run_pass_post.sh`) plays on `tools/balance/fixtures.gd`: the sim engineer's test catalog
  (`tests/sim/fixtures/creature_fixtures.gd`: the real stats, the four towers and the creatures it holds) with five fixture levels, one for each map
  feature and one with all four (`r5_fx1` tunnel, `r6_fx1` bridge, `r7_fx1` ice slide, `r8_fx1` hollow stumps, `r8_fx2` all), and run data built from
  the real run files with four content tiers (tower cards and perks, a middle segment for each feature cut from a real one so every stack still fits,
  packs for the tier creatures and a band 6 pack for each boss). The fixtures are not tuned. When E5.1 to E8.1 land, the same tools run on the real
  data with no flag, and `fixtures.gd` stays only as the proof that the bots work.
- **The most crowded wave as a saved game.** `perf_peak.gd save=DIR` as in B5; for a run, `tier=N` plays a run of that tier and the saved file
  holds the tier (ARCHITECTURE 14.7), so the phone resumes it at the right tier.
- `run_b6.sh`: phases T0 (tier 0 jobs of the last reports, played again), LS (forced lone searches), RT (runs and the daily at tiers 1 to 4) and PK
  (the most crowded wave as a saved game). `run_pass.sh` has seven attacking towers and `FIXTURE=1`; its seed numbers for the first four are unchanged.

## The region 5 pass (task E5.2)

Report: `region5-2026-10-28.md`. Raw numbers: `raw/2026-10-28-e52/` and `raw/2026-10-28-e52-b4b/`. Job lists: `run_pass.sh` and `run_pass_post.sh` (`SEED_SHIFT=100000`, the seeds of the 2026-10-25 pass), `run_b4.sh A` with `TIER=1` or no `TIER` for the runs and the daily, `run_e52.sh` (`BR`: forced lone Bramble Cottage searches; `PK`: the most crowded new wave as a saved game, with `jobs_e52_PK_extra.txt` for tier 1 run packs) and `run_whatif_e52.sh` (star 3 rule what-ifs for the levels where the lone Sling Post earns three stars).

What-if options added to `runs.gd` (nothing changes unless one is set): `pool=minus:id,id` (the base cards without those), `towers=PATH` and `enemies=PATH` (other stat files), `data=DIR` (another copy of the whole data folder: packs, segments, levels, run files), `bramble_fit=1` (a bot puts a Bramble Cottage on the spot with the most road in the cottage's own reach), `bramble_cap=N` (a bot builds at most N cottages). The row's `bots` field records the last two. A tier 0 file made with the new tools equals the file made before (29 of 29 compared).

A `tweak=strength:N` on `run.gd` sets every wave of the level to strength N percent (waves are 100 to 135 in the levels), so it is not the level's `strength` number; do not use it to make a level a little harder.

## The regions 6 and 7 pass (tasks E6.2 and E7.2)

Report: `region6-7-2026-10-29.md`. Raw numbers: `raw/2026-10-29-e67/` (git-ignored). Measured on a clean `git archive` of 3fb2285 with the E5.3 patch applied (the Bramble Cottage numbers in `data/stats/towers.json`). Job lists: `run_pass.sh` and `run_pass_post.sh` (`SEED_SHIFT=100000`, `r6_l1` to `r7_l6`), `run_b4.sh A` with `TIER=2` and `TIER=3` for the runs and the daily, and `run_e67.sh` with a phase argument. `run_list.sh LIST N` plays any job list (a lock folder per job, so several copies can share a list). Do not overwrite a script while a copy of it runs: bash reads it as it goes (copy to a new name, as the E6.2 run did).

`run_e67.sh` phases: `WI` and `WI2` (6-4 wave variants and star 3 rules for 6-4 and 7-4, with the lone Sling Post searches again on the seeds that found three-star builds), `NB` (the any-tower search with the Bramble Cottage left out), `AIR` and `T0` (tiers 1 to 3 and tier 0 with `leaks=1`, with and without the anti-air floor), `NC` (the new tower cards out of the pool), `SC` (a late Scarecrow), `WT` (a stronger Scarecrow, a stronger Snow Fort), `PB` (Old Hayrick's packs with a stronger boss wave), `PW` (the first wave of two band 3 packs with fewer Pips and Scamps), `FP` (the new packs of tiers 2 and 3 forced), `ST` (the bridge stacks forced), `PK` (the most crowded new wave as a saved game).

Added (nothing changes unless its option is set; a default run equals the old one, checked on 800 rows at tier 2):

- `runs.gd mode=rates leaks=1`: every row also holds `leaks`, the lives lost by creature type over the run (the battle records events and the bot reads the `leaked` ones). `runs_summary.gd part=air` prints the anti-air table from the `air/` folder.
- `runs.gd air_floor=P` (`run_bot.gd`): when a bot would build an attacker that cannot hit flyers (Pumpkin Catapult, Longbow Loft, Bramble Cottage, Snow Fort) and the anti-air towers (Sling Post, Firework Tower, Moth Lantern) would be under P percent of its attackers after the build, it builds an anti-air tower instead (the one with the lowest count over weight). The first tower of each type is not touched. The default 0 is off.
- `runs.gd scarecrow_from=W`: a bot builds no Scarecrow until W waves have started (the Bakery's `bakery_from` for the Scarecrow). The default 0 is off.
- `runs.gd tweak=pack_strength:PACK_ID;N` (the strength of a band 6 pack's boss wave) and `tweak=pack_count:PACK_ID;WAVE;ENEMY;N` (the count of one creature's group in a pack wave, 1 to 3): in memory only.
- `tools/balance/variants/`: level files for what-ifs on 6-4's waves (`level_file=res://tools/balance/variants/r6_l4_v5.json`) and two copies of `towers.json` for the Scarecrow and Snow Fort what-ifs (`towers=res://tools/balance/variants/towers_scarecrow_plus10.json`). They are copies of the 3fb2285 data with the E5.3 cottage, so they go stale when the real files change.

## The regions 5 and 8 pass, and a first look at tier 4 (tasks E5.5 and E8.2)

Report: `region5-8-2026-10-30.md`. Raw numbers: `raw/2026-10-30-e58/` (git-ignored). Measured on a clean `git archive` of f31b761 with the working tree's `tools/balance/`. Job lists: `run_pass.sh` and `run_pass_post.sh` (`SEED_SHIFT=100000`, `r5_l1` to `r5_l6` and `r8_l1` to `r8_l6`; `r5_l5` and `r5_l6` with `EVALS=6000`) and `run_e58.sh PHASE N`.

**One default changed (the DM's call, E5.5, after TUNING_R67.md 1.3 and RULES 14.8).** From content tier 2 up, the run bots keep two habits of a thoughtful player: no Scarecrow before 9 waves have started (`scarecrow_from=9`) and anti-air towers at 55% or more of the attackers (`air_floor=55`). Tiers 0 and 1 are unchanged. A value on the command line wins, so `air_floor=0 scarecrow_from=0` turns both off. Both are written into the `bots` field of every tier 2 and above file (also when they are 0). `RunBot.habits(tier, args)` in `run_bot.gd` is the one place that sets them; `runs.gd` and `perf_peak.gd` call it. Checked: `runs.gd mode=rates first=1 count=3 leaks=1` at tiers 0, 1 and 2 on the old code (with the two options named at tier 2) and the new code (no options): the files are equal in every field but `seconds`. The tier 0 golden test is a game test and is the DM's.

`run_e58.sh` phases (each writes its list to `$OUT/jobs_e58_PHASE.txt` and plays it with `run_list.sh`; `DRY=1` only writes the list):

- `T4`: tier 4 runs on seeds 1 to 100 (two jobs of 50), Normal, base cards, `leaks=1`, in five folders: `runs_t4` (neither habit), `runs_t4_air55`, `runs_t4_sc9`, `runs_t4_both` (both habits: the new default), `runs_t4_nocards` (both habits, and the tower cards of tiers 2 to 4 and their perks out of the pool: `pool=minus:tower_scarecrow,big_hat,tower_snow_fort,packed_snow,tower_moth_lantern,bright_wick`, the second reading of RULES 14.8). Read a folder with `runs_summary.gd dir=... tier=4 part=bars` (or `boss`, `fair`, `forced`).
- `TP`: Glimmertoad's two packs forced onto seeds 1 to 100 in three folders, and the three new tier 4 packs of bands 3 to 5 forced with both habits.
- `TS`: Glimmertoad's boss waves at strength 50, the lowest a band 6 pack allows (`tweak=pack_strength:` below 50 makes `RunSession.start` refuse the pack).
- `PK`: the most crowded wave as a saved game on the 12 levels, three Twists and the tier 4 run packs (150 strategies a level this time).
- `HU`: two more any-tower searches of 6000 builds where the first of 3000 found no three-star build (5-3, 5-6, 8-5).
- `WI` and `WH`: 5-6 star 3 rules in memory (`tweak=star3:`), with the lone Sling Post on a fresh seed and on pass seed 835601; `WH` is the 6000 build hunt under "at most 5 towers".
- `NB`: the any-tower search with the Bramble Cottage left out, on 8-2, 8-3 and 8-4.
- `W86`: 8-6 wave what-ifs. The level files are `variants/r8_l6_NAME.json` (copies of f31b761's `r8_l6.json` with one wave edit; `level_file=res://tools/balance/variants/...`). `VARS` and `KINDS` (`plain`, `twist`, `any`, `solo`, `tsearch`, `tdeep`) choose the jobs. Variants: `b55`, `b60`, `b65`, `b80` (boss wave strength 55, 60, 65, 80; 50 as built), `c240` (wave 7 at 200 and wave 10 at 240; 160 and 195 as built), `c240b65`, `s25` and `s50` (waves 1 to 11 stronger by 25 and 50), `s25b55`. They go stale when `r8_l6.json` changes.

A job list file is rewritten each time a phase starts. A copy already running has read its list, so starting another phase with other `VARS` or `KINDS` is safe, but do not start the same phase twice with different arguments while the first still reads.

## The final pass of version 1 (task B7)

Report: `final-2026-10-30.md`. Raw numbers: `raw/2026-10-30-b7/` (git-ignored). Measured on a clean `git archive` of 5b960f2, with the bots of that commit: no bot, `run.gd`, `runs.gd` or `run_bot.gd` file changed for this pass. Nothing in the bots is new; what is new is how the jobs are queued.

- `run_b7.sh PHASE` writes the jobs of one phase and appends them to a queue file (`OUT=docs/balance/raw/2026-10-30-b7`, queue `$OUT/queue.txt`; `DRY=1` prints them). Phases: `NEED` (the need files of all 48 levels), `CA` (campaign, folder `a`: cheap jobs of all 48 levels on the seeds of the 2026-10-25 pass, `SEED_SHIFT=100000`, plus every long search of the levels changed since the last pass), `CB` (folder `b`: any-tower and lone searches of regions 1 to 4 and of the changed levels on new seeds, `SEED_SHIFT=300000`), `R` (the 16 strategies on run seeds 1 to 200 at tiers 0 to 4: base cards, Relaxed at tiers 0 and 4, every card, the second reading at tiers 2 to 4, the three newer tower cards one at a time at tier 4, same-seed checks), `D` (400 days at each tier), `POST` (a lone search played in full, Twist searches of 6000 builds, three-star hunts, determinism again in a new process), `RPOST` (the random search for run seeds no named strategy won), `X` (every card at tiers 1 to 3), `NB` (the Bramble Cottage watch item). It uses `run_pass.sh DRY=1` for the campaign seeds, so the seeds are those of every earlier pass. The run lines carry `SCRIPT=runs.gd`; a run line without it goes to `run.gd` and gives "unknown mode".
- `run_queue.sh QUEUEFILE CAP` plays a queue file that can grow while it runs. CAP is a limit on all `Godot_v` processes on the machine, not a worker count: one worker at a time checks the count and starts its process, so the limit holds exactly (two copies on two queue files in one folder share the limit and the lock). It never ends by itself: end it by the PID in `QUEUEFILE.sentinel`.
- Raw folders under `raw/2026-10-30-b7/`: `a` (campaign, seeds of the 2026-10-25 pass), `b` (campaign long searches, new seeds), `c` (the reproduction of B4b's region 3 files on its own seeds), `p` (replays: 8-6 under the Twist, the 3-5 lone build), `r/tN` (runs and dailies at tier N; `tN_nocards` is the second reading; `t4_out_*` and `t4_only_*` are the three newer tower cards one at a time), `x` (a third seed on the open levels, and the 3-5 star 3 what-ifs), `final` (what `assemble_b7.sh` builds). `queue*.txt` are the job queues as they ran.
- `assemble_b7.sh` builds `raw/2026-10-30-b7/final/`, the folder `summary.gd pass=1` reads for all 48 levels, and `reused.txt`, which names the source folder of every file copied from an earlier pass. `summary.gd` does not read the three-star hunts (`hunt/*_search_any_h0.json`, `_h1.json`): add them up from the files, as the report does.
- Checking the bots against an earlier pass: `jq -S 'del(.. | .seconds?, .digest?, .chain_hash?, .search_hash?)'` on both files, then compare. Digests and chain hashes differ from files made before S11 because the save format changed. The report's section 1 lists every comparison.
- `variants/r8_l6_*.json` were deleted: they were copies of the old 8-6 (strength 50, gap 1000), and the level changed in E8.3. `run_e58.sh W86` needs them; take them from `git show f31b761:tools/balance/variants/...` to play it. `variants/r6_l4_*.json` (copies of 6-4 before E6.3) and `variants/towers_*.json` (copies of the tower stats before E8.1) are stale in the same way; I left them, and the DM may delete them.

## Files

- `tools/balance/bot.gd`: strategies, the generator and mutator, the plain recipe, the player.
- `tools/balance/run.gd`: spread, search, recipes and determinism runs, with `tweak=` and `stat=`
  what-ifs that edit a level or tower numbers in memory only.
- `tools/balance/benchmark.gd`: time per tick and peak creatures (`twist=1` for a Twist).
- `tools/balance/compare_raw.gd`: compares two raw folders file by file (see "Checking the bots"
  below).
- `tools/balance/summary.gd`: turns the raw JSON into the report's markdown tables. `pass=1` prints the tables of
  a `run_pass.sh` run (plain, solo, search, spread, Twist, determinism and benchmark files, and the what-if
  files of `run_whatif_b1.sh`). Without it, the old region 1 tables.
- `tools/balance/run_bot.gd`, `runs.gd`, `runs_summary.gd`, `run_runs.sh`: the run and daily bots, runner, tables and job list (above).
- `tools/balance/run_b4.sh`: the job list and seeds of the B4 run report (raw folder `raw/2026-10-25-b4/`) and of B5 (`raw/2026-10-27-b5/`).
- `tools/balance/perf_cases.gd`, `perf_peak.gd`, `run_perf.sh`: the benchmark's largest wave (above).
- `tools/balance/fixtures.gd`, `run_b6.sh`: the fixtures and job lists of task B6 (above).
- `tools/balance/run_region1.sh`, `run_whatif.sh`, `run_stats.sh`: the exact job lists and seeds.
- `tools/balance/run_b7.sh`, `run_queue.sh`, `assemble_b7.sh`: the job lists, the queue runner and the folder builder of the final pass (above).
- `tools/balance/run_pass.sh`, `run_pass_post.sh`, `run_special.sh`, `run_whatif_b3.sh`: the job lists and seeds of the 2026-10-25
  campaign pass (raw folder `raw/2026-10-25-b3/`, report `campaign-2026-10-25.md`, `SEED_SHIFT=100000`).
- `tools/balance/run_pass.sh` and `run_whatif_b1.sh`: the job lists of the B1 pass (2026-10-24, raw folder
  `raw/2026-10-24-b1/`) and its star 3 what-ifs (other rules tried with `tweak=star3:...`, and a level file with
  Flitters added to 2-3).
- `tools/balance/run_rerun.sh` and `run_exhaust.sh`: the job lists and seeds of the 2026-10-24 report
  (fresh seeds, two single tower searches per tower, the exhaustive 1-3 check, longer searches).
- `run.gd` also takes `level_file=PATH`, `towers=PATH` and `enemies=PATH`, which play other
  level and stat files than the ones in `data/`, for what-ifs on waves and numbers without touching
  the data. Since 2026-10-24 the tower use counts in a search result (`three_star_builds_using`) are
  what stood at the end of each play. In the 2026-10-23 report they counted what the strategy planned.
- Run everything from the repo root. Nothing here is exported (the export filter excludes `tools/*` and `docs/*`).

## Checking the bots after a change

The region 1 numbers of the 2026-10-24 report must not move when the bots change, unless the change
is meant to move them. `run_bots_check.sh` plays a set of those jobs again with the same seeds into a
new folder (searches, spreads, recipes, determinism runs and the plain recipe). `compare_raw.gd` then
compares each file with the old one:

```
bash tools/balance/run_bots_check.sh 2026-10-24-bots 4
godot --headless --path . --script res://tools/balance/compare_raw.gd -- old=res://docs/balance/raw/2026-10-24 new=res://docs/balance/raw/2026-10-24-bots ignore=digest,chain_hash,search_hash
```

The `ignore` keys are hashes of the saved battle. The sim's save format changed in phase 7, so they
differ from the 2026-10-24 files although every play is the same. Everything else must be identical.
A strategy file keeps its old shape for a level with one gate (`"gate": [x, y]`). A second or third
gate goes in `"more_gates"`.

`mode=plain compare_old=1` on a region 1 level lists any difference between the plain recipe and the
old recipe. It must list none.

## One pass

`run_pass.sh DATE JOBS [levels]` writes the job list of a whole pass (all levels of campaign.json by
default, Twists included) and runs it, at most JOBS at once. `DRY=1` only writes `jobs.txt`. The seeds
it uses are in the script's header. `EVALS` sets the builds per search (default 3000; the B1 pass used 2500).
Then `summary.gd dir=... pass=1` prints the tables. Run it from a clean checkout of the commit being measured:
other agents edit the working tree, and a half-written data file stops a job with exit code 2 and no output file.

**What-ifs on star 3 rules.** `tweak=star3:KIND;N` replaces the level's star 3 rule in memory (`tier_at_most;2`,
`towers_at_most;5`, `gates_at_most;1`, `early_calls_at_least;6`, `kinds_at_most;3`, `tower_ban;ID`, `no_lives_lost`).
`run_whatif_b1.sh` plays an any-tower search and one lone-attacker search per attacking tower for each rule.

**Plain mode rows** hold `lives_at` (lives when each wave starts), so a report can say in which wave lives were lost.
When `compare_raw.gd` compares a plain file made before B1, add `lives_at` to its `ignore` list.
