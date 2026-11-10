class_name DungeonGenerator
extends RefCounted
## Gera masmorras de salas + corredores em uma grade (0 = sólido, 1 = chão).

const SOLID := 0
const FLOOR := 1

var width := 72
var height := 72
var grid := PackedByteArray()
var rooms: Array[Rect2i] = []
var start_room: Rect2i
var end_room: Rect2i


func generate(depth: int, seed_value: int = -1) -> void:
	if seed_value >= 0:
		seed(seed_value)
	width = 60 + mini(depth * 4, 30)
	height = 60 + mini(depth * 4, 30)
	grid.resize(width * height)
	grid.fill(SOLID)
	rooms.clear()

	var target_rooms := mini(8 + depth, 16)
	var tries := 0
	while rooms.size() < target_rooms and tries < 400:
		tries += 1
		var w := randi_range(7, 14)
		var h := randi_range(6, 11)
		var r: Rect2i = Rect2i(randi_range(3, width - w - 4), randi_range(4, height - h - 4), w, h)
		var ok := true
		for other in rooms:
			if r.grow(3).intersects(other):
				ok = false
				break
		if ok:
			rooms.append(r)
			_carve_rect(r)

	# Conecta salas em ordem de proximidade (árvore geradora mínima simples)
	var connected: Array[Rect2i] = [rooms[0]]
	var remaining: Array[Rect2i] = rooms.slice(1)
	while not remaining.is_empty():
		var best_a: Rect2i
		var best_b: Rect2i
		var best_d := INF
		for a in connected:
			for b in remaining:
				var d: float = Vector2(a.get_center()).distance_squared_to(Vector2(b.get_center()))
				if d < best_d:
					best_d = d
					best_a = a
					best_b = b
		_carve_corridor(best_a.get_center(), best_b.get_center())
		connected.append(best_b)
		remaining.erase(best_b)
	# Alguns laços extras para não ficar linear
	for i in 2:
		var a: Rect2i = rooms.pick_random()
		var b: Rect2i = rooms.pick_random()
		if a != b:
			_carve_corridor(a.get_center(), b.get_center())

	_remove_thin_walls()
	start_room = rooms[0]
	end_room = _farthest_room(start_room)


func is_floor(c: Vector2i) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= width or c.y >= height:
		return false
	return grid[c.y * width + c.x] == FLOOR


func set_cell(c: Vector2i, v: int) -> void:
	if c.x <= 0 or c.y <= 1 or c.x >= width - 1 or c.y >= height - 1:
		return
	grid[c.y * width + c.x] = v


func random_floor_in(r: Rect2i, margin: int = 1) -> Vector2i:
	for i in 30:
		var c: Vector2i = Vector2i(randi_range(r.position.x + margin, r.end.x - 1 - margin), randi_range(r.position.y + margin, r.end.y - 1 - margin))
		if is_floor(c):
			return c
	return r.get_center()


func _carve_rect(r: Rect2i) -> void:
	for x in range(r.position.x, r.end.x):
		for y in range(r.position.y, r.end.y):
			set_cell(Vector2i(x, y), FLOOR)


func _carve_corridor(a: Vector2i, b: Vector2i) -> void:
	var horizontal_first := randf() < 0.5
	var corner: Vector2i = Vector2i(b.x, a.y) if horizontal_first else Vector2i(a.x, b.y)
	_carve_line(a, corner)
	_carve_line(corner, b)


func _carve_line(a: Vector2i, b: Vector2i) -> void:
	# Proteção contra edge case: se a e b são iguais, não fazer nada
	if a == b:
		return
	
	var c := a
	var step: Vector2i = Vector2i(signi(b.x - a.x), signi(b.y - a.y))
	while true:
		# Corredores horizontais com 3 de altura, verticais com 2 de largura
		if step.x != 0:
			for oy in range(-1, 2):
				set_cell(c + Vector2i(0, oy), FLOOR)
		else:
			for ox in range(0, 2):
				set_cell(c + Vector2i(ox, 0), FLOOR)
		if c == b:
			break
		c += step


## Paredes de 1 célula entre dois chãos (vertical) ficam estranhas - vira chão
func _remove_thin_walls() -> void:
	for pass_i in 2:
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				var c: Vector2i = Vector2i(x, y)
				if is_floor(c):
					continue
				if is_floor(c + Vector2i.UP) and is_floor(c + Vector2i.DOWN):
					set_cell(c, FLOOR)
				elif is_floor(c + Vector2i.LEFT) and is_floor(c + Vector2i.RIGHT):
					set_cell(c, FLOOR)


func _farthest_room(from: Rect2i) -> Rect2i:
	# Proteção: se não há salas, retornar retângulo vazio
	if rooms.is_empty():
		return Rect2i()
	# BFS a partir do centro da sala inicial
	var dist: Dictionary = {}
	var start := from.get_center()
	var queue: Array[Vector2i] = [start]
	dist[start] = 0
	var head := 0
	while head < queue.size():
		var c: Vector2i = queue[head]
		head += 1
		for d in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			var n: Vector2i = c + d
			if is_floor(n) and not dist.has(n):
				dist[n] = dist[c] + 1
				queue.append(n)
	var best := rooms[rooms.size() - 1]
	var best_d := -1
	for r in rooms:
		var d: int = dist.get(r.get_center(), -1)
		if d > best_d:
			best_d = d
			best = r
	return best
