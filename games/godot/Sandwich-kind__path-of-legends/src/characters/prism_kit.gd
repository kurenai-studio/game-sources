class_name PrismKit
extends HeroKit
# ---------- ПРИЗМА — легенда за Ириду (40-я волна Арены) ----------
# Оружие: лучики света — небольшие быстрые снаряды, отскакивают от стен и блоков.
# 1 «Зеркало»     — зеркальная стена отражает чужие снаряды обратно.
#                   МЕГА: стена выше, отражённые снаряды ускоряются и бьют сильнее.
# 2 «Хрустальный столб» — из земли бьёт кристалл: ранит и подбрасывает, потом
#                   стоит преградой несколько секунд и рассыпается.
#                   МЕГА: 5 столбов один за другим — от героя в сторону взгляда.
# 3 «Преломление» — телепорт вперёд; на старом месте остаётся хрустальная
#                   приманка, враги бьют её, а потом она взрывается осколками.
#                   МЕГА: ещё и хрустальная броня — принимает урон на себя,
#                   а когда разбита или время вышло — взрывается осколками.
# Ульта «Радужный луч» — см. weapons/prism_ray.gd. Заряжается долго.

var _ray: PrismRay
var _walls: Array = []
var _hue := 0.0

const LIGHT := [Color(1.0, 0.75, 0.8), Color(1.0, 0.95, 0.7), Color(0.75, 1.0, 0.8), Color(0.75, 0.88, 1.0), Color(0.9, 0.78, 1.0)]
const CRYSTAL := Color(0.58, 0.74, 1.0)
const MAX_WALLS := 2
const WALL_DIST := 200.0

func ulting() -> bool:
	return _ray != null and is_instance_valid(_ray)

# ---------- Стрельба: лучики света ----------
func weapon(delta: float, shoot: bool) -> void:
	if ulting():
		return                                  # во время ульты стрелять нельзя
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
	var b := p._shoot_bullet(p.bullet_speed, p.bullet_damage, 0.0, p.bullet_size, randf_range(-0.03, 0.03))
	_hue = fmod(_hue + 1.0, LIGHT.size())
	b.color = LIGHT[int(_hue)]
	b.restyle("light")
	b.bounces = 2 if rapid and p.is_mega("rapid") else 1
	if rapid and p.is_mega("rapid"):
		b.pierce = 2
	p._cooldown_left = p.fire_cooldown * (0.5 if rapid else 1.0)
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	p._cd[i] = maxf(0.0, p._cd[i] - delta * p._cd_speed())
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	if ulting() and ab != "mirror_wall":
		return                                  # во время ульты — только зеркало
	use(ab)
	p._cd[i] = p.ability_cds[i]

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"mirror_wall":
			_mirror(mega)
		"crystal_pillar":
			p._anim("cast")
			var arena := Balance.arena(p)
			if mega:
				var n := 7 if arena else 5             # Арена: 7 столбов (без МЕГА — 3)
				for k in n:
					_after(0.05 + k * 0.14, _pillar.bind(p.global_position.x + p.facing * (90.0 + k * 95.0), true, p.facing))
			elif arena:
				for k in 3:
					_after(k * 0.16, _pillar.bind(p.global_position.x + p.facing * (170.0 + k * 120.0), false, p.facing))
			else:
				_pillar(p.global_position.x + p.facing * 200.0, false, p.facing)
		"refract":
			_refract(mega)

# ---------- 1. Зеркало ----------
func _mirror(mega: bool) -> void:
	var world := p.get_parent()
	_walls = _walls.filter(func(w): return is_instance_valid(w) and not w._dead)
	while _walls.size() >= MAX_WALLS:
		var old: MirrorWall = _walls.pop_front()
		old.life = 0.0
	p._anim("cast")
	var w := MirrorWall.new()
	w.owner_p = p
	w.team = p.team
	w.mega = mega
	w.h = 230.0 if mega else 160.0
	w.life = 6.0 if mega else 5.0
	if Balance.arena(p):
		w.life += 3.0                          # Арена: зеркало стоит дольше...
		w.dmg_boost = 1.5                      # ...и отражённое бьёт в полтора раза сильнее
	w.normal = Vector2(p.facing, 0)
	var feet := p.global_position.y + p.body_size.y / 2
	# зеркало встаёт подальше — дальше точки, где сходится луч ульты, чтобы луч проходил сквозь него
	w.position = Vector2(clampf(p.global_position.x + p.facing * WALL_DIST, 50.0, p.map_w - 50.0), feet - w.h / 2)
	world.add_child(w)
	_walls.append(w)

# ---------- 2. Хрустальный столб ----------
func _pillar(x: float, mega: bool, dir: int) -> void:
	if not p.is_alive():
		return
	var world := p.get_parent()
	x = clampf(x, 60.0, p.map_w - 60.0)
	var ground := _ground_at(x, p.global_position.y)
	if ground == INF:
		return
	var h := 140.0 if mega else 170.0
	# удар из-под земли: ранит и подбрасывает
	var rs := RootSpike.new()
	rs.team = p.team
	rs.attacker = p
	rs.crystal = true
	rs.damage = 14 if mega else 22
	rs.half = 34.0
	rs.warn = 0.12
	rs.position = Vector2(x, ground)
	world.add_child(rs)
	_after(0.14, _raise_pillar.bind(x, ground, h, 4.5 if mega else 6.0, dir))

func _raise_pillar(x: float, ground: float, h: float, life: float, dir: int) -> void:
	if not is_instance_valid(p):
		return
	var world := p.get_parent()
	var d := Maps.make_destructible(Rect2(x - 20.0, ground - h, 40.0, h), 20.0, CRYSTAL, 40, 30.0)
	d.mat_kind = "crystal"
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	d.set_meta("prism_pillar", true)
	world.add_child(d)
	Shimmer.apply(d, 0.3, 0.6)
	# кто стоял на месте столба — подлетает вверх и в сторону
	for e in _enemies():
		if absf(e.global_position.x - x) < 20.0 + e.body_size.x / 2 and absf(e.global_position.y - (ground - h / 2)) < h / 2 + e.body_size.y / 2:
			e.velocity = Vector2(dir * 320.0, -700.0)
	Fx.sparks(world, Vector2(x, ground), Color(0.7, 0.85, 1.0), 10, 260.0, 3.5, true)
	var t := d.create_tween()
	t.tween_interval(maxf(0.1, life - 0.6))
	t.tween_property(d, "modulate:a", 0.45, 0.6)
	t.tween_callback(_shatter_pillar.bind(d))

func _shatter_pillar(d: Destructible) -> void:
	if not is_instance_valid(d):
		return
	Fx.sparks(d.get_parent(), d.global_position, Color(0.75, 0.88, 1.0), 16, 260.0, 3.5)
	d.queue_free()

# Где земля под точкой (луч вниз от уровня героя, затем от верха карты)
func _ground_at(x: float, from_y: float) -> float:
	var space := p.get_world_2d().direct_space_state
	for y0 in [from_y - 20.0, from_y - 300.0]:
		var ex: Array[RID] = []
		for k in 8:
			var q := PhysicsRayQueryParameters2D.create(Vector2(x, y0), Vector2(x, y0 + 900.0), Layer.WORLD | Layer.FRAME, ex)
			var hit := space.intersect_ray(q)
			if hit.is_empty():
				break
			var c = hit["collider"]
			if c is Destructible and (c.background or c.has_meta("prism_pillar")):
				ex.append(hit["rid"])
				continue
			return hit["position"].y
	return INF

# ---------- 3. Преломление ----------
func _refract(mega: bool) -> void:
	var world := p.get_parent()
	var from := p.global_position
	# приманка остаётся на старом месте
	var dec := _make_decoy(from)
	dec.died.connect(_decoy_burst.bind(dec, mega))
	_after(0.0, _tint_decoy.bind(dec))
	# телепорт вперёд — сквозь врагов, но не в стену
	var to := from + Vector2(p.facing * 340.0, -10.0)
	to.x = clampf(to.x, 60.0, p.map_w - 60.0)
	var space := p.get_world_2d().direct_space_state
	var q := PhysicsRayQueryParameters2D.create(from, to, Layer.FRAME, [p.get_rid()])
	var hit := space.intersect_ray(q)
	if not hit.is_empty():
		to = hit["position"] - Vector2(p.facing * (p.body_size.x / 2 + 6.0), 0)
	p.global_position = to
	p.velocity = Vector2.ZERO
	_push_out()
	p._invuln = maxf(p._invuln, 0.25)
	# след преломлённого света
	for k in 3:
		var l := Line2D.new()
		l.points = PackedVector2Array([from + Vector2(0, (k - 1) * 10.0), p.global_position + Vector2(0, (k - 1) * 10.0)])
		l.width = 5.0
		l.default_color = Color(PrismRay.COLORS[k * 2], 0.7)
		l.z_index = 7
		world.add_child(l)
		var t := l.create_tween()
		t.tween_property(l, "modulate:a", 0.0, 0.35)
		t.tween_callback(l.queue_free)
	Fx.sparks(world, from, Color(0.8, 0.9, 1.0), 10, 220.0, 3.0)
	Fx.ring(world, p.global_position, 55.0, Color(0.9, 0.95, 1.0, 0.9), 0.3, 4.0)
	if mega:
		p.give_crust(60.0, 6.0, true)          # хрустальная броня
	elif Balance.arena(p):
		p.give_crust(30.0, 4.0, true)          # Арена: тонкая хрустальная броня и без МЕГА

func _make_decoy(at: Vector2) -> Player:
	var target := _nearest_enemy()
	var b := Bots.create("crystal_decoy", 1, at, target if target else p, p.map_w)
	b.rig_kind = "prism"                       # хрустальная копия самой Призмы
	b.team = p.team
	b.index = p.index
	b.is_minion = true
	b.minion_owner = p
	b.lifetime = 6.0 if Balance.arena(p) else 4.0       # Арена: приманка держится дольше
	b.team_color = p.team_color
	b.target = target
	b.facing = p.facing
	b.position = at
	b.set_meta("decoy", true)
	b.add_to_group("allies")
	b.add_to_group("decoys")
	Balance.inherit(b, p)
	p.get_parent().add_child(b)
	return b

func _tint_decoy(dec: Player) -> void:
	if is_instance_valid(dec):
		dec.set_tint(Color(0.75, 0.9, 1.35, 0.8))
		if dec._rig_root:
			Shimmer.apply(dec._rig_root, 0.35, 0.7)
			for c in dec._rig_root.get_children():
				if c is CanvasItem:
					Shimmer.apply(c, 0.35, 0.7)

func _decoy_burst(_i: int, dec: Player, mega: bool) -> void:
	if not is_instance_valid(p) or not is_instance_valid(dec):
		return
	var n := 12 if mega else 9
	if Balance.arena(p):
		n += 5                                 # Арена: больше осколков
	Shards.burst(p.get_parent(), dec.global_position, p.team, p, n, 16 if mega else 12, CRYSTAL)
	dec.visible = false

# ---------- Ульта ----------
func ult() -> void:
	if ulting():
		return
	p._anim("cast")
	_ray = PrismRay.new()
	_ray.p = p
	_ray.mega = p._mega_ab()
	if Balance.arena(p):
		_ray.dur = 5.5                         # Арена: луч горит дольше
	p.get_parent().add_child(_ray)
	p.move_mult = 0.35
	Fx.rune_circle(p.get_parent(), p.global_position + Vector2(0, p.body_size.y / 2), 70.0, Color(0.85, 0.8, 1.0, 0.9), 1.1)

func ult_ended() -> void:
	p.move_mult = 1.0
	_ray = null

func on_death() -> void:
	super()
	if ulting():
		_ray.finish()
	_ray = null
	p.move_mult = 1.0
