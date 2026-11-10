class_name ZarnitsaKit
extends HeroKit
# ---------- ЗАРНИЦА — легенда за Громовника (70-я волна Арены) ----------
# Послушница Храма шторма с боевым веером.
# Оружие «Искра»: взмахом веера пускает быстрые искры. Каждое 3-е попадание
#   перескакивает молнией на ближайшего соседнего врага.
# «Планирование»: зажми прыжок в воздухе — веер раскрывается над головой,
#   Зарница медленно парит.
# 1 «Порыв» — волна ветра вперёд: отбрасывает врагов и сдувает вражеские снаряды.
#   МЕГА: ещё и стена ветра на 4 с — чужие снаряды отлетают обратно во врагов.
#   Арена: волна шире и сбивает врагов с ног.
# 2 «Громоотвод» — втыкает медный громоотвод: 4 с бьёт молнией врагов рядом.
#   МЕГА: молния цепью перескакивает между врагами. Арена: стоит 6 с и бьёт чаще.
# 3 «Вихрь» — рывок в любую сторону (даже в воздухе), позади — след молнии, который
#   ранит врагов. МЕГА: 2 рывка подряд. Арена: след держится дольше.
# Ульта «Око бури» — 5 с молнии бьют по всем врагам на экране, ветер стягивает их
#   к Зарнице. МЕГА: по полю носятся смерчи. Арена: 7 с, молнии чаще.

const SPARK := Color(0.62, 0.80, 1.0)
const BOLT := Color(0.88, 0.94, 1.0)
const GLIDE_FALL := 120.0
const DASH_SPEED := 1550.0
const DASH_T := 0.17
const CHAIN_R := 340.0

var _hits := 0                   # попадания искрами — каждое 3-е перескакивает
var _gliding := false
var _canopy: Node2D              # раскрытый веер над головой при планировании
var _glide_fx := 0.0
# рывок
var _dash_t := 0.0
var _dash_dir := Vector2.RIGHT
var _dash_from := Vector2.ZERO
var _second_t := 0.0             # МЕГА: время, пока можно сделать второй рывок
var _second_used := false
# ульта
var _storm: StormEye

# ---------- Стрельба: искры ----------
func weapon(delta: float, shoot: bool) -> void:
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
	if not shoot or p._cooldown_left > 0.0 or p._reloading > 0.0 or _dash_t > 0.0:
		return
	p.bullet_style = "spark"
	var b := p._shoot_bullet(p.bullet_speed, p.bullet_damage, 0.0, p.bullet_size, randf_range(-0.03, 0.03))
	b.color = SPARK
	b.on_hit = _spark_hit
	if rapid and p.is_mega("rapid"):
		b.pierce = 2
	p._cooldown_left = p.fire_cooldown * (0.5 if rapid else 1.0)
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

func _spark_hit(victim: Node) -> void:
	if not is_instance_valid(p) or not (victim is Player):
		return
	_hits += 1
	if _hits % 3 != 0:
		return
	var world := p.get_parent()
	var from: Vector2 = victim.hurt_center()
	var best: Player = null
	var bd := CHAIN_R
	for e in _enemies():
		if e == victim or e.cutscene_shield:
			continue
		var d: float = e.hurt_center().distance_to(from)
		if d < bd:
			bd = d
			best = e
	Fx.zap(world, from, BOLT, 24.0)
	if best == null:
		return
	Fx.bolt(world, from, best.hurt_center(), BOLT)
	Fx.bolt(world, from, best.hurt_center(), SPARK)
	best.take_damage(int(p.bullet_damage * 1.2), p)
	Fx.zap(world, best.hurt_center(), BOLT, 26.0)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	p._cd[i] = maxf(0.0, p._cd[i] - delta * p._cd_speed())
	if not Input.is_action_just_pressed(action) or _dash_t > 0.0:
		return
	if ab == "storm_dash" and _second_t > 0.0 and not _second_used:
		_second_used = true                 # МЕГА: второй рывок подряд
		_second_t = 0.0
		_dash()
		return
	if p._cd[i] > 0.0:
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"gale":
			_gale(mega)
		"copper_rod":
			_plant_rod(mega)
		"storm_dash":
			_second_used = false
			_second_t = 2.5 if mega else 0.0
			_dash()

# ---------- 1. Порыв ----------
func _gale(mega: bool) -> void:
	var world := p.get_parent()
	var arena := Balance.arena(p)
	p._anim("throw")
	var reach := 470.0 if arena else 380.0
	var half_h := 150.0 if arena else 115.0
	var o := p.global_position
	# волна: несколько изогнутых линий ветра летят вперёд
	var wave := GaleWave.new()
	wave.dir = p.facing
	wave.reach = reach
	wave.half_h = half_h
	wave.position = o + Vector2(p.facing * 30.0, -6.0)
	world.add_child(wave)
	for e in _enemies():
		if e.cutscene_shield:
			continue
		var to: Vector2 = e.hurt_center() - o
		if to.x * p.facing < -20.0 or absf(to.x) > reach + e.body_size.x * 0.4 or absf(to.y) > half_h + e.body_size.y * 0.3:
			continue
		e.take_damage(10, p)
		if GasBubble._is_boss(e):
			e.push_wind(p.facing * 260.0)
		else:
			e.velocity = Vector2(p.facing * 760.0, -340.0)
			e.push_wind(p.facing * 520.0)
			if arena:
				e.stun(0.5)
	# сдувает вражеские снаряды
	for n in world.get_children():
		if not (n is Bullet or n is Spear or n is Arrow or n is Shuriken or n is Shell or n is Grenade):
			continue
		if int(n.get("team")) == p.team:
			continue
		var rel: Vector2 = n.global_position - o
		if rel.x * p.facing < -40.0 or absf(rel.x) > reach + 40.0 or absf(rel.y) > half_h + 40.0:
			continue
		Fx.sparks(world, n.global_position, Color(0.85, 0.92, 1.0), 5, 180.0, 3.0)
		n.queue_free()
	if mega:
		var w := WindWall.new()
		w.team = p.team
		w.owner_p = p
		w.mega = true
		w.life = 4.0
		w.h = 210.0
		w.normal = Vector2(p.facing, 0)
		w.dmg_boost = 1.3 if arena else 1.0
		w.position = o + Vector2(p.facing * 120.0, p.body_size.y / 2 - 105.0)
		world.add_child(w)

# ---------- 2. Громоотвод ----------
func _plant_rod(mega: bool) -> void:
	var world := p.get_parent()
	var arena := Balance.arena(p)
	p._anim("slam")
	var x := clampf(p.global_position.x + p.facing * 70.0, 40.0, p.map_w - 40.0)
	var gy := RaidAbilities._ground_under(p, Vector2(x, p.global_position.y - 20.0))
	var r := CopperRod.new()
	r.team = p.team
	r.attacker = p
	r.mega = mega
	r.life = 6.0 if arena else 4.0
	r.every = 0.38 if arena else 0.5
	r.position = Vector2(x, gy)
	world.add_child(r)

# ---------- 3. Вихрь ----------
func _dash() -> void:
	var d := Vector2(Input.get_axis(p.prefix + "_left", p.prefix + "_right"), 0.0)
	if Input.is_action_pressed(p.prefix + "_jump"):
		d.y -= 1.0
	if Input.is_action_pressed(p.prefix + "_down"):
		d.y += 1.0
	if d.length() < 0.1:
		d = Vector2(p.facing, 0)
	_dash_dir = d.normalized()
	if absf(_dash_dir.x) > 0.01:
		p.facing = 1 if _dash_dir.x > 0 else -1
		p._update_eye()
	_dash_t = DASH_T
	_dash_from = p.global_position
	p._invuln = maxf(p._invuln, DASH_T + 0.1)
	p._forced_time = DASH_T
	p._forced_vx = _dash_dir.x * DASH_SPEED
	p._forced_no_gravity = false
	p.velocity.y = _dash_dir.y * DASH_SPEED
	p._anim("cast")
	Fx.zap(p.get_parent(), p.global_position, BOLT, 30.0)

func _end_dash() -> void:
	_dash_t = 0.0
	p._forced_time = 0.0
	p.velocity.y = _dash_dir.y * 260.0
	var world := p.get_parent()
	var trail := LightningTrail.new()
	trail.team = p.team
	trail.attacker = p
	trail.a = _dash_from
	trail.b = p.global_position
	trail.life = 2.2 if Balance.arena(p) else 1.3
	world.add_child(trail)
	Fx.zap(world, p.global_position, BOLT, 30.0)

# ---------- Ульта: Око бури ----------
func ult() -> void:
	if is_instance_valid(_storm):
		return
	p._anim("cast")
	var s := StormEye.new()
	s.owner_p = p
	s.team = p.team
	s.mega = p._mega_ab()
	s.life = 7.0 if Balance.arena(p) else 5.0
	s.every = 0.36 if Balance.arena(p) else 0.48
	p.get_parent().add_child(s)
	_storm = s

func ulting() -> bool:
	return is_instance_valid(_storm)

# ---------- Каждый кадр ----------
func _physics_process(delta: float) -> void:
	if p == null or not p.is_alive():
		return
	if _second_t > 0.0:
		_second_t -= delta
	if _dash_t > 0.0:
		_dash_t -= delta
		p.velocity.y = _dash_dir.y * DASH_SPEED - p.gravity * delta
		if randf() < 0.7:
			Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-10, 10), randf_range(-20, 20)), SPARK, 1, 80.0, 3.0)
		if _dash_t <= 0.0:
			_end_dash()
	_glide(delta)

# «Планирование»: зажатый прыжок в воздухе — медленное падение
func _glide(delta: float) -> void:
	var want := not p.is_bot and not p.frozen and p._stun_t <= 0.0 and _dash_t <= 0.0 \
			and p._forced_time <= 0.0 and not p.fly_free and not p.is_on_floor() \
			and p.velocity.y > GLIDE_FALL * 0.6 and Input.is_action_pressed(p.prefix + "_jump")
	if want:
		p.velocity.y = minf(p.velocity.y, GLIDE_FALL)
		_glide_fx -= delta
		if _glide_fx <= 0.0:
			_glide_fx = 0.09
			Fx.sparks(p.get_parent(), p.global_position + Vector2(randf_range(-22, 22), -p.body_size.y / 2 - 26.0), Color(0.85, 0.92, 1.0, 0.8), 1, 50.0, 2.5)
	if want != _gliding:
		_gliding = want
		_show_canopy(want)
	if _gliding and is_instance_valid(_canopy):
		_canopy.rotation = sin(Time.get_ticks_msec() * 0.006) * 0.08

func _show_canopy(on: bool) -> void:
	if not is_instance_valid(_canopy):
		_canopy = Node2D.new()
		_canopy.z_index = 3
		var top := -p.body_size.y / 2 - 22.0
		var fan := Polygon2D.new()
		var pts := PackedVector2Array([Vector2(0, top + 18)])
		for i in 13:
			var a := PI + PI * i / 12.0
			pts.append(Vector2(0, top + 18) + Vector2.from_angle(a) * Vector2(46, 34))
		fan.polygon = pts
		fan.color = Color(0.30, 0.42, 0.78, 0.95)
		_canopy.add_child(fan)
		var edge := Line2D.new()
		var ep := PackedVector2Array()
		for i in 13:
			var a := PI + PI * i / 12.0
			ep.append(Vector2(0, top + 18) + Vector2.from_angle(a) * Vector2(46, 34))
		edge.points = ep
		edge.width = 3.0
		edge.default_color = Color(0.95, 0.80, 0.35)
		_canopy.add_child(edge)
		for i in 7:
			var a := PI + PI * (i + 0.5) / 7.0 + 0.0
			var rib := Line2D.new()
			rib.points = PackedVector2Array([Vector2(0, top + 18), Vector2(0, top + 18) + Vector2.from_angle(a) * Vector2(44, 32)])
			rib.width = 1.5
			rib.default_color = Color(0.20, 0.16, 0.20, 0.8)
			_canopy.add_child(rib)
		var zig := Line2D.new()          # молния на веере
		zig.points = PackedVector2Array([Vector2(-8, top - 8), Vector2(2, top + 2), Vector2(-3, top + 4), Vector2(8, top + 14)])
		zig.width = 2.5
		zig.default_color = Color(1.0, 0.92, 0.45)
		_canopy.add_child(zig)
		p.add_child(_canopy)
	_canopy.visible = on

func on_death() -> void:
	super()
	_dash_t = 0.0
	_second_t = 0.0
	_gliding = false
	if is_instance_valid(_canopy):
		_canopy.visible = false
	if is_instance_valid(_storm):
		_storm.finish()


# =====================================================================
# Волна «Порыва»: дуги ветра летят вперёд и тают
class GaleWave extends Node2D:
	var dir := 1
	var reach := 380.0
	var half_h := 115.0
	var _t := 0.0
	var _arcs: Array = []

	func _ready() -> void:
		z_index = 7
		for k in 4:
			var l := Line2D.new()
			var pts := PackedVector2Array()
			var hh := half_h * (1.0 - k * 0.18)
			for i in 9:
				var y := -hh + 2.0 * hh * i / 8.0
				pts.append(Vector2(dir * (cos(y / hh * 1.2) * 34.0), y))
			l.points = pts
			l.width = 5.0 - k
			l.default_color = Color(0.88, 0.94, 1.0, 0.85 - k * 0.15)
			l.position.x = -dir * k * 26.0
			add_child(l)
			_arcs.append(l)

	func _process(delta: float) -> void:
		_t += delta
		var k := _t / 0.32
		position.x += dir * reach / 0.32 * delta
		modulate.a = clampf(1.2 - k, 0.0, 1.0)
		if k >= 1.2:
			queue_free()


# Стена ветра (МЕГА «Порыва»): как зеркало Призмы, только из ветра
class WindWall extends MirrorWall:
	var _lines: Array = []

	func _build_visual() -> void:
		_vis = Node2D.new()
		_vis.z_index = 4
		add_child(_vis)
		var half := h / 2
		var base := Polygon2D.new()
		base.polygon = PackedVector2Array([Vector2(-14, half), Vector2(-10, -half), Vector2(10, -half), Vector2(14, half)])
		base.color = Color(0.75, 0.88, 1.0, 0.22)
		_vis.add_child(base)
		for k in 6:
			var l := Line2D.new()
			var pts := PackedVector2Array()
			for i in 10:
				var y := -half + h * i / 9.0
				pts.append(Vector2(sin(y * 0.05 + k) * 8.0, y))
			l.points = pts
			l.width = 2.5
			l.default_color = Color(0.88, 0.95, 1.0, 0.75)
			_vis.add_child(l)
			_lines.append(l)
		_glint = Polygon2D.new()
		_glint.polygon = PackedVector2Array([Vector2(-10, -6), Vector2(10, -14), Vector2(10, -8), Vector2(-10, 0)])
		_glint.color = Color(1, 1, 1, 0.6)
		_vis.add_child(_glint)

	func _process(delta: float) -> void:
		for k in _lines.size():
			var l: Line2D = _lines[k]
			l.position.x = sin(_t * 9.0 + k * 1.3) * 6.0
			l.position.y = fmod(_t * 220.0 + k * 31.0, 40.0) - 20.0


# Медный громоотвод: бьёт молнией ближайших врагов
class CopperRod extends Node2D:
	var team := 0
	var attacker: Player
	var mega := false
	var life := 4.0
	var every := 0.5
	var _t := 0.0
	var _next := 0.25
	var _glow: Polygon2D
	const R := 270.0
	const H := 96.0

	func _ready() -> void:
		z_index = 3
		var pole := Polygon2D.new()
		pole.polygon = PackedVector2Array([Vector2(-3, 0), Vector2(-2.5, -H), Vector2(2.5, -H), Vector2(3, 0)])
		pole.color = Color(0.78, 0.46, 0.22)
		add_child(pole)
		var shine := Polygon2D.new()
		shine.polygon = PackedVector2Array([Vector2(-1, -2), Vector2(-1, -H + 4), Vector2(0.5, -H + 4), Vector2(0.5, -2)])
		shine.color = Color(1.0, 0.75, 0.45)
		add_child(shine)
		for k in 3:                           # медные кольца
			var ring := Polygon2D.new()
			var y := -20.0 - k * 26.0
			ring.polygon = PackedVector2Array([Vector2(-6, y), Vector2(6, y), Vector2(6, y - 4), Vector2(-6, y - 4)])
			ring.color = Color(0.62, 0.36, 0.18)
			add_child(ring)
		var foot := Polygon2D.new()
		foot.polygon = PackedVector2Array([Vector2(-12, 2), Vector2(-5, -8), Vector2(5, -8), Vector2(12, 2)])
		foot.color = Color(0.42, 0.40, 0.44)
		add_child(foot)
		var tip := Polygon2D.new()
		tip.polygon = PackedVector2Array([Vector2(0, -H - 22), Vector2(4, -H), Vector2(-4, -H)])
		tip.color = Color(0.95, 0.70, 0.40)
		add_child(tip)
		_glow = Polygon2D.new()
		_glow.polygon = Util.circle(12.0, 14)
		_glow.color = Color(0.7, 0.85, 1.0, 0.45)
		_glow.position = Vector2(0, -H - 6)
		add_child(_glow)
		scale = Vector2(1.0, 0.1)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.15).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		Fx.sparks(get_parent(), position, Color(0.9, 0.7, 0.4), 8, 160.0, 3.0, true)
		# зона действия — тонкий круг на земле
		var zone := Fx.rune_circle(get_parent(), position, R, Color(0.6, 0.8, 1.0, 0.55), life, 0.18)
		zone.z_index = 2

	func tip_pos() -> Vector2:
		return global_position + Vector2(0, -H - 14)

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		_glow.scale = Vector2.ONE * (1.0 + 0.25 * sin(_t * 14.0))
		if randf() < 0.25:
			Fx.sparks(get_parent(), tip_pos(), Color(0.8, 0.9, 1.0), 1, 90.0, 2.5)
		_next -= delta
		if _next <= 0.0:
			_next = every
			_strike()
		if life <= 0.0:
			Fx.sparks(get_parent(), tip_pos(), Color(0.9, 0.7, 0.4), 10, 200.0, 3.0)
			queue_free()

	func _foes() -> Array:
		var res := []
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
				res.append(n)
		return res

	func _strike() -> void:
		var world := get_parent()
		var from := tip_pos()
		var best: Player = null
		var bd := R
		for e in _foes():
			var d: float = e.hurt_center().distance_to(global_position + Vector2(0, -H * 0.5))
			if d < bd + e.body_size.x * 0.3:
				bd = d
				best = e
		if best == null:
			return
		var who: Player = attacker if is_instance_valid(attacker) else null
		Fx.bolt(world, from, best.hurt_center(), Color(0.88, 0.94, 1.0))
		Fx.bolt(world, from, best.hurt_center(), Color(0.55, 0.75, 1.0))
		best.take_damage(9, who)
		Fx.zap(world, best.hurt_center(), Color(0.85, 0.92, 1.0), 26.0)
		_glow.color = Color(1, 1, 1, 0.9)
		create_tween().tween_property(_glow, "color", Color(0.7, 0.85, 1.0, 0.45), 0.2)
		if not mega:
			return
		# МЕГА: молния цепью перескакивает дальше
		var hit := {best: true}
		var cur: Player = best
		for j in 3:
			var nxt: Player = null
			var nd := 330.0
			for e in _foes():
				if hit.has(e):
					continue
				var d2: float = e.hurt_center().distance_to(cur.hurt_center())
				if d2 < nd:
					nd = d2
					nxt = e
			if nxt == null:
				break
			Fx.bolt(world, cur.hurt_center(), nxt.hurt_center(), Color(0.85, 0.92, 1.0))
			nxt.take_damage(6, who)
			Fx.zap(world, nxt.hurt_center(), Color(0.85, 0.92, 1.0), 22.0)
			hit[nxt] = true
			cur = nxt


# След молнии после «Вихря»: ранит врагов, которые его касаются
class LightningTrail extends Node2D:
	var team := 0
	var attacker: Player
	var a := Vector2.ZERO
	var b := Vector2.ZERO
	var life := 1.3
	var _t := 0.0
	var _tick := 0.0
	var _lines: Array = []
	var _total := 1.3

	func _ready() -> void:
		z_index = 6
		_total = life
		for k in 2:
			var l := Line2D.new()
			l.width = 6.0 if k == 0 else 2.5
			l.default_color = Color(0.55, 0.75, 1.0, 0.7) if k == 0 else Color(0.95, 0.98, 1.0)
			add_child(l)
			_lines.append(l)
		_rebuild()

	func _rebuild() -> void:
		var pts := PackedVector2Array([a])
		var n := maxi(3, int(a.distance_to(b) / 34.0))
		var side := (b - a).orthogonal().normalized()
		for i in range(1, n):
			pts.append(a.lerp(b, float(i) / n) + side * randf_range(-12.0, 12.0))
		pts.append(b)
		for l in _lines:
			l.points = pts

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		if fmod(_t, 0.08) < delta:
			_rebuild()
		modulate.a = clampf(life / (_total * 0.4), 0.0, 1.0)
		_tick -= delta
		if _tick <= 0.0:
			_tick = 0.35
			var who: Player = attacker if is_instance_valid(attacker) else null
			for n in get_parent().get_children():
				if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
					var c: Vector2 = n.hurt_center()
					var q := Geometry2D.get_closest_point_to_segment(c, a, b)
					if q.distance_to(c) < 26.0 + maxf(n.body_size.x, n.body_size.y) * 0.4:
						n.take_damage(8, who)
						Fx.zap(get_parent(), c, Color(0.85, 0.92, 1.0), 20.0)
		if life <= 0.0:
			queue_free()


# Ульта «Око бури»: тучи над головой, молнии по всем врагам на экране,
# ветер стягивает врагов к Зарнице. МЕГА: смерчи.
class StormEye extends Node2D:
	var owner_p: Player
	var team := 0
	var mega := false
	var life := 5.0
	var every := 0.48
	var _t := 0.0
	var _next := 0.3
	var _swirl: Array = []
	var _dim: ColorRect
	var _done := false
	const VIEW := Vector2(980, 560)

	func _ready() -> void:
		z_index = 8
		# закручивающиеся тучи над Зарницей
		for k in 5:
			var l := Line2D.new()
			var pts := Util.circle(1.0, 24)
			pts.append(pts[0])
			var rr := 70.0 + k * 34.0
			for i in pts.size():
				pts[i] = pts[i] * Vector2(rr, rr * 0.32)
			l.points = pts
			l.width = 7.0 - k
			l.default_color = Color(0.36, 0.42, 0.58, 0.75 - k * 0.1)
			add_child(l)
			_swirl.append(l)
		var eye := Polygon2D.new()
		eye.polygon = Util.circle(26.0, 16)
		eye.scale = Vector2(1.0, 0.4)
		eye.color = Color(0.85, 0.93, 1.0, 0.85)
		add_child(eye)
		_swirl.append(eye)
		scale = Vector2(0.2, 0.2)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.35)
		_place()
		Fx.ring(get_parent(), _p_pos(), 300.0, Color(0.8, 0.9, 1.0, 0.8), 0.5, 8.0)
		if is_instance_valid(owner_p):
			owner_p._float_label("Око бури!", Color(0.75, 0.88, 1.0))
		if mega:
			for d in [-1, 1]:
				var tw := Twister.new()
				tw.team = team
				tw.attacker = owner_p
				tw.dir = -d
				tw.map_w = owner_p.map_w if is_instance_valid(owner_p) else 2600.0
				tw.life = life
				var gx := clampf(_p_pos().x + d * 520.0, 160.0, tw.map_w - 160.0)
				tw.position = Vector2(gx, RaidAbilities._ground_under(owner_p, Vector2(gx, _p_pos().y - 40.0)))
				get_parent().add_child(tw)

	func _p_pos() -> Vector2:
		return owner_p.global_position if is_instance_valid(owner_p) else global_position

	func _place() -> void:
		if is_instance_valid(owner_p):
			global_position = owner_p.global_position + Vector2(0, -owner_p.body_size.y / 2 - 150.0)

	func _foes() -> Array:
		var res := []
		var c := _p_pos()
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
				var d: Vector2 = n.global_position - c
				if absf(d.x) < VIEW.x and absf(d.y) < VIEW.y:
					res.append(n)
		return res

	func _physics_process(delta: float) -> void:
		if _done:
			return
		if not is_instance_valid(owner_p) or not owner_p.is_alive():
			finish()
			return
		_t += delta
		life -= delta
		_place()
		for k in _swirl.size():
			var sw: Node2D = _swirl[k]
			sw.position.x = sin(_t * 3.0 + k) * 6.0
			if sw is Line2D:
				var ln := sw as Line2D
				var cc := ln.default_color
				cc.a = (0.75 - k * 0.1) * (0.8 + 0.2 * sin(_t * 8.0 + k))
				ln.default_color = cc
		# ветер тянет к Зарнице (кроме боссов)
		var c := _p_pos()
		for e in _foes():
			if GasBubble._is_boss(e):
				continue
			var dx: float = c.x - e.global_position.x
			if absf(dx) > 60.0:
				e.push_wind(signf(dx) * 230.0)
		if randf() < 0.4:
			Fx.sparks(get_parent(), c + Vector2(randf_range(-400, 400), randf_range(-200, 40)), Color(0.8, 0.88, 1.0, 0.7), 1, 160.0, 2.5)
		_next -= delta
		if _next <= 0.0:
			_next = every
			var who: Player = owner_p
			for e in _foes():
				var at: Vector2 = e.hurt_center()
				var top := at + Vector2(randf_range(-90, 90), -720.0)
				Fx.bolt(get_parent(), top, at, Color(0.92, 0.96, 1.0))
				Fx.bolt(get_parent(), top, at, Color(0.55, 0.72, 1.0))
				e.take_damage(10, who)
				Fx.zap(get_parent(), at, Color(0.9, 0.95, 1.0), 30.0)
			if not _foes().is_empty():
				Util.flash(get_parent(), global_position, 60.0, Color(0.85, 0.92, 1.0, 0.5))
		if life <= 0.0:
			finish()

	func finish() -> void:
		if _done:
			return
		_done = true
		var t := create_tween()
		t.tween_property(self, "modulate:a", 0.0, 0.4)
		t.tween_callback(queue_free)


# Смерч (МЕГА ульты): носится по полю, подхватывает врагов
class Twister extends Node2D:
	var team := 0
	var attacker: Player
	var dir := 1.0
	var map_w := 2600.0
	var speed := 300.0
	var life := 5.0
	var _rings: Array = []
	var _t := 0.0
	var _tick := {}

	func _ready() -> void:
		z_index = 6
		for k in 8:
			var r := Line2D.new()
			var pts := Util.circle(1.0, 18)
			pts.append(pts[0])
			var rw := 22.0 + k * 8.0
			for i in pts.size():
				pts[i] = pts[i] * Vector2(rw, rw * 0.25)
			r.points = pts
			r.width = 4.0
			r.default_color = Color(0.72, 0.84, 1.0, 0.75 - k * 0.05)
			r.position = Vector2(0, -12.0 - k * 24.0)
			add_child(r)
			_rings.append(r)
		scale = Vector2(0.2, 0.2)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.4)

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		position.x += dir * speed * delta
		if position.x < 140.0 or position.x > map_w - 140.0:
			dir = -dir                                     # отскакивает от края поля
			position.x = clampf(position.x, 140.0, map_w - 140.0)
		for k in _rings.size():
			var r: Line2D = _rings[k]
			r.position.x = sin(_t * 6.0 + k * 0.6) * (4.0 + k * 2.0)
		if randf() < 0.4:
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-30, 30), -randf_range(0, 190)), Color(0.85, 0.92, 1.0), 1, 140.0, 3.0)
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
				var feet: float = n.global_position.y + n.body_size.y / 2
				if absf(n.global_position.x - global_position.x) < 56.0 and feet > global_position.y - 230.0 and feet < global_position.y + 24.0:
					if not GasBubble._is_boss(n):
						n.velocity.y = minf(n.velocity.y, -340.0)
						n.push_wind(dir * 150.0)
					var nt: float = _tick.get(n, 0.0)
					if _t >= nt:
						_tick[n] = _t + 0.45
						n.take_damage(7, attacker if is_instance_valid(attacker) else null)
		if life <= 0.0:
			modulate.a -= delta * 3.0
			if modulate.a <= 0.0:
				queue_free()
