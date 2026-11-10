class_name BossFx
# ---------- Смерть боссов Арены: у каждого своя ----------
# Когда босс погибает, его модель «отцепляется» от бойца (боец исчезает, как обычно,
# и игра идёт дальше), а модель остаётся на арене и доигрывает свою сцену:
#   Десятник Гнилозуб   — тёмная сила уходит дымом, тело тает в чёрную лужу;
#   Атаман Чёрный Вепрь — падает навзничь, кошель лопается — летят монеты;
#   Вождь гоблинов      — кружится, падает лицом вниз, маска слетает, листья;
#   Древний Энт         — засыхает, сыплются листья, рассыпается трухой — остаётся росток;
#   Паучья королева     — переворачивается на спину, лапки дёргаются;
#   Король скелетов     — рассыпается грудой костей, корона катится по полу;
#   Барон Грызь         — машина чихает дымом, взрывается, барона уносит;
#   Ирида               — рассыпается на кристаллы, они уходят столбом света в небо;
#   Гладиатор           — салютует толпе, падает на колено, сыплются лепестки;
#   Колосс              — ядро взрывается, тело оседает, остаётся столб дыма;
#   Ведьма Полынь       — рассыпается стаей воронов, шляпа падает на землю;
#   Трясинный Владыка   — тонет в трясине, последней скрывается рука;
#   Ётун Стужа          — застывает ледяной статуей и раскалывается, венец катится;
#   Громовник           — молнии рвутся во все стороны, последняя бьёт в него — тает вихрем;
#   Цербер              — три огня гаснут, тело остывает в обсидиан и рассыпается пеплом;
#   Тёмный Лорд         — на колено, меч в пол, доспех трескается светом — пепел уносит вверх.
# У главных боссов (каждые 10 волн) последний удар — с замедлением времени.

# Возвращает узел с моделью — за ним можно навести камеру
static func death(world: Node, b: Player) -> Node2D:
	if not is_instance_valid(b) or b._rig_root == null:
		return null
	var kind: String = b.get_meta("kind", "")
	if b.has_meta("avatar"):
		kind = "dark_avatar"                 # Воплощение Тьмы (третья фаза Лорда) — голова парит
	var c := _corpse(world, b)
	if c == null:
		return null
	var feet := c.position
	var f := float(b.facing)
	var bs := b.body_size
	# Погиб в прыжке или над краем — сначала падает на пол (Ирида и Ведьма парят — остаются в воздухе)
	var gy := _ground_y(c, feet)
	if kind not in ["irida", "witch", "dark_avatar"] and gy > feet.y + 6.0 and gy < feet.y + 2500.0:
		var h := gy - feet.y
		var ft := c.create_tween()
		ft.tween_property(c, "position:y", gy, clampf(sqrt(2.0 * h / 2400.0), 0.12, 0.8)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ft.tween_callback(func():
			if is_instance_valid(world):
				Fx.sparks(world, Vector2(feet.x, gy - 4), Color(0.7, 0.6, 0.45), 10, 180.0, 4.0, true)
				_play(world, c, kind, Vector2(feet.x, gy), f, bs))
		return c
	_play(world, c, kind, feet, f, bs)
	return c

static func _play(world: Node, c: Node2D, kind: String, feet: Vector2, f: float, bs: Vector2) -> void:
	# стоит у края платформы — падает туда, где есть пол, а не в пустоту
	var lie := bs.y * 0.6
	if kind == "ataman":
		if not _supported(c, feet, -f * lie) and _supported(c, feet, f * lie):
			f = -f
	elif kind in ["chief", "gladiator"]:
		if not _supported(c, feet, f * lie) and _supported(c, feet, -f * lie):
			f = -f
	match kind:
		"sergeant": _sergeant(world, c, feet, f, bs)
		"dark_avatar": DarkAvatar.death_fx(world, c, feet, bs)
		"ataman": _ataman(world, c, feet, f, bs)
		"chief": _chief(world, c, feet, f, bs)
		"treant": _treant(world, c, feet, f, bs)
		"spider_queen": _spider(world, c, feet, f, bs)
		"skeleton_king": _king(world, c, feet, f, bs)
		"baron_gryz": _baron(world, c, feet, f, bs)
		"irida": _irida(world, c, feet, f, bs)
		"gladiator": _gladiator(world, c, feet, f, bs)
		"colossus": _colossus(world, c, feet, f, bs)
		"witch": _witch(world, c, feet, f, bs)
		"bog_lord": _bog_lord(world, c, feet, f, bs)
		"jotun": _jotun(world, c, feet, f, bs)
		"storm_lord": _storm_lord(world, c, feet, f, bs)
		"cerberus": _cerberus(world, c, feet, f, bs)
		"dark_lord": _dark_lord(world, c, feet, f, bs)
		_:
			_fade(c, 0.3, 0.8)

# Верх пола (или платформы) под точкой
static func _ground_y(n: Node2D, at: Vector2) -> float:
	var q := PhysicsRayQueryParameters2D.create(at + Vector2(0, -6), at + Vector2(0, 3000))
	q.collision_mask = Layer.WORLD
	var r := n.get_world_2d().direct_space_state.intersect_ray(q)
	return INF if r.is_empty() else float(r["position"].y)

# Есть ли пол на той же высоте в стороне от ног (куда упадёт тело)
static func _supported(n: Node2D, feet: Vector2, dx: float) -> bool:
	return absf(_ground_y(n, feet + Vector2(dx, 0)) - feet.y) < 14.0

# Модель босса переезжает в отдельный узел у его ног и дальше живёт сама
static func _corpse(world: Node, b: Player) -> Node2D:
	var root := b._rig_root
	var c := Node2D.new()
	c.position = b.global_position + Vector2(0, b.body_size.y / 2)
	c.z_index = 2
	world.add_child(c)
	root.reparent(c, true)
	root.position = Vector2.ZERO
	root.visible = true
	var rig = b.rig
	if rig and is_instance_valid(rig):
		if "size" in rig:
			rig.size = b.body_size
		if "puppet_facing" in rig:
			rig.puppet_facing = b.facing
		if "puppet_vx" in rig:
			rig.puppet_vx = 0.0
		if "bot" in rig:
			rig.bot = null
	return c

static func _fade(n: Node2D, delay: float, dur: float) -> void:
	var t := n.create_tween()
	t.tween_interval(delay)
	t.tween_property(n, "modulate:a", 0.0, dur)
	t.tween_callback(n.queue_free)

static func _poly(parent: Node, pts: PackedVector2Array, col: Color, pos := Vector2.ZERO, z := 3) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = pts
	p.color = col
	p.position = pos
	p.z_index = z
	parent.add_child(p)
	return p

# Кусочек, который летит по дуге и падает (монета, кость, шестерёнка, лепесток…)
static func _fling(world: Node, pts: PackedVector2Array, col: Color, from: Vector2, vel: Vector2, ground: float,
		life := 1.6, spin := 6.0) -> void:
	var p := _poly(world, pts, col, from, 4)
	var t := p.create_tween()
	var steps := 18
	var g := 1400.0
	var pos := from
	var v := vel
	var dt := 0.05
	for i in steps:
		v.y += g * dt
		pos += v * dt
		if pos.y > ground:
			pos.y = ground
			v = Vector2(v.x * 0.5, -v.y * 0.3)
		t.tween_property(p, "position", pos, dt)
		t.parallel().tween_property(p, "rotation", p.rotation + spin * dt * (i + 1), dt)
	t.tween_interval(maxf(0.0, life - steps * dt))
	t.tween_property(p, "modulate:a", 0.0, 0.5)
	t.tween_callback(p.queue_free)

static func _smoke(world: Node, at: Vector2, col: Color, n: int, spread: float) -> void:
	for k in n:
		var s := _poly(world, Util.circle(randf_range(10, 22), 10), col, at + Vector2(randf_range(-spread, spread), randf_range(-20, 10)), 5)
		var t := s.create_tween()
		t.set_parallel(true)
		t.tween_property(s, "position", s.position + Vector2(randf_range(-30, 30), -randf_range(80, 160)), 1.4)
		t.tween_property(s, "scale", Vector2(1.8, 1.8), 1.4)
		t.tween_property(s, "modulate:a", 0.0, 1.4)
		t.chain().tween_callback(s.queue_free)

static func _slowmo(world: Node, k: float, real_time: float) -> void:
	Engine.time_scale = k
	world.get_tree().create_timer(real_time, true, false, true).timeout.connect(func(): Engine.time_scale = 1.0)

# ---------- Десятник: тёмная сила уходит, тело тает ----------
static func _sergeant(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var t := c.create_tween()
	t.tween_property(c, "rotation", -0.2 * f, 0.4)
	t.parallel().tween_property(c, "modulate", Color(0.35, 0.25, 0.45), 1.0)
	t.tween_interval(0.4)
	t.tween_property(c, "scale", Vector2(1.5, 0.05), 0.9).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_property(c, "modulate:a", 0.0, 0.6)
	t.tween_callback(c.queue_free)
	for k in 6:
		world.get_tree().create_timer(0.15 + k * 0.22).timeout.connect(func():
			if is_instance_valid(world):
				_smoke(world, feet + Vector2(0, -bs.y * 0.5), Color(0.18, 0.08, 0.25, 0.7), 3, bs.x * 0.4))
	# сгусток тёмной силы улетает к хозяину
	var wisp := _poly(world, Util.circle(10.0, 12), Color(0.55, 0.2, 0.9, 0.9), feet + Vector2(0, -bs.y * 0.6), 6)
	var wt := wisp.create_tween()
	wt.tween_interval(0.9)
	wt.tween_property(wisp, "position", feet + Vector2(-f * 500.0, -700.0), 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	wt.parallel().tween_property(wisp, "scale", Vector2(0.3, 0.3), 1.2)
	wt.tween_callback(wisp.queue_free)
	# чёрная лужа остаётся ненадолго
	var pts := Util.circle(bs.x * 0.8, 20)
	for i in pts.size():
		pts[i].y *= 0.18
	var pud := _poly(world, pts, Color(0.08, 0.04, 0.10, 0.0), feet, 1)
	var pt := pud.create_tween()
	pt.tween_interval(1.1)
	pt.tween_property(pud, "color:a", 0.85, 0.5)
	pt.tween_interval(1.5)
	pt.tween_property(pud, "color:a", 0.0, 1.0)
	pt.tween_callback(pud.queue_free)

# ---------- Атаман: падает навзничь, монеты разлетаются ----------
static func _ataman(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var t := c.create_tween()
	t.tween_property(c, "position", feet + Vector2(-f * 40.0, -20.0), 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.tween_property(c, "position", feet + Vector2(-f * 60.0, 0.0), 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(c, "rotation", -f * 1.45, 0.45).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	t.tween_callback(func():
		if is_instance_valid(world):
			Fx.ring(world, feet + Vector2(-f * 60.0, 0), 110.0, Color(0.75, 0.62, 0.45, 0.8), 0.35, 6.0, 0.3)
			Fx.sparks(world, feet + Vector2(-f * 80.0, -6), Color(0.7, 0.6, 0.45), 12, 200.0, 4.0, true)
			Fx.shake(world, 6.0))
	t.tween_interval(1.6)
	t.tween_property(c, "modulate:a", 0.0, 0.7)
	t.tween_callback(c.queue_free)
	# кошель лопается — монеты!
	var coin := PackedVector2Array([Vector2(-4, 0), Vector2(0, -4), Vector2(4, 0), Vector2(0, 4)])
	for k in 16:
		_fling(world, coin, Color(1.0, 0.82, 0.25), feet + Vector2(0, -bs.y * 0.45),
				Vector2(randf_range(-420, 420), -randf_range(420, 760)), feet.y - 3.0, 2.2, 10.0)

# ---------- Вождь гоблинов: кружится, падает лицом вниз, маска слетает ----------
static func _chief(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var t := c.create_tween()
	t.tween_property(c, "scale:x", -1.0, 0.15)
	t.tween_property(c, "scale:x", 1.0, 0.15)
	t.tween_property(c, "scale:x", -1.0, 0.15)
	t.tween_property(c, "scale:x", 1.0, 0.15)
	t.tween_property(c, "rotation", f * 1.5, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		if is_instance_valid(world):
			Fx.sparks(world, feet + Vector2(f * 60.0, -6), Color(0.35, 0.65, 0.25), 18, 260.0, 4.0, true)
			Fx.shake(world, 5.0))
	t.tween_interval(1.4)
	t.tween_property(c, "modulate:a", 0.0, 0.6)
	t.tween_callback(c.queue_free)
	# маска вождя слетает и катится
	var mask := PackedVector2Array([Vector2(-9, -12), Vector2(9, -12), Vector2(11, 2), Vector2(0, 14), Vector2(-11, 2)])
	world.get_tree().create_timer(0.55).timeout.connect(func():
		if is_instance_valid(world):
			_fling(world, mask, Color(0.62, 0.40, 0.20), feet + Vector2(0, -bs.y * 0.85), Vector2(-f * 260.0, -620.0), feet.y - 10.0, 2.2, 7.0)
			for k in 10:
				_fling(world, PackedVector2Array([Vector2(-5, 0), Vector2(0, -3), Vector2(6, 0), Vector2(0, 3)]),
						Color(0.30, 0.62, 0.24).lightened(randf() * 0.2), feet + Vector2(randf_range(-40, 40), -bs.y * 0.6),
						Vector2(randf_range(-300, 300), -randf_range(300, 600)), feet.y - 2.0, 1.8, 4.0))

# ---------- Древний Энт: засыхает, листья опадают, рассыпается — остаётся росток ----------
static func _treant(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var t := c.create_tween()
	t.tween_property(c, "modulate", Color(0.55, 0.48, 0.38), 1.2)
	t.parallel().tween_property(c, "rotation", 0.08 * f, 1.2)
	t.tween_property(c, "scale", Vector2(1.15, 0.0), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.parallel().tween_property(c, "modulate:a", 0.0, 0.8)
	t.tween_callback(func():
		if is_instance_valid(world):
			Fx.sparks(world, feet + Vector2(0, -10), Color(0.45, 0.33, 0.20), 24, 260.0, 5.0, true)
			Fx.ring(world, feet, 140.0, Color(0.55, 0.45, 0.3, 0.8), 0.4, 6.0, 0.3))
	t.tween_callback(c.queue_free)
	# листья опадают
	for k in 22:
		var col := Color(0.35, 0.62, 0.25) if k % 3 else Color(0.8, 0.7, 0.25)
		var leaf := _poly(world, PackedVector2Array([Vector2(-5, 0), Vector2(0, -3), Vector2(6, 0), Vector2(0, 3)]), col,
				feet + Vector2(randf_range(-bs.x * 0.6, bs.x * 0.6), -bs.y * randf_range(0.6, 1.1)), 5)
		var lt := leaf.create_tween()
		lt.tween_interval(randf_range(0.0, 1.2))
		lt.tween_property(leaf, "position", Vector2(leaf.position.x + randf_range(-60, 60), feet.y - 3), randf_range(1.2, 2.0)).set_trans(Tween.TRANS_SINE)
		lt.parallel().tween_property(leaf, "rotation", randf_range(-6, 6), 1.6)
		lt.tween_property(leaf, "modulate:a", 0.0, 0.6)
		lt.tween_callback(leaf.queue_free)
	# росток — лес жив
	var sprout := _poly(world, PackedVector2Array([Vector2(-3, 0), Vector2(3, 0), Vector2(2, -22), Vector2(12, -30), Vector2(1, -26),
			Vector2(0, -36), Vector2(-1, -26), Vector2(-12, -30), Vector2(-2, -22)]), Color(0.45, 0.85, 0.35), feet, 3)
	sprout.scale = Vector2.ZERO
	var st := sprout.create_tween()
	st.tween_interval(2.2)
	st.tween_property(sprout, "scale", Vector2(1.4, 1.4), 0.6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	st.tween_interval(2.0)
	st.tween_property(sprout, "modulate:a", 0.0, 1.0)
	st.tween_callback(sprout.queue_free)

# ---------- Паучья королева: на спину, лапки дёргаются ----------
static func _spider(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var t := c.create_tween()
	t.tween_property(c, "position:y", feet.y - 90.0, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	t.parallel().tween_property(c, "rotation", PI * f, 0.45)
	t.tween_property(c, "position:y", feet.y - bs.y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		if is_instance_valid(world):
			Fx.sparks(world, feet + Vector2(0, -8), Color(0.45, 0.8, 0.3), 16, 240.0, 4.0, true)
			Fx.shake(world, 5.0))
	for k in 4:                                    # лапки дёргаются
		t.tween_property(c, "scale", Vector2(1.08, 0.92), 0.08)
		t.tween_property(c, "scale", Vector2.ONE, 0.12)
		t.tween_interval(0.12 + k * 0.08)
	t.tween_property(c, "modulate", Color(0.4, 0.4, 0.4, 0.0), 0.8)
	t.tween_callback(c.queue_free)

# ---------- Король скелетов: груда костей, корона катится ----------
static func _king(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var t := c.create_tween()
	for k in 5:                                    # дрожит
		t.tween_property(c, "position:x", feet.x + (6.0 if k % 2 == 0 else -6.0), 0.06)
	t.tween_property(c, "position:x", feet.x, 0.05)
	t.tween_property(c, "scale", Vector2(1.25, 0.12), 0.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		Fx.shake(world, 7.0)
		Fx.sparks(world, feet + Vector2(0, -10), Color(0.92, 0.90, 0.82), 20, 260.0, 4.0, true)
		var bone := PackedVector2Array([Vector2(-10, -2), Vector2(10, -2), Vector2(12, 0), Vector2(10, 2), Vector2(-10, 2), Vector2(-12, 0)])
		for k in 12:
			_fling(world, bone, Color(0.92, 0.90, 0.82), feet + Vector2(randf_range(-30, 30), -30),
					Vector2(randf_range(-380, 380), -randf_range(250, 560)), feet.y - 3.0, 2.4, 8.0)
		# корона катится
		var crown := _poly(world, PackedVector2Array([Vector2(-14, 0), Vector2(-14, -12), Vector2(-7, -5), Vector2(0, -15),
				Vector2(7, -5), Vector2(14, -12), Vector2(14, 0)]), Color(1.0, 0.8, 0.25), feet + Vector2(0, -bs.y * 0.9), 6)
		var ct := crown.create_tween()
		ct.tween_property(crown, "position", feet + Vector2(f * 90.0, -150.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ct.parallel().tween_property(crown, "rotation", 3.0 * f, 0.35)
		ct.tween_property(crown, "position", feet + Vector2(f * 170.0, -2.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ct.parallel().tween_property(crown, "rotation", 6.3 * f, 0.35)
		ct.tween_property(crown, "position:x", feet.x + f * 300.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ct.parallel().tween_property(crown, "rotation", 12.6 * f, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ct.tween_interval(1.6)
		ct.tween_property(crown, "modulate:a", 0.0, 0.6)
		ct.tween_callback(crown.queue_free))
	t.tween_interval(2.2)
	t.tween_property(c, "modulate:a", 0.0, 0.6)
	t.tween_callback(c.queue_free)

# ---------- Барон Грызь: машина дымит, глохнет и взрывается ----------
static func _baron(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var t := c.create_tween()
	for k in 8:
		t.tween_property(c, "rotation", 0.06 * (1 if k % 2 == 0 else -1), 0.08)
	t.tween_property(c, "rotation", 0.0, 0.05)
	t.tween_callback(func(): c.visible = false)
	t.tween_interval(1.6)
	t.tween_callback(c.queue_free)
	for k in 5:
		world.get_tree().create_timer(0.1 + k * 0.14).timeout.connect(func():
			if is_instance_valid(world):
				_smoke(world, feet + Vector2(-f * bs.x * 0.3, -bs.y * 0.8), Color(0.12, 0.10, 0.10, 0.75), 2, 20.0))
	for k in 3:
		world.get_tree().create_timer(0.25 + k * 0.17).timeout.connect(func():
			if is_instance_valid(world):
				var at := feet + Vector2(randf_range(-bs.x * 0.4, bs.x * 0.4), -randf_range(20, bs.y * 0.8))
				Util.flash(world, at, 60.0, Color(1.0, 0.7, 0.3, 0.9))
				Fx.ring(world, at, 60.0, Color(1.0, 0.55, 0.2, 0.9), 0.25, 4.0))
	world.get_tree().create_timer(0.72).timeout.connect(func():
		if not is_instance_valid(world):
			return
		var mid := feet + Vector2(0, -bs.y * 0.5)
		Util.flash(world, mid, 200.0, Color(1.0, 0.75, 0.4, 0.95))
		Fx.ring(world, mid, 220.0, Color(1.0, 0.55, 0.2, 0.95), 0.45, 9.0)
		Fx.sparks(world, mid, Color(1.0, 0.6, 0.25), 30, 420.0, 6.0)
		Fx.shake(world, 10.0)
		_smoke(world, mid, Color(0.15, 0.12, 0.12, 0.8), 8, bs.x * 0.4)
		var gear := Util.circle(9.0, 8)
		for k in 8:
			_fling(world, gear, Color(0.55, 0.55, 0.6), mid, Vector2(randf_range(-500, 500), -randf_range(300, 700)), feet.y - 4.0, 2.0, 12.0)
		# самого барона уносит взрывом
		var kob := BestiaryScreen.make_figure("kobold_miner", Vector2(50, 70))
		kob.position = mid
		kob.z_index = 6
		world.add_child(kob)
		var kt := kob.create_tween()
		kt.tween_property(kob, "position", mid + Vector2(f * 380.0, -620.0), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		kt.parallel().tween_property(kob, "rotation", 9.0 * f, 1.4)
		kt.tween_property(kob, "position", mid + Vector2(f * 700.0, -1100.0), 0.7)
		kt.parallel().tween_property(kob, "scale", Vector2(0.2, 0.2), 0.7)
		kt.tween_callback(kob.queue_free))

# ---------- Ирида: кристаллы уходят столбом света ----------
static func _irida(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var mid := feet + Vector2(0, -bs.y * 0.5)
	var t := c.create_tween()
	t.tween_property(c, "modulate", Color(2.0, 2.0, 2.4, 1.0), 0.5)
	t.tween_callback(func():
		c.visible = false
		if not is_instance_valid(world):
			return
		Util.flash(world, mid, 220.0, Color(0.85, 0.9, 1.0, 0.95))
		var cols := [Color(0.7, 0.85, 1.0), Color(0.85, 0.7, 1.0), Color(0.7, 1.0, 0.9), Color(1.0, 0.85, 0.95)]
		for k in 26:
			var sh := _poly(world, PackedVector2Array([Vector2(-6, 0), Vector2(0, -3), Vector2(10, 0), Vector2(0, 3)]),
					cols[k % cols.size()], mid + Vector2(randf_range(-30, 30), randf_range(-60, 60)), 6)
			sh.rotation = randf() * TAU
			var out: Vector2 = sh.position + Vector2.from_angle(randf() * TAU) * randf_range(80, 200)
			var st := sh.create_tween()
			st.tween_property(sh, "position", out, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			st.tween_property(sh, "position", Vector2(mid.x + randf_range(-20, 20), mid.y - 900.0), randf_range(0.8, 1.3)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			st.parallel().tween_property(sh, "modulate:a", 0.0, 1.1)
			st.tween_callback(sh.queue_free)
		# столб света
		var beam := _poly(world, PackedVector2Array([Vector2(-40, 0), Vector2(-20, -1400), Vector2(20, -1400), Vector2(40, 0)]),
				Color(0.85, 0.9, 1.0, 0.0), feet, 2)
		var bt := beam.create_tween()
		bt.tween_interval(0.5)
		bt.tween_property(beam, "color:a", 0.45, 0.4)
		bt.tween_property(beam, "scale:x", 0.0, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		bt.tween_callback(beam.queue_free))
	t.tween_interval(2.5)
	t.tween_callback(c.queue_free)

# ---------- Гладиатор: салют толпе, колено, лепестки ----------
static func _gladiator(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var rig = c.get_child(0).get_child(0) if c.get_child_count() > 0 and c.get_child(0).get_child_count() > 0 else null
	if rig and rig.has_method("play"):
		rig.play("roar")                         # поднимает меч — салют
	var t := c.create_tween()
	t.tween_interval(0.8)
	t.tween_property(c, "position:y", feet.y + 14.0, 0.3)
	t.parallel().tween_property(c, "rotation", 0.15 * f, 0.3)
	t.tween_interval(0.9)
	t.tween_property(c, "rotation", 1.4 * f, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		if is_instance_valid(world):
			Fx.sparks(world, feet + Vector2(f * 60.0, -6), Color(0.85, 0.7, 0.5), 12, 200.0, 4.0, true))
	t.tween_interval(1.0)
	t.tween_property(c, "modulate:a", 0.0, 0.6)
	t.tween_callback(c.queue_free)
	# с трибун летят лепестки роз
	for k in 30:
		var petal := _poly(world, PackedVector2Array([Vector2(-4, 0), Vector2(0, -3), Vector2(4, 0), Vector2(0, 2)]),
				Color(0.9, 0.15, 0.2).lightened(randf() * 0.2), feet + Vector2(randf_range(-420, 420), -randf_range(500, 750)), 6)
		var pt := petal.create_tween()
		pt.tween_interval(randf_range(0.2, 1.4))
		pt.tween_property(petal, "position", Vector2(petal.position.x + randf_range(-80, 80), feet.y - 2.0), randf_range(1.6, 2.4)).set_trans(Tween.TRANS_SINE)
		pt.parallel().tween_property(petal, "rotation", randf_range(-8, 8), 2.0)
		pt.tween_property(petal, "modulate:a", 0.0, 0.8)
		pt.tween_callback(petal.queue_free)

# ---------- Колосс: ядро взрывается, тело оседает ----------
static func _colossus(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var mid := feet + Vector2(0, -bs.y * 0.55)
	var core := _poly(world, Util.circle(30.0, 18), Color(1.0, 0.6, 0.2, 0.8), mid, 6)
	var ct := core.create_tween()
	for k in 3:
		ct.tween_property(core, "scale", Vector2.ONE * (1.6 + k * 0.8), 0.18)
		ct.tween_property(core, "scale", Vector2.ONE * (1.1 + k * 0.5), 0.14)
	ct.tween_property(core, "scale", Vector2(5.0, 5.0), 0.2)
	ct.parallel().tween_property(core, "color", Color(1.0, 0.95, 0.8, 1.0), 0.2)
	ct.tween_callback(func():
		if not is_instance_valid(world):
			return
		Util.flash(world, mid, 520.0, Color(1.0, 0.9, 0.7, 1.0))
		Fx.ring(world, mid, 520.0, Color(1.0, 0.55, 0.2, 0.95), 0.6, 14.0)
		Fx.ring(world, mid, 300.0, Color(1.0, 0.9, 0.6, 0.9), 0.45, 9.0)
		Fx.sparks(world, mid, Color(1.0, 0.6, 0.2), 50, 620.0, 7.0)
		Fx.shake(world, 18.0)
		var plate := PackedVector2Array([Vector2(-14, -6), Vector2(14, -8), Vector2(12, 7), Vector2(-11, 8)])
		for k in 12:
			_fling(world, plate, Color(0.26, 0.20, 0.32), mid, Vector2(randf_range(-650, 650), -randf_range(400, 900)), feet.y - 4.0, 2.4, 9.0))
	ct.tween_property(core, "modulate:a", 0.0, 0.4)
	ct.tween_callback(core.queue_free)
	var t := c.create_tween()
	t.tween_property(c, "modulate", Color(1.6, 1.0, 0.7), 0.9)
	t.tween_property(c, "modulate", Color(0.15, 0.12, 0.12), 0.3)
	t.tween_property(c, "scale", Vector2(1.2, 0.1), 0.7).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	t.tween_callback(func():
		if is_instance_valid(world):
			for k in 6:
				_smoke(world, feet + Vector2(randf_range(-60, 60), -10), Color(0.2, 0.17, 0.16, 0.75), 3, 50.0))
	t.tween_property(c, "modulate:a", 0.0, 1.0)
	t.tween_callback(c.queue_free)

# ---------- Ведьма: стая воронов, шляпа падает ----------
static func _witch(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var mid := feet + Vector2(0, -bs.y * 0.5)
	var t := c.create_tween()
	t.tween_property(c, "scale:x", -1.0, 0.12)
	t.tween_property(c, "scale:x", 1.0, 0.12)
	t.tween_callback(func():
		c.visible = false
		if not is_instance_valid(world):
			return
		Util.flash(world, mid, 120.0, Color(0.7, 0.35, 0.9, 0.9))
		_smoke(world, mid, Color(0.4, 0.2, 0.5, 0.7), 6, 30.0)
		for k in 12:
			var cr := WildRig.new()
			cr.kind = "crow"
			cr.size = Vector2(30, 22)
			var dir := Vector2.from_angle(randf_range(-PI * 0.95, -PI * 0.05))
			cr.puppet_facing = 1 if dir.x > 0.0 else -1
			cr.position = mid + Vector2(randf_range(-20, 20), randf_range(-30, 20))
			cr.z_index = 6
			world.add_child(cr)
			var crt := cr.create_tween()
			crt.tween_property(cr, "position", cr.position + dir * randf_range(500, 800), randf_range(1.0, 1.5)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
			crt.parallel().tween_property(cr, "modulate:a", 0.0, 1.2).set_delay(0.3)
			crt.tween_callback(cr.queue_free)
		# шляпа медленно падает, покачиваясь
		var hat := _poly(world, PackedVector2Array([Vector2(-18, 0), Vector2(18, 0), Vector2(8, -4), Vector2(2, -26), Vector2(-6, -10), Vector2(-8, -4)]),
				Color(0.22, 0.12, 0.28), feet + Vector2(0, -bs.y * 0.95), 5)
		var hy := _ground_y(c, feet)
		if hy > feet.y + 2500.0:
			hy = feet.y
		var drop := hy - 2.0 - hat.position.y
		var hx0 := hat.position.x
		var hy0 := hat.position.y
		var ht := hat.create_tween()
		for k in 4:
			ht.tween_property(hat, "position", Vector2(hx0 + (30.0 if k % 2 == 0 else 0.0), hy0 + drop * (k + 1) / 4.0), 0.4).set_trans(Tween.TRANS_SINE)
			ht.parallel().tween_property(hat, "rotation", 0.4 if k % 2 == 0 else -0.4, 0.4)
		ht.tween_property(hat, "rotation", 0.0, 0.2)
		ht.tween_interval(1.8)
		ht.tween_property(hat, "modulate:a", 0.0, 0.6)
		ht.tween_callback(hat.queue_free))
	t.tween_interval(0.5)
	t.tween_callback(c.queue_free)

# ---------- Трясинный Владыка: тонет, последней скрывается рука ----------
static func _bog_lord(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var pud := SwampBits.MudPuddle.new()
	pud.width = bs.x * 1.6
	pud.life = 5.0
	pud.position = feet
	world.add_child(pud)
	c.z_index = 0
	# прячем ноги под «землю»: болотная корка поверх тонущего тела
	var mask := _poly(world, PackedVector2Array([Vector2(-bs.x, 0), Vector2(bs.x, 0), Vector2(bs.x, 400), Vector2(-bs.x, 400)]),
			Color(0.22, 0.23, 0.17), feet + Vector2(0, 2), 1)
	var t := c.create_tween()
	t.tween_property(c, "rotation", 0.12 * f, 0.4)
	t.tween_property(c, "position:y", feet.y + bs.y + 20.0, 2.4).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	t.tween_callback(c.queue_free)
	for k in 12:
		world.get_tree().create_timer(0.2 + k * 0.2).timeout.connect(func():
			if is_instance_valid(world):
				Fx.sparks(world, feet + Vector2(randf_range(-bs.x * 0.5, bs.x * 0.5), -4), Color(0.35, 0.42, 0.22), 4, 140.0, 4.0, true))
	# рука тянется вверх — и тоже уходит в трясину
	var hand := _poly(world, PackedVector2Array([Vector2(-12, 0), Vector2(-14, -26), Vector2(-9, -40), Vector2(-6, -28), Vector2(-3, -44),
			Vector2(0, -28), Vector2(4, -42), Vector2(6, -27), Vector2(11, -36), Vector2(13, -22), Vector2(12, 0)]),
			Color(0.30, 0.36, 0.22), feet + Vector2(f * 20.0, 50.0), 0)
	var ht := hand.create_tween()
	ht.tween_interval(2.2)
	ht.tween_property(hand, "position:y", feet.y - 30.0, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	ht.tween_interval(0.5)
	ht.tween_property(hand, "position:y", feet.y + 60.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	ht.tween_callback(hand.queue_free)
	var mt := mask.create_tween()
	mt.tween_interval(4.2)
	mt.tween_callback(mask.queue_free)

# ---------- Ётун: застывает ледяной статуей и раскалывается ----------
static func _jotun(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var t := c.create_tween()
	t.tween_property(c, "rotation", -0.06 * f, 0.3)
	t.tween_property(c, "modulate", Color(1.5, 1.8, 2.2), 0.9)            # застывает изнутри — белеет
	t.tween_callback(func():
		for k in 8:                                                       # трещины по статуе
			var cr := Line2D.new()
			var p0 := Vector2(randf_range(-bs.x * 0.3, bs.x * 0.3), -randf_range(bs.y * 0.15, bs.y * 0.95))
			cr.points = PackedVector2Array([p0, p0 + Vector2(randf_range(-20, 20), randf_range(15, 35)), p0 + Vector2(randf_range(-30, 30), randf_range(35, 70))])
			cr.width = 3.0
			cr.default_color = Color(0.35, 0.55, 0.8)
			cr.z_index = 3
			c.add_child(cr))
	t.tween_interval(0.7)
	t.tween_callback(func():
		c.visible = false
		if not is_instance_valid(world):
			return
		var mid := feet + Vector2(0, -bs.y * 0.5)
		Util.flash(world, mid, 220.0, Color(0.85, 0.95, 1.0, 0.95))
		Fx.ring(world, mid, 260.0, Color(0.8, 0.95, 1.0, 0.9), 0.5, 8.0)
		Fx.shake(world, 10.0)
		_smoke(world, feet + Vector2(0, -20), Color(0.92, 0.96, 1.0, 0.7), 8, bs.x * 0.5)
		for k in 20:                                                      # глыбы льда разлетаются
			var r := randf_range(8, 20)
			var chunk := PackedVector2Array([Vector2(-r, -r * 0.5), Vector2(r * 0.4, -r), Vector2(r, r * 0.3), Vector2(-r * 0.3, r * 0.8)])
			_fling(world, chunk, Color(0.70, 0.88, 1.0) if k % 3 else Color(0.92, 0.98, 1.0),
					mid + Vector2(randf_range(-bs.x * 0.3, bs.x * 0.3), randf_range(-bs.y * 0.4, bs.y * 0.4)),
					Vector2(randf_range(-520, 520), -randf_range(250, 700)), feet.y - 4.0, 2.4, 7.0)
		# ледяной венец катится
		var crown := _poly(world, PackedVector2Array([Vector2(-16, 0), Vector2(-14, -10), Vector2(-8, -4), Vector2(-3, -16), Vector2(2, -5),
				Vector2(8, -13), Vector2(12, -4), Vector2(16, 0)]), Color(0.75, 0.92, 1.0), feet + Vector2(0, -bs.y * 0.95), 6)
		var ct := crown.create_tween()
		ct.tween_property(crown, "position", feet + Vector2(f * 120.0, -160.0), 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		ct.parallel().tween_property(crown, "rotation", 3.0 * f, 0.4)
		ct.tween_property(crown, "position", feet + Vector2(f * 220.0, -2.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		ct.tween_property(crown, "position:x", feet.x + f * 330.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ct.parallel().tween_property(crown, "rotation", 9.0 * f, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		ct.tween_interval(1.8)
		ct.tween_property(crown, "modulate:a", 0.0, 0.6)
		ct.tween_callback(crown.queue_free))
	t.tween_interval(0.5)
	t.tween_callback(c.queue_free)

# ---------- Громовник: молнии выходят из-под власти, последний удар — и он рассеивается ветром ----------
static func _storm_lord(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var mid := feet + Vector2(0, -bs.y * 0.55)
	var t := c.create_tween()
	t.tween_property(c, "position:y", feet.y - 60.0, 1.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)   # беспомощно всплывает
	t.parallel().tween_property(c, "rotation", 0.2 * f, 1.2)
	for k in 7:                                                          # разряды бьют во все стороны
		var tt := c.create_tween()
		tt.tween_interval(0.12 + k * 0.15)
		tt.tween_callback(func():
			if is_instance_valid(world):
				var to := mid + Vector2.from_angle(randf_range(-PI, 0.2)) * randf_range(180, 360)
				Fx.bolt(world, mid + Vector2(0, -60), to, Color(0.85, 0.92, 1.0))
				Fx.zap(world, to, Color(0.8, 0.9, 1.0), 26.0))
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		# последняя молния с неба — прямо в Владыку
		for k in 4:
			Fx.bolt(world, mid + Vector2(randf_range(-150, 150), -1000.0), mid + Vector2(0, -80), Color(1, 1, 1) if k % 2 else Color(0.7, 0.85, 1.0))
		Util.flash(world, mid, 300.0, Color(0.9, 0.95, 1.0, 1.0))
		Fx.ring(world, mid, 320.0, Color(0.8, 0.9, 1.0, 0.95), 0.5, 10.0)
		Fx.shake(world, 12.0))
	t.tween_property(c, "modulate", Color(2.6, 2.8, 3.2, 1.0), 0.12)
	t.tween_property(c, "scale", Vector2(0.4, 1.6), 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)   # тает вихрем вверх
	t.parallel().tween_property(c, "position:y", feet.y - 320.0, 0.5)
	t.parallel().tween_property(c, "modulate:a", 0.0, 0.5)
	t.tween_callback(c.queue_free)
	# облачко под ним расходится, сверху сыплются искры-капли
	for k in 18:
		var dot := _poly(world, Util.circle(3.0, 6), Color(0.75, 0.88, 1.0, 0.9), mid + Vector2(randf_range(-160, 160), -randf_range(150, 300)), 6)
		var dt := dot.create_tween()
		dt.tween_interval(1.6 + randf() * 0.4)
		dt.tween_property(dot, "position:y", feet.y - 2.0, randf_range(0.6, 1.0)).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		dt.tween_property(dot, "modulate:a", 0.0, 0.3)
		dt.tween_callback(dot.queue_free)
	# посох со сферой падает и катится
	var orb := _poly(world, Util.circle(9.0, 12), Color(0.6, 0.8, 1.0, 0.95), mid + Vector2(f * 30.0, -40.0), 6)
	var ot := orb.create_tween()
	ot.tween_interval(1.4)
	ot.tween_property(orb, "position", Vector2(mid.x + f * 140.0, feet.y - 9.0), 0.6).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	ot.tween_property(orb, "position:x", mid.x + f * 260.0, 0.8).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	ot.tween_property(orb, "color", Color(0.3, 0.35, 0.45, 0.9), 0.6)              # сфера гаснет
	ot.tween_interval(1.4)
	ot.tween_property(orb, "modulate:a", 0.0, 0.6)
	ot.tween_callback(orb.queue_free)

# ---------- Цербер: головы гаснут одна за другой, тело остывает в обсидиан и рассыпается пеплом ----------
static func _cerberus(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var rig = c.get_child(0).get_child(0) if c.get_child_count() > 0 and c.get_child(0).get_child_count() > 0 else null
	var heads: Array = rig.head_points() if rig and rig.has_method("head_points") else []
	var t := c.create_tween()
	for k in 3:                                                          # три последних вздоха — гаснут три огня
		t.tween_interval(0.35)
		t.tween_callback(func():
			if not is_instance_valid(world):
				return
			var hp: Vector2 = heads[k] if k < heads.size() else feet + Vector2(f * bs.x * 0.4, -bs.y * 0.7)
			_smoke(world, hp, Color(0.25, 0.22, 0.22, 0.75), 2, 10.0)
			Fx.sparks(world, hp, Color(1.0, 0.55, 0.2), 6, 120.0, 3.0)
			Fx.shake(world, 3.0))
		t.parallel().tween_property(c, "rotation", 0.06 * f * (k + 1), 0.3)
	t.tween_property(c, "position:y", feet.y + 10.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)   # оседает
	t.parallel().tween_property(c, "modulate", Color(0.35, 0.33, 0.38), 1.2)                                     # остывает в чёрный камень
	t.tween_callback(func():
		if is_instance_valid(world):
			Fx.shake(world, 6.0)
			Fx.cracks(world, feet, Color(1.0, 0.45, 0.12), 140.0))
	t.tween_interval(0.5)
	t.tween_property(c, "scale", Vector2(1.15, 0.0), 0.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)   # рассыпается
	t.parallel().tween_property(c, "modulate:a", 0.0, 0.8)
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		for k in 26:                                                    # пепел поднимается
			var a := _poly(world, PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(2, 2), Vector2(-2, 2)]),
					Color(0.25, 0.22, 0.22) if k % 3 else Color(1.0, 0.5, 0.2), feet + Vector2(randf_range(-bs.x * 0.5, bs.x * 0.5), -randf_range(0, bs.y * 0.5)), 5)
			var at2 := a.create_tween()
			at2.tween_property(a, "position", a.position + Vector2(randf_range(-60, 60), -randf_range(120, 260)), randf_range(1.2, 2.0))
			at2.parallel().tween_property(a, "modulate:a", 0.0, 1.6)
			at2.tween_callback(a.queue_free)
		for k in 10:
			_fling(world, PackedVector2Array([Vector2(-6, -4), Vector2(5, -6), Vector2(7, 3), Vector2(-4, 5)]), Color(0.12, 0.10, 0.13),
					feet + Vector2(randf_range(-bs.x * 0.4, bs.x * 0.4), -20), Vector2(randf_range(-300, 300), -randf_range(200, 420)), feet.y - 4.0, 2.0, 6.0))
	t.tween_callback(c.queue_free)

# ---------- Тёмный Лорд: на колено, меч в пол, доспех трескается светом — и он рассыпается пеплом ----------
static func _dark_lord(world: Node, c: Node2D, feet: Vector2, f: float, bs: Vector2) -> void:
	var mid := feet + Vector2(0, -bs.y * 0.5)
	var t := c.create_tween()
	t.tween_property(c, "rotation", 0.12 * f, 0.5).set_trans(Tween.TRANS_SINE)
	t.parallel().tween_property(c, "position:y", feet.y + 34.0, 0.5)                       # на колено
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		Fx.shake(world, 8.0)
		Fx.cracks(world, feet + Vector2(f * bs.x * 0.6, 0), Color(0.8, 0.25, 0.1), 120.0)
		# меч остаётся воткнутым в пол
		var sw := Node2D.new()
		sw.position = feet + Vector2(f * bs.x * 0.65, 0)
		sw.z_index = 3
		sw.rotation = 0.12 * f
		var blade := Polygon2D.new()
		blade.polygon = PackedVector2Array([Vector2(-6, -20), Vector2(6, -20), Vector2(5, 30), Vector2(0, 40), Vector2(-5, 30)])
		blade.color = Color(0.12, 0.10, 0.14)
		sw.add_child(blade)
		var edge := Line2D.new()
		edge.points = PackedVector2Array([Vector2(4, -18), Vector2(4, 28)])
		edge.width = 2.0
		edge.default_color = Color(1.0, 0.4, 0.12)
		sw.add_child(edge)
		var guard := Polygon2D.new()
		guard.polygon = PackedVector2Array([Vector2(-22, -26), Vector2(22, -26), Vector2(26, -32), Vector2(18, -22), Vector2(-18, -22), Vector2(-26, -32)])
		guard.color = Color(0.55, 0.52, 0.58)
		sw.add_child(guard)
		var grip := Polygon2D.new()
		grip.polygon = PackedVector2Array([Vector2(-4, -26), Vector2(4, -26), Vector2(4, -58), Vector2(-4, -58)])
		grip.color = Color(0.20, 0.16, 0.16)
		sw.add_child(grip)
		world.add_child(sw)
		var swt := sw.create_tween()
		swt.tween_interval(6.0)
		swt.tween_property(sw, "modulate:a", 0.0, 1.0)
		swt.tween_callback(sw.queue_free))
	t.tween_interval(0.4)
	t.tween_callback(func():
		if not is_instance_valid(world):
			return
		for k in 12:                                                      # из трещин доспеха бьёт свет
			var l := Line2D.new()
			var a := randf() * TAU
			var o := mid + Vector2(randf_range(-bs.x * 0.2, bs.x * 0.2), randf_range(-bs.y * 0.3, bs.y * 0.2))
			l.points = PackedVector2Array([o, o + Vector2.from_angle(a) * randf_range(140, 320)])
			l.width = 5.0
			l.default_color = Color(1.0, 0.75, 0.4, 0.0)
			l.z_index = 9
			world.add_child(l)
			var lt := l.create_tween()
			lt.tween_property(l, "default_color:a", 0.9, 0.25).set_delay(k * 0.07)
			lt.tween_interval(0.6)
			lt.tween_property(l, "default_color:a", 0.0, 0.4)
			lt.tween_callback(l.queue_free))
	t.tween_property(c, "modulate", Color(2.4, 1.7, 1.2), 1.2)
	t.tween_callback(func():
		c.visible = false
		if not is_instance_valid(world):
			return
		# камень в груди раскалывается — вспышка
		Util.flash(world, mid, 360.0, Color(1.0, 0.85, 0.6, 1.0))
		Fx.ring(world, mid, 420.0, Color(1.0, 0.6, 0.3, 0.95), 0.6, 12.0)
		Fx.ring(world, mid, 240.0, Color(1.0, 0.95, 0.8, 0.9), 0.45, 8.0)
		Fx.shake(world, 16.0)
		for k in 8:
			_fling(world, PackedVector2Array([Vector2(-4, -3), Vector2(4, -4), Vector2(3, 4), Vector2(-3, 3)]), Color(1.0, 0.35, 0.12),
					mid + Vector2(0, -bs.y * 0.1), Vector2(randf_range(-400, 400), -randf_range(300, 700)), feet.y - 3.0, 2.4, 9.0)
		for k in 60:                                                     # пепел уносит вверх
			var a := _poly(world, PackedVector2Array([Vector2(-3, -2), Vector2(3, -2), Vector2(2, 2), Vector2(-2, 2)]),
					Color(0.10, 0.08, 0.10) if k % 4 else Color(1.0, 0.5, 0.2), mid + Vector2(randf_range(-bs.x * 0.45, bs.x * 0.45), randf_range(-bs.y * 0.5, bs.y * 0.45)), 6)
			var at2 := a.create_tween()
			at2.tween_property(a, "position", a.position + Vector2(randf_range(-120, 120), -randf_range(260, 560)), randf_range(1.6, 2.6)).set_trans(Tween.TRANS_SINE)
			at2.parallel().tween_property(a, "rotation", randf_range(-6, 6), 2.0)
			at2.parallel().tween_property(a, "modulate:a", 0.0, 2.2)
			at2.tween_callback(a.queue_free))
	t.tween_interval(0.5)
	t.tween_callback(c.queue_free)
