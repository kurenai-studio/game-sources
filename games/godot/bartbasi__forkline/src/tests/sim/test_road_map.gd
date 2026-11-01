# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Routing on forked test maps: distances, the tie break, the seal check and routes
## (RULES 7.3, 7.4; docs/ARCHITECTURE.md 4).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

var catalog: Catalog = null


func before_each() -> void:
	catalog = Fx.catalog()


func _map(grid: Array) -> RoadMap:
	return RoadMap.new(Fx.level(grid, [{"groups": [Fx.group("scamp", 1)]}], {}, catalog))


func test_distances_count_steps_to_the_base_rules_7_3() -> void:
	var map: RoadMap = _map(Fx.FORK_GRID)
	var dist: PackedInt32Array = map.distances([])
	assert_eq(dist.size(), 70)
	assert_eq(dist[map.index(Vector2i(3, 9))], 0, "the base is 0")
	assert_eq(dist[map.index(Vector2i(3, 8))], 1)
	assert_eq(dist[map.index(Vector2i(3, 0))], 13, "both branches are 13 steps")
	assert_eq(dist[map.index(Vector2i(0, 0))], -1, "scenery is -1")
	assert_eq(dist[map.index(Vector2i(0, 1))], -1, "a build spot is not road")
	var closed: Array[Vector2i] = [Vector2i(1, 3)]
	dist = map.distances(closed)
	assert_eq(dist[map.index(Vector2i(1, 3))], -1, "a closed socket is cut off")
	assert_eq(dist[map.index(Vector2i(1, 2))], 13, "the west branch now goes round by the east")
	assert_eq(dist[map.index(Vector2i(3, 0))], 13)


## A crossing at [3, 2] with road on all four sides. Since contract 14.3 only real steps
## count, so the tie test needs a cell whose four neighbors are all road.
const PLUS_GRID: Array = [
	"...1...",
	"...#...",
	".#####.",
	".#.#.#.",
	".#.#.#.",
	".#.#.#.",
	".#####.",
	"...B...",
]


func test_tie_break_order_is_south_west_east_north_rules_7_3() -> void:
	var map: RoadMap = _map(PLUS_GRID)
	var cell: Vector2i = Vector2i(3, 2)
	var dist: PackedInt32Array = PackedInt32Array()
	dist.resize(map.size())
	dist.fill(-1)
	dist[map.index(cell)] = 5
	var south: Vector2i = cell + Vector2i(0, 1)
	var west: Vector2i = cell + Vector2i(-1, 0)
	var east: Vector2i = cell + Vector2i(1, 0)
	var north: Vector2i = cell + Vector2i(0, -1)
	for near: Vector2i in [south, west, east, north]:
		dist[map.index(near)] = 4
	# Contract 14.3: next_node() takes the place of next_step(). With no feature a cell's node is its index.
	var node: int = map.node_of(cell)
	assert_eq(map.node_cell(map.next_node(node, dist)), south, "south first")
	dist[map.index(south)] = 6
	assert_eq(map.node_cell(map.next_node(node, dist)), west, "then west")
	dist[map.index(west)] = -1
	assert_eq(map.node_cell(map.next_node(node, dist)), east, "then east")
	dist[map.index(east)] = 5
	assert_eq(map.node_cell(map.next_node(node, dist)), north, "then north")
	dist[map.index(north)] = 3
	assert_eq(map.next_node(node, dist), node, "no neighbor exactly one less: stays")


func test_forked_map_tie_break_sends_walkers_west_rules_7_3() -> void:
	# Contract 2.4: with no gate the two 13 step branches tie and walkers go west.
	var map: RoadMap = _map(Fx.FORK_GRID)
	var path: Array[Vector2i] = map.route(Vector2i(3, 0), map.distances([]))
	assert_eq(path.size(), 14)
	assert_eq(path[0], Vector2i(3, 0))
	assert_eq(path[3], Vector2i(2, 2), "turns west at the fork")
	assert_true(path.has(Vector2i(1, 5)), "walks the west branch")
	assert_false(path.has(Vector2i(5, 5)))
	assert_eq(path.back(), Vector2i(3, 9))
	var closed: Array[Vector2i] = [Vector2i(1, 3)]
	path = map.route(Vector2i(3, 0), map.distances(closed))
	assert_true(path.has(Vector2i(5, 5)), "a gate on the west socket sends them east")
	assert_eq(path.size(), 14)
	# On the triple map, entrance 1 meets a south and east tie at [0, 2] and goes south.
	var triple: RoadMap = _map(Fx.TRIPLE_GRID)
	var left: Array[Vector2i] = triple.route(Vector2i(0, 0), triple.distances([]))
	assert_eq(left[3], Vector2i(0, 3), "south beats east")


func test_seal_check_on_forks_rules_7_4() -> void:
	var map: RoadMap = _map(Fx.FORK_GRID)
	assert_false(map.seals([]))
	assert_false(map.seals([Vector2i(1, 3)] as Array[Vector2i]))
	assert_false(map.seals([Vector2i(5, 5)] as Array[Vector2i]))
	assert_true(map.seals([Vector2i(1, 3), Vector2i(5, 5)] as Array[Vector2i]), "both branches closed")
	var triple: RoadMap = _map(Fx.TRIPLE_GRID)
	assert_false(triple.seals([Vector2i(0, 3), Vector2i(3, 3)] as Array[Vector2i]), "one branch left open")
	assert_true(triple.seals([Vector2i(0, 3), Vector2i(3, 3), Vector2i(6, 3)] as Array[Vector2i]), "all three closed")
	assert_true(triple.seals([Vector2i(3, 9)] as Array[Vector2i]), "a closed base seals")


func test_route_is_empty_when_cut_off_rules_7_4() -> void:
	var map: RoadMap = _map(Fx.FORK_GRID)
	var closed: Array[Vector2i] = [Vector2i(1, 3), Vector2i(5, 5)]
	assert_eq(map.route(Vector2i(3, 0), map.distances(closed)).size(), 0)
	assert_eq(map.route(Vector2i(0, 0), map.distances([])).size(), 0, "from scenery")
	assert_eq(map.route(Vector2i(-3, 40), map.distances([])).size(), 0, "from outside")
