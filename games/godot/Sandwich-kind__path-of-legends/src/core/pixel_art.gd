class_name PixelArt
# Пиксельные картинки, нарисованные кодом: заставка меню, фоны карт.
# Рисуется маленькая картинка, а потом растягивается без сглаживания —
# получается настоящий пиксель-арт.

const SCALE := 4.0           # во сколько раз растягиваем фоны карт

static func make_sprite(img: Image, scale: float) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.scale = Vector2(scale, scale)
	return s

# ---------- Заставка главного меню: поле, река, лес, гора ----------
static func title_landscape() -> Image:
	var w := 320
	var h := 180
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	# небо полосами и солнце
	_vgrad(img, 0, w, 0, 125, Color(0.30, 0.50, 0.86), Color(0.98, 0.80, 0.62), 14)
	_halo(img, 250, 50, 40, Color(1.0, 0.9, 0.7, 0.5))
	_circle(img, 250, 50, 19, Color(1.0, 0.88, 0.66))
	_circle(img, 250, 50, 13, Color(1.0, 0.96, 0.78))
	_birds(img, 7, 30, 70, rng, Color(0.25, 0.25, 0.35))
	# далёкие горы с большой снежной вершиной
	var far := _ridge(w, 120.0, [[96, 92, 72], [160, 58, 48], [28, 46, 44], [232, 54, 58], [298, 40, 40]], rng, 2.0)
	_mountains(img, far, 125, Color(0.58, 0.56, 0.72), Color(0.43, 0.42, 0.60), 54.0, rng)
	# ближние холмы
	var hills := _ridge(w, 133.0, [[60, 24, 95], [205, 20, 110], [305, 16, 70]], rng, 1.0)
	_mountains(img, hills, 140, Color(0.36, 0.58, 0.42), Color(0.29, 0.49, 0.36), -1.0, rng)
	# лес
	var x := 0
	while x < w:
		var th := rng.randi_range(9, 17)
		var c := Color(0.13, 0.34, 0.22) if rng.randf() < 0.5 else Color(0.17, 0.41, 0.26)
		_pine(img, x, rng.randi_range(136, 141), th, c)
		x += rng.randi_range(3, 7)
	# поле
	_vgrad(img, 0, w, 140, h, Color(0.52, 0.76, 0.34), Color(0.34, 0.60, 0.24), 7)
	for i in 420:
		var px := rng.randi_range(0, w - 1)
		var py := rng.randi_range(142, h - 1)
		img.set_pixel(px, py, Color(0.30, 0.52, 0.22))
	_grain(img, Rect2i(0, 140, w, h - 140), 0.06, 0.25, rng)
	for i in 30:                                                   # кусты и камни в поле
		_bush(img, rng.randi_range(0, w - 1), rng.randi_range(150, h - 4), rng.randi_range(2, 4), Color(0.30, 0.55, 0.24))
	for i in 14:
		var sx := rng.randi_range(0, w - 3)
		var sy := rng.randi_range(150, h - 3)
		img.fill_rect(Rect2i(sx, sy, 3, 2), Color(0.55, 0.53, 0.5))
		img.set_pixel(sx, sy, Color(0.7, 0.68, 0.64))
	for i in 70:
		var flower: Color = [Color(1, 0.9, 0.3), Color(1, 1, 1), Color(0.95, 0.4, 0.4), Color(0.7, 0.6, 1.0)][rng.randi_range(0, 3)]
		img.set_pixel(rng.randi_range(0, w - 1), rng.randi_range(146, h - 1), flower)
	# река: от подножия горы через лес и поле к зрителю
	for y in range(121, h):
		var t := float(y - 121)
		var cx := int(100.0 + t * 0.9 + 14.0 * sin(t / 9.0))
		var hw := int(1.0 + t * 0.12)
		img.fill_rect(Rect2i(cx - hw - 1, y, hw * 2 + 3, 1), Color(0.24, 0.45, 0.30))
		img.fill_rect(Rect2i(cx - hw, y, hw * 2 + 1, 1), Color(0.30, 0.56, 0.90))
		if rng.randf() < 0.6:
			img.set_pixel(cx + rng.randi_range(-hw, hw), y, Color(0.72, 0.86, 1.0))
	return img

static func cloud() -> Image:
	var img := Image.create(44, 16, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in 5:
		var cx := 8 + i * 7 + rng.randi_range(-2, 2)
		var r := rng.randi_range(4, 7)
		_circle(img, cx, 10 - r / 3, r, Color(1, 1, 1, 0.95))
	img.fill_rect(Rect2i(4, 12, 36, 2), Color(0.88, 0.90, 0.97, 0.95))
	return img

# ---------- Фон TWO_HOUSES: небо, горы, холмы, лес ----------
# Картинка покрывает карту от y_top до низа, масштаб SCALE.
static func valley_backdrop(map_w: float, y_top: float, ground_y: float) -> Image:
	var w := int(map_w / SCALE)
	var h := int((ground_y - y_top) / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	_vgrad(img, 0, w, 0, h, Color(0.26, 0.44, 0.78), Color(0.78, 0.86, 0.95), 22)
	# облака прямо на фоне
	for i in 14:
		var c := cloud()
		img.blend_rect(c, Rect2i(0, 0, c.get_width(), c.get_height()),
				Vector2i(rng.randi_range(0, w - 44), rng.randi_range(int(h * 0.2), int(h * 0.65))))
	var peaks := []
	for i in 9:
		peaks.append([rng.randi_range(0, w), rng.randi_range(55, 110), rng.randi_range(60, 120)])
	var far := _ridge(w, h - 30.0, peaks, rng, 2.0)
	_mountains(img, far, h, Color(0.58, 0.60, 0.74), Color(0.45, 0.47, 0.63), h - 95.0, rng)
	var hp := []
	for i in 8:
		hp.append([rng.randi_range(0, w), rng.randi_range(14, 30), rng.randi_range(80, 160)])
	var hills := _ridge(w, h - 12.0, hp, rng, 1.0)
	_mountains(img, hills, h, Color(0.38, 0.60, 0.44), Color(0.31, 0.51, 0.38), -1.0, rng)
	_grain(img, Rect2i(0, int(h * 0.55), w, h), 0.05, 0.12, rng)
	# дальний лес — мельче и бледнее, ближний — крупнее
	var xf := 0
	while xf < w:
		_pine(img, xf, h - rng.randi_range(8, 14), rng.randi_range(5, 9), Color(0.27, 0.46, 0.36))
		xf += rng.randi_range(2, 5)
	var x := 0
	while x < w:
		_pine(img, x, h - rng.randi_range(1, 6), rng.randi_range(8, 15),
				Color(0.15, 0.37, 0.24) if rng.randf() < 0.5 else Color(0.19, 0.43, 0.28))
		if rng.randf() < 0.25:
			_bush(img, x + rng.randi_range(-3, 3), h - 2, rng.randi_range(2, 4), Color(0.24, 0.48, 0.28))
		x += rng.randi_range(3, 9)
	_birds(img, 10, int(h * 0.15), int(h * 0.45), rng, Color(0.2, 0.22, 0.3))
	return img

# ---------- Фон колизея: небо, трибуны со зрителями, арки ----------
static func colosseum_backdrop(map_w: float, floor_y: float, night: bool) -> Image:
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var sky_h := int(h * 0.30)
	if night:
		_vgrad(img, 0, w, 0, sky_h + 10, Color(0.04, 0.05, 0.14), Color(0.13, 0.13, 0.28), 10)
		for i in 160:
			img.set_pixel(rng.randi_range(0, w - 1), rng.randi_range(0, sky_h),
					Color(1, 1, 0.9, rng.randf_range(0.4, 1.0)))
	else:
		_vgrad(img, 0, w, 0, sky_h + 10, Color(0.36, 0.60, 0.92), Color(0.80, 0.90, 1.0), 10)
		for i in 6:
			var c := cloud()
			img.blend_rect(c, Rect2i(0, 0, 44, 16), Vector2i(rng.randi_range(0, w - 44), rng.randi_range(4, sky_h - 18)))
	var stone := Color(0.74, 0.64, 0.50)
	var stone_dark := Color(0.60, 0.51, 0.40)
	var hole := Color(0.22, 0.17, 0.15)
	var y1 := sky_h                    # верхний ярус: трибуны со зрителями
	var y2 := y1 + int(h * 0.17)       # средний ярус: арки
	var y3 := y2 + int(h * 0.25)       # нижний ярус: большие арки
	# трибуны
	img.fill_rect(Rect2i(0, y1, w, y2 - y1), Color(0.42, 0.33, 0.27))
	for row in range(y1 + 2, y2 - 1, 3):
		img.fill_rect(Rect2i(0, row + 2, w, 1), Color(0.34, 0.26, 0.21))
		for xx in range(rng.randi_range(0, 2), w, 2):
			if rng.randf() < (0.35 if night else 0.75):
				var hc := Color.from_hsv(rng.randf(), rng.randf_range(0.3, 0.8), rng.randf_range(0.6, 1.0))
				img.set_pixel(xx, row, Color(0.95, 0.78, 0.62) if rng.randf() < 0.5 else hc)
				img.set_pixel(xx, row + 1, hc.darkened(0.2))
	# флажки по верхнему краю
	for xx in range(6, w, 40):
		img.fill_rect(Rect2i(xx, y1 - 9, 1, 10), Color(0.35, 0.25, 0.2))
		var fc := Color(0.85, 0.2, 0.2) if (xx / 40) % 2 == 0 else Color(0.95, 0.75, 0.2)
		for k in 5:
			img.fill_rect(Rect2i(xx + 1, y1 - 9 + k, 6 - k, 1), fc)
	img.fill_rect(Rect2i(0, y1 - 1, w, 2), stone)
	# средний ярус
	img.fill_rect(Rect2i(0, y2, w, y3 - y2), stone)
	img.fill_rect(Rect2i(0, y2, w, 2), stone.lightened(0.15))
	_masonry(img, Rect2i(0, y2 + 2, w, y3 - y2 - 2), 8, 4, stone, rng)
	for xx in range(4, w - 8, 16):
		_arch(img, xx, y2 + 5, 9, y3 - y2 - 8, hole)
		_arch_trim(img, xx, y2 + 5, 9, stone)
		if (xx / 16) % 4 == 1:                                  # знамёна между арками
			img.fill_rect(Rect2i(xx + 11, y2 + 4, 3, 9), Color(0.7, 0.12, 0.12))
			img.fill_rect(Rect2i(xx + 11, y2 + 4, 3, 1), Color(0.95, 0.75, 0.25))
			img.set_pixel(xx + 12, y2 + 8, Color(0.95, 0.75, 0.25))
			img.set_pixel(xx + 11, y2 + 13, Color(0.7, 0.12, 0.12))
			img.set_pixel(xx + 13, y2 + 13, Color(0.7, 0.12, 0.12))
	# нижний ярус
	img.fill_rect(Rect2i(0, y3, w, h - y3), stone_dark)
	img.fill_rect(Rect2i(0, y3, w, 2), stone.lightened(0.1))
	_masonry(img, Rect2i(0, y3 + 2, w, h - y3 - 2), 10, 5, stone_dark, rng)
	for xx in range(10, w - 20, 34):
		_arch(img, xx, y3 + 7, 18, h - y3 - 7, hole.darkened(0.2))
		_arch_trim(img, xx, y3 + 7, 18, stone_dark)
		# полуколонна между арками: светлый ствол, тень справа, капитель
		var px := xx + 24
		img.fill_rect(Rect2i(px, y3 + 4, 4, h - y3 - 4), stone_dark.lightened(0.14))
		img.fill_rect(Rect2i(px + 3, y3 + 4, 1, h - y3 - 4), stone_dark.darkened(0.15))
		img.fill_rect(Rect2i(px - 1, y3 + 3, 6, 2), stone.lightened(0.08))
	# трещинки и камни
	for i in 400:
		img.set_pixel(rng.randi_range(0, w - 1), rng.randi_range(y2 + 2, h - 1), stone_dark.darkened(0.15))
	# полотняный навес над трибунами (веларий) — полосатые клинья
	for xx in range(0, w, 12):
		var vc := Color(0.85, 0.25, 0.2) if (xx / 12) % 2 == 0 else Color(0.92, 0.86, 0.72)
		if night:
			vc = vc.darkened(0.55)
		for k in 4:
			img.fill_rect(Rect2i(xx + k, y1 - 14 + k, 12 - k * 2, 1), vc)
	_grain(img, Rect2i(0, y2, w, h - y2), 0.04, 0.1, rng)
	return img

# Обрамление арки: светлая кромка слева, замковый камень сверху
static func _arch_trim(img: Image, x: int, y: int, aw: int, c: Color) -> void:
	var r := aw / 2
	img.fill_rect(Rect2i(x + r - 1, y - 2, 3, 2), c.lightened(0.2))
	for i in r:
		var hw := int(sqrt(float(r * r - (r - i) * (r - i))))
		if x + r - hw - 1 >= 0:
			img.set_pixel(x + r - hw - 1, y + i, c.lightened(0.12))

# ---------- Фон джунглей: кроны, стволы, лианы, древний храм гоблинов ----------
static func jungle_backdrop(map_w: float, floor_y: float, night: bool) -> Image:
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var k := 0.38 if night else 1.0       # ночью всё темнее и синее
	var tint := func(c: Color) -> Color:
		return Color(c.r * k * (0.8 if night else 1.0), c.g * k, c.b * k * (1.6 if night else 1.0))
	if night:
		_vgrad(img, 0, w, 0, h, Color(0.03, 0.05, 0.12), Color(0.08, 0.14, 0.2), 12)
		for i in 90:
			img.set_pixel(rng.randi_range(0, w - 1), rng.randi_range(0, int(h * 0.3)), Color(1, 1, 0.9, rng.randf_range(0.3, 0.9)))
	else:
		_vgrad(img, 0, w, 0, h, Color(0.55, 0.80, 0.70), Color(0.85, 0.92, 0.65), 12)
	# дальние кроны — три слоя, чем ближе, тем темнее
	var layers := [[Color(0.45, 0.65, 0.45), 0.22, 26], [Color(0.30, 0.52, 0.32), 0.34, 22], [Color(0.20, 0.40, 0.24), 0.46, 18]]
	for L in layers:
		var c: Color = tint.call(L[0])
		var base := int(h * float(L[1]))
		var x := -10
		while x < w + 10:
			var r: int = rng.randi_range(L[2] - 6, L[2] + 6)
			var cy := base + rng.randi_range(-6, 6)
			_circle(img, x, cy, r, c)
			_circle(img, x - r / 3, cy - r / 3, r / 2, c.lightened(0.07))     # освещённая сторона кроны
			x += rng.randi_range(12, 22)
		img.fill_rect(Rect2i(0, base, w, h - base), c)
	# древний храм в центре
	var tc: Color = tint.call(Color(0.48, 0.50, 0.42))
	var cx := w / 2
	for step in 5:
		var sw := 120 - step * 20
		var sy := int(h * 0.62) - step * 14
		img.fill_rect(Rect2i(cx - sw / 2, sy, sw, 14), tc.darkened(step * 0.04))
		img.fill_rect(Rect2i(cx - sw / 2, sy, sw, 1), tc.lightened(0.15))
	_masonry(img, Rect2i(cx - 60, int(h * 0.62) - 56, 120, h), 8, 4, tc, rng)
	for i in 50:                                                    # мох на ступенях
		var mx := rng.randi_range(cx - 60, cx + 60)
		var my := rng.randi_range(int(h * 0.62) - 56, int(h * 0.62) + 14)
		img.fill_rect(Rect2i(mx, my, rng.randi_range(2, 5), 1), tint.call(Color(0.32, 0.5, 0.26)))
	var dark: Color = tint.call(Color(0.12, 0.1, 0.08))
	img.fill_rect(Rect2i(cx - 8, int(h * 0.62) - 66, 16, 22), dark)
	_circle(img, cx - 14, int(h * 0.62) - 50, 3, tint.call(Color(0.9, 0.5, 0.2)))
	_circle(img, cx + 14, int(h * 0.62) - 50, 3, tint.call(Color(0.9, 0.5, 0.2)))
	img.fill_rect(Rect2i(cx - 60, int(h * 0.62) + 14, 120, h), tc.darkened(0.1))
	# стволы среднего плана
	var trunk: Color = tint.call(Color(0.30, 0.22, 0.14))
	var x2 := 8
	while x2 < w:
		if absi(x2 - cx) > 75:
			var tw := rng.randi_range(5, 10)
			img.fill_rect(Rect2i(x2, int(h * 0.3), tw, h), trunk.darkened(rng.randf_range(0.0, 0.25)))
			img.fill_rect(Rect2i(x2, int(h * 0.3), 1, h), trunk.lightened(0.15))
			_circle(img, x2 + tw / 2, int(h * 0.3), rng.randi_range(16, 24), tint.call(Color(0.18, 0.38, 0.2)))
		x2 += rng.randi_range(40, 70)
	# лианы сверху
	for i in 40:
		var vx := rng.randi_range(0, w - 1)
		var vl := rng.randi_range(15, int(h * 0.55))
		for vy in vl:
			img.set_pixel(clampi(vx + int(sin(vy * 0.15) * 1.5), 0, w - 1), vy, tint.call(Color(0.22, 0.48, 0.2)))
			if vy % 6 == 3:                                               # листики на лиане
				img.set_pixel(clampi(vx + int(sin(vy * 0.15) * 1.5) + (1 if vy % 12 == 3 else -1), 0, w - 1), vy, tint.call(Color(0.35, 0.62, 0.28)))
		_circle(img, vx, vl, 2, tint.call(Color(0.3, 0.6, 0.25)))
	# густые кроны сверху
	var top: Color = tint.call(Color(0.14, 0.32, 0.16))
	var x3 := -8
	while x3 < w + 8:
		_circle(img, x3, rng.randi_range(-6, 6), rng.randi_range(14, 24), top)
		x3 += rng.randi_range(10, 18)
	# лучи света сквозь листву (днём) и светлячки (ночью)
	if not night:
		for i in 7:
			var lx := rng.randi_range(0, w)
			for yy in range(int(h * 0.1), h):
				var xx := lx + (yy - int(h * 0.1)) / 3
				for kk in 5:
					var px := xx + kk
					if px >= 0 and px < w:
						img.set_pixel(px, yy, img.get_pixel(px, yy).lerp(Color(1.0, 0.98, 0.8), 0.07))
	else:
		for i in 70:
			var fx2 := rng.randi_range(0, w - 1)
			var fy2 := rng.randi_range(int(h * 0.3), h - 4)
			img.set_pixel(fx2, fy2, Color(1.0, 0.95, 0.5))
			if fx2 + 1 < w:
				img.set_pixel(fx2 + 1, fy2, Color(0.8, 0.9, 0.3, 0.6))
	_grain(img, Rect2i(0, 0, w, h), 0.035, 0.08, rng)
	# папоротники у земли
	var fern: Color = tint.call(Color(0.20, 0.45, 0.22))
	for i in 160:
		var fx := rng.randi_range(0, w - 1)
		var fh := rng.randi_range(4, 12)
		for j in fh:
			img.set_pixel(clampi(fx + (j * (1 if i % 2 == 0 else -1)) / 2, 0, w - 1), h - 1 - j, fern)
	return img

# ---------- Фон пещер: своды, сталактиты, грибы / царство скелетов ----------
static func cave_backdrop(map_w: float, floor_y: float, deep: bool) -> Image:
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 33 if deep else 31
	var top := Color(0.10, 0.09, 0.12) if deep else Color(0.16, 0.14, 0.15)
	var bottom := Color(0.20, 0.17, 0.24) if deep else Color(0.30, 0.25, 0.22)
	_vgrad(img, 0, w, 0, h, top, bottom, 14)
	# дальняя стена: пятна камня
	for i in 140:
		var yy := rng.randi_range(0, h)
		var base := top.lerp(bottom, float(yy) / h)
		var c := base.darkened(rng.randf_range(0.03, 0.12)) if i % 2 == 0 else base.lightened(rng.randf_range(0.02, 0.06))
		_circle(img, rng.randi_range(0, w), yy, rng.randi_range(3, 8), c)
	# слои породы и трещины
	for i in 26:
		var sy := rng.randi_range(0, h)
		var sx := rng.randi_range(-20, w)
		var sl := rng.randi_range(20, 80)
		for k in sl:
			var yy := sy + int(sin(k * 0.12) * 2.0)
			if sx + k >= 0 and sx + k < w and yy >= 0 and yy < h:
				img.set_pixel(sx + k, yy, img.get_pixel(sx + k, yy).darkened(0.12))
				if yy + 1 < h:
					img.set_pixel(sx + k, yy + 1, img.get_pixel(sx + k, yy + 1).lightened(0.05))
	_grain(img, Rect2i(0, 0, w, h), 0.04, 0.15, rng)
	# сталактиты сверху и сталагмиты снизу (силуэты)
	var sil := top.lightened(0.05)
	var x := 0
	while x < w:
		var len := rng.randi_range(8, 40 if deep else 28)
		var bw := rng.randi_range(3, 8)
		for yy in len:
			var hw := int(bw * (1.0 - float(yy) / len))
			img.fill_rect(Rect2i(x - hw, yy, hw * 2 + 1, 1), sil)
		x += rng.randi_range(6, 16)
	x = 0
	while x < w:
		var len2 := rng.randi_range(6, 26)
		var bw2 := rng.randi_range(3, 7)
		for yy in len2:
			var hw2 := int(bw2 * float(yy) / len2)
			img.fill_rect(Rect2i(x - hw2, h - len2 + yy, hw2 * 2 + 1, 1), bottom.darkened(0.25))
		x += rng.randi_range(10, 30)
	if deep:
		# царство скелетов: колонны разрушенного зала, знамёна, груды костей
		for cx in range(30, w, 70):
			var ch := rng.randi_range(int(h * 0.45), int(h * 0.8))
			img.fill_rect(Rect2i(cx, h - ch, 12, ch), Color(0.22, 0.20, 0.26))
			img.fill_rect(Rect2i(cx - 2, h - ch, 16, 4), Color(0.26, 0.24, 0.30))
			img.fill_rect(Rect2i(cx + 1, h - ch + 4, 1, ch - 4), Color(0.28, 0.26, 0.32))
			for fl in [4, 7, 10]:                                     # каннелюры колонны
				img.fill_rect(Rect2i(cx + fl, h - ch + 4, 1, ch - 4), Color(0.19, 0.17, 0.23))
			img.fill_rect(Rect2i(cx - 2, h - 4, 16, 4), Color(0.25, 0.23, 0.29))
			if rng.randf() < 0.6:
				img.fill_rect(Rect2i(cx + 2, h - ch + 8, 8, 22), Color(0.35, 0.08, 0.1))
				img.fill_rect(Rect2i(cx + 5, h - ch + 14, 2, 6), Color(0.8, 0.65, 0.2))
		for i in 30:
			var bx := rng.randi_range(0, w)
			for k in 6:
				img.fill_rect(Rect2i(bx + rng.randi_range(-6, 6), h - rng.randi_range(1, 6), 3, 1), Color(0.55, 0.53, 0.48))
			if i % 3 == 0:                                                # черепа в грудах костей
				var sx2 := bx + rng.randi_range(-4, 4)
				img.fill_rect(Rect2i(sx2, h - 9, 4, 3), Color(0.72, 0.7, 0.62))
				img.set_pixel(clampi(sx2 + 1, 0, w - 1), h - 8, Color(0.1, 0.08, 0.1))
				img.set_pixel(clampi(sx2 + 3, 0, w - 1), h - 8, Color(0.1, 0.08, 0.1))
				img.fill_rect(Rect2i(sx2 + 1, h - 6, 2, 1), Color(0.62, 0.6, 0.54))
		for cx2 in range(15, w, 55):                                       # цепи со свода
			for yy in range(0, rng.randi_range(20, 50), 3):
				img.fill_rect(Rect2i(cx2, yy, 2, 2), Color(0.3, 0.29, 0.3))
	else:
		# крепь шахтёров: столбы и перекладины с фонарём
		for bx in range(60, w, 140):
			var bh := int(h * 0.55)
			var beam := Color(0.30, 0.21, 0.13)
			img.fill_rect(Rect2i(bx, h - bh, 3, bh), beam)
			img.fill_rect(Rect2i(bx + 24, h - bh, 3, bh), beam)
			img.fill_rect(Rect2i(bx - 2, h - bh, 31, 3), beam.lightened(0.08))
			img.fill_rect(Rect2i(bx, h - bh, 1, bh), beam.lightened(0.12))
			img.fill_rect(Rect2i(bx + 10, h - bh + 3, 1, 6), Color(0.4, 0.38, 0.36))
			img.fill_rect(Rect2i(bx + 9, h - bh + 9, 3, 3), Color(1.0, 0.75, 0.3))
			_halo(img, bx + 10, h - bh + 10, 12, Color(1.0, 0.7, 0.3, 0.35))
		# кристаллы с ореолом
		for i in 16:
			var kx := rng.randi_range(4, w - 4)
			var ky := rng.randi_range(int(h * 0.2), h - 6)
			var kc := Color(0.45, 0.9, 1.0) if rng.randf() < 0.5 else Color(0.75, 0.5, 1.0)
			_halo(img, kx, ky, 8, Color(kc.r, kc.g, kc.b, 0.3))
			for k in 3:
				var kh := rng.randi_range(3, 6)
				img.fill_rect(Rect2i(kx - 2 + k * 2, ky - kh, 2, kh), kc.darkened(0.1 * k))
				img.set_pixel(kx - 2 + k * 2, ky - kh, kc.lightened(0.4))
		# светящиеся грибы и кристаллы
		for i in 60:
			var gx := rng.randi_range(0, w)
			var gy := h - rng.randi_range(1, 30)
			var gc := Color(0.4, 0.9, 0.8) if rng.randf() < 0.5 else Color(0.7, 0.5, 1.0)
			img.fill_rect(Rect2i(gx, gy, 1, 3), Color(0.6, 0.6, 0.55))
			img.fill_rect(Rect2i(gx - 1, gy - 1, 3, 1), gc)
	return img

# Каменный трон Короля скелетов
static func throne() -> Image:
	var img := Image.create(40, 52, false, Image.FORMAT_RGBA8)
	var st := Color(0.30, 0.28, 0.34)
	img.fill_rect(Rect2i(4, 0, 32, 34), st)                 # спинка
	img.fill_rect(Rect2i(6, 2, 28, 30), st.lightened(0.08))
	for x in [8, 18, 28]:                                     # черепа на спинке
		img.fill_rect(Rect2i(x, 4, 5, 4), Color(0.85, 0.83, 0.75))
		img.set_pixel(x + 1, 5, Color(0.1, 0.1, 0.1))
		img.set_pixel(x + 3, 5, Color(0.1, 0.1, 0.1))
	img.fill_rect(Rect2i(0, 30, 40, 8), st.darkened(0.1))    # сиденье
	img.fill_rect(Rect2i(0, 24, 6, 14), st.darkened(0.2))    # подлокотники
	img.fill_rect(Rect2i(34, 24, 6, 14), st.darkened(0.2))
	img.fill_rect(Rect2i(2, 38, 36, 14), st.darkened(0.25))  # постамент
	img.fill_rect(Rect2i(0, 48, 40, 4), st.darkened(0.35))
	img.fill_rect(Rect2i(14, 0, 12, 3), Color(0.6, 0.12, 0.12))
	return img

# ---------- Подвал Колизея: каменная кладка, арки, цепи, факелы, люк наверху ----------
static func basement() -> Image:
	var w := 320
	var h := 180
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	img.fill_rect(Rect2i(0, 0, w, h), Color(0.16, 0.13, 0.12))
	# кладка
	for row in range(0, 150, 8):
		var off := 0 if (row / 8) % 2 == 0 else 8
		for bx in range(-off, w, 16):
			var c := Color(0.30, 0.25, 0.22).lightened(rng.randf_range(-0.08, 0.06))
			img.fill_rect(Rect2i(bx + 1, row + 1, 14, 6), c)
	# арки с темнотой
	for ax in [20, 260]:
		_arch(img, ax, 60, 40, 90, Color(0.05, 0.04, 0.04))
	# потолочные балки и светлый проём люка над подъёмниками
	img.fill_rect(Rect2i(0, 0, w, 10), Color(0.22, 0.15, 0.10))
	img.fill_rect(Rect2i(80, 0, 160, 6), Color(0.95, 0.85, 0.55))
	for i in 12:
		img.fill_rect(Rect2i(80 + i * 13, 0, 2, 6), Color(0.35, 0.25, 0.15))
	for y in range(6, 60):            # лучи света сверху
		var a := 0.25 * (1.0 - float(y) / 60.0)
		for xx in range(90 - y / 4, 90 - y / 4 + 140 + y / 2):
			img.set_pixel(xx, y, img.get_pixel(xx, y).lerp(Color(1.0, 0.9, 0.6), a))
	# цепи
	for cx in [70, 250]:
		for y in range(10, 70, 3):
			img.fill_rect(Rect2i(cx, y, 2, 2), Color(0.45, 0.43, 0.42))
	# пол из досок
	for y in range(150, h, 5):
		img.fill_rect(Rect2i(0, y, w, 5), Color(0.25, 0.17, 0.11).lightened(0.04 * ((y / 5) % 2)))
	# ящики, бочки, стойка с оружием
	for bx in [8, 290]:
		img.fill_rect(Rect2i(bx, 128, 22, 22), Color(0.45, 0.30, 0.16))
		img.fill_rect(Rect2i(bx + 2, 130, 18, 18), Color(0.38, 0.25, 0.13))
		img.fill_rect(Rect2i(bx, 138, 22, 2), Color(0.3, 0.2, 0.1))
	img.fill_rect(Rect2i(48, 112, 26, 3), Color(0.35, 0.22, 0.12))
	for k in 4:
		img.fill_rect(Rect2i(51 + k * 6, 92, 1, 36), Color(0.6, 0.6, 0.62))
		img.fill_rect(Rect2i(50 + k * 6, 90, 3, 3), Color(0.7, 0.7, 0.72))
	# факелы
	for tx in [110, 210]:
		img.fill_rect(Rect2i(tx, 70, 3, 10), Color(0.3, 0.2, 0.12))
		img.fill_rect(Rect2i(tx - 1, 64, 5, 6), Color(1.0, 0.6, 0.2))
		img.fill_rect(Rect2i(tx, 62, 3, 3), Color(1.0, 0.9, 0.5))
		for yy in range(-16, 17):
			for xx in range(-16, 17):
				var dd := sqrt(float(xx * xx + yy * yy))
				if dd < 16.0 and not (absi(xx) < 3 and yy > -5 and yy < 15):
					var px2: int = tx + 1 + xx
					var py2 := 66 + yy
					img.set_pixel(px2, py2, img.get_pixel(px2, py2).lerp(Color(1.0, 0.65, 0.3), 0.18 * (1.0 - dd / 16.0)))
	return img

# ---------- Помощники ----------
static func _vgrad(img: Image, x0: int, x1: int, y0: int, y1: int, top: Color, bottom: Color,
		steps: int = 0) -> void:
	for y in range(y0, y1):
		var t := float(y - y0) / maxf(1.0, float(y1 - y0 - 1))
		if steps > 0:
			t = floorf(t * steps) / steps     # полосами, по-пиксельному
		img.fill_rect(Rect2i(x0, y, x1 - x0, 1), top.lerp(bottom, t))

static func _circle(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(-r, r + 1):
		var hw := int(sqrt(maxf(0.0, float(r * r - y * y))))
		img.fill_rect(Rect2i(cx - hw, cy + y, hw * 2 + 1, 1), c)

# Высота хребта по столбцам: треугольные вершины + неровности
static func _ridge(w: int, base: float, peaks: Array, rng: RandomNumberGenerator, rough: float) -> PackedFloat32Array:
	var res := PackedFloat32Array()
	res.resize(w)
	var jag := 0.0
	for x in w:
		var top := base
		for p in peaks:
			var k := 1.0 - absf(float(x - p[0])) / float(p[2])
			if k > 0.0:
				top = minf(top, base - float(p[1]) * k)
		jag = clampf(jag + rng.randf_range(-rough, rough), -rough * 2.0, rough * 2.0)
		res[x] = top + jag
	return res

# Горы: освещённый и теневой склон, снег выше snow_line
static func _mountains(img: Image, heights: PackedFloat32Array, base: int, lit: Color, shade: Color,
		snow_line: float, rng: RandomNumberGenerator) -> void:
	var w := img.get_width()
	for x in w:
		var top := int(heights[x])
		var slope := heights[mini(x + 1, w - 1)] - heights[maxi(x - 1, 0)]
		var c := lit if slope >= 0.0 else shade
		if base > top:
			img.fill_rect(Rect2i(x, top, 1, base - top), c)
		if base > top:
			# фактура склона: светлая кромка гребня, пятна и расщелины
			img.set_pixel(x, clampi(top, 0, img.get_height() - 1), c.lightened(0.18))
			for yy in range(top + 2, base, 3):
				if rng.randf() < 0.18:
					img.set_pixel(x, clampi(yy, 0, img.get_height() - 1), c.darkened(0.08) if rng.randf() < 0.6 else c.lightened(0.05))
			if rng.randf() < 0.09:
				var cl := rng.randi_range(4, 14)
				for k in cl:
					var yy2 := top + 3 + k
					if yy2 < base:
						img.set_pixel(clampi(x + (k / 4) * (1 if slope >= 0.0 else -1), 0, w - 1), clampi(yy2, 0, img.get_height() - 1), c.darkened(0.14))
		if snow_line > 0.0 and top < snow_line:
			var snow_end := int(snow_line) + rng.randi_range(-2, 2)
			var sc := Color(0.97, 0.97, 1.0) if slope >= 0.0 else Color(0.82, 0.85, 0.95)
			img.fill_rect(Rect2i(x, top, 1, maxi(1, snow_end - top)), sc)
			if rng.randf() < 0.3:
				img.set_pixel(x, clampi(snow_end, 0, img.get_height() - 1), sc.darkened(0.1))   # рваный край снега

# Ёлка: треугольник ярусами и стволик
static func _pine(img: Image, x: int, base_y: int, h: int, c: Color) -> void:
	for i in h:
		var y := base_y - h + i
		var hw := int(i * 0.38) - (1 if i % 4 == 3 else 0)
		img.fill_rect(Rect2i(x - hw, y, hw * 2 + 1, 1), c if i % 4 != 0 else c.lightened(0.12))
		if hw > 0:
			img.fill_rect(Rect2i(x - hw, y, 1, 1), c.lightened(0.18))       # освещённый край
			img.fill_rect(Rect2i(x + 1, y, hw, 1), c.darkened(0.15))         # теневая сторона
	img.fill_rect(Rect2i(x, base_y, 1, 2), Color(0.35, 0.24, 0.16))

# Арка: прямоугольник со скруглённым верхом
static func _arch(img: Image, x: int, y: int, aw: int, ah: int, c: Color) -> void:
	var r := aw / 2
	for i in r:
		var hw := int(sqrt(float(r * r - (r - i) * (r - i))))
		img.fill_rect(Rect2i(x + r - hw, y + i, hw * 2, 1), c)
	img.fill_rect(Rect2i(x, y + r, aw, maxi(0, ah - r)), c)

# ---------- Таверна для магазина: доски, полки, стойка, бочки, фонари ----------
static func tavern() -> Image:
	var w := 320
	var h := 180
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	# стена из досок
	for x in range(0, w, 16):
		var c := Color(0.36, 0.22, 0.13).lightened(rng.randf_range(-0.05, 0.08))
		img.fill_rect(Rect2i(x, 0, 16, 130), c)
		img.fill_rect(Rect2i(x, 0, 1, 130), Color(0.24, 0.14, 0.08))
		for i in 3:
			img.set_pixel(x + rng.randi_range(3, 12), rng.randi_range(4, 125), Color(0.28, 0.17, 0.1))
	# балка и фонари
	img.fill_rect(Rect2i(0, 8, w, 7), Color(0.22, 0.13, 0.07))
	for lx in [114, 206]:
		img.fill_rect(Rect2i(lx, 15, 1, 10), Color(0.15, 0.12, 0.1))
		img.fill_rect(Rect2i(lx - 4, 25, 9, 11), Color(0.2, 0.17, 0.12))
		img.fill_rect(Rect2i(lx - 3, 26, 7, 9), Color(1.0, 0.78, 0.35))
		for r in range(14, 4, -3):          # мягкий свет фонаря
			for yy in range(-r, r + 1):
				var hw := int(sqrt(maxf(0.0, float(r * r - yy * yy))))
				for xx in range(lx - hw, lx + hw + 1):
					if xx >= 0 and xx < w and 30 + yy >= 0:
						img.set_pixel(xx, 30 + yy, img.get_pixel(xx, 30 + yy).lerp(Color(1.0, 0.8, 0.4), 0.05))
	# полки по бокам от торговца
	for x0 in SHELF_X:
		for row in 3:
			var y: int = SHELF_Y[row]
			img.fill_rect(Rect2i(x0, y, SHELF_W, 4), Color(0.5, 0.32, 0.18))
			img.fill_rect(Rect2i(x0, y + 4, SHELF_W, 1), Color(0.2, 0.12, 0.07))
			for bx in [x0 + 2, x0 + SHELF_W - 4]:
				img.fill_rect(Rect2i(bx, y + 4, 2, 6), Color(0.3, 0.18, 0.1))
			for i in 4:
				img.set_pixel(rng.randi_range(x0 + 2, x0 + SHELF_W - 2), y - 1, Color(0.55, 0.45, 0.35))
	# дверь в кладовую за торговцем
	img.fill_rect(Rect2i(140, 52, 40, 78), Color(0.22, 0.13, 0.07))
	img.fill_rect(Rect2i(143, 55, 34, 75), Color(0.30, 0.19, 0.10))
	img.fill_rect(Rect2i(170, 92, 3, 3), Color(0.8, 0.65, 0.3))
	# вывеска
	img.fill_rect(Rect2i(125, 18, 70, 16), Color(0.55, 0.36, 0.18))
	img.fill_rect(Rect2i(127, 20, 66, 12), Color(0.68, 0.48, 0.26))
	# пол
	for y in range(130, h, 6):
		img.fill_rect(Rect2i(0, y, w, 6), Color(0.3, 0.19, 0.11).lightened(0.04 * ((y / 6) % 2)))
	# бочки
	for bx in [6, 296]:
		img.fill_rect(Rect2i(bx, 136, 18, 30), Color(0.45, 0.28, 0.14))
		for k in 3:
			img.fill_rect(Rect2i(bx, 140 + k * 10, 18, 2), Color(0.3, 0.3, 0.32))
	return img

# Полки лавки (в пикселях картинки таверны)
const SHELF_X := [14, 214]
const SHELF_W := 92
const SHELF_Y := [44, 72, 100]

# Стойка торговца — отдельной картинкой, чтобы торговец стоял за ней
static func tavern_counter() -> Image:
	var w := 320
	var h := 180
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(30, 118, 260, 8), Color(0.55, 0.34, 0.18))
	img.fill_rect(Rect2i(30, 118, 260, 2), Color(0.66, 0.44, 0.25))
	img.fill_rect(Rect2i(30, 126, 260, 34), Color(0.42, 0.25, 0.13))
	for x in range(30, 290, 4):
		img.set_pixel(x, 121 + (x / 4) % 3, Color(0.48, 0.29, 0.15))
	img.fill_rect(Rect2i(30, 158, 260, 2), Color(0.25, 0.14, 0.07))
	# кружка и весы на стойке
	img.fill_rect(Rect2i(250, 110, 8, 8), Color(0.75, 0.75, 0.7))
	img.fill_rect(Rect2i(250, 108, 8, 3), Color(1, 1, 0.92))
	img.fill_rect(Rect2i(258, 112, 2, 4), Color(0.75, 0.75, 0.7))
	img.fill_rect(Rect2i(62, 104, 1, 14), Color(0.6, 0.5, 0.3))
	img.fill_rect(Rect2i(54, 104, 17, 1), Color(0.6, 0.5, 0.3))
	img.fill_rect(Rect2i(52, 112, 6, 2), Color(0.8, 0.65, 0.3))
	img.fill_rect(Rect2i(67, 110, 6, 2), Color(0.8, 0.65, 0.3))
	return img

# ---------- Детали фонов ----------
# Лёгкая фактура: случайные светлые/тёмные пиксели на области
static func _grain(img: Image, r: Rect2i, amount: float, chance: float, rng: RandomNumberGenerator) -> void:
	r = r.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			if rng.randf() < chance:
				var c := img.get_pixel(x, y)
				if c.a > 0.0:
					img.set_pixel(x, y, c.lightened(amount) if rng.randf() < 0.5 else c.darkened(amount))

# Стая птиц галочками
static func _birds(img: Image, n: int, y0: int, y1: int, rng: RandomNumberGenerator, c: Color) -> void:
	for i in n:
		var bx := rng.randi_range(4, img.get_width() - 6)
		var by := rng.randi_range(y0, y1)
		img.set_pixel(bx, by, c)
		img.set_pixel(bx + 1, by + 1, c)
		img.set_pixel(bx + 2, by, c)

# Ореол вокруг солнца/луны
static func _halo(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(cy - r, cy + r + 1):
		for x in range(cx - r, cx + r + 1):
			if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height():
				continue
			var d := Vector2(x - cx, y - cy).length()
			if d < r:
				var k := (1.0 - d / r) * c.a
				k = floorf(k * 5.0) / 5.0                   # ступеньками, по-пиксельному
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(c.r, c.g, c.b), k))

# Куст / крона: шар с бликом сверху-слева и тенью снизу
static func _bush(img: Image, cx: int, cy: int, r: int, c: Color) -> void:
	_circle(img, cx, cy, r, c.darkened(0.15))
	_circle(img, cx - r / 4, cy - r / 4, maxi(1, r * 3 / 4), c)
	_circle(img, cx - r / 2, cy - r / 2, maxi(1, r / 3), c.lightened(0.15))

# Каменная кладка поверх области (горизонтальные швы и стыки)
static func _masonry(img: Image, r: Rect2i, bw: int, bh: int, c: Color, rng: RandomNumberGenerator) -> void:
	r = r.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	var row := 0
	for y in range(r.position.y, r.end.y, bh):
		img.fill_rect(Rect2i(r.position.x, y, r.size.x, 1), c.darkened(0.22))
		var off := (bw / 2) * (row % 2)
		for x in range(r.position.x - off, r.end.x, bw):
			if x >= r.position.x:
				img.fill_rect(Rect2i(x, y, 1, mini(bh, r.end.y - y)), c.darkened(0.18))
			if rng.randf() < 0.25 and x + 2 < r.end.x and y + 1 < r.end.y:
				img.fill_rect(Rect2i(maxi(x + 1, r.position.x), y + 1, mini(bw - 2, r.end.x - x - 1), 1), c.lightened(0.07))
		row += 1
