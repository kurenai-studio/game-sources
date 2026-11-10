class_name Arrow
extends Node2D
# ---------- Стрела Охотницы ----------
# Летит по пологой дуге, проверяя путь лучом каждый кадр.
#   mode = ""        — обычная: ранит первого врага или выбивает клетку и втыкается
#   mode = "pierce"  — зачарованная (после переката): быстрее, больнее, прошивает
#                      врагов и постройки насквозь (останавливает только рамка карты)
#   mode = "ghost"   — МЕГА-зачарованная: летит сквозь всё без урона и оставляет
#                      светящийся след, который через 1,7 с взрывается по всей длине
#   mode = "blast"   — взрывная (после крюка): взрывается при касании
#   mode = "rain"    — стрела ливня (ульта): падает сверху, ранит и выбивает клетки
#   mode = "giant"   — огромная стрела МЕГА-ульты: падает последней и взрывается

var shooter: Node
var team := 0
var velocity := Vector2.ZERO
var gravity := 420.0
var damage := 10
var cell_damage := 14
var mode := ""
var _life := 3.0
var _stuck := false
var _hit := {}                 # кого уже прошила зачарованная стрела
var _vis: Node2D
var _trail: Line2D
var _trail_pts := PackedVector2Array()
var _glow: Polygon2D
var _host: Node2D             # в кого воткнулся нож-бомба
var _host_off := Vector2.ZERO
var _fuse := -1.0
var stop_y := INF             # ливень ульты: летит сквозь всё до уровня врага

func _ready() -> void:
	z_index = 4
	_vis = Node2D.new()
	add_child(_vis)
	var big := 2.6 if mode == "giant" else 1.0
	var shaft := Color(0.62, 0.45, 0.25)
	var head := Color(0.8, 0.82, 0.88)
	var fl := Color(0.9, 0.3, 0.2)
	match mode:
		"pierce":
			head = Color(0.6, 1.0, 0.75)
			fl = Color(0.4, 1.0, 0.6)
		"ghost":
			shaft = Color(0.8, 1.0, 0.9, 0.8)
			head = Color(1.0, 1.0, 1.0)
			fl = Color(0.5, 1.0, 0.8)
		"blast":
			head = Color(1.0, 0.55, 0.15)
			fl = Color(1.0, 0.8, 0.2)
		"giant":
			shaft = Color(1.0, 0.95, 0.75)
			head = Color(1.0, 1.0, 0.85)
			fl = Color(1.0, 0.8, 0.3)
	if mode in ["knife", "knife_bomb"]:
		# нож Солдата: рукоять, гарда, клинок (у ножа-бомбы — мигающий заряд)
		_poly(PackedVector2Array([Vector2(-12, -2.5), Vector2(-3, -2.5), Vector2(-3, 2.5), Vector2(-12, 2.5)]), Color(0.15, 0.13, 0.12), 1.3)
		_poly(PackedVector2Array([Vector2(-3, -4), Vector2(-1, -4), Vector2(-1, 4), Vector2(-3, 4)]), Color(0.45, 0.45, 0.48), 1.3)
		_poly(PackedVector2Array([Vector2(-1, -2.5), Vector2(10, -2), Vector2(15, 0.5), Vector2(-1, 2.5)]), Color(0.85, 0.87, 0.9), 1.3)
		if mode == "knife_bomb":
			_glow = Polygon2D.new()
			_glow.polygon = Util.circle(4.0, 10)
			_glow.color = Color(1.0, 0.25, 0.15)
			_glow.position = Vector2(-8, 0)
			_vis.add_child(_glow)
		_vis.rotation = velocity.angle()
		return
	_poly(PackedVector2Array([Vector2(-20, -1.2), Vector2(8, -1.2), Vector2(8, 1.2), Vector2(-20, 1.2)]) , shaft, big)
	_poly(PackedVector2Array([Vector2(8, -4), Vector2(17, 0), Vector2(8, 4)]), head, big)
	_poly(PackedVector2Array([Vector2(-21, -5), Vector2(-14, -1), Vector2(-14, 1), Vector2(-21, 5), Vector2(-17, 0)]), fl, big)
	# прорисовка: блик на древке, тёмная половина оперения, блик на наконечнике, обмотка
	_poly(PackedVector2Array([Vector2(-20, -1.2), Vector2(8, -1.2), Vector2(8, -0.4), Vector2(-20, -0.4)]), shaft.lightened(0.25), big)
	_poly(PackedVector2Array([Vector2(-17, 0), Vector2(-14, 1), Vector2(-21, 5)]), fl.darkened(0.3), big)
	_poly(PackedVector2Array([Vector2(8, -4), Vector2(17, 0), Vector2(8, 0)]), head.lightened(0.25), big)
	_poly(PackedVector2Array([Vector2(6, -1.6), Vector2(8, -1.6), Vector2(8, 1.6), Vector2(6, 1.6)]), Color(0.35, 0.22, 0.12), big)
	if mode in ["pierce", "ghost", "blast", "giant"]:
		_glow = Polygon2D.new()
		_glow.polygon = Util.circle(9.0 * big, 12)
		_glow.color = Color(fl, 0.35)
		_glow.position = Vector2(12 * big, 0)
		_vis.add_child(_glow)
	if mode in ["pierce", "ghost", "rain", "giant"]:
		_trail = Line2D.new()
		_trail.top_level = true
		_trail.width = 10.0 if mode == "ghost" else (8.0 if mode == "giant" else 3.0)
		_trail.default_color = Color(0.55, 1.0, 0.8, 0.55) if mode in ["pierce", "ghost"] else Color(1.0, 0.95, 0.75, 0.35)
		_trail.z_index = 3
		add_child(_trail)
	if mode == "ghost":
		_life = 1.4
	_vis.rotation = velocity.angle()

func _poly(pts: PackedVector2Array, c: Color, k: float) -> void:
	for i in pts.size():
		pts[i] *= k
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = c
	_vis.add_child(p)

func _physics_process(delta: float) -> void:
	_life -= delta
	if _life <= 0.0:
		_finish()
		return
	if _fuse >= 0.0:
		_fuse -= delta
		if is_instance_valid(_host) and _host.is_alive():
			global_position = _host.global_position + _host_off
		if _glow:
			_glow.modulate.a = 0.4 + 0.6 * absf(sin(_fuse * (8.0 + 30.0 * (1.0 - _fuse))))
		if _fuse <= 0.0:
			_knife_boom()
		return
	if _stuck:
		return
	var from := global_position
	velocity.y += gravity * delta
	var to := from + velocity * delta
	_vis.rotation = velocity.angle()
	if _glow and mode != "knife_bomb":
		_glow.modulate.a = 0.6 + 0.4 * sin(Time.get_ticks_msec() * 0.02)
	if _trail:
		_trail.add_point(to)
		var keep := 400 if mode == "ghost" else (14 if mode == "pierce" else 6)
		while _trail.get_point_count() > keep:
			_trail.remove_point(0)
	if mode == "ghost":
		_trail_pts.append(to)
		global_position = to
		return
	if mode == "pierce":
		_pierce_step(from, to)
		return
	if stop_y < INF:
		_sky_step(from, to)
		return
	var hit := _cast(from, to, Layer.WORLD | Layer.FRAME | Layer.PLAYER | Layer.BOT)
	if hit.is_empty():
		global_position = to
		return
	global_position = hit["position"]
	var body = hit["collider"]
	if body is Node and body.has_meta("mirror"):
		# зеркальный кристалл: стрела отскакивает
		var n: Vector2 = body.normal_at(global_position) if body.has_method("normal_at") else hit["normal"]
		velocity = velocity.bounce(n) * 0.95
		global_position += n * 4.0
		return
	if body.has_method("take_damage"):
		body.take_damage(damage, shooter)
		Util.flash(get_parent(), global_position, 12.0, Color(1, 0.9, 0.7, 0.8))
	elif body.has_method("hit") and mode != "blast" and mode != "giant":
		body.hit(global_position, velocity.normalized(), cell_damage, 0.0, team, {"attacker": shooter})
	_impact(body)

# Ливень ульты: стрела пробивает всё на пути (по каждому врагу — один раз,
# по каждой постройке — небольшой урон) и втыкается на уровне, где стоит враг
func _sky_step(from: Vector2, to: Vector2) -> void:
	var land := to.y >= stop_y
	if land:
		to = from.lerp(to, clampf((stop_y - from.y) / maxf(to.y - from.y, 0.01), 0.0, 1.0))
	for n in get_parent().get_children():
		if n is Player and n.team != team and n.is_alive() and not _hit.has(n):
			if Geometry2D.get_closest_point_to_segment(n.global_position, from, to).distance_to(n.global_position) \
					< maxf(n.body_size.x, n.body_size.y) * 0.45:
				_hit[n] = true
				if mode == "rain":
					n.take_damage(damage, shooter)
					Util.flash(get_parent(), n.global_position, 12.0, Color(1, 0.9, 0.7, 0.8))
	if mode == "rain":
		var space := get_world_2d().direct_space_state
		var ex: Array[RID] = []
		for i in 6:
			var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(from, to, Layer.WORLD, ex))
			if hit.is_empty():
				break
			ex.append(hit["rid"])
			var b = hit["collider"]
			if b is Destructible and not _hit.has(b) and b.shield_team != team and not b.background:
				_hit[b] = true
				b.hit(hit["position"], velocity.normalized(), cell_damage, 0.0, team,
						{"strict": true, "attacker": shooter, "power": 0.4})
	global_position = to
	if land:
		_impact(null)

# Луч от точки до точки: пропускает своих и свои щиты
func _cast(from: Vector2, to: Vector2, mask: int) -> Dictionary:
	var ex: Array[RID] = []
	if is_instance_valid(shooter):
		ex.append(shooter.get_rid())
	var space := get_world_2d().direct_space_state
	for i in 6:
		var q := PhysicsRayQueryParameters2D.create(from, to, mask, ex)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return hit
		var b = hit["collider"]
		var skip := false
		if b is Player:
			skip = b.team == team or not b.is_alive()
		elif b is Destructible:
			skip = b.shield_team == team or b.background
		if not skip:
			return hit
		ex.append(hit["rid"])
	return {}

# Зачарованная стрела: шьёт всех врагов и блоки, пока не упрётся в рамку карты
func _pierce_step(from: Vector2, to: Vector2) -> void:
	for n in get_parent().get_children():
		if n is Player and n.team != team and n.is_alive() and not _hit.has(n):
			if Geometry2D.get_closest_point_to_segment(n.global_position, from, to).distance_to(n.global_position) \
					< maxf(n.body_size.x, n.body_size.y) * 0.45:
				_hit[n] = true
				n.take_damage(damage, shooter)
				Fx.sparks(get_parent(), n.global_position, Color(0.5, 1.0, 0.7), 8, 200.0, 4.0)
		elif n is Destructible and n.shield_team != team and not n.background \
				and n.global_position.distance_to(from) < 400.0:
			var steps := int(from.distance_to(to) / 12.0) + 1
			for k in steps:
				n.hit(from.lerp(to, float(k) / steps), velocity.normalized(), cell_damage, 0.0, team,
						{"strict": true, "attacker": shooter, "power": 0.5})
	var wall := _cast(from, to, Layer.FRAME)
	if not wall.is_empty():
		global_position = wall["position"]
		_impact(null)
		return
	global_position = to

func _impact(body) -> void:
	var parent := get_parent()
	match mode:
		"knife_bomb":
			# нож-бомба втыкается (во врага — едет вместе с ним) и скоро взрывается
			_stuck = true
			_life = 5.0
			_fuse = 1.1
			if body is Player:
				_host = body
				_host_off = global_position - body.global_position
			return
		"blast":
			Util.explode(parent, global_position, 70.0, damage, 26, team, shooter)
			Fx.ring(parent, global_position, 70.0, Color(1.0, 0.6, 0.2, 0.9), 0.35, 5.0)
			Fx.sparks(parent, global_position, Color(1.0, 0.7, 0.25), 10, 220.0, 4.0)
			queue_free()
			return
		"giant":
			Util.explode(parent, global_position, 150.0, damage, 70, team, shooter)
			Fx.ring(parent, global_position, 170.0, Color(1.0, 0.9, 0.5, 0.95), 0.5, 10.0)
			Fx.ring(parent, global_position, 110.0, Color(1.0, 1.0, 0.9, 0.9), 0.35, 6.0, 0.35)
			Fx.sparks(parent, global_position, Color(1.0, 0.9, 0.5), 24, 380.0, 6.0, true)
			Fx.cracks(parent, global_position, Color(0.3, 0.25, 0.2), 130.0)
			_stuck = true
			_life = 0.8
			var t := create_tween()
			t.tween_interval(0.4)
			t.tween_property(self, "modulate:a", 0.0, 0.4)
			return
	if body is Player or (body == null and stop_y == INF):
		queue_free()
		return
	# стрела втыкается в блок и немного торчит
	_stuck = true
	_life = 1.2
	var t2 := create_tween()
	t2.tween_interval(0.8)
	t2.tween_property(self, "modulate:a", 0.0, 0.4)

func _finish() -> void:
	if mode == "ghost" and _trail_pts.size() > 1:
		var tr := GhostTrail.new()
		tr.points = _trail_pts
		tr.team = team
		tr.attacker = shooter
		tr.damage = damage
		get_parent().add_child(tr)
	queue_free()

# Нож-бомба: взрыв и россыпь мини-гранат
func _knife_boom() -> void:
	var parent := get_parent()
	var pos := global_position
	Util.explode(parent, pos, 90.0, 26, 45, team, shooter, true)
	Fx.ring(parent, pos, 100.0, Color(1.0, 0.6, 0.2, 0.9), 0.35, 6.0)
	Fx.sparks(parent, pos, Color(1.0, 0.7, 0.3), 14, 260.0, 5.0)
	for i in 5:
		var g := Grenade.new()
		g.mini = true
		g.team = team
		g.attacker = shooter
		g.position = pos + Vector2(0, -10)
		g.linear_velocity = Vector2(randf_range(-360, 360), randf_range(-560, -280))
		parent.add_child(g)
	queue_free()
