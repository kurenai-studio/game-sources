class_name OsokaKit
extends HeroKit
# ---------- ОСОКА — легенда за Трясинного Владыку (60-я волна Арены) ----------
# Оружие: комья тины по дуге. Попадание ранит и чуть замедляет, упавший ком
#   оставляет лужицу трясины на 3 с.
# «Своя трясина»: в любой луже грязи (своей или на карте Болото) и в болоте
#   ульты Осока не вязнет, а скользит на 25% быстрее и бьёт на 20% сильнее.
#   Враги в её лужах вязнут.
# 1 «Нырок в трясину» — уходит под землю на 1,2 с (неуязвима, видно только пузыри),
#   можно вести; выныривает гейзером грязи, который подбрасывает врагов.
#   Нажми ещё раз — вынырнет раньше. МЕГА: 2 с под землёй и 3 гейзера подряд.
#   Арена: после гейзера остаётся большая лужа на 5 с.
# 2 «Болотный пузырь» — см. GasBubble (МЕГА — пузырь-ловушка).
# 3 «Язык Квака» — жаба на плече выстреливает языком вперёд: ловит врага,
#   подтягивает к Осоке в лужу и оглушает. Промах в стену или платформу —
#   подтягивает саму Осоку. МЕГА: Квак прыгает врагу на голову и кусает 3 раза.
#   Арена: язык хватает двух врагов подряд.
# Ульта «Пробуждение топи» — см. SwampWake.

const MUD := Color(0.30, 0.36, 0.20)
const DIVE_T := 1.2
const DIVE_T_MEGA := 2.0
const TONGUE_RANGE := 600.0
const TONGUE_SPEED := 2200.0

var _mud_t := 0.0                # стоит в трясине — бонус «Своя трясина»
var _mud_fx := 0.0
var _dive_t := 0.0
var _dive_mega := false
var _mound: Node2D
var _bub_t := 0.0
var _wake: SwampWake
# язык
var _tongue: Line2D
var _tip := Vector2.ZERO
var _tip_dir := Vector2.RIGHT
var _tip_dist := 0.0
var _tongue_state := ""          # "", "out", "pull_enemy", "pull_self", "back"
var _caught: Array = []
var _tongue_mega := false
var _anchor_pt := Vector2.ZERO
var _pull_left := 0.0

# ---------- Стрельба: комья тины ----------
func weapon(delta: float, shoot: bool) -> void:
	if _dive_t > 0.0:
		return
	var rapid := p.has_buff("rapid")
	if p._reloading > 0.0:
		p._reloading -= delta
		if p._reloading <= 0.0:
			p._reloading = 0.0
			p.ammo = p.clip_size
	elif not p.is_bot and Input.is_action_just_pressed(p.prefix + "_reload") and p.ammo < p.clip_size:
		p._reloading = p.reload_time
	if rapid:
		p._reloading = 0.0
		p.ammo = p.clip_size
	if not shoot or p._cooldown_left > 0.0 or p._reloading > 0.0:
		return
	var s := _throw("tina", _lob(Vector2(p.facing * 760.0, -300.0) + Vector2(p.velocity.x * 0.2, 0), 760.0), p.bullet_damage)
	if rapid and p.is_mega("rapid"):
		s.scale = Vector2(1.3, 1.3)
	p._anim("throw")
	p._cooldown_left = p.fire_cooldown * (0.5 if rapid else 1.0)
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

# Лужа (своя, карты или ульты) под ногами — зовётся каждый кадр, пока Осока в ней
func in_mud() -> void:
	_mud_t = 0.15

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	var speed_k := 2.0 if (i == 0 and is_instance_valid(_wake)) else 1.0     # в болоте ульты Нырок быстрее
	p._cd[i] = maxf(0.0, p._cd[i] - delta * p._cd_speed() * speed_k)
	if not Input.is_action_just_pressed(action):
		return
	if ab == "mud_dive" and _dive_t > 0.0:
		_emerge()                                   # нажала ещё раз — выныривает раньше
		return
	if p._cd[i] > 0.0 or _dive_t > 0.0 or _tongue_state != "":
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"mud_dive":
			_dive(mega)
		"gas_bubble":
			p._anim("cast")
			var b := GasBubble.new()
			b.team = p.team
			b.attacker = p
			b.dir = p.facing
			b.mega = mega
			b.arena = Balance.arena(p)
			b.position = p.global_position + Vector2(p.facing * (p.body_size.x / 2 + 40.0), -14.0)
			p.get_parent().add_child(b)
			Fx.sparks(p.get_parent(), b.position, Color(0.7, 1.0, 0.5), 6, 120.0, 3.0)
		"frog_tongue":
			_shoot_tongue(mega)

# ---------- 1. Нырок в трясину ----------
func _dive(mega: bool) -> void:
	var world := p.get_parent()
	_dive_mega = mega
	_dive_t = DIVE_T_MEGA if mega else DIVE_T
	p._invuln = maxf(p._invuln, _dive_t + 0.15)
	p.move_mult = 1.5
	p._no_jump_t = maxf(p._no_jump_t, _dive_t)
	if p._rig_root:
		p._rig_root.modulate.a = 0.0
	p._anim("cast")
	_splash(world, p.global_position + Vector2(0, p.body_size.y / 2), 1.0)
	# бугорок грязи с пузырями — так видно, где она под землёй
	_mound = Node2D.new()
	_mound.z_index = 3
	var hump := Polygon2D.new()
	hump.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(-16, -9), Vector2(0, -13), Vector2(16, -9), Vector2(26, 0)])
	hump.color = MUD
	_mound.add_child(hump)
	var moss := Polygon2D.new()
	moss.polygon = PackedVector2Array([Vector2(-10, -11), Vector2(10, -11), Vector2(4, -14), Vector2(-5, -14)])
	moss.color = Color(0.40, 0.56, 0.26)
	_mound.add_child(moss)
	world.add_child(_mound)
	_place_mound()

func _place_mound() -> void:
	if is_instance_valid(_mound):
		_mound.global_position = p.global_position + Vector2(0, p.body_size.y / 2)

func _emerge() -> void:
	if _dive_t <= 0.0:
		return
	_dive_t = 0.0
	p.move_mult = 1.0
	p._invuln = maxf(p._invuln, 0.2)
	p._no_jump_t = 0.0
	if p._rig_root:
		p._rig_root.modulate.a = 1.0
	if is_instance_valid(_mound):
		_mound.queue_free()
	p._anim("roots")
	var feet := p.global_position + Vector2(0, p.body_size.y / 2)
	if _dive_mega:
		for k in 3:
			_after(k * 0.16, _geyser.bind(feet.x + p.facing * k * 130.0, feet.y, k == 0))
	else:
		_geyser(feet.x, feet.y, true)

func _geyser(x: float, gy: float, first: bool) -> void:
	var world := p.get_parent()
	if not is_instance_valid(world):
		return
	var at := Vector2(clampf(x, 40.0, p.map_w - 40.0), gy)
	for e in _enemies():
		var to: Vector2 = e.global_position - at
		if absf(to.x) < 90.0 + e.body_size.x * 0.4 and to.y < 40.0 and to.y > -260.0:
			e.take_damage(22 if _dive_mega else 18, p)
			e.velocity = Vector2(signf(to.x) * 120.0, -820.0)
	# столб грязи
	var col := Node2D.new()
	col.position = at
	col.z_index = 4
	var jet := Polygon2D.new()
	jet.polygon = PackedVector2Array([Vector2(-34, 0), Vector2(-20, -150), Vector2(-8, -210), Vector2(8, -205), Vector2(22, -150), Vector2(34, 0)])
	jet.color = Color(0.34, 0.38, 0.22, 0.9)
	col.add_child(jet)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(-6, -170), Vector2(6, -170), Vector2(12, 0)])
	core.color = Color(0.50, 0.60, 0.32, 0.8)
	col.add_child(core)
	col.scale = Vector2(0.6, 0.1)
	world.add_child(col)
	var t := col.create_tween()
	t.tween_property(col, "scale", Vector2(1.0, 1.0), 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(col, "scale", Vector2(0.7, 0.0), 0.35).set_delay(0.12)
	t.tween_callback(col.queue_free)
	_splash(world, at, 1.6)
	Fx.ring(world, at, 120.0, Color(0.55, 0.75, 0.35, 0.9), 0.35, 6.0, 0.3)
	if first:
		Fx.shake(world, 4.0)
	# Арена: после гейзера — большая лужа
	if Balance.arena(p):
		_puddle(at, 250.0, 5.0)

func _puddle(at: Vector2, width: float, life: float) -> void:
	var pud := SwampBits.MudPuddle.new()
	pud.width = width
	pud.life = life
	pud.team = p.team
	pud.position = at
	p.get_parent().call_deferred("add_child", pud)

func _splash(world: Node, at: Vector2, k: float) -> void:
	Fx.sparks(world, at + Vector2(0, -4), MUD, int(10 * k), 220.0 * k, 4.0, true)

# ---------- 3. Язык Квака ----------
func _shoot_tongue(mega: bool) -> void:
	_tongue_mega = mega
	_tongue_state = "out"
	_caught.clear()
	_tip = _frog_point()
	var e := _nearest_enemy(TONGUE_RANGE + 60.0)
	_tip_dir = Vector2(p.facing, -0.05).normalized()
	if e and signf(e.global_position.x - p.global_position.x) == p.facing and absf(e.global_position.y - p.global_position.y) < 200.0:
		_tip_dir = (e.hurt_center() - _tip).normalized()       # чуть подруливает на врага впереди
	_tip_dist = 0.0
	_tongue = Line2D.new()
	_tongue.width = 5.0
	_tongue.default_color = Color(0.92, 0.45, 0.50)
	_tongue.begin_cap_mode = Line2D.LINE_CAP_ROUND
	_tongue.end_cap_mode = Line2D.LINE_CAP_ROUND
	_tongue.z_index = 6
	p.get_parent().add_child(_tongue)
	p._anim("throw")

func _frog_point() -> Vector2:
	if p.rig and p.rig.has_method("frog_point"):
		return p.rig.frog_point()
	return p.global_position + Vector2(p.facing * 10.0, -p.body_size.y * 0.3)

func _tongue_tick(delta: float) -> void:
	var world := p.get_parent()
	var base := _frog_point()
	match _tongue_state:
		"out":
			var step := TONGUE_SPEED * delta
			var next := _tip + _tip_dir * step
			# стена или платформа — цепляется (если ещё никого не поймал)
			var hit := p.get_world_2d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters2D.create(_tip, next, Layer.WORLD | Layer.FRAME, [p.get_rid()]))
			if not hit.is_empty() and _caught.is_empty():
				_anchor_pt = hit["position"]
				_tip = _anchor_pt
				_start_self_pull()
				return
			_tip = next
			_tip_dist += step
			var cap := 2 if Balance.arena(p) else 1
			for e in _enemies():
				if e in _caught or e.cutscene_shield:
					continue
				if e.hurt_center().distance_to(_tip) < maxf(e.body_size.x, e.body_size.y) * 0.5 + 14.0:
					_caught.append(e)
					Fx.sparks(world, _tip, Color(0.95, 0.5, 0.55), 6, 120.0, 3.0)
					if _caught.size() >= cap:
						break
			if _caught.size() >= cap or (_tip_dist >= TONGUE_RANGE):
				if _caught.is_empty():
					_tongue_state = "back"
					p._float_label("Мимо!", Color(0.8, 0.85, 0.8))
				else:
					_tongue_state = "pull_enemy"
					_pull_left = 0.45
		"pull_enemy":
			_pull_left -= delta
			var alive := _caught.filter(func(x): return is_instance_valid(x) and x.is_alive())
			for i in alive.size():
				var e: Player = alive[i]
				if GasBubble._is_boss(e):
					continue                                  # босса не сдвинуть — только задело
				var goal := p.global_position + Vector2(p.facing * (p.body_size.x / 2 + e.body_size.x / 2 + 18.0 + i * 46.0), p.body_size.y / 2 - e.body_size.y / 2)
				e.global_position = e.global_position.move_toward(goal, 1500.0 * delta)
				e.velocity = Vector2.ZERO
			if not alive.is_empty():
				_tip = alive[0].hurt_center()
			if _pull_left <= 0.0:
				_end_enemy_pull(alive)
		"pull_self":
			_pull_left -= delta
			_tip = _anchor_pt
			if _pull_left <= 0.0 or p.global_position.distance_to(_anchor_pt) < 50.0:
				_tongue_state = "back"
		"back":
			_tip = _tip.move_toward(base, TONGUE_SPEED * 1.4 * delta)
			if _tip.distance_to(base) < 8.0:
				_end_tongue()
				return
	if is_instance_valid(_tongue):
		_tongue.points = PackedVector2Array([base, _tip])

func _start_self_pull() -> void:
	_tongue_state = "pull_self"
	_pull_left = 0.35
	var to := _anchor_pt - p.global_position
	var v := to.normalized() * clampf(to.length() * 3.2, 600.0, 1250.0)
	v.y -= 200.0
	p._forced_time = 0.3
	p._forced_vx = v.x
	p._forced_no_gravity = false
	p.velocity.y = v.y
	Fx.sparks(p.get_parent(), _anchor_pt, Color(0.95, 0.5, 0.55), 5, 100.0, 3.0)

func _end_enemy_pull(alive: Array) -> void:
	var world := p.get_parent()
	for e in alive:
		var feet := Vector2(e.global_position.x, e.global_position.y + e.body_size.y / 2)
		e.take_damage(8, p)
		if GasBubble._is_boss(e):
			e.slow(1.5, 0.6, "mud")
		else:
			e.stun(0.5)
		_puddle(feet, 120.0, 4.0)
		_splash(world, feet, 1.0)
	if _tongue_mega and not alive.is_empty():
		_frog_jump(alive[0])
	_tongue_state = "back"

func _end_tongue() -> void:
	_tongue_state = ""
	_caught.clear()
	if is_instance_valid(_tongue):
		_tongue.queue_free()
	_tongue = null

# МЕГА: Квак прыгает врагу на голову и кусает 3 раза, потом возвращается на плечо
func _frog_jump(e: Player) -> void:
	var world := p.get_parent()
	if p.rig and p.rig.has_method("show_frog"):
		p.rig.show_frog(false)
	var frog := Node2D.new()
	frog.z_index = 7
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-11, 0), Vector2(-9, -9), Vector2(0, -12), Vector2(9, -9), Vector2(11, 0)])
	body.color = Color(0.40, 0.66, 0.28)
	frog.add_child(body)
	for sx in [-5.0, 5.0]:
		var eye := Polygon2D.new()
		eye.polygon = Util.circle(3.0, 8)
		eye.color = Color(0.52, 0.78, 0.36)
		eye.position = Vector2(sx, -12)
		frog.add_child(eye)
		var pupil := Polygon2D.new()
		pupil.polygon = Util.circle(1.4, 6)
		pupil.color = Color(0.05, 0.05, 0.04)
		pupil.position = Vector2(sx, -12)
		frog.add_child(pupil)
	frog.global_position = _frog_point()
	world.add_child(frog)
	var head := func() -> Vector2:
		return e.global_position + Vector2(0, -e.body_size.y / 2) if is_instance_valid(e) else frog.global_position
	var t := frog.create_tween()
	t.tween_method(func(k: float):
		var a: Vector2 = _frog_point()
		var b: Vector2 = head.call()
		frog.global_position = a.lerp(b, k) + Vector2(0, -sin(k * PI) * 70.0), 0.0, 1.0, 0.3)
	for k in 3:
		t.tween_callback(func():
			var hp: Vector2 = head.call()
			frog.global_position = hp
			frog.scale = Vector2(1.3, 0.7)
			if is_instance_valid(e) and e.is_alive():
				e.take_damage(6, p)
				Fx.sparks(world, hp, Color(0.95, 0.5, 0.5), 5, 120.0, 3.0))
		t.tween_property(frog, "scale", Vector2.ONE, 0.2)
	t.tween_method(func(k: float):
		var a: Vector2 = head.call()
		var b: Vector2 = _frog_point()
		frog.global_position = a.lerp(b, k) + Vector2(0, -sin(k * PI) * 60.0), 0.0, 1.0, 0.3)
	t.tween_callback(func():
		frog.queue_free()
		if is_instance_valid(p) and p.rig and p.rig.has_method("show_frog"):
			p.rig.show_frog(true))

# ---------- Ульта: Пробуждение топи ----------
func ult() -> void:
	if is_instance_valid(_wake):
		return
	p._anim("slam")
	var w := SwampWake.new()
	w.team = p.team
	w.owner_p = p
	w.mega = p._mega_ab()
	w.arena = Balance.arena(p)
	w.position = p.global_position + Vector2(0, p.body_size.y / 2)
	p.get_parent().add_child(w)
	_wake = w
	Fx.rune_circle(p.get_parent(), p.global_position + Vector2(0, p.body_size.y / 2), 80.0, Color(0.55, 0.85, 0.35, 0.9), 1.0)

func ulting() -> bool:
	return is_instance_valid(_wake)

# ---------- Каждый кадр ----------
func _physics_process(delta: float) -> void:
	if p == null or not p.is_alive():
		return
	if _dive_t > 0.0:
		_dive_t -= delta
		_place_mound()
		_bub_t -= delta
		if _bub_t <= 0.0:
			_bub_t = 0.07
			Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-14, 14), p.body_size.y / 2 - 6), Color(0.45, 0.6, 0.3), 2, 70.0, 3.0, true)
		if _dive_t <= 0.0:
			_dive_t = 0.0001
			_emerge()
	if _tongue_state != "":
		_tongue_tick(delta)
	# «Своя трясина»: быстрее и сильнее
	if _mud_t > 0.0:
		_mud_t -= delta
		if _dive_t <= 0.0:
			p.move_mult = 1.25
		p.boost(1.2, 0.2)
		_mud_fx -= delta
		if _mud_fx <= 0.0 and absf(p.velocity.x) > 60.0:
			_mud_fx = 0.12
			Fx.sparks(p.get_parent(), p.global_position + Vector2(-p.facing * 10.0, p.body_size.y / 2 - 4), Color(0.5, 0.75, 0.35), 2, 60.0, 2.5, true)
		if _mud_t <= 0.0 and _dive_t <= 0.0:
			p.move_mult = 1.0

func on_death() -> void:
	super()
	if _dive_t > 0.0:
		_dive_t = 0.0
		if is_instance_valid(_mound):
			_mound.queue_free()
	if p._rig_root:
		p._rig_root.modulate.a = 1.0
	_end_tongue()
	if p.rig and p.rig.has_method("show_frog"):
		p.rig.show_frog(true)
	_mud_t = 0.0
	p.move_mult = 1.0
