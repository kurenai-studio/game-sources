class_name ForestTrail
# ---------- Арена «Лесная тропа» (волны 1–5) ----------
# Тропа в лесу среди деревьев. По краям — огромные стволы, пол — утоптанная земля
# с травой по краям. Приспешники Тёмного лорда выходят из чащи (тёмные прогалы
# в кустах). На поле: поваленное бревно (горит!), пни, камни, мостки на ветвях
# и деревья на заднем плане, сквозь которые можно проходить. Слева — домик на
# дереве: по веткам-ступенькам можно забраться внутрь, к алтарю баффов.

const W := Colosseum.W
const H := Colosseum.H
const FLOOR_Y := Colosseum.FLOOR_Y
const WALL := Colosseum.WALL
const STEP := Colosseum.STEP
const DIRT := Color(0.46, 0.34, 0.22)
const PATH := Color(0.58, 0.46, 0.32)
const GRASS := Color(0.34, 0.58, 0.26)
const BARK := Color(0.36, 0.26, 0.17)
const WOOD := Color(0.55, 0.40, 0.24)

static func build(world: Node) -> Dictionary:
	var bg := PixelArt.make_sprite(LandArt.forest_backdrop(W, FLOOR_Y), PixelArt.SCALE)
	bg.z_index = -10
	world.add_child(bg)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, H - FLOOR_Y + 40), DIRT)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, 10), PATH)
	# трава по краям тропы
	for x in range(0, int(W), 14):
		if x < 520 or x > W - 520 or (x / 14) % 5 == 0:
			var g := Polygon2D.new()
			var hh := 6.0 + float((x * 7) % 9)
			g.polygon = PackedVector2Array([Vector2(x, FLOOR_Y + 2), Vector2(x + 4, FLOOR_Y - hh), Vector2(x + 7, FLOOR_Y + 2),
					Vector2(x + 10, FLOOR_Y - hh * 0.7), Vector2(x + 13, FLOOR_Y + 2)])
			g.color = GRASS if (x / 14) % 2 == 0 else GRASS.darkened(0.15)
			g.z_index = 1
			world.add_child(g)
	# стены — огромные стволы с корнями
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
		_thicket(world, g)
	# мягкие лучи солнца
	var glow_layer := CanvasLayer.new()
	glow_layer.layer = 1
	glow_layer.follow_viewport_enabled = true
	world.add_child(glow_layer)
	for x in [420.0, 1150.0, 1800.0, 2350.0]:
		var ray := Polygon2D.new()
		ray.polygon = PackedVector2Array([Vector2(x - 40, -40), Vector2(x + 30, -40), Vector2(x + 260, FLOOR_Y), Vector2(x + 110, FLOOR_Y)])
		ray.color = Color(1.0, 0.95, 0.7, 0.07)
		glow_layer.add_child(ray)
	# пыльца в лучах
	for i in 22:
		var f := Torch.make_glow(18.0, Color(1.0, 0.95, 0.6, 0.6))
		f.position = Vector2(randf_range(100, W - 100), randf_range(FLOOR_Y - 600, FLOOR_Y - 40))
		glow_layer.add_child(f)
		var tw := f.create_tween().set_loops()
		tw.tween_property(f, "position", f.position + Vector2(randf_range(-50, 50), randf_range(-30, 30)), randf_range(3.0, 5.0))
		tw.tween_property(f, "position", f.position, randf_range(3.0, 5.0))
	var sp := _obstacles(world)
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": null, "floor": FLOOR_Y, "spawners": sp, "totems": []}

# Тёмный прогал в чаще, из которого выходят враги
static func _thicket(world: Node, base: Vector2) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	for k in 9:
		var b := Polygon2D.new()
		b.polygon = Util.circle(48.0 + (k % 3) * 10.0, 14)
		b.color = Color(0.20, 0.36, 0.20).lightened(0.05 * (k % 3))
		b.position = Vector2(-90 + k * 22, -60 - absf(k - 4) * -6.0 - 70.0 + (k % 2) * 16.0)
		g.add_child(b)
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-55, 0), Vector2(-50, -90), Vector2(-20, -125), Vector2(22, -122),
			Vector2(50, -88), Vector2(55, 0)])
	hole.color = Color(0.05, 0.07, 0.05)
	g.add_child(hole)
	for k in 5:                      # ветки свисают в проход
		var br := Line2D.new()
		br.points = PackedVector2Array([Vector2(-40 + k * 20, -120), Vector2(-46 + k * 21, -80 + (k % 2) * 10)])
		br.width = 3.0
		br.default_color = Color(0.25, 0.18, 0.12)
		g.add_child(br)
	world.add_child(g)

# Мостки на ветвях: неразрушаемые, деревянные, снизу пропрыгнуть
static func wood_plat(world: Node, rect: Rect2, tint := WOOD) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Layer.WORLD | Layer.FRAME
	body.position = rect.get_center()
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	col.shape = rs
	col.one_way_collision = true
	body.add_child(col)
	body.add_child(Tex.slab(rect.size, "mine_wood", tint, int(rect.position.x * 7 + rect.position.y)))
	for sx in [-rect.size.x / 2 + 10, rect.size.x / 2 - 14]:     # верёвки-подвесы
		var rope := ColorRect.new()
		rope.color = Color(0.62, 0.52, 0.34)
		rope.size = Vector2(3, 60)
		rope.position = Vector2(sx, -rect.size.y / 2 - 60)
		rope.z_index = -1
		body.add_child(rope)
	world.add_child(body)

# Пенёк: держится за землю, горит
static func _stump(world: Node, x: float, h: float) -> void:
	var d := Maps.make_destructible(Rect2(x - 30, FLOOR_Y - h, 60, h), 20.0, WOOD.darkened(0.1), 60, 30.0)
	d.flammable = true
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
		d.cell_colors[Vector2i(cx, 0)] = Color(0.75, 0.62, 0.42)     # спил сверху
	world.add_child(d)

static func _obstacles(world: Node) -> Array:
	var f := FLOOR_Y
	var c := W / 2
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, f), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, f), "heal"))
	# деревья на заднем плане (сквозь них проходят, но они горят и падают)
	for x in [600.0, 1120.0, W - 1080.0, W - 640.0]:
		Maps.add_tree(world, x, f)
	for side in [1.0, -1.0]:
		var x0: float = 480.0 if side > 0 else W - 480.0
		wood_plat(world, Rect2(x0 - 130, f - STEP, 260, 20))
		wood_plat(world, Rect2(x0 - 90 + side * 120, f - STEP * 2, 200, 20))
		sp.append(Colosseum._ledge(world, x0 + side * 20, STEP * 3, 160.0))
		_stump(world, x0 + side * 320, 60.0)
		Jungle._rock(world, Rect2(x0 - side * 230 - 30, f - 40, 60, 40))
	Jungle._log(world, Rect2(c - 150, f - 50, 300, 50))
	for side in [1.0, -1.0]:
		wood_plat(world, Rect2(c + side * 300 - 100, f - STEP * 2, 200, 20))
	wood_plat(world, Rect2(c - 120, f - STEP * 3, 240, 20))
	sp.append(Colosseum._ledge(world, c, STEP * 4, 160.0))
	# домик на дереве: по веткам-ступенькам наверх, внутри — алтарь (бафф часто сразу МЕГА)
	sp.append(Props.tree_house(world, 860.0, f, false))
	Maps.add_crate(world, Vector2(W - 900.0, f - 31))
	Props.dead_stump(world, W - 1080.0, f, false)
	return sp
