class_name FarBrain
extends Node
# ---------- Особое поведение боссов дальних земель ----------
#   jotun      — Ётун Стужа: морозное дыхание (конус). Кого заденет, тот покрывается
#                инеем; а кто уже был в инее — вмерзает в глыбу льда. Вокруг — позёмка.
#   storm_lord — Громовник, Владыка Бури: парит над облачком, вокруг искрит.
#                «Перегрузка»: взлетает и копит разряд, громоотводы светятся. Кто встал
#                у громоотвода — молния уходит в него и бьёт обратно в Владыку (он падает
#                оглушённым, урон ×2). Остальных бьёт огромная молния.
#   cerberus   — Цербер: огненный рывок, за ним остаётся горящая земля.
#   dark_lord  — Тёмный Лорд: «Затмение» — зал гаснет, видны только его глаза;
#                он исчезает и трижды бросается из темноты (каждый раз глаза
#                вспыхивают перед броском). Повергнутый, встаёт в истинном облике
#                (вторая фаза): огненные крылья, пылающий камень в груди, небо горит,
#                столбы адского пламени, рывок на крыльях и чёрная дыра — после неё
#                Лорд выдыхается (камень гаснет, урон ×2).
#                Перед второй фазой Лорд взмывает сквозь свод тронного зала — бой
#                переходит на вершину цитадели под багровым вихрем. Повергнутый
#                во второй раз, он отдаёт себя тьме — третья фаза, «Воплощение
#                Тьмы» (см. DarkAvatar).

var p: Player
var kind := ""
var _t := 0.0
# ----- Ётун -----
var _breath_t := 0.0
var _breath_hit := {}
var _breath_tick := 0.0
# ----- Громовник -----
var _cloud: Node2D
var _lift := 0.0
var _over := ""
var _over_t := 0.0
var _over_cd := 0.0
var _marks: Array = []
var _rods: Array = []
# ----- Цербер -----
var _charge_t := 0.0
var _charge_dir := 1.0
var _charge_hit := {}
var _trail_x := 0.0
# ----- Тёмный Лорд -----
var _gem: Polygon2D
var _eclipse_t := 0.0
var _eclipse_step := 0.0
var _eclipse_n := 0
var _eyes: Node2D
var _cm: CanvasModulate
var _cm_color := Color.WHITE
var _phase2 := false
var _waking := false
var _wings: Node2D
var _sky: Node2D
var _hole_t := 0.0
var _hole_fx: Node2D
var _hole_tick := 0.0
var _dash_t := 0.0
var _dash_dir := 1.0
var _dash_hit := {}
var _rig_y := 0.0
var _last := false
const HOLE_T := 3.2

func _ready() -> void:
	name = "FarBrain"
	match kind:
		"storm_lord":
			_lift = 24.0
			_cloud = Node2D.new()
			_cloud.z_index = 1
			for k in 6:
				var c := Polygon2D.new()
				c.polygon = Util.circle(randf_range(16, 26), 12)
				c.color = Color(0.62, 0.66, 0.76, 0.85)
				c.position = Vector2(-50 + k * 20, randf_range(-6, 4))
				_cloud.add_child(c)
			p.add_child.call_deferred(_cloud)
		"dark_lord":
			_gem = Polygon2D.new()
			_gem.polygon = Util.circle(9.0, 12)
			_gem.color = Color(1.0, 0.35, 0.1, 0.5)
			_gem.z_index = 3
			p.add_child.call_deferred(_gem)
			p.on_lethal = _on_lethal

func _physics_process(delta: float) -> void:
	if not is_instance_valid(p):
		return
	if not p.is_alive():
		_cleanup()
		return
	_t += delta
	match kind:
		"jotun":
			if fmod(_t, 0.25) < delta:                  # позёмка у ног
				Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-60, 60), p.body_size.y * 0.45), Color(0.85, 0.95, 1.0), 2, 80.0, 3.0)
			if _breath_t > 0.0:
				_breath_tick_fn(delta)
		"storm_lord":
			_storm_tick(delta)
		"cerberus":
			if _charge_t > 0.0:
				_charge_tick(delta)
		"dark_lord":
			_lord_tick(delta)

func _cleanup() -> void:
	if _eyes:
		_eyes.queue_free()
		_eyes = null
	if _cm and _eclipse_t > 0.0:
		_cm.color = _cm_color
		_eclipse_t = 0.0
	if _hole_fx:
		_hole_fx.queue_free()
		_hole_fx = null
	for r in _rods:
		if is_instance_valid(r):
			r.auto = true
			r.glow(false)
	for m in _marks:
		if is_instance_valid(m):
			m.queue_free()
	_marks.clear()

func _am() -> Node:
	return p.get_tree().get_first_node_in_group("arena_mode")

func _banner(text: String, c := Color(0.75, 0.88, 1.0), hold := 1.6) -> void:
	var am := _am()
	if am and am.hud:
		am.hud.show_banner(text, c)
		am._after(hold, am.hud.hide_banner)

func _foes() -> Array:
	return FarAbilities._foes(p)

# ======================= Ётун: морозное дыхание =======================
func start_breath() -> void:
	_breath_t = 1.7
	_breath_hit.clear()
	_breath_tick = 0.0
	p._anim("roar")
	p._forced_time = 1.7
	p._forced_vx = 0.0
	p._float_label("Морозное дыхание!", Color(0.7, 0.92, 1.0))

func _mouth() -> Vector2:
	return p.global_position + Vector2(p.facing * p.body_size.x * 0.28, -p.body_size.y * 0.36)

func _breath_tick_fn(delta: float) -> void:
	_breath_t -= delta
	var world := p.get_parent()
	var m := _mouth()
	if _breath_t > 1.2:
		# набирает воздух: к пасти стягивается иней
		if randf() < 0.6:
			Fx.sparks(world, m + Vector2(p.facing * 60.0, randf_range(-30, 30)), Color(0.85, 0.96, 1.0), 1, 60.0, 3.0)
		return
	p._forced_time = maxf(p._forced_time, 0.1)
	# конус инея
	for i in 3:
		var f := Polygon2D.new()
		f.polygon = Util.circle(randf_range(12, 22), 10)
		f.color = Color(0.80, 0.94, 1.0, 0.7)
		f.position = m
		f.z_index = 7
		world.add_child(f)
		var a := randf_range(-0.42, 0.42) + 0.25
		var end := m + Vector2(p.facing * cos(a), sin(a)) * randf_range(300, 470)
		var tw := f.create_tween()
		tw.tween_property(f, "position", end, 0.45)
		tw.parallel().tween_property(f, "scale", Vector2(2.2, 2.2), 0.45)
		tw.parallel().tween_property(f, "modulate:a", 0.0, 0.45)
		tw.tween_callback(f.queue_free)
	_breath_tick -= delta
	if _breath_tick <= 0.0:
		_breath_tick = 0.25
		for n in _foes():
			var dd: Vector2 = n.global_position - m
			if signf(dd.x) == float(p.facing) and absf(dd.x) < 480.0 and dd.y > -120.0 and absf(dd.y) < 70.0 + absf(dd.x) * 0.45:
				n.take_damage(6, p)
				if not _breath_hit.has(n):
					_breath_hit[n] = true
					if n.is_chilled():
						n.freeze(1.5)                  # уже был в инее — вмёрз!
						n._float_label("Вмёрз в лёд!", Color(0.7, 0.92, 1.0))
					else:
						n.chill(2.5, 0.55)
				else:
					n.chill(2.5, 0.55)
	if _breath_t <= 0.0:
		_breath_t = 0.0

# ======================= Громовник =======================
func _storm_tick(delta: float) -> void:
	var bs := p.body_size
	if p._rig_root and _over == "":
		p._rig_root.position.y = bs.y / 2 - _lift + sin(_t * 2.0) * 4.0     # парит
	if _cloud:
		var ry: float = p._rig_root.position.y if p._rig_root else bs.y / 2
		_cloud.position = Vector2(0, ry + 4.0)                       # облачко всегда под ногами
		for k in _cloud.get_child_count():
			var c := _cloud.get_child(k) as Node2D
			c.position.x = -50 + k * 20 + sin(_t * 2.0 + k) * 6.0
	if fmod(_t, 0.5) < delta:
		Fx.zap(p.get_parent(), p.global_position + Vector2(randf_range(-bs.x * 0.4, bs.x * 0.4), randf_range(-bs.y * 0.4, bs.y * 0.3)), Color(0.8, 0.9, 1.0), 18.0)
	_over_cd = maxf(0.0, _over_cd - delta)
	if _over != "":
		_over_tick(delta)

func can_overload() -> bool:
	if _over != "" or _over_cd > 0.0:
		return false
	var am := _am()
	return am != null and not (am.info.get("rods", []) as Array).is_empty()

func start_overload() -> void:
	var am := _am()
	_rods = (am.info.get("rods", []) as Array).filter(func(r): return is_instance_valid(r))
	if _rods.is_empty():
		return
	_over = "rise"
	_over_t = 0.9
	p.frozen = true
	p.cutscene_shield = true
	p.velocity = Vector2.ZERO
	if p.rig:
		p.rig.play("roar")
	_banner("Перегрузка! Встань у громоотвода!", Color(0.75, 0.9, 1.0), 2.2)
	for r in _rods:
		r.auto = false
		r.glow(true)
	if p._rig_root:
		p._rig_root.create_tween().tween_property(p._rig_root, "position:y", p.body_size.y / 2 - 150.0, 0.9).set_trans(Tween.TRANS_SINE)

func _over_tick(delta: float) -> void:
	_over_t -= delta
	var world := p.get_parent()
	match _over:
		"rise":
			if _over_t <= 0.0:
				_over = "charge"
				_over_t = 3.0
				for n in _foes():
					if not n.is_minion:
						var mk := Fx.rune_circle(world, n.global_position + Vector2(0, n.body_size.y / 2), 80.0, Color(0.65, 0.85, 1.0, 0.9), 3.2)
						_marks.append(mk)
		"charge":
			var core: Vector2 = p.global_position + Vector2(0, -p.body_size.y * 0.3 - 126.0)
			if randf() < 0.7:
				Fx.zap(world, core + Vector2(randf_range(-60, 60), randf_range(-60, 60)), Color(0.85, 0.95, 1.0), 40.0)
			if randf() < 0.15:
				Fx.bolt(world, core + Vector2(randf_range(-300, 300), -500.0), core, Color(0.75, 0.88, 1.0))
			# метки следуют за героями
			var i := 0
			for n in _foes():
				if n.is_minion:
					continue
				if i < _marks.size() and is_instance_valid(_marks[i]):
					(_marks[i] as Node2D).global_position = n.global_position + Vector2(0, n.body_size.y / 2)
				i += 1
			if _over_t <= 0.0:
				_over_strike()

func _over_strike() -> void:
	var world := p.get_parent()
	var core: Vector2 = p.global_position + Vector2(0, -p.body_size.y * 0.3 - 126.0)
	var redirected := false
	for n in _foes():
		var rod = null
		for r in _rods:
			if is_instance_valid(r) and r.shelters(n):
				rod = r
		if rod:
			redirected = true
			Fx.bolt(world, core, rod.tip(), Color(0.9, 0.96, 1.0))
			rod.discharge_into(p.global_position + Vector2(0, -p.body_size.y * 0.2))
		elif not n.is_minion:
			var at: Vector2 = n.global_position
			for k in 3:
				Fx.bolt(world, core, at, Color(0.9, 0.96, 1.0) if k % 2 == 0 else Color(0.6, 0.75, 1.0))
			Util.flash(world, at, 110.0, Color(0.85, 0.92, 1.0, 0.95))
			n.take_damage(26, p)
	Fx.shake(world, 10.0)
	for m in _marks:
		if is_instance_valid(m):
			m.queue_free()
	_marks.clear()
	for r in _rods:
		if is_instance_valid(r):
			r.glow(false)
			r.auto = true
	_over = ""
	_over_cd = 6.0
	p.cutscene_shield = false
	p.frozen = false
	if p._rig_root:
		p._rig_root.create_tween().tween_property(p._rig_root, "position:y", p.body_size.y / 2 - (0.0 if redirected else _lift), 0.25 if redirected else 0.6)
	if redirected:
		# молния ушла в громоотвод и вернулась в самого Владыку
		p.take_damage(int(p.max_hp * 0.04))
		p.stun(3.2)
		p._float_label("ПЕРЕГРУЗКА! урон ×%s" % str(p.stun_mult).trim_suffix(".0"), Color(1.0, 0.9, 0.4))
		Fx.ring(world, p.global_position, 200.0, Color(0.85, 0.92, 1.0, 0.95), 0.4, 8.0)

# ======================= Цербер: огненный рывок =======================
func start_lava_charge(dir: float) -> void:
	_charge_dir = dir if dir != 0.0 else float(p.facing)
	_charge_t = 1.9
	_charge_hit.clear()
	_trail_x = p.global_position.x
	p._anim("roar")
	p._forced_time = 0.5
	p._forced_vx = 0.0
	Fx.ring(p.get_parent(), p.global_position, 160.0, Color(1.0, 0.5, 0.2, 0.9), 0.5, 6.0)

func _charge_tick(delta: float) -> void:
	_charge_t -= delta
	if _charge_t > 1.4:
		return                                          # замах: роет землю
	p.facing = int(_charge_dir)
	p._forced_time = 0.1
	p._forced_vx = _charge_dir * 780.0
	var world := p.get_parent()
	if absf(p.global_position.x - _trail_x) > 70.0:
		_trail_x = p.global_position.x
		var fz := FireZone.new()
		fz.team = p.team
		fz.attacker = p
		fz.position = p.global_position + Vector2(0, p.body_size.y / 2 - 6)
		world.add_child(fz)
	for n in _foes():
		if _charge_hit.has(n):
			continue
		var dd: Vector2 = n.global_position - p.global_position
		if absf(dd.x) < p.body_size.x / 2 + 20.0 and absf(dd.y) < p.body_size.y / 2 + 20.0:
			_charge_hit[n] = true
			n.take_damage(20, p)
			n.velocity = Vector2(_charge_dir * 600.0, -420.0)
	var near_wall := p.global_position.x < 160.0 or p.global_position.x > p.map_w - 160.0
	if _charge_t <= 0.0 or (near_wall and signf(_charge_dir) == signf(p.global_position.x - p.map_w / 2)):
		_charge_t = 0.0
		p._forced_time = 0.0

# ======================= Тёмный Лорд =======================
func _lord_tick(delta: float) -> void:
	var bs := p.body_size
	if _gem:
		_gem.position = Vector2(p.facing * bs.x * 0.04, -bs.y * 0.18)
		var k := 0.45 + 0.25 * sin(_t * 4.0)
		if _phase2:
			k = 0.8 + 0.2 * sin(_t * 8.0)
			if p.is_stunned():
				k = 0.12                                   # выдохся: камень погас
		_gem.color = Color(1.0, 0.4, 0.12, k)
		_gem.scale = Vector2.ONE * (1.0 + (0.6 if _phase2 else 0.0))
	if _wings:
		_wings.position = Vector2(-p.facing * bs.x * 0.15, -bs.y * 0.25)
		_wings.scale.x = -float(p.facing)
		for k in _wings.get_child_count():
			var w := _wings.get_child(k) as Node2D
			w.rotation = sin(_t * 3.0 + k) * 0.12 + (0.0 if _dash_t <= 0.0 else -0.4)
	if _eclipse_t > 0.0:
		_eclipse_tick(delta)
	if _hole_t > 0.0:
		_hole_tick_fn(delta)
	if _dash_t > 0.0:
		_dash_tick(delta)

# ----- Затмение -----
func start_eclipse() -> void:
	var world := p.get_parent()
	_cm = null
	for n in world.get_children():
		if n is CanvasModulate:
			_cm = n
	if _cm == null:
		return
	_cm_color = _cm.color
	_cm.create_tween().tween_property(_cm, "color", Color(0.10, 0.08, 0.12), 0.8)
	_eclipse_t = 8.0
	_eclipse_step = 1.4
	_eclipse_n = 0
	p._anim("roar")
	p.frozen = true
	_banner("Затмение! Следи за его глазами", Color(1.0, 0.55, 0.3), 1.8)
	_make_eyes()
	if p._rig_root:
		p._rig_root.create_tween().tween_property(p._rig_root, "modulate:a", 0.12, 0.8)

func _make_eyes() -> void:
	var am := _am()
	var gl: CanvasLayer = am.info.get("glow") if am else null
	_eyes = Node2D.new()
	for s in [-1, 1]:
		var e := Torch.make_glow(70.0, Color(1.0, 0.45, 0.12, 0.95))
		e.position = Vector2(s * 9.0, 0)
		_eyes.add_child(e)
		var core := Polygon2D.new()
		core.polygon = PackedVector2Array([Vector2(-5, -1.5), Vector2(5, -2.5), Vector2(4, 1.5), Vector2(-4, 1.5)])
		core.color = Color(1.0, 0.8, 0.45)
		core.position = Vector2(s * 9.0, 0)
		_eyes.add_child(core)
	if gl:
		gl.add_child(_eyes)
	else:
		p.get_parent().add_child(_eyes)

func _eclipse_tick(delta: float) -> void:
	_eclipse_t -= delta
	if is_instance_valid(_eyes):
		_eyes.global_position = p.global_position + Vector2(p.facing * p.body_size.x * 0.1, -p.body_size.y * 0.36)
	_eclipse_step -= delta
	if _eclipse_step <= 0.0 and _eclipse_n < 3 and is_instance_valid(p.target):
		_eclipse_n += 1
		_eclipse_step = 2.2
		# исчезает и появляется сбоку от героя; глаза вспыхивают — бросок
		var t: Player = p.target
		var side := -1.0 if randf() < 0.5 else 1.0
		var x := clampf(t.global_position.x + side * 340.0, 140.0, p.map_w - 140.0)
		FarAbilities._dark_smoke(p.get_parent(), p.global_position, p.body_size)
		p.global_position = Vector2(x, t.global_position.y + t.body_size.y / 2 - p.body_size.y / 2 - 2.0)
		p.velocity = Vector2.ZERO
		p.facing = -int(side)
		if is_instance_valid(_eyes):
			for e in _eyes.get_children():
				e.create_tween().tween_property(e, "scale", e.scale * 1.8, 0.25)
				e.create_tween().tween_property(e, "scale", e.scale, 0.25).set_delay(0.6)
		p._after(0.7, _eclipse_slash)
	if _eclipse_t <= 0.0:
		_end_eclipse()

func _eclipse_slash() -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	p.frozen = false
	p._anim("swing")
	p._forced_time = 0.32
	p._forced_vx = p.facing * 1150.0
	var world := p.get_parent()
	Fx.arc(world, p.global_position + Vector2(p.facing * 60.0, -20.0), 80.0, -1.0, 1.0, Color(0.9, 0.3, 0.2, 0.8), 0.3)
	var hit := {}
	for k in 4:
		p._after(0.08 * (k + 1), func():
			if not is_instance_valid(p):
				return
			for n in _foes():
				if hit.has(n):
					continue
				var dd: Vector2 = n.global_position - p.global_position
				if absf(dd.x) < p.body_size.x / 2 + 60.0 and absf(dd.y) < p.body_size.y / 2:
					hit[n] = true
					n.take_damage(18, p))
	p._after(0.45, func():
		if is_instance_valid(p) and _eclipse_t > 0.0:
			p.frozen = true)

func _end_eclipse() -> void:
	_eclipse_t = 0.0
	p.frozen = false
	if _cm:
		_cm.create_tween().tween_property(_cm, "color", _cm_color, 0.8)
	if is_instance_valid(_eyes):
		_eyes.queue_free()
	_eyes = null
	if p._rig_root:
		p._rig_root.create_tween().tween_property(p._rig_root, "modulate:a", 1.0, 0.6)

# ----- Вторая фаза -----
func _on_lethal() -> bool:
	if _waking or _last:
		return false
	p.hp = 1
	if _phase2:
		_last = true
		_start_last_form()
		return true
	_waking = true
	_start_awakening()
	return true

func _start_awakening() -> void:
	var world := p.get_parent()
	var am := _am()
	if _eclipse_t > 0.0:
		_end_eclipse()
	p.cutscene_shield = true
	p.frozen = true
	p.velocity = Vector2.ZERO
	p._forced_time = 0.0
	p.stagger = 0.0
	p._stun_t = 0.0
	if p._stun_fx:
		p._stun_fx.visible = false
	if am:
		for b in am._alive.duplicate():
			if is_instance_valid(b) and b != p and b.is_alive():
				FarAbilities._dark_smoke(world, b.global_position, b.body_size)
				b.take_damage(99999)
	Engine.time_scale = 0.3
	p.get_tree().create_timer(0.8, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	Util.flash(world, p.global_position, 260.0, Color(1.0, 0.6, 0.4, 0.9))
	Fx.shake(world, 8.0)
	if am:
		am.cinematic(p, 7.5)
	_banner("Тёмный Лорд повержен…", Color(1.0, 0.55, 0.3))
	if p._rig_root:
		_rig_y = p._rig_root.position.y
		var kt := p._rig_root.create_tween()
		kt.tween_property(p._rig_root, "rotation", 0.18 * p.facing, 0.6).set_trans(Tween.TRANS_SINE)
		kt.parallel().tween_property(p._rig_root, "position:y", _rig_y + 30.0, 0.6)        # на колено
	p._after(1.4, _gem_flare)
	p._after(2.2, func(): _banner("…камень в его груди вспыхивает!", Color(1.0, 0.55, 0.3)))
	p._after(3.0, _rise_true_form)
	p._after(3.8, _take_off)
	p._after(4.7, _move_to_citadel)
	p._after(6.3, _descend)
	p._after(7.2, _begin_phase2)

func _gem_flare() -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	var c: Vector2 = p.global_position + Vector2(0, -p.body_size.y * 0.18)
	for k in 10:                                         # лучи света из трещин доспеха
		var l := Line2D.new()
		var a := randf() * TAU
		l.points = PackedVector2Array([c, c + Vector2.from_angle(a) * randf_range(120, 260)])
		l.width = 4.0
		l.default_color = Color(1.0, 0.6, 0.25, 0.0)
		l.z_index = 8
		world.add_child(l)
		var t := l.create_tween()
		t.tween_property(l, "default_color:a", 0.85, 0.3).set_delay(k * 0.08)
		t.tween_property(l, "default_color:a", 0.0, 0.6)
		t.tween_callback(l.queue_free)
	Fx.sparks(world, c, Color(1.0, 0.5, 0.2), 20, 260.0, 4.0)
	Fx.shake(world, 6.0)

func _rise_true_form() -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	var am := _am()
	var c := p.global_position
	Fx.shake(world, 14.0)
	Util.flash(world, c, 360.0, Color(1.0, 0.5, 0.25, 0.95))
	Fx.ring(world, c, 460.0, Color(0.9, 0.2, 0.3, 0.95), 0.6, 12.0)
	Fx.ring(world, c, 280.0, Color(1.0, 0.7, 0.4, 0.9), 0.45, 8.0)
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive() and n.global_position.distance_to(c) < 460.0:
			n.velocity = Vector2(signf(n.global_position.x - c.x + 0.01) * 720.0, -460.0)
	# огненные крылья за спиной
	_wings = Node2D.new()
	_wings.z_index = -1
	var bs := p.body_size
	for k in 2:
		var w := Polygon2D.new()
		var sgn := -1.0 if k == 0 else 1.0
		w.polygon = PackedVector2Array([Vector2(0, 0), Vector2(bs.x * 0.9, -bs.y * 0.45 + sgn * 10), Vector2(bs.x * 1.2, -bs.y * 0.2),
				Vector2(bs.x * 0.95, -bs.y * 0.05), Vector2(bs.x * 1.1, bs.y * 0.12), Vector2(bs.x * 0.7, bs.y * 0.08), Vector2(bs.x * 0.4, bs.y * 0.2)])
		w.color = Color(0.25, 0.04, 0.10, 0.85) if k == 0 else Color(0.85, 0.25, 0.10, 0.55)
		w.scale = Vector2(0.1, 0.1)
		_wings.add_child(w)
		w.create_tween().tween_property(w, "scale", Vector2.ONE * (1.0 if k == 0 else 0.8), 0.6).set_trans(Tween.TRANS_BACK)
	p.add_child(_wings)

# Лорд взмывает на огненных крыльях сквозь свод зала
func _take_off() -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	p.set_physics_process(false)
	if p.rig:
		p.rig.play("roar")
	if p._rig_root:
		var kt := p._rig_root.create_tween()                # встаёт с колена
		kt.tween_property(p._rig_root, "rotation", 0.0, 0.2)
		kt.parallel().tween_property(p._rig_root, "position:y", _rig_y, 0.2)
	_banner("Лорд уходит на вершину цитадели — за ним!", Color(1.0, 0.55, 0.3), 1.4)
	Fx.shake(world, 10.0)
	var from := p.global_position
	var t := p.create_tween()
	t.tween_property(p, "global_position:y", from.y - 1100.0, 0.75).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	for k in 8:                                           # огненный след
		p._after(0.06 * k, func():
			if is_instance_valid(p):
				Fx.sparks(p.get_parent(), p.global_position + Vector2(0, p.body_size.y * 0.4), Color(1.0, 0.5, 0.2), 6, 200.0, 4.0))
	# свод зала не выдерживает — сверху сыплются камни
	for k in 16:
		var r := Polygon2D.new()
		var s := randf_range(6, 14)
		r.polygon = PackedVector2Array([Vector2(-s, -s * 0.6), Vector2(s * 0.7, -s), Vector2(s, s * 0.5), Vector2(-s * 0.4, s)])
		r.color = Color(0.20, 0.16, 0.18)
		r.position = Vector2(from.x + randf_range(-260, 260), 40.0)
		r.z_index = 6
		world.add_child(r)
		var rt := r.create_tween()
		rt.tween_interval(0.5 + randf() * 0.5)
		rt.tween_property(r, "position:y", from.y + p.body_size.y / 2 - 4.0, randf_range(0.5, 0.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		rt.parallel().tween_property(r, "rotation", randf_range(-6, 6), 0.7)
		rt.tween_property(r, "modulate:a", 0.0, 0.5)
		rt.tween_callback(r.queue_free)

# Бой переходит на вершину цитадели
func _move_to_citadel() -> void:
	if not is_instance_valid(p):
		return
	var am := _am()
	if am == null:
		return
	var cx := Colosseum.W / 2.0
	var xs := [cx - 430.0, cx + 430.0]
	am.relocate(func(w: Node) -> Dictionary: return FarStages.citadel(w), [p], func():
		am.place_name = FarStages.CITADEL_NAME
		_cm = null
		if is_instance_valid(p):
			p.global_position = Vector2(cx, -500.0)
		am.cut_jump(Vector2(cx, am.info["floor"] - 300.0)), xs)

# Лорд падает с неба на стену цитадели
func _descend() -> void:
	if not is_instance_valid(p):
		return
	var am := _am()
	var world := p.get_parent()
	var floor_y: float = am.info["floor"] if am else 940.0
	var land := Vector2(Colosseum.W / 2.0, floor_y - p.body_size.y / 2 - 2.0)
	var t := p.create_tween()
	t.tween_property(p, "global_position", land, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		if not is_instance_valid(p):
			return
		p.set_physics_process(true)
		p.velocity = Vector2.ZERO
		var feet := Vector2(land.x, floor_y)
		Fx.shake(world, 16.0)
		Util.flash(world, feet + Vector2(0, -80), 300.0, Color(1.0, 0.5, 0.25, 0.9))
		Fx.ring(world, feet, 480.0, Color(0.9, 0.2, 0.3, 0.95), 0.6, 12.0, 0.3)
		Fx.cracks(world, feet, Color(1.0, 0.35, 0.1), 160.0)
		for n in world.get_children():
			if n is Player and n.team != p.team and n.is_alive() and absf(n.global_position.x - feet.x) < 520.0:
				n.velocity = Vector2(signf(n.global_position.x - feet.x + 0.01) * 520.0, -380.0)
		# небо горит, с него падают метеоры
		_sky = InfernoSky.new()
		_sky.boss = p
		_sky.map_w = p.map_w
		_sky.floor_y = floor_y
		_sky.glow = am.info.get("glow") if am else null
		world.add_child(_sky))

# Третья фаза: Лорд отдаёт себя тьме (см. DarkAvatar)
func _start_last_form() -> void:
	if _hole_t > 0.0:
		_hole_t = 0.0
		if is_instance_valid(_hole_fx):
			_hole_fx.queue_free()
		_hole_fx = null
	_dash_t = 0.0
	p._forced_time = 0.0
	p.frozen = true
	var av := DarkAvatar.new()
	av.lord = p
	av.lord_sky = _sky
	p.get_parent().add_child(av)
	set_physics_process(false)

func _begin_phase2() -> void:
	Engine.time_scale = 1.0
	if not is_instance_valid(p):
		return
	var am := _am()
	var t: Dictionary = Bots.TYPES["dark_lord"]
	var factor := float(p.max_hp) / float(t["hp"])
	var share := p.stagger_max / float(maxi(p.max_hp, 1))
	p.max_hp = int(t["phase2_hp"] * factor)
	p.stagger_max = p.max_hp * share
	p.stagger = 0.0
	var ht := p.create_tween()
	ht.tween_method(func(v: float):
		if is_instance_valid(p) and p.is_alive():
			p.hp = maxi(p.hp, int(v)), 1.0, float(p.max_hp), 1.0)
	p.speed = float(t["speed"]) * 1.3
	p.set_tint(Color(1.25, 0.9, 0.85))
	p.set_meta("title", t["phase2_name"])
	p.bot_abilities = {"swing": 2.0, "hellfire": 6.0, "wing_dash": 7.5, "dark_wave": 5.0, "black_hole": 15.0, "dark_orbs": 8.0}
	p._bot_cd = {}
	if p._rig_root:
		var kt := p._rig_root.create_tween()
		kt.tween_property(p._rig_root, "rotation", 0.0, 0.3)
		kt.parallel().tween_property(p._rig_root, "position:y", _rig_y, 0.3)
	if p.rig:
		p.rig.play("roar")
	_phase2 = true
	_waking = false
	p.frozen = false
	p.cutscene_shield = false
	if am:
		am._name_card("dark_lord", t["phase2_name"], "ВТОРАЯ ФАЗА")
		am._after(2.6, am.hud.show_hint.bind(String(t["hint2"]), 10.0))

# ----- Чёрная дыра -----
func start_black_hole() -> void:
	_hole_t = HOLE_T
	_hole_tick = 0.0
	p._anim("roar")
	p.frozen = true
	var world := p.get_parent()
	_hole_fx = Node2D.new()
	_hole_fx.z_index = 6
	var core := Polygon2D.new()
	core.polygon = Util.circle(36.0, 20)
	core.color = Color(0.02, 0.0, 0.04)
	_hole_fx.add_child(core)
	for k in 3:
		var ring := Line2D.new()
		var pts := Util.circle(50.0 + k * 26.0, 28)
		pts.append(pts[0])
		ring.points = pts
		ring.width = 5.0 - k
		ring.default_color = Color(0.6, 0.15, 0.7, 0.8 - k * 0.2)
		_hole_fx.add_child(ring)
	_hole_fx.position = p.global_position + Vector2(0, -p.body_size.y * 0.7)
	_hole_fx.scale = Vector2(0.1, 0.1)
	world.add_child(_hole_fx)
	_hole_fx.create_tween().tween_property(_hole_fx, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_BACK)
	_banner("Чёрная дыра! Беги от Лорда!", Color(0.85, 0.5, 1.0), 1.8)

func _hole_tick_fn(delta: float) -> void:
	_hole_t -= delta
	var world := p.get_parent()
	if not is_instance_valid(_hole_fx):
		_hole_t = 0.0
		return
	var c := _hole_fx.global_position
	for k in _hole_fx.get_child_count():
		(_hole_fx.get_child(k) as Node2D).rotation += delta * (3.0 + k)
	if randf() < 0.8:                                     # затягивает пыль и искры
		var s := Polygon2D.new()
		s.polygon = Util.circle(3.0, 6)
		s.color = Color(0.8, 0.5, 1.0, 0.8)
		s.position = c + Vector2.from_angle(randf() * TAU) * randf_range(200, 420)
		s.z_index = 6
		world.add_child(s)
		var tw := s.create_tween()
		tw.tween_property(s, "position", c, 0.6).set_ease(Tween.EASE_IN)
		tw.tween_callback(s.queue_free)
	_hole_tick -= delta
	for n in _foes():
		var dd: Vector2 = c - n.global_position
		if dd.length() < 900.0:
			n.push_wind(signf(dd.x) * 230.0)            # тянет к Лорду
			if _hole_tick <= 0.0 and dd.length() < 170.0:
				n.take_damage(6, p)
	if _hole_tick <= 0.0:
		_hole_tick = 0.4
	if _hole_t <= 0.0:
		_hole_t = 0.0
		Util.explode(world, c, 230.0, 24, 30, p.team, p)
		Fx.ring(world, c, 260.0, Color(0.7, 0.2, 0.9, 0.95), 0.5, 10.0)
		Util.flash(world, c, 200.0, Color(0.85, 0.5, 1.0, 0.9))
		_hole_fx.queue_free()
		_hole_fx = null
		p.frozen = false
		p.stun(3.5)                                       # выдохся: камень гаснет
		p._float_label("Лорд выдохся! урон ×%s" % str(p.stun_mult).trim_suffix(".0"), Color(1.0, 0.85, 0.3))

# ----- Рывок на огненных крыльях -----
func start_wing_dash(dir: float) -> void:
	_dash_dir = dir if dir != 0.0 else float(p.facing)
	_dash_t = 1.25
	_dash_hit.clear()
	_trail_x = p.global_position.x
	p._anim("windup")
	p._forced_time = 0.4
	p._forced_vx = 0.0

func _dash_tick(delta: float) -> void:
	_dash_t -= delta
	if _dash_t > 0.85:
		return
	p.facing = int(_dash_dir)
	p._forced_time = 0.1
	p._forced_vx = _dash_dir * 1050.0
	var world := p.get_parent()
	if absf(p.global_position.x - _trail_x) > 90.0:
		_trail_x = p.global_position.x
		var fz := FireZone.new()
		fz.team = p.team
		fz.attacker = p
		fz.position = p.global_position + Vector2(0, p.body_size.y / 2 - 6)
		world.add_child(fz)
	for n in _foes():
		if _dash_hit.has(n):
			continue
		var dd: Vector2 = n.global_position - p.global_position
		if absf(dd.x) < p.body_size.x / 2 + 30.0 and absf(dd.y) < p.body_size.y / 2 + 10.0:
			_dash_hit[n] = true
			n.take_damage(22, p)
			n.velocity = Vector2(_dash_dir * 650.0, -460.0)
	var near_wall := p.global_position.x < 170.0 or p.global_position.x > p.map_w - 170.0
	if _dash_t <= 0.0 or (near_wall and signf(_dash_dir) == signf(p.global_position.x - p.map_w / 2)):
		_dash_t = 0.0
		p._forced_time = 0.0
