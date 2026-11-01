# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## The map feature rules that are level design rules, not load checks (RULES 3.5 to 3.9, 14.2;
## docs/ARCHITECTURE.md 14.2, 14.13). Used on campaign levels and on assembled run maps, so a
## run map is checked across the seams between its segments.

## RULES 3.6: a map has at most 6 tunnel tiles, and a tunnel is 1 to 4 tiles long.
const MAX_TUNNEL_TILES: int = 6
const MAX_TUNNEL_RUN: int = 4
## RULES 3.6: tunnels hold at most a quarter of the steps of any entrance's shortest route with no gates.
const TUNNEL_SHARE_DIVISOR: int = 4
## RULES 3.7: a map has at most 3 bridges.
const MAX_BRIDGES: int = 3
## RULES 3.8: slides come in straight runs of 2 or more tiles.
const MIN_SLIDE_RUN: int = 2
## RULES 3.5: the feature each grid character belongs to.
const FEATURE_KINDS: Dictionary = {"T": "tunnel", "X": "bridge", "^": "slide", "v": "slide", "<": "slide", ">": "slide", "P": "stump", "Q": "stump"}
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]


static func tunnel_tiles(level: LevelData) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for r: int in level.rows:
		for c: int in Sim.MAP_COLUMNS:
			var cell: Vector2i = Vector2i(c, r)
			if level.feature_at(cell) == LevelData.Feature.TUNNEL:
				out.append(cell)
	return out


## The tunnels of a map: each one the list of its tiles, joined north, south, east or west.
static func tunnels(level: LevelData) -> Array[Array]:
	var tiles: Array[Vector2i] = tunnel_tiles(level)
	var done: Dictionary = {}
	var out: Array[Array] = []
	for start: Vector2i in tiles:
		if done.has(start):
			continue
		var run: Array[Vector2i] = []
		var todo: Array[Vector2i] = [start]
		done[start] = true
		while not todo.is_empty():
			var cell: Vector2i = todo.pop_back()
			run.append(cell)
			for side: Vector2i in SIDES:
				var next: Vector2i = cell + side
				if tiles.has(next) and not done.has(next):
					done[next] = true
					todo.append(next)
		run.sort()
		out.append(run)
	return out


## Every way the tunnels of `level` break RULES 3.6, one line each. Empty when they keep every rule.
static func tunnel_problems(level: LevelData) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var tiles: Array[Vector2i] = tunnel_tiles(level)
	if tiles.size() > MAX_TUNNEL_TILES:
		out.append("%d tunnel tiles, at most %d" % [tiles.size(), MAX_TUNNEL_TILES])
	for run: Array in tunnels(level):
		var rows: Dictionary = {}
		var columns: Dictionary = {}
		for cell: Vector2i in run:
			rows[cell.y] = true
			columns[cell.x] = true
		if run.size() > MAX_TUNNEL_RUN:
			out.append("the tunnel at %s is %d tiles, at most %d" % [run[0], run.size(), MAX_TUNNEL_RUN])
		if rows.size() > 1 and columns.size() > 1:
			out.append("the tunnel at %s bends" % run[0])
		# Each tile has exactly two road neighbors, on opposite sides, in the line of its tunnel.
		var along_column: bool = columns.size() == 1 and rows.size() > 1
		var along_row: bool = rows.size() == 1 and columns.size() > 1
		for cell: Vector2i in run:
			var up: bool = level.is_road(cell + Vector2i.UP)
			var down: bool = level.is_road(cell + Vector2i.DOWN)
			var left: bool = level.is_road(cell + Vector2i.LEFT)
			var right: bool = level.is_road(cell + Vector2i.RIGHT)
			var vertical: bool = up and down and not left and not right
			var horizontal: bool = left and right and not up and not down
			if not vertical and not horizontal:
				out.append("tunnel tile %s is a fork, a bend or a dead end" % cell)
			elif (along_column and not vertical) or (along_row and not horizontal):
				out.append("tunnel tile %s does not run in the line of its tunnel" % cell)
	for cell: Vector2i in tiles:
		for side: Vector2i in SIDES:
			if level.sockets.has(cell + side):
				out.append("tunnel tile %s is next to the socket %s" % [cell, cell + side])
	if not tiles.is_empty():
		var map: RoadMap = RoadMap.new(level)
		var none: Array[Vector2i] = []
		var dist: PackedInt32Array = map.distances(none)
		for i: int in level.entrances.size():
			var route: Array[Vector2i] = map.route(level.entrances[i], dist)
			var steps: int = route.size() - 1
			var under: int = 0
			for cell: Vector2i in route:
				if tiles.has(cell):
					under += 1
			if under * TUNNEL_SHARE_DIVISOR > steps:
				out.append("entrance %d: %d of %d steps in tunnels, at most a quarter" % [i + 1, under, steps])
	return out


static func bridge_tiles(level: LevelData) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for r: int in level.rows:
		for c: int in Sim.MAP_COLUMNS:
			var cell: Vector2i = Vector2i(c, r)
			if level.feature_at(cell) == LevelData.Feature.BRIDGE:
				out.append(cell)
	return out


## Every way the bridges of `level` break RULES 3.7, one line each. Empty when they keep every rule: each
## bridge has four road neighbors, so it is never on the map edge; a map has at most 3; and no two bridges
## are neighbors, so a plain road tile lies between two.
static func bridge_problems(level: LevelData) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var tiles: Array[Vector2i] = bridge_tiles(level)
	if tiles.size() > MAX_BRIDGES:
		out.append("%d bridges, at most %d" % [tiles.size(), MAX_BRIDGES])
	for cell: Vector2i in tiles:
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if not level.is_road(next):
				out.append("bridge %s has no road at %s" % [cell, next])
			elif tiles.has(next):
				out.append("bridge %s is next to the bridge %s" % [cell, next])
	return out


## RULES 3.7 level guide: the bridges that lie on no entrance's shortest route for any placement of up to
## `gates` gates that seals nothing. Empty when every bridge always matters.
static func bridges_off_every_route(level: LevelData, gates: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = bridge_tiles(level)
	if tiles.is_empty():
		return tiles
	var map: RoadMap = RoadMap.new(level)
	var sets: Array[Array] = []
	gate_sets(level.sockets, gates, 0, [], sets)
	var crossed: Dictionary = {}
	for placed: Array in sets:
		var closed: Array[Vector2i] = []
		closed.assign(placed)
		if map.seals(closed):
			continue
		var dist: PackedInt32Array = map.distances(closed)
		for entrance: Vector2i in level.entrances:
			for cell: Vector2i in map.route(entrance, dist):
				if tiles.has(cell):
					crossed[cell] = true
	var out: Array[Vector2i] = []
	for cell: Vector2i in tiles:
		if not crossed.has(cell):
			out.append(cell)
	return out


## How a route crosses each bridge, in order: "over" for the east-west road on the deck, "under" for the
## north-south road. A route lists a bridge cell once for each crossing (docs/ARCHITECTURE.md 14.3).
static func crossings(level: LevelData, route: Array[Vector2i]) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for i: int in range(1, route.size() - 1):
		if level.feature_at(route[i]) != LevelData.Feature.BRIDGE:
			continue
		out.append("over" if route[i - 1].y == route[i].y else "under")
	return out


static func slide_tiles(level: LevelData) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for r: int in level.rows:
		for c: int in Sim.MAP_COLUMNS:
			var cell: Vector2i = Vector2i(c, r)
			if level.feature_at(cell) == LevelData.Feature.SLIDE:
				out.append(cell)
	return out


## The slide runs of a map: each one the list of its tiles, joined north, south, east or west.
static func slide_runs(level: LevelData) -> Array[Array]:
	var tiles: Array[Vector2i] = slide_tiles(level)
	var done: Dictionary = {}
	var out: Array[Array] = []
	for start: Vector2i in tiles:
		if done.has(start):
			continue
		var run: Array[Vector2i] = []
		var todo: Array[Vector2i] = [start]
		done[start] = true
		while not todo.is_empty():
			var cell: Vector2i = todo.pop_back()
			run.append(cell)
			for side: Vector2i in SIDES:
				var next: Vector2i = cell + side
				if tiles.has(next) and not done.has(next):
					done[next] = true
					todo.append(next)
		run.sort()
		out.append(run)
	return out


## Every way the slides of `level` break RULES 3.8, one line each. Empty when they keep every rule: each run of
## slide tiles is straight, 2 or more tiles long, with every arrow the same and pointing along the run; the tile
## each arrow points to is road; and with no gates every slide tile still reaches the base, so no slide is a
## dead end.
static func slide_problems(level: LevelData) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	for run: Array in slide_runs(level):
		var first: Vector2i = run[0]
		var way: Vector2i = level.slide_dir(first)
		if run.size() < MIN_SLIDE_RUN:
			out.append("the slide at %s is %d tile long, at least %d" % [first, run.size(), MIN_SLIDE_RUN])
		for cell: Vector2i in run:
			if level.slide_dir(cell) != way:
				out.append("the slide run at %s mixes arrows at %s" % [first, cell])
			# Along the run: every tile lies on the line through the first tile in the arrow's direction.
			var along: Vector2i = cell - first
			var crosswise: int = along.x * way.y - along.y * way.x
			if crosswise != 0:
				out.append("the slide run at %s bends at %s, or its arrows point across it" % [first, cell])
	var map: RoadMap = RoadMap.new(level)
	var none: Array[Vector2i] = []
	var dist: PackedInt32Array = map.distances(none)
	for cell: Vector2i in slide_tiles(level):
		var next: Vector2i = cell + level.slide_dir(cell)
		if not level.is_road(next):
			out.append("slide %s points at %s, which is not road" % [cell, next])
		if dist[map.node_of(cell)] < 0:
			out.append("slide %s is a dead end with no gates" % cell)
	return out


## RULES 3.8 and the bridge rule of 3.7 for slides: the slide tiles that lie on no entrance's shortest route for
## any placement of up to `gates` gates that seals nothing. Empty when every slide is walked by some placement.
static func slides_off_every_route(level: LevelData, gates: int) -> Array[Vector2i]:
	var tiles: Array[Vector2i] = slide_tiles(level)
	if tiles.is_empty():
		return tiles
	var map: RoadMap = RoadMap.new(level)
	var sets: Array[Array] = []
	gate_sets(level.sockets, gates, 0, [], sets)
	var walked: Dictionary = {}
	for placed: Array in sets:
		var closed: Array[Vector2i] = []
		closed.assign(placed)
		if map.seals(closed):
			continue
		var dist: PackedInt32Array = map.distances(closed)
		for entrance: Vector2i in level.entrances:
			for cell: Vector2i in map.route(entrance, dist):
				if tiles.has(cell):
					walked[cell] = true
	var out: Array[Vector2i] = []
	for cell: Vector2i in tiles:
		if not walked.has(cell):
			out.append(cell)
	return out


## The slide tiles a route walks.
static func slides_walked(level: LevelData, route: Array[Vector2i]) -> int:
	var count: int = 0
	for cell: Vector2i in route:
		if level.feature_at(cell) == LevelData.Feature.SLIDE:
			count += 1
	return count


## RULES 3.9: a map has at most 2 pairs of hollow stumps.
const MAX_STUMP_PAIRS: int = 2
const STUMP_CHARS: String = "PQ"


static func stump_tiles(level: LevelData) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for r: int in level.rows:
		for c: int in Sim.MAP_COLUMNS:
			var cell: Vector2i = Vector2i(c, r)
			if level.feature_at(cell) == LevelData.Feature.STUMP:
				out.append(cell)
	return out


## The stump pairs of a map, each [stump, twin] in cell order, one per letter.
static func stump_pairs(level: LevelData) -> Array[Array]:
	var by_letter: Dictionary = {}
	for cell: Vector2i in stump_tiles(level):
		var ch: String = level.grid[cell.y][cell.x]
		if not by_letter.has(ch):
			by_letter[ch] = []
		(by_letter[ch] as Array).append(cell)
	var out: Array[Array] = []
	for i: int in STUMP_CHARS.length():
		if by_letter.has(STUMP_CHARS[i]):
			out.append(by_letter[STUMP_CHARS[i]])
	return out


## Every way the stumps of `level` break RULES 3.9, one line each. Empty when they keep every rule: each letter
## twice or not at all, at most 2 pairs, twins never next to each other, and each stump's twin is the other stump
## of its letter.
static func stump_problems(level: LevelData) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var pairs: Array[Array] = stump_pairs(level)
	if pairs.size() > MAX_STUMP_PAIRS:
		out.append("%d pairs of stumps, at most %d" % [pairs.size(), MAX_STUMP_PAIRS])
	var map: RoadMap = RoadMap.new(level)
	for pair: Array in pairs:
		if pair.size() != 2:
			out.append("the stumps at %s are not one pair" % [pair])
			continue
		var a: Vector2i = pair[0]
		var b: Vector2i = pair[1]
		if absi(a.x - b.x) + absi(a.y - b.y) == 1:
			out.append("the twins %s and %s are next to each other" % [a, b])
		if map.twin_of(a) != b or map.twin_of(b) != a:
			out.append("the stumps %s and %s are not twins" % [a, b])
	return out


## The twin steps a route takes: each pair of cells in a row that are not neighbors (docs/ARCHITECTURE.md 14.3).
static func twin_steps(route: Array[Vector2i]) -> int:
	var count: int = 0
	for i: int in range(1, route.size()):
		if absi(route[i].x - route[i - 1].x) + absi(route[i].y - route[i - 1].y) > 1:
			count += 1
	return count


## RULES 3.9 level guide: the stump pairs whose twin step no entrance's shortest route takes, for any placement of up
## to `gates` gates that seals nothing. Each pair is given by its first stump. Empty when every pair matters.
static func stump_pairs_off_every_route(level: LevelData, gates: int) -> Array[Vector2i]:
	var pairs: Array[Array] = stump_pairs(level)
	var out: Array[Vector2i] = []
	if pairs.is_empty():
		return out
	var map: RoadMap = RoadMap.new(level)
	var sets: Array[Array] = []
	gate_sets(level.sockets, gates, 0, [], sets)
	var stepped: Dictionary = {}
	for placed: Array in sets:
		var closed: Array[Vector2i] = []
		closed.assign(placed)
		if map.seals(closed):
			continue
		var dist: PackedInt32Array = map.distances(closed)
		for entrance: Vector2i in level.entrances:
			var route: Array[Vector2i] = map.route(entrance, dist)
			for i: int in range(1, route.size()):
				if absi(route[i].x - route[i - 1].x) + absi(route[i].y - route[i - 1].y) > 1:
					stepped[mini(route[i].y * Sim.MAP_COLUMNS + route[i].x, route[i - 1].y * Sim.MAP_COLUMNS + route[i - 1].x)] = true
	for pair: Array in pairs:
		var a: Vector2i = pair[0]
		if not stepped.has(a.y * Sim.MAP_COLUMNS + a.x):
			out.append(a)
	return out


## The kinds of feature a map holds ("tunnel", "bridge", "slide", "stump"), each once, in reading order.
static func feature_kinds(grid: PackedStringArray) -> PackedStringArray:
	var out: PackedStringArray = PackedStringArray()
	var chars: String = feature_chars(grid)
	for i: int in chars.length():
		var kind: String = FEATURE_KINDS[chars[i]]
		if not out.has(kind):
			out.append(kind)
	return out


## The feature grid characters a map holds, each once, in reading order.
static func feature_chars(grid: PackedStringArray) -> String:
	var out: String = ""
	for line: String in grid:
		for i: int in line.length():
			var ch: String = line[i]
			if "TX^v<>PQ".contains(ch) and not out.contains(ch):
				out += ch
	return out


## Every placement of up to `left` gates on `sockets`, the empty one included.
static func gate_sets(sockets: Array[Vector2i], left: int, start: int, current: Array, out: Array[Array]) -> void:
	out.append(current.duplicate())
	if left == 0:
		return
	for i: int in range(start, sockets.size()):
		var next: Array = current.duplicate()
		next.append(sockets[i])
		gate_sets(sockets, left - 1, i + 1, next, out)
