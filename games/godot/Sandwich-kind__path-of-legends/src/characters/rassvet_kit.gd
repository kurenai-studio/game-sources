class_name RassvetKit
extends HeroKit
# ---------- РАССВЕТ — легенда за Тёмного Лорда (80-я волна Арены) ----------
# Бывший чёрный рыцарь Лорда, отказавшийся ему служить. Подобрал камень, что
# выпал из головы Воплощения Тьмы, — и камень очистился: трещины на доспехе
# светятся золотом.
# Оружие: обсидиановый двуручный меч — серия из 3 широких ударов вблизи,
#   третий тяжёлый и бросает вперёд серп света.
# «Осколок сердца»: раз за жизнь, когда здоровья меньше 30% (или удар смертелен),
#   камень вспыхивает — 2 с неуязвимости и лечение на 30%.
# 1 «Шаг тени» — телепорт за спину ближайшему врагу и удар; на старом месте
#   остаётся тёмный силуэт и через секунду взрывается. МЕГА: 3 шага подряд.
#   Арена: удар после шага оглушает.
# 2 «Затмение» — вокруг на 4 с сгущается тьма: враги внутри замедлены и ослеплены
#   (боты не стреляют), Рассвет бьёт на 30% сильнее. МЕГА: удары внутри лечат.
#   Арена: тьма шире и держится 5 с.
# 3 «Чёрное солнце» — бросает осколок камня: там, где он упадёт, 1,5 с тянет
#   врагов в точку, потом взрыв света. МЕГА: тянет вдвое дальше, взрыв оглушает.
#   Арена: взрыв сильнее и шире.
# Ульта «Восход» — крылья света: 6 с полёта, каждый удар меча бросает серп света;
#   в конце — удар о землю, волна рассвета. МЕГА: небо светлеет — Рассвет
#   лечится, враги вокруг горят. Арена: полёт 8 с.

const GOLD := Color(1.0, 0.84, 0.42)
const DUSK := Color(0.16, 0.08, 0.20)
const CUT_ANIM := ["cut1", "cut2", "big_cut"]
const CUT_HIT := [0.12, 0.12, 0.22]
const CUT_CD := [0.42, 0.42, 0.66]
const CUT_REACH := [150.0, 150.0, 190.0]
const CUT_DMG := [16, 16, 24]

var _combo := 0
var _combo_t := 0.0
var _shard := true                # «Осколок сердца» ещё не сработал в этой жизни
var _shard_fx: Node2D
var _steps := 0                   # МЕГА «Шага тени»: сколько шагов осталось
var _eclipse: Node2D
var _eclipse_t := 0.0
var _eclipse_mega := false
var _eclipse_r := 260.0
var _dawn_t := 0.0
var _dawn_mega := false
var _wings: Node2D
var _dawn_tick := 0.0
var _crash_t := 0.0

func _ready() -> void:
	if p:
		p.on_lethal = _on_lethal

# ---------- Меч ----------
func weapon(delta: float, shoot: bool) -> void:
	p.ammo = p.clip_size
	p._reloading = 0.0
	_combo_t -= delta
	if _combo_t <= 0.0:
		_combo = 0
	if not shoot or p._cooldown_left > 0.0:
		return
	var step := _combo
	_combo = (_combo + 1) % 3
	_combo_t = 1.1
	var spd := 0.6 if p.has_buff("rapid") else 1.0
	p._anim(CUT_ANIM[step])
	_after(CUT_HIT[step] * spd, _cut.bind(step))
	p._cooldown_left = CUT_CD[step] * spd

func _cut(step: int) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	_swing(CUT_REACH[step], 70.0, CUT_DMG[step], 220.0 if step == 2 else 140.0)
	var c := p.global_position + Vector2(p.facing * 18.0, -8.0)
	var col := Color(GOLD, 0.8) if _dawn_t > 0.0 or step == 2 else Color(0.85, 0.80, 0.95, 0.75)
	var arcs := [[-2.1, 0.9], [1.2, -1.6], [-2.4, 1.3]]
	var a: Array = arcs[step]
	Fx.arc(p.get_parent(), c, CUT_REACH[step] * 0.75, _ang(a[0]), _ang(a[1]), col, 0.2, 20.0 if step == 2 else 14.0)
	if step == 2 or _dawn_t > 0.0:
		_light_wave()

func _ang(a: float) -> float:
	return a if p.facing > 0 else PI - a

# Удар мечом по всем впереди (и по блокам)
func _swing(reach: float, half_h: float, dmg: int, knock: float, both := false) -> Array:
	var hit := []
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		if both or signf(to.x) == p.facing or absf(to.x) < 20.0:
			if absf(to.x) < reach + e.body_size.x / 2 and absf(to.y) < half_h + e.body_size.y / 2:
				e.take_damage(dmg, p)
				if not GasBubble._is_boss(e):
					e.velocity = Vector2((signf(to.x) if both and to.x != 0.0 else float(p.facing)) * knock, -140.0)
				hit.append(e)
	for n in p.get_parent().get_children():
		if n is Destructible and n.shield_team != p.team and not n.background \
				and n.global_position.distance_to(p.global_position) < 500.0:
			var x := 30.0
			while x <= reach:
				var y := -half_h
				while y <= half_h * 0.6:
					n.hit(p.global_position + Vector2(p.facing * x, y), Vector2(p.facing, 0), 24, 5.0, p.team,
							{"strict": true, "attacker": p, "power": 0.5})
					y += 22.0
				x += 22.0
	return hit

# Серп света вперёд
func _light_wave() -> void:
	var w := SlashWave.new()
	w.team = p.team
	w.attacker = p
	w.dir = p.facing
	w.damage = 18
	w.color = Color(GOLD, 0.85)
	w.position = p.global_position + Vector2(p.facing * 40.0, -8.0)
	if _dawn_t > 0.0 and _dawn_mega:
		w.burn = 6.0
	p.get_parent().add_child(w)

# Затмение: урон по врагам внутри тьмы лечит (МЕГА)
func on_dealt(amount: int, victim: Node) -> void:
	if _eclipse_t > 0.0 and _eclipse_mega and _in_eclipse(p) and victim is Player:
		p.heal(maxi(1, int(amount * 0.25)))

# ---------- Осколок сердца ----------
func _on_lethal() -> bool:
	if not _shard:
		return false
	p.hp = 1
	_flare_shard()
	return true

func _flare_shard() -> void:
	_shard = false
	p._invuln = maxf(p._invuln, 2.0)
	p.heal(int(p.max_hp * 0.3))
	var world := p.get_parent()
	Util.flash(world, p.global_position, 160.0, Color(1.0, 0.9, 0.6, 0.9))
	Fx.ring(world, p.global_position, 180.0, GOLD, 0.45, 8.0)
	Fx.sparks(world, p.global_position, GOLD, 18, 260.0, 4.0)
	p._float_label("Осколок сердца!", GOLD)
	_shard_fx = Node2D.new()                         # золотое сияние, пока неуязвим
	var g := Polygon2D.new()
	g.polygon = Util.circle(maxf(p.body_size.x, p.body_size.y) * 0.7, 20)
	g.color = Color(1.0, 0.85, 0.45, 0.3)
	_shard_fx.add_child(g)
	p.add_child(_shard_fx)
	var t := _shard_fx.create_tween()
	t.tween_interval(1.6)
	t.tween_property(_shard_fx, "modulate:a", 0.0, 0.4)
	t.tween_callback(_shard_fx.queue_free)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	p._cd[i] = maxf(0.0, p._cd[i] - delta * p._cd_speed())
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"dawn_step":
			_steps = 2 if mega else 0
			_shadow_step({})
		"dawn_eclipse":
			_start_eclipse(mega)
		"black_sun":
			_throw_sun(mega)

# ----- 1. Шаг тени -----
func _shadow_step(done: Dictionary) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var world := p.get_parent()
	var from := p.global_position
	var target: Player = null
	var bd := 520.0
	for e in _enemies():
		if done.has(e) or e.cutscene_shield:
			continue
		var d: float = e.global_position.distance_to(from)
		if d < bd:
			bd = d
			target = e
	var to := from + Vector2(p.facing * 280.0, 0)
	if target:
		var side := signf(target.global_position.x - from.x)
		if side == 0.0:
			side = float(p.facing)
		var feet_y: float = target.global_position.y + target.body_size.y / 2
		to = Vector2(target.global_position.x + side * (target.body_size.x / 2 + p.body_size.x / 2 + 16.0), feet_y - p.body_size.y / 2 - 2.0)
		if _blocked(to):
			to.x = target.global_position.x - side * (target.body_size.x / 2 + p.body_size.x / 2 + 16.0)
		done[target] = true
	if _blocked(to):
		to = from
	to.x = clampf(to.x, 40.0, p.map_w - 40.0)
	_silhouette(from)
	p.global_position = to
	p.velocity = Vector2.ZERO
	if target:
		p.facing = 1 if target.global_position.x > to.x else -1
		p._update_eye()
	Fx.sparks(world, to, Color(0.55, 0.30, 0.75), 10, 200.0, 4.0)
	p._anim("cut1")
	var hit := _swing(150.0, 70.0, 22, 160.0)
	Fx.arc(world, to + Vector2(p.facing * 18.0, -8.0), 110.0, _ang(-2.1), _ang(0.9), Color(0.75, 0.55, 1.0, 0.85), 0.2, 16.0)
	if Balance.arena(p):
		for e in hit:
			e.stun(0.6)
	p._invuln = maxf(p._invuln, 0.25)
	if _steps > 0:
		_steps -= 1
		_after(0.28, _shadow_step.bind(done))

func _blocked(at: Vector2) -> bool:
	var q := PhysicsShapeQueryParameters2D.new()
	var rs := RectangleShape2D.new()
	rs.size = p.body_size - Vector2(6, 6)
	q.shape = rs
	q.transform = Transform2D(0, at)
	q.collision_mask = Layer.WORLD
	return not p.get_world_2d().direct_space_state.intersect_shape(q, 1).is_empty()

# Тёмный силуэт на старом месте — через секунду взрывается
func _silhouette(at: Vector2) -> void:
	var world := p.get_parent()
	var s := Node2D.new()
	s.position = at
	s.z_index = 5
	var bs := p.body_size
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-bs.x * 0.4, bs.y * 0.5), Vector2(-bs.x * 0.45, -bs.y * 0.1), Vector2(-bs.x * 0.25, -bs.y * 0.3),
			Vector2(-bs.x * 0.2, -bs.y * 0.5), Vector2(bs.x * 0.2, -bs.y * 0.5), Vector2(bs.x * 0.25, -bs.y * 0.3), Vector2(bs.x * 0.45, -bs.y * 0.1), Vector2(bs.x * 0.4, bs.y * 0.5)])
	body.color = Color(0.20, 0.08, 0.28, 0.85)
	s.add_child(body)
	world.add_child(s)
	var team := p.team
	var who := p
	var big := Balance.arena(p)
	var t := s.create_tween()
	t.tween_property(s, "scale", Vector2(1.15, 1.15), 0.9)
	t.parallel().tween_property(body, "color", Color(0.55, 0.25, 0.85, 0.95), 0.9)
	t.tween_callback(func():
		var w2 := s.get_parent()
		if w2 == null:
			return
		var r := 130.0 if big else 105.0
		Fx.ring(w2, s.global_position, r, Color(0.7, 0.4, 1.0, 0.9), 0.35, 8.0)
		Fx.sparks(w2, s.global_position, Color(0.6, 0.3, 0.9), 14, 260.0, 4.0)
		for n in w2.get_children():
			if n is Player and n.team != team and n.is_alive() and n.global_position.distance_to(s.global_position) < r + n.body_size.x * 0.4:
				n.take_damage(18, who if is_instance_valid(who) else null)
		s.queue_free())

# ----- 2. Затмение -----
func _start_eclipse(mega: bool) -> void:
	if is_instance_valid(_eclipse):
		_eclipse.queue_free()
	var arena := Balance.arena(p)
	_eclipse_mega = mega
	_eclipse_t = 5.0 if arena else 4.0
	_eclipse_r = 340.0 if arena else 260.0
	p._anim("cast")
	_eclipse = Node2D.new()
	_eclipse.z_index = 6
	_eclipse.position = p.global_position
	var dome := Polygon2D.new()
	dome.polygon = Util.circle(_eclipse_r, 36)
	dome.color = Color(0.06, 0.02, 0.10, 0.62)
	_eclipse.add_child(dome)
	var rim := Line2D.new()
	var pts := Util.circle(_eclipse_r, 36)
	pts.append(pts[0])
	rim.points = pts
	rim.width = 4.0
	rim.default_color = Color(0.60, 0.35, 0.95, 0.8) if not mega else Color(GOLD, 0.85)
	_eclipse.add_child(rim)
	for k in 8:                                           # клочья тьмы по краю
		var wisp := Polygon2D.new()
		var a := TAU * k / 8.0
		wisp.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(0, -26), Vector2(14, 0)])
		wisp.position = Vector2.from_angle(a) * _eclipse_r
		wisp.rotation = a + PI / 2
		wisp.color = Color(0.10, 0.03, 0.15, 0.8)
		_eclipse.add_child(wisp)
	p.get_parent().add_child(_eclipse)
	_eclipse.scale = Vector2(0.2, 0.2)
	_eclipse.create_tween().tween_property(_eclipse, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)

func _in_eclipse(n: Node2D) -> bool:
	return is_instance_valid(_eclipse) and n.global_position.distance_to(_eclipse.global_position) < _eclipse_r

func _eclipse_tick(delta: float) -> void:
	_eclipse_t -= delta
	_eclipse.rotation += delta * 0.4
	for e in _enemies():
		if _in_eclipse(e):
			e.slow(0.2, 0.55)
			if e.is_bot:
				e._cooldown_left = maxf(e._cooldown_left, 0.25)     # ослеплён: не стреляет
	if _in_eclipse(p):
		p.boost(1.3, 0.2)
	if _eclipse_t <= 0.0:
		var t := _eclipse.create_tween()
		t.tween_property(_eclipse, "modulate:a", 0.0, 0.35)
		t.tween_callback(_eclipse.queue_free)
		_eclipse = null

# ----- 3. Чёрное солнце -----
func _throw_sun(mega: bool) -> void:
	p._anim("throw")
	var s := BlackSun.new()
	s.team = p.team
	s.attacker = p
	s.mega = mega
	s.arena = Balance.arena(p)
	s.vel = Vector2(p.facing * 640.0, -360.0)
	s.position = (p.rig.muzzle() if p.rig else p.global_position) + Vector2(0, -6)
	p.get_parent().add_child(s)

# ---------- Ульта: Восход ----------
func ult() -> void:
	if _dawn_t > 0.0:
		return
	_dawn_mega = p._mega_ab()
	_dawn_t = 8.0 if Balance.arena(p) else 6.0
	p.fly_free = true
	p._anim("invoke")
	p.velocity = Vector2(0, -420)
	var world := p.get_parent()
	Util.flash(world, p.global_position, 200.0, Color(1.0, 0.9, 0.6, 0.85))
	Fx.ring(world, p.global_position, 220.0, GOLD, 0.5, 8.0)
	p._float_label("Восход!", GOLD)
	_wings = Node2D.new()
	_wings.z_index = -1
	var bs := p.body_size
	for s in [-1.0, 1.0]:
		var w := Polygon2D.new()
		w.polygon = PackedVector2Array([Vector2(0, -bs.y * 0.15), Vector2(s * bs.x * 1.4, -bs.y * 0.75), Vector2(s * bs.x * 1.9, -bs.y * 0.55),
				Vector2(s * bs.x * 1.5, -bs.y * 0.3), Vector2(s * bs.x * 1.8, -bs.y * 0.1), Vector2(s * bs.x * 1.2, 0.0), Vector2(s * bs.x * 0.9, bs.y * 0.2)])
		w.color = Color(1.0, 0.88, 0.55, 0.75)
		w.scale = Vector2(0.1, 0.1)
		_wings.add_child(w)
		w.create_tween().tween_property(w, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK)
	p.add_child(_wings)

func ulting() -> bool:
	return _dawn_t > 0.0

func _dawn_tick_fn(delta: float) -> void:
	_dawn_t -= delta
	if is_instance_valid(_wings):
		for k in _wings.get_child_count():
			(_wings.get_child(k) as Node2D).rotation = sin(Time.get_ticks_msec() * 0.008 + k * PI) * 0.15
	if randf() < 0.5:
		Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-30, 30), randf_range(-20, 30)), GOLD, 1, 90.0, 3.0)
	if _dawn_mega:
		_dawn_tick -= delta
		if _dawn_tick <= 0.0:
			_dawn_tick = 1.0
			p.heal(4)
			for e in _enemies():
				if e.global_position.distance_to(p.global_position) < 600.0:
					e.burn(2.0, 6.0, p)
	if _dawn_t <= 0.0:
		_dawn_crash()

# Конец ульты: удар о землю, волна рассвета
func _dawn_crash() -> void:
	_dawn_t = 0.0
	p.fly_free = false
	if is_instance_valid(_wings):
		var t := _wings.create_tween()
		t.tween_property(_wings, "modulate:a", 0.0, 0.3)
		t.tween_callback(_wings.queue_free)
	_wings = null
	_crash_t = 1.2                                     # пикирует вниз до земли
	p.velocity = Vector2(0, 1600.0)
	p._invuln = maxf(p._invuln, 0.4)

func _dawn_wave() -> void:
	var world := p.get_parent()
	var feet := p.global_position + Vector2(0, p.body_size.y / 2)
	Fx.shake(world, 9.0)
	Util.flash(world, feet + Vector2(0, -40), 220.0, Color(1.0, 0.9, 0.6, 0.9))
	Fx.ring(world, feet, 280.0, GOLD, 0.5, 10.0, 0.3)
	Fx.cracks(world, feet, GOLD, 120.0)
	for e in _enemies():
		var d: Vector2 = e.global_position - feet
		if absf(d.x) < 260.0 + e.body_size.x * 0.4 and d.y > -320.0 and d.y < 60.0:
			e.take_damage(40, p)
			if not GasBubble._is_boss(e):
				e.velocity = Vector2(signf(d.x + 0.01) * 520.0, -420.0)

# ---------- Каждый кадр ----------
func _physics_process(delta: float) -> void:
	if p == null or not p.is_alive():
		return
	if _shard and p.hp < p.max_hp * 0.3 and p.hp > 0:
		_flare_shard()
	if _eclipse_t > 0.0 and is_instance_valid(_eclipse):
		_eclipse_tick(delta)
	if _dawn_t > 0.0:
		_dawn_tick_fn(delta)
	if _crash_t > 0.0:
		_crash_t -= delta
		p.velocity.y = maxf(p.velocity.y, 1400.0)
		if p.is_on_floor() or _crash_t <= 0.0:
			_crash_t = 0.0
			_dawn_wave()

func on_death() -> void:
	super()
	_dawn_t = 0.0
	_crash_t = 0.0
	_steps = 0
	if is_instance_valid(_wings):
		_wings.queue_free()
	_wings = null
	if is_instance_valid(_eclipse):
		_eclipse.queue_free()
	_eclipse = null
	_eclipse_t = 0.0
	_shard = true                                     # после возрождения камень снова готов


# =====================================================================
# Осколок камня: летит по дуге, на месте падения тянет врагов, потом взрыв света
class BlackSun extends Node2D:
	var team := 0
	var attacker: Player
	var mega := false
	var arena := false
	var vel := Vector2.ZERO
	var _landed := false
	var _t := 0.0
	var _tick := 0.0
	var _core: Polygon2D
	var _rings: Array = []

	func _ready() -> void:
		z_index = 7
		_core = Polygon2D.new()
		_core.polygon = PackedVector2Array([Vector2(0, -9), Vector2(7, 0), Vector2(0, 9), Vector2(-7, 0)])
		_core.color = Color(1.0, 0.84, 0.42)
		add_child(_core)

	func _foes() -> Array:
		var res := []
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
				res.append(n)
		return res

	func _physics_process(delta: float) -> void:
		_t += delta
		if not _landed:
			vel.y += 1500.0 * delta
			var next := global_position + vel * delta
			var hit := get_world_2d().direct_space_state.intersect_ray(
					PhysicsRayQueryParameters2D.create(global_position, next, Layer.WORLD | Layer.FRAME))
			var touch := false
			for e in _foes():
				if e.hurt_center().distance_to(next) < maxf(e.body_size.x, e.body_size.y) * 0.5 + 10.0:
					touch = true
			_core.rotation += delta * 12.0
			if not hit.is_empty() or touch or _t > 2.0:
				global_position = hit["position"] + Vector2(0, -30) if not hit.is_empty() else next
				_open()
			else:
				global_position = next
			return
		# чёрная дыра
		var pull_r := 600.0 if mega else 300.0
		for k in _rings.size():
			(_rings[k] as Node2D).rotation += delta * (2.5 + k)
		_tick -= delta
		for e in _foes():
			var d: Vector2 = global_position - e.global_position
			if d.length() < pull_r:
				if not GasBubble._is_boss(e):
					e.push_wind(signf(d.x) * 260.0)
					if absf(d.y) > 30.0 and d.y < 0.0:
						e.velocity.y = minf(e.velocity.y, -120.0)
				if _tick <= 0.0 and d.length() < 140.0:
					e.take_damage(4, attacker if is_instance_valid(attacker) else null)
		if _tick <= 0.0:
			_tick = 0.3
		if randf() < 0.7:
			var s := Polygon2D.new()
			s.polygon = Util.circle(3.0, 6)
			s.color = Color(1.0, 0.85, 0.5, 0.8)
			s.position = global_position + Vector2.from_angle(randf() * TAU) * randf_range(pull_r * 0.4, pull_r * 0.8)
			s.z_index = 6
			get_parent().add_child(s)
			var tw := s.create_tween()
			tw.tween_property(s, "position", global_position, 0.5).set_ease(Tween.EASE_IN)
			tw.tween_callback(s.queue_free)
		if _t >= 1.5:
			_burst()

	func _open() -> void:
		_landed = true
		_t = 0.0
		var hole := Polygon2D.new()
		hole.polygon = Util.circle(26.0, 18)
		hole.color = Color(0.02, 0.0, 0.04)
		add_child(hole)
		move_child(hole, 0)
		for k in 3:
			var ring := Line2D.new()
			var pts := Util.circle(38.0 + k * 20.0, 24)
			pts.append(pts[0])
			ring.points = pts
			ring.width = 4.0 - k
			ring.default_color = Color(1.0, 0.84, 0.42, 0.85 - k * 0.2)
			add_child(ring)
			_rings.append(ring)
		scale = Vector2(0.2, 0.2)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)

	func _burst() -> void:
		var world := get_parent()
		var r := 220.0 if arena else 170.0
		if mega:
			r += 40.0
		var dmg := 34 if arena else 26
		Util.flash(world, global_position, r, Color(1.0, 0.92, 0.65, 0.95))
		Fx.ring(world, global_position, r * 1.2, Color(1.0, 0.84, 0.42, 0.9), 0.45, 9.0)
		Fx.sparks(world, global_position, Color(1.0, 0.85, 0.5), 20, 300.0, 4.0)
		for e in _foes():
			if e.global_position.distance_to(global_position) < r + e.body_size.x * 0.4:
				e.take_damage(dmg, attacker if is_instance_valid(attacker) else null)
				if mega:
					e.stun(1.2)
				elif not GasBubble._is_boss(e):
					e.velocity = Vector2(signf(e.global_position.x - global_position.x + 0.01) * 300.0, -380.0)
		queue_free()
