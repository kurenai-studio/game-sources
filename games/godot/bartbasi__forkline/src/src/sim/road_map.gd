# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name RoadMap
extends RefCounted
## Routing on a level's node graph (docs/ARCHITECTURE.md 4 and 14.3, RULES 7.3 and 7.4).
##
## Every road cell is a node, with the id row * 7 + column. On a bridge that node is the
## north-south road, and the k-th bridge in cell order also has an east-west node, with
## the id rows * 7 + k. Every step is one step long: a neighbor step, which leaves its
## cell on the step's axis and arrives on the same axis, or a twin step between stumps.
## A slide has one way out, its arrow's, and no step goes onto a slide from the cell its
## arrow points to. Distances are steps to the base per node. On a map with no feature
## they are exactly the steps per cell of before.

## The tie break order: south, west, east, north (RULES 7.3). The twin step comes last.
const STEPS: Array[Vector2i] = [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]

var rows: int = 0
var base: Vector2i = Vector2i(-1, -1)
var entrances: Array[Vector2i] = []
var _road: PackedByteArray = PackedByteArray()          # per cell: 1 for a road cell
var _bridge: PackedInt32Array = PackedInt32Array()      # per cell: k for the k-th bridge, else -1
var _bridges: Array[Vector2i] = []                      # the bridge cells, in cell order
var _twin: PackedInt32Array = PackedInt32Array()        # per cell: the twin stump's cell index, else -1
var _slide: Array[Vector2i] = []                        # per cell: a slide's way out, else (0, 0)
# The steps, as flat lists per node: out of a node in tie order, and into a node.
var _out_start: PackedInt32Array = PackedInt32Array()
var _out: PackedInt32Array = PackedInt32Array()
var _in_start: PackedInt32Array = PackedInt32Array()
var _in: PackedInt32Array = PackedInt32Array()


func _init(level: LevelData) -> void:
	rows = level.rows
	base = level.base
	entrances = level.entrances.duplicate()
	var cells: int = size()
	_road.resize(cells)
	_bridge.resize(cells)
	_bridge.fill(-1)
	_twin.resize(cells)
	_twin.fill(-1)
	_slide.resize(cells)
	var stumps: Dictionary[int, Array] = {}             # letter to its cell indexes
	for r: int in rows:
		for c: int in Sim.MAP_COLUMNS:
			var cell: Vector2i = Vector2i(c, r)
			var i: int = index(cell)
			_road[i] = 1 if level.is_road(cell) else 0
			_slide[i] = level.slide_dir(cell)
			match level.feature_at(cell):
				LevelData.Feature.BRIDGE:
					_bridge[i] = _bridges.size()
					_bridges.append(cell)
				LevelData.Feature.STUMP:
					var letter: int = level.grid[r].unicode_at(c)
					if not stumps.has(letter):
						stumps[letter] = []
					stumps[letter].append(i)
	for letter: int in stumps:
		var pair: Array = stumps[letter]
		if pair.size() == 2:
			_twin[pair[0]] = pair[1]
			_twin[pair[1]] = pair[0]
	_build_steps()


## Every node's steps out, in tie order, and the same steps listed by the node they
## arrive at, for the search from the base.
func _build_steps() -> void:
	var count: int = node_count()
	var outs: Array[Array] = []
	var ins: Array[Array] = []
	for node: int in count:
		outs.append([])
		ins.append([])
	for i: int in size():
		if _road[i] == 0:
			continue
		var cell: Vector2i = Vector2i(i % Sim.MAP_COLUMNS, i / Sim.MAP_COLUMNS)
		for step: Vector2i in STEPS:
			var to: int = _neighbor_arrival(cell, step)
			if to < 0:
				continue
			var from: int = node_of(cell, step.x != 0)
			outs[from].append(to)
			ins[to].append(from)
		if _twin[i] >= 0:
			outs[i].append(_twin[i])
			ins[_twin[i]].append(i)
	_out_start.resize(count + 1)
	_in_start.resize(count + 1)
	for node: int in count:
		_out_start[node] = _out.size()
		_out.append_array(PackedInt32Array(outs[node]))
		_in_start[node] = _in.size()
		_in.append_array(PackedInt32Array(ins[node]))
	_out_start[count] = _out.size()
	_in_start[count] = _in.size()


## The node a neighbor step from `cell` in direction `step` arrives at; -1 when there is
## no such step (14.3).
func _neighbor_arrival(cell: Vector2i, step: Vector2i) -> int:
	var near: Vector2i = cell + step
	if not is_road(cell) or not is_road(near):
		return -1
	var way: Vector2i = _slide[index(cell)]
	if way != Vector2i.ZERO and way != step:
		return -1                                      # a slide's one way out is its arrow's
	if _slide[index(near)] == -step:
		return -1                                      # never onto a slide against its arrow
	return node_of(near, step.x != 0)


## The number of cells, rows * 7. Cell indexes are row * 7 + column.
func size() -> int:
	return rows * Sim.MAP_COLUMNS


func index(cell: Vector2i) -> int:
	return cell.y * Sim.MAP_COLUMNS + cell.x


func inside(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < Sim.MAP_COLUMNS and cell.y >= 0 and cell.y < rows


func is_road(cell: Vector2i) -> bool:
	return inside(cell) and _road[index(cell)] == 1


## rows * 7, plus one node for each bridge.
func node_count() -> int:
	return size() + _bridges.size()


## A road cell's node; on a bridge, `across` picks the east-west node. -1 off the road.
func node_of(cell: Vector2i, across: bool = false) -> int:
	if not is_road(cell):
		return -1
	var i: int = index(cell)
	if across and _bridge[i] >= 0:
		return size() + _bridge[i]
	return i


## The cell of a node; (-1, -1) for a number that is no node.
func node_cell(node: int) -> Vector2i:
	if node < 0 or node >= node_count():
		return Vector2i(-1, -1)
	if node >= size():
		return _bridges[node - size()]
	return Vector2i(node % Sim.MAP_COLUMNS, node / Sim.MAP_COLUMNS)


## The node a step from cell `from` to cell `to` arrives at. from == to gives to's node.
## -1 when it is not a step.
func arrival(from: Vector2i, to: Vector2i) -> int:
	if from == to:
		return node_of(to)
	var gap: Vector2i = to - from
	if absi(gap.x) + absi(gap.y) == 1:
		return _neighbor_arrival(from, gap)
	if twin_of(from) == to:
		return node_of(to)
	return -1


## A neighbor step or a twin step exists from `from` to `to`.
func is_step(from: Vector2i, to: Vector2i) -> bool:
	return from != to and arrival(from, to) >= 0


## A stump's twin; (-1, -1) for any other cell.
func twin_of(cell: Vector2i) -> Vector2i:
	if not inside(cell) or _twin[index(cell)] < 0:
		return Vector2i(-1, -1)
	var t: int = _twin[index(cell)]
	return Vector2i(t % Sim.MAP_COLUMNS, t / Sim.MAP_COLUMNS)


## A step that runs north or south with a bridge at either end: it passes under the
## deck (the render's draw order, docs/ARCHITECTURE.md 14.10).
func under_bridge(from: Vector2i, to: Vector2i) -> bool:
	if from.x != to.x or absi(from.y - to.y) != 1:
		return false
	return _is_bridge(from) or _is_bridge(to)


func _is_bridge(cell: Vector2i) -> bool:
	return inside(cell) and _bridge[index(cell)] >= 0


## Steps to the base per node over open nodes, node_count() long; -1 when cut off or
## not road. One breadth first search from the base over the steps taken backwards
## (docs/ARCHITECTURE.md 4.3, 14.3). A closed cell closes its node, and on a bridge
## both (a socket is never a bridge, so play only ever closes one node).
func distances(closed: Array[Vector2i]) -> PackedInt32Array:
	var count: int = node_count()
	var dist: PackedInt32Array = PackedInt32Array()
	dist.resize(count)
	dist.fill(-1)
	if not is_road(base) or closed.has(base):
		return dist
	var shut: PackedByteArray = PackedByteArray()
	shut.resize(count)
	for cell: Vector2i in closed:
		if not is_road(cell):
			continue
		shut[node_of(cell)] = 1
		shut[node_of(cell, true)] = 1
	var queue: PackedInt32Array = PackedInt32Array()
	var start: int = node_of(base)
	queue.append(start)
	dist[start] = 0
	var head: int = 0
	while head < queue.size():
		var node: int = queue[head]
		head += 1
		var next_dist: int = dist[node] + 1
		for k: int in range(_in_start[node], _in_start[node + 1]):
			var from: int = _in[k]
			if shut[from] == 1 or dist[from] != -1:
				continue
			dist[from] = next_dist
			queue.append(from)
	return dist


## One step closer to the base: the first step out of `node`, in the order south, west,
## east, north, then the twin step, that leads to a node whose distance is exactly one
## less. The node itself when there is none.
func next_node(node: int, dist: PackedInt32Array) -> int:
	if node < 0 or node >= node_count() or node >= dist.size():
		return node
	var here: int = dist[node]
	if here <= 0:
		return node
	for k: int in range(_out_start[node], _out_start[node + 1]):
		var to: int = _out[k]
		if dist[to] == here - 1:
			return to
	return node


## From a cell (not a bridge) to the base: the cell of every node passed, both ends
## included. A bridge appears once for each crossing. Empty when cut off.
func route(from: Vector2i, dist: PackedInt32Array) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var node: int = node_of(from)
	if node < 0 or node >= dist.size() or dist[node] < 0:
		return path
	path.append(from)
	while dist[node] > 0:
		var next: int = next_node(node, dist)
		if next == node:
			return path                                # only a made up distance list gets here
		node = next
		path.append(node_cell(node))
	return path


## True when any entrance has no open route to the base.
func seals(closed: Array[Vector2i]) -> bool:
	var dist: PackedInt32Array = distances(closed)
	for entrance: Vector2i in entrances:
		var node: int = node_of(entrance)
		if node < 0 or dist[node] < 0:
			return true
	return false
