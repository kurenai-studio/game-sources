class_name MirrorWall
extends StaticBody2D
# ---------- Зеркальная стена Призмы (способность 1) ----------
# Вертикальное хрустальное зеркало перед героем. Сквозь него можно ходить, свои
# выстрелы пролетают насквозь, а чужие снаряды (пули, копья, стрелы, гранаты,
# сюрикены) отлетают обратно и становятся снарядами Призмы. Лучи света
# (призматики, Ирида) тоже отражаются — и бьют уже по своим.
# МЕГА: стена выше, а отражённый снаряд ещё и ускоряется и бьёт больнее.
# Луч ульты проходит сквозь стену и усиливается (радужный).

var owner_p: Player
var team := 0
var mega := false
var dmg_boost := 1.0             # Арена: отражённые снаряды бьют сильнее
var life := 5.0
var h := 160.0
var normal := Vector2.RIGHT      # куда смотрит зеркало (в сторону взгляда героя)
var _done := {}
var _vis: Node2D
var _glint: Polygon2D
var _t := 0.0
var _dead := false

const HALF_W := 24.0             # толщина зоны отражения (быстрые пули не проскочат)

func _ready() -> void:
	collision_layer = Layer.MIRROR
	collision_mask = 0
	set_meta("mirror", true)
	set_meta("mirror_team", team)
	add_to_group("mirror_walls")
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(14, h)
	col.shape = rs
	add_child(col)
	_build_visual()
	_vis.scale = Vector2(1.0, 0.05)
	var t := _vis.create_tween()
	t.tween_property(_vis, "scale", Vector2(1.0, 1.0), 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.sparks(get_parent(), global_position + Vector2(0, h / 2), Color(0.8, 0.9, 1.0), 10, 200.0, 3.0, true)

func _build_visual() -> void:
	_vis = Node2D.new()
	_vis.z_index = 4
	add_child(_vis)
	var half := h / 2
	# хрустальная рама: неровные грани сверху и снизу
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([Vector2(-11, half), Vector2(-13, -half + 18), Vector2(-4, -half - 10),
			Vector2(5, -half + 2), Vector2(12, -half + 22), Vector2(11, half), Vector2(5, half + 8), Vector2(-6, half + 6)])
	frame.color = Color(0.45, 0.55, 0.95, 0.95) if not mega else Color(0.65, 0.5, 1.0, 0.95)
	_vis.add_child(frame)
	# стекло: светлое с голубым отливом, по краям — грани
	var glass := Polygon2D.new()
	glass.polygon = PackedVector2Array([Vector2(-7, half - 4), Vector2(-8, -half + 20), Vector2(-3, -half - 2),
			Vector2(3, -half + 6), Vector2(8, -half + 22), Vector2(7, half - 4)])
	glass.color = Color(0.82, 0.92, 1.0, 0.85)
	_vis.add_child(glass)
	var edge := Line2D.new()
	edge.points = PackedVector2Array([Vector2(normal.x * 3.0, half - 6), Vector2(normal.x * 3.0, -half + 12)])
	edge.width = 2.0
	edge.default_color = Color(1, 1, 1, 0.9)
	_vis.add_child(edge)
	# грани-кристаллы у основания
	for k in 3:
		var c := Polygon2D.new()
		var x := -12.0 + k * 12.0
		c.polygon = PackedVector2Array([Vector2(x - 6, half + 4), Vector2(x, half - 18 - k % 2 * 8), Vector2(x + 6, half + 4)])
		c.color = DeepArt.GEMS[(k * 2 + 1) % DeepArt.GEMS.size()].lightened(0.2)
		_vis.add_child(c)
	# бегущий блик
	_glint = Polygon2D.new()
	_glint.polygon = PackedVector2Array([Vector2(-7, -10), Vector2(7, -22), Vector2(7, -12), Vector2(-7, 0)])
	_glint.color = Color(1, 1, 1, 0.75)
	_vis.add_child(_glint)
	Shimmer.apply(_vis, 0.3, 0.6)

func normal_at(at: Vector2) -> Vector2:
	return normal if (at - global_position).dot(normal) >= 0.0 else -normal

func _physics_process(delta: float) -> void:
	if _dead:
		return
	_t += delta
	life -= delta
	_glint.position.y = fmod(_t * 160.0, h + 40.0) - h / 2 - 10.0
	if life < 0.6:
		_vis.modulate.a = 0.4 + 0.6 * absf(sin(_t * 18.0))
	if life <= 0.0:
		_break()
		return
	for n in get_parent().get_children():
		if _done.has(n):
			continue
		if not (n is Bullet or n is Spear or n is Arrow or n is Shuriken or n is Shell or n is Grenade):
			continue
		if int(n.get("team")) == team:
			continue
		if n is Spear and n._stuck or n is Arrow and n._stuck:
			continue
		var rel: Vector2 = n.global_position - global_position
		if absf(rel.x) > HALF_W or absf(rel.y) > h / 2 + 6.0:
			continue
		var nv := normal if rel.x * normal.x >= 0.0 else -normal
		var v := _vel(n)
		if v.dot(nv) >= 0.0:
			continue                      # уже летит прочь от зеркала
		_done[n] = true
		_reflect(n, v.bounce(nv), nv)

func _vel(n: Node) -> Vector2:
	if n is Bullet or n is Shuriken or n is Shell:
		return n.direction * n.speed
	if n is Grenade:
		return n.linear_velocity
	return n.velocity

func _reflect(n: Node, v: Vector2, nv: Vector2) -> void:
	var boost := 1.6 if mega else 1.0
	if n is Bullet or n is Shuriken or n is Shell:
		n.direction = v.normalized()
		n.speed *= boost
		if n is Bullet:
			n._life = maxf(n._life, 1.5)
			n.color = Color(0.75, 0.9, 1.0)
	elif n is Grenade:
		n.linear_velocity = v * boost
		n.attacker = owner_p
	else:
		n.velocity = v * boost
	if "shooter" in n:
		n.set("shooter", owner_p)
	n.set("team", team)
	var k := (1.4 if mega else 1.0) * dmg_boost
	if k != 1.0 and "damage" in n:
		n.set("damage", int(int(n.get("damage")) * k))
	n.global_position = Vector2(global_position.x + nv.x * (HALF_W + 4.0), n.global_position.y)
	Fx.sparks(get_parent(), n.global_position, Color(0.8, 0.95, 1.0), 7, 200.0, 3.0)
	Fx.ring(get_parent(), n.global_position, 26.0, Color(1, 1, 1, 0.8), 0.2, 3.0)
	_vis.modulate = Color(1.6, 1.6, 1.8)
	_vis.create_tween().tween_property(_vis, "modulate", Color.WHITE, 0.2)

# Время вышло — зеркало осыпается блёстками
func _break() -> void:
	_dead = true
	remove_from_group("mirror_walls")
	collision_layer = 0
	Fx.sparks(get_parent(), global_position, Color(0.8, 0.9, 1.0), 14, 240.0, 3.0)
	var t := _vis.create_tween()
	t.tween_property(_vis, "scale", Vector2(1.4, 0.0), 0.2)
	t.tween_callback(queue_free)

# Пересекает ли отрезок a→b это зеркало (для луча ульты)
func crosses(a: Vector2, b: Vector2) -> bool:
	if _dead:
		return false
	var top := global_position + Vector2(0, -h / 2)
	var bot := global_position + Vector2(0, h / 2)
	return Geometry2D.segment_intersects_segment(a, b, top, bot) != null
