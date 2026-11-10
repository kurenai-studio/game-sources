class_name Caves
# Арена «Пещеры» (волны 21–30). Размер тот же, что у Колизея.
#   Механики: в пещерах со свода падают камни (бьют всех — и героя, и врагов),
#   в Царстве скелетов из решёток в полу выстреливают шипы.
#   Волны 21–25 — пещеры с факелами, грибами и деревянными лесами;
#   волны 26–30 — Царство скелетов: огромный мрачный зал, колонны, знамёна
#   и трон, на котором дремлет Король скелетов (его нельзя потревожить до 30-й волны).

const W := Colosseum.W
const H := Colosseum.H
const FLOOR_Y := Colosseum.FLOOR_Y
const WALL := Colosseum.WALL
const STEP := Colosseum.STEP
const ROCK := Color(0.33, 0.29, 0.30)
const ROCK_DEEP := Color(0.24, 0.22, 0.28)
const STALAG := Color(0.42, 0.38, 0.38)
const SCAFFOLD := Color(0.5, 0.36, 0.22)

static func build(world: Node, deep: bool) -> Dictionary:
	var rock := ROCK_DEEP if deep else ROCK
	var bg := PixelArt.make_sprite(PixelArt.cave_backdrop(W, FLOOR_Y, deep), PixelArt.SCALE)
	bg.z_index = -10
	world.add_child(bg)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, H - FLOOR_Y + 40), rock)
	Maps.add_block(world, Rect2(0, FLOOR_Y, W, 8), rock.lightened(0.12))
	Maps.add_block(world, Rect2(0, -800, WALL, H + 800), rock.darkened(0.2))
	Maps.add_block(world, Rect2(W - WALL, -800, WALL, H + 800), rock.darkened(0.2))
	Maps.add_block(world, Rect2(0, -800, W, 830), rock.darkened(0.3))      # свод пещеры
	# сталактиты под сводом (украшение)
	var x := 120.0
	while x < W - 100.0:
		var st := Polygon2D.new()
		var l := randf_range(30, 110)
		st.polygon = PackedVector2Array([Vector2(x - 18, 28), Vector2(x + 18, 28), Vector2(x, 28 + l)])
		st.color = rock.darkened(0.15)
		world.add_child(st)
		x += randf_range(70, 160)
	var gates := [Vector2(WALL + 70, FLOOR_Y), Vector2(W - WALL - 70, FLOOR_Y)]
	for g in gates:
		_tunnel(world, g, rock)
	# темнота и свет
	var cm := CanvasModulate.new()
	cm.color = Color(0.40, 0.40, 0.55) if deep else Color(0.55, 0.52, 0.58)
	world.add_child(cm)
	var glow_layer := CanvasLayer.new()
	glow_layer.layer = 1
	glow_layer.follow_viewport_enabled = true
	world.add_child(glow_layer)
	var torch_x := [300.0, 820.0, 1300.0, 1780.0, 2300.0]
	for tx in torch_x:
		var t := Torch.new()
		t.position = Vector2(tx, FLOOR_Y - 300.0 - (40.0 if int(tx) % 3 == 0 else 0.0))
		t.lit = true
		t.glow_layer = glow_layer
		world.add_child(t)
	if deep:
		# жаровни с призрачным огнём
		for bx in [600.0, W - 600.0]:
			var g := Torch.make_glow(260.0, Color(0.5, 1.0, 0.6, 0.6))
			g.position = Vector2(bx, FLOOR_Y - 60)
			glow_layer.add_child(g)
			var bowl := Polygon2D.new()
			bowl.polygon = PackedVector2Array([Vector2(bx - 22, FLOOR_Y - 50), Vector2(bx + 22, FLOOR_Y - 50),
					Vector2(bx + 10, FLOOR_Y - 30), Vector2(bx + 6, FLOOR_Y), Vector2(bx - 6, FLOOR_Y), Vector2(bx - 10, FLOOR_Y - 30)])
			bowl.color = Color(0.25, 0.23, 0.28)
			bowl.z_index = -3
			world.add_child(bowl)
			var fire := Polygon2D.new()
			fire.polygon = PackedVector2Array([Vector2(bx - 16, FLOOR_Y - 50), Vector2(bx + 16, FLOOR_Y - 50), Vector2(bx, FLOOR_Y - 95)])
			fire.color = Color(0.5, 1.0, 0.6)
			fire.z_index = -3
			world.add_child(fire)
	var res := _obstacles(world, deep, rock, glow_layer)
	if not deep:
		# камнепад: со свода срываются камни (видно тень), бьют всех
		var rf := Rockfall.new()
		rf.ceiling = 30.0
		rf.floor_y = FLOOR_Y
		rf.map_w = W
		world.add_child(rf)
	else:
		# ловушки с шипами в полу и саркофаги
		for tx in [700.0, 1060.0, W - 1060.0, W - 700.0]:
			var tr := SpikeTrap.new()
			tr.position = Vector2(tx, FLOOR_Y)
			world.add_child(tr)
		for sx in [880.0, W - 880.0]:
			Props.sarcophagus(world, sx, FLOOR_Y)
		Props.bone_pile(world, 320.0, FLOOR_Y)
		Props.bone_pile(world, W - 320.0, FLOOR_Y)
	var info := {"size": Vector2(W, H), "center": Vector2(W / 2, FLOOR_Y - 32), "gates": gates,
			"glow": glow_layer, "floor": FLOOR_Y, "spawners": res, "totems": [], "ceiling": 30.0}
	if deep:
		info["throne"] = _throne(world)
	return info

# Проход в скале, из которого выходят враги
static func _tunnel(world: Node, base: Vector2, rock: Color) -> void:
	var g := Node2D.new()
	g.position = base
	g.z_index = -9
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([Vector2(-90, 0), Vector2(-80, -150), Vector2(-30, -200), Vector2(35, -195),
			Vector2(85, -140), Vector2(90, 0)])
	Tex.apply(frame, "rock", rock.lightened(0.1))
	g.add_child(frame)
	var hole := Polygon2D.new()
	hole.polygon = PackedVector2Array([Vector2(-60, 0), Vector2(-55, -110), Vector2(-20, -145), Vector2(25, -140),
			Vector2(58, -105), Vector2(60, 0)])
	hole.color = Color(0.03, 0.02, 0.03)
	g.add_child(hole)
	for k in 4:          # доски крепи
		var b := ColorRect.new()
		b.color = SCAFFOLD.darkened(0.2)
		b.position = Vector2(-66 + (k % 2) * 118, -150 + k / 2 * 4)
		b.size = Vector2(12, 150)
		g.add_child(b)
	var top := ColorRect.new()
	top.color = SCAFFOLD.darkened(0.2)
	top.position = Vector2(-70, -158)
	top.size = Vector2(140, 12)
	g.add_child(top)
	world.add_child(g)

static func _stalagmite(world: Node, x: float, h: float) -> void:
	var d := Maps.make_destructible(Rect2(x - 20, FLOOR_Y - h, 40, h), 20.0, STALAG, 70, 45.0)
	d.anchored = true
	for cx in d.cols:
		d.anchors.append(Vector2i(cx, d.rows - 1))
	world.add_child(d)

static func _obstacles(world: Node, deep: bool, rock: Color, glow: CanvasLayer = null) -> Array:
	var f := FLOOR_Y
	var c := W / 2
	var sp: Array = []
	sp.append(Colosseum._station(world, Vector2(WALL + 175, f), "heal"))
	sp.append(Colosseum._station(world, Vector2(W - WALL - 175, f), "heal"))
	if not deep:
		# деревянные леса шахтёров, сталагмиты, ящики
		for side in [1.0, -1.0]:
			var x0: float = 520.0 if side > 0 else W - 520.0
			Colosseum.plat(world, Rect2(x0 - 130, f - STEP, 260, 20))
			Colosseum.plat(world, Rect2(x0 - 90 + side * 90, f - STEP * 2, 200, 20))
			sp.append(Colosseum._ledge(world, x0 + side * 30, STEP * 3, 160.0))
			_stalagmite(world, x0 + side * 300, 100.0)
			Props.mushroom(world, x0 - side * 190, f, glow)
		Colosseum._tower(world, c, 280.0, 3)
		sp.append(Colosseum._ledge(world, c, STEP * 4, 160.0))
	else:
		# огромный зал: разрушенные колонны, широкие мосты, середина свободна под трон
		for side in [1.0, -1.0]:
			var x0: float = 470.0 if side > 0 else W - 470.0
			_stalagmite(world, x0 - side * 120, 140.0)
			Colosseum.plat(world, Rect2(x0 - 110, f - STEP, 220, 20))
			Colosseum.plat(world, Rect2(x0 - 60 + side * 140, f - STEP * 2, 240, 20))
			Colosseum.plat(world, Rect2(x0 + side * 300 - 100, f - STEP * 3, 200, 20))
			sp.append(Colosseum._ledge(world, x0 + side * 40, STEP * 3, 150.0))
		for side in [1.0, -1.0]:
			Colosseum.plat(world, Rect2(c + side * 330 - 110, f - STEP * 2, 220, 20))
			# лесенка к среднему алтарю: с пола — на низкую плиту, потом выше и выше
			Colosseum.plat(world, Rect2(c + side * 210 - 90, f - STEP, 180, 20))
			Colosseum.plat(world, Rect2(c + side * 175 - 85, f - STEP * 3, 170, 20))
		sp.append(Colosseum._ledge(world, c, STEP * 4, 180.0))
	return sp

# Трон на заднем плане, на нём спит Король скелетов (только картинка)
static func _throne(world: Node) -> Dictionary:
	var pos := Vector2(W * 0.72, FLOOR_Y)       # в глубине зала, правее центра
	var th := PixelArt.make_sprite(PixelArt.throne(), 5.0)
	th.position = pos - Vector2(20, 52) * 5.0
	th.z_index = -8
	th.modulate = Color(0.75, 0.75, 0.85)
	world.add_child(th)
	var king := BotRig.new()
	king.kind = "skeleton_king"
	king.size = Bots.TYPES["skeleton_king"]["size"]
	king.sit = 1.0
	king.puppet_facing = -1
	king.eyes_lit = false
	king.z_index = -7
	king.modulate = Color(0.7, 0.7, 0.8)
	# бёдра — на сиденье трона (110 пикселей над полом), ноги вытянуты вперёд
	king.position = pos + Vector2(0, -42.0 - king.size.y / 2)
	world.add_child(king)
	return {"rig": king, "throne": th, "pos": pos}
