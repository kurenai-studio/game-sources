# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The creature rules of regions 7 and 8 at their edges (RULES 6.2, 6.3, 8.1, 8.5;
## docs/ARCHITECTURE.md 14.5, 14.6): Snowroller and Snowsnore growth, Yawner and Snowsnore
## yawns and tower dozes, Blinker and Glimmertoad blinks, Hootling and Glimmertoad wake,
## Glimmertoad's Flitters, the timers step order and the new events. Also the DM's rule of
## 2026-10-27: a napping creature does nothing, and its break and summon timers pause.
## Edge cases place creatures exactly and run one step of the tick; the rest play the
## tick as a whole.

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


func _at(column: int, row: int) -> Vector2i:
	return Sim.center(Vector2i(column, row))


## Puts a walker on the step from `from` to `to`, `progress` along it.
func _put(b: Battle, e: EnemyState, from: Vector2i, to: Vector2i, progress: int) -> void:
	e.from_cell = from
	e.to_cell = to
	e.to_node = b.map.node_of(to)
	e.progress = progress
	e.step_dir = to - from
	b._place(e)


## A creature that is down now naps, as the defeats step does.
func _knock_down(b: Battle, e: EnemyState) -> void:
	e.health = 0
	b._downed = true
	b._defeat_step()
	assert_true(e.nap_ticks > 0, "%s naps" % e.type)


# Grow (RULES 6.2, 6.3)

func test_a_snowroller_grows_10_pct_of_its_start_at_each_tile_center_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("snowroller", 1)])
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	assert_eq([e.start_health, e.max_health, e.health], [40, 40, 40], "its spawn at the entrance does not count")
	e.health = 30
	Fx.steps(b, 18)
	assert_eq(e.max_health, 40, "not before the first center")
	for k: int in range(1, 12):
		Fx.steps(b, 20 if k > 1 else 1)
		assert_eq([e.max_health, e.health], [40 + 4 * k, 30 + 4 * k], "center %d: both rise by 4" % k)
	assert_eq(b.enemy_numbers(0)["max_health"], 84, "enemy_numbers gives the grown max health")
	assert_eq(e.start_health, 40, "the start stays")


func test_growth_rounds_half_up_adds_only_what_fits_and_then_stops_rules_6_2() -> void:
	var b: Battle = Cx.battle(STRAIGHT, [{"strength": 115, "groups": [Fx.group("snowroller", 1)]}], {}, catalog)
	b.start_next_wave()
	Fx.steps(b, 20)
	var e: EnemyState = b.enemy_with_id(0)
	assert_eq([e.start_health, e.max_health], [46, 51], "46 at strength 115, and 4.6 rounds to 5")
	var big: Catalog = Cx.catalog_with("snowroller", {"grow_pct": 30, "grow_cap_pct": 150})
	var c: Battle = Cx.battle(STRAIGHT, [{"strength": 105, "groups": [Fx.group("snowroller", 1)]}], {}, big)
	c.start_next_wave()
	c.step()
	var f: EnemyState = c.enemy_with_id(0)
	assert_eq([f.start_health, f.grow_step, f.grow_cap], [42, 13, 63], "12.6 rounds to 13; the cap is 63")
	f.health = 37
	Fx.steps(c, 19)
	assert_eq([f.max_health, f.health], [55, 50], "the first center")
	Fx.steps(c, 20)
	assert_eq([f.max_health, f.health], [63, 58], "only 8 fit, to both")
	Fx.steps(c, 20)
	assert_eq([f.max_health, f.health], [63, 58], "then it stops")


func test_snowsnore_grows_2_pct_up_to_1_5_times_rules_6_3() -> void:
	var b: Battle = _battle([Fx.group("snowsnore", 1)])
	b.start_next_wave()
	b.step()
	var e: EnemyState = b.enemy_with_id(0)
	assert_eq([e.start_health, e.grow_step, e.grow_cap], [3400, 68, 5100])
	while b.tick < 200 and e.max_health == 3400:
		b.step()
	assert_eq(e.max_health, 3468, "2% at the first center")
	e.max_health = 5090
	e.health = 5000
	var at: int = e.max_health
	while b.tick < 400 and e.max_health == at:
		b.step()
	assert_eq([e.max_health, e.health], [5100, 5010], "up to 1.5 times")
	Fx.steps(b, 70)
	assert_eq(e.max_health, 5100, "and no more")


func test_the_end_of_a_twin_step_counts_as_a_center_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("snowroller", 1)], {}, null, Fx.STUMP_GRID)
	b.start_next_wave()
	var e: EnemyState = null
	while b.tick < 200 and (e == null or e.to_cell != Vector2i(5, 5)):
		b.step()
		e = b.enemy_with_id(0)
	assert_eq([e.from_cell, e.to_cell], [Vector2i(3, 2), Vector2i(5, 5)], "on the twin step")
	var before: int = e.max_health
	while b.tick < 300 and e.from_cell == Vector2i(3, 2):
		b.step()
	assert_eq(e.max_health, before + 4, "it grew once, landing at the twin")


# Yawn and doze (RULES 6.2, 6.3)

func test_a_yawn_dozes_every_attacking_tower_in_reach_but_never_bells_scarecrows_or_bakeries_rules_6_2() -> void:
	var yawner: EnemyType = catalog.enemy(&"yawner")
	var b: Battle = _battle([Fx.group("yawner", 1)])
	_spawned(b, 1)
	var e: EnemyState = b.enemy_with_id(0)
	assert_eq(e.yawn_at, 80, "the first yawn is due 4.0 s after it appears")
	e.pos = _at(3, 3)
	for t: Array in [[Vector2i(2, 2), &"sling_post"], [Vector2i(4, 2), &"bramble_cottage"], [Vector2i(2, 4), &"lullaby_bell"],
			[Vector2i(4, 4), &"snow_fort"], [Vector2i(5, 1), &"moth_lantern"]]:
		Tx.build(b, t[0], t[1])
	b.take_events()
	e.yawn_at = b.tick
	b._timer_step()
	var yawns: Array[Dictionary] = Fx.events_of(b.take_events(), &"yawned")
	assert_eq(yawns.size(), 1)
	var cells: Array[Vector2i] = [Vector2i(2, 2), Vector2i(4, 2), Vector2i(4, 4)]
	assert_eq(yawns[0], {"kind": &"yawned", "id": 0, "enemy": &"yawner", "pos": _at(3, 3), "cells": cells}, "in spot order")
	assert_eq(yawns[0].keys(), ["kind", "id", "enemy", "pos", "cells"])
	var doze: int = yawner.doze_ms / Sim.MS_PER_TICK
	assert_eq(b.tower_at(Vector2i(2, 2)).doze_ticks, doze, "2.0 s")
	assert_eq(b.tower_at(Vector2i(4, 4)).doze_ticks, doze)
	assert_eq(b.tower_at(Vector2i(2, 4)).doze_ticks, 0, "a Bell never dozes")
	assert_eq(b.tower_at(Vector2i(5, 1)).doze_ticks, 0, "out of reach")
	assert_eq(e.yawn_at, b.tick + yawner.yawn_ms / Sim.MS_PER_TICK, "the next is 4.0 s on")
	assert_eq(b.tower_numbers(Vector2i(2, 2))["doze_ms"], yawner.doze_ms, "tower_numbers gives the time left")
	assert_eq(b.tower_numbers(Vector2i(2, 4))["doze_ms"], 0)
	b.sell_tower(Vector2i(2, 4))
	b.sell_tower(Vector2i(4, 4))
	Tx.build(b, Vector2i(2, 4), &"bakery")
	Tx.build(b, Vector2i(4, 4), &"scarecrow")
	for cell: Vector2i in [Vector2i(2, 2), Vector2i(4, 2)]:
		b.tower_at(cell).doze_ticks = 0
	b.take_events()
	e.yawn_at = b.tick
	b._timer_step()
	var again: Array[Dictionary] = Fx.events_of(b.take_events(), &"yawned")
	assert_eq(again[0]["cells"], [Vector2i(2, 2), Vector2i(4, 2)] as Array[Vector2i], "Bakeries and Scarecrows never doze")
	assert_eq([b.tower_at(Vector2i(2, 4)).doze_ticks, b.tower_at(Vector2i(4, 4)).doze_ticks], [0, 0])


func test_a_yawn_reaches_exactly_1_5_tiles_and_lands_with_no_tower_in_reach_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("yawner", 1)])
	_spawned(b, 1)
	var e: EnemyState = b.enemy_with_id(0)
	var sling: TowerState = Tx.build(b, Vector2i(2, 2), &"sling_post")
	b.take_events()
	e.pos = Sim.center(Vector2i(2, 2)) + Vector2i(30000, 0)
	e.yawn_at = b.tick
	b._timer_step()
	assert_eq(sling.doze_ticks, 40, "a tower center exactly 1.5 tiles away dozes")
	sling.doze_ticks = 0
	e.pos += Vector2i(1, 0)
	e.yawn_at = b.tick
	b.take_events()
	b._timer_step()
	assert_eq(sling.doze_ticks, 0, "one sub-unit further does not")
	var yawns: Array[Dictionary] = Fx.events_of(b.take_events(), &"yawned")
	assert_eq(yawns.size(), 1, "the yawn still happens")
	assert_eq(yawns[0]["cells"], [] as Array[Vector2i], "with no tower")


func test_doze_timers_run_down_before_new_yawns_land_and_keep_the_longer_time_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("yawner", 1)])
	_spawned(b, 1)
	var e: EnemyState = b.enemy_with_id(0)
	e.pos = _at(3, 2)
	var near: TowerState = Tx.build(b, Vector2i(2, 2), &"sling_post")
	var long: TowerState = Tx.build(b, Vector2i(4, 2), &"sling_post")
	near.doze_ticks = 1
	long.doze_ticks = 50
	b._dozes_on = true                                 # as a yawn sets it
	e.yawn_at = b.tick
	b._timer_step()
	assert_eq(near.doze_ticks, 40, "1 ran down to 0, then the new doze lasts its full 40")
	assert_eq(long.doze_ticks, 49, "50 ran down to 49, which is longer than 40")


## The Yawner walks down the road; its first yawn at tick 80 catches the Sling Post at
## [2, 2], whose towers step is skipped for exactly 40 ticks, starting that tick.
func test_a_dozing_tower_skips_its_turn_for_the_whole_doze_from_the_yawn_tick_rules_6_2_8_1() -> void:
	var b: Battle = _battle([Fx.group("yawner", 1)])
	var sling: TowerState = Tx.build(b, Vector2i(2, 2), &"sling_post")
	b.start_next_wave()
	var reload_before: int = -1
	var log: Array = []
	while b.tick <= 170 and b.phase == Battle.Phase.WAVE:
		var at: int = b.tick
		var events: Array = Fx.log_ticks(b, 1)
		log.append_array(events)
		var shots: Array = Fx.of_kind(events, &"fired")
		if at >= 80 and at < 120:
			assert_eq(shots, [], "tick %d: no shot while dozing" % at)
			assert_eq(sling.reload, reload_before, "tick %d: the reload timer waits" % at)
			assert_eq(sling.doze_ticks, 40 - (at - 80), "tick %d" % at)
		if at == 120:
			assert_eq(sling.doze_ticks, 0)
			assert_true(not shots.is_empty() or sling.reload < reload_before, "tick 120: it acts again")
		reload_before = sling.reload
	var yawns: Array = Fx.of_kind(log, &"yawned")
	assert_eq(Fx.ticks(yawns), [80, 160] as Array[int], "4.0 s after it appears, then every 4.0 s")
	assert_eq(yawns[0][1]["cells"], [Vector2i(2, 2)] as Array[Vector2i])
	assert_eq(yawns[1][1]["cells"], [] as Array[Vector2i], "the second finds no tower near")
	assert_true(Fx.of_kind(log, &"fired").size() > 3, "the Sling Post shot before and after")


func test_a_yawner_yawns_out_of_reach_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("yawner", 1)], {}, null, Fx.TUNNEL_GRID)
	_spawned(b, 1)
	var e: EnemyState = b.enemy_with_id(0)
	var sling: TowerState = Tx.build(b, Vector2i(2, 3), &"sling_post")
	_put(b, e, Vector2i(3, 2), Vector2i(3, 3), Sim.UNIT)
	b._tower_step()
	assert_true(e.out_of_reach, "in the tunnel")
	e.yawn_at = b.tick
	b._timer_step()
	assert_eq(sling.doze_ticks, 40, "the tower beside the mound dozes")


func test_snowsnore_yawns_every_6_s_within_2_tiles_for_3_s_rules_6_3() -> void:
	var b: Battle = _battle([Fx.group("snowsnore", 1)])
	_spawned(b, 1)
	var e: EnemyState = b.enemy_with_id(0)
	assert_eq(e.yawn_at, 120)
	var above: TowerState = Tx.build(b, Vector2i(2, 2), &"sling_post")
	var beside: TowerState = Tx.build(b, Vector2i(4, 4), &"sling_post")
	e.pos = _at(2, 4)                                  # exactly 2.0 tiles from both towers
	e.yawn_at = b.tick
	b._timer_step()
	assert_eq([above.doze_ticks, beside.doze_ticks], [60, 60], "2.0 tiles away, 3.0 s")
	assert_eq(e.yawn_at, b.tick + 120, "the next is 6.0 s on")
	above.doze_ticks = 0
	beside.doze_ticks = 0
	e.pos += Vector2i(0, 1)
	e.yawn_at = b.tick
	b._timer_step()
	assert_eq([above.doze_ticks, beside.doze_ticks], [0, 0], "just beyond 2.0 tiles")


# Blink (RULES 6.2, 6.3)

func test_a_blinker_blinks_2_tiles_every_3_s_then_walks_on_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("blinker", 1)])
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 130)
	var blinks: Array = Fx.of_kind(log, &"blinked")
	assert_eq(Fx.ticks(blinks), [60, 120] as Array[int], "3.0 s after it appears, then every 3.0 s")
	assert_eq(blinks[0][1], {"kind": &"blinked", "id": 0, "enemy": &"blinker", "from": Vector2i(ROAD_X, 64000), "pos": Vector2i(ROAD_X, 104000)})
	assert_eq(blinks[0][1].keys(), ["kind", "id", "enemy", "from", "pos"])
	assert_eq(blinks[1][1]["from"], Vector2i(ROAD_X, 158000), "it walked on at its speed")
	assert_eq(blinks[1][1]["pos"], Vector2i(ROAD_X, 198000))
	var c: Battle = _battle([Fx.group("blinker", 1)])
	c.start_next_wave()
	Fx.steps(c, 60)
	c.step()
	var e: EnemyState = c.enemy_with_id(0)
	assert_eq(e.pos, Vector2i(ROAD_X, 104900), "the blink, then its usual move in the same tick")
	assert_eq(e.prev_pos, Vector2i(ROAD_X, 104000), "prev_pos is where it landed")


func test_a_slow_never_shortens_a_blink_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("blinker", 1)])
	_spawned(b, 1)
	var e: EnemyState = b.enemy_with_id(0)
	e.slow_pct = 50
	e.slow_ticks = 100
	var before: Vector2i = e.pos
	e.blink_at = b.tick
	b._move_step()
	assert_eq(e.pos, before + Vector2i(0, 40000 + 450), "2 tiles, then half its usual move")


func test_a_blink_that_would_pass_the_base_ends_there_and_gets_through_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("blinker", 1)])
	_spawned(b, 1)
	var e: EnemyState = b.enemy_with_id(0)
	_put(b, e, Vector2i(3, 10), Vector2i(3, 11), 10000)
	var lives: int = b.lives
	e.blink_at = b.tick
	b._move_step()
	var events: Array[Dictionary] = b.take_events()
	var blinked: Array[Dictionary] = Fx.events_of(events, &"blinked")
	assert_eq(blinked.size(), 1)
	assert_eq(blinked[0]["pos"], Sim.center(b.level.base), "it ends at the base")
	assert_eq(Fx.events_of(events, &"leaked").size(), 1, "and gets through")
	assert_eq(b.lives, lives - 1)
	assert_eq(b.enemies.size(), 0)


func test_a_blink_takes_a_twin_step_as_one_tile_and_grows_at_each_center_rules_6_2() -> void:
	var both: Catalog = Cx.catalog_with("blinker", {"grow_pct": 10, "grow_cap_pct": 300})
	var b: Battle = _battle([Fx.group("blinker", 1)], {}, both, Fx.STUMP_GRID)
	_spawned(b, 1)
	var e: EnemyState = b.enemy_with_id(0)
	assert_eq(e.max_health, 60)
	_put(b, e, Vector2i(3, 0), Vector2i(3, 1), Sim.UNIT)
	e.blink_at = b.tick
	b._move_step()
	var blinked: Array[Dictionary] = Fx.events_of(b.take_events(), &"blinked")
	assert_eq(blinked.size(), 1)
	assert_eq([blinked[0]["from"], blinked[0]["pos"]], [_at(3, 1), _at(5, 5)], "one tile to the stump, one across the twin step")
	assert_eq(e.prev_pos, _at(5, 5), "it landed at the twin")
	assert_eq([e.from_cell, e.to_cell], [Vector2i(5, 5), Vector2i(5, 6)], "and walked on from there")
	assert_eq(e.max_health, 72, "it grew at both centers")


func test_a_napping_creature_never_blinks_but_its_timer_moves_on_rules_6_2() -> void:
	var sleepy: Catalog = Cx.catalog_with("blinker", {"nap_ms": 2000})
	var b: Battle = _battle([Fx.group("blinker", 1)], {}, sleepy)
	_spawned(b, 1)
	var e: EnemyState = b.enemy_with_id(0)
	_knock_down(b, e)
	b.take_events()
	var spot: Vector2i = e.pos
	e.blink_at = b.tick
	b._move_step()
	assert_eq(e.pos, spot, "it stays")
	assert_eq(Fx.events_of(b.take_events(), &"blinked"), [] as Array[Dictionary])
	assert_eq(e.blink_at, b.tick + 60, "the timer moved on")


func test_glimmertoad_hops_3_tiles_every_6_s_rules_6_3() -> void:
	var b: Battle = _battle([Fx.group("glimmertoad", 1)])
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 121)
	var hops: Array = Fx.of_kind(log, &"blinked")
	assert_eq(Fx.ticks(hops), [120] as Array[int], "6.0 s after it appears")
	assert_eq((hops[0][1]["pos"] as Vector2i) - (hops[0][1]["from"] as Vector2i), Vector2i(0, 60000), "3 tiles")
	assert_eq(b.enemy_with_id(0).blink_at, 240)


# Wake (RULES 6.2, 8.5)

func test_a_hootling_wakes_every_creature_within_1_5_tiles_itself_included_rules_6_2() -> void:
	var groups: Array = [Fx.group("hootling", 1), Fx.group("scamp", 3, 0, 50), Fx.group("flitter", 1), Fx.group("sleepyhead", 1)]
	var b: Battle = _battle(groups)
	_spawned(b, 6)
	var hoot: EnemyState = _of(b, &"hootling")[0]
	var scamps: Array[EnemyState] = _of(b, &"scamp")
	var flyer: EnemyState = _of(b, &"flitter")[0]
	var sleepy: EnemyState = _of(b, &"sleepyhead")[0]
	_knock_down(b, sleepy)
	hoot.pos = Vector2i(ROAD_X, 130000)
	scamps[0].pos = Vector2i(ROAD_X, 160000)           # exactly 1.5 tiles
	scamps[1].pos = Vector2i(ROAD_X, 160001)           # just beyond
	scamps[2].pos = Vector2i(ROAD_X + 21213, 151213)   # on the diagonal, just inside
	flyer.pos = Vector2i(60000, 120000)
	sleepy.pos = Vector2i(ROAD_X, 110000)
	for e: EnemyState in b.enemies:
		e.slow_pct = 45
		e.slow_ticks = 20
	b._timer_step()
	for e: EnemyState in [hoot, scamps[0], scamps[2], flyer, sleepy]:
		assert_true(e.awake, "%s %d is awake" % [e.type, e.id])
		assert_eq([e.slow_pct, e.slow_ticks], [0, 0], "%s %d: its slow ends" % [e.type, e.id])
		assert_true(b.enemy_numbers(e.id)["awake"])
	assert_false(scamps[1].awake, "one sub-unit beyond 1.5 tiles")
	assert_eq([scamps[1].slow_pct, scamps[1].slow_ticks], [45, 19], "its slow runs on")
	assert_false(b.enemy_numbers(scamps[1].id)["awake"])
	hoot.health = 0
	b._removed = true
	b._compact()
	b._timer_step()
	for e: EnemyState in b.enemies:
		assert_false(e.awake, "with no Hootling nothing is awake: %s %d" % [e.type, e.id])
	assert_false(b._awake_set)


func test_creatures_out_of_reach_are_awake_too_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("hootling", 1), Fx.group("scamp", 1)], {}, null, Fx.TUNNEL_GRID)
	_spawned(b, 2)
	var hoot: EnemyState = _of(b, &"hootling")[0]
	var scamp: EnemyState = _of(b, &"scamp")[0]
	_put(b, hoot, Vector2i(3, 4), Vector2i(3, 5), Sim.UNIT)
	_put(b, scamp, Vector2i(3, 3), Vector2i(3, 4), Sim.UNIT)
	b._tower_step()
	assert_true(scamp.out_of_reach and not hoot.out_of_reach)
	b._timer_step()
	assert_true(scamp.awake, "a creature in the tunnel beside it is awake")


func test_an_awake_creature_gets_no_slow_but_frights_and_lures_land_rules_6_2() -> void:
	var b: Battle = _battle([Fx.group("hootling", 1), Fx.group("scamp", 2, 0, 50), Fx.group("flitter", 1)])
	_spawned(b, 4)
	var hoot: EnemyState = _of(b, &"hootling")[0]
	var scamps: Array[EnemyState] = _of(b, &"scamp")
	var flyer: EnemyState = _of(b, &"flitter")[0]
	hoot.pos = Vector2i(ROAD_X, 70000)
	scamps[0].pos = Vector2i(ROAD_X, 80000)            # awake
	scamps[1].pos = Vector2i(ROAD_X, 110000)           # 2 tiles away: not awake
	flyer.pos = Vector2i(ROAD_X, 60000)                # awake
	b._timer_step()
	assert_true(scamps[0].awake and flyer.awake and not scamps[1].awake)
	Tx.build(b, Vector2i(2, 4), &"lullaby_bell")
	Tx.build(b, Vector2i(4, 4), &"scarecrow")
	b._ring_step()
	assert_eq(scamps[0].slow_pct, 0, "a Bell does not slow it")
	assert_true(scamps[1].slow_pct > 0, "the one further away is slowed")
	assert_true(scamps[0].fright_pct > 0, "a Scarecrow still frightens it")
	var jam: TowerStats = Fx.stats(catalog, &"pumpkin_catapult", 3, 1)
	assert_true(jam.slow_pct > 0, "the Jam Pot slows")
	var index: int = b.enemies.find(scamps[0])
	b._hit(index, jam, 0)
	assert_eq(scamps[0].slow_pct, 0, "a Jam Pot's hit does not slow it")
	assert_true(scamps[0].health < scamps[0].max_health, "but it hurts")
	var lantern: TowerStats = Fx.stats(catalog, &"moth_lantern", 1)
	b._hit(b.enemies.find(flyer), lantern, 0)
	assert_true(flyer.low_ticks > 0, "a lure still lands")


## Every tick, a creature is awake exactly when it was within 1.5 tiles of the Hootling at
## the start of the tick (where the timers step saw them), and then holds no slow under
## the Bells.
func test_wake_follows_the_hootling_tick_by_tick_rules_6_2_8_1() -> void:
	var b: Battle = _battle([Fx.group("hootling", 1, 1000), Fx.group("scamp", 16, 0, 300)])
	Tx.build(b, Vector2i(2, 4), &"lullaby_bell", 2)
	Tx.build(b, Vector2i(4, 7), &"lullaby_bell", 2)
	b.start_next_wave()
	var awake_seen: int = 0
	var slowed_seen: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 800:
		var before: Dictionary = {}
		var hoot_at: Vector2i = Vector2i(-1, -1)
		for e: EnemyState in b.enemies:
			before[e.id] = e.pos
			if e.type == &"hootling":
				hoot_at = e.pos
		b.step()
		if hoot_at.x < 0:
			continue                                   # no Hootling yet, or it appears this tick
		for e: EnemyState in b.enemies:
			if not before.has(e.id):
				continue
			var d: Vector2i = (before[e.id] as Vector2i) - hoot_at
			var want: bool = d.x * d.x + d.y * d.y <= 30000 * 30000
			assert_eq(e.awake, want, "tick %d, %s %d" % [b.tick - 1, e.type, e.id])
			if want:
				assert_eq(e.slow_pct, 0, "tick %d: awake %d holds no slow" % [b.tick - 1, e.id])
				awake_seen += 1
			elif e.slow_pct > 0:
				slowed_seen += 1
	assert_true(awake_seen > 20 and slowed_seen > 20, "awake %d, slowed %d" % [awake_seen, slowed_seen])


## The Gatecrasher here wakes itself, as Glimmertoad does, so the Bell beside its gate
## never slows its breaking (RULES 6.2, 7.7).
func test_a_breaker_that_is_awake_breaks_at_full_speed_rules_6_2_7_7() -> void:
	var spans: Array[int] = []
	for stats: Catalog in [Cx.catalog_with("gatecrasher", {"wake_reach": 150}), catalog]:
		var b: Battle = Cx.battle(Fx.TWO_SOCKET_GRID, [{"groups": [Fx.group("gatecrasher", 1)]}], {"gates": 1}, stats)
		assert_eq(b.place_gate(Vector2i(1, 4)), Battle.DONE)
		Tx.build(b, Vector2i(3, 4), &"lullaby_bell", 2)
		b.start_next_wave()
		var log: Array = Fx.log_ticks(b, 600)
		var started: Array = Fx.of_kind(log, &"break_started")
		var broken: Array = Fx.of_kind(log, &"gate_broken")
		assert_eq([started.size(), broken.size()], [1, 1])
		if started.size() == 1 and broken.size() == 1:
			spans.append(int(broken[0][0]) - int(started[0][0]))
	assert_eq(spans.size(), 2)
	if spans.size() == 2:
		assert_eq(spans[0], 80, "awake: 4.0 s at full speed")
		assert_true(spans[1] > 80, "not awake: the Bell slows the breaking, %d ticks" % spans[1])


func test_glimmertoad_cannot_be_slowed_and_wakes_within_2_tiles_rules_6_3() -> void:
	var b: Battle = _battle([Fx.group("glimmertoad", 1), Fx.group("scamp", 2, 0, 50)])
	_spawned(b, 3)
	var toad: EnemyState = _of(b, &"glimmertoad")[0]
	var scamps: Array[EnemyState] = _of(b, &"scamp")
	toad.pos = Vector2i(ROAD_X, 50000)
	scamps[0].pos = Vector2i(ROAD_X, 90000)            # exactly 2.0 tiles
	scamps[1].pos = Vector2i(ROAD_X, 90001)
	b._timer_step()
	assert_true(toad.awake and scamps[0].awake and not scamps[1].awake)
	Tx.build(b, Vector2i(2, 2), &"lullaby_bell", 2)
	b._ring_step()
	assert_eq(toad.slow_pct, 0, "no slow reaches it")


func test_glimmertoad_lets_6_flitters_out_at_half_health_rules_6_3() -> void:
	var b: Battle = _battle([Fx.group("glimmertoad", 1)])
	_spawned(b, 1)
	var toad: EnemyState = b.enemy_with_id(0)
	toad.health = 1801
	Tx.build(b, Vector2i(2, 2), &"sling_post")         # 6 damage less armor 4: 2 a hit
	var log: Array = Fx.log_ticks(b, 40)
	var released: Array = Fx.of_kind(log, &"released")
	assert_eq(released.size(), 1, "at 50%")
	if released.size() != 1:
		return
	var at: int = released[0][0]
	assert_eq([released[0][1]["enemy"], released[0][1]["count"]], [&"flitter", 6])
	var flitters: Array = []
	for entry: Array in Fx.of_kind(log, &"spawned"):
		if entry[1]["enemy"] == &"flitter":
			flitters.append(entry)
	assert_eq(Fx.ticks(flitters), [at + 1, at + 7, at + 13, at + 19, at + 25, at + 31] as Array[int], "6, from the next tick, 0.3 s apart")


# A napping creature does nothing (DM, 2026-10-27)

func test_a_napping_breaker_does_not_break_and_its_timer_pauses_dm_2026_10_27() -> void:
	var sleepy: Catalog = Cx.catalog_with("gatecrasher", {"nap_ms": 2000})
	var b: Battle = Cx.battle(Fx.TWO_SOCKET_GRID, [{"groups": [Fx.group("gatecrasher", 1)]}], {"gates": 1}, sleepy)
	assert_eq(b.place_gate(Vector2i(1, 4)), Battle.DONE)
	b.start_next_wave()
	var log: Array = []
	while b.tick < 400 and Fx.of_kind(log, &"break_started").is_empty():
		log.append_array(Fx.log_ticks(b, 1))
	var started: int = Fx.of_kind(log, &"break_started")[0][0]
	Fx.steps(b, 20)
	var e: EnemyState = b.enemy_with_id(0)
	var left: int = e.breaking
	assert_eq(left, 400000 - 20 * 5000, "20 ticks of breaking")
	_knock_down(b, e)
	var nap: Array = Fx.log_ticks(b, 39)
	assert_eq(e.breaking, left, "paused while it naps")
	assert_eq(Fx.of_kind(nap, &"gate_broken"), [])
	var rest: Array = Fx.log_ticks(b, 200)
	var broken: Array = Fx.of_kind(rest, &"gate_broken")
	assert_eq(broken.size(), 1)
	if broken.size() == 1:
		assert_eq(broken[0][0], started + 80 + 40, "4.0 s of breaking plus the 2.0 s nap")


func test_a_napping_summoner_pauses_its_summons_dm_2026_10_27() -> void:
	var sleepy: Catalog = Cx.catalog_with("grumblesack", {"nap_ms": 2000})
	var b: Battle = _battle([Fx.group("grumblesack", 1)], {}, sleepy)
	b.start_next_wave()
	Fx.steps(b, 100)
	var boss: EnemyState = b.enemy_with_id(0)
	assert_eq(boss.summon_at, 120)
	_knock_down(b, boss)
	b.take_events()
	var log: Array = Fx.log_ticks(b, 40)
	assert_eq(Fx.of_kind(log, &"released"), [], "no batch while it naps, though one was due at 120")
	assert_eq(boss.summon_at, 160, "20 ticks still to go, as when it fell asleep")
	log = Fx.log_ticks(b, 30)
	assert_eq(Fx.ticks(Fx.of_kind(log, &"released")), [160] as Array[int])
	assert_eq(boss.summon_at, 280, "then every 6.0 s again")


func test_a_napping_creature_releases_only_once_it_wakes_dm_2026_10_27() -> void:
	var sleepy: Catalog = Cx.catalog_with("glimmertoad", {"nap_ms": 2000})
	var b: Battle = _battle([Fx.group("glimmertoad", 1)], {}, sleepy)
	_spawned(b, 1)
	var toad: EnemyState = b.enemy_with_id(0)
	_knock_down(b, toad)
	assert_eq(toad.health, 1800, "it naps at half health, its release's mark")
	var events: Array[Dictionary] = b.take_events()
	assert_eq(Fx.events_of(events, &"released"), [] as Array[Dictionary], "no release as it falls asleep")
	var nap: Array = Fx.log_ticks(b, 39)
	assert_eq(Fx.of_kind(nap, &"released"), [], "nor while it naps")
	var at: int = b.tick
	var woke: Array = Fx.log_ticks(b, 1)
	assert_eq(Fx.ticks(Fx.of_kind(woke, &"woke")), [at] as Array[int])
	assert_eq(Fx.ticks(Fx.of_kind(woke, &"released")), [at] as Array[int], "the release begins the tick it wakes")
	var next: Array = Fx.log_ticks(b, 1)
	assert_eq(Fx.of_kind(next, &"spawned").size(), 1, "and its first Flitter comes on the next tick")


func test_a_napping_yawner_does_not_yawn_but_its_timer_moves_on_dm_2026_10_27() -> void:
	var sleepy: Catalog = Cx.catalog_with("yawner", {"nap_ms": 2000})
	var b: Battle = _battle([Fx.group("yawner", 1)], {}, sleepy)
	_spawned(b, 1)
	var e: EnemyState = b.enemy_with_id(0)
	e.pos = _at(3, 2)
	var sling: TowerState = Tx.build(b, Vector2i(2, 2), &"sling_post")
	_knock_down(b, e)
	b.take_events()
	e.yawn_at = b.tick
	b._timer_step()
	assert_eq(Fx.events_of(b.take_events(), &"yawned"), [] as Array[Dictionary])
	assert_eq(sling.doze_ticks, 0)
	assert_eq(e.yawn_at, b.tick + 80, "the timer moved on")


# The tick order and the events (RULES 8.1, docs/ARCHITECTURE.md 14.5, 14.6)

## One tick where a nap ends, a yawn and a blink are due and a tower then fires: the
## events come in the order of the steps.
func test_naps_end_then_yawns_land_then_blinks_then_shots_rules_8_1() -> void:
	var b: Battle = _battle([Fx.group("sleepyhead", 1), Fx.group("yawner", 1), Fx.group("blinker", 1), Fx.group("scamp", 1)])
	_spawned(b, 4)
	var sleepy: EnemyState = _of(b, &"sleepyhead")[0]
	var yawner: EnemyState = _of(b, &"yawner")[0]
	var blinker: EnemyState = _of(b, &"blinker")[0]
	Tx.build(b, Vector2i(4, 10), &"sling_post")
	_knock_down(b, sleepy)
	sleepy.nap_ticks = 1
	yawner.yawn_at = b.tick
	blinker.blink_at = b.tick
	_put(b, _of(b, &"scamp")[0], Vector2i(3, 9), Vector2i(3, 10), 0)
	b.take_events()
	b.step()
	var kinds: Array[StringName] = []
	for event: Dictionary in b.take_events():
		if [&"woke", &"yawned", &"blinked", &"fired"].has(event["kind"]):
			kinds.append(event["kind"])
	assert_eq(kinds, [&"woke", &"yawned", &"blinked", &"fired"] as Array[StringName])


func test_rules_of_regions_7_and_8_keep_nothing_when_their_creatures_are_absent_contract_14_12() -> void:
	var b: Battle = _battle([Fx.group("scamp", 20, 0, 100), Fx.group("flitter", 5, 0, 300)])
	Tx.build(b, Vector2i(2, 2), &"sling_post")
	Tx.build(b, Vector2i(2, 4), &"lullaby_bell")
	b.start_next_wave()
	Fx.steps(b, 60)
	assert_eq([b._yawners.size(), b._wakers.size(), b._blinkers], [0, 0, 0], "no lists for absent rules")
	assert_false(b._dozes_on or b._awake_set, "no doze pass, no wake pass")
	for e: EnemyState in b.enemies:
		assert_false(e.awake or e.grows)
	var c: Battle = _battle([Fx.group("snowroller", 1), Fx.group("yawner", 1), Fx.group("blinker", 1), Fx.group("hootling", 1),
		Fx.group("snowsnore", 1), Fx.group("glimmertoad", 1)])
	c.start_next_wave()
	c.step()
	assert_eq([c._yawners.size(), c._wakers.size(), c._blinkers], [2, 2, 2], "each creature joins its lists")
	for e: EnemyState in c.enemies:
		e.health = 0
	c._removed = true
	c._compact()
	assert_eq([c._yawners.size(), c._wakers.size(), c._blinkers], [0, 0, 0], "and leaves them")
