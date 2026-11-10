class_name GasBubble
extends Node2D
# ---------- Болотный пузырь Осоки ----------
# Большой пузырь газа медленно плывёт вперёд. Лопается, если в него попадёт
# любой снаряд (даже вражеский), если коснётся врага или через 2 секунды —
# на его месте остаётся ядовитое облако, которое ранит врагов Осоки.
# Арена: пузырь выдерживает 3 попадания, облако больше и держится дольше.
# МЕГА «Пузырь-ловушка»: выстрелы не лопают пузырь — он их глотает. Коснувшись
# врага, проглатывает его: враг поднимается в пузыре на 1,5 с и ничего не может
# сделать, потом пузырь лопается облаком прямо на нём, и враг падает.
#   Арена: по пути глотает до 3 врагов. Боссов поднять не может — прилипает
#   к боссу и лопается на нём облаком с двойным уроном.

var team := 0
var attacker: Player
var dir := 1
var mega := false
var arena := false

var radius := 26.0
var speed := 230.0
var life := 2.0
var hits_left := 1
var cloud_r := 110.0
var cloud_life := 3.0
var cap_max := 1
const HOLD := 1.5

var _t := 0.0
var _captured: Array = []
var _froze := {}
var _hold_t := -1.0
var _body: Polygon2D
var _rim: Line2D
var _done := false

func _ready() -> void:
	z_index = 6
	if mega:
		radius = 36.0
		speed = 200.0
		life = 3.0
		cap_max = 3 if arena else 1
	elif arena:
		hits_left = 3
	if arena:
		cloud_r = 150.0
		cloud_life = 4.0
	_body = Polygon2D.new()
	_body.polygon = Util.circle(radius, 24)
	_body.color = Color(0.55, 0.85, 0.35, 0.28) if not mega else Color(0.62, 0.86, 0.36, 0.34)
	add_child(_body)
	_rim = Line2D.new()
	var pts := Util.circle(radius, 24)
	pts.append(pts[0])
	_rim.points = pts
	_rim.width = 2.5 if not mega else 3.5
	_rim.default_color = Color(0.72, 1.0, 0.52, 0.85) if not mega else Color(0.95, 0.92, 0.45, 0.9)
	add_child(_rim)
	var shine := Polygon2D.new()
	shine.polygon = Util.circle(radius * 0.22, 10)
	shine.scale = Vector2(1.4, 0.8)
	shine.color = Color(1, 1, 1, 0.6)
	shine.position = Vector2(-radius * 0.4, -radius * 0.45)
	add_child(shine)
	tree_exiting.connect(_release_all)

func _physics_process(delta: float) -> void:
	if _done:
		return
	_t += delta
	var wob := 1.0 + 0.06 * sin(_t * 9.0)
	_body.scale = Vector2(wob, 2.0 - wob)
	_rim.scale = _body.scale
	var world := get_parent()
	if _hold_t < 0.0:
		# летит вперёд; МЕГА на Арене с добычей внутри летит дальше и собирает ещё врагов
		position.x += dir * speed * (0.8 if not _captured.is_empty() else 1.0) * delta
		position.y += sin(_t * 3.0) * 14.0 * delta
		_carry()
		life -= delta
		if life <= 0.0:
			if _captured.is_empty():
				_burst(1.0)
				return
			_start_lift()
		# упёрся в стену — обычный лопается, МЕГА зависает (а с добычей — начинает подъём)
		if dir != 0 and _hold_t < 0.0:
			var hit := get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
					global_position, global_position + Vector2(dir * (radius + 6.0), 0), Layer.WORLD))
			if not hit.is_empty() and not Util.is_one_way(hit["collider"]):
				if mega:
					dir = 0
					if not _captured.is_empty():
						_start_lift()
				else:
					_burst(1.0)
					return
	else:
		# несёт пойманных вверх
		position.y -= 70.0 * delta
		position.x += dir * speed * 0.3 * delta
		_carry()
		_hold_t -= delta
		if _hold_t <= 0.0:
			_burst(1.0)
			return
	# снаряды: обычный пузырь лопается, МЕГА — глотает чужие выстрелы
	for n in world.get_children():
		if not _is_shot(n) or n.global_position.distance_to(global_position) > radius + 8.0:
			continue
		if "_stuck" in n and n._stuck:
			continue
		if mega:
			if n.get("team") == team:
				continue
			Fx.sparks(world, n.global_position, Color(0.7, 1.0, 0.5), 4, 90.0, 2.0)
			n.queue_free()
			continue
		n.queue_free()
		hits_left -= 1
		_rim.default_color = Color(1.0, 0.95, 0.6, 0.9)
		if hits_left <= 0:
			_burst(1.0)
			return
	# враги
	for e in world.get_children():
		if not (e is Player) or e.team == team or not e.is_alive() or e.cutscene_shield or e in _captured:
			continue
		if e.hurt_center().distance_to(global_position) > radius + minf(e.body_size.x, e.body_size.y) * 0.45:
			continue
		if not mega:
			_burst(1.0)
			return
		if _is_boss(e):
			global_position = e.hurt_center()
			_burst(2.0)                       # к боссу прилипает и лопается двойным облаком
			return
		if _captured.size() < cap_max and _hold_t < 0.0:
			_capture(e)

static func _is_shot(n: Node) -> bool:
	return n is Bullet or n is Arrow or n is Spear or n is Shuriken or n is Shell or n is Mortar or n is ThrownHammer

static func _is_boss(e: Player) -> bool:
	return e.stagger_max > 0.0 or (e.has_meta("kind") and Bots.TYPES.has(e.get_meta("kind")) and Bots.is_boss(e.get_meta("kind")))

# Пойманные висят внутри пузыря
func _carry() -> void:
	for i in _captured.size():
		var e: Player = _captured[i]
		if is_instance_valid(e) and e.is_alive():
			e.global_position = global_position + Vector2((i - (_captured.size() - 1) / 2.0) * 22.0, e.body_size.y * 0.1)
			e.velocity = Vector2.ZERO
			e.stun(0.3)
			e._forced_time = maxf(e._forced_time, 0.3)

func _start_lift() -> void:
	if _hold_t >= 0.0:
		return
	_hold_t = HOLD

func _capture(e: Player) -> void:
	_captured.append(e)
	# пузырь раздувается вокруг добычи (с каждым пойманным — чуть больше)
	var t := create_tween()
	t.tween_property(self, "scale", Vector2.ONE * (1.15 + 0.12 * _captured.size()), 0.25).set_trans(Tween.TRANS_BACK)
	if _captured.size() >= cap_max:
		_start_lift()                     # места больше нет — поднимает всех
	else:
		life = maxf(life, 1.2)            # ещё летит и ищет следующих
	e.stun(HOLD + 0.4)
	e._forced_time = HOLD + 0.4
	e._forced_vx = 0.0
	e._forced_no_gravity = true
	e.velocity = Vector2.ZERO
	if not e.frozen:
		e.frozen = true
		_froze[e] = true
	Fx.ring(get_parent(), global_position, radius * 1.6, Color(0.7, 1.0, 0.5, 0.9), 0.3, 4.0)
	if is_instance_valid(attacker):
		attacker._float_label("Попался!", Color(0.7, 1.0, 0.5))

func _release_all() -> void:
	for e in _captured:
		if is_instance_valid(e):
			if _froze.has(e):
				e.frozen = false
			e._forced_time = 0.0
			e._forced_no_gravity = false
			e.velocity = Vector2(0, 60)
	_captured.clear()
	_froze.clear()

func _burst(mult: float) -> void:
	if _done:
		return
	_done = true
	var world := get_parent()
	# МЕГА: пойманные получают удар газа сразу, когда пузырь лопается прямо на них
	for e in _captured:
		if is_instance_valid(e) and e.is_alive():
			e.take_damage(12, attacker if is_instance_valid(attacker) else null)
	_release_all()
	var c := GasCloud.new()
	c.team = team
	c.attacker = attacker if is_instance_valid(attacker) else null
	c.radius = cloud_r * (1.2 if mult > 1.0 else 1.0)
	c.life = cloud_life
	c.mult = mult
	c.position = global_position
	world.add_child(c)
	Fx.ring(world, global_position, radius * 1.8, Color(0.75, 1.0, 0.55, 0.9), 0.3, 5.0)
	Fx.sparks(world, global_position, Color(0.7, 1.0, 0.5), 12, 220.0, 3.0)
	queue_free()

# ---------- Ядовитое облако ----------
class GasCloud extends Node2D:
	var team := 0
	var attacker: Player
	var radius := 110.0
	var life := 3.0
	var mult := 1.0
	var _tick := 0.0
	var _t := 0.0
	var _puffs: Array = []

	func _ready() -> void:
		z_index = 5
		for k in 8:
			var pf := Polygon2D.new()
			pf.polygon = Util.circle(randf_range(0.35, 0.55) * radius, 14)
			pf.color = Color(0.55, 0.85, 0.35, 0.22)
			var a := TAU * k / 8.0 + randf() * 0.5
			pf.position = Vector2(cos(a), sin(a) * 0.6) * radius * randf_range(0.2, 0.55)
			pf.scale = Vector2(0.3, 0.3)
			add_child(pf)
			_puffs.append(pf)
			var tw := pf.create_tween()
			tw.tween_property(pf, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_BACK)

	func _physics_process(delta: float) -> void:
		_t += delta
		for i in _puffs.size():
			var pf: Polygon2D = _puffs[i]
			pf.position += Vector2(sin(_t * 1.3 + i), cos(_t * 1.1 + i * 2.0)) * 6.0 * delta
		if _t > life - 0.6:
			modulate.a = clampf((life - _t) / 0.6, 0.0, 1.0)
		if _t >= life:
			queue_free()
			return
		_tick -= delta
		if _tick > 0.0:
			return
		_tick = 0.5
		for e in get_parent().get_children():
			if e is Player and e.team != team and e.is_alive() and e.hurt_center().distance_to(global_position) < radius:
				e.take_damage(int(round(5.0 * mult)), attacker if is_instance_valid(attacker) else null)
				Fx.sparks(get_parent(), e.hurt_center(), Color(0.6, 1.0, 0.4), 3, 80.0, 2.0)
