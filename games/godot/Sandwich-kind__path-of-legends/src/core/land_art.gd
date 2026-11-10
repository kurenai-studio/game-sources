class_name LandArt
# ---------- Фоны Лесной тропы и Окраины деревни ----------
# Рисуются по пикселям, как и остальные фоны (PixelArt), и растягиваются в 4 раза.

const SCALE := PixelArt.SCALE

# Лесная тропа: утреннее небо в просветах крон, три слоя стволов (дальние —
# бледные и голубоватые), лучи света сквозь листву, папоротники и туман у земли.
static func forest_backdrop(map_w: float, floor_y: float) -> Image:
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 314
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.62, 0.80, 0.88), Color(0.86, 0.92, 0.78), 14)
	# три слоя деревьев: дальние светлые, ближние тёмные
	var layers := [[Color(0.50, 0.64, 0.56), Color(0.56, 0.62, 0.60), 0.62, 4, 9],
			[Color(0.32, 0.50, 0.34), Color(0.40, 0.36, 0.30), 0.78, 7, 14],
			[Color(0.20, 0.36, 0.22), Color(0.30, 0.22, 0.16), 0.94, 12, 20]]
	for L in layers:
		var leaf: Color = L[0]
		var bark: Color = L[1]
		var base := int(h * float(L[2]))
		var tw: int = L[3]
		var x := rng.randi_range(-10, 10)
		while x < w + 10:
			# ствол до самого верха кадра, с корнями
			img.fill_rect(Rect2i(x, 0, tw, base), bark)
			img.fill_rect(Rect2i(x, 0, 1, base), bark.lightened(0.12))
			img.fill_rect(Rect2i(x + tw - 1, 0, 1, base), bark.darkened(0.15))
			for k in 6:
				img.set_pixel(clampi(x + rng.randi_range(1, tw - 2), 0, w - 1), rng.randi_range(4, maxi(5, base - 2)), bark.darkened(0.2))
			img.fill_rect(Rect2i(x - 2, base - 3, tw + 4, 3), bark.darkened(0.08))
			# ветка в сторону с пучком листвы
			if rng.randf() < 0.7:
				var by := rng.randi_range(int(base * 0.25), int(base * 0.6))
				var side := 1 if rng.randf() < 0.5 else -1
				var bl := rng.randi_range(6, 14)
				for i in bl:
					img.set_pixel(clampi(x + tw / 2 + side * (tw / 2 + i), 0, w - 1), clampi(by - i / 3, 0, h - 1), bark)
				PixelArt._bush(img, x + tw / 2 + side * (tw / 2 + bl), by - bl / 3, rng.randi_range(5, 9), leaf)
			# мох у корней
			for mk in 4:
				img.set_pixel(clampi(x + rng.randi_range(0, tw - 1), 0, w - 1), clampi(base - rng.randi_range(4, 16), 0, h - 1), Color(0.35, 0.55, 0.28))
			x += rng.randi_range(tw + 14, tw + 46)
		# густой полог листвы сверху, с клочьями пониже и свисающими лианами
		var cx := -6
		while cx < w + 6:
			var cy := rng.randi_range(-6, int(h * 0.2 * float(L[2])))
			PixelArt._bush(img, cx, cy, rng.randi_range(14, 26), leaf)
			if rng.randf() < 0.35:
				PixelArt._bush(img, cx + rng.randi_range(-6, 6), cy + rng.randi_range(18, 34), rng.randi_range(6, 10), leaf.lightened(0.04))
			if rng.randf() < 0.3:
				var vl := rng.randi_range(10, 30)
				for i in vl:
					img.set_pixel(clampi(cx + int(sin(i * 0.5) * 1.5), 0, w - 1), clampi(cy + 10 + i, 0, h - 1), leaf.darkened(0.15))
			cx += rng.randi_range(8, 14)
	# лучи света сквозь листву
	for i in 7:
		var lx := rng.randi_range(20, w - 40)
		for y in h:
			var off := int(y * 0.45)
			for dx in 7:
				var px := lx + off + dx
				if px >= 0 and px < w:
					img.set_pixel(px, y, img.get_pixel(px, y).lerp(Color(1.0, 0.98, 0.8), 0.13))
	# папоротники, кусты и цветы у земли
	var fx := 0
	while fx < w:
		PixelArt._bush(img, fx, h - rng.randi_range(2, 6), rng.randi_range(3, 7), Color(0.26, 0.48, 0.24))
		if rng.randf() < 0.25:
			img.set_pixel(clampi(fx + 2, 0, w - 1), h - rng.randi_range(4, 9), [Color(1.0, 0.9, 0.4), Color(0.9, 0.5, 0.7), Color(1, 1, 1)][rng.randi() % 3])
		fx += rng.randi_range(4, 10)
	# дымка у земли
	for y in range(int(h * 0.8), h):
		var a := float(y - int(h * 0.8)) / float(h - int(h * 0.8)) * 0.18
		for x2 in w:
			img.set_pixel(x2, y, img.get_pixel(x2, y).lerp(Color(0.9, 0.95, 0.9), a))
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.04, 0.08, rng)
	return img

# Окраина деревни днём: небо, холмы, деревня на пригорке (дома с соломенными
# и черепичными крышами, мельница, колокольня), из некоторых труб идёт дым.
# Впереди — поле с пшеницей и плетень.
static func village_backdrop(map_w: float, floor_y: float) -> Image:
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1077
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.30, 0.52, 0.85), Color(0.80, 0.90, 0.98), 16)
	# солнце высоко в небе
	PixelArt._halo(img, int(w * 0.2), int(h * 0.14), 30, Color(1.0, 0.98, 0.85, 0.6))
	PixelArt._circle(img, int(w * 0.2), int(h * 0.14), 9, Color(1.0, 0.97, 0.8))
	for i in 9:
		var c := PixelArt.cloud()
		img.blend_rect(c, Rect2i(0, 0, c.get_width(), c.get_height()),
				Vector2i(rng.randi_range(0, w - 44), rng.randi_range(int(h * 0.08), int(h * 0.4))))
	# дальние холмы
	var hp := []
	for i in 7:
		hp.append([rng.randi_range(0, w), rng.randi_range(18, 40), rng.randi_range(90, 170)])
	var hills := PixelArt._ridge(w, h * 0.72, hp, rng, 0.8)
	PixelArt._mountains(img, hills, h, Color(0.52, 0.62, 0.72), Color(0.45, 0.54, 0.66), -1.0, rng)
	# пригорок с деревней
	var vp := [[int(w * 0.55), 22, 260]]
	var hill := PixelArt._ridge(w, h * 0.80, vp, rng, 0.5)
	PixelArt._mountains(img, hill, h, Color(0.46, 0.62, 0.32), Color(0.40, 0.54, 0.28), -1.0, rng)
	# дома вдоль пригорка
	var smokes: Array = []
	var x := int(w * 0.30)
	var n := 0
	while x < int(w * 0.86):
		var top := int(hill[clampi(x, 0, w - 1)])
		var hw := rng.randi_range(14, 22)
		var hh := rng.randi_range(10, 15)
		var smoking := n % 3 == 1                    # дым идёт только из некоторых труб
		_house(img, x, top + 3, hw, hh, rng, smoking)
		if smoking:
			smokes.append(Vector2(x + hw - 4, top + 3 - hh - (hw / 2 + 2)))
		x += hw + rng.randi_range(4, 12)
		n += 1
	# колокольня и мельница
	var bx := int(w * 0.58)
	var btop := int(hill[bx])
	img.fill_rect(Rect2i(bx, btop - 34, 8, 36), Color(0.62, 0.56, 0.50))
	img.fill_rect(Rect2i(bx + 2, btop - 28, 4, 5), Color(0.18, 0.14, 0.12))
	for i in 8:
		img.fill_rect(Rect2i(bx + 4 - i / 2, btop - 42 + i, i + 1, 1), Color(0.45, 0.22, 0.18))
	var mx := int(w * 0.80)
	var mtop := int(hill[mx])
	for i in 22:
		img.fill_rect(Rect2i(mx - 3 - i / 6, mtop - 22 + i, 7 + i / 3, 1), Color(0.70, 0.62, 0.52))
	for a in 4:
		var ang := 0.4 + a * PI / 2
		for r in 16:
			var px := mx + int(cos(ang) * r)
			var py := mtop - 20 + int(sin(ang) * r)
			if px >= 0 and px < w and py >= 0 and py < h:
				img.set_pixel(px, py, Color(0.45, 0.32, 0.22))
	# дым из труб — светло-серые клубы, тают вверху
	for f in smokes:
		for k in 12:
			var sy := int(f.y) - k * 4
			var sx := int(f.x) + int(sin(k * 0.6) * 2) + k
			if sy > 0:
				var sc := Color(0.62, 0.62, 0.66).lerp(Color(0.86, 0.88, 0.92), k / 12.0)
				PixelArt._circle(img, sx, sy, 1 + k / 3, img.get_pixel(clampi(sx, 0, w - 1), clampi(sy, 0, h - 1)).lerp(sc, 0.75 - k * 0.04))
	# плетень и поле с пшеницей впереди
	var fy := int(h * 0.88)
	for x2 in range(0, w, 6):
		img.fill_rect(Rect2i(x2, fy - 6, 1, 8), Color(0.42, 0.30, 0.18))
	img.fill_rect(Rect2i(0, fy - 4, w, 1), Color(0.48, 0.34, 0.20))
	img.fill_rect(Rect2i(0, fy - 1, w, 1), Color(0.48, 0.34, 0.20))
	img.fill_rect(Rect2i(0, fy + 1, w, h - fy - 1), Color(0.78, 0.62, 0.30))
	for x3 in range(0, w, 2):
		var sh := rng.randi_range(2, 6)
		img.fill_rect(Rect2i(x3, h - sh - 1, 1, sh), Color(0.92, 0.76, 0.38) if x3 % 4 == 0 else Color(0.70, 0.55, 0.26))
	PixelArt._grain(img, Rect2i(0, int(h * 0.6), w, h), 0.05, 0.1, rng)
	return img

# Домик: стена с балками, окно, крыша, труба (дым из трубы рисуется отдельно).
static func _house(img: Image, x: int, base: int, hw: int, hh: int, rng: RandomNumberGenerator, _smoking: bool) -> void:
	var wall: Color = [Color(0.86, 0.80, 0.66), Color(0.78, 0.70, 0.58), Color(0.70, 0.62, 0.52)][rng.randi() % 3]
	var roof := Color(0.62, 0.45, 0.22) if rng.randf() < 0.5 else Color(0.62, 0.26, 0.20)
	img.fill_rect(Rect2i(x, base - hh, hw, hh), wall)
	img.fill_rect(Rect2i(x, base - hh, 1, hh), Color(0.40, 0.28, 0.18))
	img.fill_rect(Rect2i(x + hw - 1, base - hh, 1, hh), Color(0.40, 0.28, 0.18))
	img.fill_rect(Rect2i(x, base - hh / 2, hw, 1), Color(0.40, 0.28, 0.18))
	var win := Color(0.55, 0.70, 0.85) if rng.randf() < 0.6 else Color(0.2, 0.18, 0.2)
	img.fill_rect(Rect2i(x + hw / 3, base - hh + 3, 3, 3), win)
	img.fill_rect(Rect2i(x + hw - 5, base - 5, 3, 5), Color(0.30, 0.20, 0.12))
	var rh := hw / 2 + 2
	for i in rh:
		img.fill_rect(Rect2i(x + hw / 2 - i - 1, base - hh - rh + i, i * 2 + 2, 1), roof if i % 3 else roof.darkened(0.15))
	img.fill_rect(Rect2i(x + hw - 5, base - hh - rh + 1, 3, rh - 2), Color(0.45, 0.40, 0.38))

# ---------- Жуткий лес и Болото (волны 51–60) ----------
# Мёртвое дерево: ствол сужается кверху, ветки расходятся вилками (без листвы)
static func dead_tree(img: Image, x: int, base_y: int, h: int, w: int, c: Color, rng: RandomNumberGenerator) -> void:
	var iw := img.get_width()
	var ih := img.get_height()
	for y in h:
		var k := float(y) / h
		var hw := int(round(w * (1.0 - k * 0.75) / 2.0))
		var yy := base_y - y
		if yy < 0 or yy >= ih:
			continue
		for xx in range(x - hw, x + hw + 1):
			if xx >= 0 and xx < iw:
				img.set_pixel(xx, yy, c if xx != x - hw else c.lightened(0.08))
	# корни
	for s in [-1, 1]:
		for i in 6:
			var px: int = x + s * (w / 2 + i)
			var py: int = base_y - 3 + i / 2
			if px >= 0 and px < iw and py >= 0 and py < ih:
				img.set_pixel(px, py, c)
	# ветки
	var n := rng.randi_range(3, 6)
	for b in n:
		var by := base_y - int(h * rng.randf_range(0.45, 0.95))
		var dir := -1 if b % 2 == 0 else 1
		_branch(img, Vector2(x, by), Vector2(dir * rng.randf_range(0.6, 1.0), -rng.randf_range(0.3, 1.0)).normalized(),
				rng.randi_range(int(h * 0.18), int(h * 0.35)), c, rng, 2)

static func _branch(img: Image, from: Vector2, dir: Vector2, length: int, c: Color, rng: RandomNumberGenerator, depth: int) -> void:
	var p := from
	for i in length:
		p += dir
		dir = dir.rotated(rng.randf_range(-0.12, 0.12)).normalized()
		var xx := int(p.x)
		var yy := int(p.y)
		if xx >= 0 and xx < img.get_width() and yy >= 0 and yy < img.get_height():
			img.set_pixel(xx, yy, c)
			if i < length / 3 and yy + 1 < img.get_height():
				img.set_pixel(xx, yy + 1, c)
		if depth > 0 and i == length / 2:
			_branch(img, p, dir.rotated(rng.randf_range(0.4, 0.8) * (1 if rng.randf() < 0.5 else -1)).normalized(),
					length / 2, c, rng, depth - 1)

# Жуткий лес: сумеречное серо-лиловое небо, бледная луна в дымке, три слоя
# голых деревьев, вороны на ветках, полосы тумана. Травы нет.
# swamp = true — Болото: впереди тёмная вода с отражениями, камыш, коряги, зелёный туман.
static func eerie_backdrop(map_w: float, floor_y: float, swamp: bool) -> Image:
	var w := int(map_w / SCALE)
	var h := int(floor_y / SCALE) + 2
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 6611 if not swamp else 7722
	if swamp:
		PixelArt._vgrad(img, 0, w, 0, h, Color(0.16, 0.20, 0.18), Color(0.42, 0.50, 0.38), 14)
	else:
		PixelArt._vgrad(img, 0, w, 0, h, Color(0.14, 0.12, 0.20), Color(0.46, 0.42, 0.50), 14)
	# луна в дымке
	var mx := int(w * 0.7)
	var my := int(h * 0.2)
	PixelArt._halo(img, mx, my, 34, Color(0.9, 0.92, 0.85, 0.5) if not swamp else Color(0.8, 0.95, 0.75, 0.45))
	PixelArt._circle(img, mx, my, 10, Color(0.92, 0.92, 0.86) if not swamp else Color(0.85, 0.95, 0.8))
	for i in 40:
		img.set_pixel(rng.randi_range(0, w - 1), rng.randi_range(0, int(h * 0.35)), Color(1, 1, 1, rng.randf_range(0.2, 0.6)))
	# слои голых деревьев
	var layers := [[Color(0.36, 0.34, 0.42), 0.80, 6, 10, 0.55], [Color(0.24, 0.22, 0.28), 0.90, 10, 13, 0.75], [Color(0.13, 0.12, 0.15), 1.0, 14, 16, 0.95]]
	if swamp:
		layers = [[Color(0.32, 0.38, 0.32), 0.78, 6, 10, 0.55], [Color(0.21, 0.26, 0.21), 0.86, 9, 13, 0.75], [Color(0.11, 0.14, 0.11), 0.95, 13, 16, 0.95]]
	for L in layers:
		var c: Color = L[0]
		var base := int(h * float(L[1]))
		var x := rng.randi_range(-8, 8)
		while x < w + 8:
			var th := int(base * float(L[4]) * rng.randf_range(0.75, 1.05))
			dead_tree(img, x, base, th, rng.randi_range(int(L[2]), int(L[3])), c, rng)
			x += rng.randi_range(26, 60)
		if not swamp:
			img.fill_rect(Rect2i(0, base, w, h - base), c.darkened(0.15))
		# полоса тумана над слоем
		for y in range(base - 14, base + 2):
			if y < 0 or y >= h:
				continue
			var a := 0.12 * (1.0 - absf(y - (base - 6)) / 9.0)
			for xx in w:
				img.set_pixel(xx, y, img.get_pixel(xx, y).lerp(Color(0.75, 0.75, 0.82) if not swamp else Color(0.6, 0.8, 0.6), maxf(a, 0.0)))
	# вороны на ветках и в небе
	PixelArt._birds(img, 12, int(h * 0.1), int(h * 0.45), rng, Color(0.05, 0.05, 0.07))
	if swamp:
		# тёмная вода с отражениями, камыш и коряги
		var wy := int(h * 0.86)
		for y in range(wy, h):
			for xx in w:
				var src := img.get_pixel(xx, clampi(wy - (y - wy) * 2, 0, h - 1))
				var water := Color(0.10, 0.14, 0.10)
				img.set_pixel(xx, y, water.lerp(src, 0.25) if (xx + y) % 7 != 0 else water.lightened(0.1))
		var rx := 0
		while rx < w:
			var rh := rng.randi_range(4, 12)
			for i in rh:
				img.set_pixel(rx, wy - i, Color(0.20, 0.30, 0.16))
			if rng.randf() < 0.4:
				img.fill_rect(Rect2i(rx - 1, wy - rh - 2, 2, 3), Color(0.35, 0.22, 0.12))   # рогоз
			rx += rng.randi_range(2, 7)
		for k in 6:
			var sx := rng.randi_range(10, w - 10)
			img.fill_rect(Rect2i(sx - 4, wy - 6, 8, 7), Color(0.16, 0.14, 0.12))          # коряга в воде
			img.set_pixel(sx + 4, wy - 9, Color(0.16, 0.14, 0.12))
		# зелёная дымка
		for y in range(int(h * 0.55), h):
			var a2 := float(y - int(h * 0.55)) / (h * 0.45) * 0.16
			for xx in w:
				img.set_pixel(xx, y, img.get_pixel(xx, y).lerp(Color(0.55, 0.75, 0.45), a2))
	else:
		# тёмная земля у подножия: кочки, камни, кривые надгробия вдали
		var gy := int(h * 0.94)
		img.fill_rect(Rect2i(0, gy, w, h - gy), Color(0.16, 0.14, 0.15))
		for k in 10:
			var gx := rng.randi_range(5, w - 5)
			img.fill_rect(Rect2i(gx, gy - 6, 3, 6), Color(0.30, 0.30, 0.34))
			img.fill_rect(Rect2i(gx - 1, gy - 4, 5, 1), Color(0.30, 0.30, 0.34))
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.04, 0.08, rng)
	return img
