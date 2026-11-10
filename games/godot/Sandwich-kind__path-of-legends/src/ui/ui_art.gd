class_name UiArt
# ---------- Рисованные кнопки интерфейса ----------
# Кнопки меню — пластина с бронзовой окантовкой, заклёпками по углам,
# светом сверху и фактурой камня. Экранные кнопки управления — тёмное стекло
# в металлической оправе. Картинки растягиваются по 9 частям, углы не плывут.

static var _cache := {}

static func _key(parts: Array) -> String:
	return str(parts)

# Пластина кнопки меню. state: normal, hover, pressed, disabled
static func button_box(state: String) -> StyleBoxTexture:
	var fill := Color(0.20, 0.16, 0.27)
	var trim := Color(0.86, 0.64, 0.30)
	match state:
		"hover":
			fill = Color(0.28, 0.22, 0.37)
			trim = Color(1.0, 0.80, 0.42)
		"pressed":
			fill = Color(0.30, 0.21, 0.15)
			trim = Color(0.95, 0.72, 0.36)
		"disabled":
			fill = Color(0.15, 0.15, 0.17)
			trim = Color(0.42, 0.40, 0.40)
	var st := StyleBoxTexture.new()
	st.texture = plate(fill, trim, state == "pressed")
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		st.set_texture_margin(side, 14)
	st.content_margin_left = 14
	st.content_margin_right = 14
	st.content_margin_top = 6
	st.content_margin_bottom = 8 if state != "pressed" else 4
	return st

static func plate(fill: Color, trim: Color, pressed: bool) -> ImageTexture:
	var key := _key(["plate", fill, trim, pressed])
	if _cache.has(key):
		return _cache[key]
	var n := 48
	var im := Image.create(n, n, false, Image.FORMAT_RGBA8)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	var out := Color(0.05, 0.04, 0.05)
	for y in n:
		for x in n:
			if _corner_cut(x, y, n, 4):
				continue
			var c := out
			var edge := mini(mini(x, y), mini(n - 1 - x, n - 1 - y))
			if edge >= 2 and edge < 5:
				# бронзовая окантовка: светлая сверху-слева, тёмная снизу-справа
				var lit := (y < n / 2) != pressed
				c = trim.lightened(0.15) if lit else trim.darkened(0.25)
				if edge == 2:
					c = trim.lightened(0.35) if lit else trim.darkened(0.4)
			elif edge >= 5:
				var t := float(y) / n
				if pressed:
					t = 1.0 - t
				c = fill.lightened(0.12 * (1.0 - t)) if t < 0.5 else fill.darkened(0.15 * (t - 0.5) * 2.0)
				if edge == 5:
					c = fill.darkened(0.35)                          # тень под окантовкой
				c = c.lightened(rng.randf_range(-0.03, 0.03)) if rng.randf() < 0.5 else c
			im.set_pixel(x, y, c)
	for p in [Vector2i(8, 8), Vector2i(n - 9, 8), Vector2i(8, n - 9), Vector2i(n - 9, n - 9)]:
		im.set_pixel(p.x, p.y, trim.lightened(0.5))                 # заклёпки
		im.set_pixel(p.x + 1, p.y, trim)
		im.set_pixel(p.x, p.y + 1, trim.darkened(0.3))
		im.set_pixel(p.x + 1, p.y + 1, trim.darkened(0.5))
	var t2 := ImageTexture.create_from_image(im)
	_cache[key] = t2
	return t2

static func _corner_cut(x: int, y: int, n: int, r: int) -> bool:
	var cx := r if x < r else (n - 1 - r if x > n - 1 - r else x)
	var cy := r if y < r else (n - 1 - r if y > n - 1 - r else y)
	return Vector2(x - cx, y - cy).length() > r + 0.3

# Экранная кнопка: тёмное стекло в металлической оправе (цвет задаётся modulate)
static func touch_box() -> StyleBoxTexture:
	var st := StyleBoxTexture.new()
	st.texture = touch_plate()
	for side in [SIDE_LEFT, SIDE_TOP, SIDE_RIGHT, SIDE_BOTTOM]:
		st.set_texture_margin(side, 16)
	return st

static func touch_plate() -> ImageTexture:
	if _cache.has("touch"):
		return _cache["touch"]
	var n := 48
	var im := Image.create(n, n, false, Image.FORMAT_RGBA8)
	for y in n:
		for x in n:
			if _corner_cut(x, y, n, 9):
				continue
			var edge := mini(mini(x, y), mini(n - 1 - x, n - 1 - y))
			var c: Color
			if edge < 2:
				c = Color(0.05, 0.05, 0.07, 0.9)
			elif edge < 4:
				c = Color(0.85, 0.85, 0.9, 0.85) if y < n / 2 else Color(0.5, 0.5, 0.58, 0.85)
			else:
				var t := float(y) / n
				c = Color(0.35, 0.35, 0.45, 0.55).lerp(Color(0.12, 0.12, 0.18, 0.6), t)
				if y < 10 and edge >= 4:
					c = c.lightened(0.18)                                # блик на стекле
			im.set_pixel(x, y, c)
	var t2 := ImageTexture.create_from_image(im)
	_cache["touch"] = t2
	return t2
