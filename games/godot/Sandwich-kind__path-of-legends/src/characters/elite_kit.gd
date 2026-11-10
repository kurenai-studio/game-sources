class_name EliteKit
extends HeroKit
# Легенды из Лавки (покупаются за монеты).
#   soldier — СОЛДАТ: автомат (бег с оружием наперевес, стрельба на ходу), пистолет
#             с электрошоком, кувырок с гранатой, бросок ножа, ульта «Авиаудар».
#   samurai — САМУРАЙ: катана (серия из 5 разных ударов), дальний взмах, сюрикены,
#             рывок сквозь блоки, ульта «Пламя клинка» (МЕГА — синее пламя).

# Солдат
var _fire_t := 0.0
var _knife_skill := false
var _run_t := 0.0
var _run_hit := 0.0
# Самурай
var _combo := 0
var _combo_t := 0.0
var _flurry_t := 0.0
var _flurry_tick := 0.0
var _frozen: Array = []
var _dash_t := 0.0
var flame_t := 0.0
var _flame_mega := false
var _flame_fx := 0.0

const ORANGE_FIRE := Color(1.0, 0.55, 0.15, 0.95)
const BLUE_FIRE := Color(0.35, 0.65, 1.0, 0.95)

# ---------- Стрельба ----------
func weapon(delta: float, shoot: bool) -> void:
	if hero == "samurai":
		_katana(delta, shoot)
		return
	_rifle(delta, shoot)

func _rifle(delta: float, shoot: bool) -> void:
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
	if shoot and p._cooldown_left <= 0.0 and p._reloading <= 0.0 and p.ammo > 0 and _run_t <= 0.0:
		var b := p._shoot_bullet(p.bullet_speed, p.bullet_damage, 0.0, p.bullet_size, randf_range(-0.04, 0.04))
		b.color = Color(1.0, 0.9, 0.5)
		b.restyle("tracer")
		if p.is_mega("rapid"):
			b.pierce = 3
		_fire_t = 0.35
		p._cooldown_left = p.fire_cooldown * (0.6 if rapid else 1.0)
		if not rapid:
			p.ammo -= 1
			if p.ammo <= 0:
				p._reloading = p.reload_time

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	p._cd[i] = maxf(0.0, p._cd[i] - delta * p._cd_speed())
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	if _flurry_t > 0.0 or _run_t > 0.0:
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"pistol":
			var arena := Balance.arena(p)
			if mega:
				var shots := 4 if arena else 3           # Арена: на выстрел больше
				for k in shots:
					_after(k * 0.16, _pistol_shot)
				_after(shots * 0.16 + 0.07, _draw_knife_throw.bind(false))
			elif arena:
				_pistol_shot()                           # Арена: два выстрела шокером
				_after(0.18, _pistol_shot)
				_after(0.6, _holster)
			else:
				_pistol_shot()
				_after(0.4, _holster)
		"roll_grenade":
			if mega:
				_knife_run()
			else:
				p._forced_time = 0.38
				p._forced_vx = p.facing * 760.0
				p._forced_no_gravity = false
				p._invuln = 0.4
				p._anim("roll_f")
				_after(0.18, _grenade.bind(Vector2(p.facing * 640.0, -380.0)))
				if Balance.arena(p):                     # Арена: вторая граната подальше
					_after(0.3, _grenade.bind(Vector2(p.facing * 860.0, -440.0)))
		"knife":
			_knife_skill = true                      # нож брошен способностью (не после пистолета)
			_draw_knife_throw(mega)
		"wave":
			if mega:
				_start_flurry()
			else:
				# широкий удар мечом по большой области перед собой
				p._anim("big_cut")
				p._forced_time = 0.35
				p._forced_vx = p.facing * 160.0
				_after(0.3, _wide_cut)
				if Balance.arena(p):
					_after(0.32, _launch_wave)          # Арена: взмах ещё и пускает волну вперёд
		"shuriken":
			_shurikens(mega)
		"dash":
			if mega:
				_teleport()
			else:
				_dash_up()

func _after(time: float, fn: Callable) -> void:
	get_tree().create_timer(time).timeout.connect(fn)

# ---------- Ульта ----------
func ult() -> void:
	if hero == "samurai":
		_ignite()
	else:
		_call_airstrike()

# ---------- Каждый кадр ----------
func _physics_process(delta: float) -> void:
	super(delta)
	if p == null or not p.is_alive():
		return
	if hero == "soldier":
		_soldier_tick(delta)
	else:
		_samurai_tick(delta)

func on_death() -> void:
	super()
	_fire_t = 0.0
	_run_t = 0.0
	_flurry_t = 0.0
	_dash_t = 0.0
	if flame_t > 0.0:
		flame_t = 0.0
		_end_flame()
	_release_frozen()
	if p.rig:
		p.rig.hold = ""
		p.rig.alt = ""
	p.collision_mask = Player.NORMAL_MASK
	p.move_mult = 1.0

# ======================= СОЛДАТ =======================
func _soldier_tick(delta: float) -> void:
	if _fire_t > 0.0:
		_fire_t -= delta
	if p.rig:
		p.rig.hold = "aim" if _fire_t > 0.0 and _run_t <= 0.0 else ""
	# стреляя, идёт шагом; без стрельбы — бежит быстрее всех
	if _run_t <= 0.0:
		p.move_mult = 0.62 if _fire_t > 0.0 else 1.0
	if _run_t > 0.0:
		_run_t -= delta
		p._invuln = maxf(p._invuln, 0.05)        # во время пробежки неуязвим
		_run_hit -= delta
		if _run_hit <= 0.0:
			_run_hit = 0.15
			_melee(80.0, 45.0, 6, 150.0, 10, false)
			Fx.arc(p.get_parent(), p.global_position + Vector2(p.facing * 25.0, -6.0), 46.0,
					_ang(-1.0), _ang(1.0), Color(1, 1, 1, 0.6), 0.12, 10.0)
		if _run_t <= 0.0:
			_final_slash()

# стороны дуги удара с учётом того, куда смотрит герой
func _ang(a: float) -> float:
	return a if p.facing > 0 else PI - a

func _pistol_shot() -> void:
	if not p.is_alive():
		return
	if p.rig:
		p.rig.alt = "pistol"
	p._anim("pistol")
	var b := Bullet.new()
	b.shooter = p
	b.team = p.team
	b.direction = Vector2(p.facing, 0)
	b.speed = 1600.0
	b.damage = 12
	b.size = 7.0
	b.color = Color(0.55, 0.85, 1.0)
	b.shock = 0.9
	b.style = "shock"
	b.position = p.rig.muzzle() if p.rig else p.global_position
	if p.rig and p.rig._alts.has("pistol"):
		var ps: Sprite2D = p.rig._alts["pistol"]
		b.position = ps.to_global(Vector2(ps.texture.get_width(), ps.texture.get_height() / 2.0) + ps.offset)
	p.get_parent().add_child(b)
	Fx.zap(p.get_parent(), b.position, Color(0.55, 0.85, 1.0), 14.0)

func _holster() -> void:
	if p.rig and _run_t <= 0.0:
		p.rig.alt = ""

# Достаёт нож и бросает во врага (МЕГА — нож-бомба)
func _draw_knife_throw(bomb: bool) -> void:
	if not p.is_alive():
		return
	if p.rig:
		p.rig.alt = "knife"
	p._anim("throw")
	_after(0.12, _knife_release.bind(bomb))
	_after(0.4, _holster)

func _knife_release(bomb: bool) -> void:
	if not p.is_alive():
		return
	var from: Vector2 = p.global_position + Vector2(p.facing * 20.0, -14.0)
	var aim := Vector2(p.facing, -0.04).normalized()
	var e := _nearest_enemy(900.0)
	if e and signf(e.global_position.x - p.global_position.x) == p.facing:
		aim = (e.global_position - from).normalized()
	# Арена: три ножа веером (МЕГА — три ножа-бомбы)
	var spread := [-0.12, 0.0, 0.12] if Balance.arena(p) and _knife_skill else [0.0]
	_knife_skill = false
	for sp in spread:
		var a := Arrow.new()
		a.shooter = p
		a.team = p.team
		a.mode = "knife_bomb" if bomb else "knife"
		a.damage = 12 if bomb else 34
		a.cell_damage = 30
		a.gravity = 250.0
		a.velocity = aim.rotated(sp) * 1450.0
		a.position = from
		p.get_parent().add_child(a)
	if p.rig:
		p.rig.alt = ""

func _grenade(vel: Vector2) -> void:
	if not p.is_alive():
		return
	var g := Grenade.new()
	g.team = p.team
	g.attacker = p
	g.fuse = 1.2
	g.style = "frag"
	g.position = p.global_position + Vector2(p.facing * 20.0, -20.0)
	g.linear_velocity = vel
	g.angular_velocity = p.facing * 8.0
	p.get_parent().add_child(g)
	g.add_collision_exception_with(p)

# МЕГА: пробежка с ножом — неуязвим, бьёт перед собой, бросает 3 гранаты
func _knife_run() -> void:
	_run_t = 0.9
	_run_hit = 0.05
	p._forced_time = 0.9
	p._forced_vx = p.facing * 640.0
	p._forced_no_gravity = false
	p._invuln = 0.95
	if p.rig:
		p.rig.alt = "knife"
		p.rig.hold = ""
	p._anim("knife_run")
	for k in (5 if Balance.arena(p) else 3):      # Арена: 5 гранат
		_grenade(Vector2(p.facing * (440.0 + k * 120.0), -300.0 - k * 50.0))
	Fx.sparks(p.get_parent(), p.global_position + Vector2(0, p.body_size.y / 2), Color(0.8, 0.75, 0.65), 8, 160.0, 4.0, true)

func _final_slash() -> void:
	p._anim("slash")
	p._forced_time = 0.3
	p._forced_vx = 0.0
	_after(0.12, _final_slash_hit)
	_after(0.45, _holster)

func _final_slash_hit() -> void:
	if not p.is_alive():
		return
	_melee(150.0, 70.0, 24, 520.0, 40, true)
	Fx.arc(p.get_parent(), p.global_position + Vector2(p.facing * 20.0, -8.0), 120.0, _ang(-2.0), _ang(1.4),
			Color(1, 1, 1, 0.8), 0.25, 26.0)

# Ульта: рация, метка на враге, самолёт
func _call_airstrike() -> void:
	var world := p.get_parent()
	var mega := p._mega_ab()
	p._forced_time = 0.9
	p._forced_vx = 0.0
	p._anim("radio")
	if p.rig:
		p.rig.alt = "radio"
		p.rig.hold = ""
	_after(0.95, _holster)
	for k in 3:                                   # радиоволны над рацией
		_after(0.15 + k * 0.2, _radio_wave)
	var e := _nearest_enemy(2400.0)
	var marks: Array = [e]
	if Balance.arena(p) and e:
		# Арена: метки на трёх врагах — бомбы падают на каждого по очереди
		var es := _enemies().filter(func(x): return x != e)
		es.sort_custom(func(a, b): return a.global_position.distance_to(p.global_position) < b.global_position.distance_to(p.global_position))
		marks += es.slice(0, 2)
	for i in marks.size():
		_mark_strike(world, marks[i], mega and i == 0, 3.5 + i * 0.5)

func _mark_strike(world: Node, e, mega: bool, delay: float) -> void:
	var tx: float = e.global_position.x if e else p.global_position.x + p.facing * 500.0
	var ty: float = e.global_position.y if e else p.global_position.y
	var ground := p.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(Vector2(tx, ty - 10.0), Vector2(tx, ty + 900.0), Layer.WORLD | Layer.FRAME))
	var gy: float = ground["position"].y if not ground.is_empty() else ty + 30.0
	var st := AirStrike.new()
	st.team = p.team
	st.attacker = p
	st.mega = mega
	st.target = Vector2(tx, gy)
	st.map_w = p.map_w
	st.sky_y = maxf(p.map_top + 70.0, gy - 640.0)
	st.delay = delay
	world.add_child(st)

func _radio_wave() -> void:
	if not p.is_alive():
		return
	var at: Vector2 = p.global_position + Vector2(-p.facing * 4.0, -p.body_size.y * 0.6)
	if p.rig and p.rig._alts.has("radio"):
		at = p.rig._alts["radio"].global_position
	Fx.ring(p.get_parent(), at, 40.0, Color(0.5, 1.0, 0.5, 0.8), 0.4, 3.0)

# ======================= САМУРАЙ =======================
const CUT_CD := [0.36, 0.36, 0.38, 0.38, 0.55]
const CUT_HIT := [0.15, 0.15, 0.17, 0.14, 0.25]
const CUT_DMG := [9, 9, 12, 11, 20]
const CUT_REACH := [130.0, 120.0, 135.0, 165.0, 150.0]
const CUT_ARC := [[-2.3, 0.8], [1.1, -1.5], [-1.9, 1.0], [-0.15, 0.15], [-2.6, 2.6]]

func _katana(delta: float, shoot: bool) -> void:
	p.ammo = p.clip_size
	p._reloading = 0.0
	_combo_t -= delta
	if _combo_t <= 0.0:
		_combo = 0
	if not shoot or p._cooldown_left > 0.0 or _flurry_t > 0.0 or _dash_t > 0.0:
		return
	var step := _combo
	_combo = (_combo + 1) % 5
	_combo_t = 1.0
	var spd := 1.0
	if flame_t > 0.0:
		spd = 0.45 if _flame_mega else 0.8           # в ульте — быстрее, в МЕГА — молниеносно
	if p.has_buff("rapid"):
		spd *= 0.6
	p._anim("cut%d" % (step + 1))
	_after(CUT_HIT[step] * spd, _cut_hit.bind(step))
	p._cooldown_left = CUT_CD[step] * spd
	if step == 3:
		p._forced_time = 0.12                         # выпад — шаг вперёд
		p._forced_vx = p.facing * 520.0

func _cut_hit(step: int) -> void:
	if not p.is_alive():
		return
	var both := step == 4                             # удар с разворотом — во все стороны
	_melee(CUT_REACH[step], 60.0 if step != 3 else 38.0, CUT_DMG[step], 300.0 if step == 4 else 160.0, 26, both)
	var col := Color(1, 1, 1, 0.75)
	if flame_t > 0.0:
		col = BLUE_FIRE if _flame_mega else ORANGE_FIRE
	var c := p.global_position + Vector2(p.facing * 18.0, -10.0)
	var arc: Array = CUT_ARC[step]
	if step == 3:
		# выпад: длинный тонкий след вперёд
		var l := Line2D.new()
		l.points = PackedVector2Array([c, c + Vector2(p.facing * CUT_REACH[step], 0)])
		l.width = 7.0
		l.default_color = col
		l.z_index = 8
		p.get_parent().add_child(l)
		var t := l.create_tween()
		t.tween_property(l, "modulate:a", 0.0, 0.18)
		t.tween_callback(l.queue_free)
	elif both:
		Fx.arc(p.get_parent(), c, CUT_REACH[step] * 0.8, -PI, PI, col, 0.25, 18.0)
	else:
		Fx.arc(p.get_parent(), c, CUT_REACH[step] * 0.75, _ang(arc[0]), _ang(arc[1]), col, 0.18, 18.0)

func _wide_cut() -> void:
	if not p.is_alive():
		return
	_melee(240.0, 110.0, 24, 420.0, 40, false)
	var col := Color(1, 1, 1, 0.85)
	if flame_t > 0.0:
		col = BLUE_FIRE if _flame_mega else ORANGE_FIRE
	var c := p.global_position + Vector2(p.facing * 20.0, -10.0)
	Fx.arc(p.get_parent(), c, 210.0, _ang(-2.2), _ang(1.3), col, 0.3, 46.0)
	Fx.arc(p.get_parent(), c, 150.0, _ang(-2.0), _ang(1.1), Color(1, 1, 1, 0.5), 0.22, 18.0)
	Fx.sparks(p.get_parent(), c + Vector2(p.facing * 150.0, 0), col, 10, 240.0, 4.0)

func _launch_wave() -> void:
	if not p.is_alive():
		return
	var w := SlashWave.new()
	w.team = p.team
	w.attacker = p
	w.dir = p.facing
	w.position = p.global_position + Vector2(p.facing * 40.0, -6.0)
	if flame_t > 0.0:
		w.color = BLUE_FIRE if _flame_mega else ORANGE_FIRE
		w.burn = 9.0 if _flame_mega else 7.0
		if _flame_mega:
			w.freeze = 1.3
	p.get_parent().add_child(w)

# МЕГА-взмах: серия молниеносных ударов — задетые враги замирают
func _start_flurry() -> void:
	_flurry_t = 1.0
	_flurry_tick = 0.0
	_frozen.clear()
	p._forced_time = 1.45
	p._forced_vx = 0.0
	p._anim("flurry")
	_after(1.0, _flurry_finish)

func _flurry_finish() -> void:
	if not p.is_alive():
		_release_frozen()
		return
	p._anim("big_cut")
	_after(0.22, _flurry_big_hit)

func _flurry_big_hit() -> void:
	if not p.is_alive():
		_release_frozen()
		return
	_release_frozen()                              # «отпускает» время...
	_melee(190.0, 80.0, 30, 520.0, 60, false)      # ...и бьёт мощным взмахом
	if Balance.arena(p):
		_launch_wave()
	var col := Color(1, 1, 1, 0.85)
	if flame_t > 0.0:
		col = BLUE_FIRE if _flame_mega else ORANGE_FIRE
	Fx.arc(p.get_parent(), p.global_position + Vector2(p.facing * 20.0, -10.0), 160.0, _ang(-2.3), _ang(1.2), col, 0.3, 34.0)
	Fx.ring(p.get_parent(), p.global_position + Vector2(p.facing * 110.0, 0), 90.0, Color(1, 1, 1, 0.8), 0.3, 5.0)

func _release_frozen() -> void:
	for e in _frozen:
		if is_instance_valid(e) and e.is_alive():
			e._stun_t = 0.0
			e.set_tint(Color.WHITE)
	_frozen.clear()

func _shurikens(mega: bool) -> void:
	p._anim("throw")
	var angles := [-0.2, -0.1, 0.0, 0.1, 0.2] if mega else [-0.12, 0.0, 0.12]
	var arena := Balance.arena(p)
	if arena:                                     # Арена: больше сюрикенов, каждый пробивает больше врагов
		angles = [-0.27, -0.18, -0.09, 0.0, 0.09, 0.18, 0.27] if mega else [-0.2, -0.1, 0.0, 0.1, 0.2]
	for a in angles:
		var s := Shuriken.new()
		s.shooter = p
		s.team = p.team
		s.direction = Vector2(p.facing, 0).rotated(a * p.facing)
		s.damage = 10
		s.speed = 1100.0
		s.max_targets = (4 if mega else 2) if arena else (3 if mega else 1)
		s.detailed = true
		s.pierce = 30.0 if mega else 10.0
		s.position = p.global_position + Vector2(p.facing * 20.0, -8.0)
		if flame_t > 0.0:
			s.set_meta("burn", 7.0)
			if _flame_mega:
				s.chain = true                      # электрические сюрикены
				s.color = Color(0.6, 0.85, 1.0)
			else:
				s.color = Color(1.0, 0.6, 0.25)
		p.get_parent().add_child(s)
		s._life = 0.75 if mega else 0.65            # не через всю карту

# Рывок вверх-вперёд: пока летит вверх — сквозь блоки
func _dash_up() -> void:
	if Balance.arena(p):
		_dash_slash(p.global_position)              # Арена: рывок рассекает всех на пути
	_dash_t = 0.7
	p._forced_time = 0.3
	p._forced_vx = p.facing * 640.0
	p._forced_no_gravity = false
	p.velocity.y = -980.0
	p.collision_mask = Player.PHASE_MASK
	p._anim("dash_up")
	Fx.sparks(p.get_parent(), p.global_position + Vector2(0, p.body_size.y / 2), Color(0.9, 0.9, 1.0), 8, 180.0, 4.0, true)

# Арена: через мгновение после рывка — разрез по всей линии пути
func _dash_slash(from: Vector2) -> void:
	_after(0.28, func():
		if not p.is_alive():
			return
		var to := p.global_position
		var hit := false
		for e in _enemies():
			var cp := Geometry2D.get_closest_point_to_segment(e.global_position, from, to)
			if cp.distance_to(e.global_position) < 60.0 + e.body_size.x * 0.5:
				e.take_damage(16, p)
				_fire_effects(e)
				hit = true
		var l := Line2D.new()
		l.points = PackedVector2Array([from, to])
		l.width = 8.0 if hit else 5.0
		l.default_color = Color(0.95, 0.97, 1.0, 0.8)
		l.z_index = 8
		p.get_parent().add_child(l)
		var t := l.create_tween()
		t.tween_property(l, "modulate:a", 0.0, 0.25)
		t.tween_callback(l.queue_free))

func _end_dash() -> void:
	_dash_t = 0.0
	p.collision_mask = Player.NORMAL_MASK
	_push_out()                                   # застрял в блоке — выталкиваем

# МЕГА: мгновенный телепорт в конечную точку и удар вниз
func _teleport() -> void:
	var world := p.get_parent()
	var from := p.global_position
	if Balance.arena(p):
		_dash_slash(from)
	var to := from + Vector2(p.facing * 300.0, -230.0)
	to.x = clampf(to.x, 40.0, p.map_w - 40.0)
	to.y = maxf(to.y, p.map_top + 40.0)
	_afterimage(from)
	p.global_position = to
	p.velocity = Vector2.ZERO
	_push_out()
	Fx.sparks(world, from, Color(0.85, 0.9, 1.0), 12, 220.0, 4.0)
	Fx.ring(world, p.global_position, 60.0, Color(0.9, 0.95, 1.0, 0.9), 0.3, 4.0)
	var trail := Line2D.new()
	trail.points = PackedVector2Array([from, p.global_position])
	trail.width = 10.0
	trail.default_color = Color(0.9, 0.95, 1.0, 0.6)
	trail.z_index = 7
	world.add_child(trail)
	var t := trail.create_tween()
	t.tween_property(trail, "modulate:a", 0.0, 0.3)
	t.tween_callback(trail.queue_free)
	p._anim("cut_down")
	p._forced_time = 0.3
	p._forced_vx = p.facing * 120.0
	p.velocity.y = 700.0
	_after(0.1, _down_cut_hit)

func _down_cut_hit() -> void:
	if not p.is_alive():
		return
	var world := p.get_parent()
	var c := p.global_position + Vector2(p.facing * 40.0, 30.0)
	for e in _enemies():
		var d: Vector2 = e.global_position - c
		if absf(d.x) < 120.0 + e.body_size.x / 2 and d.y > -90.0 and d.y < 220.0:
			e.take_damage(26, p)
			e.velocity = Vector2(p.facing * 300.0, 400.0)
			_fire_effects(e)
	for n in world.get_children():
		if n is Destructible and n.shield_team != p.team and not n.background \
				and n.global_position.distance_to(c) < 500.0:
			for x in [-40.0, 0.0, 40.0, 80.0]:
				for y in [0.0, 40.0, 80.0]:
					n.hit(c + Vector2(p.facing * x, y), Vector2.DOWN, 30, 6.0, p.team, {"strict": true, "attacker": p})
	Fx.arc(world, p.global_position, 120.0, _ang(-1.6), _ang(1.4), Color(0.95, 0.97, 1.0, 0.85), 0.25, 24.0)

func _afterimage(at: Vector2) -> void:
	var g := Polygon2D.new()
	g.polygon = PackedVector2Array([Vector2(-14, -30), Vector2(14, -30), Vector2(18, 30), Vector2(-18, 30)])
	g.color = Color(0.8, 0.85, 1.0, 0.45)
	g.position = at
	g.z_index = 5
	p.get_parent().add_child(g)
	var t := g.create_tween()
	t.tween_property(g, "modulate:a", 0.0, 0.35)
	t.tween_callback(g.queue_free)

# Ульта: клинок вспыхивает пламенем
func _ignite() -> void:
	var mega := p._mega_ab()
	_flame_mega = mega
	p._forced_time = 0.85
	p._forced_vx = 0.0
	p._anim("ignite")
	var col := BLUE_FIRE if mega else ORANGE_FIRE
	Fx.rune_circle(p.get_parent(), p.global_position + Vector2(0, p.body_size.y / 2), 70.0, col, 1.1)
	Fx.glow(p.get_parent(), p.global_position, 70.0, Color(col, 0.25), 1.0)
	_after(0.45, _light_blade)

func _light_blade() -> void:
	if not p.is_alive():
		return
	var col := BLUE_FIRE if _flame_mega else ORANGE_FIRE
	flame_t = 13.0 if Balance.arena(p) else 9.0        # Арена: клинок горит дольше
	if p.rig:
		p.rig.blade_fire = col
	p.move_mult = 1.55 if _flame_mega else 1.3
	var tip: Vector2 = p.rig.tip() if p.rig else p.global_position
	Fx.star(p.get_parent(), tip, 26.0, Color(col, 0.95), 0.4)
	Fx.sparks(p.get_parent(), tip, col, 16, 260.0, 4.0)
	Fx.ring(p.get_parent(), p.global_position, 130.0, col, 0.45, 6.0)

func _end_flame() -> void:
	if p.rig:
		p.rig.blade_fire = Color(0, 0, 0, 0)
	p.move_mult = 1.0

func _samurai_tick(delta: float) -> void:
	if _flurry_t > 0.0:
		_flurry_t -= delta
		_flurry_tick -= delta
		if _flurry_tick <= 0.0:
			_flurry_tick = 0.06
			for e in _enemies():
				var to: Vector2 = e.global_position - p.global_position
				if (signf(to.x) == p.facing or absf(to.x) < 20.0) and absf(to.x) < 150.0 + e.body_size.x / 2 \
						and absf(to.y) < 70.0 + e.body_size.y / 2:
					e.take_damage(3, p)
					e.velocity = Vector2.ZERO
					e.stun(3.0)                           # замер на месте до конца серии
					if not _frozen.has(e):
						_frozen.append(e)
						e.set_tint(Color(0.75, 0.8, 1.0))
					_fire_effects(e)
			var c := p.global_position + Vector2(p.facing * (40.0 + randf() * 70.0), randf_range(-40.0, 25.0))
			var a := randf_range(-PI, PI)
			Fx.arc(p.get_parent(), c, randf_range(30.0, 55.0), a, a + 2.2, Color(1, 1, 1, 0.7), 0.1, 8.0)
	if _dash_t > 0.0:
		_dash_t -= delta
		if p.velocity.y >= 0.0 or _dash_t <= 0.0:
			_end_dash()                           # перестал лететь вверх — снова твёрдый
	if flame_t > 0.0:
		flame_t -= delta
		_flame_fx -= delta
		if _flame_fx <= 0.0 and p.rig:
			_flame_fx = 0.07
			var col := BLUE_FIRE if _flame_mega else ORANGE_FIRE
			Fx.sparks(p.get_parent(), p.rig.tip(), col, 2, 90.0, 4.0, true)
			Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-14, 14), 20), Color(col, 0.6), 1, 80.0, 3.0, true)
		if flame_t <= 0.0:
			_end_flame()

# Поджог и (в МЕГА-ульте) заморозка от ударов Самурая
func _fire_effects(e: Player) -> void:
	if flame_t <= 0.0:
		return
	e.burn(3.0, 9.0 if _flame_mega else 7.0, p)

# ======================= общее =======================
# Удар перед героем: враги в прямоугольнике и клетки блоков.
# both — во все стороны (удар с разворотом).
func _melee(reach: float, half_h: float, dmg: int, knock: float, cell_dmg: int, both: bool) -> void:
	var world := p.get_parent()
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		if both or signf(to.x) == p.facing or absf(to.x) < 20.0:
			if absf(to.x) < reach + e.body_size.x / 2 and absf(to.y) < half_h + e.body_size.y / 2:
				e.take_damage(dmg, p)
				var side := signf(to.x) if both and to.x != 0.0 else float(p.facing)
				e.velocity = Vector2(side * knock, -150.0)
				_fire_effects(e)
				if hero == "samurai" and flame_t > 0.0 and _flame_mega and _flurry_t <= 0.0:
					e.stun(1.0)                           # МЕГА-ульта: удары замораживают
					Fx.ice(e, e.body_size, 1.0)
	for n in world.get_children():
		if n is Destructible and n.shield_team != p.team and not n.background \
				and n.global_position.distance_to(p.global_position) < 500.0:
			var x := 30.0
			while x <= reach:
				for sgn in ([-1.0, 1.0] if both else [float(p.facing)]):
					var y := -half_h
					while y <= half_h * 0.6:
						n.hit(p.global_position + Vector2(sgn * x, y), Vector2(sgn, 0), cell_dmg, 5.0, p.team,
								{"strict": true, "attacker": p, "power": 0.5, "fire": flame_t > 0.0})
						y += 22.0
				x += 22.0
