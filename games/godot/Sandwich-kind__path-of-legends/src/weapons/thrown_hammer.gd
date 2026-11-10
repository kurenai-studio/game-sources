class_name ThrownHammer
extends Node2D
# Брошенный молот Кузнеца.
# Обычный: летит во врага и рикошетит ещё 3 раза в ближайших врагов
# (в Дуэли — отскакивает и снова бьёт того же), потом возвращается.
# МЕГА: летит вперёд, вонзается у первого препятствия или врага, стягивает всех
# врагов вокруг к себе и возвращается к Кузнецу, волоча их за собой.

const SPEED := 1150.0

var owner_p: Player
var team := 0
var mega := false
var dir := 1
var bounces := 3
var damage := 16
var _state := "fly"          # fly — к цели, bounce — отскок, back — домой, pull — стягивает
var _target: Player
var _hit_cd := {}
var _t := 0.0
var _vel := Vector2.ZERO
var _bounce_to := Vector2.ZERO
var _grabbed: Array = []
var _offsets: Array = []
var _vis: Node2D
var _chain: Line2D
var _travel := 0.0

func _ready() -> void:
	z_index = 6
	_vis = Node2D.new()
	add_child(_vis)
	var handle := Polygon2D.new()
	handle.polygon = PackedVector2Array([Vector2(-22, -2.5), Vector2(6, -2.5), Vector2(6, 2.5), Vector2(-22, 2.5)])
	handle.color = BotRig.WOOD
	_vis.add_child(handle)
	var head := Polygon2D.new()
	head.polygon = PackedVector2Array([Vector2(4, -11), Vector2(20, -11), Vector2(20, 11), Vector2(4, 11)])
	head.color = Color(0.4, 0.4, 0.45)
	_vis.add_child(head)
	var shine := Polygon2D.new()
	shine.polygon = PackedVector2Array([Vector2(6, -9), Vector2(18, -9), Vector2(18, -5), Vector2(6, -5)])
	shine.color = Color(0.68, 0.68, 0.74)
	_vis.add_child(shine)
	# прорисовка: волокна рукояти, кожаная оплётка, железные обручи, тёмный боёк
	for y in [-1.0, 1.0]:
		var grain := Line2D.new()
		grain.points = PackedVector2Array([Vector2(-20, y), Vector2(4, y)])
		grain.width = 0.8
		grain.default_color = Color(0.38, 0.24, 0.12)
		_vis.add_child(grain)
	var grip := Polygon2D.new()
	grip.polygon = PackedVector2Array([Vector2(-22, -3), Vector2(-14, -3), Vector2(-14, 3), Vector2(-22, 3)])
	grip.color = Color(0.25, 0.17, 0.11)
	_vis.add_child(grip)
	for x in [-20.0, -17.0]:
		var wrap := Line2D.new()
		wrap.points = PackedVector2Array([Vector2(x, -3), Vector2(x + 2, 3)])
		wrap.width = 1.0
		wrap.default_color = Color(0.45, 0.3, 0.18)
		_vis.add_child(wrap)
	var band := Polygon2D.new()
	band.polygon = PackedVector2Array([Vector2(2, -3.5), Vector2(5, -3.5), Vector2(5, 3.5), Vector2(2, 3.5)])
	band.color = Color(0.55, 0.55, 0.6)
	_vis.add_child(band)
	var face := Polygon2D.new()
	face.polygon = PackedVector2Array([Vector2(18, -11), Vector2(20, -11), Vector2(20, 11), Vector2(18, 11)])
	face.color = Color(0.25, 0.25, 0.28)
	_vis.add_child(face)
	if owner_p and owner_p.kit and owner_p.kit.get("forge_t") != null and owner_p.kit.forge_t > 0.0:
		head.color = Color(1.0, 0.45, 0.15)      # раскалённый в ульте
	if mega:
		_chain = Line2D.new()
		_chain.top_level = true
		_chain.width = 3.0
		_chain.default_color = Color(0.6, 0.6, 0.65)
		_chain.z_index = 5
		add_child(_chain)
	_vel = Vector2(dir * SPEED, -60.0)
	if not mega:
		_target = _pick_target(null)

func _enemies() -> Array:
	var res := []
	for n in get_parent().get_children():
		if n is Player and n.team != team and n.is_alive() and not n.invulnerable:
			res.append(n)
	return res

func _pick_target(exclude) -> Player:
	var best: Player = null
	var bd := 700.0
	for e in _enemies():
		if e == exclude:
			continue
		var d := global_position.distance_to(e.global_position)
		if _state == "fly" and _t == 0.0 and signf(e.global_position.x - global_position.x) != dir and d > 120.0:
			continue                 # первый бросок — только вперёд
		if d < bd:
			bd = d
			best = e
	return best

func _physics_process(delta: float) -> void:
	_t += delta
	_vis.rotation += delta * 18.0 * dir
	if owner_p == null or not is_instance_valid(owner_p) or not owner_p.is_alive():
		_drop()
		return
	if _chain:
		_chain.points = PackedVector2Array([owner_p.global_position, global_position])
	for k in _hit_cd.keys():
		_hit_cd[k] -= delta
	match _state:
		"fly":
			if mega:
				_mega_fly(delta)
			else:
				_seek(delta)
		"bounce":
			var to := _bounce_to - global_position
			if to.length() < 30.0:
				_state = "fly"
			else:
				global_position += to.normalized() * SPEED * delta
				_chip(delta)
		"pull":
			_pull(delta)
		"back":
			_go_back(delta)

func _seek(delta: float) -> void:
	if not is_instance_valid(_target) or not _target.is_alive():
		_target = _pick_target(null)
	if _target == null:
		# никого нет — летит вперёд и возвращается
		global_position += _vel * delta
		_travel += SPEED * delta
		_chip(delta)
		if _travel > 650.0:
			_state = "back"
		return
	var to := _target.global_position - global_position
	_vel = _vel.lerp(to.normalized() * SPEED, minf(1.0, 8.0 * delta))
	global_position += _vel * delta
	_chip(delta)
	if to.length() < 34.0 + _target.body_size.x * 0.4:
		_strike(_target)

func _strike(e: Player) -> void:
	e.take_damage(damage, owner_p)
	if owner_p.kit and owner_p.kit.has_method("on_hammer_hit"):
		owner_p.kit.on_hammer_hit(e)
	e.velocity += Vector2(signf(e.global_position.x - global_position.x) * 160.0, -180.0)
	Fx.sparks(get_parent(), e.global_position, Color(1.0, 0.85, 0.5), 10, 240.0, 5.0)
	Fx.ring(get_parent(), e.global_position, 45.0, Color(1, 0.95, 0.8, 0.9), 0.25, 4.0)
	_hit_cd[e] = 0.35
	if bounces <= 0:
		_state = "back"
		return
	bounces -= 1
	var next := _pick_target(e)
	damage = maxi(8, damage - 2)
	if next:
		_target = next
		_state = "fly"
	else:
		# в Дуэли врагов больше нет — отскакивает и снова бьёт того же
		_target = e
		var away := Vector2(signf(global_position.x - e.global_position.x), -0.8).normalized()
		if away.x == 0.0:
			away.x = -dir
		_bounce_to = e.global_position + away * 170.0
		_state = "bounce"

func _mega_fly(delta: float) -> void:
	var step := Vector2(dir * SPEED * delta, 0)
	var hit := get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(global_position, global_position + step * 2.0, Layer.WORLD | Layer.FRAME))
	var stop := not hit.is_empty()
	for e in _enemies():
		if e.global_position.distance_to(global_position) < 40.0 + e.body_size.x * 0.5:
			stop = true
	_travel += step.length()
	if stop or _travel > 620.0:
		_state = "pull"
		_t = 0.0
		_vis.rotation = 0.0
		Fx.ring(get_parent(), global_position, 260.0, Color(0.75, 0.75, 0.85, 0.8), 0.4, 6.0)
		Fx.sparks(get_parent(), global_position, Color(0.9, 0.9, 1.0), 12, 260.0, 5.0)
		return
	global_position += step

# МЕГА: стягивает врагов вокруг к молоту
func _pull(delta: float) -> void:
	_vis.rotation = sin(_t * 40.0) * 0.2
	for e in _enemies():
		var to: Vector2 = global_position - e.global_position
		if to.length() < 260.0 and not _grabbed.has(e):
			if to.length() > 30.0:
				e.move_and_collide(to.normalized() * minf(to.length(), 900.0 * delta))
				e.velocity = Vector2.ZERO
			else:
				_grabbed.append(e)
				_offsets.append(e.global_position - global_position)
	if _t > 0.4:
		for e in _enemies():
			if global_position.distance_to(e.global_position) < 90.0 and not _grabbed.has(e):
				_grabbed.append(e)
				_offsets.append(e.global_position - global_position)
		_state = "back"

func _go_back(delta: float) -> void:
	var home := owner_p.global_position + Vector2(owner_p.facing * 70.0, -10)
	var to := home - global_position
	var spd := SPEED * (0.75 if mega else 1.0)
	var mv := to.normalized() * minf(to.length(), spd * delta)
	global_position += mv
	if not mega:
		_chip(delta)
	for i in _grabbed.size():
		var e: Player = _grabbed[i]
		if is_instance_valid(e) and e.is_alive():
			var want: Vector2 = global_position + _offsets[i] * 0.5
			e.move_and_collide(want - e.global_position)
			e.velocity = Vector2.ZERO
			e.root(0.15)
	if to.length() < 24.0:
		if owner_p.kit and owner_p.kit.has_method("hammer_back"):
			owner_p.kit.hammer_back(mega, _grabbed)
		queue_free()

# по пути молот выбивает клетки из блоков
func _chip(_delta: float) -> void:
	for n in get_parent().get_children():
		if n is Destructible and n.shield_team != team and not n.background \
				and n.global_position.distance_to(global_position) < 400.0:
			n.hit(global_position, _vel.normalized(), 22, 8.0, team, {"strict": true, "attacker": owner_p})
		elif n is Player and n.team != team and n.is_alive() and n != _target and _hit_cd.get(n, 0.0) <= 0.0 \
				and n.global_position.distance_to(global_position) < 34.0 + n.body_size.x * 0.4:
			n.take_damage(8, owner_p)
			_hit_cd[n] = 0.5

func _drop() -> void:
	if owner_p and is_instance_valid(owner_p) and owner_p.kit and owner_p.kit.has_method("hammer_back"):
		owner_p.kit.hammer_back(false, [])
	queue_free()
