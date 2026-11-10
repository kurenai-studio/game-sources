class_name FarStages
# ---------- Арены дальних земель (волны 61–80) ----------
#   12 — Ледяная тропа (61–65): ночь, северное сияние, снег. Наледь, сосульки, сугробы.
#   13 — Храм шторма (66–70): вечная гроза, ливень, ветер. Порывы ветра, громоотводы.
#   14 — Лавовые просторы (71–75): пепел и обсидиан, сажа. Лавовые озёра, вулканические бомбы.
#   15 — Тронный зал Тёмного лорда (76–80): люстры над залом, решётки с пламенем бездны.
#   16 — Вершина цитадели: сюда Тёмный Лорд уводит бой во второй фазе (и здесь же
#        третья фаза). Отдельно не выбирается — только посреди боя с Лордом.
# Механики — в FarBits, фоны — в FarArt, погода — Weather.

const W := Colosseum.W
const H := Colosseum.H
const FLOOR_Y := Colosseum.FLOOR_Y
const WALL := Colosseum.WALL
const STEP := Colosseum.STEP

const ICE := Color(0.62, 0.80, 0.95)
const ICE_WALL := Color(0.50, 0.66, 0.84)
const SNOW_FLOOR := Color(0.84, 0.87, 0.93)
const TEMPLE := Color(0.46, 0.48, 0.54)
const TEMPLE_FLOOR := Color(0.30, 0.32, 0.38)
const BASALT := Color(0.16, 0.13, 0.14)
const OBSIDIAN := Color(0.10, 0.08, 0.12)
const HALL := Color(0.24, 0.20, 0.23)
const HALL_FLOOR := Color(0.15, 0.12, 0.14)

static func build(world: Node, stage: int) -> Dictionary:
	match stage:
		12: return _ice(world)
		13: return _storm(world)
		14: return _lava(world)
		16: return citadel(world)
		_: return _throne(world)

# ---------- общее ----------
static func _backdrop(world: Node, img: Image) -> void:
	var bg := PixelArt.make_sprite(img, PixelArt.SCALE)
	bg.z_index = -10
	world.add_child(bg)

static func _frame(world: Node, floor_c: Color, top_c: Color, wall_c: Color) -> void:
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, H - FLOOR_Y + 40), floor_c)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, 8), top_c)
	for x in [0.0, W - WALL]:
		Maps.add_block(world, Rect2(x, -800, WALL, H + 800), wall_c)

static func _glow_layer(world: Node, tint: Color) -> CanvasLayer:
	var cm := CanvasModulate.new()
	cm.color = tint
	world.add_child(cm)
	var gl := CanvasLayer.new()
	gl.layer = 1
	gl.follow_viewport_enabled = true
	world.add_child(gl)
	return gl

static func _weather(world: Node, mode: String, flashes := false) -> Weather:
	var w := Weather.new()
	w.mode = mode
	w.flashes = flashes
	world.add_child(w)
	return w

# Сквозная площадка своего материала (снизу пропрыгнуть, сверху стоять)
static func _plat(world: Node, rect: Rect2, c: Color) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Layer.WORLD | Layer.FRAME
	body.position = rect.get_center()
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	col.shape = rs
	col.one_way_collision = true
	body.add_child(col)
	body.add_child(Tex.slab(rect.size, Tex.material_for(c), c, int(rect.position.x * 7 + rect.position.y)))
	world.add_child(body)

static func _info(gates: Array, glow: CanvasLayer, sp: Array) -> Dictionary:
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": glow, "floor": FLOOR_Y, "spawners": sp, "totems": []}

# Типовая раскладка: лечебные алтари у стен, по бокам две ступени площадок,
# в середине — препятствие, площадки ярусами и уступ с баффом на самом верху.
static func _layout(world: Node, c: Color, sp: Array) -> void:
	sp.append(Colosseum._station(world, Vector2(WALL + 175, FLOOR_Y), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, FLOOR_Y), "heal"))
	for side in [1.0, -1.0]:
		var x0: float = 470.0 if side > 0 else W - 470.0
		_plat(world, Rect2(x0 - 130, FLOOR_Y - STEP, 260, 18), c)
		_plat(world, Rect2(x0 - 90 + side * 130, FLOOR_Y - STEP * 2, 200, 18), c)
		sp.append(Colosseum._ledge(world, x0 + side * 30, STEP * 3, 150.0))
	_plat(world, Rect2(W / 2 - 120, FLOOR_Y - STEP * 2, 240, 18), c)
	_plat(world, Rect2(W / 2 - 300, FLOOR_Y - STEP * 3, 170, 18), c)
	_plat(world, Rect2(W / 2 + 130, FLOOR_Y - STEP * 3, 170, 18), c)
	sp.append(Colosseum._ledge(world, W / 2, STEP * 4 + 10, 160.0))

# ======================= 12 — Ледяная тропа =======================
static func _ice(world: Node) -> Dictionary:
	_backdrop(world, FarArt.ice_backdrop(W, FLOOR_Y))
	_frame(world, SNOW_FLOOR, Maps.SNOW, ICE_WALL)
	# снежная кромка: наносы на полу
	for x in range(40, int(W), 90):
		var dr := Polygon2D.new()
		var hw := randf_range(26, 44)
		dr.polygon = PackedVector2Array([Vector2(-hw, 0), Vector2(-hw * 0.4, -6), Vector2(hw * 0.3, -7), Vector2(hw, 0)])
		dr.color = Color(0.96, 0.98, 1.0)
		dr.position = Vector2(x + randf_range(-20, 20), FLOOR_Y + 1)
		dr.z_index = 1
		world.add_child(dr)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	for g in gates:
		_ice_cave(world, g)
	var glow := _glow_layer(world, Color(0.64, 0.70, 0.98))
	# светящиеся ледяные кристаллы на ближнем плане
	for x in [330.0, 900.0, 1700.0, 2270.0]:
		_ice_crystal(world, glow, Vector2(x, FLOOR_Y), randf_range(70, 120))
	var sp: Array = []
	_layout(world, ICE, sp)
	# наледь — катишься по инерции
	for pd in [[760.0, 260.0], [W / 2, 320.0], [W - 760.0, 260.0]]:
		var ip := FarBits.IcePatch.new()
		ip.width = pd[1]
		ip.position = Vector2(pd[0], FLOOR_Y)
		world.add_child(ip)
	# сосульки под верхними площадками: срываются на того, кто под ними
	for side in [1.0, -1.0]:
		var x0: float = 470.0 if side > 0 else W - 470.0
		_icicles(world, Vector2(x0 - 90 + side * 130 + 100, FLOOR_Y - STEP * 2 + 18), 150.0)
	_icicles(world, Vector2(W / 2, FLOOR_Y - STEP * 2 + 18), 190.0)
	# сугробы — укрытия
	for x in [470.0 + 300.0, 470.0 - 230.0, W - 470.0 - 300.0, W - 470.0 + 230.0, W / 2 - 330.0, W / 2 + 330.0]:
		FarBits.snowdrift(world, x, FLOOR_Y, 120.0 if absf(x - W / 2) < 400.0 else 100.0, 60.0)
	# ледяная глыба посередине
	var blk := Maps.make_destructible(Rect2(W / 2 - 60, FLOOR_Y - 80, 120, 80), 20.0, ICE, 70, 40.0)
	blk.anchored = true
	for cx in blk.cols:
		blk.anchors.append(Vector2i(cx, blk.rows - 1))
	world.add_child(blk)
	_weather(world, "snow")
	return _info(gates, glow, sp)

static func _icicles(world: Node, at: Vector2, w: float) -> void:
	var ic := FarBits.IcicleCluster.new()
	ic.position = at
	ic.width = w
	ic.count = int(w / 36.0)
	ic.land_y = FLOOR_Y
	world.add_child(ic)

# Ледяной грот у стены: отсюда выходят враги
static func _ice_cave(world: Node, base: Vector2) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	var rock := Polygon2D.new()
	rock.polygon = PackedVector2Array([Vector2(-110, 0), Vector2(-95, -140), Vector2(-60, -230), Vector2(-10, -260), Vector2(50, -240),
			Vector2(90, -170), Vector2(110, 0)])
	rock.color = ICE_WALL.darkened(0.1)
	g.add_child(rock)
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-58, 0), Vector2(-52, -95), Vector2(-25, -140), Vector2(20, -138), Vector2(50, -96), Vector2(58, 0)])
	hole.color = Color(0.05, 0.08, 0.16)
	g.add_child(hole)
	for k in 7:                                           # сосульки над входом
		var ic := Polygon2D.new()
		var x := -48.0 + k * 16.0
		var y := -128.0 + absf(x) * 0.6
		ic.polygon = PackedVector2Array([Vector2(x - 5, y), Vector2(x + 5, y), Vector2(x, y + randf_range(16, 30))])
		ic.color = Color(0.82, 0.94, 1.0)
		g.add_child(ic)
	var snow := Polygon2D.new()
	snow.polygon = PackedVector2Array([Vector2(-100, -150), Vector2(-60, -236), Vector2(-10, -266), Vector2(50, -246), Vector2(40, -232),
			Vector2(-10, -248), Vector2(-56, -222), Vector2(-90, -150)])
	snow.color = Color(0.95, 0.97, 1.0)
	g.add_child(snow)
	world.add_child(g)

static func _ice_crystal(world: Node, glow: CanvasLayer, base: Vector2, hgt: float) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -6
	for k in 3:
		var sh := Polygon2D.new()
		var hh := hgt * (1.0 - k * 0.25)
		var x := (k - 1) * 16.0
		sh.polygon = PackedVector2Array([Vector2(x - 10, 0), Vector2(x - 6, -hh * 0.8), Vector2(x, -hh), Vector2(x + 6, -hh * 0.8), Vector2(x + 10, 0)])
		sh.color = Color(0.55, 0.85, 1.0, 0.9).lightened(k * 0.1)
		sh.rotation = (k - 1) * 0.18
		g.add_child(sh)
		var ln := Line2D.new()
		ln.points = PackedVector2Array([Vector2(x - 4, -4), Vector2(x - 2, -hh * 0.75)])
		ln.width = 2.0
		ln.default_color = Color(1, 1, 1, 0.7)
		ln.rotation = sh.rotation
		g.add_child(ln)
	world.add_child(g)
	var gl := Torch.make_glow(hgt * 2.6, Color(0.45, 0.85, 1.0, 0.8))
	gl.position = base + Vector2(0, -hgt * 0.5)
	glow.add_child(gl)

# ======================= 13 — Храм шторма =======================
static func _storm(world: Node) -> Dictionary:
	_backdrop(world, FarArt.storm_backdrop(W, FLOOR_Y))
	_frame(world, TEMPLE_FLOOR, TEMPLE_FLOOR.lightened(0.12), TEMPLE.darkened(0.15))
	# лужи на мокрых плитах (блестят от вспышек)
	for x in range(150, int(W) - 100, 230):
		var pd := Polygon2D.new()
		var hw := randf_range(30, 70)
		pd.polygon = PackedVector2Array([Vector2(-hw, 1), Vector2(hw, 1), Vector2(hw * 0.8, 4), Vector2(-hw * 0.8, 4)])
		pd.color = Color(0.55, 0.62, 0.75, 0.55)
		pd.position = Vector2(x + randf_range(-40, 40), FLOOR_Y)
		pd.z_index = 1
		world.add_child(pd)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	for g in gates:
		_temple_door(world, g)
	# колонны храма на заднем плане (сквозь них проходят)
	for x in [300.0, 760.0, 1060.0, 1540.0, 1840.0, 2300.0]:
		_column(world, x, 360.0)
	var glow := _glow_layer(world, Color(0.72, 0.76, 0.88))
	# жаровни с голубым огнём
	for x in [600.0, W - 600.0]:
		_brazier(world, glow, Vector2(x, FLOOR_Y), Color(0.55, 0.8, 1.0))
	var sp: Array = []
	_layout(world, TEMPLE, sp)
	# обломки колонн — разрушаемые укрытия
	for x in [470.0 + 300.0, W - 470.0 - 300.0]:
		var d := Maps.make_destructible(Rect2(x - 30, FLOOR_Y - 100, 60, 100), 20.0, TEMPLE, 70, 45.0)
		d.anchored = true
		for cx in d.cols:
			d.anchors.append(Vector2i(cx, d.rows - 1))
		d.cells.clear()
		for cx in d.cols:
			for cy in d.rows:
				if cy == 0 and cx == 2:
					continue                              # отколотый верх
				d.cells[Vector2i(cx, cy)] = d.cell_hp
		world.add_child(d)
	# громоотводы: копят заряд и бьют молнией вокруг себя
	var rods: Array = []
	for x in [640.0, W / 2 - 360.0, W / 2 + 360.0, W - 640.0]:
		var rod := FarBits.LightningRod.new()
		rod.position = Vector2(x, FLOOR_Y)
		world.add_child(rod)
		rods.append(rod)
	var wth := _weather(world, "rain", true)
	var wg := FarBits.WindGusts.new()
	wg.weather = wth
	world.add_child(wg)
	var info := _info(gates, glow, sp)
	info["rods"] = rods
	info["wind"] = wg
	return info

static func _column(world: Node, x: float, hgt: float) -> void:
	var g := Node2D.new()
	g.position = Vector2(x, FLOOR_Y)
	g.z_index = -6
	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([Vector2(-22, 0), Vector2(-20, -hgt), Vector2(20, -hgt), Vector2(22, 0)])
	Tex.apply(shaft, "stone", TEMPLE)
	g.add_child(shaft)
	for k in 4:                                           # каннелюры
		var fl := Line2D.new()
		fl.points = PackedVector2Array([Vector2(-12 + k * 8, -6), Vector2(-11 + k * 8, -hgt + 10)])
		fl.width = 2.0
		fl.default_color = TEMPLE.darkened(0.25)
		g.add_child(fl)
	for y in [0.0, -hgt]:
		var cap := Polygon2D.new()
		cap.polygon = PackedVector2Array([Vector2(-32, y), Vector2(32, y), Vector2(28, y - 14 if y < 0.0 else y - 12), Vector2(-28, y - 14 if y < 0.0 else y - 12)])
		cap.color = TEMPLE.lightened(0.08)
		g.add_child(cap)
	world.add_child(g)

static func _temple_door(world: Node, base: Vector2) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([Vector2(-95, 0), Vector2(-95, -210), Vector2(0, -270), Vector2(95, -210), Vector2(95, 0)])
	Tex.apply(frame, "stone", TEMPLE.lightened(0.05))
	g.add_child(frame)
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-60, 0), Vector2(-60, -170), Vector2(0, -205), Vector2(60, -170), Vector2(60, 0)])
	hole.color = Color(0.04, 0.05, 0.08)
	g.add_child(hole)
	for s in [-1.0, 1.0]:                                  # распахнутые бронзовые створки
		var door := Polygon2D.new()
		door.polygon = PackedVector2Array([Vector2(s * 60, 0), Vector2(s * 60, -170), Vector2(s * 82, -160), Vector2(s * 82, 6)])
		door.color = Color(0.55, 0.40, 0.22)
		g.add_child(door)
	var orb := Polygon2D.new()                             # знак молнии над входом
	orb.polygon = PackedVector2Array([Vector2(-6, -250), Vector2(4, -250), Vector2(-1, -238), Vector2(7, -238), Vector2(-6, -218), Vector2(-1, -232), Vector2(-8, -232)])
	orb.color = Color(0.75, 0.88, 1.0)
	g.add_child(orb)
	world.add_child(g)

static func _brazier(world: Node, glow: CanvasLayer, base: Vector2, fire_c: Color) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -3
	var bowl := Polygon2D.new()
	bowl.polygon = PackedVector2Array([Vector2(-24, -52), Vector2(24, -52), Vector2(12, -32), Vector2(6, 0), Vector2(-6, 0), Vector2(-12, -32)])
	bowl.color = Color(0.25, 0.23, 0.28)
	g.add_child(bowl)
	var fire := Polygon2D.new()
	fire.polygon = PackedVector2Array([Vector2(-18, -52), Vector2(-8, -80), Vector2(0, -98), Vector2(8, -78), Vector2(18, -52)])
	fire.color = fire_c
	g.add_child(fire)
	var tw := fire.create_tween().set_loops()
	tw.tween_property(fire, "scale", Vector2(1.08, 0.9), 0.18)
	tw.tween_property(fire, "scale", Vector2(0.94, 1.08), 0.2)
	world.add_child(g)
	var gl := Torch.make_glow(280.0, Color(fire_c, 0.7))
	gl.position = base + Vector2(0, -64)
	glow.add_child(gl)

# ======================= 14 — Лавовые просторы =======================
static func _lava(world: Node) -> Dictionary:
	_backdrop(world, FarArt.lava_backdrop(W, FLOOR_Y))
	_frame(world, BASALT, BASALT.lightened(0.10), OBSIDIAN)
	# тлеющие трещины на полу
	for x in range(60, int(W) - 40, 110):
		var cr := Line2D.new()
		var x0 := x + randf_range(-30, 30)
		cr.points = PackedVector2Array([Vector2(x0, FLOOR_Y + 2), Vector2(x0 + 14, FLOOR_Y + 6), Vector2(x0 + 30, FLOOR_Y + 4), Vector2(x0 + 44, FLOOR_Y + 9)])
		cr.width = 2.0
		cr.default_color = Color(1.0, 0.45, 0.12, 0.85)
		cr.z_index = 1
		world.add_child(cr)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	for g in gates:
		_lava_cave(world, g)
	# каменные арки на ближнем плане
	for x in [820.0, W - 820.0]:
		_arch(world, x, 300.0, 420.0)
	var glow := _glow_layer(world, Color(1.0, 0.84, 0.78))
	var sp: Array = []
	_layout(world, BASALT, sp)
	# лавовые озёра — обжигают и подбрасывают
	# (середина свободна: там герои появляются и возрождаются)
	for pd in [[640.0, 220.0], [W / 2 - 330.0, 190.0], [W / 2 + 330.0, 190.0], [W - 640.0, 220.0]]:
		var lp := FarBits.LavaPool.new()
		lp.width = pd[1]
		lp.glow_layer = glow
		lp.position = Vector2(pd[0], FLOOR_Y)
		world.add_child(lp)
	# обсидиановые шипы — укрытия
	for x in [470.0 + 300.0 + 120.0, 470.0 - 230.0, W - 470.0 - 300.0 - 120.0, W - 470.0 + 230.0]:
		_obsidian(world, x)
	# вулкан плюётся бомбами
	var vb := FarBits.VolcanoBombs.new()
	vb.map_w = W
	vb.floor_y = FLOOR_Y
	world.add_child(vb)
	_weather(world, "soot")
	return _info(gates, glow, sp)

static func _obsidian(world: Node, x: float) -> void:
	var d := Maps.make_destructible(Rect2(x - 40, FLOOR_Y - 120, 80, 120), 20.0, OBSIDIAN, 80, 50.0)
	d.anchored = true
	d.mat_kind = "darkrock"
	for cx in d.cols:
		var k := 1.0 - absf((cx + 0.5) / d.cols - 0.5) * 2.0
		var top := int(round((1.0 - k) * (d.rows - 2)))
		for cy in range(top, d.rows):
			d.cells[Vector2i(cx, cy)] = d.cell_hp
			if cy == d.rows - 1:
				d.anchors.append(Vector2i(cx, cy))
	world.add_child(d)

static func _arch(world: Node, x: float, aw: float, ah: float) -> void:
	var g := Node2D.new()
	g.position = Vector2(x, FLOOR_Y)
	g.z_index = -7
	var pts := PackedVector2Array()
	var inner := PackedVector2Array()
	for i in 25:
		var a := PI * i / 24.0
		pts.append(Vector2(cos(a) * aw / 2.0 + cos(a) * 36.0, -sin(a) * (ah + 36.0)))
		inner.append(Vector2(cos(a) * aw / 2.0, -sin(a) * ah))
	inner.reverse()
	var poly := pts + inner
	var arch := Polygon2D.new()
	arch.polygon = poly
	Tex.apply(arch, "darkrock", BASALT.lightened(0.04))
	g.add_child(arch)
	for k in 6:                                           # тлеющие жилы в камне
		var a2 := randf_range(0.2, PI - 0.2)
		var vein := Line2D.new()
		var r0 := aw / 2.0 + 6.0
		vein.points = PackedVector2Array([Vector2(cos(a2), -sin(a2) * ah / (aw / 2.0)) * r0,
				Vector2(cos(a2 + 0.08), -sin(a2 + 0.08) * ah / (aw / 2.0)) * (r0 + 22.0)])
		vein.width = 2.0
		vein.default_color = Color(1.0, 0.45, 0.12, 0.8)
		g.add_child(vein)
	world.add_child(g)

static func _lava_cave(world: Node, base: Vector2) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	var rock := Polygon2D.new()
	rock.polygon = PackedVector2Array([Vector2(-110, 0), Vector2(-100, -150), Vector2(-50, -240), Vector2(20, -250), Vector2(80, -190), Vector2(110, 0)])
	Tex.apply(rock, "darkrock", OBSIDIAN.lightened(0.05))
	g.add_child(rock)
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-58, 0), Vector2(-50, -100), Vector2(-20, -145), Vector2(25, -140), Vector2(52, -96), Vector2(58, 0)])
	hole.color = Color(0.35, 0.08, 0.04)
	g.add_child(hole)
	var core := Polygon2D.new()
	core.polygon = PackedVector2Array([Vector2(-36, 0), Vector2(-30, -60), Vector2(0, -90), Vector2(30, -60), Vector2(36, 0)])
	core.color = Color(0.85, 0.30, 0.08, 0.8)
	g.add_child(core)
	world.add_child(g)

# ======================= 15 — Тронный зал Тёмного лорда =======================
static func _throne(world: Node) -> Dictionary:
	_backdrop(world, FarArt.throne_backdrop(W, FLOOR_Y))
	_frame(world, HALL_FLOOR, HALL_FLOOR.lightened(0.16), HALL.darkened(0.2))
	# красная ковровая дорожка к трону
	var carpet := Polygon2D.new()
	carpet.polygon = PackedVector2Array([Vector2(W / 2 - 420, FLOOR_Y + 1), Vector2(W / 2 + 420, FLOOR_Y + 1), Vector2(W / 2 + 430, FLOOR_Y + 7), Vector2(W / 2 - 430, FLOOR_Y + 7)])
	carpet.color = Color(0.45, 0.06, 0.08)
	carpet.z_index = 1
	world.add_child(carpet)
	var trim := Line2D.new()
	trim.points = PackedVector2Array([Vector2(W / 2 - 420, FLOOR_Y + 2), Vector2(W / 2 + 420, FLOOR_Y + 2)])
	trim.width = 2.0
	trim.default_color = Color(0.85, 0.65, 0.25)
	trim.z_index = 1
	world.add_child(trim)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	for g in gates:
		_castle_door(world, g)
	var glow := _glow_layer(world, Color(0.72, 0.60, 0.66))
	# жаровни с багровым огнём
	for x in [330.0, 1000.0, 1600.0, W - 330.0]:
		_brazier(world, glow, Vector2(x, FLOOR_Y), Color(1.0, 0.35, 0.15))
	# колонны зала (сквозь них проходят)
	for x in [600.0, 1180.0, 1420.0, 2000.0]:
		_hall_column(world, glow, x)
	var sp: Array = []
	_layout(world, HALL, sp)
	# решётки с пламенем бездны
	for x in [780.0, W - 780.0]:
		var ag := FarBits.AbyssGrate.new()
		ag.position = Vector2(x, FLOOR_Y)
		world.add_child(ag)
	# люстры над залом
	for x in [880.0, W / 2, W - 880.0]:
		var ch := FarBits.Chandelier.new()
		ch.position = Vector2(x, 0.0)
		ch.hang = 300.0 if x != W / 2 else 250.0
		ch.floor_y = FLOOR_Y
		ch.glow_layer = glow
		world.add_child(ch)
	# горгульи на уступах (украшение)
	for x in [470.0 + 30.0, W - 470.0 - 30.0]:
		_gargoyle_statue(world, Vector2(x + 50.0 * (1 if x < W / 2 else -1), FLOOR_Y - STEP * 3 + 1))
	_weather(world, "embers")
	return _info(gates, glow, sp)

# ======================= 16 — Вершина цитадели =======================
const CITADEL_NAME := "Вершина цитадели"
# Площадки для третьей фазы: с них достаёшь до головы Воплощения Тьмы
const CITADEL_PLATS := [Rect2(820, FLOOR_Y - 150, 180, 18), Rect2(1600, FLOOR_Y - 150, 180, 18),
		Rect2(1040, FLOOR_Y - 290, 170, 18), Rect2(1390, FLOOR_Y - 290, 170, 18)]

static func citadel(world: Node) -> Dictionary:
	_backdrop(world, FarArt.citadel_backdrop(W, FLOOR_Y))
	_frame(world, BASALT, HALL_FLOOR.lightened(0.20), HALL.darkened(0.2))
	# плиты стены: швы и тлеющие трещины
	for x in range(60, int(W), 140):
		var seam := Line2D.new()
		seam.points = PackedVector2Array([Vector2(x, FLOOR_Y + 2), Vector2(x + 6, FLOOR_Y + 40)])
		seam.width = 2.0
		seam.default_color = Color(0.06, 0.04, 0.05)
		seam.z_index = 1
		world.add_child(seam)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	for g in gates:
		_castle_door(world, g)
	var glow := _glow_layer(world, Color(0.80, 0.60, 0.60))
	for x in [300.0, 940.0, 1660.0, W - 300.0]:
		_brazier(world, glow, Vector2(x, FLOOR_Y), Color(1.0, 0.35, 0.15))
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(640, FLOOR_Y), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - 640, FLOOR_Y), "heal"))
	for r: Rect2 in CITADEL_PLATS:
		_plat(world, r, HALL)
	for side in [1.0, -1.0]:
		var x0: float = 310.0 if side > 0 else W - 310.0
		_plat(world, Rect2(x0 - 110, FLOOR_Y - 140, 220, 18), HALL)
		sp.append(Colosseum._ledge(world, x0, STEP * 2 + 40, 150.0))
		_gargoyle_statue(world, Vector2(x0 - 70.0 * side, FLOOR_Y - 140))
	_weather(world, "embers")
	return _info(gates, glow, sp)

static func _hall_column(world: Node, glow: CanvasLayer, x: float) -> void:
	var g := Node2D.new()
	g.position = Vector2(x, FLOOR_Y)
	g.z_index = -6
	var shaft := Polygon2D.new()
	shaft.polygon = PackedVector2Array([Vector2(-26, 0), Vector2(-24, -700), Vector2(24, -700), Vector2(26, 0)])
	Tex.apply(shaft, "darkrock", OBSIDIAN.lightened(0.06))
	g.add_child(shaft)
	var vein := Line2D.new()
	var pts := PackedVector2Array()
	var vx := randf_range(-8, 8)
	for y in range(0, -700, -35):
		vx = clampf(vx + randf_range(-6, 6), -16, 16)
		pts.append(Vector2(vx, y))
	vein.points = pts
	vein.width = 3.0
	vein.default_color = Color(1.0, 0.35, 0.10, 0.85)
	g.add_child(vein)
	var base := Polygon2D.new()
	base.polygon = PackedVector2Array([Vector2(-36, 0), Vector2(36, 0), Vector2(30, -18), Vector2(-30, -18)])
	base.color = HALL.lightened(0.05)
	g.add_child(base)
	world.add_child(g)

static func _castle_door(world: Node, base: Vector2) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([Vector2(-100, 0), Vector2(-100, -200), Vector2(-60, -260), Vector2(0, -285), Vector2(60, -260), Vector2(100, -200), Vector2(100, 0)])
	Tex.apply(frame, "stone", HALL.lightened(0.04))
	g.add_child(frame)
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-64, 0), Vector2(-64, -170), Vector2(-30, -215), Vector2(0, -225), Vector2(30, -215), Vector2(64, -170), Vector2(64, 0)])
	hole.color = Color(0.04, 0.02, 0.03)
	g.add_child(hole)
	for k in 5:                                           # поднятая решётка-герса
		var bar := Line2D.new()
		bar.points = PackedVector2Array([Vector2(-48 + k * 24, -180), Vector2(-48 + k * 24, -224 + absf(k - 2) * 8)])
		bar.width = 4.0
		bar.default_color = Color(0.22, 0.20, 0.22)
		g.add_child(bar)
	var eye := Polygon2D.new()                             # тлеющий знак над дверью
	eye.polygon = PackedVector2Array([Vector2(-12, -248), Vector2(0, -256), Vector2(12, -248), Vector2(0, -242)])
	eye.color = Color(1.0, 0.35, 0.12)
	g.add_child(eye)
	world.add_child(g)

static func _gargoyle_statue(world: Node, at: Vector2) -> void:
	var g := Node2D.new()
	g.position = at
	g.z_index = -2
	var c := Color(0.30, 0.27, 0.30)
	var body := Polygon2D.new()
	body.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(-16, -22), Vector2(-8, -34), Vector2(-4, -46), Vector2(4, -46), Vector2(8, -34),
			Vector2(16, -22), Vector2(14, 0)])
	body.color = c
	g.add_child(body)
	for s in [-1.0, 1.0]:
		var wing := Polygon2D.new()
		wing.polygon = PackedVector2Array([Vector2(s * 10, -30), Vector2(s * 34, -52), Vector2(s * 30, -30), Vector2(s * 38, -22), Vector2(s * 14, -18)])
		wing.color = c.darkened(0.15)
		g.add_child(wing)
		var horn := Polygon2D.new()
		horn.polygon = PackedVector2Array([Vector2(s * 3, -46), Vector2(s * 9, -58), Vector2(s * 6, -44)])
		horn.color = c.lightened(0.1)
		g.add_child(horn)
	var eyes := Polygon2D.new()
	eyes.polygon = PackedVector2Array([Vector2(-5, -40), Vector2(-2, -40), Vector2(-2, -38), Vector2(-5, -38)])
	eyes.color = Color(1.0, 0.3, 0.1)
	g.add_child(eyes)
	world.add_child(g)
