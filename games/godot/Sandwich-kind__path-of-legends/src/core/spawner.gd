class_name Spawner
# Выбор места возрождения в режиме на двоих.
# Случайная точка на своей половине карты, где есть свободное место:
# не внутри блоков и обломков, не рядом с противником и не там же, где в прошлый раз.
# Иногда (если на карте есть небо) — высоко в небе, с парашютом.

const SKY_CHANCE := 0.25        # шанс возродиться в небе с парашютом
const MIN_ENEMY_DIST := 320.0   # не ближе к противнику
const MIN_REPEAT_DIST := 220.0  # не там же, где в прошлый раз
const EDGE := 70.0              # отступ от стен карты
const MIDDLE_GAP := 120.0       # отступ от середины карты

# Возвращает {"pos": Vector2, "parachute": bool}
static func pick(world: Node2D, p: Player, enemy: Player, info: Dictionary) -> Dictionary:
	var size: Vector2 = info["size"]
	var sky: Array = info.get("sky", [])
	if not sky.is_empty() and p.last_spawn_kind != "sky" and randf() < SKY_CHANCE:
		return _done(p, sky[p.team], true, "sky")

	# своя часть карты (на «Цитадели во тьме» бой идёт только между стенами мрака)
	var left: float = info.get("x_lo", 0.0)
	var right: float = info.get("x_hi", size.x)
	var mid := (left + right) / 2.0
	var lo := left + EDGE
	var hi := mid - MIDDLE_GAP
	if p.team == 1:
		lo = mid + MIDDLE_GAP
		hi = right - EDGE
	var space := world.get_world_2d().direct_space_state
	for attempt in 30:
		var x := randf_range(lo, hi)
		var spots := _spots_on_line(space, x, info["top_y"], size.y)
		spots.shuffle()
		for s in spots:
			if enemy != null and is_instance_valid(enemy) and enemy.is_alive() \
					and s.distance_to(enemy.global_position) < MIN_ENEMY_DIST:
				continue
			if p.last_spawn.x != INF and s.distance_to(p.last_spawn) < MIN_REPEAT_DIST:
				continue
			if _is_free(space, s):
				return _done(p, s, false, "ground")
	# на всякий случай — стартовая точка
	return _done(p, info["p1"] if p.team == 0 else info["p2"], false, "base")

static func _done(p: Player, pos: Vector2, parachute: bool, kind: String) -> Dictionary:
	p.last_spawn = pos
	p.last_spawn_kind = kind
	return {"pos": pos, "parachute": parachute}

# Все места, где можно стоять, на вертикальной линии x: на полу, на платформах,
# на крышах, на этажах домов. Луч идёт сверху вниз и отмечает каждую поверхность.
static func _spots_on_line(space: PhysicsDirectSpaceState2D, x: float, top_y: float,
		bottom: float) -> Array:
	var res: Array = []
	var y := top_y
	for i in 200:
		var q := PhysicsRayQueryParameters2D.create(Vector2(x, y), Vector2(x, bottom + 10.0))
		q.collision_mask = Layer.WORLD
		q.hit_from_inside = true
		var r := space.intersect_ray(q)
		if r.is_empty():
			break
		var col = r["collider"]
		var pt: Vector2 = r["position"]
		# луч начался внутри блока — это не поверхность, идём дальше вниз сквозь блок
		var inside: bool = pt.y - y < 1.0
		# стоять можно только на неподвижном: рамка карты и закреплённые объекты
		var solid: bool = col is StaticBody2D or (col is Destructible and col.freeze)
		if solid and not inside:
			res.append(Vector2(x, pt.y - Player.SIZE.y / 2.0 - 2.0))
		y = pt.y + 8.0
	return res

static func _is_free(space: PhysicsDirectSpaceState2D, pos: Vector2) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Player.SIZE + Vector2(8, -2)   # не задевает пол под ногами
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, pos)
	q.collision_mask = Layer.WORLD | Layer.FRAG | Layer.PLAYER
	return space.intersect_shape(q, 1).is_empty()
