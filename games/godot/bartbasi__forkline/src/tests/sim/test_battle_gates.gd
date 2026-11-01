# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Gates in battle: place, move, remove, the seal check, locking during waves, walkers
## following the open route, and route lines (RULES 7; docs/ARCHITECTURE.md 4).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _fork(gate_count: int, waves: Array = []) -> Battle:
	var list: Array = waves if not waves.is_empty() else [{"groups": [Fx.group("scamp", 1)]}, {"groups": [Fx.group("scamp", 1)]}]
	return Fx.battle(Fx.FORK_GRID, list, {"gates": gate_count}, catalog)


func test_place_move_and_remove_rules_7_2() -> void:
	var b: Battle = _fork(2)
	assert_eq(b.place_gate(Vector2i(2, 2)), &"not_a_socket", "a road cell")
	assert_eq(b.place_gate(Vector2i(0, 1)), &"not_a_socket", "a build spot")
	assert_eq(b.place_gate(Vector2i(1, 3)), Battle.DONE)
	assert_eq(b.gates_in_hand, 1)
	assert_eq(b.place_gate(Vector2i(1, 3)), &"has_gate")
	assert_eq(b.closed_cells(), [Vector2i(1, 3)] as Array[Vector2i])
	assert_eq(b.remove_gate(Vector2i(5, 5)), &"no_gate")
	assert_eq(b.move_gate(Vector2i(5, 5), Vector2i(1, 3)), &"no_gate")
	assert_eq(b.move_gate(Vector2i(1, 3), Vector2i(3, 3)), &"not_a_socket")
	assert_eq(b.remove_gate(Vector2i(1, 3)), Battle.DONE, "removing is always allowed")
	assert_eq(b.gates_in_hand, 2)
	var events: Array[Dictionary] = b.take_events()
	assert_eq(events, [{"kind": &"gate_placed", "cell": Vector2i(1, 3)}, {"kind": &"gate_removed", "cell": Vector2i(1, 3)}] as Array[Dictionary])
	var one: Battle = _fork(1)
	one.place_gate(Vector2i(1, 3))
	assert_eq(one.place_gate(Vector2i(5, 5)), &"no_gates_left")


func test_refused_when_it_would_seal_every_road_rules_7_4() -> void:
	var b: Battle = _fork(2)
	assert_eq(b.place_gate(Vector2i(1, 3)), Battle.DONE)
	var before: String = Fx.snapshot(b)
	b.take_events()
	assert_eq(b.place_gate(Vector2i(5, 5)), &"would_seal")
	assert_eq(Fx.snapshot(b), before, "a refusal changes nothing")
	assert_eq(b.take_events().size(), 0)
	assert_true(b.seals([Vector2i(1, 3), Vector2i(5, 5)] as Array[Vector2i]))
	assert_false(b.seals([Vector2i(5, 5)] as Array[Vector2i]))


func test_a_move_is_checked_on_its_result_rules_7_2() -> void:
	var b: Battle = _fork(1)
	b.place_gate(Vector2i(1, 3))
	b.take_events()
	# Closing [5, 5] while [1, 3] is closed would seal, but the move opens [1, 3] at the same moment.
	assert_eq(b.move_gate(Vector2i(1, 3), Vector2i(5, 5)), Battle.DONE)
	assert_eq(b.closed_cells(), [Vector2i(5, 5)] as Array[Vector2i])
	assert_eq(b.take_events(), [{"kind": &"gate_removed", "cell": Vector2i(1, 3)}, {"kind": &"gate_placed", "cell": Vector2i(5, 5)}] as Array[Dictionary])
	var triple: Battle = Fx.battle(Fx.TRIPLE_GRID, [{"groups": [Fx.group("scamp", 1)]}], {"gates": 3}, catalog)
	assert_eq(triple.place_gate(Vector2i(0, 3)), Battle.DONE)
	assert_eq(triple.place_gate(Vector2i(3, 3)), Battle.DONE)
	assert_eq(triple.place_gate(Vector2i(6, 3)), &"would_seal", "the third branch is the last road")
	assert_eq(triple.move_gate(Vector2i(0, 3), Vector2i(6, 3)), Battle.DONE, "a move leaves the west branch open")
	assert_eq(triple.move_gate(Vector2i(6, 3), Vector2i(3, 3)), &"has_gate")
	assert_eq(triple.gates_in_hand, 1)


func test_gates_lock_during_waves_rules_7_6() -> void:
	var b: Battle = _fork(1)
	b.place_gate(Vector2i(1, 3))
	b.start_next_wave()
	assert_eq(b.place_gate(Vector2i(5, 5)), &"gates_locked")
	assert_eq(b.move_gate(Vector2i(1, 3), Vector2i(5, 5)), &"gates_locked")
	assert_eq(b.remove_gate(Vector2i(1, 3)), &"gates_locked", "even while paused")
	Fx.run_wave(b)
	assert_eq(b.phase, Battle.Phase.BUILD)
	assert_eq(b.move_gate(Vector2i(1, 3), Vector2i(5, 5)), Battle.DONE, "free again in the next build phase")


func test_walkers_take_the_shortest_open_route_rules_7_3() -> void:
	for pair: Array in [[Vector2i(-1, -1), Vector2i(1, 5)], [Vector2i(1, 3), Vector2i(5, 5)], [Vector2i(5, 5), Vector2i(1, 5)]]:
		var b: Battle = _fork(1)
		if pair[0] != Vector2i(-1, -1):
			b.place_gate(pair[0])
		b.start_next_wave()
		var seen: Array[Vector2i] = []
		while b.phase == Battle.Phase.WAVE:
			b.step()
			for e: EnemyState in b.enemies:
				if not seen.has(e.to_cell):
					seen.append(e.to_cell)
		assert_true(seen.has(pair[1]), "gate %s: walks past %s" % [pair[0], pair[1]])
		assert_false(seen.has(pair[0]), "never onto a closed gate")


func test_route_lines_rules_7_5() -> void:
	var waves: Array = [{"groups": [Fx.group("scamp", 1)]}, {"groups": [Fx.group("flitter", 1, 0, 1000, 2), Fx.group("scamp", 1)]}]
	var b: Battle = Fx.battle(Fx.TRIPLE_GRID, waves, {"gates": 1}, catalog)
	var lines: Array[Dictionary] = b.routes(b.closed_cells())
	assert_eq(lines.size(), 2, "one entry per entrance")
	assert_eq(lines[0]["entrance"], 1)
	assert_eq(lines[1]["entrance"], 2)
	assert_eq(lines[0]["walk"][0], Vector2i(0, 0))
	assert_eq(lines[0]["walk"].back(), Vector2i(3, 9))
	assert_true((lines[0]["walk"] as Array).has(Vector2i(0, 5)), "entrance A goes down the west branch")
	assert_eq(lines[0]["walk"], b.map.route(Vector2i(0, 0), b.map.distances([])), "exactly the walker route")
	assert_eq([lines[0]["fly"], lines[1]["fly"]], [false, false], "wave 1 has no flyers")
	assert_eq(lines[0]["break"], [] as Array[Vector2i])
	assert_eq(lines[0]["cracks"], [] as Array[Vector2i])
	# While a gate is dragged: the would-be closed set.
	var drag: Array[Dictionary] = b.routes([Vector2i(0, 3)] as Array[Vector2i])
	assert_false((drag[0]["walk"] as Array).has(Vector2i(0, 5)))
	assert_true((drag[0]["walk"] as Array).has(Vector2i(3, 5)), "the middle branch instead")
	# Sealed: an empty walk line.
	var sealed: Array[Dictionary] = b.routes([Vector2i(0, 3), Vector2i(3, 3), Vector2i(6, 3)] as Array[Vector2i])
	assert_eq(sealed[0]["walk"].size(), 0)
	b.start_next_wave()
	Fx.run_wave(b)
	lines = b.routes(b.closed_cells())
	assert_eq([lines[0]["fly"], lines[1]["fly"]], [false, true], "the next wave's flyers come from entrance B")


func test_distances_follow_gate_changes_in_build_rules_7_3() -> void:
	var b: Battle = _fork(1)
	assert_eq(b.routes(b.closed_cells())[0]["walk"][3], Vector2i(2, 2), "west with no gate")
	b.place_gate(Vector2i(1, 3))
	assert_eq(b.routes(b.closed_cells())[0]["walk"][3], Vector2i(4, 2), "east with the west closed")
	b.move_gate(Vector2i(1, 3), Vector2i(5, 5))
	assert_eq(b.routes(b.closed_cells())[0]["walk"][3], Vector2i(2, 2))
	b.remove_gate(Vector2i(5, 5))
	assert_eq(b._dist, b.map.distances([]))
