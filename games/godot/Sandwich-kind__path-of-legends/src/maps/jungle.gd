class_name Jungle
# Арена в джунглях гоблинов (волны 11–20). Размер тот же, что у Колизея.
# По краям — огромные стволы, пол — земля с травой. Боты выходят из пещер.
# Механика: лианы — свисают с крон и платформ, по ним можно забраться наверх.
# Препятствия: поваленные брёвна (горят!), замшелые камни, головы идолов, деревянные мостки,
# каменные уступы с алтарями баффов и станции лечения у краёв.
# Ночью (волны 16–20) темно, на фоне горят факелы.

const W := Colosseum.W
const H := Colosseum.H
const FLOOR_Y := Colosseum.FLOOR_Y
const WALL := Colosseum.WALL
const STEP := Colosseum.STEP
const DIRT := Color(0.40, 0.29, 0.18)
const GRASS := Color(0.30, 0.55, 0.24)
const BARK := Color(0.33, 0.23, 0.14)
const MOSS := Color(0.42, 0.50, 0.38)
const LOG := Color(0.52, 0.36, 0.20)
const NIGHT_TINT := Color(0.36, 0.42, 0.62)

static func build(world: Node, night: bool) -> Dictionary:
	var bg := PixelArt.make_sprite(PixelArt.jungle_backdrop(W, FLOOR_Y, night), PixelArt.SCALE)
	bg.z_index = -10
	world.add_child(bg)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, H - FLOOR_Y + 40), DIRT)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, 10), GRASS)
	# стены — огромные стволы
	for x in [0.0, W - WALL]:
		Maps.add_block(world, Rect2(x, -800, WALL, H + 800), BARK)
		for k in 6:
			var r := ColorRect.new()
			r.color = BARK.darkened(0.25)
			r.position = Vector2(x + 14 + (k % 2) * 22, -700 + k * 270)
			r.size = Vector2(8, 200)
			r.z_index = 1
			world.add_child(r)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	for g in gates:
		_cave(world, g)

	var glow_layer: CanvasLayer = null
	if night:
		var cm := CanvasModulate.new()
		cm.color = NIGHT_TINT
		world.add_child(cm)
		glow_layer = CanvasLayer.new()
		glow_layer.layer = 1
		glow_layer.follow_viewport_enabled = true
		world.add_child(glow_layer)
		# факелы на фоне
		for x in [300.0, 760.0, 1300.0, 1840.0, 2300.0]:
			var t := Torch.new()
			t.position = Vector2(x, FLOOR_Y - 260.0 - (60.0 if int(x) % 3 == 0 else 0.0))
			t.lit = true
			t.glow_layer = glow_layer
			world.add_child(t)
		# светлячки
		for i in 26:
			var f := Torch.make_glow(26.0, Color(0.7, 1.0, 0.4, 0.8))
			f.position = Vector2(randf_range(100, W - 100), randf_range(FLOOR_Y - 600, FLOOR_Y - 40))
			glow_layer.add_child(f)
			var tw := f.create_tween().set_loops()
			tw.tween_property(f, "position", f.position + Vector2(randf_range(-60, 60), randf_range(-40, 40)), randf_range(2.0, 4.0))
			tw.tween_property(f, "position", f.position, randf_range(2.0, 4.0))

	var res := _obstacles(world, night)
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": glow_layer, "floor": FLOOR_Y, "spawners": res[0], "totems": res[1]}

# Пещера, из которой выходят гоблины
static func _cave(world: Node, base: Vector2) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	var rock := Polygon2D.new()
	rock.polygon = PackedVector2Array([Vector2(-95, 0), Vector2(-85, -120), Vector2(-40, -175), Vector2(30, -180),
			Vector2(85, -130), Vector2(95, 0)])
	Tex.apply(rock, "rock", Color(0.36, 0.38, 0.33))
	g.add_child(rock)
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-58, 0), Vector2(-52, -95), Vector2(-20, -130), Vector2(22, -128),
			Vector2(52, -92), Vector2(58, 0)])
	hole.color = Color(0.06, 0.05, 0.05)
	g.add_child(hole)
	for k in 7:
		var vine := ColorRect.new()
		vine.color = Color(0.22, 0.5, 0.2)
		vine.position = Vector2(-70 + k * 22, -170 + (k % 3) * 8)
		vine.size = Vector2(4, 40 + (k * 13) % 50)
		g.add_child(vine)
	world.add_child(g)

# Поваленное бревно: горит и ломается, держится за землю нижним рядом
static func _log(world: Node, rect: Rect2) -> void:
	var d := Maps.make_destructible(rect, 20.0, LOG, 55, 30.0)
	d.flammable = true
	d.anchored = true
	for x in d.cols:
		d.anchors.append(Vector2i(x, d.rows - 1))
	for x in d.cols:
		for y in d.rows:
			if (x + y * 3) % 7 == 0:
				d.cell_colors[Vector2i(x, y)] = LOG.darkened(0.2)
	world.add_child(d)

# Замшелый камень
static func _rock(world: Node, rect: Rect2) -> void:
	var d := Maps.make_destructible(rect, 20.0, MOSS, 80, 45.0)
	d.anchored = true
	for x in d.cols:
		d.anchors.append(Vector2i(x, d.rows - 1))
		d.cell_colors[Vector2i(x, 0)] = GRASS
	world.add_child(d)

# Возвращает [станции, места для тотемов]
static func _obstacles(world: Node, night: bool) -> Array:
	var f := FLOOR_Y
	var c := W / 2
	var sp: Array = []
	var totems: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, f), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, f), "heal"))
	if not night:
		# «Поляна»: мостки ярусами, бревно посередине, камни
		for side in [1.0, -1.0]:
			var x0: float = 470.0 if side > 0 else W - 470.0
			Colosseum.plat(world, Rect2(x0 - 140, f - STEP, 280, 20))
			Colosseum.plat(world, Rect2(x0 - 100 + side * 120, f - STEP * 2, 200, 20))
			totems.append(Vector2(x0 + side * 120, f - STEP * 2))
			sp.append(Colosseum._ledge(world, x0 + side * 20, STEP * 3, 160.0))
			totems.append(Vector2(x0 + side * 20 + 45, f - STEP * 3))
			_rock(world, Rect2((x0 + side * 330) - 40, f - 60, 80, 60))
		_log(world, Rect2(c - 160, f - 60, 320, 60))
		Colosseum._tower(world, c, 300.0, 3)
		sp.append(Colosseum._ledge(world, c, STEP * 4, 160.0))
		totems.append(Vector2(c + 45, f - STEP * 4))
		for x in [960.0, W - 960.0]:
			Props.idol_head(world, x, f)
	else:
		# «Деревня гоблинов»: хижины на сваях по краям, руины в центре
		for side in [1.0, -1.0]:
			var x0: float = 560.0 if side > 0 else W - 560.0
			Maps.add_column(world, Rect2(x0 - 120, f - STEP, 30, STEP))
			Maps.add_column(world, Rect2(x0 + 90, f - STEP, 30, STEP))
			Colosseum.plat(world, Rect2(x0 - 150, f - STEP - 20, 300, 20))
			Colosseum.plat(world, Rect2(x0 - 110, f - STEP * 2 - 20, 220, 20))
			totems.append(Vector2(x0 - side * 60, f - STEP * 2 - 20))
			sp.append(Colosseum._ledge(world, x0, STEP * 3 + 20, 160.0))
			totems.append(Vector2(x0 + 45, f - STEP * 3 - 20))
			_log(world, Rect2(x0 + side * 260 - 80, f - 40, 160, 40))
		for side in [1.0, -1.0]:
			_rock(world, Rect2(c + side * 200 - 30, f - 100, 60, 100))
		Colosseum._tower(world, c, 260.0, 3)
		sp.append(Colosseum._ledge(world, c, STEP * 4, 160.0))
		totems.append(Vector2(c + 45, f - STEP * 4))
	_vines(world, night)
	return [sp, totems]

# Лианы: свисают с крон и с краёв платформ. По ним можно забраться наверх
# (держи прыжок), повиснуть или съехать вниз.
static func _vines(world: Node, night: bool) -> void:
	var f := FLOOR_Y
	var c := W / 2
	# длинные — с крон, достают почти до земли: путь к верхним ярусам
	for x in [760.0, 1060.0, W - 1060.0, W - 760.0]:
		var v := ClimbVine.new()
		v.position = Vector2(x, f - STEP * 5.2)
		v.length = STEP * 5.2 - 70.0
		world.add_child(v)
	# короткие — с краёв платформ
	for side in [1.0, -1.0]:
		var x0: float = (470.0 if side > 0 else W - 470.0) if not night else (560.0 if side > 0 else W - 560.0)
		var v2 := ClimbVine.new()
		v2.position = Vector2(x0 + side * (150.0 if not night else 160.0), f - STEP * 2 + 10.0)
		v2.length = STEP * 2 - 70.0
		world.add_child(v2)
	var vc := ClimbVine.new()
	vc.position = Vector2(c + 160.0, f - STEP * 3 + 10.0)
	vc.length = STEP * 3 - 70.0
	world.add_child(vc)
	# платформы поросли: зелёные клочья на краях (украшение)
	for x in [470.0, W - 470.0, c]:
		for k in 4:
			var tuft := Polygon2D.new()
			tuft.polygon = PackedVector2Array([Vector2(-12, 0), Vector2(0, -8), Vector2(12, 0), Vector2(4, 10), Vector2(-4, 12)])
			tuft.color = Color(0.30, 0.58, 0.24) if k % 2 == 0 else Color(0.24, 0.48, 0.20)
			tuft.position = Vector2(x - 110 + k * 70, f - STEP * (1 + k % 3) + 2)
			tuft.z_index = 2
			world.add_child(tuft)
