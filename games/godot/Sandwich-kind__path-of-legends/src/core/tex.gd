class_name Tex
# ---------- Процедурные текстуры мира ----------
# Каждый объект из клеток (ящик, колонна, стена дома, платформа...) получает
# одну цельную пиксельную картинку на весь объект: доски и гвозди у ящика,
# каннелюры и капитель у колонны, кладка у стен, кора у брёвен и т.д.
# Клетки берут из неё свой кусочек — физика остаётся прежней (клетки
# откалываются по одной), а вместе они выглядят как настоящий предмет.
# Края объекта (там, где нет соседней клетки) получают контур, блик сверху
# и тень снизу — поэтому даже выбитый кусок выглядит объёмным.

static var _tile_cache := {}
static var _crack_cache := {}

# Сколько пикселей рисунка в одной клетке (1 пиксель рисунка ≈ 2,5 точки мира)
static func texel(cell: float) -> int:
	return maxi(4, int(round(cell / 2.5)))

# Материал по цвету объекта
static func material_for(c: Color) -> String:
	var table := [
		[Maps.CRATE, "crate"], [Maps.STONE, "stone"], [Maps.PLAT, "plat"], [Maps.BRICK, "brick"],
		[Maps.ROOF, "roof"], [Maps.WOOD, "wood"], [Maps.BACK_WALL, "backwall"], [Maps.TRUNK, "log"],
		[Maps.LEAVES, "leaves"], [Maps.ROCK, "rock"], [Maps.ROCK_DARK, "rock"], [Maps.GRASS, "grass"],
		[Maps.SNOW, "snow"], [Maps.GROUND, "ground"],
		[Caves.ROCK, "rock"], [Caves.ROCK_DEEP, "rock"], [Caves.STALAG, "rock"], [Caves.SCAFFOLD, "wood"],
		[Jungle.DIRT, "dirt"], [Jungle.GRASS, "grass"], [Jungle.BARK, "log"], [Jungle.MOSS, "moss"],
		[Jungle.LOG, "log"], [Colosseum.SAND, "sand"], [Colosseum.WALL_STONE, "stone"],
		[Colosseum.LEDGE, "stone"],
		[FarStages.ICE, "crystal"], [FarStages.ICE_WALL, "crystal"], [FarStages.SNOW_FLOOR, "snow"],
		[FarStages.TEMPLE, "stone"], [FarStages.TEMPLE_FLOOR, "ground"], [FarStages.BASALT, "darkrock"],
		[FarStages.OBSIDIAN, "darkrock"], [FarStages.HALL, "stone"], [FarStages.HALL_FLOOR, "ground"],
	]
	var best := "generic"
	var bd := 0.07
	for row in table:
		var k: Color = row[0]
		var d := absf(k.r - c.r) + absf(k.g - c.g) + absf(k.b - c.b)
		if d < bd:
			bd = d
			best = row[1]
	if best == "generic":
		# похожие оттенки (светлее/темнее) — ищем по семейству
		var d2 := 1e9
		for row in table:
			var k: Color = row[0]
			var hue_d := absf(k.h - c.h) * 2.0 + absf(k.s - c.s)
			if hue_d < 0.25 and hue_d < d2 and row[1] in ["rock", "stone", "sand", "dirt", "grass"]:
				d2 = hue_d
				best = row[1]
	return best

# ---------- Картинка для целого объекта из клеток ----------
static func object_image(mat: String, cells: Dictionary, cols: int, rows: int, tp: int, c: Color,
		seed_v: int) -> Image:
	var w := cols * tp
	var h := rows * tp
	var im := Image.create(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	paint(im, mat, c, rng, cols, rows, tp)
	if mat != "energy":
		_edges(im, cells, tp, c)
	return im

static func paint(im: Image, mat: String, c: Color, rng: RandomNumberGenerator, cols: int, rows: int, tp: int) -> void:
	var w := im.get_width()
	var h := im.get_height()
	match mat:
		"crate":
			_crate(im, w, h, c, rng)
		"stone":
			if cols <= 3 and rows >= cols * 2:
				_column(im, w, h, c, rng)
			else:
				_ashlar(im, w, h, c, rng, maxi(3, tp / 2 + 1), tp, 0.07)
		"plat":
			_plat(im, w, h, c, rng, tp)
		"brick":
			_ashlar(im, w, h, c, rng, 3, 6, 0.09)
		"backwall":
			_ashlar(im, w, h, c.darkened(0.08), rng, 3, 7, 0.05)
			_noise(im, 0.04, rng)
		"roof":
			_roof(im, w, h, c, rng)
		"wood":
			_planks(im, w, h, c, rng, w >= h)
		"log":
			_bark(im, w, h, c, rng, w > h * 1.5)
		"leaves":
			_leaves(im, w, h, c, rng)
		"rock":
			_rock(im, w, h, c, rng)
		"moss":
			_rock(im, w, h, c.darkened(0.1), rng)
			_moss(im, w, h, rng)
		"grass":
			_dirt(im, w, h, Color(0.42, 0.31, 0.2), rng)
			_grass_top(im, w, c, rng)
		"snow":
			_snow(im, w, h, c, rng)
		"dirt":
			_dirt(im, w, h, c, rng)
		"sand":
			_sand(im, w, h, c, rng)
		"ground":
			_ashlar(im, w, h, c, rng, 4, 9, 0.05)
			_noise(im, 0.05, rng)
		"iron":
			_iron(im, w, h, c, rng, tp)
		"energy":
			_energy(im, w, h, c)
		"gem":
			DeepArt.paint_gem(im, w, h, c, rng, tp)
		"crystal":
			DeepArt.paint_crystal(im, w, h, c, rng, tp)
		"mine_wood":
			_planks(im, w, h, c, rng, w >= h)
			DeepArt.paint_bolts(im, w, h, rng)
		"darkrock":
			_rock(im, w, h, c, rng)
			DeepArt.paint_veins(im, w, h, rng)
		_:
			im.fill(c)
			_noise(im, 0.07, rng)

# ---------- Плитка для неразрушаемых блоков (пол, стены, своды) ----------
static func tile(mat: String, c: Color) -> ImageTexture:
	var key := "%s_%s" % [mat, c.to_html()]
	if _tile_cache.has(key):
		return _tile_cache[key]
	var im := Image.create(32, 32, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key)
	paint(im, mat, c, rng, 4, 4, 8)
	var t := ImageTexture.create_from_image(im)
	_tile_cache[key] = t
	return t

# Трещины поверх повреждённой клетки (1 — первые трещины, 2 — сильные)
static func cracks(tp: int, stage: int) -> ImageTexture:
	var key := tp * 10 + stage
	if _crack_cache.has(key):
		return _crack_cache[key]
	var im := Image.create(tp, tp, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = key * 7919
	var col := Color(0.05, 0.03, 0.03, 0.75)
	for k in stage + 1:
		var p := Vector2(rng.randi_range(1, tp - 2), rng.randi_range(1, tp - 2))
		for i in tp + stage * 2:
			_px(im, int(p.x), int(p.y), col)
			p += Vector2(rng.randi_range(-1, 1), rng.randi_range(-1, 1))
			p = p.clamp(Vector2.ZERO, Vector2(tp - 1, tp - 1))
	var t := ImageTexture.create_from_image(im)
	_crack_cache[key] = t
	return t

# ---------- Помощники ----------
static func _px(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, c)

static func _rect(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, im.get_width(), im.get_height()))
	if r.size.x > 0 and r.size.y > 0:
		im.fill_rect(r, c)

static func _shade(im: Image, x: int, y: int, k: float) -> void:
	if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
		return
	var p := im.get_pixel(x, y)
	if p.a <= 0.0:
		return
	im.set_pixel(x, y, p.lightened(k) if k > 0.0 else p.darkened(-k))

static func _noise(im: Image, amount: float, rng: RandomNumberGenerator) -> void:
	for y in im.get_height():
		for x in im.get_width():
			_shade(im, x, y, rng.randf_range(-amount, amount))

# Контур, блик и тень по краям объекта (где нет соседней клетки)
static func _edges(im: Image, cells: Dictionary, tp: int, base: Color) -> void:
	var outline := base.darkened(0.6)
	for cc in cells:
		var x0: int = cc.x * tp
		var y0: int = cc.y * tp
		var up := not cells.has(cc + Vector2i(0, -1))
		var down := not cells.has(cc + Vector2i(0, 1))
		var left := not cells.has(cc + Vector2i(-1, 0))
		var right := not cells.has(cc + Vector2i(1, 0))
		for i in tp:
			if up:
				_shade(im, x0 + i, y0 + 1, 0.18)
				_px(im, x0 + i, y0, outline)
			if down:
				_shade(im, x0 + i, y0 + tp - 2, -0.22)
				_px(im, x0 + i, y0 + tp - 1, outline)
			if left:
				_shade(im, x0 + 1, y0 + i, 0.08)
				_px(im, x0, y0 + i, outline)
			if right:
				_shade(im, x0 + tp - 2, y0 + i, -0.14)
				_px(im, x0 + tp - 1, y0 + i, outline)

# ---------- Материалы ----------
# Деревянный ящик: доски, рама, диагональная распорка, гвозди
static func _crate(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator) -> void:
	im.fill(c)
	var pb := maxi(3, h / 5)
	for y in h:
		if y % pb == 0:
			_rect(im, 0, y, w, 1, c.darkened(0.35))
		for x in w:
			if rng.randf() < 0.12:
				_shade(im, x, y, rng.randf_range(-0.12, 0.06))
	for k in w / 3:                                             # волокна
		var gy := rng.randi_range(0, h - 1)
		var gx := rng.randi_range(0, w - 4)
		_rect(im, gx, gy, rng.randi_range(2, 5), 1, c.darkened(0.15))
	var fw := maxi(2, w / 9)
	var fc := c.lightened(0.1)
	for b in [[0, 0, w, fw], [0, h - fw, w, fw], [0, 0, fw, h], [w - fw, 0, fw, h]]:
		_rect(im, b[0], b[1], b[2], b[3], fc)
	_rect(im, fw, fw, w - fw * 2, 1, c.darkened(0.4))          # тень под рамой
	_rect(im, fw, fw, 1, h - fw * 2, c.darkened(0.3))
	_rect(im, 0, fw - 1, w, 1, fc.darkened(0.25))
	_rect(im, 0, h - fw, w, 1, fc.lightened(0.15))
	# диагональная распорка
	var n := maxi(w, h)
	for i in n:
		var x := int(lerpf(fw, w - fw - 1, float(i) / n))
		var y := int(lerpf(h - fw - 1, fw, float(i) / n))
		_px(im, x, y, fc)
		_px(im, x + 1, y, fc)
		_px(im, x, y + 1, fc.darkened(0.35))
	# гвозди
	var nail := Color(0.72, 0.72, 0.76)
	for p in [Vector2i(fw / 2, fw / 2), Vector2i(w - 1 - fw / 2, fw / 2), Vector2i(fw / 2, h - 1 - fw / 2),
			Vector2i(w - 1 - fw / 2, h - 1 - fw / 2), Vector2i(w / 2, fw / 2), Vector2i(w / 2, h - 1 - fw / 2)]:
		_px(im, p.x, p.y, nail)
		_px(im, p.x + 1, p.y + 1, nail.darkened(0.5))

# Колонна: каннелюры, капитель и база, объём слева-направо
static func _column(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator) -> void:
	for x in w:
		var k := lerpf(0.12, -0.18, float(x) / maxf(w - 1, 1))
		var col := c.lightened(k) if k > 0.0 else c.darkened(-k)
		_rect(im, x, 0, 1, h, col)
		if x % 3 == 1:
			_rect(im, x, 0, 1, h, col.darkened(0.16))           # желобок
	var cap := maxi(2, h / 14)
	_rect(im, 0, 0, w, cap, c.lightened(0.18))
	_rect(im, 0, cap, w, 1, c.darkened(0.35))
	_rect(im, 0, cap + 1, w, 1, c.lightened(0.08))
	_rect(im, 0, h - cap, w, cap, c.lightened(0.05))
	_rect(im, 0, h - cap - 1, w, 1, c.darkened(0.3))
	for k2 in 3:                                                # трещинки и сколы
		var p := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(cap + 2, h - cap - 2))
		for i in rng.randi_range(2, 5):
			_shade(im, p.x, p.y, -0.25)
			p += Vector2i(rng.randi_range(-1, 1), 1)
	_noise(im, 0.035, rng)

# Тёсаный камень / кирпич: ряды блоков со швами
static func _ashlar(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator, bh: int, bw: int,
		vary: float) -> void:
	var mortar := c.darkened(0.38)
	im.fill(mortar)
	var row := 0
	var y := 0
	while y < h:
		var off := (bw / 2) if row % 2 == 1 else 0
		var x := -off
		while x < w:
			var bc := c.lightened(rng.randf_range(-vary, vary)) if rng.randf() < 0.5 else c.darkened(rng.randf_range(0.0, vary))
			_rect(im, x + 1, y + 1, bw - 1, bh - 1, bc)
			_rect(im, x + 1, y + 1, bw - 1, 1, bc.lightened(0.12))        # верхняя грань блока светлее
			_rect(im, x + 1, y + bh - 1, bw - 1, 1, bc.darkened(0.12))
			if rng.randf() < 0.3:
				_px(im, x + rng.randi_range(2, bw - 2), y + rng.randi_range(1, bh - 1), bc.darkened(0.25))
			x += bw
		y += bh
		row += 1

# Плита платформы: светлая кромка сверху, швы, тень снизу
static func _plat(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator, tp: int) -> void:
	im.fill(c)
	_noise(im, 0.05, rng)
	_rect(im, 0, 0, w, 1, c.lightened(0.3))
	_rect(im, 0, 1, w, 1, c.lightened(0.12))
	_rect(im, 0, h - 1, w, 1, c.darkened(0.4))
	_rect(im, 0, h - 2, w, 1, c.darkened(0.18))
	var x := tp + rng.randi_range(0, tp)
	while x < w:
		_rect(im, x, 2, 1, h - 3, c.darkened(0.3))
		_rect(im, x + 1, 2, 1, h - 3, c.lightened(0.08))
		x += tp * 2 + rng.randi_range(-1, 2)

# Доски (горизонтальные или вертикальные) с волокнами и гвоздями
static func _planks(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator, horizontal: bool) -> void:
	im.fill(c)
	var n := w if not horizontal else h
	var size := 4
	for i in n:
		if i % size == 0:
			if horizontal:
				_rect(im, 0, i, w, 1, c.darkened(0.35))
			else:
				_rect(im, i, 0, 1, h, c.darkened(0.35))
	for k in (w * h) / 10:
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		if horizontal:
			_rect(im, x, y, rng.randi_range(2, 4), 1, c.darkened(rng.randf_range(0.05, 0.15)))
		else:
			_rect(im, x, y, 1, rng.randi_range(2, 4), c.darkened(rng.randf_range(0.05, 0.15)))
	for i in range(2, n, size):
		var p := Vector2i(1, i) if horizontal else Vector2i(i, 1)
		_px(im, p.x, p.y, Color(0.75, 0.75, 0.78))

# Кора бревна / ствола
static func _bark(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator, horizontal: bool) -> void:
	im.fill(c)
	for k in (w * h) / 6:
		var x := rng.randi_range(0, w - 1)
		var y := rng.randi_range(0, h - 1)
		var l := rng.randi_range(2, 6)
		if horizontal:
			_rect(im, x, y, l, 1, c.darkened(0.3))
			_rect(im, x, y - 1, l, 1, c.lightened(0.08))
		else:
			_rect(im, x, y, 1, l, c.darkened(0.3))
			_rect(im, x + 1, y, 1, l, c.lightened(0.08))
	for k in maxi(1, (w * h) / 220):                                  # сучки
		var kx := rng.randi_range(2, w - 3)
		var ky := rng.randi_range(2, h - 3)
		_rect(im, kx - 1, ky - 1, 3, 3, c.darkened(0.35))
		_px(im, kx, ky, c.darkened(0.55))

# Листва: тёмная основа, светлые пучки листьев
static func _leaves(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator) -> void:
	im.fill(c.darkened(0.22))
	for k in (w * h) / 9:
		var cx := rng.randi_range(0, w - 1)
		var cy := rng.randi_range(0, h - 1)
		var r := rng.randi_range(1, 3)
		var lc := c.lightened(rng.randf_range(-0.05, 0.12))
		for y in range(-r, r + 1):
			for x in range(-r, r + 1):
				if x * x + y * y <= r * r:
					_px(im, cx + x, cy + y, lc)
		_px(im, cx - r / 2, cy - r / 2, lc.lightened(0.25))
	for k in (w * h) / 30:
		_px(im, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), c.darkened(0.45))

# Черепица: ряды со смещением, у каждой плитки тень снизу
static func _roof(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator) -> void:
	im.fill(c)
	var rh := 3
	var row := 0
	for y in range(0, h, rh):
		var off := 3 if row % 2 else 0
		_rect(im, 0, y + rh - 1, w, 1, c.darkened(0.35))
		_rect(im, 0, y, w, 1, c.lightened(0.1))
		for x in range(-off, w, 6):
			_rect(im, x, y, 1, rh, c.darkened(0.25))
			if rng.randf() < 0.3:
				_rect(im, x + 1, y + 1, 4, 1, c.lightened(0.06))
		row += 1

# Скала: пятна света и тени, трещины, камешки
static func _rock(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator) -> void:
	var g := 6
	var gw := w / g + 2
	var gh := h / g + 2
	var grid := []
	for i in gw * gh:
		grid.append(rng.randf_range(-1.0, 1.0))
	for y in h:
		for x in w:
			var fx := float(x) / g
			var fy := float(y) / g
			var ix := int(fx)
			var iy := int(fy)
			var tx := fx - ix
			var ty := fy - iy
			var a: float = lerpf(grid[iy * gw + ix], grid[iy * gw + ix + 1], tx)
			var b: float = lerpf(grid[(iy + 1) * gw + ix], grid[(iy + 1) * gw + ix + 1], tx)
			var v := lerpf(a, b, ty) * 0.11 + rng.randf_range(-0.03, 0.03)
			im.set_pixel(x, y, c.lightened(v) if v > 0.0 else c.darkened(-v))
	for k in maxi(1, (w * h) / 120):
		var p := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
		for i in rng.randi_range(3, 7):
			_shade(im, p.x, p.y, -0.3)
			_shade(im, p.x + 1, p.y, 0.1)
			p += Vector2i(rng.randi_range(-1, 1), rng.randi_range(0, 1))
	for k in (w * h) / 40:
		var q := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
		_shade(im, q.x, q.y, 0.2)
		_shade(im, q.x, q.y + 1, -0.2)

static func _moss(im: Image, w: int, h: int, rng: RandomNumberGenerator) -> void:
	var mc := Color(0.32, 0.55, 0.26)
	for x in w:
		var d := rng.randi_range(1, 3) + (2 if rng.randf() < 0.15 else 0)
		for y in d:
			_px(im, x, y, mc.lightened(0.15) if y == 0 else mc)
	for k in (w * h) / 25:
		_px(im, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), mc.darkened(0.1))

static func _dirt(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator) -> void:
	_rock(im, w, h, c, rng)
	for k in (w * h) / 35:
		var p := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
		_px(im, p.x, p.y, Color(0.6, 0.55, 0.5))                       # камешки
		_px(im, p.x, p.y + 1, c.darkened(0.3))
	for k in maxi(1, w / 12):                                             # корешки
		var r := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
		for i in 5:
			_px(im, r.x, r.y, c.darkened(0.4))
			r += Vector2i(rng.randi_range(-1, 1), 1)

static func _grass_top(im: Image, w: int, c: Color, rng: RandomNumberGenerator) -> void:
	for x in w:
		var d := 2 + rng.randi_range(0, 2)
		for y in d:
			_px(im, x, y, c.lightened(0.12) if y == 0 else c)
		if rng.randf() < 0.4:
			_px(im, x, 0, c.lightened(0.3))
		_px(im, x, d, c.darkened(0.3))

static func _snow(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator) -> void:
	for y in h:
		for x in w:
			var k := float(y) / maxf(h, 1)
			im.set_pixel(x, y, c.lerp(Color(0.72, 0.8, 0.95), k * 0.5).lightened(rng.randf_range(-0.03, 0.03)))
	for k in (w * h) / 30:
		_px(im, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color(1, 1, 1))

static func _sand(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator) -> void:
	im.fill(c)
	_noise(im, 0.05, rng)
	for k in (w * h) / 16:
		_px(im, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), c.darkened(0.15))
	for y in range(3, h, 8):                                           # следы ветра
		var x := rng.randi_range(0, w - 1)
		_rect(im, x, y, rng.randi_range(4, 9), 1, c.lightened(0.1))

# Металл: листы с заклёпками, фаска, царапины
static func _iron(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator, tp: int) -> void:
	im.fill(c)
	var plate := tp * 2
	for y in range(0, h, plate):
		for x in range(0, w, plate):
			_rect(im, x, y, plate, 1, c.lightened(0.25))
			_rect(im, x, y, 1, plate, c.lightened(0.15))
			_rect(im, x, y + plate - 1, plate, 1, c.darkened(0.35))
			_rect(im, x + plate - 1, y, 1, plate, c.darkened(0.25))
			for r in [Vector2i(2, 2), Vector2i(plate - 3, 2), Vector2i(2, plate - 3), Vector2i(plate - 3, plate - 3)]:
				_px(im, x + r.x, y + r.y, c.lightened(0.45))
				_px(im, x + r.x + 1, y + r.y + 1, c.darkened(0.4))
	for k in (w * h) / 60:
		var p := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
		_rect(im, p.x, p.y, rng.randi_range(2, 4), 1, c.lightened(0.12))
	_noise(im, 0.025, rng)

# Щит из энергии: прозрачный, с бликами-полосами и яркой кромкой
static func _energy(im: Image, w: int, h: int, c: Color) -> void:
	for y in h:
		for x in w:
			var stripe := (x + y) % 6 < 2
			var col := c.lightened(0.25) if stripe else c
			col.a = c.a * (0.95 if stripe else 0.75)
			if x == 0 or y == 0 or x == w - 1 or y == h - 1:
				col = c.lightened(0.5)
				col.a = 0.95
			im.set_pixel(x, y, col)

# Наложить текстуру материала на многоугольник (скалы у входов, арки, камни)
static func apply(poly: Polygon2D, mat: String, c: Color) -> void:
	poly.texture = tile(mat, c)
	poly.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	poly.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	poly.texture_scale = Vector2(0.4, 0.4)
	poly.color = Color.WHITE

# Цельная плита по размеру (платформы, уступы): рисунок с краями под точный размер
static func slab(size: Vector2, mat: String, c: Color, seed_v := 1) -> Sprite2D:
	var tw := maxi(2, int(round(size.x / 2.5)))
	var th := maxi(2, int(round(size.y / 2.5)))
	var im := Image.create(tw, th, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	paint(im, mat, c, rng, maxi(1, tw / 8), maxi(1, th / 8), 8)
	var outline := c.darkened(0.6)
	for x in tw:
		im.set_pixel(x, 0, outline)
		im.set_pixel(x, th - 1, outline)
	for y in th:
		im.set_pixel(0, y, outline)
		im.set_pixel(tw - 1, y, outline)
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(im)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.scale = size / Vector2(tw, th)
	return s
