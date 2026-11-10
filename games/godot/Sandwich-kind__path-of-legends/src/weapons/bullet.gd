class_name Bullet
extends Area2D
# ---------- Пуля ----------

var shooter: Node
var team := 0
var direction := Vector2.RIGHT
var speed := 600.0
var damage := 10
var blast := 0.0
var size := 10.0
var color := Color.WHITE
var pierce := 0              # сколько врагов пробьёт насквозь (МЕГА-«Шквал»)
var lifesteal := 0.0         # доля урона, которая лечит стрелка (сгустки душ Мортиса)
var homing := 0.0            # радиус самонаведения (0 — летит прямо)
var style := ""            # вид пули легенды: soul (Мортис), tracer (автомат), shock (пистолет)
var _trail: Line2D
var _vis2: Node2D
var bounces := 0              # сколько раз отскочит от стен и блоков (лучики Призмы)
var accel_on_bounce := 1.0     # во сколько раз ускоряется после отскока
var _bounce_cd := 0.0
var shock := 0.0             # пуля пистолета Солдата: бьёт током и обездвиживает
var chill := 0.0             # ледяная стрела/осколок: покрывает инеем (замедляет) на столько секунд
var burn_t := 0.0            # огненный шар: поджигает на столько секунд
var on_hit := Callable()     # своя реакция на попадание по врагу (искры Зарницы)
var poison := 0.0            # зелёная крышка Пивозавра: отравляет на столько секунд
var _life := 3.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = Layer.WORLD | Layer.PLAYER | Layer.BOT
	var col := CollisionShape2D.new()
	var cs := CircleShape2D.new()
	cs.radius = size / 2
	col.shape = cs
	add_child(col)
	if style != "":
		_styled()
	else:
		var vis := ColorRect.new()
		vis.size = Vector2(size, size)
		vis.position = -vis.size / 2
		vis.color = color
		add_child(vis)
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	if homing > 0.0:
		var best = null
		var bd := homing
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive():
				var d := global_position.distance_to(n.global_position)
				if d < bd:
					bd = d
					best = n
		if best:
			var want: Vector2 = (best.global_position - global_position).normalized()
			direction = direction.lerp(want, minf(1.0, 4.0 * delta)).normalized()
	_bounce_cd -= delta
	position += direction * speed * delta
	if _vis2:
		_vis2.rotation = direction.angle()
		if style == "soul":
			_vis2.get_child(0).rotation += delta * 6.0
		elif style == "shuriken":
			_vis2.rotation = _life * 22.0           # сюрикен крутится
		elif style == "cap":
			_vis2.rotation = _life * 18.0           # крышка кувыркается
			_vis2.scale.y = 0.45 + 0.55 * absf(sin(_life * 20.0))
	if _trail:
		_trail.add_point(global_position)
		while _trail.get_point_count() > (12 if style == "soul" else 5):
			_trail.remove_point(0)
	_life -= delta
	if _life <= 0.0:
		queue_free()

func _on_body_entered(body: Node) -> void:
	if body == shooter or body.get("shield_team") == team:
		return                      # свой щит пропускает
	# зеркальный кристалл отражает всегда, а лучики Призмы — ещё и от стен и блоков
	if not body.has_method("take_damage") and (body.has_meta("mirror") or bounces > 0) and _bounce_cd <= 0.0:
		if not body.has_meta("mirror"):
			bounces -= 1
			if body.has_method("hit"):
				body.hit(global_position, direction, maxi(1, damage / 2), 0.0, team, {"attacker": shooter, "strict": true})
		_reflect(body)
		return
	if body.has_method("take_damage"):
		if body.team == team:
			return
		body.take_damage(damage, shooter)
		if shock > 0.0 and body.is_alive():
			body.root(shock)
			Fx.zap(get_parent(), body.global_position, Color(0.5, 0.85, 1.0))
		if chill > 0.0 and body.is_alive() and body.has_method("chill"):
			body.chill(chill)
		if burn_t > 0.0 and body.is_alive() and body.has_method("burn") and not body.has_meta("fireproof"):
			body.burn(burn_t, 6.0, shooter)
		if poison > 0.0 and body.is_alive() and body.has_method("poison"):
			body.poison(poison, 5.0)
		if lifesteal > 0.0 and is_instance_valid(shooter) and shooter.has_method("heal") and shooter.is_alive():
			shooter.heal(maxi(1, int(damage * lifesteal)))
		if on_hit.is_valid():
			on_hit.call(body)
		if pierce > 0:
			pierce -= 1
			return
	elif body.has_method("hit"):
		var point := global_position - direction * size
		body.hit(point, direction, damage, blast, team, {"attacker": shooter})
	queue_free()

# Детальные пули легенд
func _styled() -> void:
	_vis2 = Node2D.new()
	add_child(_vis2)
	_trail = Line2D.new()
	_trail.top_level = true
	_trail.z_index = -1
	add_child(_trail)
	match style:
		"soul":
			# сгусток души: светящееся ядро, тёмная оболочка, клочья-завихрения и шлейф
			var wisp := Node2D.new()
			_vis2.add_child(wisp)
			for k in 3:
				var w := Polygon2D.new()
				w.polygon = PackedVector2Array([Vector2(0, -size * 0.2), Vector2(size * 0.9, 0), Vector2(0, size * 0.2)])
				w.color = Color(0.55, 0.3, 0.9, 0.6)
				w.rotation = TAU * k / 3.0
				wisp.add_child(w)
			for r in [[0.62, Color(0.45, 0.22, 0.75, 0.85)], [0.45, Color(0.75, 0.5, 1.0)], [0.25, Color(0.97, 0.9, 1.0)]]:
				var c := Polygon2D.new()
				c.polygon = Util.circle(size * r[0], 14)
				c.color = r[1]
				_vis2.add_child(c)
			_trail.width = size * 0.8
			_trail.default_color = Color(0.6, 0.35, 1.0, 0.35)
			var g := Gradient.new()
			g.set_color(0, Color(1, 1, 1, 0))
			g.set_color(1, Color(1, 1, 1, 1))
			_trail.gradient = g
		"tracer":
			# пуля автомата: латунная гильза-капсула и огненный след трассера
			var body := Polygon2D.new()
			body.polygon = PackedVector2Array([Vector2(-5, -1.6), Vector2(3, -1.6), Vector2(6, 0), Vector2(3, 1.6), Vector2(-5, 1.6)])
			body.color = Color(0.85, 0.65, 0.3)
			_vis2.add_child(body)
			var tip := Polygon2D.new()
			tip.polygon = PackedVector2Array([Vector2(1, -1.6), Vector2(3, -1.6), Vector2(6, 0), Vector2(3, 1.6), Vector2(1, 1.6)])
			tip.color = Color(0.7, 0.45, 0.25)
			_vis2.add_child(tip)
			var shine := Polygon2D.new()
			shine.polygon = PackedVector2Array([Vector2(-4, -1.4), Vector2(2, -1.4), Vector2(2, -0.6), Vector2(-4, -0.6)])
			shine.color = Color(1.0, 0.92, 0.6)
			_vis2.add_child(shine)
			_trail.width = 3.0
			_trail.default_color = Color(1.0, 0.75, 0.3, 0.6)
		"kunai":
			# кунай: стальной ромб-наконечник, обмотанная рукоять, кольцо на конце
			var blade := Polygon2D.new()
			blade.polygon = PackedVector2Array([Vector2(-1, -3), Vector2(9, 0), Vector2(-1, 3), Vector2(-3, 0)])
			blade.color = Color(0.72, 0.75, 0.82)
			_vis2.add_child(blade)
			var edge := Polygon2D.new()
			edge.polygon = PackedVector2Array([Vector2(-1, -3), Vector2(9, 0), Vector2(-2, 0)])
			edge.color = Color(0.92, 0.94, 1.0)
			_vis2.add_child(edge)
			var grip := Polygon2D.new()
			grip.polygon = PackedVector2Array([Vector2(-10, -1.2), Vector2(-3, -1.2), Vector2(-3, 1.2), Vector2(-10, 1.2)])
			grip.color = Color(0.45, 0.25, 0.15)
			_vis2.add_child(grip)
			var ring := Line2D.new()
			var pts := Util.circle(2.2, 8)
			pts.append(pts[0])
			ring.points = pts
			ring.position = Vector2(-12, 0)
			ring.width = 1.0
			ring.default_color = Color(0.6, 0.62, 0.68)
			_vis2.add_child(ring)
			_trail.width = 2.0
			_trail.default_color = Color(0.85, 0.9, 1.0, 0.35)
		"shuriken":
			# сюрикен: четыре лезвия, вращается в полёте
			var star := Polygon2D.new()
			var sp := PackedVector2Array()
			for i in 8:
				var r := size * 0.95 if i % 2 == 0 else size * 0.3
				sp.append(Vector2.from_angle(TAU * i / 8.0) * r)
			star.polygon = sp
			star.color = Color(0.70, 0.72, 0.78)
			_vis2.add_child(star)
			var hole := Polygon2D.new()
			hole.polygon = Util.circle(size * 0.18, 8)
			hole.color = Color(0.15, 0.15, 0.18)
			_vis2.add_child(hole)
			_trail.width = 2.0
			_trail.default_color = Color(0.85, 0.85, 0.9, 0.3)
		"arrow":
			# тёмная стрела с оперением
			var shaft := Polygon2D.new()
			shaft.polygon = PackedVector2Array([Vector2(-14, -0.8), Vector2(6, -0.8), Vector2(6, 0.8), Vector2(-14, 0.8)])
			shaft.color = Color(0.40, 0.30, 0.20)
			_vis2.add_child(shaft)
			var head := Polygon2D.new()
			head.polygon = PackedVector2Array([Vector2(5, -3), Vector2(11, 0), Vector2(5, 3)])
			head.color = Color(0.55, 0.55, 0.6)
			_vis2.add_child(head)
			var fl := Polygon2D.new()
			fl.polygon = PackedVector2Array([Vector2(-14, -3), Vector2(-9, -0.8), Vector2(-9, 0.8), Vector2(-14, 3), Vector2(-12, 0)])
			fl.color = color.darkened(0.2)
			_vis2.add_child(fl)
			_trail.width = 1.5
			_trail.default_color = Color(0.8, 0.8, 0.8, 0.25)
		"light":
			# лучик света: вытянутое сияющее ядро и короткий светящийся след
			var glow := Polygon2D.new()
			glow.polygon = PackedVector2Array([Vector2(-size, -size * 0.45), Vector2(size * 0.9, -size * 0.3), Vector2(size * 1.3, 0),
					Vector2(size * 0.9, size * 0.3), Vector2(-size, size * 0.45)])
			glow.color = Color(color, 0.45)
			_vis2.add_child(glow)
			var core := Polygon2D.new()
			core.polygon = PackedVector2Array([Vector2(-size * 0.6, -size * 0.18), Vector2(size, 0), Vector2(-size * 0.6, size * 0.18)])
			core.color = Color(1, 1, 1, 0.95)
			_vis2.add_child(core)
			_trail.width = size * 0.6
			_trail.default_color = Color(color, 0.5)
			var g2 := Gradient.new()
			g2.set_color(0, Color(1, 1, 1, 0))
			g2.set_color(1, Color(1, 1, 1, 1))
			_trail.gradient = g2
		"cap":
			# крышка от бутылки: кружок с зубчатым краем своего цвета
			var cc := color
			var pts := PackedVector2Array()
			for i in 22:
				pts.append(Vector2.from_angle(TAU * i / 22.0) * size * (0.78 if i % 2 == 0 else 0.64))
			var rim := Polygon2D.new()
			rim.polygon = pts
			rim.color = cc.darkened(0.3)
			_vis2.add_child(rim)
			var top := Polygon2D.new()
			top.polygon = Util.circle(size * 0.52, 14)
			top.color = cc
			_vis2.add_child(top)
			var shine := Polygon2D.new()
			shine.polygon = Util.circle(size * 0.18, 8)
			shine.position = Vector2(-size * 0.18, -size * 0.18)
			shine.color = cc.lightened(0.55)
			_vis2.add_child(shine)
			_trail.width = size * 0.35
			_trail.default_color = Color(cc.r, cc.g, cc.b, 0.35)
		"ice", "dark", "ember", "spark":
			# дальние земли: ледяной осколок, сгусток тьмы, огненный шар, искра молнии
			var cols: Array = {"ice": [Color(0.55, 0.85, 1.0, 0.55), Color(0.80, 0.95, 1.0), Color(1, 1, 1)],
					"dark": [Color(0.30, 0.05, 0.40, 0.65), Color(0.12, 0.04, 0.16), Color(0.95, 0.30, 0.20)],
					"ember": [Color(1.0, 0.45, 0.10, 0.55), Color(1.0, 0.70, 0.25), Color(1.0, 0.95, 0.70)],
					"spark": [Color(0.55, 0.75, 1.0, 0.55), Color(0.85, 0.92, 1.0), Color(1, 1, 1)]}[style]
			if style == "ice":
				var shard := Polygon2D.new()
				shard.polygon = PackedVector2Array([Vector2(-size, -size * 0.35), Vector2(size * 1.2, 0), Vector2(-size, size * 0.35), Vector2(-size * 0.6, 0)])
				shard.color = cols[1]
				_vis2.add_child(shard)
				var edge2 := Polygon2D.new()
				edge2.polygon = PackedVector2Array([Vector2(-size * 0.6, -size * 0.25), Vector2(size * 1.1, 0), Vector2(-size * 0.6, 0)])
				edge2.color = cols[2]
				_vis2.add_child(edge2)
			else:
				for k in 3:
					var c3 := Polygon2D.new()
					c3.polygon = Util.circle(size * [0.85, 0.55, 0.28][k], 12)
					c3.color = cols[k]
					_vis2.add_child(c3)
				if style == "spark":
					for k in 3:
						var l2 := Line2D.new()
						var a2 := TAU * k / 3.0
						l2.points = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a2) * size * 0.8, Vector2.from_angle(a2 + 0.6) * size * 1.3])
						l2.width = 1.5
						l2.default_color = Color(0.85, 0.95, 1.0)
						_vis2.add_child(l2)
			_trail.width = size * 0.7
			_trail.default_color = Color(cols[0].r, cols[0].g, cols[0].b, 0.45)
			var g3 := Gradient.new()
			g3.set_color(0, Color(1, 1, 1, 0))
			g3.set_color(1, Color(1, 1, 1, 1))
			_trail.gradient = g3
		"shock":
			# заряд шокера: голубое ядро и потрескивающие искры
			for r in [[size * 0.8, Color(0.3, 0.6, 1.0, 0.5)], [size * 0.5, Color(0.6, 0.85, 1.0)], [size * 0.25, Color(1, 1, 1)]]:
				var c2 := Polygon2D.new()
				c2.polygon = Util.circle(r[0], 12)
				c2.color = r[1]
				_vis2.add_child(c2)
			for k in 4:
				var l := Line2D.new()
				var a := TAU * k / 4.0 + 0.4
				l.points = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(a) * size * 0.7, Vector2.from_angle(a + 0.5) * size * 1.2])
				l.width = 1.5
				l.default_color = Color(0.7, 0.9, 1.0)
				_vis2.add_child(l)
			_trail.width = 4.0
			_trail.default_color = Color(0.5, 0.8, 1.0, 0.5)

# Отскок: нормаль поверхности — лучом назад по пути пули
func _reflect(body: Node) -> void:
	var n := -direction
	if body.has_method("normal_at"):
		n = body.normal_at(global_position)
	else:
		var q := PhysicsRayQueryParameters2D.create(global_position - direction * 30.0, global_position + direction * 30.0,
				Layer.WORLD | Layer.FRAME)
		var hit := get_world_2d().direct_space_state.intersect_ray(q)
		if not hit.is_empty():
			n = hit["normal"]
	direction = direction.bounce(n).normalized()
	position += n * 6.0
	speed *= accel_on_bounce
	_bounce_cd = 0.05
	_life = maxf(_life, 1.2)
	Fx.sparks(get_parent(), global_position, color.lightened(0.3), 4, 140.0, 2.0)

# Сменить вид уже выпущенной пули (пули легенд создаются общим кодом героя)
func restyle(st: String) -> void:
	style = st
	for c in get_children():
		if c is ColorRect:
			c.queue_free()
	_styled()
