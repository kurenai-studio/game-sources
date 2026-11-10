class_name AvatarRig
extends Node2D
# ---------- Модель Воплощения Тьмы (третья фаза Тёмного Лорда) ----------
# Огромная голова и две кисти рук без тела. Голова — рогатый шлем-череп из
# чёрного обсидиана с лезвием-гребнем, как у Лорда, горящие глаза, камень во лбу
# (тот самый, что был у него в груди), трещины с лавой, длинные чёрные пряди
# по бокам и отдельная нижняя челюсть. Руки — латные когтистые кисти, у
# запястья растворяются в дыму; бывают раскрытые (когти вниз) и сжатые в кулак.
# Рисуется маленькой пиксельной картинкой и растягивается без сглаживания.
#   part — "head" или "hand"; side — для руки: -1 слева на арене (правая рука
#   демона), 1 справа (левая рука).

const OBS := Color(0.10, 0.08, 0.11)
const RIM := Color(0.24, 0.19, 0.27)
const LAVA := Color(1.0, 0.42, 0.10)
const EYE := Color(1.0, 0.62, 0.16)
const BONE := Color(0.80, 0.74, 0.66)
const HEAD_PX := Vector2i(80, 72)
const JAW_PX := Vector2i(40, 15)
const HAND_PX := Vector2i(52, 42)

static var _cache := {}

var part := "head"
var side := -1
var size := Vector2(300, 270)
var bot: Player
var jaw_open := 0.0             # 0 — закрыта, 1 — пасть распахнута
var fist := false
var flat := false               # рука плашмя (удар ладонью по полу)
var dim := 0.0                  # 0 — глаза горят, 1 — погасли
var _jaw_want := 0.0
var _act := ""
var _act_t := 0.0
var _t := 0.0
var _scale := 4.0
var _head: Sprite2D
var _jaw: Sprite2D
var _maw: Polygon2D
var _open_s: Sprite2D
var _fist_s: Sprite2D
var _wisps: Array = []
var _eyes: Array = []
var _hurt_t := 0.0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if part == "head":
		_build_head()
	else:
		_build_hand()

# ---------- Голова ----------
func _build_head() -> void:
	_scale = size.x / 75.0
	# дымная грива позади головы
	for k in 9:
		var w := Polygon2D.new()
		var a := -PI * 0.9 + PI * 0.8 * k / 8.0
		var r := size.x * 0.46
		var base := Vector2.from_angle(a) * Vector2(r, r * 0.8) + Vector2(0, size.y * 0.05)
		w.polygon = PackedVector2Array([base + Vector2(-26, 0), base + Vector2.from_angle(a) * 70.0, base + Vector2(26, 0), base + Vector2(0, 30)])
		w.color = Color(0.05, 0.03, 0.07, 0.75)
		w.z_index = -1
		add_child(w)
		_wisps.append(w)
	_maw = Polygon2D.new()                                    # глотка за челюстью
	var mx := _scale
	_maw.polygon = PackedVector2Array([Vector2(-14, 53) * mx, Vector2(14, 53) * mx, Vector2(11, 66) * mx, Vector2(-11, 66) * mx])
	_maw.position = Vector2(0, -HEAD_PX.y * mx * 0.5)
	_maw.color = Color(0.55, 0.06, 0.04)
	add_child(_maw)
	_head = _sprite(_tex("head"), Vector2(HEAD_PX.x / 2.0, HEAD_PX.y / 2.0))
	_jaw = _sprite(_tex("jaw"), Vector2(JAW_PX.x / 2.0, 0))
	_jaw.position = Vector2(0, (54 - HEAD_PX.y / 2.0) * _scale)
	# живые глаза: мягкое свечение поверх рисунка
	for s: int in [-1, 1]:
		var e := Polygon2D.new()
		e.polygon = PackedVector2Array([Vector2(7, -2.5), Vector2(-6.5, 0.5), Vector2(-4.5, 3.5), Vector2(4.5, 1.5)])
		e.scale = Vector2(_scale * float(s), _scale)
		e.position = Vector2(float(s) * 11.0 * _scale, (33.5 - HEAD_PX.y / 2.0) * _scale)
		e.color = Color(1.0, 0.8, 0.4, 0.55)
		add_child(e)
		_eyes.append(e)

func _sprite(tex: Texture2D, pivot: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.centered = false
	s.offset = -pivot
	s.scale = Vector2(_scale, _scale)
	add_child(s)
	return s

# Точки для лучей и свечения (в мировых координатах)
func eye_points() -> Array:
	var res := []
	for s: float in [-1.0, 1.0]:
		res.append(to_global(Vector2(s * 11.0 * _scale, (33.5 - HEAD_PX.y / 2.0) * _scale)))
	return res

func gem_point() -> Vector2:
	return to_global(Vector2(0, (22.0 - HEAD_PX.y / 2.0) * _scale))

func mouth_point() -> Vector2:
	return to_global(Vector2(0, (58.0 - HEAD_PX.y / 2.0) * _scale + jaw_open * 7.0 * _scale))

# Кончики когтей (откуда летят огненные шары)
func finger_points() -> Array:
	var res := []
	for k in 4:
		var x := (13.0 + k * 7.5 - HAND_PX.x / 2.0) * float(-side if side != 0 else 1)
		res.append(to_global(Vector2(x * _scale, (HAND_PX.y / 2.0 - 2.0) * _scale)))
	return res

# ---------- Рука ----------
func _build_hand() -> void:
	_scale = size.x / 50.0
	for k in 5:                                              # дым у запястья
		var w := Polygon2D.new()
		w.polygon = Util.circle(randf_range(14, 24), 10)
		w.color = Color(0.05, 0.03, 0.07, 0.7)
		w.position = Vector2(randf_range(-30, 30), -size.y * 0.42 - k * 14.0)
		w.z_index = -1
		add_child(w)
		_wisps.append(w)
	_open_s = _sprite(_tex("hand_open"), Vector2(HAND_PX.x / 2.0, HAND_PX.y / 2.0))
	_fist_s = _sprite(_tex("hand_fist"), Vector2(HAND_PX.x / 2.0, HAND_PX.y / 2.0))
	var mir := float(-side) if side != 0 else 1.0       # нарисована левая (на арене) рука
	_open_s.scale.x = _scale * mir
	_fist_s.scale.x = _scale * mir
	_fist_s.visible = false

# ---------- Анимация ----------
func play(n: String) -> void:
	_act = n
	_act_t = 0.0
	match n:
		"roar":
			_jaw_want = 1.0
		"open":
			_jaw_want = 1.0
		"close":
			_jaw_want = 0.0

func hurt() -> void:
	_hurt_t = 0.12

func muzzle() -> Vector2:
	if part == "head":
		return mouth_point()
	var fp := finger_points()
	return fp[1] if fp.size() > 1 else global_position

func _process(delta: float) -> void:
	_t += delta
	_act_t += delta
	if _act == "roar" and _act_t > 1.1:
		_jaw_want = 0.0
		_act = ""
	if _hurt_t > 0.0:
		_hurt_t -= delta
	var flash := Color(1.6, 1.4, 1.4) if _hurt_t > 0.0 else Color.WHITE
	for k in _wisps.size():
		var w: Polygon2D = _wisps[k]
		w.rotation = sin(_t * 1.6 + k) * 0.12
		w.scale = Vector2.ONE * (1.0 + 0.08 * sin(_t * 2.3 + k * 0.7))
	if part == "head":
		jaw_open = move_toward(jaw_open, _jaw_want, delta * 4.0)
		_jaw.position.y = (54 - HEAD_PX.y / 2.0) * _scale + jaw_open * 9.0 * _scale
		_jaw.rotation = sin(_t * 30.0) * 0.015 * jaw_open
		_maw.color = Color(0.55, 0.06, 0.04).lerp(Color(1.0, 0.35, 0.12), jaw_open * (0.6 + 0.4 * sin(_t * 12.0)))
		_head.modulate = flash
		_jaw.modulate = flash
		for e in _eyes:
			(e as Polygon2D).color = Color(1.0, 0.8, 0.4, (0.55 + 0.2 * sin(_t * 5.0)) * (1.0 - dim))
	else:
		_open_s.visible = not fist
		_fist_s.visible = fist
		_open_s.modulate = flash
		_fist_s.modulate = flash
		if flat:                                                       # плашмя — когтями к середине
			rotation = lerp_angle(rotation, (PI / 2.0) * float(side), minf(1.0, delta * 10.0))

# ---------- Пиксельные картинки ----------
static func _tex(id: String) -> ImageTexture:
	if _cache.has(id):
		return _cache[id]
	var im: Image
	match id:
		"head": im = _head_img()
		"jaw": im = _jaw_img()
		"hand_open": im = _hand_img(false)
		"hand_fist": im = _hand_img(true)
	var t := ImageTexture.create_from_image(im)
	_cache[id] = t
	return t

static func _px(im: Image, x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < im.get_width() and y < im.get_height():
		if c.a >= 0.999:
			im.set_pixel(x, y, c)
		else:
			var b := im.get_pixel(x, y)
			im.set_pixel(x, y, Color(lerpf(b.r, c.r, c.a), lerpf(b.g, c.g, c.a), lerpf(b.b, c.b, c.a), maxf(b.a, c.a)))

static func _poly(im: Image, pts: PackedVector2Array, c: Color) -> void:
	var r := Rect2(pts[0], Vector2.ZERO)
	for q in pts:
		r = r.expand(q)
	for y in range(int(r.position.y) - 1, int(r.end.y) + 2):
		for x in range(int(r.position.x) - 1, int(r.end.x) + 2):
			if Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), pts):
				_px(im, x, y, c)

static func _line(im: Image, a: Vector2, b: Vector2, c: Color, w := 1) -> void:
	var n := int(maxf(absf(b.x - a.x), absf(b.y - a.y))) + 1
	for i in n + 1:
		var q := a.lerp(b, float(i) / n)
		for dy in w:
			for dx in w:
				_px(im, int(q.x) + dx, int(q.y) + dy, c)

static func _disc(im: Image, cx: float, cy: float, r: float, c: Color) -> void:
	for y in range(int(cy - r) - 1, int(cy + r) + 2):
		for x in range(int(cx - r) - 1, int(cx + r) + 2):
			if Vector2(x + 0.5 - cx, y + 0.5 - cy).length() <= r:
				_px(im, x, y, c)

# Обводка по краю непрозрачного — так фигура читается на тёмном фоне
static func _outline(im: Image, c: Color) -> void:
	var src := im.duplicate() as Image
	for y in im.get_height():
		for x in im.get_width():
			if src.get_pixel(x, y).a > 0.0:
				continue
			for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
				var q: Vector2i = Vector2i(x, y) + d
				if q.x >= 0 and q.y >= 0 and q.x < im.get_width() and q.y < im.get_height() and src.get_pixel(q.x, q.y).a > 0.5:
					im.set_pixel(x, y, c)
					break

static func _head_img() -> Image:
	var im := Image.create(HEAD_PX.x, HEAD_PX.y, false, Image.FORMAT_RGBA8)
	var cx := HEAD_PX.x / 2.0
	# длинные чёрные пряди по бокам (позади шлема)
	for s: float in [-1.0, 1.0]:
		for k in 4:
			var x0 := cx + s * (22.0 + k * 3.0)
			for y in range(28, 72):
				var x := x0 + s * (sin(y * 0.18 + k) * 1.6 + (y - 28) * 0.10)
				var hc := Color(0.06, 0.05, 0.08) if k % 2 == 0 else Color(0.11, 0.09, 0.14)
				if y > 66 - k * 2:
					hc.a = 0.6
				_px(im, int(x), y, hc)
				_px(im, int(x) + 1, y, hc)
	# рога: толстые у основания, загибаются наружу и вверх
	for s: float in [-1.0, 1.0]:
		var p0 := Vector2(cx + s * 19.0, 24.0)
		var p1 := Vector2(cx + s * 36.0, 22.0)
		var p2 := Vector2(cx + s * 37.0, 2.0)
		for i in 40:
			var t := i / 39.0
			var q := p0.lerp(p1, t).lerp(p1.lerp(p2, t), t)
			var r := lerpf(4.6, 0.6, t)
			var hc := Color(0.20, 0.16, 0.19).lerp(Color(0.42, 0.34, 0.33), t * 0.7)
			if i % 6 == 0 and t < 0.85:
				hc = hc.darkened(0.35)                            # кольца на роге
			_disc(im, q.x, q.y, r, hc)
			if t > 0.86:
				_px(im, int(q.x), int(q.y), Color(1.0, 0.55, 0.25))   # раскалённые кончики
	# череп-шлем
	var skull := PackedVector2Array([Vector2(14, 22), Vector2(25, 15), Vector2(cx, 12), Vector2(55, 15), Vector2(66, 22), Vector2(68, 34),
			Vector2(63, 46), Vector2(58, 56), Vector2(50, 63), Vector2(cx, 65), Vector2(30, 63), Vector2(22, 56), Vector2(17, 46), Vector2(12, 34)])
	_poly(im, skull, OBS)
	# свет сверху-слева, тень снизу
	for y in range(12, 66):
		for x in range(10, 70):
			var c0 := im.get_pixel(x, y)
			if c0.a < 0.9 or not Geometry2D.is_point_in_polygon(Vector2(x + 0.5, y + 0.5), skull):
				continue
			var k := clampf((y - 12) / 53.0, 0.0, 1.0)
			var sidek := absf(x - cx) / 30.0
			im.set_pixel(x, y, OBS.lightened(0.10 * (1.0 - k) + 0.05 * sidek).darkened(0.25 * k))
	# грани: скулы и пластины
	for s: float in [-1.0, 1.0]:
		_poly(im, PackedVector2Array([Vector2(cx + s * 24, 40), Vector2(cx + s * 14, 44), Vector2(cx + s * 16, 52), Vector2(cx + s * 22, 49)]), RIM)
		_poly(im, PackedVector2Array([Vector2(cx + s * 27, 22), Vector2(cx + s * 16, 17), Vector2(cx + s * 8, 16), Vector2(cx + s * 14, 21)]), RIM.darkened(0.1))
		_line(im, Vector2(cx + s * 27, 23), Vector2(cx + s * 30, 34), RIM.lightened(0.1))
	# лезвие-гребень на лбу (как на шлеме Лорда)
	_poly(im, PackedVector2Array([Vector2(cx - 3, 20), Vector2(cx - 0.5, -1), Vector2(cx + 0.5, -1), Vector2(cx + 3, 20)]), Color(0.18, 0.16, 0.22))
	_line(im, Vector2(cx + 1, 2), Vector2(cx + 2, 18), Color(1.0, 0.45, 0.15, 0.9))
	_line(im, Vector2(cx - 1, 3), Vector2(cx - 2, 18), Color(0.42, 0.38, 0.48))
	# тяжёлые брови буквой V
	for s: float in [-1.0, 1.0]:
		_line(im, Vector2(cx + s * 22, 26), Vector2(cx + s * 4, 31), Color(0.17, 0.14, 0.20), 3)
		_line(im, Vector2(cx + s * 22, 26), Vector2(cx + s * 4, 31), Color(0.32, 0.27, 0.36), 1)
	# глаза: раскосые, горят
	for s: float in [-1.0, 1.0]:
		var eye := PackedVector2Array([Vector2(cx + s * 18, 31), Vector2(cx + s * 5, 34), Vector2(cx + s * 7, 37), Vector2(cx + s * 16, 35)])
		_poly(im, eye, EYE)
		_line(im, Vector2(cx + s * 15, 33), Vector2(cx + s * 8, 35), Color(1.0, 0.95, 0.7))
		# слёзы-трещины с лавой
		var q := Vector2(cx + s * 11, 37)
		for i in 9:
			var nq := q + Vector2(s * (0.6 if i % 3 == 0 else -0.3), 1.2)
			_px(im, int(nq.x), int(nq.y), Color(LAVA, 0.9))
			q = nq
	# камень во лбу — тот самый, из груди Лорда
	_poly(im, PackedVector2Array([Vector2(cx, 18), Vector2(cx + 4, 22.5), Vector2(cx, 27), Vector2(cx - 4, 22.5)]), Color(1.0, 0.32, 0.10))
	_px(im, int(cx) - 1, 20, Color(1.0, 0.85, 0.55))
	_px(im, int(cx), 21, Color(1.0, 0.70, 0.40))
	# нос — две щели
	_px(im, int(cx) - 2, 43, Color(0.02, 0.01, 0.02))
	_px(im, int(cx) + 1, 43, Color(0.02, 0.01, 0.02))
	_px(im, int(cx) - 2, 44, Color(0.02, 0.01, 0.02))
	_px(im, int(cx) + 1, 44, Color(0.02, 0.01, 0.02))
	# трещины с лавой по щекам и черепу
	var rng := RandomNumberGenerator.new()
	rng.seed = 808
	for k in 7:
		var q := Vector2(rng.randf_range(20, 60), rng.randf_range(14, 50))
		if absf(q.x - cx) < 5:
			continue
		for i in rng.randi_range(4, 8):
			var nq := q + Vector2(rng.randf_range(-1.4, 1.4), rng.randf_range(0.4, 1.4))
			_px(im, int(nq.x), int(nq.y), Color(LAVA, 0.75))
			q = nq
	# пасть: тёмная щель и верхние клыки
	_poly(im, PackedVector2Array([Vector2(26, 53), Vector2(54, 53), Vector2(52, 66), Vector2(28, 66)]), Color(0.08, 0.01, 0.02))
	for k in 7:
		var tx := 28.0 + k * 4.0
		var long := 5.0 if k in [1, 5] else 3.0
		_poly(im, PackedVector2Array([Vector2(tx - 1.5, 53), Vector2(tx + 1.5, 53), Vector2(tx, 53 + long)]), BONE)
	_outline(im, Color(0.02, 0.01, 0.03))
	return im

static func _jaw_img() -> Image:
	var im := Image.create(JAW_PX.x, JAW_PX.y, false, Image.FORMAT_RGBA8)
	var jaw := PackedVector2Array([Vector2(0, 3), Vector2(40, 3), Vector2(37, 9), Vector2(29, 14), Vector2(11, 14), Vector2(3, 9)])
	_poly(im, jaw, OBS.darkened(0.2))
	_line(im, Vector2(3, 9), Vector2(11, 14), RIM)
	_line(im, Vector2(37, 9), Vector2(29, 14), RIM)
	for k in 7:                                                  # нижние клыки
		var tx := 8.0 + k * 4.0
		var long := 4.0 if k in [0, 6] else 2.5
		_poly(im, PackedVector2Array([Vector2(tx - 1.5, 4), Vector2(tx + 1.5, 4), Vector2(tx, 4 - long)]), BONE.darkened(0.06))
	_line(im, Vector2(14, 8), Vector2(18, 11), Color(LAVA, 0.8))
	_line(im, Vector2(26, 7), Vector2(23, 11), Color(LAVA, 0.8))
	_outline(im, Color(0.02, 0.01, 0.03))
	return im

# Кисть «смотрит» когтями вниз; большой палец — к середине арены (рисуется
# для руки слева, справа — зеркально)
static func _hand_img(is_fist: bool) -> Image:
	var im := Image.create(HAND_PX.x, HAND_PX.y, false, Image.FORMAT_RGBA8)
	var plate := Color(0.12, 0.10, 0.13)
	# запястье — тает дымом
	for y in range(0, 8):
		for x in range(16, 36):
			if (x + y) % 3 != 0 or y > 3:
				_px(im, x, y, Color(0.07, 0.05, 0.08, 0.35 + y * 0.08))
	# тыльная сторона ладони — латная пластина
	var back := PackedVector2Array([Vector2(14, 6), Vector2(37, 6), Vector2(41, 15), Vector2(40, 22), Vector2(12, 22), Vector2(10, 15)])
	_poly(im, back, plate)
	_line(im, Vector2(14, 6), Vector2(37, 6), RIM.lightened(0.15))
	_line(im, Vector2(10, 15), Vector2(14, 6), RIM)
	for k in 3:                                                   # лавовые жилы
		_line(im, Vector2(18 + k * 7, 8), Vector2(16 + k * 8, 20), Color(LAVA, 0.8))
	_line(im, Vector2(12, 21), Vector2(40, 21), RIM)
	if not is_fist:
		# четыре пальца когтями вниз, чуть веером
		for k in 4:
			var x0 := 13.0 + k * 7.5
			var tilt := (k - 1.5) * 0.9
			var seg := PackedVector2Array([Vector2(x0 - 2.5, 21), Vector2(x0 + 2.5, 21), Vector2(x0 + 2.5 + tilt, 33), Vector2(x0 - 2.5 + tilt, 33)])
			_poly(im, seg, plate.lightened(0.04))
			_line(im, Vector2(x0 - 2.5, 27), Vector2(x0 + 2.5, 27), RIM)             # сустав
			_px(im, int(x0 - 2), 22, RIM.lightened(0.2))
			var tip := PackedVector2Array([Vector2(x0 - 2.5 + tilt, 32), Vector2(x0 + 2.5 + tilt, 32), Vector2(x0 + tilt * 1.6, 40)])
			_poly(im, tip, BONE.darkened(0.2))
			_px(im, int(x0 + tilt * 1.5), 39, Color(1.0, 0.6, 0.3))
		# большой палец — к середине
		_poly(im, PackedVector2Array([Vector2(38, 13), Vector2(42, 16), Vector2(49, 27), Vector2(46, 29), Vector2(38, 21)]), plate.lightened(0.04))
		_poly(im, PackedVector2Array([Vector2(46, 27), Vector2(49, 26), Vector2(50, 33)]), BONE.darkened(0.2))
	else:
		# кулак: костяшки вниз, когти поджаты
		_poly(im, PackedVector2Array([Vector2(10, 20), Vector2(42, 20), Vector2(43, 30), Vector2(39, 35), Vector2(13, 35), Vector2(9, 30)]), plate.lightened(0.03))
		for k in 4:
			var kx := 14.0 + k * 7.5
			_disc(im, kx, 33, 3.2, plate.lightened(0.10))
			_px(im, int(kx) - 1, 32, RIM.lightened(0.3))
			_line(im, Vector2(kx - 2, 26), Vector2(kx + 2, 26), RIM)
		_line(im, Vector2(12, 28), Vector2(40, 28), Color(LAVA, 0.6))
		_poly(im, PackedVector2Array([Vector2(37, 14), Vector2(44, 20), Vector2(42, 27), Vector2(34, 24)]), plate.lightened(0.06))
		for k in 3:                                               # кончики поджатых когтей
			_px(im, 16 + k * 8, 37, BONE.darkened(0.25))
	_outline(im, Color(0.02, 0.01, 0.03))
	return im
