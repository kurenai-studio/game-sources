extends RefCounted

## Wall bits stored per cell.
const NORTH := 1
const EAST := 2
const SOUTH := 4
const WEST := 8

const STEPS: Array[Vector2i] = [Vector2i(0, -1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(-1, 0)]
const BITS: Array[int] = [NORTH, EAST, SOUTH, WEST]
const OPPOSITE_BITS: Array[int] = [SOUTH, WEST, NORTH, EAST]


## Returns one packed wall mask per cell, row-major.
static func generate(cols: int, rows: int, extra_openings: int = 0) -> PackedInt32Array:
	var cells := PackedInt32Array()
	cells.resize(cols * rows)
	cells.fill(NORTH | EAST | SOUTH | WEST)

	var visited := {Vector2i.ZERO: true}
	var stack: Array[Vector2i] = [Vector2i.ZERO]
	while not stack.is_empty():
		var cell: Vector2i = stack[-1]
		var choices: Array[int] = []
		for dir in 4:
			var neighbor: Vector2i = cell + STEPS[dir]
			if _inside(neighbor, cols, rows) and not visited.has(neighbor):
				choices.append(dir)
		if choices.is_empty():
			stack.pop_back()
			continue
		var dir: int = choices.pick_random()
		var next: Vector2i = cell + STEPS[dir]
		_open(cells, cols, cell, dir)
		visited[next] = true
		stack.append(next)

	_loosen(cells, cols, rows, extra_openings)
	return cells


static func has_wall(cells: PackedInt32Array, cols: int, cell: Vector2i, dir: int) -> bool:
	return cells[cell.y * cols + cell.x] & BITS[dir] != 0


## Breadth-first distances from `from`, in cells. Unreachable cells stay at -1.
static func distances(cells: PackedInt32Array, cols: int, rows: int, from: Vector2i) -> PackedInt32Array:
	var result := PackedInt32Array()
	result.resize(cols * rows)
	result.fill(-1)
	result[from.y * cols + from.x] = 0
	var queue: Array[Vector2i] = [from]
	var head := 0
	while head < queue.size():
		var cell: Vector2i = queue[head]
		head += 1
		for dir in 4:
			if has_wall(cells, cols, cell, dir):
				continue
			var next: Vector2i = cell + STEPS[dir]
			if not _inside(next, cols, rows) or result[next.y * cols + next.x] >= 0:
				continue
			result[next.y * cols + next.x] = result[cell.y * cols + cell.x] + 1
			queue.append(next)
	return result


static func farthest_from(cells: PackedInt32Array, cols: int, rows: int, from: Vector2i) -> Vector2i:
	var dist := distances(cells, cols, rows, from)
	var best := from
	var best_distance := -1
	for y in rows:
		for x in cols:
			if dist[y * cols + x] > best_distance:
				best_distance = dist[y * cols + x]
				best = Vector2i(x, y)
	return best


static func _inside(cell: Vector2i, cols: int, rows: int) -> bool:
	return cell.x >= 0 and cell.y >= 0 and cell.x < cols and cell.y < rows


static func _open(cells: PackedInt32Array, cols: int, cell: Vector2i, dir: int) -> void:
	var next: Vector2i = cell + STEPS[dir]
	cells[cell.y * cols + cell.x] &= ~BITS[dir]
	cells[next.y * cols + next.x] &= ~OPPOSITE_BITS[dir]


## Knocks out a few interior walls so the maze has loops instead of only dead ends.
static func _loosen(cells: PackedInt32Array, cols: int, rows: int, count: int) -> void:
	var attempts := 0
	var opened := 0
	while opened < count and attempts < count * 20:
		attempts += 1
		var cell := Vector2i(randi() % cols, randi() % rows)
		var dir := randi() % 4
		var next: Vector2i = cell + STEPS[dir]
		if not _inside(next, cols, rows) or not has_wall(cells, cols, cell, dir):
			continue
		_open(cells, cols, cell, dir)
		opened += 1
