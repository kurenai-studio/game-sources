class_name FarArt
# ---------- Фоны дальних локаций Арены (волны 61–80) ----------
#   ice_backdrop    — Ледяная тропа: ночное небо, звёзды, северное сияние,
#                     снежные горы и светящиеся ледяные пики, снежная равнина;
#   storm_backdrop  — Храм шторма: тяжёлые тучи, застывшая молния, скала с храмом
#                     и башней-громоотводом, косой дождь, мокрые руины;
#   lava_backdrop   — Лавовые просторы: дымное небо в зареве, вулкан, горы из пепла
#                     и обсидиана, каменные арки, лавовые реки, сажа;
#   throne_backdrop — Тронный зал Тёмного лорда: стрельчатые окна с багровым вихрем,
#                     обсидиановые колонны с лавовыми жилами, знамёна, трон на возвышении.
# Рисуется маленькая картинка (в 4 раза меньше карты) и растягивается без сглаживания.

const SCALE := PixelArt.SCALE

static func _img(map_w: float, floor_y: float) -> Image:
	return Image.create(int(map_w / SCALE), int(floor_y / SCALE) + 2, false, Image.FORMAT_RGBA8)

static func _px(img: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < img.get_width() and y < img.get_height():
		if c.a >= 0.999:
			img.set_pixel(x, y, c)
		else:
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(c.r, c.g, c.b), c.a))

static func _blend_rect(img: Image, r: Rect2i, c: Color) -> void:
	r = r.intersection(Rect2i(0, 0, img.get_width(), img.get_height()))
	for y in range(r.position.y, r.end.y):
		for x in range(r.position.x, r.end.x):
			img.set_pixel(x, y, img.get_pixel(x, y).lerp(Color(c.r, c.g, c.b), c.a))

static func _line(img: Image, a: Vector2, b: Vector2, c: Color, w := 1) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n:
		var p := a.lerp(b, float(i) / maxf(1.0, n - 1))
		for dx in w:
			_px(img, int(p.x) + dx, int(p.y), c)

# Облако / клуб дыма: несколько кругов
static func _puff(img: Image, cx: int, cy: int, r: int, c: Color, rng: RandomNumberGenerator) -> void:
	for k in 5:
		var ox := rng.randi_range(-r, r)
		var oy := rng.randi_range(-r / 3, r / 3)
		var rr := rng.randi_range(r / 2, r)
		for y in range(-rr, rr + 1):
			var hw := int(sqrt(maxf(0.0, float(rr * rr - y * y))))
			for x in range(-hw, hw + 1):
				_px(img, cx + ox + x, cy + oy + y, c)

# ===================== Ледяная тропа =====================
static func ice_backdrop(map_w: float, floor_y: float) -> Image:
	var img := _img(map_w, floor_y)
	var w := img.get_width()
	var h := img.get_height()
	var rng := RandomNumberGenerator.new()
	rng.seed = 6161
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.03, 0.04, 0.12), Color(0.22, 0.24, 0.48), 18)
	# Млечный путь — наискосок через небо
	for i in 900:
		var t := rng.randf()
		var x := int(t * w)
		var y := int(lerpf(h * 0.05, h * 0.32, t) + rng.randf_range(-14, 14))
		_px(img, x, y, Color(0.75, 0.75, 1.0, rng.randf_range(0.05, 0.22)))
	for i in 260:                                          # звёзды
		var sx := rng.randi_range(0, w - 1)
		var sy := rng.randi_range(0, int(h * 0.62))
		var a := rng.randf_range(0.3, 1.0)
		_px(img, sx, sy, Color(1, 1, 1, a))
		if a > 0.9 and rng.randf() < 0.4:
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				_px(img, sx + d.x, sy + d.y, Color(0.8, 0.85, 1.0, 0.45))
	# северное сияние: несколько волнистых «занавесов»
	var bands := [[0.20, 0.10, 0.018, Color(0.25, 1.0, 0.65)], [0.27, 0.07, 0.026, Color(0.35, 0.95, 1.0)],
			[0.15, 0.05, 0.013, Color(0.7, 0.45, 1.0)]]
	for bd in bands:
		var base: float = h * float(bd[0])
		var amp: float = h * float(bd[1])
		var fr: float = bd[2]
		var col: Color = bd[3]
		var ph := rng.randf() * TAU
		for x in w:
			var yc := base + sin(x * fr + ph) * amp + sin(x * fr * 2.7 + ph * 2.0) * amp * 0.3
			var strength := 0.5 + 0.5 * sin(x * 0.05 + ph)
			var tall := int(22 + 14 * strength)
			for k in tall:
				var a2 := (1.0 - float(k) / tall) * 0.42 * (0.4 + 0.6 * strength)
				if (x + k) % 3 == 0:
					a2 *= 0.7                              # вертикальные «лучи» занавеса
				_px(img, x, int(yc) + k, Color(col.r, col.g, col.b, a2))
			_px(img, x, int(yc) - 1, Color(col.r, col.g, col.b, 0.15))
	# дальние горы — бледные, в снегу
	var far := PixelArt._ridge(w, h * 0.70, [[w * 0.12, 70, 70], [w * 0.22, 52, 30], [w * 0.36, 95, 80], [w * 0.47, 60, 28], [w * 0.62, 80, 70], [w * 0.75, 58, 26], [w * 0.88, 100, 85]], rng, 1.2)
	PixelArt._mountains(img, far, h, Color(0.42, 0.48, 0.70), Color(0.30, 0.34, 0.56), h * 0.58, rng)
	# светящиеся ледяные пики (как кристаллы) с ореолом
	for i in 9:
		var cx := int(w * (0.06 + 0.11 * i) + rng.randi_range(-12, 12))
		var ch := rng.randi_range(34, 70)
		PixelArt._halo(img, cx, int(h * 0.74) - ch / 2, ch / 2 + 10, Color(0.45, 0.9, 1.0, 0.25))
		DeepArt.spire(img, cx, int(h * 0.80), rng.randi_range(4, 7), ch, Color(0.45, 0.80, 0.95), rng.randf_range(-0.12, 0.12))
		for k in rng.randi_range(1, 3):
			DeepArt.spire(img, cx + rng.randi_range(-12, 12), int(h * 0.80), rng.randi_range(2, 4), ch / 2 + rng.randi_range(0, 12),
					Color(0.55, 0.88, 1.0), rng.randf_range(-0.3, 0.3))
	# ближние горы — тёмные скалы со снежными шапками
	var near := PixelArt._ridge(w, h * 0.86, [[w * 0.05, 60, 55], [w * 0.28, 48, 60], [w * 0.5, 64, 50], [w * 0.74, 52, 65], [w * 0.97, 66, 60]], rng, 1.6)
	PixelArt._mountains(img, near, h, Color(0.20, 0.23, 0.38), Color(0.13, 0.15, 0.27), h * 0.74, rng)
	# снежная равнина с наносами
	var gy := int(h * 0.90)
	for x in w:
		var drift := int(3.0 * sin(x * 0.07) + 2.0 * sin(x * 0.19 + 1.3))
		for y in range(gy + drift, h):
			var k2 := float(y - gy) / maxf(1.0, h - gy)
			img.set_pixel(x, y, Color(0.70, 0.76, 0.92).lerp(Color(0.48, 0.54, 0.76), k2))
		_px(img, x, gy + drift, Color(0.92, 0.95, 1.0))
	# одинокие ели в снегу
	for i in 14:
		var tx := rng.randi_range(4, w - 4)
		PixelArt._pine(img, tx, gy + 2, rng.randi_range(8, 16), Color(0.10, 0.16, 0.22))
		_px(img, tx, gy + 2 - rng.randi_range(4, 8), Color(0.9, 0.95, 1.0))
	PixelArt._grain(img, Rect2i(0, int(h * 0.55), w, h), 0.03, 0.06, rng)
	return img

# ===================== Храм шторма =====================
static func storm_backdrop(map_w: float, floor_y: float) -> Image:
	var img := _img(map_w, floor_y)
	var w := img.get_width()
	var h := img.get_height()
	var rng := RandomNumberGenerator.new()
	rng.seed = 6666
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.11, 0.12, 0.17), Color(0.36, 0.40, 0.46), 16)
	# тяжёлые тучи слоями
	for layer in 3:
		var cy := int(h * (0.08 + 0.12 * layer))
		var col := Color(0.22, 0.24, 0.30).lerp(Color(0.40, 0.43, 0.50), layer / 2.0)
		var x := -10
		while x < w + 10:
			_puff(img, x, cy + rng.randi_range(-6, 6), rng.randi_range(12, 22), Color(col.r, col.g, col.b, 0.85), rng)
			_puff(img, x + 4, cy - 4, rng.randi_range(6, 10), Color(col.r + 0.08, col.g + 0.08, col.b + 0.09, 0.5), rng)
			x += rng.randi_range(14, 26)
	# застывшая молния — от туч к дальней вершине
	var p := Vector2(w * 0.78, h * 0.18)
	PixelArt._halo(img, int(p.x), int(h * 0.4), 40, Color(0.7, 0.8, 1.0, 0.18))
	for i in 22:
		var np := p + Vector2(rng.randf_range(-4, 4), rng.randf_range(2.5, 4.5))
		_line(img, p, np, Color(0.92, 0.95, 1.0))
		_line(img, p + Vector2(1, 0), np + Vector2(1, 0), Color(0.6, 0.75, 1.0, 0.6))
		if i == 9:
			var q := np
			for j in 7:
				var nq := q + Vector2(rng.randf_range(1, 4), rng.randf_range(1.5, 3.5))
				_line(img, q, nq, Color(0.8, 0.88, 1.0, 0.85))
				q = nq
		p = np
	# дальние горы — тёмный сланец
	var far := PixelArt._ridge(w, h * 0.66, [[w * 0.15, 60, 80], [w * 0.45, 70, 90], [w * 0.8, 85, 85]], rng, 1.0)
	PixelArt._mountains(img, far, h, Color(0.26, 0.28, 0.34), Color(0.19, 0.21, 0.27), 0.0, rng)
	# скала с храмом посередине
	var cx := int(w * 0.5)
	var cliff := PixelArt._ridge(w, h * 0.78, [[cx, 70, 120]], rng, 0.8)
	PixelArt._mountains(img, cliff, h, Color(0.30, 0.31, 0.36), Color(0.22, 0.23, 0.28), 0.0, rng)
	var ty := int(cliff[cx]) + 2
	var stone := Color(0.52, 0.54, 0.58)
	# ступенчатое основание и колоннада
	for s in 3:
		var sw := 70 - s * 14
		img.fill_rect(Rect2i(cx - sw / 2, ty - 4 - s * 4, sw, 4), stone.darkened(0.15 - s * 0.05))
	var top := ty - 16
	img.fill_rect(Rect2i(cx - 26, top - 18, 52, 3), stone.lightened(0.05))
	for k in 7:
		img.fill_rect(Rect2i(cx - 24 + k * 8, top - 15, 3, 15), stone)
		_px(img, cx - 24 + k * 8, top - 15, stone.lightened(0.2))
	for y in 8:                                             # фронтон
		img.fill_rect(Rect2i(cx - 26 + y * 3, top - 26 + y, 52 - y * 6, 1), stone.darkened(0.05))
	# башня-громоотвод с горящей сферой
	img.fill_rect(Rect2i(cx + 30, top - 60, 10, 60), stone.darkened(0.1))
	img.fill_rect(Rect2i(cx + 30, top - 60, 2, 60), stone.lightened(0.1))
	img.fill_rect(Rect2i(cx + 28, top - 64, 14, 4), stone.lightened(0.05))
	_line(img, Vector2(cx + 35, top - 64), Vector2(cx + 35, top - 84), Color(0.75, 0.55, 0.30))
	PixelArt._halo(img, cx + 35, top - 70, 22, Color(0.55, 0.75, 1.0, 0.45))
	PixelArt._circle(img, cx + 35, top - 70, 3, Color(0.85, 0.95, 1.0))
	# мокрые руины на переднем плане: обломки колонн и плиты
	var gy := int(h * 0.90)
	img.fill_rect(Rect2i(0, gy, w, h - gy), Color(0.20, 0.21, 0.25))
	for i in 16:
		var rx := rng.randi_range(0, w - 1)
		var rh := rng.randi_range(8, 30)
		var rw := rng.randi_range(4, 8)
		var c := Color(0.30, 0.31, 0.36).lerp(Color(0.40, 0.41, 0.46), rng.randf())
		img.fill_rect(Rect2i(rx, gy - rh, rw, rh), c)
		img.fill_rect(Rect2i(rx, gy - rh, 1, rh), c.lightened(0.12))
		for k in rng.randi_range(0, 2):                     # отколотый верх
			_px(img, rx + rng.randi_range(0, rw - 1), gy - rh - 1, c)
	# лужи с отражением неба
	for i in 18:
		var lx := rng.randi_range(0, w - 20)
		var lw := rng.randi_range(8, 26)
		var ly := rng.randi_range(gy + 2, h - 2)
		img.fill_rect(Rect2i(lx, ly, lw, 1), Color(0.48, 0.52, 0.60))
	# косой дождь по всей картинке
	for i in 1200:
		var x0 := rng.randi_range(-20, w)
		var y0 := rng.randi_range(0, h)
		for k in 4:
			_px(img, x0 + k, y0 + k * 2, Color(0.75, 0.80, 0.90, 0.16))
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.03, 0.05, rng)
	return img

# ===================== Лавовые просторы =====================
static func lava_backdrop(map_w: float, floor_y: float) -> Image:
	var img := _img(map_w, floor_y)
	var w := img.get_width()
	var h := img.get_height()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7171
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.07, 0.05, 0.06), Color(0.50, 0.20, 0.10), 18)
	# дымные тучи в зареве
	for i in 40:
		var c := Color(0.14, 0.10, 0.10).lerp(Color(0.36, 0.18, 0.12), rng.randf())
		_puff(img, rng.randi_range(-10, w + 10), rng.randi_range(4, int(h * 0.42)), rng.randi_range(10, 24), Color(c.r, c.g, c.b, 0.75), rng)
	# солнце сквозь пепел — тусклый диск
	PixelArt._halo(img, int(w * 0.22), int(h * 0.30), 30, Color(1.0, 0.85, 0.6, 0.35))
	PixelArt._circle(img, int(w * 0.22), int(h * 0.30), 8, Color(1.0, 0.88, 0.70))
	# вулкан вдали: конус, кратер, лавовые потоки, столб дыма
	var vx := int(w * 0.7)
	var vy := int(h * 0.36)
	var vbase := int(h * 0.78)
	for y in range(vy, vbase):
		var k := float(y - vy) / (vbase - vy)
		var hw := int(10 + k * 120)
		img.fill_rect(Rect2i(vx - hw, y, hw * 2, 1), Color(0.16, 0.12, 0.12).lerp(Color(0.10, 0.08, 0.09), k))
		img.fill_rect(Rect2i(vx - hw, y, maxi(1, hw / 3), 1), Color(0.22, 0.16, 0.15))
	PixelArt._halo(img, vx, vy, 26, Color(1.0, 0.5, 0.15, 0.6))
	img.fill_rect(Rect2i(vx - 9, vy - 1, 18, 3), Color(1.0, 0.6, 0.2))
	for s in [-1, 1, 0]:                                    # лава течёт по склонам
		var q := Vector2(vx + s * 4, vy + 1)
		for i in 60:
			var nq := q + Vector2(s * rng.randf_range(0.2, 1.6) + rng.randf_range(-0.6, 0.6), 1.0)
			_px(img, int(nq.x), int(nq.y), Color(1.0, 0.45 + rng.randf() * 0.3, 0.12))
			_px(img, int(nq.x) + 1, int(nq.y), Color(0.9, 0.3, 0.1, 0.6))
			q = nq
	for i in 26:                                            # столб дыма
		var t := float(i) / 26.0
		_puff(img, vx + int(sin(t * 4.0) * 10 + t * 40), vy - 6 - int(t * vy * 0.9), int(6 + t * 16),
				Color(0.18, 0.15, 0.15, 0.55 - t * 0.25), rng)
	# горы из пепла (серые, светлые вершины)
	var ash := PixelArt._ridge(w, h * 0.72, [[w * 0.08, 50, 70], [w * 0.32, 66, 80], [w * 0.94, 60, 70]], rng, 1.4)
	PixelArt._mountains(img, ash, int(h * 0.84), Color(0.36, 0.32, 0.31), Color(0.25, 0.22, 0.22), h * 0.46, rng)
	# обсидиановые шипы — чёрные, со стеклянным бликом
	for i in 22:
		var sx := rng.randi_range(0, w)
		var sh := rng.randi_range(18, 56)
		var lean := rng.randf_range(-0.35, 0.35)
		DeepArt.spire(img, sx, int(h * 0.86), rng.randi_range(3, 7), sh, Color(0.10, 0.08, 0.12), lean)
		_line(img, Vector2(sx - 1, h * 0.86 - 2), Vector2(sx + lean * sh * 0.8, h * 0.86 - sh * 0.8), Color(0.62, 0.55, 0.75, 0.55))
	# каменные арки (как на концепте)
	for ax: int in [int(w * 0.14), int(w * 0.56), int(w * 0.9)]:
		var aw := rng.randi_range(46, 64)
		var ah := rng.randi_range(56, 76)
		var base := int(h * 0.88)
		var rock := Color(0.15, 0.12, 0.12)
		for t in 90:
			var a := PI * float(t) / 89.0
			var px := ax + int(cos(a) * aw / 2.0)
			var py := base - int(sin(a) * ah)
			var thick := 7 if t > 20 and t < 70 else 9
			img.fill_rect(Rect2i(px - thick / 2, py - 2, thick, 5), rock)
			_px(img, px - thick / 2, py - 2, rock.lightened(0.15))
		img.fill_rect(Rect2i(ax - aw / 2 - 6, base - 12, 12, 12), rock)
		img.fill_rect(Rect2i(ax + aw / 2 - 6, base - 12, 12, 12), rock)
		for k in 10:                                        # тлеющие трещины в арке
			var t2 := rng.randf()
			var a2 := PI * t2
			_px(img, ax + int(cos(a2) * aw / 2.0), base - int(sin(a2) * ah), Color(1.0, 0.45, 0.15, 0.8))
	# лавовые реки вдали — тонкие светящиеся ленты между шипами; у подножия — тёмный базальт
	var gy := int(h * 0.88)
	img.fill_rect(Rect2i(0, gy, w, h - gy), Color(0.09, 0.07, 0.08))
	for x in w:
		_px(img, x, gy, Color(0.20, 0.14, 0.13))
	for i in 7:                                            # дальние лавовые озёра у подножия гор
		var lx := rng.randi_range(20, w - 20)
		var ly := int(h * 0.845) + rng.randi_range(-3, 3)
		var lw := rng.randi_range(14, 34)
		PixelArt._halo(img, lx, ly, lw, Color(1.0, 0.45, 0.15, 0.25))
		for x in range(-lw / 2, lw / 2):
			var dy := int(2.0 * sqrt(maxf(0.0, 1.0 - pow(2.0 * x / lw, 2))))
			for y in range(-dy, dy + 1):
				_px(img, lx + x, ly + y, Color(1.0, 0.65 if y == 0 else 0.45, 0.1))
	# сажа и искры в воздухе
	for i in 500:
		var sx := rng.randi_range(0, w - 1)
		var sy := rng.randi_range(0, h - 1)
		if rng.randf() < 0.75:
			_px(img, sx, sy, Color(0.05, 0.04, 0.04, rng.randf_range(0.3, 0.8)))
		else:
			_px(img, sx, sy, Color(1.0, 0.6, 0.25, rng.randf_range(0.4, 0.9)))
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.03, 0.05, rng)
	return img

# ===================== Тронный зал Тёмного лорда =====================
static func throne_backdrop(map_w: float, floor_y: float) -> Image:
	var img := _img(map_w, floor_y)
	var w := img.get_width()
	var h := img.get_height()
	var rng := RandomNumberGenerator.new()
	rng.seed = 8080
	var wall := Color(0.13, 0.10, 0.12)
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.06, 0.04, 0.05), wall, 12)
	PixelArt._masonry(img, Rect2i(0, 0, w, h), 14, 6, wall, rng)
	var cx := w / 2
	# стрельчатые окна: в них — багровое небо с огненным вихрем
	var win_x := []
	for i in 6:
		var x := int(w * (0.08 + i * 0.168))
		if absf(x - cx) < 60:
			continue
		win_x.append(x)
	for x: int in win_x:
		var ww := 26
		var wy := int(h * 0.12)
		var wh := int(h * 0.50)
		for y in range(wy, wy + wh):
			var k := float(y - wy) / wh
			var half := ww / 2
			if y < wy + ww / 2:                              # стрельчатый верх
				var t := float(y - wy) / (ww / 2.0)
				half = int(ww / 2.0 * sqrt(t))
			for xx in range(x - half, x + half):
				var d := Vector2(xx - x, (y - wy - wh * 0.35) * 0.8).length()
				var swirl := 0.5 + 0.5 * sin(d * 0.6 - atan2(y - wy - wh * 0.35, xx - x) * 3.0)
				var c := Color(0.55, 0.10, 0.06).lerp(Color(1.0, 0.55, 0.18), swirl * (1.0 - k * 0.6))
				img.set_pixel(clampi(xx, 0, w - 1), clampi(y, 0, h - 1), c)
		# переплёт и рама
		_line(img, Vector2(x, wy + 2), Vector2(x, wy + wh), Color(0.05, 0.03, 0.04))
		for yy in range(wy + 16, wy + wh, 14):
			_line(img, Vector2(x - ww / 2, yy), Vector2(x + ww / 2, yy), Color(0.05, 0.03, 0.04))
		for yy in range(wy, wy + wh + 2):
			_px(img, x - ww / 2 - 1, yy, Color(0.22, 0.18, 0.20))
			_px(img, x + ww / 2, yy, Color(0.22, 0.18, 0.20))
		img.fill_rect(Rect2i(x - ww / 2 - 3, wy + wh, ww + 6, 3), Color(0.24, 0.20, 0.22))
		PixelArt._halo(img, x, wy + wh + 10, 18, Color(1.0, 0.4, 0.15, 0.18))
	# обсидиановые колонны между окнами, с лавовыми жилами
	for i in 7:
		var x := int(w * (0.0 + i * 0.168)) + 6
		if absf(x - cx) < 40:
			continue
		var c := Color(0.08, 0.06, 0.08)
		img.fill_rect(Rect2i(x - 7, 0, 14, h), c)
		img.fill_rect(Rect2i(x - 7, 0, 2, h), Color(0.26, 0.22, 0.30))
		img.fill_rect(Rect2i(x - 9, int(h * 0.72), 18, 4), Color(0.16, 0.13, 0.16))
		var q := Vector2(x + rng.randi_range(-3, 3), 0)
		for y in h:
			q.x = clampf(q.x + rng.randf_range(-0.8, 0.8), x - 5, x + 5)
			if rng.randf() < 0.85:
				_px(img, int(q.x), y, Color(1.0, 0.35, 0.10, 0.75))
	# знамёна со знаком Тёмного лорда (рогатый шлем)
	for x: int in win_x:
		for s in [-1, 1]:
			var bx: int = x + s * 22
			var by := int(h * 0.06)
			img.fill_rect(Rect2i(bx - 5, by, 10, 46), Color(0.42, 0.06, 0.08))
			for k in 5:                                       # «ласточкин хвост»
				img.fill_rect(Rect2i(bx - 5 + k, by + 46 + k, 1, 1), Color(0.42, 0.06, 0.08))
				img.fill_rect(Rect2i(bx + 4 - k, by + 46 + k, 1, 1), Color(0.42, 0.06, 0.08))
			img.fill_rect(Rect2i(bx - 3, by + 14, 6, 6), Color(0.85, 0.65, 0.25))
			_px(img, bx - 3, by + 12, Color(0.85, 0.65, 0.25))
			_px(img, bx + 2, by + 12, Color(0.85, 0.65, 0.25))
			_px(img, bx, by + 22, Color(0.85, 0.65, 0.25))
	# круглое окно-роза над троном: в нём огненный вихрь
	var ry := int(h * 0.30)
	var rr := 34
	for y in range(-rr, rr + 1):
		for x in range(-rr, rr + 1):
			var d := Vector2(x, y).length()
			if d > rr:
				continue
			var ang := atan2(y, x)
			var swirl := 0.5 + 0.5 * sin(d * 0.45 - ang * 2.0)
			var c := Color(0.45, 0.06, 0.05).lerp(Color(1.0, 0.62, 0.22), swirl * (1.0 - d / rr * 0.5))
			if d > rr - 3:
				c = Color(0.22, 0.18, 0.22)
			elif int(round(fmod(ang + PI, TAU / 8.0) * 10.0)) == 0 or absf(d - rr * 0.45) < 0.8:
				c = Color(0.05, 0.03, 0.04)                 # переплёт розы
			_px(img, cx + x, ry + y, c)
	PixelArt._halo(img, cx, ry, rr + 16, Color(1.0, 0.4, 0.15, 0.15))
	# трон на возвышении посередине
	var base := int(h * 0.96)
	for s in 5:
		var sw := 120 - s * 16
		img.fill_rect(Rect2i(cx - sw / 2, base - (s + 1) * 4, sw, 4), Color(0.12, 0.10, 0.12).lightened(s * 0.02))
		img.fill_rect(Rect2i(cx - sw / 2, base - (s + 1) * 4, sw, 1), Color(0.30, 0.25, 0.30))
	var ty := base - 20
	PixelArt._halo(img, cx, ty - 34, 50, Color(0.9, 0.25, 0.1, 0.25))
	var throne := Color(0.07, 0.05, 0.07)
	img.fill_rect(Rect2i(cx - 22, ty - 20, 44, 20), throne)              # сиденье и подлокотники
	img.fill_rect(Rect2i(cx - 16, ty - 70, 32, 52), throne)              # спинка
	for k in 5:                                                          # шипы на спинке
		var sx := cx - 16 + k * 8
		var spike := 14 + (6 if k == 2 else 0) - absi(k - 2) * 2
		for y in spike:
			var hw := maxi(0, 3 - y * 3 / spike)
			img.fill_rect(Rect2i(sx - hw + 1, ty - 70 - y, hw * 2 + 1, 1), throne)
	img.fill_rect(Rect2i(cx - 16, ty - 70, 1, 52), Color(0.32, 0.26, 0.34))
	PixelArt._circle(img, cx, ty - 54, 4, Color(0.95, 0.25, 0.12))      # камень в спинке
	_px(img, cx - 1, ty - 56, Color(1.0, 0.8, 0.6))
	for s in [-1, 1]:                                                    # жаровни у трона
		var fx: int = cx + s * 58
		img.fill_rect(Rect2i(fx - 4, base - 30, 8, 26), Color(0.16, 0.13, 0.15))
		PixelArt._halo(img, fx, base - 36, 16, Color(1.0, 0.45, 0.15, 0.5))
		for k in 6:
			_px(img, fx + rng.randi_range(-3, 3), base - 32 - k * 2, Color(1.0, 0.65 - k * 0.06, 0.2))
	# тёмный цоколь стены с тлеющей щелью
	var gy := int(h * 0.97)
	for x in w:
		var hot := 0.5 + 0.5 * sin(x * 0.13)
		img.fill_rect(Rect2i(x, gy, 1, h - gy), Color(0.10, 0.07, 0.08))
		_px(img, x, gy, Color(0.75, 0.22 + hot * 0.2, 0.06, 0.7))
	for i in 60:                                                          # отсветы лавы на стене
		_px(img, rng.randi_range(0, w - 1), rng.randi_range(int(h * 0.8), gy - 2), Color(1.0, 0.4, 0.15, 0.3))
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.03, 0.06, rng)
	return img

# ===================== Вершина цитадели (вторая фаза Тёмного Лорда) =====================
# Небо закручено в багровый вихрь, по нему бьют красные молнии; вдали — чёрные
# скалы с лавопадами и остальные башни цитадели с горящими окнами; ближе всего —
# зубцы крепостной стены, по которой идёт бой.
static func citadel_backdrop(map_w: float, floor_y: float) -> Image:
	var img := _img(map_w, floor_y)
	var w := img.get_width()
	var h := img.get_height()
	var rng := RandomNumberGenerator.new()
	rng.seed = 8181
	PixelArt._vgrad(img, 0, w, 0, h, Color(0.08, 0.02, 0.03), Color(0.46, 0.10, 0.05), 16)
	# огромный вихрь в небе над серединой
	var cx := w / 2
	var cy := int(h * 0.42)
	var rr := 150.0
	for y in range(0, int(h * 0.80)):
		for x in range(cx - 240, cx + 240):
			if x < 0 or x >= w:
				continue
			var d := Vector2(x - cx, (y - cy) * 1.9).length()
			if d > rr * 1.6:
				continue
			var ang := atan2((y - cy) * 1.9, x - cx)
			var k := clampf(1.0 - d / (rr * 1.6), 0.0, 1.0)
			var swirl := 0.5 + 0.5 * sin(d * 0.16 - ang * 3.0)
			var c := Color(0.30, 0.04, 0.04).lerp(Color(1.0, 0.50, 0.16), swirl * k * k)
			_px(img, x, y, Color(c.r, c.g, c.b, minf(0.95, k * 1.4)))
	PixelArt._halo(img, cx, cy, 30, Color(1.0, 0.85, 0.55, 0.85))      # «глаз» вихря
	PixelArt._circle(img, cx, cy, 5, Color(1.0, 0.95, 0.8))
	# рваные тучи по краям, подсвеченные снизу
	for i in 46:
		var px := rng.randi_range(-10, w + 10)
		if absi(px - cx) < 140 and rng.randf() < 0.7:
			continue
		var py := rng.randi_range(2, int(h * 0.40))
		var c2 := Color(0.12, 0.04, 0.05).lerp(Color(0.38, 0.10, 0.07), rng.randf())
		_puff(img, px, py, rng.randi_range(10, 20), Color(c2.r, c2.g, c2.b, 0.8), rng)
		_puff(img, px + 3, py + 5, rng.randi_range(5, 9), Color(0.75, 0.25, 0.10, 0.35), rng)
	# красные молнии из вихря
	for s in [-1, 1]:
		var p := Vector2(cx + s * 30, cy + 10)
		for i in 26:
			var np := p + Vector2(s * rng.randf_range(1.0, 5.0), rng.randf_range(1.5, 4.0))
			_line(img, p, np, Color(1.0, 0.70, 0.45))
			_line(img, p + Vector2(1, 0), np + Vector2(1, 0), Color(1.0, 0.30, 0.15, 0.6))
			p = np
	# чёрные скалы вдали с лавопадами
	var cliffs := PixelArt._ridge(w, h * 0.74, [[w * 0.10, 60, 70], [w * 0.30, 40, 60], [w * 0.72, 46, 60], [w * 0.92, 66, 70]], rng, 1.4)
	PixelArt._mountains(img, cliffs, h, Color(0.14, 0.09, 0.10), Color(0.09, 0.06, 0.07), 0.0, rng)
	for fx: int in [int(w * 0.08), int(w * 0.13), int(w * 0.29), int(w * 0.70), int(w * 0.88), int(w * 0.94)]:
		var top := int(cliffs[clampi(fx, 0, w - 1)]) + 2
		PixelArt._halo(img, fx, top + 24, 16, Color(1.0, 0.40, 0.12, 0.35))
		for y in range(top, int(h * 0.86)):
			var wob := int(sin(y * 0.3 + fx) * 1.2)
			_px(img, fx + wob, y, Color(1.0, 0.55 + 0.25 * ((y / 3) % 2), 0.15))
			_px(img, fx + wob + 1, y, Color(0.9, 0.30, 0.10, 0.8))
	# башни цитадели по сторонам: шпили, горящие окна, мост между ними
	var towers := [[0.06, 26, 120], [0.24, 20, 104], [0.31, 14, 74], [0.36, 12, 60], [0.64, 12, 62], [0.69, 15, 80], [0.76, 22, 110], [0.94, 28, 128]]
	for tw in towers:
		var tx := int(w * float(tw[0]))
		var tww: int = tw[1]
		var th: int = tw[2]
		var base := int(h * 0.90)
		var col := Color(0.07, 0.05, 0.07)
		img.fill_rect(Rect2i(tx - tww / 2, base - th, tww, th), col)
		img.fill_rect(Rect2i(tx - tww / 2, base - th, 1, th), Color(0.30, 0.12, 0.10))
		for y in range(0, tww + 10):                                    # конический шпиль
			var hw := int((tww / 2 + 2) * (1.0 - float(y) / (tww + 10)))
			img.fill_rect(Rect2i(tx - hw, base - th - y, hw * 2 + 1, 1), col)
		img.fill_rect(Rect2i(tx - tww / 2 - 2, base - th, tww + 4, 3), Color(0.12, 0.08, 0.10))
		for k in rng.randi_range(2, 4):                                 # горящие окна
			var wy := base - th + 10 + k * rng.randi_range(14, 22)
			if wy > base - 6:
				break
			var wx := tx + rng.randi_range(-tww / 2 + 3, tww / 2 - 4)
			img.fill_rect(Rect2i(wx, wy, 2, 4), Color(1.0, 0.60, 0.20))
			PixelArt._halo(img, wx, wy + 2, 6, Color(1.0, 0.45, 0.15, 0.3))
	for s in [-1, 1]:                                                   # мостики между башнями
		var x0 := int(w * (0.24 if s < 0 else 0.69))
		var x1 := int(w * (0.31 if s < 0 else 0.76))
		var y0 := int(h * 0.90) - 60
		img.fill_rect(Rect2i(mini(x0, x1), y0, absi(x1 - x0), 4), Color(0.08, 0.05, 0.07))
	# зубцы крепостной стены на переднем плане
	var wall_top := int(h * 0.86)
	var stone := Color(0.17, 0.13, 0.15)
	img.fill_rect(Rect2i(0, wall_top, w, h - wall_top), stone)
	PixelArt._masonry(img, Rect2i(0, wall_top, w, h - wall_top), 12, 5, stone, rng)
	for x in range(0, w, 22):
		img.fill_rect(Rect2i(x, wall_top - 9, 12, 9), stone.lightened(0.04))
		img.fill_rect(Rect2i(x, wall_top - 9, 12, 1), Color(0.40, 0.22, 0.18))
		img.fill_rect(Rect2i(x, wall_top - 9, 1, 9), Color(0.32, 0.18, 0.16))
	for x in w:
		_px(img, x, wall_top, Color(0.42, 0.20, 0.14))
	for i in 7:                                                         # факелы на зубцах
		var fx2 := int(w * (0.07 + i * 0.145))
		PixelArt._halo(img, fx2, wall_top - 14, 10, Color(1.0, 0.5, 0.15, 0.45))
		img.fill_rect(Rect2i(fx2, wall_top - 12, 1, 4), Color(0.25, 0.16, 0.12))
		_px(img, fx2, wall_top - 14, Color(1.0, 0.8, 0.4))
	# пепел и искры в воздухе
	for i in 420:
		var sx := rng.randi_range(0, w - 1)
		var sy := rng.randi_range(0, h - 1)
		if rng.randf() < 0.7:
			_px(img, sx, sy, Color(0.05, 0.03, 0.04, rng.randf_range(0.3, 0.7)))
		else:
			_px(img, sx, sy, Color(1.0, 0.55, 0.22, rng.randf_range(0.4, 0.9)))
	PixelArt._grain(img, Rect2i(0, 0, w, h), 0.03, 0.05, rng)
	return img
