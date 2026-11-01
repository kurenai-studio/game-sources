# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Puffball splits, Mender heals, the Gatecrasher, broken gates and walkers changing
## route during a wave (RULES 6.2, 7.5 to 7.8, 8.1).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const ALL_TOWERS: Array = ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery"]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _battle(grid: Array, waves: Array, changes: Dictionary = {}, stats: Catalog = null) -> Battle:
	var all: Dictionary = {"start_gold": 9000, "towers": ALL_TOWERS}
	all.merge(changes, true)
	return Fx.battle(grid, waves, all, stats if stats != null else catalog)


# Splits.

func test_a_puffball_releases_its_puffs_where_it_fell_rules_6_2() -> void:
	var weak: Catalog = Fx.catalog_with_enemy("puffball", {"health": 1})
	var ball: EnemyType = weak.enemy(&"puffball")
	var gap: int = ball.split_gap_ms / Sim.MS_PER_TICK
	var b: Battle = _battle(Fx.LINE_GRID, [{"strength": 150, "groups": [Fx.group("puffball", 1)]}], {}, weak)
	b.start_next_wave()
	Fx.steps(b, 40)
	var step: Array = [b.enemy_with_id(0).from_cell, b.enemy_with_id(0).to_cell]
	b.place_tower(Vector2i(2, 3), &"sling_post")
	b.take_events()
	var log: Array = []
	var first: EnemyState = null
	for i: int in 60:
		var at: int = b.tick
		b.step()
		for event: Dictionary in b.take_events():
			log.append([at, event])
		for e: EnemyState in b.enemies:
			if first == null and e.type == ball.split_into:
				first = e
				assert_eq(first.wave, 0, "Puffs belong to the Puffball's wave")
				assert_eq(first.max_health, Sim.pct_half_up(weak.enemy(&"puff").health, 150), "and use its strength")
				assert_eq([first.from_cell, first.to_cell], step, "and finish the Puffball's step")
	assert_not_null(first, "a Puff appeared")
	var defeated: Array = Fx.of_kind(log, &"defeated")
	assert_eq(defeated[0][1]["enemy"], &"puffball")
	var fell_at: int = defeated[0][0]
	var spot: Vector2i = defeated[0][1]["pos"]
	var released: Array = Fx.of_kind(log, &"released")
	assert_eq(released.size(), 1)
	assert_eq(released[0][1], {"kind": &"released", "id": 0, "source": &"puffball", "enemy": ball.split_into, "count": ball.split_count, "pos": spot})
	var puffs: Array = []
	for entry: Array in Fx.of_kind(log, &"spawned"):
		if entry[1]["enemy"] == ball.split_into:
			puffs.append(entry)
	var expected: Array[int] = []
	for k: int in ball.split_count:
		expected.append(fell_at + 1 + k * gap)
	assert_eq(Fx.ticks(puffs), expected, "one at once (the next spawn step), then one every 0.3 s")
	for entry: Array in puffs:
		assert_eq(entry[1]["pos"], spot, "every Puff appears where the Puffball fell")


func test_a_puffball_that_gets_through_releases_nothing_rules_6_2() -> void:
	var b: Battle = _battle(Fx.LINE_GRID, [{"groups": [Fx.group("puffball", 1)]}])
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 2000)
	assert_eq(b.phase, Battle.Phase.WON)
	assert_eq(b.lives, catalog.rules.start_lives - catalog.enemy(&"puffball").lives)
	for entry: Array in Fx.of_kind(log, &"spawned"):
		assert_eq(entry[1]["enemy"], &"puffball", "no Puff")


func test_a_wave_waits_for_its_puffs_rules_4_1_and_6_2() -> void:
	var weak: Catalog = Fx.catalog_with_enemy("puffball", {"health": 1})
	var b: Battle = _battle(Fx.LINE_GRID, [{"groups": [Fx.group("puffball", 1)]}, {"groups": [Fx.group("scamp", 1)]}], {}, weak)
	b.place_tower(Vector2i(2, 1), &"sling_post")
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 2000)
	var last_puff: int = Fx.ticks(Fx.of_kind(log, &"spawned")).back()
	var cleared: Array = Fx.of_kind(log, &"wave_cleared")
	assert_eq(cleared.size(), 1)
	assert_true(cleared[0][0] >= last_puff, "cleared only once the Puffs are gone")


# Heals.

func test_a_mender_heals_others_near_it_every_2_seconds_rules_6_2() -> void:
	var mender: EnemyType = catalog.enemy(&"mender")
	var every: int = mender.heal_ms / Sim.MS_PER_TICK
	var amount: int = Sim.pct_half_up(mender.heal, 150)
	# Spawned together, by the first heal the Scamp is 0.6 tiles ahead of the Mender, the
	# Flitter 1 tile ahead and the Skitter 2.6 tiles ahead.
	var groups: Array = [Fx.group("mender", 1), Fx.group("scamp", 1), Fx.group("flitter", 1), Fx.group("skitter", 1), Fx.group("bubbler", 1)]
	var b: Battle = _battle(Fx.LINE_GRID, [{"strength": 150, "groups": groups}])
	b.start_next_wave()
	Fx.steps(b, every)
	for e: EnemyState in b.enemies:
		e.health = 1
	var full: EnemyState = b.enemy_with_id(4)
	full.health = full.max_health - 1
	var log: Array = Fx.log_ticks(b, 1)
	var healed: Array = Fx.of_kind(log, &"healed")
	assert_eq(healed.size(), 1, "the first heal comes 2.0 s after it appears")
	assert_eq(healed[0][0], every)
	assert_eq(healed[0][1], {"kind": &"healed", "id": 0, "ids": [1, 2, 4] as Array[int]})
	assert_eq(b.enemy_with_id(0).health, 1, "not itself")
	assert_eq(b.enemy_with_id(1).health, 1 + amount, "heal scaled by strength")
	assert_eq(b.enemy_with_id(2).health, 1 + amount, "flyers too")
	assert_eq(b.enemy_with_id(3).health, 1, "out of reach")
	assert_eq(b.enemy_with_id(4).health, b.enemy_with_id(4).max_health, "up to max health")
	assert_true(b.enemy_with_id(4).bubble, "a heal is not a hit: the bubble stays")
	assert_eq(Fx.ticks(Fx.of_kind(Fx.log_ticks(b, every), &"healed")), [every * 2] as Array[int], "and every 2.0 s after")


func test_menders_heal_bosses_and_each_heals_on_its_own_rules_6_2_and_8_7() -> void:
	var mender: EnemyType = catalog.enemy(&"mender")
	var every: int = mender.heal_ms / Sim.MS_PER_TICK
	var b: Battle = _battle(Fx.LINE_GRID, [{"groups": [Fx.group("grumblesack", 1), Fx.group("mender", 2, 0, 50)]}])
	b.start_next_wave()
	Fx.steps(b, every + 1)
	var boss: EnemyState = b.enemy_with_id(0)
	boss.health = 100
	Fx.steps(b, every)
	assert_eq(boss.health, 100 + 2 * mender.heal, "two Menders, two heals")


## A heal still reaches every creature in reach, but its event lists only the first
## Battle.HEAL_EVENT_IDS of them in id order, the most the map marks (contract 3.1).
func test_a_heal_event_lists_at_most_heal_event_ids_creatures() -> void:
	var wide: Catalog = Fx.catalog_with_enemy("mender", {"heal_reach": 1000})
	var mender: EnemyType = wide.enemy(&"mender")
	var every: int = mender.heal_ms / Sim.MS_PER_TICK
	var hurt: int = Battle.HEAL_EVENT_IDS + 4
	var b: Battle = _battle(Fx.LINE_GRID, [{"groups": [Fx.group("mender", 1), Fx.group("shellback", hurt, 0, 50)]}], {}, wide)
	b.start_next_wave()
	Fx.steps(b, every)
	assert_eq(b.enemies.size(), hurt + 1)
	for e: EnemyState in b.enemies:
		e.health = 1
	var healed: Array = Fx.of_kind(Fx.log_ticks(b, 1), &"healed")
	assert_eq(healed.size(), 1)
	var ids: Array[int] = []
	for id: int in range(1, Battle.HEAL_EVENT_IDS + 1):
		ids.append(id)
	assert_eq(healed[0][1], {"kind": &"healed", "id": 0, "ids": ids}, "the first %d in id order" % Battle.HEAL_EVENT_IDS)
	for id: int in range(1, hurt + 1):
		assert_eq(b.enemy_with_id(id).health, 1 + mender.heal, "creature %d healed all the same" % id)


# Gate breakers.

## Ticks for a creature to walk n tiles from a cell center at full speed: it gets there
## during the movement of the returned tick.
func _arrive(speed: int, tiles: int, start: int = 0) -> int:
	var per_tick: int = speed * 10
	return start + (tiles * Sim.UNIT + per_tick - 1) / per_tick - 1


func test_a_gatecrasher_breaks_the_gate_on_its_own_route_rules_7_7() -> void:
	var crasher: EnemyType = catalog.enemy(&"gatecrasher")
	var b: Battle = _battle(Fx.FORK_GRID, [{"groups": [Fx.group("gatecrasher", 1)]}], {"gates": 1})
	assert_eq(b.place_gate(Vector2i(1, 3)), Battle.DONE)
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 3000)
	# Its route ignores gates, so it goes west to [1, 2], 4 tiles, and stops there.
	var arrive: int = _arrive(crasher.speed, 4)
	var started: Array = Fx.of_kind(log, &"break_started")
	assert_eq(started.size(), 1)
	assert_eq(started[0], [arrive, {"kind": &"break_started", "id": 0, "cell": Vector2i(1, 3)}])
	var broken: Array = Fx.of_kind(log, &"gate_broken")
	assert_eq(broken.size(), 1)
	assert_eq(broken[0], [arrive + crasher.break_ms / Sim.MS_PER_TICK, {"kind": &"gate_broken", "cell": Vector2i(1, 3)}])
	assert_eq(b.phase, Battle.Phase.WON)
	assert_eq(b.lives, catalog.rules.start_lives - crasher.lives, "it walked on through the broken gate")


func test_breaking_shows_in_the_creature_numbers_rules_9_4() -> void:
	var crasher: EnemyType = catalog.enemy(&"gatecrasher")
	var b: Battle = _battle(Fx.FORK_GRID, [{"groups": [Fx.group("gatecrasher", 1)]}], {"gates": 1})
	b.place_gate(Vector2i(1, 3))
	b.start_next_wave()
	Fx.steps(b, _arrive(crasher.speed, 4) + 1)
	assert_eq(b.enemy_numbers(0)["breaking_ms"], crasher.break_ms)
	Fx.steps(b, 10)
	assert_eq(b.enemy_numbers(0)["breaking_ms"], crasher.break_ms - 500)
	assert_eq(b.enemy_with_id(0).pos, Sim.center(Vector2i(1, 2)), "it waits at the center before the gate")


func test_a_slow_slows_the_breaking_rules_7_7_and_8_5() -> void:
	var crasher: EnemyType = catalog.enemy(&"gatecrasher")
	var bell: TowerStats = Fx.stats(catalog, &"lullaby_bell", 1)
	var b: Battle = _battle(Fx.FORK_GRID, [{"groups": [Fx.group("gatecrasher", 1)]}], {"gates": 1})
	b.place_gate(Vector2i(1, 3))
	b.place_tower(Vector2i(0, 1), &"lullaby_bell")
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 3000)
	var started: int = Fx.of_kind(log, &"break_started")[0][0]
	var broken: int = Fx.of_kind(log, &"gate_broken")[0][0]
	var per_tick: int = Sim.MS_PER_TICK * (100 - bell.slow_pct)
	assert_eq(broken - started, (crasher.break_ms * 100 + per_tick - 1) / per_tick, "each second counts as %d%% of one" % (100 - bell.slow_pct))


func test_a_breaker_defeated_while_breaking_leaves_the_gate_closed_rules_7_7() -> void:
	var crasher: EnemyType = catalog.enemy(&"gatecrasher")
	var b: Battle = _battle(Fx.FORK_GRID, [{"groups": [Fx.group("gatecrasher", 1)]}], {"gates": 1})
	b.place_gate(Vector2i(1, 3))
	b.start_next_wave()
	Fx.steps(b, _arrive(crasher.speed, 4) + 20)
	assert_true(b.enemy_with_id(0).breaking > 0)
	b.enemy_with_id(0).health = 1
	b.place_tower(Vector2i(0, 1), &"sling_post")
	var log: Array = Fx.log_ticks(b, 3000)
	assert_eq(Fx.of_kind(log, &"gate_broken").size(), 0)
	assert_eq(Fx.of_kind(log, &"defeated").size(), 1)
	assert_eq(b.closed_cells(), [Vector2i(1, 3)] as Array[Vector2i], "the gate stays closed")


func test_two_breakers_at_one_gate_do_not_add_up_rules_7_7() -> void:
	var crasher: EnemyType = catalog.enemy(&"gatecrasher")
	var b: Battle = _battle(Fx.FORK_GRID, [{"groups": [Fx.group("gatecrasher", 2, 0, 1000)]}], {"gates": 1})
	b.place_gate(Vector2i(1, 3))
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 3000)
	var started: Array = Fx.of_kind(log, &"break_started")
	assert_eq(started.size(), 2, "each keeps its own timer")
	var broken: Array = Fx.of_kind(log, &"gate_broken")
	assert_eq(broken.size(), 1)
	assert_eq(broken[0][0], started[0][0] + crasher.break_ms / Sim.MS_PER_TICK, "the first timer to run out breaks it")
	assert_eq(b.lives, catalog.rules.start_lives - 2 * crasher.lives, "and both walk on")


func test_a_breaker_breaks_every_closed_gate_on_its_route_in_turn_rules_7_7() -> void:
	var crasher: EnemyType = catalog.enemy(&"gatecrasher")
	var b: Battle = _battle(Fx.TWO_SOCKET_GRID, [{"groups": [Fx.group("gatecrasher", 1)]}], {"gates": 2})
	assert_eq(b.place_gate(Vector2i(1, 4)), Battle.DONE)
	assert_eq(b.place_gate(Vector2i(1, 6)), Battle.DONE)
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 4000)
	var broken: Array = Fx.of_kind(log, &"gate_broken")
	assert_eq(broken.size(), 2)
	assert_eq([broken[0][1]["cell"], broken[1][1]["cell"]], [Vector2i(1, 4), Vector2i(1, 6)])
	var first: int = _arrive(crasher.speed, 5) + crasher.break_ms / Sim.MS_PER_TICK
	assert_eq(broken[0][0], first)
	assert_eq(broken[1][0], _arrive(crasher.speed, 2, first) + crasher.break_ms / Sim.MS_PER_TICK, "then 2 tiles on, the next one")


func test_walkers_take_the_new_route_when_a_gate_breaks_rules_7_8() -> void:
	# The Scamps take the east branch while [1, 3] is closed. Once it breaks, a Scamp at
	# [3, 2] picks the west branch again (the tie break).
	var b: Battle = _battle(Fx.FORK_GRID, [{"groups": [Fx.group("gatecrasher", 1), Fx.group("scamp", 20, 0, 500)]}], {"gates": 1})
	b.place_gate(Vector2i(1, 3))
	b.start_next_wave()
	var broke_at: int = -1
	var west_after: int = 0
	var east_before: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 4000:
		b.step()
		for event: Dictionary in b.take_events():
			if event["kind"] == &"gate_broken":
				broke_at = b.tick
		for e: EnemyState in b.enemies:
			if e.type != &"scamp" or e.from_cell != Vector2i(3, 2):
				continue
			if e.to_cell == Vector2i(4, 2) and broke_at < 0:
				east_before += 1
			if e.to_cell == Vector2i(2, 2) and broke_at >= 0:
				west_after += 1
	assert_true(broke_at > 0, "the gate broke")
	assert_true(east_before > 0, "east while the gate held")
	assert_true(west_after > 0, "west once it broke")


func test_a_walker_may_turn_back_when_a_gate_breaks_rules_7_8() -> void:
	# LOOP_GRID: the Gatecrasher breaks [0, 1] from the entrance at once. A Scamp sent
	# down the long road just before the gate breaks turns back at its next center.
	var crasher: EnemyType = catalog.enemy(&"gatecrasher")
	var breaks: int = crasher.break_ms / Sim.MS_PER_TICK
	var b: Battle = _battle(Fx.LOOP_GRID, [{"groups": [Fx.group("gatecrasher", 1), Fx.group("scamp", 1, (breaks - 30) * Sim.MS_PER_TICK)]}], {"gates": 1})
	b.place_gate(Vector2i(0, 1))
	b.start_next_wave()
	var cells: Array[Vector2i] = []
	while b.phase == Battle.Phase.WAVE and b.tick < 2000:
		b.step()
		var scamp: EnemyState = b.enemy_with_id(1)
		if scamp != null and (cells.is_empty() or cells.back() != scamp.to_cell):
			cells.append(scamp.to_cell)
	assert_eq(cells.slice(0, 4), [Vector2i(1, 0), Vector2i(2, 0), Vector2i(1, 0), Vector2i(0, 0)] as Array[Vector2i], "east, then back west")
	assert_true(cells.has(Vector2i(0, 2)), "down the short road through the broken gate")


func test_broken_gates_mend_when_the_build_phase_begins_rules_7_6() -> void:
	var b: Battle = _battle(Fx.FORK_GRID, [{"groups": [Fx.group("gatecrasher", 1)]}, {"groups": [Fx.group("scamp", 1)]}], {"gates": 1, "star3": {"kind": "gates_whole"}})
	b.place_gate(Vector2i(1, 3))
	b.start_next_wave()
	while b.phase == Battle.Phase.WAVE:
		b.step()
		if b.gates[0].broken:
			assert_eq(b.closed_cells().size(), 0, "a broken gate is open to every walker")
			assert_eq(b.stars_possible() & 4, 0, "Use every gate and keep them whole: lost")
	assert_eq(b.phase, Battle.Phase.BUILD)
	assert_false(b.gates[0].broken, "mended, closed, on the same socket")
	assert_eq(b.closed_cells(), [Vector2i(1, 3)] as Array[Vector2i])
	assert_eq(b.routes(b.closed_cells())[0]["walk"][3], Vector2i(4, 2), "walkers go east again")


func test_route_lines_show_the_breaker_route_and_its_cracks_rules_7_5() -> void:
	var waves: Array = [{"groups": [Fx.group("scamp", 1)]}, {"groups": [Fx.group("gatecrasher", 1)]}]
	var b: Battle = _battle(Fx.FORK_GRID, waves, {"gates": 1})
	b.place_gate(Vector2i(1, 3))
	var lines: Array[Dictionary] = b.routes(b.closed_cells())
	assert_eq(lines[0]["break"].size(), 0, "no breaker in the next wave")
	b.start_next_wave()
	Fx.run_wave(b)
	lines = b.routes(b.closed_cells())
	var free_route: Array[Vector2i] = b.map.route(Vector2i(3, 0), b.map.distances([]))
	assert_eq(lines[0]["break"], free_route, "the route with no gates")
	assert_eq(lines[0]["cracks"], [Vector2i(1, 3)] as Array[Vector2i], "a crack on the closed gate it would break")
	assert_false((lines[0]["walk"] as Array).has(Vector2i(1, 3)), "the walkers' line goes around")
	var drag: Array[Dictionary] = b.routes([Vector2i(5, 5)] as Array[Vector2i])
	assert_eq(drag[0]["cracks"].size(), 0, "a gate dragged off its route leaves nothing to break")


func test_flyers_never_break_gates_rules_6_5() -> void:
	var b: Battle = _battle(Fx.FORK_GRID, [{"groups": [Fx.group("dusk_moth", 2, 0, 500)]}], {"gates": 1})
	b.place_gate(Vector2i(1, 3))
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 3000)
	assert_eq(Fx.of_kind(log, &"break_started").size(), 0)
	assert_eq(Fx.of_kind(log, &"gate_broken").size(), 0)
