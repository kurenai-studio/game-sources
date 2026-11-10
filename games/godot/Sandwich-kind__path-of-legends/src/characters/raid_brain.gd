class_name RaidBrain
extends Node
# ---------- Особое поведение боссов Деревни и Колизея ----------
#   ataman, gladiator — «вихрь»: крутятся с оружием и идут на героя, потом
#                       у них кружится голова (оглушены → урон ×2);
#   colossus          — три фазы: обычная, «ярость» (с 2/3 здоровья: быстрее,
#                       зовёт бойцов) и «перегрев» (с 1/3: ещё быстрее, но
#                       раскалённая броня слабее, а спина уязвима сильнее).
#                       Пар из труб на спине, горящие глаза, земля трескается
#                       под шагами.
#                       Повергнутый, Колосс не умирает, а ПРОБУЖДАЕТСЯ (вторая фаза):
#                       броня разлетается, в груди пылает огненное сердце, небо
#                       над Колизеем горит и с него падают метеоры (InfernoSky).
#                       Новые атаки: огненный рывок (за ним горит земля),
#                       прыжок-метеор (тень с неба → удар и столбы пламени),
#                       залп лавой и «Сверхновая» — после неё он выдыхается
#                       (оглушён, урон ×2).
#   witch             — «стая воронов»: рассыпается воронами и появляется
#                       в другом конце поля;
#   bog_lord          — ныряет в трясину: по земле к герою бегут пузыри,
#                       потом Владыка вырывается из грязи прямо под ним.

var p: Player
var kind := ""
var _whirl_t := 0.0
var _whirl_tick := 0.0
var _disc: Node2D
var _phase := 0
var _vent_t := 0.0
var _step_t := 0.0
var _eye: Polygon2D
var _core: Polygon2D
var _t := 0.0
var _crush_t := 0.0
var _hide_t := 0.0             # ведьма в стае воронов / Владыка под трясиной
var _hide_kind := ""
var _goal_x := 0.0
var _floor_y := 0.0
# ----- Колосс: вторая фаза -----
var _awake := false
var _waking := false
var _cracks: Node2D
var _sky: Node2D
var _ember_t := 0.0
var _dash_t := 0.0
var _dash_dir := 1.0
var _dash_hit := {}
var _trail_x := 0.0
var _leap := ""                 # crouch, up, track, lock, fall
var _leap_t := 0.0
var _leap_ground := 0.0
var _shadow: Node2D
var _nova_t := 0.0
var _nova_fx: Node2D
var _rig_y := 0.0
const NOVA_R := 440.0
const NOVA_T := 2.4

func _ready() -> void:
	name = "RaidBrain"
	if kind == "colossus":
		_eye = Polygon2D.new()
		_eye.polygon = Util.circle(16.0, 12)
		_eye.color = Color(1.0, 0.2, 0.1, 0.55)
		_eye.z_index = 3
		p.add_child.call_deferred(_eye)
		_core = Polygon2D.new()
		_core.polygon = Util.circle(26.0, 16)
		_core.color = Color(1.0, 0.45, 0.15, 0.0)
		_core.z_index = 3
		p.add_child.call_deferred(_core)
		p.on_lethal = _on_lethal              # смертельный удар — не конец: Колосс пробуждается

func _physics_process(delta: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		if _disc:
			_disc.queue_free()
			_disc = null
		return
	_t += delta
	if _whirl_t > 0.0:
		_whirl_tick_fn(delta)
	if kind == "colossus":
		if _awake:
			_colossus_awake(delta)
		elif not _waking:
			_colossus(delta)
	if _hide_t > 0.0:
		_hidden_tick(delta)
	elif kind == "bog_lord" and fmod(_t, 0.4) < delta:
		# с Владыки капает грязь, вокруг жужжит мошкара
		Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-60, 60), p.body_size.y * 0.2), Color(0.28, 0.30, 0.18), 2, 60.0, 4.0)

# ---------- Вихрь ----------
func start_whirl(time: float) -> void:
	_whirl_t = time
	_whirl_tick = 0.0
	if p.rig:
		p.rig.play("swing")
	_disc = Node2D.new()
	_disc.z_index = 4
	p.add_child(_disc)
	var r := p.body_size.x / 2 + 60.0
	for k in 3:                                        # три размытых лезвия по кругу
		var bl := Polygon2D.new()
		var a0 := TAU * k / 3.0
		var pts := PackedVector2Array()
		for i in 9:
			pts.append(Vector2.from_angle(a0 + i * 0.12) * r)
		for i in 9:
			pts.append(Vector2.from_angle(a0 + (8 - i) * 0.12) * (r - 18.0))
		bl.polygon = pts
		bl.color = Color(0.85, 0.87, 0.92, 0.75)
		_disc.add_child(bl)
	var ring := Line2D.new()
	var rp := Util.circle(r - 9.0, 28)
	rp.append(rp[0])
	ring.points = rp
	ring.width = 3.0
	ring.default_color = Color(1, 1, 1, 0.35)
	_disc.add_child(ring)
	_disc.scale = Vector2(1.0, 0.45)                    # крутится плашмя, вокруг пояса

func _whirl_tick_fn(delta: float) -> void:
	_whirl_t -= delta
	var dir := float(p.facing)
	if is_instance_valid(p.target):
		dir = signf(p.target.global_position.x - p.global_position.x)
	p._forced_time = 0.1
	p._forced_vx = dir * 270.0
	if _disc:
		_disc.rotation = 0.0
		for c in _disc.get_children():
			if c is Polygon2D:
				c.rotation += delta * 18.0
	if p.rig and fmod(_whirl_t, 0.5) < delta:
		p.rig.play("swing")
	_whirl_tick -= delta
	if _whirl_tick <= 0.0:
		_whirl_tick = 0.2
		var reach := p.body_size.x / 2 + 70.0
		for n in p.get_parent().get_children():
			if n is Player and n.team != p.team and n.is_alive():
				var dd: Vector2 = n.global_position - p.global_position
				if absf(dd.x) < reach + n.body_size.x / 2 and absf(dd.y) < p.body_size.y / 2 + 20.0:
					n.take_damage(7 if kind == "ataman" else 8, p)
					n.velocity.x = signf(dd.x) * 380.0
		Fx.sparks(p.get_parent(), p.global_position + Vector2(0, p.body_size.y / 2 - 4), Color(0.7, 0.6, 0.45), 3, 160.0, 3.0)
	if _whirl_t <= 0.0:
		_whirl_t = 0.0
		if _disc:
			_disc.queue_free()
			_disc = null
		p._forced_time = 0.0
		p.stun(1.6)                                    # голова кружится
		p._float_label("Голова кружится!", Color(1.0, 0.9, 0.4))

# ---------- Колосс ----------
func _colossus(delta: float) -> void:
	var bs := p.body_size
	# горящий глаз и ядро в груди
	_eye.position = Vector2(p.facing * bs.x * 0.2, -bs.y * 0.36)
	_eye.color.a = 0.45 + 0.25 * sin(_t * 5.0) + (0.2 if _phase >= 1 else 0.0)
	_core.position = Vector2(p.facing * bs.x * 0.05, -bs.y * 0.12)
	if _phase >= 2:
		_core.color = Color(1.0, 0.5 + 0.2 * sin(_t * 9.0), 0.15, 0.55 + 0.2 * sin(_t * 7.0))
	# пар из труб на спине (в перегреве — искры и огонь)
	_vent_t -= delta
	if _vent_t <= 0.0:
		_vent_t = 0.35 if _phase < 2 else 0.18
		var at := p.global_position + Vector2(-p.facing * bs.x * 0.38, -bs.y * 0.42)
		var c := Color(0.75, 0.75, 0.78, 0.8) if _phase < 2 else Color(1.0, 0.55, 0.2, 0.9)
		Fx.sparks(p.get_parent(), at, c, 3 if _phase < 2 else 5, 120.0, 6.0, true)
	# тяжёлые шаги: земля трескается
	if p.is_on_floor() and absf(p.velocity.x) > 30.0:
		_step_t -= delta
		if _step_t <= 0.0:
			_step_t = 0.6
			var feet := p.global_position + Vector2(p.facing * bs.x * 0.2, bs.y / 2)
			Fx.sparks(p.get_parent(), feet, Color(0.65, 0.55, 0.42), 5, 140.0, 4.0, true)
			Fx.cracks(p.get_parent(), feet, Color(0.3, 0.24, 0.2), 40.0)
	# огромный Колосс не перепрыгивает препятствия — он их сносит
	_crush_t -= delta
	if _crush_t <= 0.0:
		_crush_t = 0.25
		_crush()
	# фазы
	var ratio := float(p.hp) / p.max_hp
	var want := 0
	if ratio < 0.67:
		want = 1
	if ratio < 0.34:
		want = 2
	if want > _phase:
		_phase = want
		_enter_phase()

func _crush() -> void:
	var dirx := signf(p.velocity.x) if absf(p.velocity.x) > 5.0 else float(p.facing)
	if is_instance_valid(p.target) and absf(p.velocity.x) <= 5.0:
		dirx = signf(p.target.global_position.x - p.global_position.x)
	var space := p.get_world_2d().direct_space_state
	var bs := p.body_size
	for fy in [0.42, 0.15, -0.15, -0.4]:
		var from := p.global_position + Vector2(0, bs.y * fy)
		var q := PhysicsRayQueryParameters2D.create(from, from + Vector2(dirx * (bs.x / 2 + 40.0), 0), Layer.WORLD, [p.get_rid()])
		var hit := space.intersect_ray(q)
		if not hit.is_empty() and hit["collider"] is Destructible and not hit["collider"].background and not hit["collider"].one_way:
			hit["collider"].hit(hit["position"] + Vector2(dirx * 10.0, 0), Vector2(dirx, 0), 90, 46.0, p.team,
					{"strict": true, "radial": true, "origin": hit["position"], "attacker": p})
			Fx.sparks(p.get_parent(), hit["position"], Color(0.7, 0.62, 0.5), 6, 200.0, 4.0)

func _enter_phase() -> void:
	var world := p.get_parent()
	for ab in p.bot_abilities.keys():
		p.bot_abilities[ab] = p.bot_abilities[ab] * 0.8      # способности чаще
	p.speed *= 1.15
	if p.rig:
		p.rig.play("roar")
	Fx.ring(world, p.global_position, 260.0, Color(1.0, 0.35, 0.2, 0.85), 0.6, 9.0)
	var am := p.get_tree().get_first_node_in_group("arena_mode")
	if _phase == 1:
		_banner(am, "Колосс в ярости!")
		if p.summon.is_valid():
			p.summon.call("fighter", 2, p.global_position)
	else:
		# перегрев: броня раскалилась и стала мягче, спина — ещё уязвимее
		_banner(am, "Колосс раскалился! Броня слабеет")
		p.front_armor = 0.6
		p.back_mult = 1.5
		p.set_tint(Color(1.25, 0.82, 0.75))
		if p.summon.is_valid():
			p.summon.call("fighter", 2, p.global_position)

# ========== Вторая фаза: «Колосс Пробуждённый» ==========
func _on_lethal() -> bool:
	if _awake or _waking:
		return false
	_waking = true
	p.hp = 1
	_start_awakening()
	return true

# Сцена пробуждения (~3,6 с): замедление, Колосс падает на колено, по броне бегут
# огненные трещины — и броня разлетается, а небо над Колизеем загорается.
func _start_awakening() -> void:
	var world := p.get_parent()
	var am := p.get_tree().get_first_node_in_group("arena_mode")
	p.cutscene_shield = true
	p.frozen = true
	p.velocity = Vector2.ZERO
	p._forced_time = 0.0
	p.stagger = 0.0
	p._stun_t = 0.0                          # не «оглушён», а повержен
	if p._stun_fx:
		p._stun_fx.visible = false
	_whirl_t = 0.0
	if _disc:
		_disc.queue_free()
		_disc = null
	# бойцы, которых он звал, разбегаются
	if am:
		for b in am._alive.duplicate():
			if is_instance_valid(b) and b != p and b.is_alive():
				Fx.sparks(world, b.global_position, Color(0.8, 0.7, 0.5), 8, 200.0, 4.0)
				b.take_damage(99999)
	# замедление времени на миг
	Engine.time_scale = 0.3
	p.get_tree().create_timer(0.8, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)
	Util.flash(world, p.global_position, 260.0, Color(1.0, 0.9, 0.7, 0.9))
	Fx.shake(world, 8.0)
	if am:
		am.cinematic(p, 4.3)                    # камера смотрит на Колосса, герои ждут
	_banner(am, "Колосс повержен…")
	if p.rig:
		p.rig.play("roar")
	if p._rig_root:
		_rig_y = p._rig_root.position.y
		var kt := p._rig_root.create_tween()
		kt.tween_property(p._rig_root, "rotation", -0.14 * p.facing, 0.7).set_trans(Tween.TRANS_SINE)
		kt.parallel().tween_property(p._rig_root, "position:y", _rig_y + 22.0, 0.7)
	p._after(1.2, _glow_cracks)
	p._after(2.0, func(): _banner(am, "…но в груди у него горит огонь!"))
	p._after(3.0, _armor_burst)
	p._after(3.6, _begin_phase2)

func _glow_cracks() -> void:
	if not is_instance_valid(p):
		return
	var bs := p.body_size
	_cracks = Node2D.new()
	_cracks.z_index = 4
	for k in 7:
		var l := Line2D.new()
		var x0 := randf_range(-bs.x * 0.35, bs.x * 0.35)
		var y0 := randf_range(-bs.y * 0.4, bs.y * 0.3)
		var pts := PackedVector2Array([Vector2(x0, y0)])
		for i in 3:
			pts.append(pts[pts.size() - 1] + Vector2(randf_range(-16, 16), randf_range(10, 22)))
		l.points = pts
		l.width = 3.0
		l.default_color = Color(1.0, 0.6, 0.2, 0.0)
		_cracks.add_child(l)
		l.create_tween().tween_property(l, "default_color:a", 0.95, 0.4).set_delay(k * 0.1)
	p.add_child(_cracks)
	Fx.shake(p.get_parent(), 5.0)
	Fx.sparks(p.get_parent(), p.global_position, Color(1.0, 0.6, 0.2), 14, 220.0, 4.0)

func _armor_burst() -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	var am := p.get_tree().get_first_node_in_group("arena_mode")
	var c := p.global_position
	Fx.shake(world, 14.0)
	Util.flash(world, c, 340.0, Color(1.0, 0.7, 0.3, 0.95))
	Fx.ring(world, c, 440.0, Color(1.0, 0.5, 0.2, 0.95), 0.6, 12.0)
	Fx.ring(world, c, 260.0, Color(1.0, 0.85, 0.5, 0.9), 0.45, 8.0)
	Fx.sparks(world, c, Color(1.0, 0.6, 0.2), 40, 520.0, 7.0)
	# куски брони разлетаются
	for k in 12:
		var pl := Polygon2D.new()
		var w := randf_range(10, 22)
		pl.polygon = PackedVector2Array([Vector2(-w, -6), Vector2(w, -8), Vector2(w * 0.8, 7), Vector2(-w * 0.7, 8)])
		pl.color = Color(0.26, 0.20, 0.32) if k % 3 else Color(0.36, 0.30, 0.40)
		pl.position = c + Vector2(randf_range(-40, 40), randf_range(-80, 40))
		pl.z_index = 5
		world.add_child(pl)
		var dir := Vector2.from_angle(randf_range(-PI, 0.0))
		var t := pl.create_tween()
		t.set_parallel(true)
		t.tween_property(pl, "position", pl.position + dir * randf_range(220, 460) + Vector2(0, 260), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		t.tween_property(pl, "rotation", randf_range(-8.0, 8.0), 1.1)
		t.tween_property(pl, "modulate:a", 0.0, 0.5).set_delay(0.7)
		t.chain().tween_callback(pl.queue_free)
	# героев рядом отбрасывает волной (без урона)
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive() and n.global_position.distance_to(c) < 440.0:
			n.velocity = Vector2(signf(n.global_position.x - c.x + 0.01) * 720.0, -460.0)
	# небо загорается
	_sky = InfernoSky.new()
	_sky.boss = p
	_sky.map_w = p.map_w
	_sky.floor_y = am.info["floor"] if am else p.global_position.y + p.body_size.y / 2
	_sky.glow = am.info.get("glow") if am else null
	world.add_child(_sky)

func _begin_phase2() -> void:
	Engine.time_scale = 1.0
	if not is_instance_valid(p):
		return
	var am := p.get_tree().get_first_node_in_group("arena_mode")
	var t: Dictionary = Bots.TYPES["colossus"]
	var factor := float(p.max_hp) / float(t["hp"])          # волна и игра вдвоём
	var share := p.stagger_max / float(maxi(p.max_hp, 1))
	p.max_hp = int(t["phase2_hp"] * factor)
	p.stagger_max = p.max_hp * share
	p.stagger = 0.0
	var ht := p.create_tween()                                # полоска здоровья заполняется заново
	ht.tween_method(func(v: float):
		if is_instance_valid(p) and p.is_alive():
			p.hp = maxi(p.hp, int(v)), 1.0, float(p.max_hp), 1.0)
	p.front_armor = 0.0
	p.back_mult = 1.0
	p.speed = float(t["speed"]) * 1.5
	p.set_tint(Color(1.35, 0.86, 0.72))
	p.set_meta("title", t["phase2_name"])
	p.bot_abilities = {"fire_dash": 7.0, "meteor_leap": 11.0, "lava_volley": 6.0, "core_nova": 19.0, "shockwave": 10.0}
	p._bot_cd = {}
	if p._rig_root:
		var kt := p._rig_root.create_tween()
		kt.tween_property(p._rig_root, "rotation", 0.0, 0.3)
		kt.parallel().tween_property(p._rig_root, "position:y", _rig_y, 0.3)
	if p.rig:
		p.rig.play("roar")
	_awake = true
	_waking = false
	p.frozen = false
	p.cutscene_shield = false
	if am:
		am._name_card("colossus", t["phase2_name"], "ВТОРАЯ ФАЗА")
		var hint: String = t["hint2"]
		am._after(2.6, am.hud.show_hint.bind(hint, 10.0))

func _colossus_awake(delta: float) -> void:
	var bs := p.body_size
	var world := p.get_parent()
	_eye.position = Vector2(p.facing * bs.x * 0.2, -bs.y * 0.36)
	_eye.color = Color(1.0, 0.55, 0.15, 0.7 + 0.25 * sin(_t * 8.0))
	_core.position = Vector2(p.facing * bs.x * 0.05, -bs.y * 0.12)
	var nova_k := 1.0 - _nova_t / NOVA_T if _nova_t > 0.0 else 0.0
	_core.scale = Vector2.ONE * (1.0 + 0.15 * sin(_t * 6.0) + nova_k * 1.6)
	_core.color = Color(1.0, 0.55 + 0.25 * sin(_t * 9.0), 0.15, 0.75 if not p.is_stunned() else 0.25)
	if _cracks:
		_cracks.modulate.a = 0.75 + 0.25 * sin(_t * 7.0)
	# искры с раскалённого тела
	_ember_t -= delta
	if _ember_t <= 0.0:
		_ember_t = 0.1
		Fx.sparks(world, p.global_position + Vector2(randf_range(-bs.x * 0.4, bs.x * 0.4), randf_range(-bs.y * 0.4, bs.y * 0.3)),
				Color(1.0, 0.55, 0.15), 2, 90.0, 3.0, true)
	_crush_t -= delta
	if _crush_t <= 0.0:
		_crush_t = 0.25
		_crush()
	if _dash_t > 0.0:
		_dash_tick(delta)
	if _leap != "":
		_leap_tick(delta)
	if _nova_t > 0.0:
		_nova_tick(delta)

# ----- Огненный рывок: линия на земле, потом таран через поле, за ним горит земля -----
func start_dash(dir: float) -> void:
	var world := p.get_parent()
	_dash_dir = dir
	p._anim("windup")
	p._forced_time = 0.7
	p._forced_vx = 0.0
	p.facing = int(dir)
	var fy := p.global_position.y + p.body_size.y * 0.2
	var end_x := clampf(p.global_position.x + dir * 1400.0, 80.0, p.map_w - 80.0)
	LightBeam.aim_line(world, Vector2(p.global_position.x, fy), Vector2(end_x, fy), Color(1.0, 0.4, 0.1), 0.7)
	Fx.sparks(world, p.global_position + Vector2(-dir * 30.0, p.body_size.y / 2 - 6), Color(1.0, 0.55, 0.2), 10, 160.0, 4.0, true)
	p._after(0.7, func():
		if not is_instance_valid(p) or not p.is_alive() or p.is_stunned():
			return
		_dash_t = 0.85
		_dash_hit.clear()
		_trail_x = p.global_position.x
		p._forced_time = 0.85
		p._forced_vx = _dash_dir * 1450.0
		Fx.ring(world, p.global_position, 120.0, Color(1.0, 0.5, 0.2, 0.9), 0.3, 6.0))

func _dash_tick(delta: float) -> void:
	_dash_t -= delta
	var world := p.get_parent()
	var bs := p.body_size
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive() and not _dash_hit.has(n):
			var dd: Vector2 = n.global_position - p.global_position
			if absf(dd.x) < bs.x / 2 + n.body_size.x / 2 + 10.0 and absf(dd.y) < bs.y / 2 + n.body_size.y / 2:
				_dash_hit[n] = true
				n.take_damage(22, p)
				n.velocity = Vector2(_dash_dir * 650.0, -520.0)
				n.burn(2.0, 5.0, p)
	# за Колоссом горит земля
	var feet_y := p.global_position.y + bs.y / 2
	if absf(p.global_position.x - _trail_x) > 120.0:
		_trail_x = p.global_position.x
		var fz := FireZone.new()
		fz.team = p.team
		fz.attacker = p
		fz._life = 3.0
		fz.position = Vector2(p.global_position.x - _dash_dir * bs.x * 0.4, feet_y - 6.0)
		world.add_child(fz)
	if is_on_wall_ahead():
		_dash_t = 0.0
	if _dash_t <= 0.0:
		_dash_t = 0.0
		p._forced_time = 0.35
		p._forced_vx = 0.0
		Fx.shake(world, 6.0)
		Fx.sparks(world, p.global_position + Vector2(_dash_dir * bs.x / 2, bs.y / 2 - 10), Color(0.8, 0.6, 0.4), 12, 240.0, 4.0, true)

func is_on_wall_ahead() -> bool:
	return p.global_position.x < 120.0 + p.body_size.x / 2 or p.global_position.x > p.map_w - 120.0 - p.body_size.x / 2

# ----- Прыжок-метеор: взмывает за край экрана, тень ищет героя, падает огненным ударом -----
func start_leap() -> void:
	_leap = "crouch"
	_leap_t = 0.4
	p._anim("stomp")
	p._forced_time = 0.5
	p._forced_vx = 0.0
	_leap_ground = p.global_position.y

func _leap_tick(delta: float) -> void:
	var world := p.get_parent()
	_leap_t -= delta
	match _leap:
		"crouch":
			if _leap_t <= 0.0:
				_leap = "up"
				_leap_t = 0.45
				p.cutscene_shield = true          # в небе его не достать
				p.set_physics_process(false)
				Fx.ring(world, Vector2(p.global_position.x, _leap_ground + p.body_size.y / 2), 160.0, Color(1.0, 0.6, 0.3, 0.9), 0.4, 7.0, 0.3)
				Fx.sparks(world, Vector2(p.global_position.x, _leap_ground + p.body_size.y / 2), Color(0.8, 0.65, 0.45), 16, 260.0, 5.0, true)
				var t := p.create_tween()
				t.tween_property(p, "global_position:y", _leap_ground - 1100.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
				# тень на земле
				_shadow = Node2D.new()
				_shadow.z_index = 3
				var sh := Polygon2D.new()
				var pts := Util.circle(p.body_size.x * 0.7, 24)
				for i in pts.size():
					pts[i].y *= 0.22
				sh.polygon = pts
				sh.color = Color(0.0, 0.0, 0.0, 0.45)
				_shadow.add_child(sh)
				var ring := Line2D.new()
				var rp := pts.duplicate()
				rp.append(rp[0])
				ring.points = rp
				ring.width = 3.0
				ring.default_color = Color(1.0, 0.45, 0.15, 0.0)
				ring.name = "Ring"
				_shadow.add_child(ring)
				_shadow.position = Vector2(p.global_position.x, _leap_ground + p.body_size.y / 2)
				_shadow.scale = Vector2(0.3, 0.3)
				world.add_child(_shadow)
				_shadow.create_tween().tween_property(_shadow, "scale", Vector2.ONE, 1.2)
		"up":
			if _leap_t <= 0.0:
				_leap = "track"
				_leap_t = 1.3
		"track":
			if is_instance_valid(p.target) and is_instance_valid(_shadow):
				var tx := clampf(p.target.global_position.x, 120.0 + p.body_size.x / 2, p.map_w - 120.0 - p.body_size.x / 2)
				_shadow.position.x = move_toward(_shadow.position.x, tx, 850.0 * delta)
			if _leap_t <= 0.0:
				_leap = "lock"
				_leap_t = 0.5
				if is_instance_valid(_shadow):
					var ring: Line2D = _shadow.get_node("Ring")
					ring.default_color.a = 0.95
		"lock":
			if is_instance_valid(_shadow):
				var ring2: Line2D = _shadow.get_node("Ring")
				ring2.width = 3.0 + 2.0 * absf(sin(_t * 18.0))
			if _leap_t <= 0.0:
				_leap = "fall"
				_leap_t = 0.22
				var x: float = _shadow.position.x if is_instance_valid(_shadow) else p.global_position.x
				p.global_position = Vector2(x, _leap_ground - 1100.0)
				var t2 := p.create_tween()
				t2.tween_property(p, "global_position:y", _leap_ground, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		"fall":
			if _leap_t <= 0.0:
				_leap = ""
				_land()

func _land() -> void:
	var world := p.get_parent()
	p.global_position.y = _leap_ground
	p.set_physics_process(true)
	p.cutscene_shield = false
	p.velocity = Vector2.ZERO
	p._forced_time = 0.7                              # приходит в себя после удара
	p._forced_vx = 0.0
	if is_instance_valid(_shadow):
		_shadow.queue_free()
	var feet := Vector2(p.global_position.x, _leap_ground + p.body_size.y / 2)
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive():
			var dd: Vector2 = n.global_position - feet
			if absf(dd.x) < 190.0 and dd.y > -260.0 and dd.y < 40.0:
				n.take_damage(30, p)
				n.velocity = Vector2(signf(dd.x + 0.01) * 600.0, -480.0)
	Util.explode(world, feet + Vector2(0, -20), 150.0, 0, 50, p.team, p, true)
	Fx.ring(world, feet, 220.0, Color(1.0, 0.5, 0.2, 0.95), 0.45, 10.0, 0.3)
	Fx.cracks(world, feet, Color(0.25, 0.12, 0.08), 180.0)
	Fx.sparks(world, feet + Vector2(0, -8), Color(1.0, 0.6, 0.2), 30, 420.0, 6.0, true)
	Fx.shake(world, 14.0)
	# столбы пламени расходятся в обе стороны — перепрыгивай!
	for side in [-1.0, 1.0]:
		for k in 8:
			p._after(0.12 + k * 0.08, _fire_pillar.bind(feet.x + side * (210.0 + k * 100.0), feet.y))

func _fire_pillar(x: float, fy: float) -> void:
	if not is_instance_valid(p) or x < 70.0 or x > p.map_w - 70.0:
		return
	var world := p.get_parent()
	var col := Node2D.new()
	col.position = Vector2(x, fy)
	col.z_index = 4
	var outer := Polygon2D.new()
	outer.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(-16, -90), Vector2(-4, -150), Vector2(6, -140), Vector2(18, -86), Vector2(26, 0)])
	outer.color = Color(1.0, 0.42, 0.1, 0.9)
	col.add_child(outer)
	var inner := Polygon2D.new()
	inner.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(-6, -80), Vector2(2, -110), Vector2(10, -70), Vector2(12, 0)])
	inner.color = Color(1.0, 0.88, 0.45, 0.95)
	col.add_child(inner)
	col.scale = Vector2(0.7, 0.05)
	world.add_child(col)
	var t := col.create_tween()
	t.tween_property(col, "scale", Vector2(1.0, 1.0), 0.1).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t.tween_property(col, "scale", Vector2(0.5, 0.0), 0.3).set_delay(0.12)
	t.tween_callback(col.queue_free)
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive():
			var feet_n: float = n.global_position.y + n.body_size.y / 2
			if absf(n.global_position.x - x) < 30.0 + n.body_size.x / 2 and absf(feet_n - fy) < 24.0:
				n.take_damage(14, p)
				n.velocity.y = -560.0
				n.burn(1.5, 5.0, p)

# ----- Сверхновая: ядро разгорается 2,4 с (тянет героев к себе), взрыв — и Колосс выдыхается -----
func start_nova() -> void:
	var world := p.get_parent()
	_nova_t = NOVA_T
	p._anim("roar")
	p._forced_time = NOVA_T + 0.2
	p._forced_vx = 0.0
	p._float_label("Сверхновая!", Color(1.0, 0.6, 0.2))
	_nova_fx = Node2D.new()
	_nova_fx.z_index = 4
	var ring := Line2D.new()
	var pts := Util.circle(NOVA_R, 48)
	pts.append(pts[0])
	ring.points = pts
	ring.width = 4.0
	ring.default_color = Color(1.0, 0.35, 0.1, 0.85)
	_nova_fx.add_child(ring)
	var fill := Polygon2D.new()
	fill.polygon = Util.circle(NOVA_R, 48)
	fill.color = Color(1.0, 0.4, 0.1, 0.12)
	fill.name = "Fill"
	fill.scale = Vector2(0.05, 0.05)
	_nova_fx.add_child(fill)
	_nova_fx.position = p.global_position
	world.add_child(_nova_fx)

func _nova_tick(delta: float) -> void:
	var world := p.get_parent()
	_nova_t -= delta
	if p.is_stunned():                                 # оглушили во время зарядки — сорвалась
		_nova_t = 0.0
		if is_instance_valid(_nova_fx):
			_nova_fx.queue_free()
		return
	if is_instance_valid(_nova_fx):
		_nova_fx.position = p.global_position
		var fill: Polygon2D = _nova_fx.get_node("Fill")
		fill.scale = Vector2.ONE * (1.0 - _nova_t / NOVA_T)
		fill.color.a = 0.12 + 0.15 * absf(sin(_t * 10.0))
	# ядро тянет героев к себе
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive() and not n.is_minion:
			var dx: float = p.global_position.x - n.global_position.x
			if absf(dx) < 900.0:
				n.global_position.x += signf(dx) * 110.0 * delta
	if fmod(_nova_t, 0.15) < delta:
		Fx.sparks(world, p.global_position + Vector2.from_angle(randf() * TAU) * 220.0, Color(1.0, 0.6, 0.2), 3, 60.0, 3.0)
	if _nova_t <= 0.0:
		_nova_t = 0.0
		_nova_boom()

func _nova_boom() -> void:
	var world := p.get_parent()
	var c := p.global_position
	if is_instance_valid(_nova_fx):
		_nova_fx.queue_free()
	for n in world.get_children():
		if n is Player and n.team != p.team and n.is_alive() and n.hurt_center().distance_to(c) < NOVA_R:
			n.take_damage(34, p)
			n.velocity = Vector2(signf(n.global_position.x - c.x + 0.01) * 820.0, -480.0)
	Util.explode(world, c, NOVA_R * 0.8, 0, 40, p.team, p, true)
	Util.flash(world, c, NOVA_R, Color(1.0, 0.75, 0.4, 0.95))
	Fx.ring(world, c, NOVA_R, Color(1.0, 0.55, 0.2, 0.95), 0.5, 12.0)
	Fx.ring(world, c, NOVA_R * 0.6, Color(1.0, 0.9, 0.6, 0.9), 0.35, 8.0)
	Fx.sparks(world, c, Color(1.0, 0.6, 0.2), 40, 600.0, 7.0)
	Fx.shake(world, 16.0)
	# выдохся: ядро погасло, урон по нему двойной
	p.stun(3.0)
	p._float_label("Колосс выдохся! урон ×%s" % str(p.stun_mult).trim_suffix(".0"), Color(1.0, 0.85, 0.3))

func _banner(am, text: String) -> void:
	if am and am.hud:
		am.hud.show_banner(text, Color(1.0, 0.45, 0.3))
		am._after(1.6, am.hud.hide_banner)

# ---------- Ведьма: стая воронов ----------
func start_blink() -> void:
	_begin_hide("blink", 0.9)
	var world := p.get_parent()
	for k in 8:
		Fx.sparks(world, p.global_position + Vector2(randf_range(-30, 30), randf_range(-50, 30)), Color(0.08, 0.08, 0.1), 3, 260.0, 6.0, true)
	# появится подальше от героя, но на арене
	var tx: float = p.target.global_position.x if is_instance_valid(p.target) else p.global_position.x
	var side := -1.0 if tx > Colosseum.W / 2 else 1.0
	_goal_x = _safe_x(tx + side * randf_range(450.0, 700.0))

# ---------- Трясинный Владыка: под трясиной ----------
func start_submerge() -> void:
	_begin_hide("submerge", 1.6)
	_goal_x = _safe_x(p.target.global_position.x if _good_target() else p.global_position.x)
	var world := p.get_parent()
	Fx.ring(world, Vector2(p.global_position.x, _floor_y), 150.0, Color(0.35, 0.4, 0.2, 0.9), 0.5, 7.0, 0.3)
	Fx.sparks(world, Vector2(p.global_position.x, _floor_y - 6), Color(0.3, 0.32, 0.18), 16, 260.0, 6.0, true)

# Куда можно вынырнуть/появиться: не в стене и не за краем арены
func _safe_x(x: float) -> float:
	var m := Colosseum.WALL + p.body_size.x / 2 + 20.0
	var w: float = p.map_w if p.map_w > 0.0 else Colosseum.W
	if x != x:                                   # NaN — на всякий случай
		x = p.global_position.x
	return clampf(x, m, w - m)

# Цель, за которой можно нырять: живой герой (не приманка и не призванный)
func _good_target() -> bool:
	var t = p.target
	return is_instance_valid(t) and t.is_alive() and t.visible and not t.is_minion and not t.has_meta("decoy")

func _begin_hide(kind_h: String, time: float) -> void:
	_hide_kind = kind_h
	_hide_t = time
	_floor_y = p.global_position.y + p.body_size.y / 2
	p.cutscene_shield = true
	p.visible = false
	p.frozen = true
	p.velocity = Vector2.ZERO
	p._col.set_deferred("disabled", true)
	p.set_physics_process(false)

func _hidden_tick(delta: float) -> void:
	_hide_t -= delta
	var world := p.get_parent()
	if _hide_kind == "submerge":
		if _good_target() and _hide_t > 0.5:
			_goal_x = _safe_x(move_toward(_goal_x, p.target.global_position.x, 420.0 * delta))
		p.global_position.x = move_toward(p.global_position.x, _goal_x, 700.0 * delta)
		if fmod(_hide_t, 0.12) < delta:
			Fx.sparks(world, Vector2(p.global_position.x, _floor_y - 4), Color(0.4, 0.45, 0.25), 3, 120.0, 5.0, true)
		if _hide_t < 0.5 and fmod(_hide_t, 0.15) < delta:
			Fx.ring(world, Vector2(_goal_x, _floor_y), 120.0, Color(0.6, 0.9, 0.3, 0.7), 0.2, 4.0, 0.3)
	else:
		p.global_position.x = move_toward(p.global_position.x, _goal_x, 1600.0 * delta)
		if fmod(_hide_t, 0.06) < delta:
			Fx.sparks(world, p.global_position + Vector2(randf_range(-50, 50), randf_range(-60, 20)), Color(0.08, 0.08, 0.1), 2, 200.0, 5.0)
	if _hide_t <= 0.0:
		_unhide()

func _unhide() -> void:
	var world := p.get_parent()
	var hk := _hide_kind
	_hide_kind = ""
	_hide_t = 0.0
	_goal_x = _safe_x(_goal_x)
	p.global_position = Vector2(_goal_x, _floor_y - p.body_size.y / 2 - 2.0)
	p.velocity = Vector2.ZERO
	p.visible = true
	p.frozen = false
	p.cutscene_shield = false
	p._col.set_deferred("disabled", false)
	p.set_physics_process(true)
	if p.rig:
		p.rig.play("roar")
	if hk == "submerge":
		var at := Vector2(_goal_x, _floor_y)
		Util.explode(world, at, 150.0, 28, 40, p.team, p)
		for n in world.get_children():
			if n is Player and n.team != p.team and n.is_alive() and absf(n.global_position.x - _goal_x) < 150.0:
				n.velocity = Vector2(signf(n.global_position.x - _goal_x) * 320.0, -720.0)
		Fx.ring(world, at, 170.0, Color(0.45, 0.5, 0.25, 0.9), 0.4, 8.0, 0.35)
		var pud := SwampBits.MudPuddle.new()
		pud.width = 200.0
		pud.life = 5.0
		pud.position = at
		world.add_child(pud)
	else:
		for k in 10:
			Fx.sparks(world, p.global_position + Vector2(randf_range(-40, 40), randf_range(-60, 30)), Color(0.08, 0.08, 0.1), 3, 240.0, 6.0)
		Fx.ring(world, p.global_position, 90.0, Color(0.6, 0.3, 0.9, 0.8), 0.3, 5.0)
