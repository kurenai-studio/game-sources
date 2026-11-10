class_name EerieWoods
# ---------- Арены «Жуткий лес» (волны 51–55) и «Болото» (волны 56–60) ----------
# Голые мёртвые деревья — только стволы и ветки, тропа из тёмной земли без травы.
#
# Жуткий лес. Механика: хватающие корни — кто наступит на чёрный узел корней
#   (и герой, и враг), того оплетает. Ведьмина избушка на мёртвом дереве —
#   по сучьям-ступенькам можно забраться к алтарю (бафф часто МЕГА).
#   Препятствия: надгробия, мёртвые пни, поваленное чёрное бревно, мостки на сучьях.
# Болото. Механики: лужи трясины (вязнешь — вдвое медленнее), болотный газ
#   (пузыри растут, потом вспышка бьёт всех рядом), брёвна-плоты над трясиной —
#   под седоком медленно тонут. Препятствия: гнилые коряги, кочки, мостки.

const W := Colosseum.W
const H := Colosseum.H
const FLOOR_Y := Colosseum.FLOOR_Y
const WALL := Colosseum.WALL
const STEP := Colosseum.STEP
const EARTH := Color(0.27, 0.23, 0.21)
const EARTH_TOP := Color(0.20, 0.18, 0.18)
const MUD := Color(0.22, 0.23, 0.17)
const MUD_TOP := Color(0.17, 0.20, 0.13)
const DEADWOOD := Color(0.24, 0.21, 0.21)
const PLANK := Color(0.50, 0.44, 0.40)

static func build(world: Node, swamp: bool) -> Dictionary:
	var bg := PixelArt.make_sprite(LandArt.eerie_backdrop(W, FLOOR_Y, swamp), PixelArt.SCALE)
	bg.z_index = -10
	world.add_child(bg)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, H - FLOOR_Y + 40), MUD if swamp else EARTH)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, 8), MUD_TOP if swamp else EARTH_TOP)
	# камешки и трещины на тропе (без травы)
	for x in range(30, int(W), 47):
		var st := Polygon2D.new()
		var r := 2.0 + float(x % 5)
		st.polygon = PackedVector2Array([Vector2(-r, 0), Vector2(-r * 0.4, -r * 0.7), Vector2(r * 0.6, -r * 0.6), Vector2(r, 0)])
		st.color = Color(0.36, 0.34, 0.36) if not swamp else Color(0.26, 0.30, 0.22)
		st.position = Vector2(x, FLOOR_Y + 1)
		st.z_index = 1
		world.add_child(st)
	# стены — огромные мёртвые стволы
	for x in [0.0, W - WALL]:
		Maps.add_block(world, Rect2(x, -800, WALL, H + 800), DEADWOOD)
		for k in 6:
			var r2 := ColorRect.new()
			r2.color = DEADWOOD.darkened(0.3)
			r2.position = Vector2(x + 12 + (k % 2) * 26, -700 + k * 270)
			r2.size = Vector2(6, 220)
			r2.z_index = 1
			world.add_child(r2)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	for g in gates:
		_hollow(world, g, swamp)
	# сумрак, блуждающие огоньки, туман
	var cm := CanvasModulate.new()
	cm.color = Color(0.78, 0.76, 0.88) if not swamp else Color(0.76, 0.86, 0.76)
	world.add_child(cm)
	var glow_layer := CanvasLayer.new()
	glow_layer.layer = 1
	glow_layer.follow_viewport_enabled = true
	world.add_child(glow_layer)
	for i in 14:
		var f := Torch.make_glow(40.0, Color(0.55, 1.0, 0.75, 0.75) if swamp else Color(0.7, 0.8, 1.0, 0.7))
		f.position = Vector2(randf_range(150, W - 150), randf_range(FLOOR_Y - 500, FLOOR_Y - 60))
		glow_layer.add_child(f)
		var tw := f.create_tween().set_loops()
		tw.tween_property(f, "position", f.position + Vector2(randf_range(-80, 80), randf_range(-40, 40)), randf_range(3.0, 5.0))
		tw.tween_property(f, "position", f.position, randf_range(3.0, 5.0))
	for x in [380.0, 1300.0, W - 380.0]:
		var t := Torch.new()
		t.position = Vector2(x, FLOOR_Y - 280.0)
		t.lit = true
		t.glow_layer = glow_layer
		world.add_child(t)
	_fog(world)
	_bg_trees(world, swamp)
	var sp := _swamp(world) if swamp else _forest(world)
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": glow_layer, "floor": FLOOR_Y, "spawners": sp, "totems": []}

# Дупло в мёртвом стволе: из него лезут враги
static func _hollow(world: Node, base: Vector2, swamp: bool) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([Vector2(-100, 0), Vector2(-80, -150), Vector2(-60, -260), Vector2(-20, -300), Vector2(30, -290),
			Vector2(70, -240), Vector2(85, -140), Vector2(105, 0)])
	trunk.color = DEADWOOD.lightened(0.05)
	g.add_child(trunk)
	_bark(g, -60.0, 50.0, -270.0, DEADWOOD.lightened(0.05))
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-55, 0), Vector2(-50, -90), Vector2(-25, -135), Vector2(18, -132), Vector2(48, -92), Vector2(55, 0)])
	hole.color = Color(0.03, 0.03, 0.04)
	g.add_child(hole)
	for s in [-1, 1]:
		var eye := Polygon2D.new()               # в темноте дупла — глаза
		eye.polygon = Util.circle(3.0, 8)
		eye.color = Color(1.0, 0.85, 0.3, 0.8) if not swamp else Color(0.6, 1.0, 0.4, 0.8)
		eye.position = Vector2(s * 10 - 2, -86)
		g.add_child(eye)
	for k in 4:                                  # сучья
		var br := Line2D.new()
		var y0 := -150.0 - k * 35.0
		var sd := -1.0 if k % 2 == 0 else 1.0
		br.points = PackedVector2Array([Vector2(sd * 60, y0), Vector2(sd * 120, y0 - 40), Vector2(sd * 150, y0 - 30)])
		br.width = 6.0 - k
		br.default_color = DEADWOOD
		g.add_child(br)
	world.add_child(g)

# Кора: тёмные продольные трещины, светлый край с одной стороны и дупло-сучок
static func _bark(parent: Node2D, x0: float, x1: float, top: float, base: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(x0 * 13.0 + top)
	var lit := Line2D.new()
	lit.points = PackedVector2Array([Vector2(x1 - 3.0, -4.0), Vector2(x1 * 0.5 - 2.0, top + 30.0)])
	lit.width = 3.0
	lit.default_color = base.lightened(0.18)
	parent.add_child(lit)
	var n := int((x1 - x0) / 9.0)
	for k in n:
		var x := lerpf(x0 + 6.0, x1 - 8.0, (k + 0.5) / float(n))
		var cr := Line2D.new()
		var y0 := -rng.randf_range(0.0, 40.0)
		var y1 := lerpf(y0, top * 0.9, rng.randf_range(0.4, 0.9))
		cr.points = PackedVector2Array([Vector2(x, y0), Vector2(x + rng.randf_range(-3, 3), (y0 + y1) / 2.0),
				Vector2(x * 0.7, y1)])
		cr.width = 2.0
		cr.default_color = base.darkened(0.35)
		parent.add_child(cr)
	var knot := Polygon2D.new()
	knot.polygon = Util.circle(5.0, 10)
	knot.scale = Vector2(0.8, 1.3)
	knot.color = base.darkened(0.55)
	knot.position = Vector2(lerpf(x0, x1, 0.4) * 0.6, top * rng.randf_range(0.35, 0.6))
	parent.add_child(knot)

# Полосы тумана, медленно плывущие над тропой
static func _fog(world: Node) -> void:
	for k in 3:
		var fog := Polygon2D.new()
		var y := FLOOR_Y - 30.0 - k * 26.0
		fog.polygon = PackedVector2Array([Vector2(-200, y), Vector2(W + 200, y - 6), Vector2(W + 200, y + 24), Vector2(-200, y + 30)])
		fog.color = Color(0.80, 0.82, 0.88, 0.07)
		fog.z_index = 5
		world.add_child(fog)
		var tw := fog.create_tween().set_loops()
		tw.tween_property(fog, "position:x", 140.0 * (1 if k % 2 == 0 else -1), 9.0 + k * 2.0)
		tw.tween_property(fog, "position:x", 0.0, 9.0 + k * 2.0)

# Большие мёртвые деревья на ближнем плане (сквозь них проходят)
static func _bg_trees(world: Node, swamp: bool) -> void:
	for x in [560.0, 1000.0, 1620.0, 2080.0]:
		var t := Node2D.new()
		t.position = Vector2(x, FLOOR_Y)
		t.z_index = -6
		var trunk := Polygon2D.new()
		trunk.polygon = PackedVector2Array([Vector2(-24, 0), Vector2(-14, -360), Vector2(-6, -520), Vector2(6, -520), Vector2(14, -360), Vector2(24, 0),
				Vector2(44, 6), Vector2(-44, 6)])
		trunk.color = DEADWOOD.lightened(0.10)
		t.add_child(trunk)
		_bark(t, -16.0, 16.0, -500.0, DEADWOOD.lightened(0.10))
		var rng := RandomNumberGenerator.new()
		rng.seed = int(x)
		for k in 5:
			var br := Line2D.new()
			var y0 := -200.0 - k * 60.0
			var sd := -1.0 if (k + int(x)) % 2 == 0 else 1.0
			var l := rng.randf_range(60, 120)
			br.points = PackedVector2Array([Vector2(0, y0), Vector2(sd * l * 0.6, y0 - l * 0.5), Vector2(sd * l, y0 - l * 0.4 - 20)])
			br.width = 8.0 - k
			br.default_color = DEADWOOD.lightened(0.05)
			t.add_child(br)
			if swamp and k % 2 == 0:
				var moss := Line2D.new()             # свисающий болотный мох
				moss.points = PackedVector2Array([Vector2(sd * l * 0.6, y0 - l * 0.5), Vector2(sd * l * 0.6 + 4, y0 - l * 0.5 + 50)])
				moss.width = 4.0
				moss.default_color = Color(0.36, 0.45, 0.30, 0.85)
				t.add_child(moss)
		world.add_child(t)

# Поваленное чёрное бревно
static func _dead_log(world: Node, rect: Rect2) -> void:
	var d := Maps.make_destructible(rect, 20.0, Color(0.26, 0.22, 0.22), 60, 30.0)
	d.anchored = true
	d.flammable = true
	for x in d.cols:
		d.anchors.append(Vector2i(x, d.rows - 1))
	world.add_child(d)

static func _forest(world: Node) -> Array:
	var f := FLOOR_Y
	var c := W / 2
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, f), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, f), "heal"))
	for side in [1.0, -1.0]:
		var x0: float = 470.0 if side > 0 else W - 470.0
		ForestTrail.wood_plat(world, Rect2(x0 - 130, f - STEP, 260, 18), PLANK)
		ForestTrail.wood_plat(world, Rect2(x0 - 90 + side * 120, f - STEP * 2, 200, 18), PLANK)
		Props.gravestone(world, x0 + side * 300.0, f, side > 0)
		Props.dead_stump(world, x0 - side * 220.0, f, false)
	# ведьмина избушка на мёртвом дереве — справа
	sp.append(Props.tree_house(world, W - 900.0, f, true))
	sp.append(Colosseum._ledge(world, 470.0 + 20.0, STEP * 3, 150.0))
	_dead_log(world, Rect2(c - 140, f - 40, 280, 40))
	ForestTrail.wood_plat(world, Rect2(c - 120, f - STEP * 2, 240, 18), PLANK)
	ForestTrail.wood_plat(world, Rect2(c - 300, f - STEP * 3, 170, 18), PLANK)
	sp.append(Colosseum._ledge(world, c + 60, STEP * 4, 160.0))
	Props.gravestone(world, 880.0, f, false)
	# хватающие корни на тропе
	for x in [720.0, 1120.0, 1500.0, W - 620.0]:
		var rt := RootTrap.new()
		rt.position = Vector2(x, f)
		world.add_child(rt)
	return sp

static func _swamp(world: Node) -> Array:
	var f := FLOOR_Y
	var c := W / 2
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, f), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, f), "heal"))
	# лужи трясины, над ними брёвна-плоты, в лужах — газ
	for px in [620.0, c, W - 620.0]:
		var pud := SwampBits.MudPuddle.new()
		pud.width = 300.0 if px == c else 240.0
		pud.position = Vector2(px, f)
		world.add_child(pud)
	for lx in [620.0, W - 620.0]:
		var lg := SwampBits.SinkingLog.new()
		lg.width = 200.0
		lg.position = Vector2(lx, f - STEP)
		world.add_child(lg)
	for gx in [560.0, c + 90.0, W - 680.0]:
		var gv := SwampBits.GasVent.new()
		gv.position = Vector2(gx, f)
		world.add_child(gv)
	for side in [1.0, -1.0]:
		var x0: float = 470.0 if side > 0 else W - 470.0
		ForestTrail.wood_plat(world, Rect2(x0 - 90 + side * 160, f - STEP * 2, 200, 18), PLANK)
		sp.append(Colosseum._ledge(world, x0 + side * 40, STEP * 3, 150.0))
		Props.dead_stump(world, x0 + side * 420.0, f, true)
	# середина: плот повыше и мостки к верхнему алтарю
	var mid := SwampBits.SinkingLog.new()
	mid.width = 240.0
	mid.position = Vector2(c, f - STEP * 2)
	world.add_child(mid)
	ForestTrail.wood_plat(world, Rect2(c - 110, f - STEP * 3 - 20, 220, 18), PLANK)
	sp.append(Colosseum._ledge(world, c, STEP * 4 + 20, 160.0))
	Props.gravestone(world, c - 330.0, f, true)
	Props.dead_stump(world, c + 330.0, f, true)
	# камыш у луж (украшение)
	for x in range(300, int(W) - 300, 37):
		if x % 3 != 0:
			continue
		var reed := Line2D.new()
		reed.points = PackedVector2Array([Vector2(x, f), Vector2(x + 3, f - 30 - x % 20)])
		reed.width = 2.0
		reed.default_color = Color(0.30, 0.40, 0.22)
		reed.z_index = 2
		world.add_child(reed)
	return sp
