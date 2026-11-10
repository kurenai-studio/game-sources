class_name GemCaves
# ---------- Драгоценные пещеры (волны 31–35) и Кристальные пещеры (36–40) ----------
# Размер — как у Колизея.
#   Драгоценные: шахта кобольдов — крепь, рельсы с вагонетками (катаются и сбивают),
#     жилы самоцветов (если разбить — золото на Арене), фонари на цепях (их можно сбить).
#   Кристальные: светлый зал из кристаллов — зеркальные кристаллы (пули и лучи
#     отскакивают), призмы в воздухе (делят луч на три), друзы, которые отрастают.

const W := Colosseum.W
const H := Colosseum.H
const FLOOR_Y := Colosseum.FLOOR_Y
const WALL := Colosseum.WALL
const STEP := Colosseum.STEP
const ROCK := Color(0.24, 0.21, 0.26)
const ROCK_C := Color(0.20, 0.23, 0.36)
const WOOD := Color(0.48, 0.33, 0.20)

static func build(world: Node, crystal: bool) -> Dictionary:
	var rock := ROCK_C if crystal else ROCK
	var img := DeepArt.crystal_backdrop(W, FLOOR_Y) if crystal else DeepArt.gem_backdrop(W, FLOOR_Y)
	var bg := PixelArt.make_sprite(img, PixelArt.SCALE)
	bg.z_index = -10
	Shimmer.apply(bg, 0.10 if crystal else 0.12, 0.5)
	world.add_child(bg)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, H - FLOOR_Y + 40), rock)
	_edge(world, Rect2(0, FLOOR_Y, W, 10), crystal)
	Maps.add_block(world, Rect2(0, -800, WALL, H + 800), rock.darkened(0.25))
	Maps.add_block(world, Rect2(W - WALL, -800, WALL, H + 800), rock.darkened(0.25))
	Maps.add_block(world, Rect2(0, -800, W, 830), rock.darkened(0.35))
	# сосульки-кристаллы под сводом
	var x := 110.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 51 if crystal else 49
	while x < W - 100.0:
		var st := Polygon2D.new()
		var l := rng.randf_range(30, 120)
		st.polygon = PackedVector2Array([Vector2(x - 16, 28), Vector2(x + 16, 28), Vector2(x + rng.randf_range(-6, 6), 28 + l)])
		if crystal or rng.randf() < 0.35:
			st.color = Color(DeepArt.CRYSTAL if rng.randf() < 0.6 else DeepArt.CRYSTAL_V, 0.85).darkened(0.15)
			Shimmer.apply(st, 0.2)
		else:
			st.color = rock.darkened(0.1)
		world.add_child(st)
		x += rng.randf_range(60, 150)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	for g in gates:
		Caves._tunnel(world, g, rock.lightened(0.05))
	var cm := CanvasModulate.new()
	cm.color = Color(0.70, 0.74, 0.92) if crystal else Color(0.82, 0.76, 0.84)
	world.add_child(cm)
	var glow_layer := CanvasLayer.new()
	glow_layer.layer = 1
	glow_layer.follow_viewport_enabled = true
	world.add_child(glow_layer)
	var info := {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": glow_layer, "floor": FLOOR_Y, "totems": [], "ceiling": 30.0, "gems": []}
	info["spawners"] = _crystal(world, glow_layer, info) if crystal else _mine(world, glow_layer, info)
	return info

# Светлая кромка пола: у шахты — щебень с самоцветами, у кристаллов — сияющая корка
static func _edge(world: Node, rect: Rect2, crystal: bool) -> void:
	var s := Tex.slab(rect.size, "crystal" if crystal else "gem", DeepArt.CRYSTAL if crystal else DeepArt.GEMS[2], 7)
	s.position = rect.get_center()
	s.z_index = -1
	world.add_child(s)
	Shimmer.apply(s, 0.18)

# Деревянный настил шахты (сквозной снизу)
static func scaffold(world: Node, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Layer.WORLD | Layer.FRAME
	body.position = rect.get_center()
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	col.shape = rs
	col.one_way_collision = true
	body.add_child(col)
	body.add_child(Tex.slab(rect.size, "mine_wood", WOOD, int(rect.position.x * 3 + rect.position.y)))
	# подпорки до пола (если невысоко) — только картинка
	if FLOOR_Y - rect.end.y < STEP * 2.2:
		for sx in [rect.position.x + 14, rect.end.x - 14]:
			var post := Tex.slab(Vector2(10, FLOOR_Y - rect.end.y), "mine_wood", WOOD.darkened(0.2), int(sx))
			post.position = Vector2(sx, (FLOOR_Y + rect.end.y) / 2) - body.position
			post.z_index = -2
			body.add_child(post)
	world.add_child(body)

# Кристальная плита (сквозная снизу) с переливом
static func crystal_plat(world: Node, rect: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Layer.WORLD | Layer.FRAME
	body.position = rect.get_center()
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	col.shape = rs
	col.one_way_collision = true
	body.add_child(col)
	var s := Tex.slab(rect.size, "crystal", DeepArt.CRYSTAL_V if int(rect.position.x) % 3 == 0 else DeepArt.CRYSTAL, int(rect.position.x))
	body.add_child(s)
	Shimmer.apply(s, 0.2)
	world.add_child(body)

static func _shadow(world: Node, at: Vector2, half_w: float) -> void:
	var sh := Polygon2D.new()
	var pts := Util.circle(1.0, 18)
	for i in pts.size():
		pts[i] *= Vector2(half_w, 8.0)
	sh.polygon = pts
	sh.color = Color(0, 0, 0, 0.32)
	sh.position = at
	sh.z_index = -2
	world.add_child(sh)

# Жила самоцветов: порода с камнями; на Арене за каждую выбитую клетку — золото
static func gem_vein(world: Node, rect: Rect2, gem_color: Color, info: Dictionary) -> Destructible:
	var d := Maps.make_destructible(rect, 20.0, gem_color, 55, 45.0)
	d.mat_kind = "gem"
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	d.set_meta("gem", true)
	Shimmer.apply(d, 0.2)
	world.add_child(d)
	info["gems"].append(d)
	_shadow(world, Vector2(rect.get_center().x, rect.end.y), rect.size.x * 0.6)
	return d

# ---------- Шахта ----------
static func _mine(world: Node, glow: CanvasLayer, info: Dictionary) -> Array:
	var f := FLOOR_Y
	var c := W / 2
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, f), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, f), "heal"))
	# рельсы на полу и две вагонетки — слева и справа
	for seg in [[330.0, 1020.0], [1580.0, 2270.0]]:
		_rails(world, seg[0] - 70, seg[1] + 70)
		var cart := MineCart.new()
		cart.x_min = seg[0]
		cart.x_max = seg[1]
		cart.floor_y = f
		cart.speed = 290.0
		world.add_child(cart)
	for side in [1.0, -1.0]:
		var x0: float = 640.0 if side > 0 else W - 640.0
		scaffold(world, Rect2(x0 - 140, f - STEP, 280, 20))
		scaffold(world, Rect2(x0 - 100 + side * 120, f - STEP * 2, 220, 20))
		sp.append(Colosseum._ledge(world, x0 - side * 60, STEP * 3, 170.0))
		gem_vein(world, Rect2(x0 + side * 330 - 50, f - 100, 100, 100), DeepArt.GEMS[0] if side > 0 else DeepArt.GEMS[2], info)
	# середина: груда самоцветов, над ней настилы к верхнему алтарю
	gem_vein(world, Rect2(c - 70, f - 80, 140, 80), DeepArt.GEMS[3], info)
	scaffold(world, Rect2(c - 300, f - STEP * 2, 200, 20))
	scaffold(world, Rect2(c + 100, f - STEP * 2, 200, 20))
	scaffold(world, Rect2(c - 110, f - STEP * 3, 220, 20))
	sp.append(Colosseum._ledge(world, c, STEP * 4, 170.0))
	# ящики с динамитом на настилах: выбей пару клеток — взрыв (и цепная реакция)
	for side in [1.0, -1.0]:
		var tx: float = (640.0 if side > 0 else W - 640.0) - side * 90.0
		var tnt := TntCrate.new()
		tnt.position = Vector2(tx, f - STEP - 41)
		world.add_child(tnt)
	var tnt2 := TntCrate.new()
	tnt2.position = Vector2(c + 200.0, f - STEP * 2 - 41)
	world.add_child(tnt2)
	# фонари на цепях под сводом
	for lx in [420.0, 900.0, 1300.0, 1700.0, 2180.0]:
		var lamp := MineLamp.new()
		lamp.glow_layer = glow
		lamp.chain_len = 90.0 + float(int(lx) % 3) * 20.0
		lamp.position = Vector2(lx, 30.0 + lamp.chain_len + 10.0)
		world.add_child(lamp)
	# мягкий свет от самоцветов у пола
	for gx in [c, 640.0 + 330.0, W - 640.0 - 330.0]:
		var g := Torch.make_glow(260.0, Color(0.9, 0.5, 1.0, 0.25))
		g.position = Vector2(gx, f - 50)
		glow.add_child(g)
	return sp

static func _rails(world: Node, x0: float, x1: float) -> void:
	var r := Node2D.new()
	r.z_index = -1
	for xx in range(int(x0), int(x1), 22):
		var sl := ColorRect.new()          # шпалы
		sl.color = Color(0.30, 0.20, 0.12)
		sl.position = Vector2(xx, FLOOR_Y - 4)
		sl.size = Vector2(14, 6)
		r.add_child(sl)
	var rail := ColorRect.new()
	rail.color = Color(0.55, 0.55, 0.6)
	rail.position = Vector2(x0, FLOOR_Y - 6)
	rail.size = Vector2(x1 - x0, 3)
	r.add_child(rail)
	var hl := ColorRect.new()
	hl.color = Color(0.8, 0.8, 0.85)
	hl.position = Vector2(x0, FLOOR_Y - 6)
	hl.size = Vector2(x1 - x0, 1)
	r.add_child(hl)
	world.add_child(r)

# ---------- Кристальный зал ----------
static func _crystal(world: Node, glow: CanvasLayer, info: Dictionary) -> Array:
	var f := FLOOR_Y
	var c := W / 2
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, f), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, f), "heal"))
	# зеркальные кристаллы: два на полу, два на верхних плитах
	for mx in [760.0, W - 760.0]:
		var m := MirrorCrystal.new()
		m.size = Vector2(44, 150)
		m.position = Vector2(mx, f - 75)
		world.add_child(m)
	for side in [1.0, -1.0]:
		var x0: float = 520.0 if side > 0 else W - 520.0
		crystal_plat(world, Rect2(x0 - 130, f - STEP, 260, 20))
		crystal_plat(world, Rect2(x0 - 90 + side * 160, f - STEP * 2, 220, 20))
		sp.append(Colosseum._ledge(world, x0 + side * 70, STEP * 3, 160.0))
		var m2 := MirrorCrystal.new()
		m2.size = Vector2(36, 110)
		m2.position = Vector2(x0 - side * 70, f - STEP * 2 - 75)
		world.add_child(m2)
		# друзы, которые отрастают
		for gx in [x0 + side * 330, c - side * 330]:
			var gr := CrystalGrower.new()
			gr.rect = Rect2(gx - 40, f - 100, 80, 100)
			gr.color = DeepArt.CRYSTAL if gx < c else DeepArt.CRYSTAL_V
			world.add_child(gr)
			_shadow(world, Vector2(gx, f), 50.0)
	# середина: плиты лесенкой к верхнему алтарю, над ними призмы
	crystal_plat(world, Rect2(c - 120, f - STEP * 2, 240, 20))
	crystal_plat(world, Rect2(c - 330, f - STEP * 3, 180, 20))
	crystal_plat(world, Rect2(c + 150, f - STEP * 3, 180, 20))
	sp.append(Colosseum._ledge(world, c, STEP * 4, 170.0))
	for pp in [Vector2(c - 520, f - 330), Vector2(c + 520, f - 330), Vector2(c, f - STEP * 4 - 140)]:
		var pr := LightPrism.new()
		pr.position = pp
		world.add_child(pr)
	# поющие кристаллы-батуты: подбрасывают высоко вверх (и героя, и врагов)
	for bx in [620.0, W - 620.0, 1110.0, W - 1110.0]:
		var pad := BouncePad.new()
		pad.position = Vector2(bx, f)
		world.add_child(pad)
	# сияние кристаллов
	for gx in [300.0, 760.0, c, W - 760.0, W - 300.0]:
		var g := Torch.make_glow(420.0, Color(0.5, 0.7, 1.0, 0.3))
		g.position = Vector2(gx, f - 120)
		glow.add_child(g)
	return sp
