class_name Util
# Вспомогательные функции: круги, вспышки, взрывы.

static func circle(r: float, n: int = 20) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in n:
		var a := TAU * i / n
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

static func flash(parent: Node, pos: Vector2, r: float, color: Color) -> void:
	var p := Polygon2D.new()
	p.polygon = circle(r, 24)
	p.color = color
	p.position = pos
	p.scale = Vector2(0.3, 0.3)
	parent.add_child(p)
	var t := p.create_tween()
	t.set_parallel(true)
	t.tween_property(p, "scale", Vector2.ONE, 0.2)
	t.tween_property(p, "modulate:a", 0.0, 0.35)
	t.chain().tween_callback(p.queue_free)

# Взрыв: урон противникам в радиусе и выбивание клеток из объектов
# (в том числе фоновых — деревьев и задних стен). fire — поджигает горючие клетки.
static func explode(parent: Node, pos: Vector2, radius: float, player_dmg: int,
		cell_dmg: int, team: int, attacker, fire := false) -> void:
	radius *= Balance.blast_mult(attacker)         # в Дуэли взрывы легенд шире
	if radius >= 90.0:
		Fx.shake(parent, clampf(radius / 25.0, 3.0, 12.0))
	for n in parent.get_children():
		if n is Player:
			if n.team != team and n.is_alive() and n.global_position.distance_to(pos) <= radius:
				n.take_damage(player_dmg, attacker)
		elif n is Destructible and n.shield_team != team:
			n.hit(pos, Vector2.ZERO, cell_dmg, radius * 0.8, team,
					{"strict": true, "radial": true, "attacker": attacker, "fire": fire})
	flash(parent, pos, radius, Color(1.0, 0.6, 0.2))

# Сквозная платформа (снизу пропрыгнуть, сверху стоять)
static func is_one_way(body) -> bool:
	if body is Destructible:
		return body.one_way
	if body is StaticBody2D:
		for c in body.get_children():
			if c is CollisionShape2D and c.one_way_collision:
				return true
	return false
