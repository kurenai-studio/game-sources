class_name Colosseum
# Колизей для режима «Арена». Стены и пол неразрушаемы, препятствия — ломаются.
# Механика: метательные плиты в полу швыряют встающих на них через арену
# или на верхний ярус. Вместо ящиков — амфоры и статуи.
# Четыре расстановки препятствий: каждые 5 волн арена перестраивается.
# Первые две — днём, последние две — ночью, при луне и факелах.

const W := 2600.0
const H := 1000.0
const FLOOR_Y := 940.0           # верх песка арены
const WALL := 70.0
const SAND := Color(0.80, 0.68, 0.46)
const WALL_STONE := Color(0.55, 0.47, 0.38)
const NIGHT_TINT := Color(0.40, 0.43, 0.64)

# Строит арену. Возвращает параметры: размер, центр, ворота, слой свечения.
static func build(world: Node, stage: int, night: bool) -> Dictionary:
	# фон
	var bg := PixelArt.make_sprite(PixelArt.colosseum_backdrop(W, FLOOR_Y, night), PixelArt.SCALE)
	bg.z_index = -10
	world.add_child(bg)
	# пол и стены
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, H - FLOOR_Y + 40), SAND)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, 8), SAND.darkened(0.15))
	Maps.add_block(world, Rect2(0, -800, WALL, H + 800), WALL_STONE)
	Maps.add_block(world, Rect2(W - WALL, -800, WALL, H + 800), WALL_STONE)
	# ворота, из которых выходят боты
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	var gate_nodes := []
	for g in gates:
		gate_nodes.append(_gate(world, g))

	# ночь: затемнение, слой света, луна и факелы
	var glow_layer: CanvasLayer = null
	if night:
		var cm := CanvasModulate.new()
		cm.color = NIGHT_TINT
		world.add_child(cm)
		glow_layer = CanvasLayer.new()
		glow_layer.layer = 1
		glow_layer.follow_viewport_enabled = true   # двигается вместе с камерой
		world.add_child(glow_layer)
		var moon := Polygon2D.new()
		moon.polygon = Util.circle(46.0, 32)
		moon.color = Color(1.0, 0.98, 0.88)
		moon.position = Vector2(W * 0.72, 120)
		glow_layer.add_child(moon)
		var shadow := Polygon2D.new()               # лунные пятна
		shadow.polygon = Util.circle(12.0, 16)
		shadow.color = Color(0.85, 0.85, 0.78)
		shadow.position = moon.position + Vector2(-14, -8)
		glow_layer.add_child(shadow)
		var mg := Torch.make_glow(420.0, Color(0.6, 0.7, 1.0, 0.7))
		mg.position = moon.position
		glow_layer.add_child(mg)
	for x in [420.0, 900.0, 1700.0, 2180.0]:
		_torch(world, Vector2(x, FLOOR_Y - 330), night, glow_layer)
	for g in gates:
		_torch(world, g + Vector2(-80 if g.x < W / 2 else 80, -175), night, glow_layer)

	var spawners := _obstacles(world, stage % 4)
	_mechanisms(world, stage % 4)
	return {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates, "gate_nodes": gate_nodes,
			"glow": glow_layer, "floor": FLOOR_Y, "spawners": spawners}

static func _torch(world: Node, pos: Vector2, lit: bool, glow_layer: CanvasLayer) -> void:
	var t := Torch.new()
	t.position = pos
	t.lit = lit
	t.glow_layer = glow_layer
	world.add_child(t)

# Ворота: тёмная арка с решёткой
static func _gate(world: Node, base: Vector2) -> Node2D:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	var arch := Polygon2D.new()
	var pts := PackedVector2Array([Vector2(-60, 0), Vector2(-60, -110)])
	for i in 13:
		var a := PI + PI * i / 12.0
		pts.append(Vector2(cos(a) * 60.0, -110.0 + sin(a) * 50.0))
	pts.append(Vector2(60, -110))
	pts.append(Vector2(60, 0))
	arch.polygon = pts
	arch.color = Color(0.12, 0.09, 0.08)
	g.add_child(arch)
	var stones := Polygon2D.new()          # каменная кладка вокруг арки
	var sp := PackedVector2Array([Vector2(-78, 0), Vector2(-78, -112)])
	for i in 13:
		var a2 := PI + PI * i / 12.0
		sp.append(Vector2(cos(a2) * 78.0, -112.0 + sin(a2) * 66.0))
	sp.append(Vector2(78, -112))
	sp.append(Vector2(78, 0))
	stones.polygon = sp
	Tex.apply(stones, "stone", WALL_STONE.darkened(0.1))
	g.add_child(stones)
	g.move_child(stones, 0)
	var bars := Node2D.new()          # решётка: поднимается, когда выходит босс
	bars.name = "Bars"
	g.add_child(bars)
	for x in range(-48, 49, 16):
		var bar := ColorRect.new()
		bar.color = Color(0.35, 0.33, 0.33)
		bar.position = Vector2(x - 2, -150)
		bar.size = Vector2(4, 150)
		bars.add_child(bar)
	var cross := ColorRect.new()
	cross.color = Color(0.3, 0.28, 0.28)
	cross.position = Vector2(-52, -90)
	cross.size = Vector2(104, 5)
	bars.add_child(cross)
	var frame := Line2D.new()
	var fp := PackedVector2Array()
	for p in pts:
		fp.append(p)
	frame.points = fp
	frame.width = 8.0
	frame.default_color = Color(0.62, 0.54, 0.44)
	g.add_child(frame)
	world.add_child(g)
	return g

# ---------- Расстановки препятствий ----------
# Платформы ярусами через 120 пикселей (обычный прыжок — около 155), сквозь них
# можно пропрыгнуть снизу. Наверху — каменные уступы с алтарями баффов.
# По краям арены — станции лечения. Середина пола свободна: там появляется игрок.
const STEP := 120.0
const LEDGE := Color(0.62, 0.56, 0.50)

static func _obstacles(world: Node, layout: int) -> Array:
	var f := FLOOR_Y
	var c := W / 2
	var sp: Array = []
	sp.append(_station(world, Vector2(WALL + 175, f), "heal"))
	sp.append(_station(world, Vector2(W - WALL - 175, f), "heal"))
	match layout:
		0:   # «Разминка»: три башни из платформ, сверху алтари
			for x in [500.0, W - 500.0]:
				_tower(world, x, 220.0, 2)
				sp.append(_ledge(world, x, STEP * 3, 160.0))
			_tower(world, c, 280.0, 3)
			sp.append(_ledge(world, c, STEP * 4, 160.0))
			for x in [790.0, W - 790.0]:
				Maps.add_column(world, Rect2(x - 20, f - 100, 40, 100))
			for x in [1120.0, W - 1120.0]:
				Props.amphora(world, x, f)
		1:   # «Руины»: лестницы с краёв к середине, низкие стены
			for side in [1.0, -1.0]:
				for k in 3:
					var x: float = 340.0 + k * 210.0
					if side < 0:
						x = W - x
					Colosseum.plat(world, Rect2(x - 100, f - STEP * (k + 1), 200, 20))
				sp.append(_ledge(world, 970.0 if side > 0 else W - 970.0, STEP * 4, 150.0))
			_tower(world, c, 300.0, 3)
			for x in [1100.0, W - 1160.0]:
				Maps.add_column(world, Rect2(x, f - 70, 60, 70))
			for x in [760.0, W - 760.0]:
				Props.amphora(world, x - 30.0, f)
				Props.amphora(world, x + 30.0, f)
		2:   # «Колоннада»: высокие колонны, мосты между ними (ночь)
			# колонны — на заднем плане: красиво, но не перегораживают дорогу
			for x in [520.0, 960.0, W - 960.0, W - 520.0]:
				_bg_column(world, Rect2(x - 20, f - 230, 40, 230))
			for side in [1.0, -1.0]:
				var x0: float = 540.0 if side > 0 else W - 940.0
				Colosseum.plat(world, Rect2(x0, f - STEP, 400, 20))
				Colosseum.plat(world, Rect2(x0 + 60, f - STEP * 2, 280, 20))
				sp.append(_ledge(world, x0 + 200, STEP * 3, 150.0))
			_tower(world, c, 260.0, 2)
			sp.append(_ledge(world, c, STEP * 3, 160.0))
			for x in [760.0, W - 760.0]:
				Props.statue(world, x, f)
		3:   # «Крепость»: два бункера, высокая середина (ночь)
			for side in [1.0, -1.0]:
				var x0: float = 520.0 if side > 0 else W - 520.0 - 240.0
				Maps.add_column(world, Rect2(x0, f - STEP, 40, STEP))
				Maps.add_column(world, Rect2(x0 + 200, f - STEP, 40, STEP))
				Colosseum.plat(world, Rect2(x0 - 20, f - STEP - 20, 280, 20))
				sp.append(_ledge(world, x0 + 120, STEP * 2, 140.0))
				Props.amphora(world, x0 + 120, f)
			_tower(world, c, 300.0, 3)
			sp.append(_ledge(world, c, STEP * 4, 160.0))
	return sp

# ---------- Механизмы арены: метательные плиты ----------
# Деревянные плиты на пружинах: кто на них встанет — герой или противник, —
# того швыряет по дуге в заданное место (стрелка над плитой показывает куда).
static func _mechanisms(world: Node, layout: int) -> void:
	var f := FLOOR_Y
	var c := W / 2
	var top := Vector2(c, f - STEP * (4 if layout != 2 else 3))     # на верхний алтарь в центре
	var plates := [
		[380.0, Vector2(W - 640.0, f)], [W - 380.0, Vector2(640.0, f)],   # через всю арену
		[960.0, top], [W - 960.0, top],
	]
	for pl in plates:
		var cp := Catapult.new()
		cp.position = Vector2(pl[0], f)
		cp.target = pl[1]
		world.add_child(cp)
	for x in [650.0, W - 650.0]:
		Props.weapon_rack(world, x, f)

# Колонна заднего плана: сквозь неё проходят все (и боты, и пули)
static func _bg_column(world: Node, rect: Rect2) -> void:
	var d := Maps.make_destructible(rect, 20.0, Maps.STONE, 70, 45.0)
	d.background = true
	d.anchored = true
	for x in d.cols:
		d.anchors.append(Vector2i(x, d.rows - 1))
	world.add_child(d)

# Башня: сквозные платформы друг над другом через STEP
static func _tower(world: Node, x: float, w: float, levels: int) -> void:
	for k in levels:
		var ww := w - k * 30.0
		Colosseum.plat(world, Rect2(x - ww / 2, FLOOR_Y - STEP * (k + 1), ww, 20))

# Площадка Арены: неразрушаемая (чтобы до алтарей баффов всегда можно было
# допрыгнуть), снизу сквозь неё можно пропрыгнуть.
static func plat(world: Node, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Layer.WORLD | Layer.FRAME
	body.position = rect.get_center()
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	col.shape = rs
	col.one_way_collision = true
	body.add_child(col)
	body.add_child(Tex.slab(rect.size, "plat", Maps.PLAT, int(rect.position.x * 7 + rect.position.y)))
	world.add_child(body)

# Неразрушаемый каменный уступ с алтарём баффов. Снизу сквозь него можно пропрыгнуть.
static func _ledge(world: Node, x: float, h: float, w: float) -> PickupSpawner:
	var body := StaticBody2D.new()
	body.collision_layer = Layer.WORLD | Layer.FRAME
	body.position = Vector2(x, FLOOR_Y - h + 10)
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = Vector2(w, 20)
	col.shape = rs
	col.one_way_collision = true
	body.add_child(col)
	body.add_child(Tex.slab(Vector2(w, 20), "stone", LEDGE, int(x)))
	world.add_child(body)
	return _station(world, Vector2(x, FLOOR_Y - h), "buff")

static func _station(world: Node, pos: Vector2, kind: String) -> PickupSpawner:
	var s := PickupSpawner.new()
	s.kind = kind
	s.position = pos
	world.add_child(s)
	return s
