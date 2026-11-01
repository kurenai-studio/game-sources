# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Walkers on the node graph: bridges, slides, twin steps, tunnels and out of reach,
## loading steps, and save and restore on a map with every feature (docs/ARCHITECTURE.md
## 14.3, 14.5; RULES 3.6 to 3.9, 7.3, 7.8, 8.8).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")
const FEATURE_TOWERS: Array = ["sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower"]

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _battle(grid: Array, groups: Array, changes: Dictionary = {}) -> Battle:
	return Fx.battle(grid, [{"groups": groups}], changes, catalog)


## The cells a creature heads to, in order, one entry per change.
func _heads(b: Battle, id: int, limit: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	while b.phase == Battle.Phase.WAVE and b.tick < limit:
		b.step()
		var e: EnemyState = b.enemy_with_id(id)
		if e == null:
			break
		if out.is_empty() or out.back() != e.to_cell:
			out.append(e.to_cell)
	return out


func _in_tunnel(b: Battle, pos: Vector2i) -> bool:
	return b.level.feature_at(Sim.cell_of(pos)) == LevelData.Feature.TUNNEL


# Bridges (RULES 3.7)

func test_walkers_go_straight_across_a_bridge_rules_3_7() -> void:
	var b: Battle = _battle(Fx.BRIDGE_LOOP_GRID, [Fx.group("scamp", 1)])
	b.start_next_wave()
	var bridge: Vector2i = Vector2i(3, 3)
	var nodes: Array[int] = []
	var cells: Array[Vector2i] = [Vector2i(0, 3)]
	while b.phase == Battle.Phase.WAVE and b.tick < 2000:
		b.step()
		var e: EnemyState = b.enemy_with_id(0)
		if e == null:
			break
		if cells.back() != e.to_cell:
			cells.append(e.to_cell)
		if e.to_cell == bridge and (nodes.is_empty() or nodes.back() != e.to_node):
			nodes.append(e.to_node)
	assert_eq(cells, b.map.route(Vector2i(0, 3), b.map.distances([])), "the walker follows the route over and under")
	assert_eq(nodes, [b.map.node_of(bridge, true), b.map.node_of(bridge)] as Array[int], "east-west first, then north-south")
	assert_eq(b.lives, b.start_lives - 1, "it got through")


func test_a_walker_turns_back_on_its_bridge_road_when_a_gate_breaks_rules_7_8() -> void:
	var b: Battle = _battle(Fx.BRIDGE_GATE_GRID, [Fx.group("scamp", 1)], {"gates": 1})
	assert_eq(b.place_gate(Vector2i(4, 1)), Battle.DONE)
	b.start_next_wave()
	var bridge: Vector2i = Vector2i(3, 3)
	var e: EnemyState = null
	while b.tick < 500:
		b.step()
		e = b.enemy_with_id(0)
		if e != null and e.to_cell == bridge:
			break
	assert_not_null(e)
	if e == null:
		return
	assert_eq(e.to_node, b.map.node_of(bridge), "on the north-south road")
	# The gate breaks (as _break_tick does it): the way back north is now shorter, and the
	# east-west road beside it, shorter still, is not a step from the north-south node.
	b.gates[0].broken = true
	b._refresh_dist()
	assert_true(b._dist[b.map.node_of(bridge, true)] < b._dist[b.map.node_of(Vector2i(3, 2))], "the deck is closer to the base")
	var heads: Array[Vector2i] = _heads(b, 0, 2000)
	assert_eq(heads.slice(0, 5), [bridge, Vector2i(3, 2), Vector2i(3, 1), Vector2i(4, 1), Vector2i(5, 1)] as Array[Vector2i], "back north, then through the broken gate")
	assert_false(heads.has(Vector2i(2, 3)) or heads.has(Vector2i(4, 3)), "never off its bridge's road")
	assert_eq(b.lives, b.start_lives - 1, "it got through")


# Twin stumps (RULES 3.9)

func test_a_twin_step_takes_one_step_out_of_reach_then_lands_at_the_twin_rules_3_9() -> void:
	var b: Battle = _battle(Fx.STUMP_GRID, [Fx.group("scamp", 1)])
	b.start_next_wave()
	var a: Vector2i = Vector2i(3, 2)
	var twin: Vector2i = Vector2i(5, 5)
	var on_step: int = 0
	var landed_at: int = -1
	var leaked_at: int = -1
	while b.phase == Battle.Phase.WAVE and b.tick < 1000:
		var at: int = b.tick
		b.step()
		for event: Dictionary in b.take_events():
			if event["kind"] == &"leaked":
				leaked_at = at
		var e: EnemyState = b.enemy_with_id(0)
		if e == null:
			continue
		if e.from_cell == a and e.to_cell == twin:
			if e.progress < Sim.UNIT:
				on_step += 1
				assert_eq(e.pos, Sim.center(a), "it stands at the stump it entered")
				assert_true(e.out_of_reach, "out of reach for the whole step")
			else:
				landed_at = at
				assert_eq(e.pos, Sim.center(twin), "then it is at the twin's center")
				assert_eq(e.prev_pos, Sim.center(twin), "prev_pos holds where it landed")
				assert_false(e.out_of_reach)
		elif e.from_cell != a:
			assert_false(e.out_of_reach, "in reach off the twin step")
	assert_eq(on_step, 19, "one step's time: 20 ticks at speed 1, the last one landing")
	assert_eq(landed_at, 59)
	assert_eq(leaked_at, 159, "8 steps of 20 ticks: the twin step counts as one")


func test_nothing_is_drawn_across_a_jump_contract_14_3() -> void:
	# Pips move 1,200 sub-units a tick, so they land part way through a tick and walk on.
	var b: Battle = _battle(Fx.STUMP_GRID, [Fx.group("pip", 6, 0, 350)])
	b.start_next_wave()
	var jumps: int = 0
	var was: Dictionary = {}
	while b.phase == Battle.Phase.WAVE and b.tick < 1000:
		b.step()
		for e: EnemyState in b.enemies:
			var gap: Vector2i = Sim.cell_of(e.pos) - Sim.cell_of(e.prev_pos)
			assert_true(absi(gap.x) + absi(gap.y) <= 1, "pip %d at tick %d draws from %s to %s" % [e.id, b.tick, e.prev_pos, e.pos])
			if was.get(e.id, false) and not (e.from_cell == Vector2i(3, 2) and e.progress < Sim.UNIT):
				jumps += 1
				assert_eq(e.prev_pos, Sim.center(Vector2i(5, 5)), "the landing tick starts the line at the twin")
			was[e.id] = e.from_cell == Vector2i(3, 2) and e.to_cell == Vector2i(5, 5) and e.progress < Sim.UNIT
	assert_eq(jumps, 6, "every pip jumped once")


func test_a_release_that_begins_on_a_twin_step_takes_the_step_too_rules_3_9() -> void:
	# The Grumblesack moves 400 sub-units a tick. Its first summon, 120 ticks after it
	# appears, comes 8,000 sub-units into its third step: the twin step.
	var b: Battle = _battle(Fx.STUMP_GRID, [Fx.group("grumblesack", 1)])
	b.start_next_wave()
	var log: Array = Fx.log_ticks(b, 121)
	var released: Array = Fx.of_kind(log, &"released")
	assert_eq(released.size(), 1)
	assert_eq(released[0][0], 120)
	assert_eq(released[0][1]["pos"], Sim.center(Vector2i(3, 2)), "it begins at the stump it entered")
	var boss: EnemyState = b.enemy_with_id(0)
	assert_eq([boss.from_cell, boss.to_cell], [Vector2i(3, 2), Vector2i(5, 5)])
	var scamp: EnemyState = b.enemy_with_id(1)
	assert_not_null(scamp)
	if scamp == null:
		return
	assert_eq([scamp.from_cell, scamp.to_cell, scamp.progress], [Vector2i(3, 2), Vector2i(5, 5), 9000], "the boss's step, then one tick of its own")
	assert_eq(scamp.pos, Sim.center(Vector2i(3, 2)))
	assert_true(scamp.out_of_reach)
	Fx.steps(b, 10)
	assert_eq(scamp.progress, 19000)
	assert_true(scamp.out_of_reach)
	b.step()
	assert_eq(scamp.pos, Sim.center(Vector2i(5, 5)), "landed at the twin on tick 131")
	assert_false(scamp.out_of_reach)
	var second: EnemyState = b.enemy_with_id(2)
	assert_not_null(second, "the second of the batch came 6 ticks later")
	if second != null:
		assert_eq([second.from_cell, second.to_cell], [Vector2i(3, 2), Vector2i(5, 5)], "from the same spot")


# Tunnels and out of reach (RULES 3.6, 8.8)

func test_walkers_in_a_tunnel_are_out_of_reach_of_shots_splash_and_bells_rules_8_8() -> void:
	var b: Battle = _battle(Fx.TUNNEL_GRID, [Fx.group("scamp", 12, 0, 400)], {"towers": FEATURE_TOWERS, "start_gold": 5000})
	assert_eq(b.place_tower(Vector2i(4, 1), &"sling_post"), Battle.DONE)
	assert_eq(b.place_tower(Vector2i(4, 6), &"pumpkin_catapult"), Battle.DONE)
	assert_eq(b.place_tower(Vector2i(2, 3), &"lullaby_bell"), Battle.DONE)
	b.upgrade_tower(Vector2i(4, 6))
	b.start_next_wave()
	var health: Dictionary = {}
	var slow: Dictionary = {}
	var where: Dictionary = {}
	var shots: int = 0
	var inside: int = 0
	var slowed_inside: int = 0
	while b.phase == Battle.Phase.WAVE and b.tick < 3000:
		b.step()
		for event: Dictionary in b.take_events():
			if event["kind"] != &"fired":
				continue
			shots += 1
			for at: Vector2i in event["at"]:
				assert_false(_in_tunnel(b, at), "no tower aims into the tunnel")
		for e: EnemyState in b.enemies:
			assert_eq(e.out_of_reach, _in_tunnel(b, e.pos), "out of reach exactly in the tunnel")
			if e.out_of_reach:
				inside += 1
				if health.has(e.id):
					assert_eq(e.health, health[e.id], "no hit or splash reaches it")
			if where.has(e.id) and _in_tunnel(b, where[e.id]):
				# It stood in the tunnel at the rings step: its slow only runs down.
				var before: Array = slow[e.id]
				var left: int = maxi(int(before[1]) - 1, 0)
				assert_eq([e.slow_pct, e.slow_ticks], [before[0] if left > 0 else 0, left], "no Bell reaches it")
				if left > 0:
					slowed_inside += 1
			health[e.id] = e.health
			slow[e.id] = [e.slow_pct, e.slow_ticks]
			where[e.id] = e.pos
	assert_true(shots > 0, "towers hit walkers outside the tunnel")
	assert_true(inside > 50, "walkers spent time in the tunnel")
	assert_true(slowed_inside > 0, "a slow taken outside keeps running down inside")


# Loading steps (contract 14.3)

func _feature_battle(waves: Array = [{"groups": [Fx.group("scamp", 2, 0, 400)]}], relaxed: bool = false) -> Battle:
	return Fx.battle(Fx.FEATURE_GRID, waves, {"towers": FEATURE_TOWERS, "start_gold": 5000, "gates": 1}, catalog, relaxed)


func _mid_wave_data() -> Dictionary:
	var b: Battle = _feature_battle()
	b.start_next_wave()
	Fx.steps(b, 3)
	return JSON.parse_string(JSON.stringify(b.to_data()))


func _with_step(data: Dictionary, key: String, from: Vector2i, to: Vector2i, progress: int) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	var item: Dictionary = copy[key][0]
	item["from"] = [from.x, from.y]
	item["to"] = [to.x, to.y]
	item["progress"] = progress
	return copy


func _with_release(data: Dictionary, from: Vector2i, to: Vector2i, progress: int) -> Dictionary:
	var copy: Dictionary = data.duplicate(true)
	var tick: int = int(copy["tick"])
	copy["releases"] = [{"enemy": "puff", "wave": 0, "left": 2, "next": tick, "gap": 6,
		"from": [from.x, from.y], "to": [to.x, to.y], "progress": progress}]
	return copy


func test_a_saved_step_is_any_graph_step_and_nothing_else_contract_14_3() -> void:
	var data: Dictionary = _mid_wave_data()
	assert_not_null(Battle.from_data(data, catalog), "the plain save loads")
	var map: RoadMap = RoadMap.new(Fx.level(Fx.FEATURE_GRID, [{"groups": [Fx.group("scamp", 1)]}], {"towers": FEATURE_TOWERS}, catalog))
	var taken: int = 0
	var refused: int = 0
	for r: int in map.rows:
		for c: int in Sim.MAP_COLUMNS:
			var from: Vector2i = Vector2i(c, r)
			if not map.is_road(from):
				continue
			var near: Array[Vector2i] = [from + Vector2i(0, 1), from + Vector2i(-1, 0), from + Vector2i(1, 0), from + Vector2i(0, -1)]
			if map.twin_of(from) != Vector2i(-1, -1):
				near.append(map.twin_of(from))
			for to: Vector2i in near:
				if not map.is_road(to):
					continue
				for progress: int in [0, 7000, Sim.UNIT]:
					var loaded: Battle = Battle.from_data(_with_step(data, "enemies", from, to, progress), catalog)
					if map.is_step(from, to):
						assert_not_null(loaded, "a walker on the step %s to %s at %d" % [from, to, progress])
						if loaded != null:
							assert_eq(loaded.enemies[0].to_node, map.arrival(from, to), "to_node worked out on load")
						taken += 1
					else:
						assert_null(loaded, "no step %s to %s" % [from, to])
						refused += 1
	# 27 pairs of road neighbors make 54 neighbor steps; the slide keeps 3 of them out
	# ([5, 4] north, [5, 5] north, [5, 6] onto [5, 5]); the twins add 2.
	assert_eq(taken, 3 * 53, "every step of the graph, at three progresses")
	assert_eq(refused, 3 * 3, "only the three pairs of road neighbors that a slide keeps apart")
	# Named cases.
	var cases: Array = [
		[Vector2i(2, 3), Vector2i(3, 3), 5000, true, "onto the bridge from the west"],
		[Vector2i(3, 3), Vector2i(3, 4), 5000, true, "off the bridge south"],
		[Vector2i(3, 6), Vector2i(5, 9), 5000, true, "a twin step"],
		[Vector2i(5, 9), Vector2i(3, 6), Sim.UNIT, true, "the twin step back, done"],
		[Vector2i(5, 4), Vector2i(5, 5), 5000, true, "down the slide"],
		[Vector2i(3, 5), Vector2i(3, 5), Sim.UNIT, true, "standing at a center"],
		[Vector2i(3, 3), Vector2i(3, 3), Sim.UNIT, false, "standing still on a bridge"],
		[Vector2i(3, 5), Vector2i(3, 5), 5000, false, "standing still away from a center"],
		[Vector2i(5, 5), Vector2i(5, 4), 5000, false, "up the slide"],
		[Vector2i(5, 6), Vector2i(5, 5), 5000, false, "onto the slide against its arrow"],
		[Vector2i(3, 0), Vector2i(3, 2), 5000, false, "two cells apart"],
		[Vector2i(3, 6), Vector2i(5, 8), 5000, false, "a stump to a cell that is not its twin"],
		[Vector2i(3, 4), Vector2i(5, 9), 5000, false, "a road cell to a stump"],
		[Vector2i(2, 1), Vector2i(3, 1), 5000, false, "from a build spot"],
	]
	for case: Array in cases:
		var walker: Battle = Battle.from_data(_with_step(data, "enemies", case[0], case[1], case[2]), catalog)
		assert_eq(walker != null, case[3], "walker: " + String(case[4]))
		var release: Battle = Battle.from_data(_with_release(data, case[0], case[1], case[2]), catalog)
		assert_eq(release != null, case[3], "release: " + String(case[4]))
	# A release on a twin step spawns its walkers on that step.
	var b: Battle = Battle.from_data(_with_release(data, Vector2i(3, 6), Vector2i(5, 9), 5000), catalog)
	b.step()
	var puff: EnemyState = b.enemies.back()
	assert_eq([puff.type, puff.from_cell, puff.to_cell], [&"puff", Vector2i(3, 6), Vector2i(5, 9)])
	assert_eq(puff.to_node, b.map.node_of(Vector2i(5, 9)))
	assert_eq(puff.pos, Sim.center(Vector2i(3, 6)))


func test_a_saved_step_needs_an_open_route_on_contract_14_3() -> void:
	var b: Battle = _feature_battle()
	assert_eq(b.place_gate(Vector2i(5, 10)), Battle.DONE)
	b.start_next_wave()
	Fx.steps(b, 3)
	var data: Dictionary = JSON.parse_string(JSON.stringify(b.to_data()))
	assert_not_null(Battle.from_data(data, catalog))
	assert_null(Battle.from_data(_with_step(data, "enemies", Vector2i(5, 9), Vector2i(5, 10), 5000), catalog), "onto the closed socket")
	assert_null(Battle.from_data(_with_step(data, "enemies", Vector2i(5, 10), Vector2i(5, 11), 5000), catalog), "off it")
	assert_not_null(Battle.from_data(_with_step(data, "enemies", Vector2i(5, 8), Vector2i(5, 9), 5000), catalog), "to the stump before it: round by the twin")


func test_out_of_reach_is_worked_out_on_load_contract_14_5() -> void:
	var data: Dictionary = _mid_wave_data()
	var cases: Array = [
		[Vector2i(3, 1), Vector2i(3, 2), 10000, true, "in the tunnel"],
		[Vector2i(3, 0), Vector2i(3, 1), 5000, false, "before its mouth"],
		[Vector2i(3, 6), Vector2i(5, 9), 5000, true, "on a twin step"],
		[Vector2i(3, 6), Vector2i(5, 9), Sim.UNIT, false, "landed"],
		[Vector2i(3, 3), Vector2i(3, 4), 5000, false, "on a bridge: in reach"],
	]
	for case: Array in cases:
		var b: Battle = Battle.from_data(_with_step(data, "enemies", case[0], case[1], case[2]), catalog)
		assert_not_null(b, case[4])
		if b != null:
			assert_eq(b.enemies[0].out_of_reach, case[3], case[4])
	var twin: Battle = Battle.from_data(_with_step(data, "enemies", Vector2i(3, 6), Vector2i(5, 9), 5000), catalog)
	assert_eq(twin.enemies[0].pos, Sim.center(Vector2i(3, 6)), "a loaded twin step stands at the stump it entered")


func test_a_map_with_no_feature_never_sets_out_of_reach_contract_14_12() -> void:
	var b: Battle = Fx.battle(Fx.FORK_GRID, [{"groups": [Fx.group("scamp", 8, 0, 300)]}], {}, catalog)
	assert_false(b._reach_features)
	assert_false(b._has_stumps)
	b.start_next_wave()
	while b.phase == Battle.Phase.WAVE:
		b.step()
		for e: EnemyState in b.enemies:
			assert_false(e.out_of_reach)


# Save and restore with every feature (contract 14.13)

func _feature_level_battle() -> Battle:
	var waves: Array = [
		{"groups": [Fx.group("scamp", 8, 0, 600), Fx.group("scamp", 6, 1000, 700, 2), Fx.group("puffball", 3, 2000, 1500),
			Fx.group("flitter", 3, 1500, 500, 2)]},
		{"groups": [Fx.group("grumblesack", 1), Fx.group("gatecrasher", 2, 1500, 2000), Fx.group("mender", 2, 0, 1500, 2),
			Fx.group("pip", 12, 2000, 200, 2), Fx.group("bubbler", 3, 3000, 800)]},
		{"groups": [Fx.group("skitter", 6, 0, 400, 2), Fx.group("shellback", 3, 500, 1200)]},
	]
	return _feature_battle(waves, true)


func _act(b: Battle) -> void:
	if b.phase == Battle.Phase.BUILD:
		match b.waves_started:
			0:
				b.place_tower(Vector2i(2, 1), &"sling_post")
				b.place_tower(Vector2i(4, 5), &"pumpkin_catapult")
				b.place_tower(Vector2i(1, 5), &"lullaby_bell")
				b.place_tower(Vector2i(1, 8), &"longbow_loft")
				b.place_tower(Vector2i(4, 8), &"firework_tower")
			1:
				for cell: Vector2i in [Vector2i(2, 1), Vector2i(4, 5)]:
					b.upgrade_tower(cell)
				b.place_gate(Vector2i(5, 10))
			2:
				b.remove_gate(Vector2i(5, 10))
		b.start_next_wave()
		return
	if b.waves_started == 2 and b.next_wave_info()["refusal"] == &"" and b.tick % 40 == 0:
		b.start_next_wave()


func _play(save_every: int) -> Dictionary:
	var b: Battle = _feature_level_battle()
	var snaps: PackedStringArray = PackedStringArray()
	var events: PackedStringArray = PackedStringArray()
	var seen: Dictionary = {"tunnel": 0, "twin": 0, "across": 0}
	while (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE) and b.tick < 20000:
		_act(b)
		if b.phase != Battle.Phase.WAVE:
			break
		b.step()
		for event: Dictionary in b.take_events():
			events.append(var_to_str(event))
		for e: EnemyState in b.enemies:
			if e.flying:
				continue
			if _in_tunnel(b, e.pos):
				seen["tunnel"] += 1
			if e.to_cell == b.map.twin_of(e.from_cell):
				seen["twin"] += 1
			if e.to_node >= b.map.size():
				seen["across"] += 1
		if save_every > 0 and b.tick % save_every == 0 and (b.phase == Battle.Phase.BUILD or b.phase == Battle.Phase.WAVE):
			var before: String = Fx.snapshot(b)
			var copy: Battle = Fx.restored(b)
			if copy == null:
				fail("restore failed at tick %d" % b.tick)
				break
			assert_eq(Fx.snapshot(copy), before, "restore at tick %d is identical" % b.tick)
			for i: int in b.enemies.size():
				assert_eq(copy.enemies[i].out_of_reach, b.enemies[i].out_of_reach, "out of reach after load")
				assert_eq(copy.enemies[i].to_node, b.enemies[i].to_node, "to_node after load")
			b = copy
		if b.tick % 25 == 0:
			snaps.append(Fx.snapshot(b))
	snaps.append(Fx.snapshot(b))
	return {"snaps": snaps, "events": events, "result": b.result(), "tick": b.tick, "seen": seen}


func test_restore_on_a_map_with_every_feature_continues_identically_contract_14_13() -> void:
	var plain: Dictionary = _play(0)
	var text: String = "\n".join(plain["events"] as PackedStringArray)
	assert_true(text.contains("&\"gate_broken\""), "the Gatecrasher broke the gate from the stump")
	assert_true(text.contains("&\"released\""), "releases happened")
	var seen: Dictionary = plain["seen"]
	assert_true(int(seen["tunnel"]) > 0 and int(seen["twin"]) > 0 and int(seen["across"]) > 0, "walkers used every feature: %s" % seen)
	print("    sim: feature run ended at tick %d, result %s, seen %s" % [plain["tick"], str(plain["result"]), str(seen)])
	for every: int in [1, 7, 13]:
		var restored: Dictionary = _play(every)
		assert_eq(restored["snaps"], plain["snaps"], "restoring every %d ticks: same states" % every)
		assert_eq(restored["events"], plain["events"], "restoring every %d ticks: same events" % every)
		assert_eq(restored["result"], plain["result"])
