class_name AssassinKit
extends HeroKit
# ---------- АССАСИН — легенда за Атамана (10-я волна Арены) ----------
# Оружие: метает кунаи вперёд.
# 1 «Вихрь клинков» — носится по кругу возле себя (видны её тени-рывки) и бьёт
#                     в обе стороны всех, кто подойдёт. МЕГА: дольше, шире,
#                     ударов больше, в конце — мощный размашистый удар вокруг.
# 2 «Оглушающая бомба» — самодельная бомба перед собой: все в радиусе оглушены.
#                     МЕГА: взрыв шире, оглушение дольше.
# 3 «Прыжок с кунаями» — высокий прыжок вперёд, в верхней точке 7 кунаев вниз.
#                     МЕГА: 3 волны по 7 кунаев.
# Ульта «Удар тени» — большой сюрикен. Промах — ульта уходит в откат.
#   Попадание — немного урона, и пару секунд ульту можно нажать ещё раз:
#   Ассасин телепортируется за спину цели (та замирает), становится тенью
#   и бьёт снизу вверх так, что разрез достаёт до неба.
#   МЕГА: вокруг цели 5 теней бьют разом, затем главная тень — разрез до неба,
#   а потом Ассасин какое-то время двигается тенью: быстрее, кунаи пробивают врага.

var _storm_t := 0.0
var _storm_len := 0.0
var _storm_mega := false
var _storm_tick := 0.0
var _storm_hop := 0.0
var _puppets: Array = []
var _last_pos := Vector2.ZERO
var _mark: Player
var _mark_t := 0.0
var _shuriken: BigShuriken
var _busy := 0.0                 # идёт удар тени — ничего другого нельзя
var _shadow_t := 0.0             # МЕГА: форма тени после ульты
var _shadow_fx := 0.0

const KUNAI := Color(0.78, 0.8, 0.88)
const SHADOW := Color(0.07, 0.06, 0.10)
const SHADOW_FORM := Color(0.22, 0.18, 0.30)
const STORM_R := 120.0
const STORM_R_MEGA := 170.0

# ---------- Стрельба: кунаи ----------
func weapon(delta: float, shoot: bool) -> void:
	if _storm_t > 0.0 or _busy > 0.0:
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
	var b := p._shoot_bullet(p.bullet_speed, p.bullet_damage, 0.0, p.bullet_size, randf_range(-0.02, 0.02))
	b.color = KUNAI
	b.restyle("kunai")
	p._anim("throw")
	if _shadow_t > 0.0:
		b.pierce = 1                              # в форме тени кунай прошивает врага
		b.color = Color(0.6, 0.45, 0.85)
	if rapid and p.is_mega("rapid"):
		b.pierce = maxi(b.pierce, 2)
	p._cooldown_left = p.fire_cooldown * (0.5 if rapid else (0.8 if _shadow_t > 0.0 else 1.0))
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	p._cd[i] = maxf(0.0, p._cd[i] - delta * p._cd_speed())
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	if _storm_t > 0.0 or _busy > 0.0:
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"blade_storm":
			_start_storm(mega)
		"stun_bomb":
			p._anim("throw")
			# Арена: две бомбы — ближняя и дальняя
			var throws := [640.0, 980.0] if Balance.arena(p) else [640.0]
			for vx in throws:
				var s := Spear.new()
				s.shooter = p
				s.team = p.team
				s.payload = "stun_bomb"
				s.damage = 6
				s.stun_time = 2.6 if mega else 1.6
				s.stun_radius = 230.0 if mega else 150.0
				s.velocity = Vector2(p.facing * vx, -380.0 - (vx - 640.0) * 0.25) + Vector2(p.velocity.x * 0.2, 0)
				s.position = (p.rig.muzzle() if p.rig else p.global_position) + Vector2(0, -6)
				p.get_parent().add_child(s)
		"kunai_leap":
			_leap(mega)

func _after(time: float, fn: Callable) -> void:
	get_tree().create_timer(time).timeout.connect(fn)

# ---------- 1. Вихрь клинков ----------
func _start_storm(mega: bool) -> void:
	_storm_mega = mega
	_storm_len = 2.4 if mega else 1.6
	_storm_t = _storm_len
	_storm_tick = 0.0
	_storm_hop = 0.0
	_last_pos = p.global_position
	p._forced_time = _storm_len
	p._forced_vx = 0.0
	p.armor_mult = 0.5                             # её почти не достать — мелькает
	if p._rig_root:
		p._rig_root.modulate.a = 0.0
	var world := p.get_parent()
	for k in (4 if mega else 3):
		var r := BotRig.new()
		r.kind = "assassin"
		r.size = p.body_size
		r.z_index = 5
		r.puppet_facing = 1 if k % 2 == 0 else -1
		r.modulate = Color(1, 1, 1, 0.0)
		world.add_child(r)
		r.global_position = p.global_position
		_puppets.append(r)
	Fx.sparks(world, p.global_position, Color(0.5, 0.75, 0.55), 10, 220.0, 3.0)

func _storm_tick_fn(delta: float) -> void:
	_storm_t -= delta
	var world := p.get_parent()
	var R := (STORM_R_MEGA if _storm_mega else STORM_R) * (1.25 if Balance.arena(p) else 1.0)   # Арена: шире
	# тени-рывки: каждая вспыхивает в новом месте вокруг героя
	_storm_hop -= delta
	if _storm_hop <= 0.0:
		_storm_hop = 0.06 if _storm_mega else 0.075
		var pup: BotRig = _puppets[randi() % _puppets.size()]
		if is_instance_valid(pup):
			var to := p.global_position + Vector2(randf_range(-R, R), randf_range(-14.0, 6.0))
			var streak := Line2D.new()
			streak.points = PackedVector2Array([_last_pos + Vector2(0, -10), to + Vector2(0, -10)])
			streak.width = 10.0
			streak.default_color = Color(0.35, 0.65, 0.45, 0.45)
			streak.z_index = 4
			world.add_child(streak)
			var st := streak.create_tween()
			st.tween_property(streak, "modulate:a", 0.0, 0.14)
			st.tween_callback(streak.queue_free)
			var face := 1 if to.x >= _last_pos.x else -1
			pup.global_position = to
			pup.puppet_facing = face
			pup.scale.x = face
			pup.modulate = Color(1, 1, 1, 0.95)
			pup.play(["cut1", "cut2", "cut3", "cut4"][randi() % 4])
			var ft := pup.create_tween()
			ft.tween_property(pup, "modulate:a", 0.25, 0.22)
			Fx.arc(world, to + Vector2(face * 30.0, -6.0), 34.0, -1.1 if face > 0 else PI - 1.1, 1.1 if face > 0 else PI + 1.1,
					Color(0.9, 1.0, 0.95, 0.85), 0.12, 10.0)
			_last_pos = to
	# урон всем, кто подошёл
	_storm_tick -= delta
	if _storm_tick <= 0.0:
		_storm_tick = 0.12
		for e in _enemies():
			var dd: Vector2 = e.global_position - p.global_position
			if absf(dd.x) < R + e.body_size.x / 2 and absf(dd.y) < 80.0 + e.body_size.y * 0.3:
				e.take_damage((5 if _storm_mega else 4) + (1 if Balance.arena(p) else 0), p)
	if _storm_t <= 0.0:
		_end_storm(true)

func _end_storm(finish: bool) -> void:
	_storm_t = 0.0
	for pup in _puppets:
		if is_instance_valid(pup):
			pup.queue_free()
	_puppets.clear()
	p.armor_mult = 1.0
	if p._rig_root:
		p._rig_root.modulate.a = 1.0
	if finish and _storm_mega and p.is_alive():
		# МЕГА: размашистый удар вокруг себя
		var world := p.get_parent()
		p._anim("big_cut")
		Fx.ring(world, p.global_position, 230.0, Color(0.6, 1.0, 0.75, 0.9), 0.35, 10.0, 0.45)
		Fx.arc(world, p.global_position, 150.0, -PI, PI, Color(0.95, 1.0, 0.95, 0.9), 0.3, 22.0)
		for e in _enemies():
			var dd: Vector2 = e.global_position - p.global_position
			if absf(dd.x) < 230.0 + e.body_size.x / 2 and absf(dd.y) < 120.0 + e.body_size.y * 0.3:
				e.take_damage(30, p)
				e.velocity = Vector2(signf(dd.x) * 520.0, -360.0)

# ---------- 3. Прыжок с кунаями ----------
func _leap(mega: bool) -> void:
	p._anim("dash_up")
	p.velocity.y = -1050.0
	p._forced_time = 0.42
	p._forced_vx = p.facing * 560.0
	p._forced_no_gravity = false
	Fx.sparks(p.get_parent(), p.global_position + Vector2(0, p.body_size.y / 2), Color(0.85, 0.95, 0.9), 8, 180.0, 4.0, true)
	_after(0.42, func():
		if not p.is_alive():
			return
		p.velocity = Vector2.ZERO
		p._forced_time = 0.5 if mega else 0.25        # зависает в верхней точке
		p._forced_vx = 0.0
		p._forced_no_gravity = true
		var waves := 3 if mega else 1
		if Balance.arena(p):
			waves += 1                                  # Арена: на волну кунаев больше
		for wv in waves:
			_after(wv * 0.16, _kunai_fan.bind(wv)))

func _kunai_fan(wave: int) -> void:
	if not p.is_alive():
		return
	p._anim("throw")
	for k in 7:
		var a := deg_to_rad(lerpf(52.0, 128.0, k / 6.0) + (wave - 1) * 5.0)
		var b := Bullet.new()
		b.shooter = p
		b.team = p.team
		b.direction = Vector2.from_angle(a)
		b.speed = 1150.0
		b.damage = 10
		b.size = 8.0
		b.color = KUNAI
		b.style = "kunai"
		b.position = p.global_position + Vector2(0, p.body_size.y * 0.2)
		p.get_parent().add_child(b)

# ---------- Ульта: Удар тени ----------
func ult() -> void:
	if _busy > 0.0:
		return
	p._anim("throw")
	var s := BigShuriken.new()
	s.team = p.team
	s.attacker = p
	s.dir = Vector2(p.facing, 0)
	s.position = (p.rig.muzzle() if p.rig else p.global_position) + Vector2(p.facing * 10.0, -4.0)
	p.get_parent().add_child(s)
	_shuriken = s
	s.done.connect(_on_shuriken)

func _on_shuriken(t) -> void:
	if t == null:
		p._float_label("Мимо!", Color(0.8, 0.8, 0.85))
		return                                     # промах: ульта уходит в откат
	_mark = t
	_mark_t = 4.0 if Balance.arena(p) else 3.0      # Арена: дольше ждёт второго нажатия
	p.ult_charge = p.ult_need                      # кнопка ульты снова горит — жми ещё раз!
	p._float_label("Ещё раз — удар тени!", Color(0.8, 0.6, 1.0))

func ult_recast() -> bool:
	if _mark_t <= 0.0:
		return false
	_mark_t = 0.0
	p.ult_charge = 0.0
	if not is_instance_valid(_mark) or not _mark.is_alive():
		return true
	if p._mega_ab():
		_shadow_mega(_mark)
	else:
		_shadow_strike(_mark, 60 if Balance.arena(p) else 45, 0.0)
	if is_instance_valid(_shuriken):
		_shuriken.release()
	return true

# Встать за спиной цели и ударить снизу вверх — разрез до самого неба
func _shadow_strike(t: Player, dmg: int, delay: float) -> void:
	var world := p.get_parent()
	_busy = delay + 0.9
	p._invuln = maxf(p._invuln, delay + 0.9)
	t.stun(delay + 1.3)
	t.velocity = Vector2.ZERO
	_after(delay, func():
		if not p.is_alive() or not is_instance_valid(t):
			return
		var from := p.global_position
		var tf: int = t.facing if t.facing != 0 else 1
		var x := clampf(t.global_position.x - tf * (t.body_size.x / 2 + 30.0), 60.0, p.map_w - 60.0)
		var feet: float = t.global_position.y + t.body_size.y / 2
		p.global_position = Vector2(x, feet - p.body_size.y / 2 - 1.0)
		p.velocity = Vector2.ZERO
		p.facing = int(signf(t.global_position.x - x))      # лицом к спине цели
		if p.facing == 0:
			p.facing = tf
		p._forced_time = 0.6
		p._forced_vx = 0.0
		p.set_tint(SHADOW)
		if p._rig_root:
			p._rig_root.modulate.a = 1.0
		_smoke(world, from)
		_smoke(world, p.global_position)
		_after(0.28, _uppercut.bind(t, dmg)))

func _uppercut(t: Player, dmg: int) -> void:
	if not p.is_alive():
		return
	var world := p.get_parent()
	p._anim("dash_up")
	var x: float = t.global_position.x if is_instance_valid(t) else p.global_position.x + p.facing * 40.0
	var ground: float = p.global_position.y + p.body_size.y / 2
	# разрез до неба: тёмная кромка, фиолетовое сияние и белое ядро
	var slash := Node2D.new()
	slash.z_index = 7
	world.add_child(slash)
	for layer in [[60.0, Color(0.35, 0.15, 0.55, 0.35)], [26.0, Color(0.65, 0.4, 0.95, 0.8)], [8.0, Color(1, 1, 1, 1)]]:
		var l := Line2D.new()
		l.points = PackedVector2Array([Vector2(x - 6, ground), Vector2(x + 10, -600.0)])
		l.width = layer[0]
		l.default_color = layer[1]
		var g := Gradient.new()
		g.set_color(0, Color(1, 1, 1, 1))
		g.set_color(1, Color(1, 1, 1, 0.3))
		l.gradient = g
		slash.add_child(l)
	var st := slash.create_tween()
	st.tween_interval(0.25)
	st.tween_property(slash, "modulate:a", 0.0, 0.45)
	st.tween_callback(slash.queue_free)
	Fx.arc(world, Vector2(x, ground - 30), 70.0, -PI * 0.9, -PI * 0.1, Color(0.9, 0.8, 1.0, 0.9), 0.25, 18.0)
	Fx.sparks(world, Vector2(x, ground - 40), Color(0.75, 0.55, 1.0), 16, 320.0, 4.0, true)
	if is_instance_valid(t) and t.is_alive():
		t.take_damage(dmg, p)
		t.velocity = Vector2(0, -900.0)
	# разрез задевает и других врагов на этой линии
	for e in _enemies():
		if e != t and absf(e.global_position.x - x) < e.body_size.x / 2 + 30.0 and e.global_position.y < ground + 10.0:
			e.take_damage(int(dmg * 0.5), p)
	_after(0.5, func():
		if _shadow_t <= 0.0:
			p.set_tint(Color.WHITE))

# МЕГА: 5 теней вокруг цели бьют разом, потом главная тень — разрез до неба,
# после чего Ассасин какое-то время остаётся тенью
func _shadow_mega(t: Player) -> void:
	var world := p.get_parent()
	_busy = 1.6
	p._invuln = maxf(p._invuln, 1.6)
	t.stun(2.2)
	t.velocity = Vector2.ZERO
	var c: Vector2 = t.global_position
	var offs := [Vector2(-160, 0), Vector2(160, 0), Vector2(-115, -120), Vector2(115, -120), Vector2(0, -190)]
	if Balance.arena(p):                            # Арена: 7 теней
		offs += [Vector2(-210, -60), Vector2(210, -60)]
	var clones: Array = []
	for o in offs:
		var r := BotRig.new()
		r.kind = "assassin"
		r.size = p.body_size
		r.z_index = 6
		r.puppet_facing = 1 if o.x < 0 else -1
		r.modulate = Color(0.07, 0.06, 0.1, 0.0)
		world.add_child(r)
		r.global_position = c + o + Vector2(0, t.body_size.y / 2 - p.body_size.y / 2)
		r.scale.x = r.puppet_facing
		var ft := r.create_tween()
		ft.tween_property(r, "modulate:a", 0.95, 0.15)
		_smoke(world, r.global_position)
		clones.append(r)
	if p._rig_root:
		p._rig_root.modulate.a = 0.0
	_after(0.5, func():
		for r in clones:
			if not is_instance_valid(r):
				continue
			var to: Vector2 = t.global_position if is_instance_valid(t) else c
			var streak := Line2D.new()
			streak.points = PackedVector2Array([r.global_position, to])
			streak.width = 12.0
			streak.default_color = Color(0.25, 0.15, 0.35, 0.8)
			streak.z_index = 6
			world.add_child(streak)
			var stw := streak.create_tween()
			stw.tween_property(streak, "modulate:a", 0.0, 0.25)
			stw.tween_callback(streak.queue_free)
			r.play("cut4")
			r.global_position = to.lerp(r.global_position, 0.25)
			var rt: Tween = r.create_tween()
			rt.tween_property(r, "modulate:a", 0.0, 0.3)
			rt.tween_callback(r.queue_free)
			if is_instance_valid(t) and t.is_alive():
				t.take_damage(6, p)                     # цель оглушена — урон и так удвоен
		Fx.ring(world, t.global_position if is_instance_valid(t) else c, 90.0, Color(0.7, 0.45, 1.0, 0.9), 0.25, 6.0))
	_shadow_strike(t, 40, 0.65)
	_after(1.6, func():
		if p.is_alive():
			_shadow_t = 6.0                          # форма тени
			p.set_tint(SHADOW_FORM)
			p.move_mult = 1.35
			p._float_label("Форма тени", Color(0.75, 0.6, 1.0)))

func _smoke(world: Node, at: Vector2) -> void:
	for k in 6:
		var puff := Polygon2D.new()
		puff.polygon = Util.circle(randf_range(12.0, 20.0), 10)
		puff.color = Color(0.12, 0.1, 0.16, 0.7)
		puff.position = at + Vector2(randf_range(-22, 22), randf_range(-30, 20))
		puff.z_index = 6
		world.add_child(puff)
		var t := puff.create_tween()
		t.set_parallel(true)
		t.tween_property(puff, "scale", Vector2(1.8, 1.8), 0.45)
		t.tween_property(puff, "modulate:a", 0.0, 0.45)
		t.chain().tween_callback(puff.queue_free)

# ---------- Каждый кадр ----------
func _physics_process(delta: float) -> void:
	super(delta)
	if p == null or not p.is_alive():
		return
	if _storm_t > 0.0:
		_storm_tick_fn(delta)
	if _busy > 0.0:
		_busy -= delta
	if _mark_t > 0.0:
		_mark_t -= delta
		if _mark_t <= 0.0 or not is_instance_valid(_mark) or not _mark.is_alive():
			_mark_t = 0.0
			p.ult_charge = 0.0                     # не успела — ульта снова в откате
			if is_instance_valid(_shuriken):
				_shuriken.release()
	if _shadow_t > 0.0:
		_shadow_t -= delta
		_shadow_fx -= delta
		if _shadow_fx <= 0.0 and absf(p.velocity.x) > 50.0:
			_shadow_fx = 0.08
			var ghost := Polygon2D.new()
			ghost.polygon = PackedVector2Array([Vector2(-12, -28), Vector2(12, -28), Vector2(15, 30), Vector2(-15, 30)])
			ghost.color = Color(0.25, 0.18, 0.35, 0.45)
			ghost.position = p.global_position
			ghost.z_index = -1
			p.get_parent().add_child(ghost)
			var gt := ghost.create_tween()
			gt.tween_property(ghost, "modulate:a", 0.0, 0.3)
			gt.tween_callback(ghost.queue_free)
		if _shadow_t <= 0.0:
			p.move_mult = 1.0
			p.set_tint(Color.WHITE)

func on_death() -> void:
	super()
	_end_storm(false)
	_busy = 0.0
	_mark_t = 0.0
	_shadow_t = 0.0
	p.move_mult = 1.0
	p.set_tint(Color.WHITE)
	if p._rig_root:
		p._rig_root.modulate.a = 1.0
