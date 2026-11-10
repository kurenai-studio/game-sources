class_name LightBeam
# ---------- Луч света ----------
# Мгновенный луч: летит по прямой до первой преграды. От зеркальных кристаллов
# отражается, проходя сквозь призму — делится на три. Ранит первого врага на пути.
# Если отражённый луч попадает в того, кто его выпустил, — тот оглушён (Ирида).
#
# fire(world, from, dir, opts) — выстрелить и нарисовать; возвращает отрезки.
# opts: team, attacker, damage, color, width, length, bounces, split, cell_damage,
#       life (сколько видно, с), stun_self (оглушить стрелка отражённым лучом, с)

const MASK := Layer.WORLD | Layer.FRAME | Layer.PLAYER | Layer.BOT | Layer.MIRROR

static func fire(world: Node2D, from: Vector2, dir: Vector2, opts := {}) -> Array:
	var segs: Array = []
	var hit_players := {}
	var used_prisms := {}
	var team0: int = opts.get("team", 1)
	var attacker0 = opts.get("attacker", null)
	# [начало, направление, отскоки, глубина, отражён ли, команда, стрелок]
	var queue: Array = [[from, dir.normalized(), int(opts.get("bounces", 2)), 0, false, team0, attacker0]]
	var space := world.get_world_2d().direct_space_state
	var length: float = opts.get("length", 2600.0)
	var guard := 0
	while not queue.is_empty() and guard < 24:
		guard += 1
		var q: Array = queue.pop_front()
		var p: Vector2 = q[0]
		var d: Vector2 = q[1]
		var bounces: int = q[2]
		var depth: int = q[3]
		var reflected: bool = q[4]
		var team: int = q[5]
		var attacker = q[6]
		var end := p + d * length
		var res := _cast(space, p, end, team, attacker, reflected)
		var hp: Vector2 = res.get("position", end)
		# призма на пути — луч делится на три
		if opts.get("split", true) and depth < 2:
			var best = null
			var bd := INF
			for pr in world.get_tree().get_nodes_in_group("prisms"):
				if used_prisms.has(pr) or not is_instance_valid(pr):
					continue
				var c: Vector2 = pr.global_position
				var cp := Geometry2D.get_closest_point_to_segment(c, p, hp)
				if cp.distance_to(c) < LightPrism.R:
					var dd := p.distance_to(c)
					if dd < bd and dd > 4.0:
						bd = dd
						best = pr
			if best:
				used_prisms[best] = true
				var c2: Vector2 = best.global_position
				segs.append([p, c2, depth])
				for a in [-0.42, 0.0, 0.42]:
					queue.append([c2 + d.rotated(a) * (LightPrism.R + 2.0), d.rotated(a), bounces, depth + 1, reflected, team, attacker])
				continue
		segs.append([p, hp, depth])
		if res.is_empty():
			continue
		var body = res["collider"]
		if body is Node and body.has_meta("mirror") and (bounces > 0 or body.has_meta("mirror_team")):
			var n: Vector2 = res.get("normal", -d)
			if body.has_method("normal_at"):
				n = body.normal_at(hp)
			# зеркальная стена Призмы перехватывает луч: теперь он бьёт по своим
			var nt := team
			var na = attacker
			if body.has_meta("mirror_team") and int(body.get_meta("mirror_team")) != team:
				nt = int(body.get_meta("mirror_team"))
				na = body.owner_p
			queue.append([hp + n * 3.0, d.bounce(n), bounces - 1, depth, true, nt, na])
		elif body is Player:
			if body == attacker0 and reflected and opts.get("stun_self", 0.0) > 0.0:
				body.stun(float(opts["stun_self"]))      # свой же луч вернулся — оглушён
				Fx.ring(world, body.global_position, 90.0, Color(1.0, 1.0, 1.0, 0.9), 0.4, 6.0)
			if body != attacker and body.team != team and not hit_players.has(body):
				hit_players[body] = true
				body.take_damage(int(opts.get("damage", 15)), attacker)
				Fx.sparks(world, hp, opts.get("color", Color.WHITE), 8, 180.0, 3.0)
		elif body is Destructible and opts.get("cell_damage", 0) > 0:
			body.hit(hp, d, int(opts["cell_damage"]), 8.0, team, {"attacker": attacker, "strict": true})
	draw(world, segs, opts.get("color", Color(1.0, 0.95, 0.8)), float(opts.get("width", 6.0)), float(opts.get("life", 0.35)))
	return segs

# Первый, во что упирается луч (своих и фон пропускаем)
static func _cast(space: PhysicsDirectSpaceState2D, a: Vector2, b: Vector2, team: int, attacker, allow_self: bool) -> Dictionary:
	var ex: Array[RID] = []
	if attacker != null and is_instance_valid(attacker) and not allow_self:
		ex.append(attacker.get_rid())
	for i in 12:
		var q := PhysicsRayQueryParameters2D.create(a, b, MASK, ex)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return hit
		var c = hit["collider"]
		var skip := false
		if c is Player:
			skip = not c.is_alive() or (c.team == team and c != attacker)
		elif c is Destructible:
			skip = c.background or c.shield_team == team
		elif Util.is_one_way(c):
			skip = true
		if not skip:
			return hit
		ex.append(hit["rid"])
	return {}

static func draw(world: Node2D, segs: Array, c: Color, width: float, life: float) -> void:
	var root := Node2D.new()
	root.z_index = 6
	world.add_child(root)
	for s in segs:
		for layer in [[width * 2.6, Color(c, 0.25)], [width, c], [width * 0.35, Color(1, 1, 1, 0.95)]]:
			var l := Line2D.new()
			l.points = PackedVector2Array([s[0], s[1]])
			l.width = layer[0] * (0.8 if s[2] > 0 else 1.0)
			l.default_color = layer[1]
			l.begin_cap_mode = Line2D.LINE_CAP_ROUND
			l.end_cap_mode = Line2D.LINE_CAP_ROUND
			root.add_child(l)
		var g := Polygon2D.new()
		g.polygon = Util.circle(width * 1.4, 10)
		g.color = Color(c, 0.6)
		g.position = s[1]
		root.add_child(g)
	var t := root.create_tween()
	t.tween_property(root, "modulate:a", 0.0, life)
	t.tween_callback(root.queue_free)

# Тонкая линия прицела перед выстрелом (без урона)
static func aim_line(world: Node2D, from: Vector2, to: Vector2, c: Color, time: float) -> Line2D:
	var l := Line2D.new()
	l.points = PackedVector2Array([from, to])
	l.width = 2.0
	l.default_color = Color(c, 0.55)
	l.z_index = 5
	world.add_child(l)
	var t := l.create_tween()
	t.tween_property(l, "width", 4.0, time)
	t.tween_callback(l.queue_free)
	return l
