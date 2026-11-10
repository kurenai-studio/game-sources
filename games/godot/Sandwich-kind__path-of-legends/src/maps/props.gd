class_name Props
# ---------- Свои препятствия для каждой локации ----------
# Вместо одинаковых ящиков и колонн — предметы, которые подходят месту:
#   Джунгли   — каменная голова идола (мох, глаза), поросшая лианами;
#   Царство   — каменный саркофаг с золотой крышкой, груда костей;
#   Колизей   — амфоры и статуя (можно разбить), стойка с оружием на фоне;
#   Жуткий лес — надгробия, мёртвые пни;
#   Болото    — гнилые коряги.
# Всё разрушаемое держится за землю нижним рядом клеток.
# И домик на дереве (Лесная тропа, Жуткий лес): забираешься по веткам-ступенькам,
# внутри — алтарь баффов, где бафф чаще всего выпадает сразу МЕГА.

const CELL := 20.0

static func _d(rect: Rect2, color: Color, hp: int, dens: float) -> Destructible:
	var d := Maps.make_destructible(rect, CELL, color, hp, dens)
	d.anchored = true
	return d

static func _anchor_bottom(d: Destructible) -> void:
	var maxy := 0
	for c in d.cells:
		maxy = maxi(maxy, c.y)
	for c in d.cells:
		if c.y == maxy:
			d.anchors.append(c)

static func _cell(d: Destructible, c: Vector2i, col: Color) -> void:
	d.cells[c] = d.cell_hp
	d.cell_colors[c] = col

# Голова идола: 5×5 клеток, глаза и рот темнее, сверху мох
static func idol_head(world: Node, x: float, floor_y: float) -> void:
	var stone := Color(0.50, 0.52, 0.44)
	var d := _d(Rect2(x - 50, floor_y - 100, 100, 100), stone, 90, 45.0)
	for cx in 5:
		for cy in 5:
			if cy == 0 and (cx == 0 or cx == 4):
				continue
			var col := stone.darkened(0.06 * ((cx + cy) % 2))
			if cy == 0 or (cy == 1 and cx in [0, 4]):
				col = Color(0.32, 0.55, 0.26)                       # мох на макушке
			if cy == 2 and cx in [1, 3]:
				col = Color(0.12, 0.12, 0.10)                       # глазницы
			if cy == 3 and cx in [1, 2, 3]:
				col = Color(0.22, 0.20, 0.17)                       # рот
			_cell(d, Vector2i(cx, cy), col)
	_anchor_bottom(d)
	d.mat_kind = "rock"
	world.add_child(d)
	# лианы свисают с головы
	for k in 3:
		var v := Line2D.new()
		v.points = PackedVector2Array([Vector2(x - 40 + k * 35, floor_y - 96), Vector2(x - 44 + k * 35, floor_y - 50 - k * 8)])
		v.width = 3.0
		v.default_color = Color(0.28, 0.52, 0.2)
		v.z_index = 1
		world.add_child(v)

# Саркофаг: 6×3, золотая крышка с узором
static func sarcophagus(world: Node, x: float, floor_y: float) -> void:
	var stone := Color(0.40, 0.38, 0.44)
	var d := _d(Rect2(x - 60, floor_y - 60, 120, 60), stone, 110, 50.0)
	for cx in 6:
		for cy in 3:
			var col := stone.darkened(0.05 * (cx % 2))
			if cy == 0:
				col = Color(0.82, 0.66, 0.26) if cx in [0, 5] or cx % 2 == 0 else Color(0.70, 0.55, 0.20)
			_cell(d, Vector2i(cx, cy), col)
	_anchor_bottom(d)
	world.add_child(d)

# Груда костей: невысокая, ломается легко
static func bone_pile(world: Node, x: float, floor_y: float) -> void:
	var bone := Color(0.88, 0.85, 0.76)
	var d := _d(Rect2(x - 50, floor_y - 40, 100, 40), bone, 25, 10.0)
	for cx in 5:
		for cy in 2:
			if cy == 0 and cx in [0, 4]:
				continue
			_cell(d, Vector2i(cx, cy), bone.darkened(0.1 * ((cx * 3 + cy) % 3)))
	_anchor_bottom(d)
	world.add_child(d)
	var skull := Polygon2D.new()
	skull.polygon = Util.circle(9.0, 10)
	skull.color = bone.lightened(0.05)
	skull.position = Vector2(x + 6, floor_y - 44)
	skull.z_index = -1
	world.add_child(skull)

# Амфора: узкое горлышко, широкое брюхо
static func amphora(world: Node, x: float, floor_y: float) -> void:
	var clay := Color(0.72, 0.42, 0.24)
	var d := _d(Rect2(x - 30, floor_y - 80, 60, 80), clay, 22, 10.0)
	for cy in 4:
		for cx in 3:
			if cy == 0 and cx != 1:
				continue
			var col := clay if cy != 2 else Color(0.18, 0.14, 0.12)       # чёрная полоса узора
			_cell(d, Vector2i(cx, cy), col)
	_anchor_bottom(d)
	d.mat_kind = "crate"
	world.add_child(d)

# Статуя гладиатора: постамент и фигура (можно расколоть)
static func statue(world: Node, x: float, floor_y: float) -> void:
	var marble := Color(0.86, 0.84, 0.80)
	var d := _d(Rect2(x - 40, floor_y - 180, 80, 180), marble, 70, 45.0)
	for cy in 9:
		for cx in 4:
			var keep := false
			if cy >= 7:
				keep = true                                     # постамент
			elif cy == 0:
				keep = cx in [1, 2]                              # голова
			elif cy <= 3:
				keep = cx in [1, 2] or (cy == 2 and cx == 3)     # торс и рука с мечом
			else:
				keep = cx in [1, 2]                              # ноги
			if keep:
				var col := marble.darkened(0.08 * ((cx + cy) % 2))
				if cy >= 7:
					col = Color(0.58, 0.54, 0.48)
				_cell(d, Vector2i(cx, cy), col)
	_anchor_bottom(d)
	d.mat_kind = "stone"
	world.add_child(d)

# Стойка с оружием на заднем плане (просто картинка)
static func weapon_rack(world: Node, x: float, floor_y: float) -> void:
	var g := Node2D.new()
	g.position = Vector2(x, floor_y)
	g.z_index = -7
	var frame := Polygon2D.new()
	frame.polygon = PackedVector2Array([Vector2(-60, 0), Vector2(-56, -110), Vector2(56, -110), Vector2(60, 0)])
	frame.color = Color(0.40, 0.28, 0.16, 0.0)
	g.add_child(frame)
	for k in [-50.0, 50.0]:
		var post := ColorRect.new()
		post.color = Color(0.42, 0.30, 0.18)
		post.position = Vector2(k - 4, -110)
		post.size = Vector2(8, 110)
		g.add_child(post)
	var bar := ColorRect.new()
	bar.color = Color(0.36, 0.26, 0.16)
	bar.position = Vector2(-56, -100)
	bar.size = Vector2(112, 6)
	g.add_child(bar)
	for k in 4:
		var w := Polygon2D.new()
		var wx := -36.0 + k * 24.0
		w.polygon = PackedVector2Array([Vector2(wx - 2, -96), Vector2(wx + 2, -96), Vector2(wx + 2, -10), Vector2(wx - 2, -10)])
		w.color = Color(0.72, 0.74, 0.78)
		g.add_child(w)
		var tip := Polygon2D.new()
		tip.polygon = PackedVector2Array([Vector2(wx - 5, -96), Vector2(wx, -110 - (k % 2) * 8), Vector2(wx + 5, -96)])
		tip.color = Color(0.82, 0.84, 0.88)
		g.add_child(tip)
	world.add_child(g)

# Надгробие: крестом или плитой
static func gravestone(world: Node, x: float, floor_y: float, cross: bool) -> void:
	var stone := Color(0.42, 0.42, 0.46)
	var d := _d(Rect2(x - 30, floor_y - 80, 60, 80), stone, 60, 40.0)
	for cy in 4:
		for cx in 3:
			var keep := true
			if cross:
				keep = cx == 1 or cy == 1
			elif cy == 0:
				keep = cx == 1
			if keep:
				var col := stone.darkened(0.08 * ((cx + cy) % 2))
				if (cx + cy * 2) % 5 == 0:
					col = Color(0.30, 0.38, 0.28)                   # лишайник
				_cell(d, Vector2i(cx, cy), col)
	_anchor_bottom(d)
	d.mat_kind = "stone"
	world.add_child(d)

# Мёртвый пень с торчащими сучьями / гнилая коряга
static func dead_stump(world: Node, x: float, floor_y: float, rotten: bool) -> void:
	var wood := Color(0.30, 0.26, 0.24) if not rotten else Color(0.26, 0.28, 0.20)
	var d := _d(Rect2(x - 40, floor_y - 60, 80, 60), wood, 55, 30.0)
	for cy in 3:
		for cx in 4:
			if cy == 0 and cx in [0, 3]:
				continue
			_cell(d, Vector2i(cx, cy), wood.darkened(0.08 * ((cx + cy) % 2)) if not (rotten and cy == 0) else Color(0.30, 0.42, 0.20))
	_anchor_bottom(d)
	d.flammable = not rotten
	world.add_child(d)
	for k in 2:
		var twig := Line2D.new()
		twig.points = PackedVector2Array([Vector2(x - 10 + k * 24, floor_y - 58), Vector2(x - 22 + k * 50, floor_y - 88)])
		twig.width = 3.0
		twig.default_color = wood.darkened(0.1)
		twig.z_index = -1
		world.add_child(twig)

# ---------- Домик на дереве ----------
# Толстый ствол (на фоне), к домику ведут ветки-ступеньки по обе стороны —
# допрыгнуть можно только по ним (паркур). Внутри — алтарь: бафф часто сразу МЕГА.
# Возвращает алтарь, чтобы Арена подписалась на подбор.
static func tree_house(world: Node, x: float, floor_y: float, eerie: bool) -> PickupSpawner:
	var step := Colosseum.STEP
	var bark := Color(0.40, 0.29, 0.18) if not eerie else Color(0.26, 0.23, 0.24)
	var tn := Node2D.new()                             # ствол — фон, сквозь него проходят
	tn.position = Vector2(x, floor_y)
	tn.z_index = -6
	var trunk := Polygon2D.new()
	trunk.polygon = PackedVector2Array([Vector2(-34, 0), Vector2(-26, -step * 4.6), Vector2(26, -step * 4.6),
			Vector2(34, 0), Vector2(60, 4), Vector2(-60, 4)])
	trunk.color = bark
	tn.add_child(trunk)
	EerieWoods._bark(tn, -28.0, 28.0, -step * 4.6, bark)
	world.add_child(tn)
	# ветки-ступеньки: зигзагом вверх (слева и справа)
	var steps := [[-1, 1.0], [1, 2.0], [-1, 3.0]]
	for s in steps:
		var sx: float = x + s[0] * 110.0
		ForestTrail.wood_plat(world, Rect2(sx - 55, floor_y - step * float(s[1]), 110, 16))
		var branch := Line2D.new()
		branch.points = PackedVector2Array([Vector2(x, floor_y - step * float(s[1]) + 30), Vector2(sx, floor_y - step * float(s[1]) + 6)])
		branch.width = 9.0
		branch.default_color = bark.darkened(0.1)
		branch.z_index = -5
		world.add_child(branch)
	# сам домик: пол, задняя стенка, крыша
	var hy := floor_y - step * 4.0
	ForestTrail.wood_plat(world, Rect2(x - 120, hy, 240, 20))
	var wall := Polygon2D.new()
	wall.polygon = PackedVector2Array([Vector2(x - 110, hy), Vector2(x - 110, hy - 110), Vector2(x + 110, hy - 110), Vector2(x + 110, hy)])
	Tex.apply(wall, "mine_wood", Color(0.55, 0.40, 0.24) if not eerie else Color(0.34, 0.30, 0.30))
	wall.z_index = -5
	world.add_child(wall)
	var win := Polygon2D.new()
	win.polygon = PackedVector2Array([Vector2(x - 74, hy - 82), Vector2(x - 44, hy - 82), Vector2(x - 44, hy - 56), Vector2(x - 74, hy - 56)])
	win.color = Color(1.0, 0.85, 0.45, 0.85) if not eerie else Color(0.55, 1.0, 0.55, 0.8)
	win.z_index = -4
	world.add_child(win)
	var roof := Polygon2D.new()
	roof.polygon = PackedVector2Array([Vector2(x - 140, hy - 106), Vector2(x, hy - 170), Vector2(x + 140, hy - 106)])
	roof.color = Color(0.48, 0.22, 0.14) if not eerie else Color(0.22, 0.20, 0.24)
	roof.z_index = -4
	world.add_child(roof)
	# крыша — тоже площадка (оттуда можно прыгать дальше)
	ForestTrail.wood_plat(world, Rect2(x - 60, hy - 150, 120, 14))
	var sp := PickupSpawner.new()
	sp.kind = "buff"
	sp.mega_chance = 0.6
	sp.position = Vector2(x + 40, hy)
	world.add_child(sp)
	return sp

# Пещерный гриб: толстая ножка и шляпка в пятнах, шляпка светится
static func mushroom(world: Node, x: float, floor_y: float, glow_layer: CanvasLayer) -> void:
	var stem := Color(0.86, 0.80, 0.66)
	var cap := Color(0.55, 0.30, 0.70)
	var d := _d(Rect2(x - 50, floor_y - 100, 100, 100), stem, 40, 20.0)
	for cy in 5:
		for cx in 5:
			var keep: bool = cy <= 1 or (cx in [1, 2, 3] and cy == 2) or cx == 2
			if cy == 0 and cx in [0, 4]:
				keep = false
			if keep:
				var col := stem
				if cy <= 1:
					col = cap if (cx + cy) % 3 != 0 else Color(0.85, 0.75, 0.95)    # пятна
				_cell(d, Vector2i(cx, cy), col)
	_anchor_bottom(d)
	world.add_child(d)
	if glow_layer:
		var g := Torch.make_glow(170.0, Color(0.7, 0.45, 1.0, 0.45))
		g.position = Vector2(x, floor_y - 80)
		glow_layer.add_child(g)
