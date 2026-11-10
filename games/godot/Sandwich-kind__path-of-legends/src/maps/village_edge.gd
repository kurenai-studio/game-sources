class_name VillageEdge
# ---------- Арена «Окраина деревни» (волны 6–10) ----------
# Поле днём у края деревни: сама деревня — на пригорке вдали, из труб идёт дым
# (на неё напали бандиты). Бой идёт на поле: стога сена (горят),
# плетни, телега, колодец, сторожевая вышка. Слева — частокол деревни с
# воротами, справа — опушка леса: бандиты лезут с обеих сторон.

const W := Colosseum.W
const H := Colosseum.H
const FLOOR_Y := Colosseum.FLOOR_Y
const WALL := Colosseum.WALL
const STEP := Colosseum.STEP
const SOIL := Color(0.44, 0.33, 0.20)
const GRASS := Color(0.48, 0.60, 0.28)
const HAY := Color(0.86, 0.72, 0.36)
const WOOD := Color(0.52, 0.38, 0.22)
const STONE := Color(0.55, 0.53, 0.50)

static func build(world: Node) -> Dictionary:
	var img := LandArt.village_backdrop(W, FLOOR_Y)
	var bg := PixelArt.make_sprite(img, PixelArt.SCALE)
	bg.z_index = -10
	world.add_child(bg)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, H - FLOOR_Y + 40), SOIL)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, 10), GRASS)
	# стены: слева частокол деревни, справа огромный ствол на опушке
	Maps.add_block(world, Rect2(0, -800, WALL, H + 800), WOOD.darkened(0.2))
	for k in 5:
		var stake := Polygon2D.new()
		var sx := 6.0 + k * 12.0
		stake.polygon = PackedVector2Array([Vector2(sx, FLOOR_Y), Vector2(sx, FLOOR_Y - 360), Vector2(sx + 5, FLOOR_Y - 380),
				Vector2(sx + 10, FLOOR_Y - 360), Vector2(sx + 10, FLOOR_Y)])
		stake.color = WOOD.darkened(0.05 * (k % 2))
		stake.z_index = 1
		world.add_child(stake)
	Maps.add_block(world, Rect2(W - WALL, -800, WALL, H + 800), Jungle.BARK)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	_gate(world, gates[0])
	ForestTrail._thicket(world, gates[1])
	# фонари на столбах — днём не горят
	for x in [380.0, 1300.0, W - 380.0]:
		var t := Torch.new()
		t.position = Vector2(x, FLOOR_Y - 260.0)
		t.lit = false
		world.add_child(t)
	var sp := _obstacles(world)
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": null, "floor": FLOOR_Y, "spawners": sp, "totems": []}

# Ворота в частоколе: из них выбегают бандиты, уже побывавшие в деревне
static func _gate(world: Node, base: Vector2) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([Vector2(-80, 0), Vector2(-80, -170), Vector2(80, -170), Vector2(80, 0)])
	Tex.apply(frame, "mine_wood", WOOD)
	g.add_child(frame)
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-58, 0), Vector2(-58, -140), Vector2(58, -140), Vector2(58, 0)])
	hole.color = Color(0.10, 0.07, 0.05)
	g.add_child(hole)
	var door := Polygon2D.new()            # створка выбита и висит набок
	door.polygon = PackedVector2Array([Vector2(30, 0), Vector2(56, -6), Vector2(70, -138), Vector2(44, -132)])
	door.color = WOOD.darkened(0.15)
	g.add_child(door)
	var top := ColorRect.new()
	top.color = WOOD.darkened(0.3)
	top.position = Vector2(-92, -186)
	top.size = Vector2(184, 18)
	g.add_child(top)
	world.add_child(g)

# Стог сена: мягкий, горит
static func _hay(world: Node, x: float, w: float, h: float) -> void:
	var d := Maps.make_destructible(Rect2(x - w / 2, FLOOR_Y - h, w, h), 20.0, HAY, 30, 15.0)
	d.flammable = true
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	for cx in d.cols:
		for cy in d.rows:
			if (cx + cy * 2) % 5 == 0:
				d.cell_colors[Vector2i(cx, cy)] = HAY.darkened(0.15)
	world.add_child(d)

# Плетень: тонкий, ломается легко
static func _fence(world: Node, x: float, w: float) -> void:
	var d := Maps.make_destructible(Rect2(x - w / 2, FLOOR_Y - 60, w, 60), 20.0, WOOD, 20, 10.0)
	d.flammable = true
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	world.add_child(d)

# Колодец: каменный сруб, прочный
static func _well(world: Node, x: float) -> void:
	var d := Maps.make_destructible(Rect2(x - 50, FLOOR_Y - 60, 100, 60), 20.0, STONE, 90, 45.0)
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	world.add_child(d)
	for sx in [-46.0, 40.0]:                 # стойки и крыша колодца (фон)
		var post := ColorRect.new()
		post.color = WOOD.darkened(0.2)
		post.position = Vector2(x + sx, FLOOR_Y - 150)
		post.size = Vector2(6, 90)
		post.z_index = -3
		world.add_child(post)
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(x - 66, FLOOR_Y - 146), Vector2(x, FLOOR_Y - 190), Vector2(x + 66, FLOOR_Y - 146)])
	roof.color = Color(0.55, 0.28, 0.20)
	roof.z_index = -3
	world.add_child(roof)

# Телега: деревянная, колёса на фоне
static func _cart(world: Node, x: float) -> void:
	var d := Maps.make_destructible(Rect2(x - 80, FLOOR_Y - 80, 160, 40), 20.0, WOOD, 45, 25.0)
	d.flammable = true
	d.anchored = true
	for cx in [1, d.cols - 2]:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	world.add_child(d)
	for wx in [x - 50.0, x + 50.0]:
		var wheel := Line2D.new()
		var pts := Util.circle(22.0, 16)
		pts.append(pts[0])
		wheel.points = pts
		wheel.width = 5.0
		wheel.default_color = WOOD.darkened(0.3)
		wheel.position = Vector2(wx, FLOOR_Y - 22)
		wheel.z_index = -2
		world.add_child(wheel)
		for k in 4:
			var spoke := Line2D.new()
			spoke.points = PackedVector2Array([Vector2.ZERO, Vector2.from_angle(k * PI / 4) * 22.0])
			spoke.width = 2.0
			spoke.default_color = WOOD.darkened(0.3)
			wheel.add_child(spoke)

static func _obstacles(world: Node) -> Array:
	var f := FLOOR_Y
	var c := W / 2
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, f), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, f), "heal"))
	# стога и плетни по бокам, мостки-навесы над ними
	for side in [1.0, -1.0]:
		var x0: float = 500.0 if side > 0 else W - 500.0
		_hay(world, x0 - side * 160.0, 100.0, 80.0)
		_fence(world, x0 + side * 260.0, 120.0)
		ForestTrail.wood_plat(world, Rect2(x0 - 130, f - STEP, 260, 20))
		ForestTrail.wood_plat(world, Rect2(x0 - 100 + side * 120, f - STEP * 2, 200, 20))
		sp.append(Colosseum._ledge(world, x0 + side * 20, STEP * 3, 160.0))
	_well(world, c - 340.0)
	_cart(world, c + 330.0)
	_hay(world, c, 120.0, 60.0)
	# сторожевая вышка в центре
	for sx in [-110.0, 100.0]:
		var post := Maps.make_destructible(Rect2(c + sx, f - STEP * 2, 20, STEP * 2), 20.0, WOOD.darkened(0.1), 70, 30.0)
		post.anchored = true
		post.anchors.append(Vector2i(0, post.rows - 1))
		world.add_child(post)
	ForestTrail.wood_plat(world, Rect2(c - 130, f - STEP * 2, 260, 20))
	ForestTrail.wood_plat(world, Rect2(c - 100, f - STEP * 3, 200, 20))
	sp.append(Colosseum._ledge(world, c, STEP * 4, 160.0))
	for x in [880.0, W - 880.0]:
		Maps.add_crate(world, Vector2(x, f - 31))
	return sp
