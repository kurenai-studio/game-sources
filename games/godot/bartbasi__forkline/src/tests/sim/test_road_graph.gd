# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Map features in the level checks and the node graph: bridges, slides, stumps and
## tunnels (docs/ARCHITECTURE.md 14.2, 14.3; RULES 3.5 to 3.9, 7.3, 7.4).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _level(grid: Array, changes: Dictionary = {}) -> LevelData:
	return Fx.level(grid, [{"groups": [Fx.group("scamp", 1)]}], changes, catalog)


func _map(grid: Array) -> RoadMap:
	return RoadMap.new(_level(grid))


func _problems(grid: Array, changes: Dictionary = {}) -> PackedStringArray:
	return LevelData.check(Fx.level_data(grid, [{"groups": [Fx.group("scamp", 1)]}], changes), catalog)


## Distance of a cell's node (its north-south one on a bridge).
func _d(map: RoadMap, dist: PackedInt32Array, cell: Vector2i, across: bool = false) -> int:
	return dist[map.node_of(cell, across)]


# The level checks (14.2)

func test_every_feature_character_loads_as_road_contract_14_2() -> void:
	var level: LevelData = _level(Fx.FEATURE_GRID)
	assert_not_null(level, "a map with every feature loads")
	if level == null:
		return
	var want: Dictionary = {
		Vector2i(3, 1): LevelData.Feature.TUNNEL, Vector2i(3, 3): LevelData.Feature.BRIDGE,
		Vector2i(5, 4): LevelData.Feature.SLIDE, Vector2i(3, 6): LevelData.Feature.STUMP,
		Vector2i(5, 9): LevelData.Feature.STUMP, Vector2i(3, 4): LevelData.Feature.NONE,
		Vector2i(5, 10): LevelData.Feature.NONE, Vector2i(3, 0): LevelData.Feature.NONE,
		Vector2i(4, 12): LevelData.Feature.NONE, Vector2i(2, 1): LevelData.Feature.NONE,
		Vector2i(0, 0): LevelData.Feature.NONE, Vector2i(-1, 3): LevelData.Feature.NONE,
		Vector2i(3, 13): LevelData.Feature.NONE,
	}
	for cell: Vector2i in want:
		assert_eq(level.feature_at(cell), want[cell], "feature at %s" % cell)
	for cell: Vector2i in [Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(5, 4), Vector2i(5, 5), Vector2i(3, 6), Vector2i(5, 9)]:
		assert_eq(level.kind_at(cell), LevelData.Kind.ROAD, "a feature is a road tile: %s" % cell)
		assert_true(level.is_road(cell))
	assert_eq(level.sockets, [Vector2i(5, 10)] as Array[Vector2i], "a feature is never a socket")
	# Each character, one at a time, on the line map. Some of them cut the line (a slide
	# that points off it), but none is an unknown character.
	for ch: String in ["T", "X", "^", "v", "<", ">", "P", "Q"]:
		var grid: Array = Fx.LINE_GRID.duplicate()
		grid[4] = "...%s..." % ch
		assert_false(_has(_problems(grid), "unknown character"), "%s is a known character" % ch)
		var raw: LevelData = LevelData.new()
		raw.grid = PackedStringArray(grid)
		raw.rows = grid.size()
		assert_eq(raw.kind_at(Vector2i(3, 4)), LevelData.Kind.ROAD, ch)
	assert_true(_has(_problems(["...1...", "...#...", "...Z...", "...#...", "...#...", "...#...", "...#...", "...B..."]), "unknown character"), "Z is not")
	for ch: String in LevelData.ROAD_CHARS:
		assert_true(LevelData.GRID_CHARS.contains(ch), "%s is a grid character" % ch)
	assert_eq(LevelData.ROAD_CHARS, "#G1234BTX^v<>PQ")


func test_slide_dir_gives_each_arrow_its_way_out_contract_14_2() -> void:
	var grid: Array = ["...1...", "...#...", ".>>v...", ".^.v...", ".^<<...", "...#...", "...#...", "...B..."]
	# Not a map that routes well; only the arrows matter here, so read it unchecked.
	var level: LevelData = LevelData.new()
	level.grid = PackedStringArray(grid)
	level.rows = grid.size()
	assert_eq(level.slide_dir(Vector2i(1, 2)), Vector2i(1, 0), "> east")
	assert_eq(level.slide_dir(Vector2i(3, 2)), Vector2i(0, 1), "v south")
	assert_eq(level.slide_dir(Vector2i(1, 3)), Vector2i(0, -1), "^ north")
	assert_eq(level.slide_dir(Vector2i(2, 4)), Vector2i(-1, 0), "< west")
	assert_eq(level.slide_dir(Vector2i(3, 1)), Vector2i.ZERO, "plain road")
	assert_eq(level.slide_dir(Vector2i(0, 0)), Vector2i.ZERO, "scenery")
	assert_eq(level.slide_dir(Vector2i(9, 2)), Vector2i.ZERO, "outside")
	assert_eq(level.feature_at(Vector2i(1, 2)), LevelData.Feature.SLIDE)


func test_stumps_come_in_twins_that_are_not_neighbors_contract_14_2() -> void:
	assert_eq(_problems(Fx.STUMP_GRID).size(), 0, "one pair of P")
	var q_pair: Array = Fx.STUMP_GRID.duplicate()
	q_pair[2] = ".##Q##."
	q_pair[5] = ".#...Q."
	assert_eq(_problems(q_pair).size(), 0, "one pair of Q")
	var both: Array = Fx.FEATURE_GRID.duplicate()
	both[1] = "..oQ..."
	both[7] = "...Q.#."
	assert_eq(_problems(both).size(), 0, "a P pair and a Q pair")
	var one: Array = Fx.STUMP_GRID.duplicate()
	one[5] = ".#...#."
	assert_true(_has(_problems(one), "P must appear exactly twice"), "a single P")
	var three: Array = Fx.STUMP_GRID.duplicate()
	three[6] = ".#...P."
	assert_true(_has(_problems(three), "P must appear exactly twice"), "three P")
	var near: Array = Fx.STUMP_GRID.duplicate()
	near[2] = ".#PP##."
	near[5] = ".#...#."
	assert_true(_has(_problems(near), "must not be neighbors"), "twins side by side")
	var below: Array = Fx.LINE_GRID.duplicate()
	below[3] = "..oQo.."
	below[4] = "...Q..."
	assert_true(_has(_problems(below), "must not be neighbors"), "twins one above the other")


func test_a_level_offers_up_to_ten_towers_contract_14_2() -> void:
	assert_eq(LevelData.MAX_TOWER_KINDS, 10)
	var files: Array = Fx.stats_files()
	var ids: Array = []
	var base_tower: Dictionary = files[0]["towers"][0]
	for i: int in 11 - (files[0]["towers"] as Array).size():
		var extra: Dictionary = base_tower.duplicate(true)
		extra["id"] = "extra_tower_%d" % i
		extra["specs"][0]["id"] = "extra_path_a_%d" % i
		extra["specs"][1]["id"] = "extra_path_b_%d" % i
		files[0]["towers"].append(extra)
	var big: Catalog = Catalog.from_data(files[0], files[1], files[2])
	assert_not_null(big, "a catalog with 11 towers")
	if big == null:
		return
	for id: StringName in big.tower_ids():
		ids.append(String(id))
	assert_eq(ids.size(), 11)
	var data: Dictionary = Fx.level_data(Fx.LINE_GRID, [{"groups": [Fx.group("scamp", 1)]}], {"towers": ids.slice(0, 10)})
	assert_eq(LevelData.check(data, big).size(), 0, "10 towers")
	var level: LevelData = LevelData.from_data(data, big)
	assert_eq(level.towers.size(), 10)
	data["towers"] = ids
	assert_true(LevelData.check(data, big).size() > 0, "11 towers are refused")
	data["towers"] = []
	assert_true(LevelData.check(data, big).size() > 0, "none is refused")


func _has(problems: PackedStringArray, text: String) -> bool:
	for line: String in problems:
		if line.contains(text):
			return true
	return false


# The node graph (14.3)

func test_a_map_with_no_feature_has_one_node_per_cell_contract_14_3() -> void:
	var map: RoadMap = _map(Fx.FORK_GRID)
	assert_eq(map.node_count(), 70)
	for r: int in 10:
		for c: int in 7:
			var cell: Vector2i = Vector2i(c, r)
			assert_eq(map.node_of(cell), map.index(cell) if map.is_road(cell) else -1)
			assert_eq(map.node_of(cell, true), map.node_of(cell), "across changes nothing off a bridge")
	assert_eq(map.node_cell(23), Vector2i(2, 3))
	assert_eq(map.node_cell(70), Vector2i(-1, -1))
	assert_eq(map.node_cell(-1), Vector2i(-1, -1))
	assert_eq(map.twin_of(Vector2i(3, 0)), Vector2i(-1, -1))


func test_a_bridge_is_two_nodes_and_walkers_go_straight_across_rules_3_7() -> void:
	var map: RoadMap = _map(Fx.BRIDGE_LOOP_GRID)
	var bridge: Vector2i = Vector2i(3, 3)
	assert_eq(map.node_count(), 8 * 7 + 1)
	assert_eq(map.node_of(bridge), 3 * 7 + 3, "the north-south node keeps the cell's id")
	assert_eq(map.node_of(bridge, true), 8 * 7, "the first bridge's east-west node is rows * 7")
	assert_eq(map.node_cell(8 * 7), bridge)
	var dist: PackedInt32Array = map.distances([])
	assert_eq(dist.size(), 57)
	assert_eq(_d(map, dist, bridge), 3, "the north-south road: 3 steps to the base")
	assert_eq(_d(map, dist, bridge, true), 11, "the east-west road goes round the loop")
	assert_eq(_d(map, dist, Vector2i(0, 3)), 14, "14 steps, not 4: the roads do not join")
	var path: Array[Vector2i] = map.route(Vector2i(0, 3), dist)
	assert_eq(path, [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), bridge, Vector2i(4, 3), Vector2i(5, 3),
		Vector2i(5, 4), Vector2i(5, 5), Vector2i(4, 5), Vector2i(3, 5), Vector2i(3, 4), bridge, Vector2i(3, 2),
		Vector2i(3, 1), Vector2i(3, 0)] as Array[Vector2i], "over the deck, round, then under it")
	# Steps: straight on each axis, never a turn.
	assert_eq(map.arrival(Vector2i(2, 3), bridge), map.node_of(bridge, true), "from the west: the east-west node")
	assert_eq(map.arrival(Vector2i(3, 4), bridge), map.node_of(bridge), "from the south: the north-south node")
	assert_eq(map.arrival(bridge, Vector2i(4, 3)), map.node_of(Vector2i(4, 3)))
	assert_eq(map.next_node(map.node_of(bridge, true), dist), map.node_of(Vector2i(4, 3)), "east-west goes on east")
	assert_eq(map.next_node(map.node_of(bridge), dist), map.node_of(Vector2i(3, 2)), "north-south goes on north")
	assert_eq(map.arrival(bridge, bridge), map.node_of(bridge), "from == to gives the cell's node")
	assert_true(map.under_bridge(Vector2i(3, 4), bridge), "north under the deck")
	assert_true(map.under_bridge(bridge, Vector2i(3, 2)))
	assert_false(map.under_bridge(Vector2i(2, 3), bridge), "east-west runs over it")
	assert_false(map.under_bridge(Vector2i(3, 1), Vector2i(3, 2)), "no bridge at either end")


func test_slides_go_one_way_rules_3_8() -> void:
	var up: RoadMap = _map(Fx.SLIDE_UP_GRID)
	var dist: PackedInt32Array = up.distances([])
	assert_eq(_d(up, dist, Vector2i(5, 2)), 12, "not down the slide: round by the west")
	assert_eq(_d(up, dist, Vector2i(5, 3)), 13, "a slide's one way out is north")
	assert_eq(_d(up, dist, Vector2i(5, 4)), 14)
	assert_eq(_d(up, dist, Vector2i(5, 5)), 5, "joining the slide from its tail is a step, but not a shorter one")
	assert_false(up.is_step(Vector2i(5, 2), Vector2i(5, 3)), "never onto a slide against its arrow")
	assert_false(up.is_step(Vector2i(5, 3), Vector2i(5, 4)), "never off a slide but its arrow's way")
	assert_true(up.is_step(Vector2i(5, 4), Vector2i(5, 3)), "along the arrow")
	assert_true(up.is_step(Vector2i(5, 5), Vector2i(5, 4)), "onto the slide's tail")
	assert_true(up.is_step(Vector2i(5, 3), Vector2i(5, 2)), "off its head")
	var down: RoadMap = _map(Fx.SLIDE_DOWN_GRID)
	dist = down.distances([])
	assert_eq(_d(down, dist, Vector2i(5, 2)), 8, "down the slide")
	assert_eq(_d(down, dist, Vector2i(5, 5)), 5)
	assert_false(down.is_step(Vector2i(5, 5), Vector2i(5, 4)), "never up it")
	var closed: Array[Vector2i] = [Vector2i(1, 3)]
	var path: Array[Vector2i] = down.route(Vector2i(3, 0), down.distances(closed))
	assert_eq(path, [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(5, 3),
		Vector2i(5, 4), Vector2i(5, 5), Vector2i(5, 6), Vector2i(5, 7), Vector2i(4, 7), Vector2i(3, 7), Vector2i(3, 8)] as Array[Vector2i])
	assert_false(down.seals(closed))


func test_a_gate_is_refused_when_the_only_way_left_runs_up_a_slide_rules_3_8() -> void:
	var waves: Array = [{"groups": [Fx.group("scamp", 1)]}]
	var up: Battle = Fx.battle(Fx.SLIDE_UP_GRID, waves, {"gates": 1}, catalog)
	assert_true(up.seals([Vector2i(1, 3)] as Array[Vector2i]), "the east branch looks joined but runs up a slide")
	assert_eq(up.place_gate(Vector2i(1, 3)), &"would_seal")
	assert_eq(up.gates.size(), 0, "nothing changed")
	assert_eq(up.gates_in_hand, 1)
	var down: Battle = Fx.battle(Fx.SLIDE_DOWN_GRID, waves, {"gates": 1}, catalog)
	assert_eq(down.place_gate(Vector2i(1, 3)), Battle.DONE, "with the slide going down it is a way")
	assert_true((down.routes(down.closed_cells())[0]["walk"] as Array).has(Vector2i(5, 4)))


func test_twin_stumps_are_joined_by_one_step_both_ways_rules_3_9() -> void:
	var map: RoadMap = _map(Fx.STUMP_GRID)
	var a: Vector2i = Vector2i(3, 2)
	var b: Vector2i = Vector2i(5, 5)
	assert_eq(map.twin_of(a), b)
	assert_eq(map.twin_of(b), a)
	assert_eq(map.twin_of(Vector2i(3, 1)), Vector2i(-1, -1))
	assert_true(map.is_step(a, b))
	assert_true(map.is_step(b, a))
	assert_eq(map.arrival(a, b), map.node_of(b))
	assert_false(map.is_step(a, Vector2i(5, 4)), "only to the twin")
	assert_false(map.is_step(Vector2i(3, 1), b), "only from a stump")
	assert_eq(map.node_count(), 63, "a stump is one node")
	var dist: PackedInt32Array = map.distances([])
	assert_eq(_d(map, dist, a), 6, "by the twin step")
	assert_eq(_d(map, dist, Vector2i(3, 0)), 8)
	assert_eq(map.route(Vector2i(3, 0), dist), [Vector2i(3, 0), Vector2i(3, 1), a, b, Vector2i(5, 6), Vector2i(5, 7),
		Vector2i(4, 7), Vector2i(3, 7), Vector2i(3, 8)] as Array[Vector2i], "two cells in a row that are twins")


func test_the_twin_step_comes_last_in_the_tie_order_rules_7_3() -> void:
	var map: RoadMap = _map(Fx.STUMP_GRID)
	var stump: Vector2i = Vector2i(3, 2)
	var node: int = map.node_of(stump)
	var west: Vector2i = Vector2i(2, 2)
	var east: Vector2i = Vector2i(4, 2)
	var north: Vector2i = Vector2i(3, 1)
	var twin: Vector2i = Vector2i(5, 5)
	var dist: PackedInt32Array = PackedInt32Array()
	dist.resize(map.node_count())
	dist.fill(-1)
	dist[node] = 5
	for near: Vector2i in [west, east, north, twin]:
		dist[map.node_of(near)] = 4
	assert_eq(map.node_cell(map.next_node(node, dist)), west, "west first (no road south)")
	dist[map.node_of(west)] = 6
	assert_eq(map.node_cell(map.next_node(node, dist)), east, "then east")
	dist[map.node_of(east)] = -1
	assert_eq(map.node_cell(map.next_node(node, dist)), north, "then north")
	dist[map.node_of(north)] = 5
	assert_eq(map.node_cell(map.next_node(node, dist)), twin, "the twin step last")
	dist[map.node_of(twin)] = 3
	assert_eq(map.next_node(node, dist), node, "none exactly one less: stays")


func test_tunnels_change_no_route_rules_3_6() -> void:
	var tunnel: RoadMap = _map(Fx.TUNNEL_GRID)
	var line: RoadMap = _map(Fx.LINE_GRID)
	assert_eq(tunnel.distances([]), line.distances([]))
	assert_eq(tunnel.route(Vector2i(3, 0), tunnel.distances([])), line.route(Vector2i(3, 0), line.distances([])))


func test_every_feature_map_routes_every_node_to_the_base_contract_14_3() -> void:
	# A node with a distance d above 0 always has a step to a node with d - 1.
	for grid: Array in [Fx.FEATURE_GRID, Fx.BRIDGE_GATE_GRID, Fx.BRIDGE_LOOP_GRID, Fx.SLIDE_UP_GRID, Fx.STUMP_GRID]:
		var map: RoadMap = _map(grid)
		var dist: PackedInt32Array = map.distances([])
		for node: int in map.node_count():
			if dist[node] <= 0:
				continue
			var next: int = map.next_node(node, dist)
			assert_eq(dist[next], dist[node] - 1, "node %d of %s" % [node, grid[0]])
			assert_true(map.is_step(map.node_cell(node), map.node_cell(next)) or map.node_cell(node) == map.node_cell(next), "a real step")
	var map: RoadMap = _map(Fx.FEATURE_GRID)
	var dist: PackedInt32Array = map.distances([])
	assert_eq(map.route(Vector2i(3, 0), dist), [Vector2i(3, 0), Vector2i(3, 1), Vector2i(3, 2), Vector2i(3, 3), Vector2i(3, 4),
		Vector2i(3, 5), Vector2i(3, 6), Vector2i(5, 9), Vector2i(5, 10), Vector2i(5, 11), Vector2i(4, 11), Vector2i(4, 12)] as Array[Vector2i])
	assert_eq(map.route(Vector2i(0, 3), dist), [Vector2i(0, 3), Vector2i(1, 3), Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3),
		Vector2i(5, 3), Vector2i(5, 4), Vector2i(5, 5), Vector2i(5, 6), Vector2i(5, 7), Vector2i(5, 8), Vector2i(5, 9),
		Vector2i(5, 10), Vector2i(5, 11), Vector2i(4, 11), Vector2i(4, 12)] as Array[Vector2i])
	var gated: PackedInt32Array = map.distances([Vector2i(5, 10)] as Array[Vector2i])
	var round_path: Array[Vector2i] = map.route(Vector2i(0, 3), gated)
	assert_eq(round_path.slice(10, 14), [Vector2i(5, 8), Vector2i(5, 9), Vector2i(3, 6), Vector2i(3, 7)] as Array[Vector2i], "the twin step the other way")
	assert_false(map.seals([Vector2i(5, 10)] as Array[Vector2i]))
