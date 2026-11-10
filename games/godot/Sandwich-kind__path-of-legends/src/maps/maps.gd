class_name Maps
# Карты: из чего собран каждый уровень и где появляются герои.

const GROUND := Color(0.35, 0.3, 0.4)
const PLAT := Color(0.55, 0.5, 0.6)
const STONE := Color(0.58, 0.6, 0.64)
const CRATE := Color(0.75, 0.55, 0.35)
const BRICK := Color(0.66, 0.42, 0.33)
const ROOF := Color(0.45, 0.22, 0.2)
const WOOD := Color(0.6, 0.45, 0.3)
const BACK_WALL := Color(0.5, 0.36, 0.32)
const TRUNK := Color(0.45, 0.31, 0.2)
const LEAVES := Color(0.3, 0.55, 0.28)

# Карты Дуэли (показываются в свитке)
const DUEL_MAPS := [
	{"id": "test_field", "name": "TEST_FIELD",
		"desc": "Маленькая арена на один экран: платформы, колонны и ящики."},
	{"id": "two_houses", "name": "Два дома",
		"desc": "Поле под открытым небом, у каждого свой прочный дом, на фоне деревья."},
	{"id": "mountain", "name": "Гора",
		"desc": "Огромная гора из очень прочного камня: проходы, пещера, вершина. Далеко друг от друга — экран делится надвое."},
	{"id": "test_buffs", "name": "TEST_BUFFS",
		"desc": "Длинная дорога. На каждой площадке — свой бафф и свой МЕГА-бафф, появляются каждые 5 секунд."},
	# Скрытые карты: открываются, когда этап Арены пройден целиком
	{"id": "arena_forest", "name": "Лесная тропа", "stage": 0,
		"desc": "Тропа в лесу: мостки на ветвях, пни, бревно и деревья. Открыта за прохождение волн 1–5 на Арене."},
	{"id": "arena_village", "name": "Окраина деревни", "stage": 1,
		"desc": "Поле у деревни: стога сена, плетни, колодец и вышка. Открыта за прохождение волн 6–10."},
	{"id": "arena_jungle", "name": "Джунгли", "stage": 2,
		"desc": "Поляна гоблинов: мостки, брёвна, камни. Открыта за прохождение волн 11–15."},
	{"id": "arena_jungle_night", "name": "Ночные джунгли", "stage": 3,
		"desc": "Деревня гоблинов ночью, с факелами и светлячками. Открыта за прохождение волн 16–20."},
	{"id": "arena_caves", "name": "Пещеры", "stage": 4,
		"desc": "Пещеры с факелами и лесами шахтёров. Открыты за прохождение волн 21–25."},
	{"id": "arena_kingdom", "name": "Царство скелетов", "stage": 5,
		"desc": "Огромный мрачный зал с троном. Открыто за прохождение волн 26–30."},
	{"id": "arena_gems", "name": "Драгоценные пещеры", "stage": 6,
		"desc": "Шахта кобольдов: вагонетки на рельсах сбивают всех на пути, фонари можно сбить. Открыта за волны 31–35."},
	{"id": "arena_crystals", "name": "Кристальные пещеры", "stage": 7,
		"desc": "Зал из кристаллов: пули отскакивают от зеркал, призмы делят лучи, друзы отрастают. Открыт за волны 36–40."},
	{"id": "arena_colosseum", "name": "Колизей", "stage": 8,
		"desc": "Песок, трибуны и ворота Колизея. Открыт за прохождение волн 41–45 на Арене."},
	{"id": "arena_colosseum_night", "name": "Ночной Колизей", "stage": 9,
		"desc": "Колизей при луне и факелах. Открыт за прохождение волн 46–50."},
	{"id": "arena_eerie", "name": "Жуткий лес", "stage": 10,
		"desc": "Мёртвый лес в тумане: домик на дереве с баффом, корни-ловушки, надгробия. Открыт за волны 51–55."},
	{"id": "arena_swamp", "name": "Болото", "stage": 11,
		"desc": "Трясина замедляет, газ взрывается, брёвна тонут под ногами. Открыто за волны 56–60."},
	{"id": "arena_ice", "name": "Ледяная тропа", "stage": 12,
		"desc": "Ночь, северное сияние и снег: на наледи катишься, сосульки срываются на голову. Открыта за волны 61–65."},
	{"id": "arena_storm", "name": "Храм шторма", "stage": 13,
		"desc": "Вечная гроза: порывы ветра сносят в сторону, громоотводы бьют молнией. Открыт за волны 66–70."},
	{"id": "arena_lava", "name": "Лавовые просторы", "stage": 14,
		"desc": "Пепел и обсидиан: лава обжигает, вулкан плюётся бомбами. Открыты за волны 71–75."},
	{"id": "arena_throne", "name": "Тронный зал", "stage": 15,
		"desc": "Зал Тёмного лорда: люстры падают на головы, из решёток бьёт пламя бездны. Открыт за волны 76–80."},
	{"id": "arena_citadel", "name": "Цитадель во тьме", "stage": 16,
		"desc": "Вершина цитадели, где бился Тёмный Лорд: по краям — стены мрака. В «Мгновенную смерть» из тьмы встаёт Воплощение Тьмы — неуязвимое, бьёт по обоим. Открыта за победу над Тёмным Лордом."},
]

# Какие карты сейчас видны в свитке Дуэли (скрытые — только открытые на Арене)
static func visible_duel_maps() -> Array:
	return DUEL_MAPS.filter(func(m): return not m.has("stage") or Save.stage_unlocked(m["stage"]))

static var preview_mode := false   # строим карту только ради эскиза: без фонов и картинок

# Строит карту и возвращает её параметры:
#   size — размер, p1/p2 — точки появления в начале раунда,
#   follow — камера следит за игроками, open_top — сверху небо,
#   top_y — откуда искать место для возрождения (сверху вниз),
#   sky — точки высоко в небе для возрождения с парашютом (по одной на игрока)
static func build(world: Node, id: String) -> Dictionary:
	match id:
		"two_houses":
			return build_two_houses(world)
		"mountain":
			return build_mountain(world)
		"test_buffs":
			return build_test_buffs(world)
		"arena_forest":
			return build_arena(world, 0)
		"arena_village":
			return build_arena(world, 1)
		"arena_colosseum":
			return build_arena(world, 8)
		"arena_colosseum_night":
			return build_arena(world, 9)
		"arena_jungle":
			return build_arena(world, 2)
		"arena_jungle_night":
			return build_arena(world, 3)
		"arena_caves":
			return build_arena(world, 4)
		"arena_kingdom":
			return build_arena(world, 5)
		"arena_gems":
			return build_arena(world, 6)
		"arena_crystals":
			return build_arena(world, 7)
		"arena_eerie":
			return build_arena(world, 10)
		"arena_swamp":
			return build_arena(world, 11)
		"arena_ice":
			return build_arena(world, 12)
		"arena_storm":
			return build_arena(world, 13)
		"arena_lava":
			return build_arena(world, 14)
		"arena_throne":
			return build_arena(world, 15)
		"arena_citadel":
			return build_citadel_dark(world)
		_:
			return build_test_field(world)

# ---------- TEST_FIELD (один экран) ----------
static func build_test_field(world: Node) -> Dictionary:
	var w := Config.W
	build_frame(world, w, Config.H, true)
	add_platform(world, Rect2(180, 460, 260, 20))
	add_platform(world, Rect2(712, 460, 260, 20))
	add_platform(world, Rect2(446, 330, 260, 20))
	add_column(world, Rect2(470, 440, 40, 160))
	add_column(world, Rect2(w - 510, 440, 40, 160))
	add_crate(world, Vector2(330, 569))
	add_crate(world, Vector2(w - 330, 569))
	add_crate(world, Vector2(w / 2, 569))
	add_crate(world, Vector2(w / 2, 508))
	add_crate(world, Vector2(w / 2 - 61, 299))
	add_crate(world, Vector2(w / 2 + 61, 299))
	return {"size": Vector2(w, Config.H), "p1": Vector2(150, 560),
			"p2": Vector2(w - 150, 560), "follow": false, "open_top": false,
			"top_y": 40.0, "sky": []}

# ---------- TWO_HOUSES (большое поле, по дому на краях) ----------
const HOUSES_W := 4000.0
const HOUSES_H := 1300.0

static func build_two_houses(world: Node) -> Dictionary:
	var w := HOUSES_W
	var g := HOUSES_H - 48.0          # верх земли
	build_frame(world, w, HOUSES_H, false)
	if not preview_mode:
		var sky := PixelArt.make_sprite(PixelArt.valley_backdrop(w, -1500.0, g), PixelArt.SCALE)
		sky.position = Vector2(0, -1500)      # пиксельное небо, горы, холмы и лес вдали
		sky.z_index = -10
		world.add_child(sky)
	add_house(world, 20.0, g, 1)                  # дом игрока 1, дверь справа
	add_house(world, w - 20.0 - 440.0, g, -1)     # дом игрока 2, дверь слева

	# деревья на заднем плане — зеркально
	for x in [820.0, 1320.0]:
		add_tree(world, x, g)
		add_tree(world, w - x, g)
	add_tree(world, w / 2 + 170, g)

	# середина поля — всё зеркально относительно центра
	for x in [650.0, 1150.0]:
		add_platform(world, Rect2(x, g - 132, 260, 20))
		add_platform(world, Rect2(w - x - 260, g - 132, 260, 20))
	add_platform(world, Rect2(900, g - 262, 260, 20))
	add_platform(world, Rect2(w - 900 - 260, g - 262, 260, 20))
	add_platform(world, Rect2(w / 2 - 130, g - 262, 260, 20))
	add_platform(world, Rect2(1400, g - 392, 260, 20))
	add_platform(world, Rect2(w - 1400 - 260, g - 392, 260, 20))
	add_platform(world, Rect2(w / 2 - 130, g - 522, 260, 20))
	for x in [560.0, 1700.0]:
		add_column(world, Rect2(x, g - 160, 40, 160))
		add_column(world, Rect2(w - x - 40, g - 160, 40, 160))
	for x in [1000.0, 1550.0]:
		add_crate(world, Vector2(x, g - 31))
		add_crate(world, Vector2(w - x, g - 31))
	add_crate(world, Vector2(1000, g - 92))
	add_crate(world, Vector2(w - 1000, g - 92))
	for k in 3:
		add_crate(world, Vector2(w / 2, g - 31 - k * 61))   # башня из ящиков в центре
	add_crate(world, Vector2(w / 2 - 60, g - 293))
	add_crate(world, Vector2(w / 2 + 60, g - 293))
	return {"size": Vector2(w, HOUSES_H), "p1": Vector2(200, g - 37),
			"p2": Vector2(w - 200, g - 37), "follow": true, "open_top": true,
			"top_y": -100.0, "sky": [Vector2(240, g - 1500), Vector2(w - 240, g - 1500)]}

# Дом 440×320: крыша, две стены-колонны, второй этаж, дверь на стороне door_side.
# Цельный и очень прочный, держится за землю внешней стеной.
static func add_house(world: Node, x: float, ground: float, door_side: int) -> void:
	var cols := 22
	var rows := 16
	var cell := 20.0
	var d := Destructible.new()
	d.cell = cell
	d.cols = cols
	d.rows = rows
	d.color = BRICK
	d.cell_hp = 250               # ломается с трудом
	d.density = 60.0              # массивный снаряд пробивает максимум 2 стены
	d.anchored = true
	d.position = Vector2(x + cols * cell / 2, ground - rows * cell / 2)
	var outer := [0, 1] if door_side > 0 else [cols - 2, cols - 1]
	var inner := [cols - 2, cols - 1] if door_side > 0 else [0, 1]
	for cx in cols:                       # крыша
		for cy in 2:
			_house_cell(d, Vector2i(cx, cy), ROOF)
	for cx in outer:                      # внешняя стена до самой земли
		for cy in range(2, rows):
			_house_cell(d, Vector2i(cx, cy), BRICK)
		d.anchors.append(Vector2i(cx, rows - 1))
	for cx in inner:                      # внутренняя стена с дверью внизу
		for cy in range(2, 11):
			_house_cell(d, Vector2i(cx, cy), BRICK)
	for i in 14:                          # второй этаж, с проёмом у двери
		var cx: int = 2 + i if door_side > 0 else cols - 3 - i
		_house_cell(d, Vector2i(cx, 9), WOOD)
	world.add_child(d)

	# Задняя стена: всегда неосязаема, её только выбивают взрывы и снаряды
	var back := Destructible.new()
	back.cell = cell
	back.cols = cols
	back.rows = rows - 2
	back.color = BACK_WALL
	back.cell_hp = 50
	back.density = 0.0                    # не тратит пробитие тяжёлого снаряда
	back.background = true
	back.ghost = true
	back.anchored = true
	for cx in cols:                       # держится каждой клеткой — отрываться нечему
		for cy in rows - 2:
			back.anchors.append(Vector2i(cx, cy))
	back.position = Vector2(x + cols * cell / 2, ground - (rows - 2) * cell / 2)
	world.add_child(back)

# Дерево на заднем плане: сквозь него все проходят. Держится за корень.
# Горит; если подрубить или сжечь ствол — верх отваливается, становится
# осязаемым и падает.
static func add_tree(world: Node, x: float, ground: float) -> void:
	var cols := 10
	var rows := 19
	var cell := 20.0
	var d := Destructible.new()
	d.cell = cell
	d.cols = cols
	d.rows = rows
	d.color = LEAVES
	d.cell_hp = 35
	d.density = 15.0                      # тяжёлый снаряд немного теряет пробитие
	d.background = true
	d.flammable = true
	d.anchored = true
	d.position = Vector2(x, ground - rows * cell / 2)
	# крона 10×7 со скруглёнными углами
	for cy in 7:
		for cx in cols:
			var corner := (cy == 0 and (cx < 2 or cx > 7)) or (cy == 1 and (cx == 0 or cx == 9)) \
					or (cy == 6 and (cx == 0 or cx == 9))
			if not corner:
				_house_cell(d, Vector2i(cx, cy), LEAVES.darkened(randf_range(0.0, 0.15)))
	# ствол 2 клетки шириной до самой земли
	for cy in range(7, rows):
		for cx in [4, 5]:
			_house_cell(d, Vector2i(cx, cy), TRUNK)
	d.anchors = [Vector2i(4, rows - 1), Vector2i(5, rows - 1)]
	world.add_child(d)

static func _house_cell(d: Destructible, c: Vector2i, col: Color) -> void:
	d.cells[c] = d.cell_hp
	d.cell_colors[c] = col

# ---------- ГОРА (огромная, из очень прочного камня) ----------
# Снаружи — уступы-террасы до самой вершины. Внутри — нижний сквозной тоннель,
# верхний тоннель, шахты с деревянными площадками и пещера под вершиной.
const MOUNT_W := 6000.0
const MOUNT_H := 2600.0
const MOUNT_CX := 3000.0
const MOUNT_HALF := 1900.0       # полуширина основания
const TERRACE_W := 135.0         # ширина уступа
const TERRACE_H := 120.0         # высота уступа (запрыгнуть можно)
const ROCK := Color(0.47, 0.42, 0.38)
const ROCK_DARK := Color(0.36, 0.32, 0.29)
const GRASS := Color(0.38, 0.62, 0.30)
const SNOW := Color(0.92, 0.94, 0.98)
const MCELL := 40.0

static func _mount_height(x: float) -> float:
	var dx := absf(x - MOUNT_CX)
	if dx >= MOUNT_HALF:
		return 0.0
	return minf(floorf((MOUNT_HALF - dx) / TERRACE_W) * TERRACE_H, TERRACE_H * 14.0)

# Пустоты внутри горы: тоннели, шахты, пещера
static func _mount_hollow(x: float, y: float, g: float) -> bool:
	if y > g - 170.0 and x > 1250.0 and x < 4750.0:                 # нижний тоннель
		return true
	if y > g - 770.0 and y < g - 600.0 and x > 1900.0 and x < 4100.0:   # верхний тоннель
		return true
	if y > g - 1260.0 and y < g - 940.0 and x > 2520.0 and x < 3480.0:  # пещера
		return true
	for sx in [2060.0, 3940.0]:                                       # шахты вниз
		if absf(x - sx) < 70.0 and y > g - 600.0 and y < g - 170.0:
			return true
	if absf(x - MOUNT_CX) < 70.0 and y > g - 940.0 and y < g - 770.0:  # шахта в пещеру
		return true
	return false

static func _mount_solid(x: float, y: float, g: float) -> bool:
	return y < g and y > g - _mount_height(x) and not _mount_hollow(x, y, g)

static func build_mountain(world: Node) -> Dictionary:
	var w := MOUNT_W
	var g := MOUNT_H - 48.0
	build_frame(world, w, MOUNT_H, false)
	if not preview_mode:
		var sky := PixelArt.make_sprite(PixelArt.valley_backdrop(w, -1500.0, g), PixelArt.SCALE)
		sky.position = Vector2(0, -1500)
		sky.z_index = -10
		world.add_child(sky)
		# тёмный камень позади — его видно в тоннелях и там, где гору разбили
		var back := Image.create(int(w / 8.0), int(g / 8.0) + 1, false, Image.FORMAT_RGBA8)
		for px in back.get_width():
			var x := (px + 0.5) * 8.0
			var top := int((g - _mount_height(x)) / 8.0)
			if top < back.get_height():
				back.fill_rect(Rect2i(px, top, 1, back.get_height() - top), Color(0.22, 0.19, 0.17))
		var bs := PixelArt.make_sprite(back, 8.0)
		bs.z_index = -9
		world.add_child(bs)
	# камень кусками по 10×10 клеток
	var cols := int(w / MCELL)
	var rows := int(g / MCELL)
	var chunk := 10
	for cx0 in range(0, cols, chunk):
		for cy0 in range(0, rows, chunk):
			var d := Destructible.new()
			d.cell = MCELL
			d.cols = chunk
			d.rows = chunk
			d.color = ROCK
			d.cell_hp = 400                # ломать долго
			d.density = 200.0
			d.anchored = true
			for i in chunk:
				for j in chunk:
					var x := (cx0 + i + 0.5) * MCELL
					var y := (cy0 + j + 0.5) * MCELL
					if not _mount_solid(x, y, g):
						continue
					var c := Vector2i(i, j)
					d.cells[c] = d.cell_hp
					d.anchors.append(c)    # гора не обрушивается целиком — только выкрашивается
					var col := ROCK.lerp(ROCK_DARK, randf() * 0.5)
					if not _mount_solid(x, y - MCELL, g) and not _mount_hollow(x, y - MCELL, g):
						col = SNOW if y < g - 1250.0 else GRASS
					d.cell_colors[c] = col
			if d.cells.is_empty():
				d.free()
				continue
			d.position = Vector2((cx0 + chunk / 2.0) * MCELL, (cy0 + chunk / 2.0) * MCELL)
			world.add_child(d)
	# деревянные площадки в шахтах (лестницы) и в пещере
	for sx in [2060.0, 3940.0]:
		for k in 3:
			add_platform(world, Rect2(sx - 60, g - 290.0 - k * 120.0, 120, 20), true)
	add_platform(world, Rect2(MOUNT_CX - 60, g - 890.0, 120, 20), true)
	add_platform(world, Rect2(2620, g - 1070, 200, 20), true)
	add_platform(world, Rect2(3180, g - 1070, 200, 20), true)
	add_platform(world, Rect2(2900, g - 1180, 200, 20), true)
	# ящики в тоннелях
	for x in [1700.0, 2500.0, 3500.0, 4300.0]:
		add_crate(world, Vector2(x, g - 31))
	add_crate(world, Vector2(2300, g - 631))
	add_crate(world, Vector2(3700, g - 631))
	if not preview_mode:
		for p in [Vector2(1500, g - 120), Vector2(2900, g - 120), Vector2(4500, g - 120),
				Vector2(2300, g - 720), Vector2(3700, g - 720), Vector2(2700, g - 1200), Vector2(3300, g - 1200)]:
			var t := Torch.new()
			t.position = p
			t.lit = true
			world.add_child(t)
		# флаг на вершине
		var top_y := g - _mount_height(MOUNT_CX)
		var pole := ColorRect.new()
		pole.color = Color(0.4, 0.3, 0.2)
		pole.position = Vector2(MOUNT_CX - 3, top_y - 140)
		pole.size = Vector2(6, 140)
		pole.z_index = -2
		world.add_child(pole)
		var flag := Polygon2D.new()
		flag.polygon = PackedVector2Array([Vector2(MOUNT_CX + 3, top_y - 140), Vector2(MOUNT_CX + 70, top_y - 118),
				Vector2(MOUNT_CX + 3, top_y - 96)])
		flag.color = Color(0.9, 0.25, 0.2)
		flag.z_index = -2
		world.add_child(flag)
	# деревья на равнинах по краям
	for x in [500.0, 850.0, w - 500.0, w - 850.0]:
		add_tree(world, x, g)
	return {"size": Vector2(w, MOUNT_H), "p1": Vector2(200, g - 37), "p2": Vector2(w - 200, g - 37),
			"follow": true, "open_top": true, "split": true, "min_zoom": 0.45,
			"top_y": -100.0, "sky": [Vector2(700, g - 1700), Vector2(w - 700, g - 1700)]}

# ---------- TEST_BUFFS: дорога с площадками баффов ----------
const BUFFS_W := 4500.0
const BUFFS_H := 900.0

static func build_test_buffs(world: Node) -> Dictionary:
	var w := BUFFS_W
	var g := BUFFS_H - 48.0
	build_frame(world, w, BUFFS_H, false)
	if not preview_mode:
		var sky := PixelArt.make_sprite(PixelArt.valley_backdrop(w, -1500.0, g), PixelArt.SCALE)
		sky.position = Vector2(0, -1500)
		sky.z_index = -10
		world.add_child(sky)
	# дорога
	add_block(world, Rect2(0, g, w, 8), Color(0.55, 0.48, 0.38))
	var types: Array = Buffs.TYPES.keys()
	var x := 420.0
	for t in types:
		for mega in [false, true]:
			var rect := Rect2(x - 80, g - 130, 160, 20)
			Colosseum.plat(world, rect)
			if not preview_mode:
				var sp := PickupSpawner.new()
				sp.kind = "buff"
				sp.fixed = t
				sp.mega = mega
				sp.respawn = 5.0
				sp.position = Vector2(x, g - 130)
				world.add_child(sp)
				var l := Label.new()
				l.text = Buffs.title(t, mega)
				l.size = Vector2(220, 30)
				l.position = Vector2(x - 110, g - 260)
				l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				l.add_theme_font_size_override("font_size", 20)
				l.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3) if mega else Color.WHITE)
				l.add_theme_constant_override("outline_size", 6)
				l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
				world.add_child(l)
			x += 340.0
	return {"size": Vector2(w, BUFFS_H), "p1": Vector2(150, g - 37), "p2": Vector2(w - 150, g - 37),
			"follow": true, "open_top": true, "top_y": -100.0,
			"sky": [Vector2(300, g - 900), Vector2(w - 300, g - 900)]}

# ---------- Арены для Дуэли (скрытые карты) ----------
# Цитадель во тьме: место третьей фазы Тёмного Лорда, бой — между стенами мрака
static func build_citadel_dark(world: Node) -> Dictionary:
	var info := build_arena(world, 16)
	var f: float = info["floor"]
	DarkAvatar.dark_stage(world, f)
	info["p1"] = Vector2(DarkAvatar.INNER_L + 160.0, f - 32)
	info["p2"] = Vector2(DarkAvatar.INNER_R - 160.0, f - 32)
	info["x_lo"] = DarkAvatar.INNER_L
	info["x_hi"] = DarkAvatar.INNER_R
	info["cam_rect"] = Rect2(DarkAvatar.INNER_L - 70.0, 110.0, DarkAvatar.INNER_R - DarkAvatar.INNER_L + 140.0, f + 60.0 - 110.0)
	return info

static func build_arena(world: Node, stage: int) -> Dictionary:
	var info: Dictionary
	match stage:
		0: info = ForestTrail.build(world)
		1: info = VillageEdge.build(world)
		2: info = Jungle.build(world, false)
		3: info = Jungle.build(world, true)
		4: info = Caves.build(world, false)
		5: info = Caves.build(world, true)
		6: info = GemCaves.build(world, false)
		7: info = GemCaves.build(world, true)
		8: info = Colosseum.build(world, 0, false)
		9: info = Colosseum.build(world, 2, true)
		10: info = EerieWoods.build(world, false)
		11: info = EerieWoods.build(world, true)
		_: info = FarStages.build(world, stage)
	var f: float = info["floor"]
	info["p1"] = Vector2(420, f - 32)
	info["p2"] = Vector2(Colosseum.W - 420, f - 32)
	info["follow"] = true
	info["open_top"] = false
	info["top_y"] = 50.0 if stage >= 4 and stage <= 7 else 10.0
	info["sky"] = []
	return info

# ---------- Строительные блоки карт ----------

# Неразрушаемая рамка: пол, стены, фон и (если ceiling) потолок.
# Без потолка над картой небо, а стены уходят высоко вверх.
static func build_frame(world: Node, w: float, h: float, ceiling: bool) -> void:
	var top := 0.0 if ceiling else -3000.0
	var bg := ColorRect.new()
	bg.color = Color(0.28, 0.27, 0.31) if ceiling else Color(0.26, 0.44, 0.78)
	bg.position = Vector2(0, top)
	bg.size = Vector2(w, h - top)
	bg.z_index = -10
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	world.add_child(bg)
	add_block(world, Rect2(0, h - 48, w, 48))
	if ceiling:
		add_block(world, Rect2(0, 0, w, 20))
	add_block(world, Rect2(0, top, 20, h - top))
	add_block(world, Rect2(w - 20, top, 20, h - top))

static func add_block(world: Node, rect: Rect2, color := GROUND) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Layer.WORLD | Layer.FRAME
	body.position = rect.get_center()
	var col := CollisionShape2D.new()
	var rs := RectangleShape2D.new()
	rs.size = rect.size
	col.shape = rs
	body.add_child(col)
	body.add_child(block_visual(rect.size, color))
	body.set_meta("color", color)
	world.add_child(body)

# Текстура неразрушаемого блока (пол, стена, свод): плитка по материалу
static func block_visual(size: Vector2, color: Color) -> Control:
	var k := 2.5
	var vis := TextureRect.new()
	vis.texture = Tex.tile(Tex.material_for(color), color)
	vis.stretch_mode = TextureRect.STRETCH_TILE
	vis.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	vis.size = size / k
	vis.scale = Vector2(k, k)
	vis.position = -size / 2
	vis.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if size.y <= 12.0:
		vis.modulate = Color(1.08, 1.08, 1.08)      # тонкая кромка поверх пола — чуть светлее
	return vis

static func make_destructible(rect: Rect2, cell: float, color: Color, cell_hp: int,
		density: float) -> Destructible:
	var d := Destructible.new()
	d.position = rect.get_center()
	d.cell = cell
	d.cols = int(rect.size.x / cell)
	d.rows = int(rect.size.y / cell)
	d.color = color
	d.cell_hp = cell_hp
	d.density = density
	return d

# Платформа: держится за три центральные клетки
# one_way — сквозь платформу можно пропрыгнуть снизу (на Арене)
static func add_platform(world: Node, rect: Rect2, one_way := false) -> void:
	var d := make_destructible(rect, 20.0, PLAT, 35, 30.0)
	d.one_way = one_way
	d.anchored = true
	var mid := int(d.cols / 2.0)
	for x in range(mid - 1, mid + 2):
		for y in d.rows:
			d.anchors.append(Vector2i(x, y))
	world.add_child(d)

# Каменная колонна: держится за землю нижним рядом
static func add_column(world: Node, rect: Rect2) -> void:
	var d := make_destructible(rect, 20.0, STONE, 70, 45.0)
	d.anchored = true
	for x in d.cols:
		d.anchors.append(Vector2i(x, d.rows - 1))
	world.add_child(d)

# Ящик: свободный физический объект
static func add_crate(world: Node, pos: Vector2) -> void:
	var rect := Rect2(pos - Vector2(30, 30), Vector2(60, 60))
	world.add_child(make_destructible(rect, 15.0, CRATE, 28, 20.0))

# ---------- Эскиз карты для свитка ----------
# Карта строится «вхолостую» (не попадая в игру), а её блоки рисуются
# коричневыми чернилами на картинке размером не больше max_size.
static func preview_image(id: String, max_size: Vector2) -> Image:
	var tmp := Node2D.new()
	preview_mode = true
	var info := build(tmp, id)
	preview_mode = false
	var size: Vector2 = info["size"]
	var top := -400.0 if info.get("open_top", false) else 0.0
	var k := minf(max_size.x / size.x, max_size.y / (size.y - top))
	var img := Image.create(int(size.x * k) + 2, int((size.y - top) * k) + 2, false, Image.FORMAT_RGBA8)
	# цветной эскиз: настоящие цвета карты, чуть приглушённые «бумагой»
	var paper := Color(0.92, 0.84, 0.66)
	var tint := func(c: Color, a := 1.0) -> Color:
		var m := c.lerp(paper, 0.18)
		m.a = a
		return m
	for n in tmp.get_children():
		if n is ColorRect:               # фон карты (небо или стена зала)
			var r := Rect2(n.position, n.size)
			_ink_rect(img, r, k, top, tint.call(n.color.lightened(0.3), 0.85))
	for pass_bg in [true, false]:
		for n in tmp.get_children():
			if n is StaticBody2D and not pass_bg:
				var col: Color = n.get_meta("color", Color(0.33, 0.20, 0.10))
				for c in n.get_children():
					if c is ColorRect:
						col = c.color
				for c in n.get_children():
					if c is CollisionShape2D and c.shape is RectangleShape2D:
						var r := Rect2(n.position + c.position - c.shape.size / 2, c.shape.size)
						_ink_rect(img, r, k, top, tint.call(col))
			elif n is Destructible and n.background == pass_bg:
				var d: Destructible = n
				var cells: Array = d.cells.keys()
				if cells.is_empty():
					for x in d.cols:
						for y in d.rows:
							cells.append(Vector2i(x, y))
				var origin := d.position - Vector2(d.cols, d.rows) * d.cell / 2.0
				for c in cells:
					var r := Rect2(origin + Vector2(c) * d.cell, Vector2(d.cell, d.cell))
					var cc: Color = d.cell_colors.get(c, d.color)
					if d.background:
						cc = cc.darkened(0.15)
					_ink_rect(img, r, k, top, tint.call(cc, 0.8 if d.background else 1.0))
	for key in ["p1", "p2"]:
		var p: Vector2 = info[key]
		var col := Config.OUTLINE_P1 if key == "p1" else Config.OUTLINE_P2
		var cx := int(p.x * k)
		var cy := int((p.y - top) * k)
		img.fill_rect(Rect2i(cx - 3, cy - 6, 6, 9), col)
	tmp.free()
	return img

static func _ink_rect(img: Image, r: Rect2, k: float, top: float, c: Color) -> void:
	var x0 := int(r.position.x * k)
	var y0 := int((r.position.y - top) * k)
	var w := maxi(1, int(ceil(r.size.x * k)))
	var h := maxi(1, int(ceil(r.size.y * k)))
	var rect := Rect2i(x0, y0, w, h).intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	if rect.size.x > 0 and rect.size.y > 0:
		img.fill_rect(rect, c)
