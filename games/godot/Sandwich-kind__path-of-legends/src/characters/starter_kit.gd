class_name StarterKit
extends HeroKit
# Способности стартовых легенд (открыты всегда).
#   hunter — ОХОТНИЦА: лук с натяжением, кувырок назад (зачаровывает стрелу),
#            капкан, стрела-крюк со взрывной стрелой, ульта «Небо стрел».
#   smith  — КУЗНЕЦ: молот (серия из 3 дальних ударов), прыжок с молотом,
#            стена / МЕГА-наковальня, бросок молота с рикошетами, ульта «Кузня».

# Охотница
const FULL_DRAW := 0.8
var _charge := -1.0
var enchant := ""              # "pierce" — зачарована перекатом, "ghost" — МЕГА-перекатом
var _ench_fx: Polygon2D
var _ench_more := 0            # Арена: сколько ещё стрел останутся зачарованными
var _rain_w := 190.0           # ширина ливня стрел
var _traps: Array = []
var _hook_t := 0.0
var _hook_line: Line2D
var _hook_anchor := Vector2.ZERO
var _hook_mega := false
# Кузнец
var _combo := 0
var _combo_t := 0.0
var hammer_out := false
var _leap_t := 0.0
var _leap_mega := false
var _anvils: Array = []
var forge_t := 0.0
var _forge_mega := false
var _finale := false
var _aura: Node2D
var _aura_tick := 0.0

const ANVIL_MAX := 2

# ---------- Стрельба ----------
func weapon(delta: float, shoot: bool) -> void:
	if hero == "smith":
		_smith_weapon(delta, shoot)
		return
	_bow(delta, shoot)

func _bow(delta: float, shoot: bool) -> void:
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
	if _charge >= 0.0:
		if shoot and _hook_t <= 0.0:
			# держит — тетива натягивается
			_charge += delta * (2.0 if rapid else 1.0)
			if p.rig:
				p.rig.hold = "draw"
			_show_charge(minf(_charge / FULL_DRAW, 1.0))
			return
		_release()
		return
	if shoot and p._cooldown_left <= 0.0 and p._reloading <= 0.0 and p.ammo > 0:
		_charge = 0.0

func _show_charge(k: float) -> void:
	p._charge_fill.visible = k >= 0.0
	p._charge_bg.visible = k >= 0.0
	if k >= 0.0:
		p._charge_fill.size.x = p._bar_w * k
		p._charge_fill.color = Color(0.5, 1.0, 0.6) if k >= 1.0 else Color(1.0, 0.85, 0.3)

func _release() -> void:
	var k := clampf(_charge / FULL_DRAW, 0.0, 1.0)
	_charge = -1.0
	_show_charge(-1.0)
	if p.rig:
		p.rig.hold = ""
	var dir := Vector2(p.facing, -0.05).normalized()
	var a: Arrow
	match enchant:
		"pierce":
			a = _shoot_arrow("pierce", dir * 1900.0, int(lerpf(10, 24, k) * 1.5) + 6, 0.0)
		"ghost":
			a = _shoot_arrow("ghost", dir * 2400.0, 34, 0.0)
		_:
			a = _shoot_arrow("", dir * lerpf(950.0, 1550.0, k), int(lerpf(10, 24, k)), lerpf(520.0, 200.0, k))
	if enchant != "":
		Fx.sparks(p.get_parent(), a.global_position, Color(0.55, 1.0, 0.75), 10, 220.0, 4.0)
		if _ench_more > 0:
			_ench_more -= 1
		else:
			enchant = ""
	if p.is_mega("rapid"):
		a.mode = "pierce" if a.mode == "" else a.mode
	p._anim("shoot")
	var rapid := p.has_buff("rapid")
	p._cooldown_left = p.fire_cooldown * (0.5 if rapid else 1.0)
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

func _shoot_arrow(mode: String, vel: Vector2, dmg: int, grav: float) -> Arrow:
	var a := Arrow.new()
	a.shooter = p
	a.team = p.team
	a.mode = mode
	a.damage = dmg
	a.gravity = grav
	a.position = p.rig.muzzle() if p.rig else p.global_position
	# помощь в прицеливании на Арене: стрела чуть доворачивает на врага
	a.velocity = p.assist_dir(a.position, vel.normalized(), vel.length(), grav) * vel.length() if Balance.arena(p) else vel
	p.get_parent().add_child(a)
	return a

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	p._cd[i] = maxf(0.0, p._cd[i] - delta * p._cd_speed())
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	if ab == "hammer_throw" and hammer_out:
		return                                 # молот ещё не вернулся
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	var world := p.get_parent()
	match ab:
		"roll":
			# кувырок назад с неуязвимостью — следующая стрела зачарована
			p._forced_time = 0.32
			p._forced_vx = -p.facing * 950.0
			p._forced_no_gravity = false
			p.velocity.y = minf(p.velocity.y, -160.0)
			p._invuln = 0.4
			p._anim("roll")
			enchant = "ghost" if mega else "pierce"
			_ench_more = 1 if Balance.arena(p) else 0        # Арена: зачарованы 2 стрелы подряд
			Fx.sparks(world, p.global_position + Vector2(0, p.body_size.y / 2), Color(0.85, 0.8, 0.7), 8, 160.0, 4.0, true)
			_after(0.3, _enchant_flash)
		"trap":
			p._anim("trap")
			# Арена: два капкана разом (ближний и дальний), всего на поле — до 4
			var arena := Balance.arena(p)
			var max_traps := 4 if arena else 2
			var throws := [Vector2(p.facing * 300.0, -300.0), Vector2(p.facing * 520.0, -360.0)] if arena \
					else [Vector2(p.facing * 380.0, -320.0)]
			_traps = _traps.filter(func(t): return is_instance_valid(t))
			while _traps.size() > max_traps - throws.size():
				var old = _traps.pop_front()
				if is_instance_valid(old):
					old._vanish()
			for v in throws:
				var tr := BearTrap.new()
				tr.team = p.team
				tr.attacker = p
				tr.mega = mega
				tr.velocity = v
				tr.position = p.global_position + Vector2(p.facing * 20.0, 0)
				world.add_child(tr)
				_traps.append(tr)
		"hook":
			_shoot_hook(mega)
		"hammer_leap":
			_leap_t = 0.01
			_leap_mega = mega
			p._forced_time = 0.55
			p._forced_vx = p.facing * 560.0
			p._forced_no_gravity = false
			p.velocity.y = -760.0
			p._anim("leap")
			Fx.sparks(world, p.global_position + Vector2(0, p.body_size.y / 2), Color(0.8, 0.75, 0.65), 8, 160.0, 4.0, true)
		"anvil":
			_drop_anvil(mega)
		"hammer_throw":
			hammer_out = true
			p._anim("throw")
			_after(0.12, _launch_hammer.bind(mega))

func _enchant_flash() -> void:
	if p.rig:
		Fx.star(p.get_parent(), p.rig.muzzle(), 16.0, Color(0.6, 1.0, 0.8, 0.9) if enchant == "pierce" else Color(1, 1, 1, 0.95), 0.35)

# ---------- Ульта ----------
func ult() -> void:
	if hero == "smith":
		_forge()
	else:
		_arrow_sky()

func _after(time: float, fn: Callable) -> void:
	get_tree().create_timer(time).timeout.connect(fn)

# ---------- Каждый кадр ----------
func _physics_process(delta: float) -> void:
	super(delta)
	if p == null or not p.is_alive():
		return
	if hero == "hunter":
		_hunter_tick(delta)
	else:
		_smith_tick(delta)

func on_death() -> void:
	super()
	_charge = -1.0
	enchant = ""
	_hook_t = 0.0
	if _hook_line and is_instance_valid(_hook_line):
		_hook_line.queue_free()
	if p.rig:
		p.rig.hold = ""
		p.rig.weapon_hidden = false
		p.rig.heat = 0.0
		p.rig.eyes_lit = false
	_show_charge(-1.0)
	hammer_out = false
	_leap_t = 0.0
	if forge_t > 0.0 or _finale:
		forge_t = 0.0
		_finale = false
	if _aura and is_instance_valid(_aura):
		_aura.queue_free()

# ======================= ОХОТНИЦА =======================
func _hunter_tick(delta: float) -> void:
	# зачарованная стрела светится на луке
	if enchant != "":
		if _ench_fx == null or not is_instance_valid(_ench_fx):
			_ench_fx = Polygon2D.new()
			_ench_fx.polygon = Util.circle(7.0, 12)
			_ench_fx.z_index = 9
			p.get_parent().add_child(_ench_fx)
		_ench_fx.color = Color(0.55, 1.0, 0.75, 0.7) if enchant == "pierce" else Color(1.0, 1.0, 1.0, 0.85)
		_ench_fx.global_position = p.rig.muzzle() if p.rig else p.global_position
		_ench_fx.scale = Vector2.ONE * (1.0 + 0.3 * sin(Time.get_ticks_msec() * 0.015))
	elif _ench_fx and is_instance_valid(_ench_fx):
		_ench_fx.queue_free()
		_ench_fx = null
	if _hook_t > 0.0:
		_hook_t -= delta
		if _hook_line and is_instance_valid(_hook_line):
			_hook_line.points = PackedVector2Array([p.rig.muzzle() if p.rig else p.global_position, _hook_anchor])
		if _hook_t <= 0.0:
			_end_hook()

func _shoot_hook(mega: bool) -> void:
	p._anim("hook")
	var dir := Vector2(p.facing, -0.85).normalized()
	var from := p.global_position + Vector2(0, -p.body_size.y / 2)
	var hit := p.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(from, from + dir * 560.0, Layer.WORLD | Layer.FRAME, [p.get_rid()]))
	_hook_anchor = hit["position"] if not hit.is_empty() else from + dir * 560.0
	_hook_line = Line2D.new()
	_hook_line.width = 2.0
	_hook_line.default_color = Color(0.85, 0.78, 0.6)
	p.get_parent().add_child(_hook_line)
	var claw := Polygon2D.new()            # крюк на конце верёвки
	claw.polygon = PackedVector2Array([Vector2(-6, -6), Vector2(6, 0), Vector2(-6, 6), Vector2(-2, 0)])
	claw.color = Color(0.7, 0.7, 0.75)
	claw.position = _hook_anchor
	claw.rotation = dir.angle()
	_hook_line.add_child(claw)
	Fx.sparks(p.get_parent(), _hook_anchor, Color(0.9, 0.9, 0.8), 6, 140.0, 3.0)
	var to := _hook_anchor - p.global_position
	var v := to.normalized() * clampf(to.length() * 3.2, 650.0, 1300.0)
	v.y -= 200.0
	p._forced_time = 0.3
	p._forced_vx = v.x
	p._forced_no_gravity = false
	p.velocity.y = v.y
	_hook_t = 0.3
	_hook_mega = mega

func _end_hook() -> void:
	if _hook_line and is_instance_valid(_hook_line):
		var ln := _hook_line
		var t := ln.create_tween()
		t.tween_property(ln, "modulate:a", 0.0, 0.15)
		t.tween_callback(ln.queue_free)
	# после подтягивания — взрывная стрела во врага (МЕГА — веер из нескольких)
	p._anim("shoot")
	var e := _nearest_enemy(1300.0)
	var from: Vector2 = p.rig.muzzle() if p.rig else p.global_position
	var aim := Vector2(p.facing, 0.35).normalized()
	if e:
		aim = (e.global_position - from).normalized()
		p.facing = 1 if aim.x >= 0.0 else -1
	var spread := [0.0]
	if Balance.arena(p):                 # Арена: 3 взрывные стрелы (МЕГА — 6)
		spread = [-0.3, -0.18, -0.06, 0.06, 0.18, 0.3] if _hook_mega else [-0.14, 0.0, 0.14]
	elif _hook_mega:
		spread = [-0.24, -0.08, 0.08, 0.24]
	for s in spread:
		_shoot_arrow("blast", aim.rotated(s) * 1250.0, 16, 150.0)

func _arrow_sky() -> void:
	var world := p.get_parent()
	var mega := p._mega_ab()
	var feet := p.global_position + Vector2(0, p.body_size.y / 2)
	# «Небо стрел»: Охотница встаёт на колено, натягивает лук к небу, вокруг
	# поднимается ветер; в небо уходит сияющая стрела — и на врага льётся ливень.
	p._forced_time = 1.15
	p._forced_vx = 0.0
	p._anim("kneel_sky")
	Fx.rune_circle(world, feet, 70.0, Color(0.55, 1.0, 0.6, 0.85), 1.3)
	Fx.leaf_swirl(world, p, 80.0, 1.1, 16)
	Fx.glow(world, p.global_position, 70.0, Color(0.6, 1.0, 0.7, 0.2), 1.1)
	var e := _nearest_enemy(1500.0)
	var tx: float = e.global_position.x if e else p.global_position.x + p.facing * 500.0
	var ty: float = e.global_position.y if e else p.global_position.y
	var ground := p.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(Vector2(tx, ty - 10.0), Vector2(tx, ty + 900.0), Layer.WORLD | Layer.FRAME))
	var gy: float = ground["position"].y if not ground.is_empty() else ty + 30.0
	var sky := maxf(gy - 620.0, p.map_top + 110.0)
	_after(0.7, _sky_shot)
	_after(0.95, _sky_marks.bind(tx, gy, sky))
	var n := 30 if mega else 24
	_rain_w = 190.0
	if Balance.arena(p):                 # Арена: ливень гуще и шире
		n = 44 if mega else 36
		_rain_w = 260.0
	for k in n:
		_after(1.75 + k * (1.2 / n), _rain_arrow.bind(tx, sky, gy))
	if mega:
		_after(1.75 + 1.35, _giant_arrow.bind(tx, sky, gy))

func _sky_shot() -> void:
	if not p.is_alive():
		return
	var world := p.get_parent()
	var tip: Vector2 = p.rig.muzzle() if p.rig else p.global_position
	Fx.star(world, tip, 26.0, Color(0.85, 1.0, 0.85, 0.95), 0.45)
	Fx.sparks(world, tip, Color(0.7, 1.0, 0.75), 14, 260.0, 4.0, true)
	Fx.ring(world, p.global_position + Vector2(0, p.body_size.y / 2), 120.0, Color(0.7, 1.0, 0.75, 0.8), 0.4, 5.0, 0.3)
	var a := _shoot_arrow("ghost", Vector2(0, -2600.0), 0, 0.0)
	a.mode = "rain"                     # сияющая стрела в небо — просто след, без урона
	a.damage = 0
	a.set_meta("sky", true)
	a.global_position = tip
	a._life = 0.5

func _sky_marks(tx: float, gy: float, sky: float) -> void:
	var world := p.get_parent()
	Fx.rune_circle(world, Vector2(tx, sky), 170.0, Color(1.0, 0.95, 0.6, 0.9), 2.2, 0.3)
	Fx.rune_circle(world, Vector2(tx, gy), 190.0, Color(1.0, 0.45, 0.3, 0.75), 2.0, 0.22)
	Fx.star(world, Vector2(tx, sky), 40.0, Color(1.0, 1.0, 0.8, 0.9), 0.6)

func _rain_arrow(tx: float, sky: float, gy: float) -> void:
	var a := Arrow.new()
	a.shooter = p
	a.team = p.team
	a.mode = "rain"
	a.damage = 7
	a.cell_damage = 8
	a.stop_y = gy
	a.gravity = 500.0
	a.velocity = Vector2(randf_range(40.0, 140.0), randf_range(1250.0, 1500.0))
	a.position = Vector2(tx + randf_range(-_rain_w, _rain_w) - 60.0, sky + randf_range(-30.0, 30.0))
	p.get_parent().add_child(a)

func _giant_arrow(tx: float, sky: float, gy: float) -> void:
	var a := Arrow.new()
	a.shooter = p
	a.team = p.team
	a.mode = "giant"
	a.damage = 35
	a.stop_y = gy
	a.gravity = 900.0
	a.velocity = Vector2(0, 1500.0)
	a.position = Vector2(tx, sky)
	p.get_parent().add_child(a)
	Fx.star(p.get_parent(), Vector2(tx, sky), 60.0, Color(1.0, 1.0, 0.85, 0.95), 0.5)

# ======================= КУЗНЕЦ =======================
func _smith_weapon(delta: float, shoot: bool) -> void:
	p.ammo = p.clip_size
	p._reloading = 0.0
	_combo_t -= delta
	if _combo_t <= 0.0:
		_combo = 0
	if not shoot or p._cooldown_left > 0.0 or _finale:
		return
	var rapid := p.has_buff("rapid")
	if hammer_out:
		# молот улетел — бьёт кулаками
		p._anim("punch")
		_melee(95.0, 50.0, 9, 220.0, 15, false)
		p._cooldown_left = 0.28 * (0.6 if rapid else 1.0)
		return
	var step := _combo
	_combo = (_combo + 1) % 3
	_combo_t = 1.2
	p._anim(["hammer1", "hammer2", "hammer3"][step])
	_after([0.17, 0.15, 0.33][step] * (0.7 if rapid else 1.0), _hammer_hit.bind(step))
	p._cooldown_left = [0.45, 0.45, 0.78][step] * (0.6 if rapid else 1.0)

func _hammer_hit(step: int) -> void:
	if not p.is_alive():
		return
	var heavy := step == 2
	var hot := forge_t > 0.0
	var reach := 205.0 if heavy else 175.0
	var dmg := 30 if heavy else 16
	if hot:
		dmg = int(dmg * 1.25)
	_melee(reach, 78.0, dmg, 600.0 if heavy else 260.0, 70 if heavy else 35, heavy)
	var world := p.get_parent()
	var c := p.global_position + Vector2(p.facing * 30.0, -10.0)
	var col := Color(1.0, 0.6, 0.25, 0.75) if hot else Color(1.0, 1.0, 0.95, 0.6)
	# след молота: дуга сверху вниз или снизу вверх
	var arcs := [[-1.7, 0.55], [1.2, -1.2], [-2.2, 0.8]]
	var a0: float = arcs[step][0]
	var a1: float = arcs[step][1]
	if p.facing < 0:
		a0 = PI - a0
		a1 = PI - a1
	Fx.arc(world, c, reach * 0.8, a0, a1, col, 0.22, 30.0 if heavy else 22.0)
	if heavy:
		var hit_at := p.global_position + Vector2(p.facing * reach * 0.75, p.body_size.y / 2)
		Fx.ring(world, hit_at, 90.0, Color(1.0, 0.85, 0.6, 0.85), 0.35, 5.0, 0.3)
		Fx.cracks(world, hit_at, Color(0.28, 0.22, 0.18), 70.0)
		Fx.sparks(world, hit_at, Color(1.0, 0.75, 0.35) if hot else Color(0.9, 0.85, 0.75), 12, 240.0, 4.0, true)
		if hot:
			var fz := FireZone.new()                 # раскалённый удар оставляет огонь
			fz.team = p.team
			fz.attacker = p
			fz.position = hit_at
			world.add_child(fz)

# Удар перед Кузнецом: враги в прямоугольнике и клетки блоков
func _melee(reach: float, half_h: float, dmg: int, knock: float, cell_dmg: int, heavy: bool) -> void:
	var hot := forge_t > 0.0
	var world := p.get_parent()
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		if signf(to.x) == p.facing or absf(to.x) < 20.0:
			if absf(to.x) < reach + e.body_size.x / 2 and absf(to.y) < half_h + e.body_size.y / 2:
				e.take_damage(dmg, p)
				e.velocity = Vector2(p.facing * knock, -260.0 if heavy else -140.0)
				if hot:
					e.burn(3.0, 8.0, p)
	var cd := int(cell_dmg * (1.6 if hot else 1.0))
	for n in world.get_children():
		if n is Destructible and n.shield_team != p.team and not n.background \
				and n.global_position.distance_to(p.global_position) < 500.0:
			var x := 30.0
			while x <= reach:
				var y := -half_h
				while y <= half_h * 0.6:
					n.hit(p.global_position + Vector2(p.facing * x, y), Vector2(p.facing, 0), cd, 6.0, p.team,
							{"strict": true, "attacker": p, "power": 0.6, "fire": hot})
					y += 22.0
				x += 22.0

func _smith_tick(delta: float) -> void:
	if _leap_t > 0.0:
		_leap_t += delta
		if _leap_t > 0.12 and p.is_on_floor():
			_leap_t = 0.0
			_slam()
		elif _leap_t > 2.5:
			_leap_t = 0.0
	if forge_t > 0.0:
		forge_t -= delta
		if _aura and is_instance_valid(_aura):
			_aura_tick -= delta
			if _aura_tick <= 0.0:
				_aura_tick = 0.5
				for e in _enemies():
					if e.global_position.distance_to(p.global_position) < 170.0:
						e.take_damage(4, p)
						e.burn(1.0, 4.0, p)
		if forge_t <= 0.0:
			_forge_finale()

# Прыжок с молотом: при приземлении — ударная волна в обе стороны
func _slam() -> void:
	var world := p.get_parent()
	var mega := _leap_mega
	var feet := p.global_position + Vector2(p.facing * 30.0, p.body_size.y / 2)
	p._anim("hammer3")
	p._forced_time = 0.25
	p._forced_vx = 0.0
	var r := 240.0 if mega else 170.0
	for e in _enemies():
		var to: Vector2 = e.global_position - feet
		if absf(to.x) < r and absf(to.y) < 110.0:
			e.take_damage(18 if not mega else 24, p)
			e.velocity = Vector2(signf(to.x) * 450.0, -430.0)
			if Balance.arena(p):
				e.stun(0.8)                  # Арена: волна ещё и оглушает
			if forge_t > 0.0:
				e.burn(3.0, 8.0, p)
	for n in world.get_children():
		if n is Destructible and n.shield_team != p.team and not n.background \
				and n.global_position.distance_to(feet) < 600.0:
			var x := -r * 0.6
			while x <= r * 0.6:
				n.hit(feet + Vector2(x, -6.0), Vector2.UP, 40, 10.0, p.team, {"strict": true, "attacker": p, "power": 0.8})
				x += 22.0
	Fx.ring(world, feet, r, Color(0.95, 0.85, 0.65, 0.9), 0.45, 7.0, 0.3)
	Fx.ring(world, feet, r * 0.6, Color(1.0, 1.0, 0.9, 0.9), 0.3, 4.0, 0.3)
	Fx.sparks(world, feet, Color(0.85, 0.78, 0.65), 16, 300.0, 5.0, true)
	Fx.cracks(world, feet, Color(0.28, 0.22, 0.18), r * 0.6)
	var spikes := []
	if mega:
		spikes = [-3, -2, -1, 1, 2, 3] if Balance.arena(p) else [-2, -1, 1, 2]
	elif Balance.arena(p):
		spikes = [-1, 1]                     # Арена: шипы из трещин и без МЕГА
	if not spikes.is_empty():
		# через секунду из трещин бьют каменные шипы
		for k in spikes:
			var rs := RootSpike.new()
			rs.team = p.team
			rs.attacker = p
			rs.stone = true
			rs.damage = 14
			rs.half = 38.0
			rs.warn = 0.9
			rs.position = feet + Vector2(k * 95.0, 0)
			world.add_child(rs)

# Стена или МЕГА-наковальня
func _drop_anvil(mega: bool) -> void:
	p._anim("anvil")
	var world := p.get_parent()
	var fa := FallingAnvil.new()
	fa.owner_p = p
	if Balance.arena(p):
		fa.life = 12.0                       # Арена: стена стоит дольше
	fa.team = p.team
	fa.mega = mega
	var feet := p.global_position.y + p.body_size.y / 2
	if mega:
		fa.x = p.global_position.x + p.facing * 200.0
		fa.land_y = _anvil_ground(fa.x, feet)
		_anvils = _anvils.filter(func(a): return is_instance_valid(a))
		while _anvils.size() >= ANVIL_MAX:
			var old = _anvils.pop_front()       # старая наковальня рассыпается
			if is_instance_valid(old):
				Util.flash(world, old.global_position, 120.0, Color(0.6, 0.6, 0.65, 0.7))
				Fx.sparks(world, old.global_position, Color(0.6, 0.6, 0.65), 16, 260.0, 6.0)
				old.queue_free()
	else:
		fa.x = p.global_position.x + p.facing * 100.0
		fa.side = p.facing
		# падает на уровень Кузнеца, а если там нет пола — ниже, до первой опоры
		var gh := p.get_world_2d().direct_space_state.intersect_ray(
				PhysicsRayQueryParameters2D.create(Vector2(fa.x, feet - 30.0), Vector2(fa.x, feet + 1500.0), Layer.WORLD | Layer.FRAME))
		fa.land_y = gh["position"].y if not gh.is_empty() else feet
	world.add_child(fa)
	if mega:
		_anvils.append(fa.d)

# Куда упадёт наковальня: сквозь разрушаемые блоки — до твёрдой земли
func _anvil_ground(x: float, feet: float) -> float:
	var space := p.get_world_2d().direct_space_state
	var ex: Array[RID] = []
	var from := Vector2(x, feet - 160.0)
	for i in 30:
		var q := PhysicsRayQueryParameters2D.create(from, Vector2(x, feet + 700.0), Layer.WORLD | Layer.FRAME, ex)
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return feet
		var b = hit["collider"]
		if b is Destructible or b is Player:
			ex.append(hit["rid"])
			continue
		return hit["position"].y
	return feet

func _launch_hammer(mega: bool) -> void:
	if not p.is_alive():
		hammer_out = false
		return
	if p.rig:
		p.rig.weapon_hidden = true
	var h := ThrownHammer.new()
	h.owner_p = p
	h.team = p.team
	h.mega = mega
	h.dir = p.facing
	h.damage = 16
	if Balance.arena(p):
		h.bounces = 5                        # Арена: молот рикошетит 5 раз и бьёт больнее
		h.damage = 20
	h.position = p.rig.muzzle() if p.rig else p.global_position
	p.get_parent().add_child(h)

func on_hammer_hit(e: Player) -> void:
	if forge_t > 0.0:
		e.burn(3.0, 8.0, p)

# Молот вернулся. После МЕГА-броска — размашистый удар по притянутым врагам.
func hammer_back(mega: bool, grabbed: Array) -> void:
	hammer_out = false
	if p.rig:
		p.rig.weapon_hidden = false
	if not p.is_alive():
		return
	Fx.sparks(p.get_parent(), p.rig.muzzle() if p.rig else p.global_position, Color(0.9, 0.9, 0.95), 6, 140.0, 3.0)
	if mega:
		p._anim("big_swing")
		p._forced_time = 0.4
		p._forced_vx = 0.0
		_after(0.24, _big_swing)

func _big_swing() -> void:
	if not p.is_alive():
		return
	var world := p.get_parent()
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		if absf(to.x) < 220.0 and absf(to.y) < 110.0:
			e.take_damage(26, p)
			e.stun(1.5)
			e.velocity = Vector2(p.facing * 500.0, -300.0)
	var c := p.global_position + Vector2(0, -10)
	Fx.arc(world, c, 190.0, -2.4 if p.facing > 0 else PI + 2.4, 0.9 if p.facing > 0 else PI - 0.9,
			Color(1.0, 1.0, 0.9, 0.8), 0.3, 40.0)
	Fx.ring(world, c, 200.0, Color(1.0, 0.9, 0.6, 0.8), 0.4, 6.0)
	Fx.sparks(world, c + Vector2(p.facing * 120.0, 0), Color(1.0, 0.85, 0.5), 16, 300.0, 5.0)

# «Кузня»: замах, удар в землю — молот раскаляется, Кузнец вырастает,
# глаза загораются огнём. Каждый удар поджигает врагов.
func _forge() -> void:
	var world := p.get_parent()
	var mega := p._mega_ab()
	_forge_mega = mega
	p._forced_time = 1.0
	p._forced_vx = 0.0
	p._anim("forge")
	Fx.glow(world, p.global_position, 80.0, Color(1.0, 0.55, 0.15, 0.25), 1.0)
	Fx.sparks(world, p.global_position + Vector2(0, -30), Color(1.0, 0.6, 0.2), 10, 160.0, 4.0, true)
	_after(0.45, _forge_impact)

func _forge_impact() -> void:
	if not p.is_alive():
		return
	var world := p.get_parent()
	var feet := p.global_position + Vector2(0, p.body_size.y / 2)
	forge_t = 11.0 if Balance.arena(p) else 8.0        # Арена: Кузня горит дольше
	Fx.ring(world, feet, 200.0, Color(1.0, 0.55, 0.15, 0.95), 0.5, 9.0, 0.3)
	Fx.ring(world, feet, 120.0, Color(1.0, 0.9, 0.6, 0.95), 0.35, 5.0, 0.3)
	Fx.rune_circle(world, feet, 95.0, Color(1.0, 0.5, 0.15, 0.9), 1.4)
	Fx.cracks(world, feet, Color(0.9, 0.35, 0.1), 130.0)
	Fx.sparks(world, feet, Color(1.0, 0.6, 0.2), 26, 380.0, 6.0, true)
	Util.explode(world, feet, 130.0, 12, 30, p.team, p, true)
	if p.rig:
		p.rig.eyes_lit = true
		p.rig.heat = 1.0
	if p._rig_root:
		var gt := p._rig_root.create_tween()
		gt.tween_property(p._rig_root, "scale", Vector2(1.35, 1.35), 0.5).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	p.set_tint(Color(1.25, 1.0, 0.85))
	p.armor_mult = 0.75
	if _forge_mega or Balance.arena(p):          # Арена: огненный круг и без МЕГА
		_aura = Fx.flame_ring(p, 160.0, forge_t)
		_aura_tick = 0.3

# Финальный удар в конце «Кузни» (МЕГА — три удара подряд, каждый сильнее)
func _forge_finale() -> void:
	_finale = true
	var hits := 3 if _forge_mega else 1
	if Balance.arena(p):
		hits += 1                            # Арена: на один финальный удар больше
	p._forced_time = 0.5 * hits + 0.1
	p._forced_vx = 0.0
	for k in hits:
		_after(k * 0.5, _finisher.bind(k, hits))
	_after(hits * 0.5 + 0.15, _forge_end)

func _finisher(k: int, hits: int) -> void:
	if not p.is_alive():
		return
	p._anim("finisher")
	_after(0.2, _finisher_boom.bind(k, hits))

func _finisher_boom(k: int, hits: int) -> void:
	if not p.is_alive():
		return
	var world := p.get_parent()
	var power := 1.0 + 0.35 * k if hits > 1 else 1.3
	var at := p.global_position + Vector2(p.facing * 110.0, p.body_size.y / 2 - 6.0)
	var r := 120.0 * power
	Util.explode(world, at, r, int(18 * power), int(45 * power), p.team, p, true)
	for e in _enemies():
		if e.global_position.distance_to(at) < r:
			e.burn(3.0, 8.0, p)
			e.velocity = Vector2(signf(e.global_position.x - at.x) * 420.0, -380.0)
	Fx.ring(world, at, r * 1.2, Color(1.0, 0.5, 0.15, 0.95), 0.45, 8.0, 0.35)
	Fx.ring(world, at, r * 0.7, Color(1.0, 0.95, 0.7, 0.95), 0.3, 5.0)
	Fx.sparks(world, at, Color(1.0, 0.6, 0.2), 20, 360.0, 6.0, true)
	Fx.cracks(world, at, Color(0.9, 0.35, 0.1), r)
	Fx.glow(world, at, r * 0.6, Color(1.0, 0.6, 0.2, 0.35), 0.5)

func _forge_end() -> void:
	_finale = false
	if p.rig:
		p.rig.eyes_lit = false
		p.rig.heat = 0.0
	p.set_visual_scale(1.0, 0.35)
	p.set_tint(Color.WHITE)
	p.armor_mult = 1.0
	if _aura and is_instance_valid(_aura):
		_aura.queue_free()
	_aura = null
