class_name DeepArt
# ---------- Рисунки Драгоценных и Кристальных пещер ----------
# Фоны, материалы блоков (самоцветная порода, кристалл, крепь шахты) и картинки
# предметов (вагонетка, фонарь, зеркальный кристалл, призма).
# Самоцветы и кристаллы рисуются насыщенными цветами — на них ложится перелив (Shimmer).

const GEMS := [Color(0.92, 0.18, 0.28), Color(0.20, 0.78, 0.42), Color(0.25, 0.48, 0.95),
		Color(0.70, 0.35, 0.92), Color(0.98, 0.72, 0.18)]
const ROCK := Color(0.22, 0.20, 0.25)
const CRYSTAL := Color(0.55, 0.80, 1.0)
const CRYSTAL_V := Color(0.72, 0.55, 1.0)

static func _px(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		im.set_pixel(x, y, c)

static func _shade(im: Image, x: int, y: int, k: float) -> void:
	if x < 0 or y < 0 or x >= im.get_width() or y >= im.get_height():
		return
	var p := im.get_pixel(x, y)
	if p.a <= 0.0:
		return
	var q := p.lightened(k) if k > 0.0 else p.darkened(-k)
	q.a = p.a
	im.set_pixel(x, y, q)

# Огранённый камушек: светлая грань сверху-слева, тёмная снизу-справа, искра
static func gem(im: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(-r, r + 1):
		var hw := r - absi(y)
		for x in range(-hw, hw + 1):
			var k := 0.0
			if x + y < 0:
				k = 0.22
			elif x + y > 0:
				k = -0.22
			if absi(x) + absi(y) == r:
				k -= 0.25
			_px(im, cx + x, cy + y, c.lightened(k) if k > 0.0 else c.darkened(-k))
	_px(im, cx - r / 2, cy - r / 2, Color(1, 1, 1, 0.95))

# ---------- Материалы блоков ----------
# Порода с вкраплениями самоцветов (c — цвет самоцветов)
static func paint_gem(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator, tp: int) -> void:
	Tex._rock(im, w, h, ROCK, rng)
	var n := maxi(2, (w * h) / 55)
	for i in n:
		var gc: Color = c if rng.randf() < 0.8 else GEMS[rng.randi() % GEMS.size()]
		gc = gc.lightened(rng.randf_range(-0.08, 0.12))
		gem(im, rng.randi_range(1, w - 2), rng.randi_range(1, h - 2), rng.randi_range(1, 3), gc)
	# тёмные трещинки породы между камнями
	for k in maxi(1, (w * h) / 150):
		var p := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
		for j in rng.randi_range(2, 5):
			_shade(im, p.x, p.y, -0.25)
			p += Vector2i(rng.randi_range(-1, 1), 1)

# Кристалл: косые грани, светлые рёбра, мягкий градиент и искры
static func paint_crystal(im: Image, w: int, h: int, c: Color, rng: RandomNumberGenerator, tp: int) -> void:
	var off := rng.randi_range(0, 7)
	for y in h:
		for x in w:
			var f := int(floor((x * 0.8 + y + off) / 7.0))
			var g := (x * 0.8 + y + off) - f * 7.0
			var k := 0.10 if f % 2 == 0 else -0.06
			k += 0.12 * (1.0 - float(y) / maxf(h, 1))          # к верху светлее
			if g < 1.0:
				k += 0.28                                       # ребро грани
			var q := c.lightened(k) if k > 0.0 else c.darkened(-k)
			q.a = 0.92
			im.set_pixel(x, y, q)
	for i in maxi(1, (w * h) / 70):
		_px(im, rng.randi_range(0, w - 1), rng.randi_range(0, h - 1), Color(1, 1, 1, 0.9))

# Болты и железные скобы на досках крепи
static func paint_bolts(im: Image, w: int, h: int, rng: RandomNumberGenerator) -> void:
	for i in maxi(1, (w * h) / 90):
		var x := rng.randi_range(1, w - 2)
		var y := rng.randi_range(1, h - 2)
		_px(im, x, y, Color(0.30, 0.30, 0.34))
		_px(im, x, y - 1, Color(0.55, 0.55, 0.6))

# Тёмная порода с тонкими светящимися жилками
static func paint_veins(im: Image, w: int, h: int, rng: RandomNumberGenerator) -> void:
	for k in maxi(1, (w * h) / 260):
		var p := Vector2i(rng.randi_range(0, w - 1), rng.randi_range(0, h - 1))
		var vc: Color = GEMS[rng.randi() % GEMS.size()].darkened(0.15)
		for j in rng.randi_range(4, 9):
			_px(im, p.x, p.y, vc)
			p += Vector2i(rng.randi_range(-1, 1), rng.randi_range(0, 1))

# ---------- Фон Драгоценных пещер ----------
static func gem_backdrop(map_w: float, floor_y: float) -> Image:
	var w := int(map_w / PixelArt.SCALE)
	var h := int(floor_y / PixelArt.SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var top := Color(0.07, 0.06, 0.09)
	var bottom := Color(0.19, 0.15, 0.18)
	PixelArt._vgrad(img, 0, w, 0, h, top, bottom, 16)
	# пятна породы
	for i in 220:
		var yy := rng.randi_range(0, h)
		var base := top.lerp(bottom, float(yy) / h)
		PixelArt._circle(img, rng.randi_range(0, w), yy, rng.randi_range(2, 7),
				base.darkened(rng.randf_range(0.05, 0.2)) if i % 2 == 0 else base.lightened(rng.randf_range(0.02, 0.07)))
	# дальние штольни — тёмные арки с крепью
	for ax in range(40, w, 150):
		var aw := rng.randi_range(22, 30)
		var ah := rng.randi_range(36, 48)
		var ay := h - ah - 6
		for y in ah:
			var t := float(y) / ah
			var hw := int(aw * (0.75 + 0.25 * sqrt(clampf(t * 3.0, 0.0, 1.0))))
			img.fill_rect(Rect2i(ax - hw, ay + y, hw * 2, 1), Color(0.03, 0.02, 0.04))
		for s in [-1, 1]:
			img.fill_rect(Rect2i(ax + s * aw - (2 if s > 0 else 0), ay + 4, 3, ah - 4), Color(0.30, 0.20, 0.12))
		img.fill_rect(Rect2i(ax - aw - 2, ay + 2, aw * 2 + 4, 3), Color(0.34, 0.23, 0.14))
		# тусклый фонарь в глубине штольни
		PixelArt._halo(img, ax, ay + 14, 10, Color(1.0, 0.7, 0.3, 0.25))
		img.fill_rect(Rect2i(ax - 1, ay + 12, 3, 4), Color(1.0, 0.8, 0.4))
	# жилы самоцветов с ореолом света
	for i in 70:
		var gx := rng.randi_range(0, w)
		var gy := rng.randi_range(8, h - 18)
		var gc: Color = GEMS[rng.randi() % GEMS.size()]
		PixelArt._halo(img, gx, gy, rng.randi_range(5, 9), Color(gc, 0.18))
		for k in rng.randi_range(2, 5):
			gem(img, gx + rng.randi_range(-4, 4), gy + rng.randi_range(-3, 3), rng.randi_range(1, 2), gc.darkened(rng.randf_range(0.0, 0.25)))
	# опоры крепи на переднем плане фона
	for px in range(10, w, 95):
		var ph := rng.randi_range(int(h * 0.55), int(h * 0.8))
		img.fill_rect(Rect2i(px, h - ph, 5, ph), Color(0.27, 0.18, 0.11))
		img.fill_rect(Rect2i(px + 1, h - ph, 1, ph), Color(0.36, 0.25, 0.15))
		img.fill_rect(Rect2i(px - 14, h - ph, 34, 4), Color(0.30, 0.20, 0.12))
		img.fill_rect(Rect2i(px - 14, h - ph, 34, 1), Color(0.40, 0.28, 0.17))
		# цепь с фонарём
		for cy in range(h - ph + 4, h - ph + 18, 2):
			_px(img, px + 12, cy, Color(0.35, 0.35, 0.38))
		img.fill_rect(Rect2i(px + 10, h - ph + 18, 5, 6), Color(0.25, 0.25, 0.28))
		PixelArt._halo(img, px + 12, h - ph + 21, 9, Color(1.0, 0.75, 0.35, 0.3))
		img.fill_rect(Rect2i(px + 11, h - ph + 19, 3, 4), Color(1.0, 0.85, 0.45))
	# рельсы у самого низа
	img.fill_rect(Rect2i(0, h - 5, w, 1), Color(0.42, 0.40, 0.45))
	for sx in range(0, w, 6):
		img.fill_rect(Rect2i(sx, h - 4, 4, 2), Color(0.25, 0.17, 0.10))
	# сталактиты сверху
	var x := 0
	while x < w:
		var len := rng.randi_range(6, 26)
		var bw := rng.randi_range(2, 6)
		for yy in len:
			var hw2 := int(bw * (1.0 - float(yy) / len))
			img.fill_rect(Rect2i(x - hw2, yy, hw2 * 2 + 1, 1), top.lightened(0.06))
		if rng.randf() < 0.3:
			gem(img, x, len - 2, 1, GEMS[rng.randi() % GEMS.size()])
		x += rng.randi_range(5, 14)
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.04, 0.12, rng)
	return img

# ---------- Фон Кристальных пещер ----------
static func crystal_backdrop(map_w: float, floor_y: float) -> Image:
	var w := int(map_w / PixelArt.SCALE)
	var h := int(floor_y / PixelArt.SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 43
	var top := Color(0.06, 0.07, 0.16)
	var bottom := Color(0.14, 0.18, 0.34)
	PixelArt._vgrad(img, 0, w, 0, h, top, bottom, 18)
	# свечение в глубине зала
	for i in 9:
		PixelArt._halo(img, rng.randi_range(0, w), rng.randi_range(h / 3, h), rng.randi_range(30, 60),
				Color(0.45, 0.6, 1.0, 0.10) if i % 2 == 0 else Color(0.7, 0.5, 1.0, 0.09))
	# дальние кристаллы — тусклые, ближние — яркие
	for layer in 3:
		var k := float(layer) / 2.0
		var n := 26 + layer * 6
		for i in n:
			var cx := rng.randi_range(-10, w + 10)
			var ch := rng.randi_range(18, 40 + layer * 22)
			var cw := rng.randi_range(4, 7 + layer * 3)
			var c: Color = (CRYSTAL if rng.randf() < 0.6 else CRYSTAL_V).darkened(0.55 - k * 0.35)
			spire(img, cx, h - 2, cw, ch, c, rng.randf_range(-0.25, 0.25))
			if layer > 0 and rng.randf() < 0.5:
				spire(img, cx + rng.randi_range(-30, 30), 0, cw - 1, ch / 2 + 8, c.darkened(0.1), rng.randf_range(-0.2, 0.2), true)
	# искры в воздухе
	for i in 160:
		var sx := rng.randi_range(0, w - 1)
		var sy := rng.randi_range(0, h - 1)
		_px(img, sx, sy, Color(0.8, 0.9, 1.0, rng.randf_range(0.3, 0.9)))
	# зеркальная вода у пола
	for y in range(h - 6, h):
		for xx in w:
			var p := img.get_pixel(xx, y)
			img.set_pixel(xx, y, p.lerp(Color(0.35, 0.5, 0.9), 0.25 + 0.05 * sin(xx * 0.4)))
	return img

# Кристальный шпиль (растёт вверх от base_y, или вниз — с потолка)
static func spire(img: Image, cx: int, base_y: int, cw: int, ch: int, c: Color, lean: float, down := false) -> void:
	for yy in ch:
		var t := float(yy) / maxf(ch, 1)
		var hw := int(round(cw * (1.0 - t * 0.85)))
		var y := base_y - yy if not down else base_y + yy
		var x0 := cx + int(lean * yy) - hw
		for x in range(x0, x0 + hw * 2 + 1):
			var left := x < cx + int(lean * yy)
			var col := c.lightened(0.18) if left else c.darkened(0.12)
			if x == x0 or x == x0 + hw * 2:
				col = c.lightened(0.35)
			_px(img, x, y, col)
	_px(img, cx + int(lean * (ch - 1)), base_y - ch + 1 if not down else base_y + ch - 1, Color(1, 1, 1, 0.9))

# ---------- Предметы ----------
static func cart_image() -> Image:
	var im := Image.create(26, 16, false, Image.FORMAT_RGBA8)
	var iron := Color(0.40, 0.40, 0.45)
	var wood := Color(0.42, 0.28, 0.16)
	BotRig._box(im, 1, 2, 24, 9, wood)
	for x in [1, 8, 16, 23]:
		im.fill_rect(Rect2i(x, 2, 2, 9), iron)
	im.fill_rect(Rect2i(0, 2, 26, 2), iron.lightened(0.15))
	im.fill_rect(Rect2i(2, 10, 22, 1), iron.darkened(0.3))
	# груда самоцветов сверху
	for i in 6:
		gem(im, 5 + i * 3, 2 - (i % 2), 1, GEMS[i % GEMS.size()])
	for wx in [6, 19]:
		PixelArt._circle(im, wx, 13, 3, Color(0.18, 0.18, 0.2))
		im.set_pixel(wx, 13, Color(0.55, 0.55, 0.6))
	return im

static func lamp_image() -> Image:
	var im := Image.create(8, 11, false, Image.FORMAT_RGBA8)
	BotRig._box(im, 1, 2, 6, 8, Color(0.28, 0.28, 0.32))
	im.fill_rect(Rect2i(2, 4, 4, 4), Color(1.0, 0.82, 0.4))
	im.fill_rect(Rect2i(3, 5, 2, 2), Color(1.0, 0.96, 0.75))
	im.fill_rect(Rect2i(3, 0, 2, 2), Color(0.35, 0.35, 0.38))
	return im

# Зеркальный кристалл: вытянутый, гладкая светлая грань посередине
static func mirror_image(w: int, h: int) -> Image:
	var im := Image.create(w, h, false, Image.FORMAT_RGBA8)
	for y in h:
		var t := float(y) / maxf(h - 1, 1)
		var hw := int(round(w * 0.5 * (0.55 + 0.45 * sin(PI * clampf(t * 1.15, 0.0, 1.0)))))
		for x in range(w / 2 - hw, w / 2 + hw):
			var u := float(x - (w / 2 - hw)) / maxf(hw * 2, 1)
			var c := CRYSTAL.lerp(Color(0.85, 0.95, 1.0), 0.5 + 0.5 * sin(u * PI))
			if absf(u - 0.5) < 0.12:
				c = Color(0.95, 0.98, 1.0)                          # зеркальная полоса
			if x == w / 2 - hw or x == w / 2 + hw - 1:
				c = CRYSTAL.darkened(0.35)
			c.a = 0.95
			im.set_pixel(x, y, c)
	return im

static func prism_image() -> Image:
	var im := Image.create(14, 13, false, Image.FORMAT_RGBA8)
	for y in 13:
		var hw := int(round(7.0 * y / 12.0))
		for x in range(7 - hw, 7 + hw):
			var c := Color(0.85, 0.92, 1.0, 0.9) if x < 7 else Color(0.65, 0.75, 1.0, 0.9)
			if x == 7 - hw or x == 7 + hw - 1 or y == 12:
				c = Color(1, 1, 1, 0.95)
			im.set_pixel(x, y, c)
	return im
