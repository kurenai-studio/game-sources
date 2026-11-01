# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The creature rules of regions 5 and 6 at their edges (RULES 6.2, 6.3, 8.1, 8.8;
## docs/ARCHITECTURE.md 14.5, 14.6): Mossbud regrow, Mistwisp mist, Gleamer dazzle,
## Sleepyhead and Old Hayrick naps, Burrowbelly digging and its Mistwisps, the timers step
## order and the new events. Edge cases place creatures exactly and run one step of the
## tick; the rest play the tick as a whole.

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const Tx: GDScript = preload("res://tests/sim/fixtures/tower_fixtures.gd")
const Cx: GDScript = preload("res://tests/sim/fixtures/creature_fixtures.gd")

## A straight road down column 3, entrance [3, 0], base [3, 12], spots on both sides.
const STRAIGHT: Array = [
	"...1...",
	".o.#.o.",
	"..o#o..",
	"...#...",
	"..o#o..",
	"...#...",
	"...#...",
	"..o#o..",
	"...#...",
	"...#...",
	"..o#o..",
	"...#...",
	"...B...",
]
const ROAD_X: int = 70000                              # the center line of column 3

var catalog: Catalog = null


func before_each() -> void:
	catalog = Cx.catalog()


func _battle(groups: Array, changes: Dictionary = {}, stats: Catalog = null, grid: Array = STRAIGHT) -> Battle:
	var b: Battle = Cx.battle(grid, [{"groups": groups}], changes, stats if stats != null else catalog)
	assert_not_null(b)
	return b


## Starts the wave and steps until `count` creatures are on the map.
func _spawned(b: Battle, count: int) -> void:
	b.start_next_wave()
	while b.enemies.size() < count and b.tick < 400:
		b.step()
	b.take_events()


func _of(b: Battle, type: StringName) -> Array[EnemyState]:
	var out: Array[EnemyState] = []
	for e: EnemyState in b.enemies:
		if e.type == type:
			out.append(e)
	return out


func _fired(b: Battle) -> Array[Dictionary]:
	return Fx.events_of(b.take_events(), &"fired")


func _at(column: int, row: int) -> Vector2i:
	return Sim.center(Vector2i(column, row))


# Regrow (RULES 6.2)

func test_a_mossbud_regrows_every_1_s_from_1_s_after_it_appears_rules_6_2() -> void:
	var moss: EnemyType = catalog.enemy(&"mossbud")
	var every: int = moss.regrow_ms / Sim.MS_PER_TICK
	var amount: int = Sim.pct_half_up(moss.regrow, 150)
	var b: Battle = Cx.battle(STRAIGHT, [{"strength": 150, "groups": [Fx.group("mossbud", 1)]}], {}, catalog)
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	assert_eq(e.regrow_at, every, "the first regrow is due 1.0 s after it appears")
	e.health = 10
	Fx.steps(b, every - 1)
	assert_eq(e.health, 10, "not before")
	b.step()
	assert_eq(e.health, 10 + amount, "4 at strength 150 is 6")
	assert_eq(e.regrow_at, 2 * every)
	Fx.steps(b, every)
	assert_eq(e.health, 10 + 2 * amount, "and every 1.0 s after")
	e.health = e.max_health - 1
	Fx.steps(b, every)
	assert_eq(e.health, e.max_health, "up to its max health")
	Fx.steps(b, every)
	assert_eq(e.health, e.max_health, "never above")


func test_a_regrow_scales_with_strength_rounded_half_up_rules_6_4() -> void:
	var three: Catalog = Cx.catalog_with("mossbud", {"regrow": 3})
	var b: Battle = Cx.battle(STRAIGHT, [{"strength": 50, "groups": [Fx.group("mossbud", 1)]}], {}, three)
	assert_not_null(b)
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	e.health = 1
	Fx.steps(b, 20)
	assert_eq(e.health, 3, "3 at strength 50 is 1.5, so 2")


func test_a_mossbud_regrows_out_of_reach_and_a_mender_heals_it_too_rules_6_2_8_7_8_8() -> void:
	var b: Battle = _battle([Fx.group("mossbud", 1)], {}, null, Fx.TUNNEL_GRID)
	b.start_next_wave()
	var e: EnemyState = null
	while b.tick < 200 and (e == null or not e.out_of_reach):
		b.step()
		e = b.enemy_with_id(0)
	assert_true(e.out_of_reach, "in the tunnel")
	e.health = 10
	var due: int = e.regrow_at
	while b.tick <= due:
		b.step()
	assert_true(e.out_of_reach, "still in the tunnel")
	assert_eq(e.health, 14, "it regrows out of reach")
	var mender: EnemyType = catalog.enemy(&"mender")
	var c: Battle = _battle([Fx.group("mossbud", 1), Fx.group("mender", 1)])
	c.start_next_wave()
	c.step()
	c.enemy_with_id(0).health = 10
	Fx.steps(c, mender.heal_ms / Sim.MS_PER_TICK)
	assert_eq(c.enemy_with_id(0).health, 10 + 2 * 4 + mender.heal, "two regrows and a heal, each on its own")


# Mist (RULES 6.2)

## A Mistwisp at [3, 6], four Scamps and a Flitter placed around it, and a second
## Mistwisp beside it; then hiding is worked out as at the start of the towers step.
func _misty_crowd() -> Array:
	var b: Battle = _battle([Fx.group("mistwisp", 2, 0, 50), Fx.group("scamp", 6, 0, 50), Fx.group("flitter", 1)])
	_spawned(b, 9)
	var wisps: Array[EnemyState] = _of(b, &"mistwisp")
	var scamps: Array[EnemyState] = _of(b, &"scamp")
	wisps[0].pos = _at(3, 6)
	wisps[1].pos = _at(3, 7)                           # beside the first: never hidden
	scamps[0].pos = _at(3, 6) + Vector2i(9999, 9999)   # on its tile, at the far corner
	scamps[1].pos = _at(2, 6)                          # west
	scamps[2].pos = _at(3, 5) + Vector2i(0, -9999)     # north, at the far edge
	scamps[3].pos = _at(4, 5)                          # diagonal to the first, and not next to the second
	scamps[4].pos = _at(3, 4) + Vector2i(0, 9999)      # two tiles north, just outside
	scamps[5].pos = _at(1, 7)                          # two tiles west of the second
	var flyer: EnemyState = _of(b, &"flitter")[0]
	flyer.pos = _at(4, 6)                              # east of the first: a flyer is hidden too
	b._tower_step()
	return [b, wisps, scamps, flyer]


func test_mist_hides_its_tile_and_the_four_next_to_it_rules_6_2() -> void:
	var got: Array = _misty_crowd()
	var wisps: Array[EnemyState] = got[1]
	var scamps: Array[EnemyState] = got[2]
	var flyer: EnemyState = got[3]
	assert_false(wisps[0].hidden or wisps[1].hidden, "a Mistwisp is never hidden, even beside another")
	assert_true(scamps[0].hidden, "on its tile")
	assert_true(scamps[1].hidden, "west")
	assert_true(scamps[2].hidden, "north")
	assert_false(scamps[3].hidden, "diagonal")
	assert_false(scamps[4].hidden, "two tiles away")
	assert_false(scamps[5].hidden, "two tiles away from the second")
	assert_true(flyer.hidden, "a flyer over a misty tile")
	var b: Battle = got[0]
	assert_true(b.enemy_numbers(scamps[0].id)["hidden"], "enemy_numbers says hidden")
	assert_false(b.enemy_numbers(scamps[3].id)["hidden"])


func test_hidden_creatures_cannot_be_aimed_at_rules_6_2_and_8_2() -> void:
	var b: Battle = _battle([Fx.group("mistwisp", 1), Fx.group("scamp", 1)])
	_spawned(b, 2)
	var wisp: EnemyState = _of(b, &"mistwisp")[0]
	var scamp: EnemyState = _of(b, &"scamp")[0]
	wisp.pos = _at(4, 3)                               # off the road, so no tower finds it
	scamp.pos = _at(3, 3)                              # on the road west of it, in reach
	var sling: TowerState = Tx.build(b, Vector2i(2, 2), &"sling_post")
	b.take_events()
	b._tower_step()
	assert_eq(_fired(b), [] as Array[Dictionary], "a hidden creature is no target")
	assert_eq(sling.reload, 0, "the timer waits at 0")
	wisp.pos = _at(0, 0)
	b._tower_step()
	var shots: Array[Dictionary] = _fired(b)
	assert_eq(shots.size(), 1, "with the mist gone it fires")
	assert_eq(shots[0]["targets"], [scamp.id] as Array[int])
	assert_false(scamp.hidden)


func test_splash_pulses_lines_and_rings_still_reach_hidden_creatures_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("mistwisp", 1), Fx.group("scamp", 3, 0, 50)])
	_spawned(b, 4)
	var wisp: EnemyState = _of(b, &"mistwisp")[0]
	var scamps: Array[EnemyState] = _of(b, &"scamp")
	wisp.pos = _at(4, 8)                               # off the road, so no tower finds it
	var hidden: EnemyState = scamps[1]
	hidden.pos = Vector2i(ROAD_X, 161000)              # tile [3, 8]: next to the Mistwisp's tile [4, 8]
	var visible: EnemyState = scamps[0]
	visible.pos = Vector2i(ROAD_X, 159000)             # tile [3, 7]: diagonal, clear, 2,000 sub-units from it
	scamps[2].pos = _at(0, 0)
	var cat: TowerState = Tx.build(b, Vector2i(2, 7), &"pumpkin_catapult")
	b.take_events()
	b._tower_step()
	assert_true(hidden.hidden and not visible.hidden)
	var shots: Array[Dictionary] = _fired(b)
	assert_eq(shots.size(), 1)
	assert_eq(shots[0]["targets"], [visible.id] as Array[int], "it aims at the one it can see")
	assert_eq(hidden.health, hidden.max_health - cat.stats.damage, "and its splash reaches the hidden one")
	b.sell_tower(cat.cell)
	var bramble: TowerState = Tx.build(b, Vector2i(4, 7), &"bramble_cottage")
	var before: int = hidden.health
	b._tower_step()
	assert_eq(hidden.health, before - bramble.stats.damage, "a pulse reaches it")
	b.sell_tower(bramble.cell)
	var fort: TowerState = Tx.build(b, Vector2i(2, 10), &"snow_fort")
	before = hidden.health
	b.take_events()
	b._tower_step()
	var line: Array[Dictionary] = _fired(b)
	assert_eq(line.size(), 1)
	assert_true((line[0]["targets"] as Array).has(hidden.id), "a line through it reaches it")
	assert_eq(hidden.health, before - fort.stats.damage)
	b.sell_tower(fort.cell)
	Tx.build(b, Vector2i(2, 7), &"lullaby_bell")
	Tx.build(b, Vector2i(4, 7), &"scarecrow")
	b._ring_step()
	assert_true(hidden.slow_pct > 0 and hidden.fright_pct > 0, "Bells and Scarecrows reach it")


func test_a_mistwisp_out_of_reach_still_hides_rules_6_2_and_8_8() -> void:
	var b: Battle = _battle([Fx.group("mistwisp", 1), Fx.group("scamp", 1)], {}, null, Fx.TUNNEL_GRID)
	_spawned(b, 2)
	var wisp: EnemyState = _of(b, &"mistwisp")[0]
	var scamp: EnemyState = _of(b, &"scamp")[0]
	wisp.pos = _at(3, 4)                               # the last tunnel tile
	scamp.pos = _at(3, 5)
	Tx.build(b, Vector2i(2, 6), &"sling_post")
	b.take_events()
	b._tower_step()
	assert_true(wisp.out_of_reach, "the Mistwisp is out of reach")
	assert_true(scamp.hidden, "and still hides the tile next to it")
	assert_eq(_fired(b), [] as Array[Dictionary], "so nothing can be aimed at")


func test_with_no_mistwisp_nothing_is_hidden_rules_6_2() -> void:
	var got: Array = _misty_crowd()
	var b: Battle = got[0]
	for wisp: EnemyState in got[1]:
		wisp.health = 0
	b._removed = true
	b._compact()
	b._tower_step()
	for e: EnemyState in b.enemies:
		assert_false(e.hidden, "%s %d" % [e.type, e.id])
	assert_false(b._hidden_set)


## In play, every tick: a creature is hidden exactly when its tile is a Mistwisp's tile
## or next to one, by the positions the towers step sees, and no shot aims at it.
func test_hiding_follows_the_mistwisps_tick_by_tick_rules_6_2_and_8_1() -> void:
	var groups: Array = [Fx.group("mistwisp", 2, 0, 3000), Fx.group("scamp", 12, 200, 500), Fx.group("flitter", 4, 300, 1500)]
	var b: Battle = _battle(groups)
	Tx.build(b, Vector2i(2, 4), &"sling_post")
	Tx.build(b, Vector2i(4, 7), &"sling_post")
	b.start_next_wave()
	var hidden_seen: int = 0
	var shots: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 2000:
		b.step()
		var events: Array[Dictionary] = b.take_events()
		# The Mistwisps the towers step saw: those on the map, and those it defeated.
		var spots: Array[Vector2i] = []
		for e: EnemyState in b.enemies:
			if e.mist:
				spots.append(e.pos)
		for event: Dictionary in Fx.events_of(events, &"defeated"):
			if event["enemy"] == &"mistwisp":
				spots.append(event["pos"])
		var misty: Dictionary = {}
		for spot: Vector2i in spots:
			var c: Vector2i = Sim.cell_of(spot)
			for near: Vector2i in [c, c + Vector2i.UP, c + Vector2i.DOWN, c + Vector2i.LEFT, c + Vector2i.RIGHT]:
				misty[near] = true
		var hidden_ids: Array[int] = []
		for e: EnemyState in b.enemies:
			var want: bool = not e.mist and misty.has(Sim.cell_of(e.pos))
			assert_eq(e.hidden, want, "tick %d, %s %d" % [b.tick, e.type, e.id])
			if e.hidden:
				hidden_ids.append(e.id)
		hidden_seen += hidden_ids.size()
		for shot: Dictionary in Fx.events_of(events, &"fired"):
			shots += 1
			for id: int in shot["targets"]:
				assert_false(hidden_ids.has(id), "tick %d: a shot aimed at hidden %d" % [b.tick, id])
	assert_true(hidden_seen > 0 and shots > 0, "hidden %d, shots %d" % [hidden_seen, shots])


# Dazzle (RULES 6.2, 8.2)

## A Scamp ahead and the creatures of `rest` behind it, and a tower placed once they are
## all in its reach. Returns the targets of its first shot.
func _first_shot(rest: Array, tower: StringName, aim: TowerState.Aim, stats: Catalog = null, tier: int = 1, spec: int = -1) -> Array:
	var groups: Array = [Fx.group("scamp", 1)]
	groups.append_array(rest)
	var b: Battle = _battle(groups, {}, stats)
	b.start_next_wave()
	Fx.steps(b, 30)
	var t: TowerState = Tx.build(b, Vector2i(2, 2), tower, tier, spec)
	if aim != TowerState.Aim.FIRST:
		assert_eq(b.set_aim(t.cell, aim), Battle.DONE)
	b.take_events()
	b.step()
	var shots: Array[Dictionary] = _fired(b)
	assert_eq(shots.size(), 1, "one shot")
	return shots[0]["targets"] if shots.size() == 1 else []


func test_a_gleamer_in_range_is_aimed_at_first_in_any_mode_rules_6_2_8_2() -> void:
	var gleamer: Array = [Fx.group("gleamer", 1, 500)]
	assert_eq(_first_shot(gleamer, &"sling_post", TowerState.Aim.FIRST), [1], "First, though the Scamp is nearer the base")
	assert_eq(_first_shot(gleamer, &"sling_post", TowerState.Aim.LAST), [1], "Last")
	var plain: Catalog = Cx.catalog_with("gleamer", {"dazzle": null})
	assert_eq(_first_shot(gleamer, &"sling_post", TowerState.Aim.FIRST, plain), [0], "without dazzle, First takes the Scamp")
	var two: Array = [Fx.group("gleamer", 2, 300, 300)]
	assert_eq(_first_shot(two, &"sling_post", TowerState.Aim.FIRST), [1], "two Gleamers: First picks between them")
	assert_eq(_first_shot(two, &"sling_post", TowerState.Aim.LAST), [2], "Last picks the other")


func test_a_triple_bow_puts_its_first_target_on_a_gleamer_rules_6_2() -> void:
	var rest: Array = [Fx.group("scamp", 2, 100, 100), Fx.group("gleamer", 1, 600)]
	assert_eq(_first_shot(rest, &"longbow_loft", TowerState.Aim.FIRST, null, 3, 1), [3, 0, 1], "the Gleamer, then by First")
	assert_eq(_first_shot(rest, &"longbow_loft", TowerState.Aim.LAST, null, 3, 1), [3, 2, 1], "the Gleamer, then by Last")


func test_a_hidden_gleamer_dazzles_nothing_rules_6_2() -> void:
	var rest: Array = [Fx.group("mistwisp", 1, 400), Fx.group("gleamer", 1, 400)]
	var targets: Array = _first_shot(rest, &"sling_post", TowerState.Aim.LAST)
	assert_false(targets.has(2), "the hidden Gleamer is no target")
	assert_eq(targets, [1], "Last takes the Mistwisp, which is never hidden")


func test_a_moth_lantern_takes_dazzle_first_then_flyers_that_are_not_low_rules_6_2_5_15() -> void:
	var bright: Catalog = Cx.catalog_with("dusk_moth", {"dazzle": true})
	for stats: Catalog in [bright, catalog]:
		var b: Battle = _battle([Fx.group("flitter", 1), Fx.group("dusk_moth", 1)], {}, stats)
		_spawned(b, 2)
		var flitter: EnemyState = _of(b, &"flitter")[0]
		var moth: EnemyState = _of(b, &"dusk_moth")[0]
		flitter.pos = _at(3, 3)
		moth.pos = _at(3, 2)
		moth.low_ticks = 5
		Tx.build(b, Vector2i(2, 2), &"moth_lantern")
		b.take_events()
		b._tower_step()
		var shots: Array[Dictionary] = _fired(b)
		assert_eq(shots.size(), 1)
		var want: int = moth.id if stats == bright else flitter.id
		assert_eq(shots[0]["targets"], [want] as Array[int], "dazzle first" if stats == bright else "not low first")


# Nap (RULES 6.2, 8.1)

func test_a_sleepyhead_naps_instead_of_its_first_defeat_rules_6_2() -> void:
	var sleepy: EnemyType = catalog.enemy(&"sleepyhead")
	var nap: int = sleepy.nap_ms / Sim.MS_PER_TICK
	var b: Battle = _battle([Fx.group("sleepyhead", 1)])
	Tx.build(b, Vector2i(2, 2), &"lullaby_bell")
	Tx.build(b, Vector2i(4, 2), &"scarecrow")
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	while b.tick < 100 and (e.slow_pct == 0 or e.fright_pct == 0):
		b.step()
	assert_true(e.slow_pct > 0 and e.fright_pct > 0, "slowed and frightened first")
	e.health = 1
	var sling: TowerState = Tx.build(b, Vector2i(5, 1), &"sling_post")
	b.take_events()
	var gold: int = b.gold
	var log: Array = []
	while b.tick < 200 and Fx.of_kind(log, &"napped").is_empty():
		log.append_array(Fx.log_ticks(b, 1))
	var napped: Array = Fx.of_kind(log, &"napped")
	assert_eq(napped.size(), 1, "it naps")
	if napped.is_empty():
		return
	var at: int = napped[0][0]
	assert_eq(napped[0][1], {"kind": &"napped", "id": 0, "enemy": &"sleepyhead", "pos": e.pos})
	assert_eq(Fx.of_kind(log, &"defeated"), [], "not defeated")
	assert_eq(b.gold, gold, "no bounty")
	assert_eq(e.health, Sim.pct_half_up(e.max_health, 50), "half its max health")
	assert_true(e.napped)
	assert_eq(e.nap_ticks, nap)
	assert_eq([e.slow_pct, e.slow_ticks, e.fright_pct, e.fright_ticks], [0, 0, 0, 0], "its slow and fright end")
	var numbers: Dictionary = b.enemy_numbers(0)
	assert_eq([numbers["health"], numbers["nap_ms"]], [e.health, sleepy.nap_ms], "the panel's numbers")
	var spot: Vector2i = e.pos
	for k: int in nap - 1:
		var events: Array = Fx.log_ticks(b, 1)
		assert_eq(e.pos, spot, "it does not move")
		assert_eq(e.prev_pos, spot)
		assert_eq(Fx.of_kind(events, &"fired"), [], "no tower aims at it")
		assert_eq([e.slow_pct, e.fright_pct], [0, 0], "Bells and Scarecrows do not reach it")
		assert_eq(e.nap_ticks, nap - 1 - k)
	assert_eq(sling.reload, 0, "the Sling Post waits")
	var woke: Array = Fx.of_kind(Fx.log_ticks(b, 1), &"woke")
	assert_eq(woke.size(), 1)
	assert_eq(woke[0][0], at + nap, "it wakes after 2.0 s")
	assert_eq(woke[0][1], {"kind": &"woke", "id": 0, "enemy": &"sleepyhead", "pos": spot})
	assert_ne(e.pos, spot, "and walks on in the same tick")
	e.health = 1
	gold = b.gold
	var later: Array = Fx.log_ticks(b, 40)
	assert_eq(Fx.of_kind(later, &"napped"), [], "it naps only once")
	var defeated: Array = Fx.of_kind(later, &"defeated")
	assert_eq(defeated.size(), 1, "the next fall pops it for good")
	if defeated.size() == 1:
		assert_eq(defeated[0][1]["gold"], e.bounty, "and pays its bounty")


func test_the_wake_value_rounds_half_up_rules_6_2() -> void:
	var b: Battle = Cx.battle(STRAIGHT, [{"strength": 110, "groups": [Fx.group("sleepyhead", 1)]}], {}, catalog)
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	assert_eq(e.max_health, 99)
	e.health = -3
	b._downed = true
	b._defeat_step()
	assert_eq(e.health, 50, "49.5 rounds to 50")
	var one: Catalog = Cx.catalog_with("sleepyhead", {"health": 1})
	var c: Battle = _battle([Fx.group("sleepyhead", 1)], {}, one)
	c.start_next_wave()
	c.step()
	c.enemy_with_id(0).health = 0
	c._downed = true
	c._defeat_step()
	assert_eq(c.enemy_with_id(0).health, 1, "at max health 1 it wakes with 1")


## A napping creature placed beside other creatures, with towers of every way of hitting.
func test_nothing_hits_heals_or_regrows_a_napping_creature_rules_6_2() -> void:
	var both: Catalog = Cx.catalog_with("sleepyhead", {"regrow": 4, "regrow_ms": 1000})
	var b: Battle = _battle([Fx.group("sleepyhead", 1), Fx.group("scamp", 1), Fx.group("mender", 1)], {}, both)
	_spawned(b, 3)
	var e: EnemyState = _of(b, &"sleepyhead")[0]
	var scamp: EnemyState = _of(b, &"scamp")[0]
	var mender: EnemyState = _of(b, &"mender")[0]
	e.napped = true
	e.nap_ticks = 200
	e.health = 45
	e.pos = Vector2i(ROAD_X, 141000)
	scamp.pos = Vector2i(ROAD_X, 139000)
	mender.pos = _at(0, 0)
	for t: Array in [[Vector2i(2, 7), &"pumpkin_catapult"], [Vector2i(4, 7), &"bramble_cottage"], [Vector2i(2, 4), &"snow_fort"]]:
		var tower: TowerState = Tx.build(b, t[0], t[1])
		b.take_events()
		b._tower_step()
		var shots: Array[Dictionary] = _fired(b)
		assert_eq(shots.size(), 1, "%s fires at the Scamp" % t[1])
		assert_eq(shots[0]["targets"], [scamp.id] as Array[int], "%s: only the Scamp" % t[1])
		assert_eq(e.health, 45, "%s: splash, pulse and line skip it" % t[1])
		scamp.health = scamp.max_health
		b.sell_tower(tower.cell)
	Tx.build(b, Vector2i(2, 7), &"lullaby_bell")
	b._ring_step()
	assert_eq(e.slow_pct, 0, "a Bell does not reach it")
	assert_true(scamp.slow_pct > 0)
	# A heal and two regrows come due while it naps.
	b.sell_tower(Vector2i(2, 7))
	var regrow_at: int = e.regrow_at
	while b.tick < mender.heal_at:
		b.step()
	mender.pos = e.pos
	scamp.pos = e.pos
	scamp.health = 1
	var spot: Vector2i = e.pos
	var log: Array = Fx.log_ticks(b, 1)
	assert_eq(Fx.of_kind(log, &"healed")[0][1]["ids"], [scamp.id] as Array[int], "the heal reaches the Scamp only")
	Fx.steps(b, 40)
	assert_eq(e.health, 45, "no heal and no regrow reach it")
	assert_true(e.regrow_at > regrow_at + 20, "its regrow timer still moves on")
	assert_eq(e.pos, spot)


func test_a_napping_creature_keeps_its_wave_running_and_counts_for_the_early_call_rules_6_2_4_9() -> void:
	var waves: Array = [{"groups": [Fx.group("sleepyhead", 1)]}, {"groups": [Fx.group("scamp", 1)]}]
	var b: Battle = Cx.battle(STRAIGHT, waves, {}, catalog)
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	e.health = 0
	b._downed = true
	b._defeat_step()
	assert_true(e.nap_ticks > 0)
	b.step()
	assert_eq(b.running, [0] as Array[int], "its wave still runs")
	assert_eq(b.next_wave_info()["bonus"], Sim.pct_up(e.bounty, catalog.rules.early_bonus_pct), "its bounty counts for the early call bonus")


func test_a_nap_releases_nothing_and_the_last_fall_does_rules_6_2() -> void:
	var split: Catalog = Cx.catalog_with("sleepyhead", {"split_into": "puff", "split_count": 3, "split_gap_ms": 300})
	var b: Battle = _battle([Fx.group("sleepyhead", 1)], {}, split)
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	e.health = 0
	b._downed = true
	b._defeat_step()
	assert_eq(Fx.events_of(b.take_events(), &"released"), [] as Array[Dictionary], "no release on a nap")
	e.nap_ticks = 0
	e.health = 0
	b._downed = true
	b._defeat_step()
	var events: Array[Dictionary] = b.take_events()
	assert_eq(Fx.events_of(events, &"defeated").size(), 1)
	assert_eq(Fx.events_of(events, &"released").size(), 1, "the Puffs come when it pops for good")


func test_old_hayrick_naps_3_s_and_dazzles_rules_6_3() -> void:
	var hay: EnemyType = catalog.enemy(&"old_hayrick")
	var b: Battle = _battle([Fx.group("old_hayrick", 1)])
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	assert_true(e.dazzle)
	e.health = 0
	b._downed = true
	b._defeat_step()
	assert_eq(e.nap_ticks, hay.nap_ms / Sim.MS_PER_TICK, "3.0 s")
	assert_eq(e.health, 1300, "half of 2600")
	assert_eq(b.gold, 100000, "no bounty")


# Dig (RULES 6.3)

func test_burrowbelly_digs_every_8_s_for_2_s_and_brings_up_mistwisps_rules_6_3() -> void:
	var belly: EnemyType = catalog.enemy(&"burrowbelly")
	var first: int = belly.dig_first_ms / Sim.MS_PER_TICK
	var every: int = belly.dig_every_ms / Sim.MS_PER_TICK
	var dig: int = belly.dig_ms / Sim.MS_PER_TICK
	var gap: int = int(belly.summon["gap_ms"]) / Sim.MS_PER_TICK
	var b: Battle = _battle([Fx.group("burrowbelly", 1)])
	Tx.build(b, Vector2i(4, 2), &"sling_post")
	Tx.build(b, Vector2i(2, 4), &"lullaby_bell")
	b.start_next_wave()
	var log: Array = []
	var boss: EnemyState = null
	var under: Array[int] = []
	var moved_under: bool = false
	var slow_before: int = 0
	var slowed_after: bool = false
	while b.tick < first + 2 * every + 1 and b.phase == Battle.Phase.WAVE:
		var at: int = b.tick
		var before: Vector2i = boss.pos if boss != null else Vector2i.ZERO
		var was_under: bool = boss != null and boss.dig_ticks > 0
		for entry: Array in Fx.log_ticks(b, 1):
			log.append(entry)
		boss = b.enemy_with_id(0)
		assert_eq(boss.out_of_reach, boss.dig_ticks > 0, "tick %d: out of reach while dug under" % at)
		if boss.dig_ticks > 0:
			under.append(at)
			moved_under = moved_under or boss.pos != before
			if was_under:
				assert_eq(boss.slow_ticks, maxi(slow_before - 1, 0), "tick %d: its slow runs down, and no Bell reaches it" % at)
		if at == first + dig + 1:
			slowed_after = boss.slow_pct > 0
		slow_before = boss.slow_ticks
	assert_eq(Fx.ticks(Fx.of_kind(log, &"burrowed")), [first, first + every, first + 2 * every] as Array[int], "6.0 s, then every 8.0 s")
	assert_eq(Fx.ticks(Fx.of_kind(log, &"surfaced")), [first + dig, first + every + dig] as Array[int], "2.0 s under")
	assert_eq(under.size(), 2 * dig + 1, "out of reach for exactly the dig, each time")
	assert_true(moved_under, "it walks on under the ground")
	var shots_at_it: int = 0
	for entry: Array in Fx.of_kind(log, &"fired"):
		var at: int = entry[0]
		var dug: bool = (at >= first and at < first + dig) or (at >= first + every and at < first + every + dig) or at >= first + 2 * every
		var at_it: bool = (entry[1]["targets"] as Array).has(0)
		if dug:
			assert_false(at_it, "tick %d: no shot at it while dug under" % at)
		elif at_it:
			shots_at_it += 1
	var burrowed: Dictionary = Fx.of_kind(log, &"burrowed")[0][1]
	assert_eq(burrowed.keys(), ["kind", "id", "enemy", "pos"])
	assert_eq([burrowed["id"], burrowed["enemy"]], [0, &"burrowbelly"])
	var surfaced: Array = Fx.of_kind(log, &"surfaced")[0]
	var released: Array = Fx.of_kind(log, &"released")
	assert_eq(Fx.ticks(released), [first + dig, first + every + dig] as Array[int], "its Mistwisps come as it comes up")
	var wisps: Array = []
	for entry: Array in Fx.of_kind(log, &"spawned"):
		if entry[1]["enemy"] == &"mistwisp":
			wisps.append(entry)
	assert_eq(Fx.ticks(wisps.slice(0, 2)), [first + dig, first + dig + gap] as Array[int], "2 Mistwisps, 0.3 s apart")
	assert_eq(wisps[0][1]["pos"], released[0][1]["pos"], "at its spot")
	assert_eq(wisps[1][1]["pos"], released[0][1]["pos"])
	assert_eq(surfaced[1].keys(), ["kind", "id", "enemy", "pos"])
	assert_true(shots_at_it > 0, "the Sling Post hits it when it is up")
	assert_true(slowed_after, "and the Bell slows it again once it is up")


# The timers step order and the events (RULES 8.1, docs/ARCHITECTURE.md 14.5, 14.6)

func test_heals_come_before_wakes_and_wakes_and_digs_go_in_id_order_contract_14_5() -> void:
	var b: Battle = _battle([Fx.group("sleepyhead", 1), Fx.group("mender", 1), Fx.group("scamp", 1), Fx.group("burrowbelly", 1)])
	_spawned(b, 4)
	var e: EnemyState = _of(b, &"sleepyhead")[0]
	var mender: EnemyState = _of(b, &"mender")[0]
	var scamp: EnemyState = _of(b, &"scamp")[0]
	var boss: EnemyState = _of(b, &"burrowbelly")[0]
	var due: int = mender.heal_at
	assert_eq(due, 40)
	while b.tick < due - 1:
		b.step()
	e.napped = true
	e.nap_ticks = 2                                    # 1 after this tick, 0 in the tick the heal is due
	boss.dig_at = due
	b.step()
	mender.pos = scamp.pos
	scamp.health = 1
	b.take_events()
	b.step()
	var kinds: Array[StringName] = []
	for event: Dictionary in b.take_events():
		if [&"healed", &"woke", &"burrowed"].has(event["kind"]):
			kinds.append(event["kind"])
	assert_eq(kinds, [&"healed", &"woke", &"burrowed"] as Array[StringName], "(a) heals, then (b) in id order")


func test_a_regrow_due_as_the_nap_ends_is_skipped_but_its_timer_moves_on_contract_14_5() -> void:
	var both: Catalog = Cx.catalog_with("sleepyhead", {"regrow": 4, "regrow_ms": 1000})
	var b: Battle = _battle([Fx.group("sleepyhead", 1)], {}, both)
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	e.napped = true
	e.health = 30
	e.nap_ticks = e.regrow_at - b.tick + 1             # it wakes in the tick the regrow is due
	var due: int = e.regrow_at
	while b.tick <= due:
		b.step()
	assert_eq(e.nap_ticks, 0, "awake")
	assert_eq(e.health, 30, "regrow comes before the nap ends in the timers step")
	assert_eq(e.regrow_at, due + 20, "and its timer moved on")
	Fx.steps(b, 20)
	assert_eq(e.health, 34, "the next one lands")


func test_a_nap_starts_in_the_defeats_step_after_the_shot_rules_8_1() -> void:
	var b: Battle = _battle([Fx.group("sleepyhead", 1)])
	b.start_next_wave()
	b.step()
	b.enemy_with_id(0).health = 1
	Tx.build(b, Vector2i(2, 2), &"sling_post")
	b.take_events()
	var kinds: Array[StringName] = []
	while b.tick < 100 and not kinds.has(&"napped"):
		b.step()
		kinds.clear()
		for event: Dictionary in b.take_events():
			kinds.append(event["kind"])
	assert_true(kinds.find(&"fired") >= 0 and kinds.find(&"fired") < kinds.find(&"napped"), str(kinds))


# Statuses after load (docs/ARCHITECTURE.md 14.5, 14.7)

func test_statuses_are_worked_out_again_on_load_contract_14_5() -> void:
	var b: Battle = _battle([Fx.group("burrowbelly", 1), Fx.group("mistwisp", 1, 6500), Fx.group("scamp", 1, 6500),
		Fx.group("sleepyhead", 1, 6000)], {}, null, Fx.TUNNEL_GRID)
	b.start_next_wave()
	var dug: bool = false
	var hidden: bool = false
	var napping: bool = false
	var tunnel: bool = false
	while b.tick < 400 and b.phase == Battle.Phase.WAVE:
		b.step()
		if b.phase != Battle.Phase.WAVE:
			break
		var sleepy: Array[EnemyState] = _of(b, &"sleepyhead")
		if not sleepy.is_empty() and not sleepy[0].napped:
			sleepy[0].health = 0
			b._downed = true
			b._defeat_step()
		var copy: Battle = Fx.restored(b)
		assert_not_null(copy, "tick %d loads" % b.tick)
		if copy == null:
			return
		assert_eq(copy.enemies.size(), b.enemies.size())
		for i: int in b.enemies.size():
			var e: EnemyState = b.enemies[i]
			var c: EnemyState = copy.enemies[i]
			assert_eq([c.out_of_reach, c.hidden, c.nap_ticks, c.napped, c.dig_ticks], [e.out_of_reach, e.hidden, e.nap_ticks, e.napped, e.dig_ticks],
				"tick %d, %s %d" % [b.tick, e.type, e.id])
			dug = dug or e.dig_ticks > 0
			hidden = hidden or e.hidden
			napping = napping or e.nap_ticks > 0
			tunnel = tunnel or (e.out_of_reach and e.dig_ticks == 0)
	assert_true(dug and hidden and napping and tunnel, "dug %s, hidden %s, napping %s, tunnel %s" % [dug, hidden, napping, tunnel])
