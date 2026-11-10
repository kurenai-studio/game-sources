class_name WildRig
extends Node2D
# ---------- «Модели» тварей Жуткого леса и Болота ----------
#   crow     — ворон: чёрное тело, жёлтый клюв, красный глаз, взмахи крыльев;
#   wisp     — блуждающий огонёк: светящееся ядро, мерцающее пламя-хвост;
#   leech    — пиявка: сегменты, ползёт волной, кольцо-присоска;
#   mosquito — комариный рой: стайка комаров кружит вокруг середины;
#   ice_wraith — ледяной дух (Ледяная тропа), harpy — гарпия, ball_lightning — шаровая
#   молния (Храм шторма), gargoyle — горгулья (Тронный зал), magma_blob — магмовый слизень.
# Рисуются маленькими пиксельными картинками, как и остальные модели.

const KINDS := ["crow", "wisp", "leech", "mosquito", "ice_wraith", "harpy", "ball_lightning", "gargoyle", "magma_blob", "magma_blob_s"]

var bot: Player
var kind := "crow"
var size := Vector2(36, 26)
var puppet_vx := 0.0
var puppet_facing := 1
var px := 2.0

var _art: Node2D
var _body: Node2D
var _parts := {}
var _segs: Array = []
var _bugs: Array = []
var _glow: Polygon2D
var _t := 0.0
var _act := ""
var _act_t := 0.0
var _hurt := 0.0

func _size() -> Vector2:
	return bot.body_size if bot else size

func _vel() -> Vector2:
	return bot.velocity if bot else Vector2(puppet_vx, 0)

func _facing() -> int:
	return bot.facing if bot else puppet_facing

func _ready() -> void:
	scale.x = float(_facing())
	_art = Node2D.new()
	add_child(_art)
	_body = Node2D.new()
	_art.add_child(_body)
	match kind:
		"crow": _build_crow()
		"wisp": _build_wisp()
		"leech": _build_leech()
		"mosquito": _build_mosquito()
		"ice_wraith": _build_ice_wraith()
		"harpy": _build_harpy()
		"ball_lightning": _build_ball_lightning()
		"gargoyle": _build_gargoyle()
		"magma_blob", "magma_blob_s": _build_magma_blob()

func _px(im: Image, x: int, y: int, c: Color) -> void:
	BotRig._px(im, x, y, c)

func _img(w: int, h: int) -> Image:
	return Image.create(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)

func _spr(parent: Node, img: Image, pivot: Vector2, pos: Vector2) -> Sprite2D:
	BotRig._volume(img)
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -pivot
	s.position = pos
	parent.add_child(s)
	return s

# Ворон: 18 × 12 рисунка
func _build_crow() -> void:
	px = _size().x / 18.0
	_art.scale = Vector2(px, px)
	var black := Color(0.13, 0.12, 0.16)
	var wing := _img(10, 6)
	for y in 6:
		for x in 10 - y:
			wing.set_pixel(x, y, black.lightened(0.06 * ((x + y) % 2)))
	_parts["wing_b"] = _spr(_body, wing, Vector2(1, 5), Vector2(-1, -2))
	_parts["wing_b"].modulate = Color(0.7, 0.7, 0.75)
	var body := _img(14, 7)
	BotRig._box(body, 2, 1, 9, 5, black)
	BotRig._box(body, 10, 0, 4, 4, black)                   # голова
	body.fill_rect(Rect2i(0, 2, 3, 2), black.lightened(0.05))   # хвост
	body.set_pixel(12, 1, Color(1.0, 0.2, 0.15))            # глаз
	body.fill_rect(Rect2i(13, 2, 1, 1), Color(0.85, 0.7, 0.2))
	_spr(_body, body, Vector2(7, 3.5), Vector2.ZERO)
	var beak := _img(3, 2)
	beak.fill_rect(Rect2i(0, 0, 3, 1), Color(0.9, 0.75, 0.25))
	beak.set_pixel(0, 1, Color(0.75, 0.6, 0.2))
	_spr(_body, beak, Vector2(0, 0), Vector2(7, -1))
	_parts["wing_f"] = _spr(_body, wing, Vector2(1, 5), Vector2(1, -2))
	# светлая кромка крыла и красный огонёк глаза — чтобы ворона было видно в сумраке
	var rim := _img(10, 1)
	rim.fill_rect(Rect2i(0, 0, 10, 1), Color(0.55, 0.52, 0.68))
	var rs := _spr(_parts["wing_f"], rim, Vector2(0, 0), Vector2(-1, -5))
	rs.modulate.a = 0.8
	var eg := Polygon2D.new()
	eg.polygon = Util.circle(1.6, 8)
	eg.color = Color(1.0, 0.25, 0.2, 0.45)
	eg.position = Vector2(5.5, -2.0)
	_body.add_child(eg)

# Огонёк: ядро и языки пламени (многоугольники) + свечение
func _build_wisp() -> void:
	var r := _size().x * 0.5
	_glow = Polygon2D.new()
	_glow.polygon = Util.circle(r * 1.25, 18)
	_glow.color = Color(0.45, 1.0, 0.7, 0.18)
	_body.add_child(_glow)
	for k in 3:
		var fl := Polygon2D.new()
		fl.polygon = PackedVector2Array([Vector2(-r * 0.5, 0), Vector2(0, -r * (1.6 - k * 0.3)), Vector2(r * 0.5, 0)])
		fl.color = [Color(0.3, 0.9, 0.55, 0.7), Color(0.55, 1.0, 0.75, 0.8), Color(0.85, 1.0, 0.9, 0.9)][k]
		fl.position = Vector2(-r * 0.2 * k, r * 0.2)
		fl.rotation = -0.9                   # пламя тянется назад
		_body.add_child(fl)
		_parts["fl%d" % k] = fl
	var core := Polygon2D.new()
	core.polygon = Util.circle(r * 0.55, 14)
	core.color = Color(0.9, 1.0, 0.92)
	_body.add_child(core)
	for s in [-1, 1]:                        # два тёмных «глаза»
		var e := Polygon2D.new()
		e.polygon = Util.circle(r * 0.1, 6)
		e.color = Color(0.1, 0.3, 0.2)
		e.position = Vector2(r * 0.15 + s * r * 0.18, -r * 0.05)
		_body.add_child(e)

# Пиявка: 6 сегментов, головка с присоской
func _build_leech() -> void:
	px = _size().x / 20.0
	_art.scale = Vector2(px, px)
	_art.position = Vector2(0, _size().y / 2)
	var c := Color(0.30, 0.20, 0.24)
	for k in 6:
		var seg := _img(5, 5)
		BotRig._box(seg, 0, 0, 5, 5, c.lightened(0.05 * (k % 2)))
		seg.set_pixel(2, 1, c.lightened(0.3))
		var sp := _spr(_body, seg, Vector2(2.5, 5), Vector2(-8 + k * 3, 0))
		_segs.append(sp)
	var head := _img(5, 5)
	BotRig._box(head, 0, 0, 5, 5, c.darkened(0.1))
	head.fill_rect(Rect2i(3, 1, 2, 3), Color(0.75, 0.30, 0.35))     # присоска
	_parts["head"] = _spr(_body, head, Vector2(0, 5), Vector2(10, 0))

# Комариный рой: 6 комаров по кругу
func _build_mosquito() -> void:
	px = _size().x / 22.0
	_art.scale = Vector2(px, px)
	for k in 6:
		var m := Node2D.new()
		var body := _img(5, 3)
		body.fill_rect(Rect2i(0, 1, 4, 1), Color(0.25, 0.22, 0.20))
		body.set_pixel(4, 1, Color(0.6, 0.15, 0.15))
		_spr(m, body, Vector2(2.5, 1.5), Vector2.ZERO)
		var wing := _img(3, 2)
		wing.fill_rect(Rect2i(0, 0, 3, 2), Color(0.85, 0.88, 0.95, 0.6))
		var w := _spr(m, wing, Vector2(1.5, 2), Vector2(0, -1))
		_bugs.append({"n": m, "w": w, "a": TAU * k / 6.0, "r": 4.0 + (k % 3) * 2.5})
		_body.add_child(m)

# Ледяной дух: полупрозрачный капюшон из инея, горящие голубые глаза, хвост-позёмка
func _build_ice_wraith() -> void:
	var r := _size().x * 0.5
	_glow = Polygon2D.new()
	_glow.polygon = Util.circle(r * 1.3, 18)
	_glow.color = Color(0.55, 0.85, 1.0, 0.16)
	_body.add_child(_glow)
	for k in 3:                                       # хвост-позёмка
		var tl := Polygon2D.new()
		tl.polygon = PackedVector2Array([Vector2(-r * 0.55, 0), Vector2(-r * 0.15, r * (1.5 - k * 0.3)), Vector2(r * 0.45, 0)])
		tl.color = [Color(0.55, 0.80, 1.0, 0.45), Color(0.70, 0.90, 1.0, 0.55), Color(0.88, 0.97, 1.0, 0.6)][k]
		tl.position = Vector2(-r * 0.15 * k, r * 0.3)
		tl.rotation = 0.5
		_body.add_child(tl)
		_parts["tl%d" % k] = tl
	var hood := Polygon2D.new()
	hood.polygon = PackedVector2Array([Vector2(-r * 0.7, r * 0.4), Vector2(-r * 0.6, -r * 0.5), Vector2(0, -r * 1.05), Vector2(r * 0.6, -r * 0.55),
			Vector2(r * 0.75, r * 0.4), Vector2(r * 0.3, r * 0.2), Vector2(0, r * 0.45), Vector2(-r * 0.3, r * 0.2)])
	hood.color = Color(0.72, 0.88, 1.0, 0.85)
	_body.add_child(hood)
	var face := Polygon2D.new()
	face.polygon = Util.circle(r * 0.38, 12)
	face.color = Color(0.08, 0.12, 0.22, 0.95)
	face.position = Vector2(r * 0.12, -r * 0.15)
	_body.add_child(face)
	for s in [-1, 1]:
		var e := Polygon2D.new()
		e.polygon = Util.circle(r * 0.09, 6)
		e.color = Color(0.6, 0.95, 1.0)
		e.position = Vector2(r * 0.18 + s * r * 0.14, -r * 0.18)
		_body.add_child(e)
	for k in 3:                                       # ледяные осколки кружат вокруг
		var sh := Polygon2D.new()
		sh.polygon = PackedVector2Array([Vector2(-2, 0), Vector2(0, -6), Vector2(2, 0), Vector2(0, 3)])
		sh.color = Color(0.85, 0.96, 1.0)
		_body.add_child(sh)
		_bugs.append({"n": sh, "a": TAU * k / 3.0, "r": r * 1.05})

# Гарпия: два больших крыла от плеч назад-вверх, тело в перьях, бледное лицо, когти
func _build_harpy() -> void:
	px = _size().x / 26.0
	_art.scale = Vector2(px, px)
	var feather := Color(0.42, 0.48, 0.62)
	var wing := _wing_img(feather, false)
	_parts["wing_b"] = _spr(_body, wing, Vector2(15, 9), Vector2(-1, -3))
	_parts["wing_b"].modulate = Color(0.68, 0.68, 0.76)
	var body := _img(12, 15)
	BotRig._box(body, 3, 5, 7, 6, feather.darkened(0.08))                 # тело в перьях
	body.fill_rect(Rect2i(5, 7, 4, 3), Color(0.82, 0.74, 0.64))           # светлая грудка
	BotRig._box(body, 5, 0, 6, 5, Color(0.86, 0.76, 0.68))                 # голова
	body.fill_rect(Rect2i(3, 0, 4, 2), Color(0.20, 0.17, 0.26))           # волосы
	body.fill_rect(Rect2i(2, 1, 3, 6), Color(0.20, 0.17, 0.26))
	_px(body, 1, 6, Color(0.20, 0.17, 0.26))
	body.fill_rect(Rect2i(8, 2, 2, 1), Color(1.0, 0.85, 0.2))             # глаза
	_px(body, 10, 4, Color(0.55, 0.30, 0.25))                             # рот
	body.fill_rect(Rect2i(4, 11, 2, 2), feather.darkened(0.2))            # ноги
	body.fill_rect(Rect2i(7, 11, 2, 2), feather.darkened(0.2))
	for x in [3, 5, 7, 9]:                                                # когти
		_px(body, x, 13, Color(0.85, 0.75, 0.35))
		_px(body, x, 14, Color(0.70, 0.60, 0.30))
	_spr(_body, body, Vector2(6, 7), Vector2.ZERO)
	_parts["wing_f"] = _spr(_body, wing, Vector2(15, 9), Vector2(1, -3))

# Крыло: от плеча (правый нижний угол картинки) назад-вверх, к краю — перья лесенкой.
# membrane = true — перепончатое (горгулья): тонкие косточки и перепонка между ними
func _wing_img(c: Color, membrane: bool) -> Image:
	var im := _img(16, 10)
	for x in 16:
		var lead := int(round(9.0 * x / 15.0))                     # передний край крыла
		var length := 2 + int(5.0 * (1.0 - absf(x - 6.0) / 9.0))
		if membrane:
			length = 1 + int(6.0 * (1.0 - absf(x - 7.0) / 9.0))
			if x % 5 == 4:
				length -= 2                                       # вырез между косточками
		for y in range(lead, mini(10, lead + maxi(1, length))):
			var col := c.lightened(0.08 * ((x + y) % 3)) if not membrane else c.darkened(0.1 + 0.05 * (y - lead))
			im.set_pixel(x, y, col)
		im.set_pixel(x, lead, c.darkened(0.3) if membrane else c.lightened(0.2))   # кромка / косточка
		if not membrane and x % 2 == 0 and lead + length < 10:
			im.set_pixel(x, lead + length, c.darkened(0.25))                       # кончики перьев
	return im

# Шаровая молния: яркое ядро, ореол и пляшущие разряды
func _build_ball_lightning() -> void:
	var r := _size().x * 0.5
	_glow = Polygon2D.new()
	_glow.polygon = Util.circle(r * 1.4, 18)
	_glow.color = Color(0.55, 0.75, 1.0, 0.22)
	_body.add_child(_glow)
	var shell := Polygon2D.new()
	shell.polygon = Util.circle(r * 0.85, 16)
	shell.color = Color(0.65, 0.82, 1.0, 0.55)
	_body.add_child(shell)
	var core := Polygon2D.new()
	core.polygon = Util.circle(r * 0.45, 12)
	core.color = Color(0.95, 0.98, 1.0)
	_body.add_child(core)
	for k in 4:
		var l := Line2D.new()
		l.width = 2.0
		l.default_color = Color(0.85, 0.92, 1.0)
		_body.add_child(l)
		_segs.append(l)

# Горгулья: каменный бес с рожками, когтями и перепончатыми крыльями
func _build_gargoyle() -> void:
	px = _size().x / 26.0
	_art.scale = Vector2(px, px)
	var stone := Color(0.44, 0.42, 0.47)
	var wing := _wing_img(stone.darkened(0.1), true)
	_parts["wing_b"] = _spr(_body, wing, Vector2(15, 9), Vector2(-1, -4))
	_parts["wing_b"].modulate = Color(0.7, 0.7, 0.76)
	var body := _img(13, 15)
	BotRig._box(body, 2, 5, 8, 6, stone)                                   # туловище
	body.fill_rect(Rect2i(4, 6, 4, 1), stone.darkened(0.2))               # рёбра
	body.fill_rect(Rect2i(4, 8, 4, 1), stone.darkened(0.2))
	BotRig._box(body, 5, 0, 7, 6, stone.lightened(0.06))                  # голова
	for k in 3:                                                           # рожки
		_px(body, 5 - k / 2, 0 - 0 + k / 3, stone.lightened(0.3))
	_px(body, 4, 0, stone.lightened(0.3))
	_px(body, 11, 0, stone.lightened(0.3))
	body.fill_rect(Rect2i(9, 2, 2, 1), Color(1.0, 0.35, 0.12))            # глаза
	body.fill_rect(Rect2i(8, 4, 4, 1), Color(0.95, 0.92, 0.85))           # клыки
	body.fill_rect(Rect2i(0, 9, 3, 1), stone.darkened(0.15))              # хвост
	_px(body, 0, 8, stone.darkened(0.15))
	body.fill_rect(Rect2i(3, 11, 2, 3), stone.darkened(0.12))             # лапы
	body.fill_rect(Rect2i(7, 11, 2, 3), stone.darkened(0.12))
	for x in [2, 4, 6, 8]:
		_px(body, x, 14, Color(0.25, 0.24, 0.26))
	_spr(_body, body, Vector2(6, 7), Vector2.ZERO)
	_parts["wing_f"] = _spr(_body, wing, Vector2(15, 9), Vector2(1, -4))
	var eg := Polygon2D.new()
	eg.polygon = Util.circle(1.4, 8)
	eg.color = Color(1.0, 0.35, 0.15, 0.5)
	eg.position = Vector2(3.5, -5.0)
	_body.add_child(eg)

# Магмовый слизень: капля лавы с тёмной коркой, внутри булькает
func _build_magma_blob() -> void:
	var r := _size().x * 0.5
	var hh := _size().y
	_glow = Polygon2D.new()
	_glow.polygon = Util.circle(r * 1.2, 16)
	_glow.color = Color(1.0, 0.5, 0.15, 0.15)
	_glow.position = Vector2(0, hh * 0.15)
	_body.add_child(_glow)
	var blob := Polygon2D.new()
	var pts := PackedVector2Array()
	for i in 17:
		var a := PI + PI * i / 16.0
		pts.append(Vector2(cos(a) * r, sin(a) * hh * 0.95 + hh * 0.5))
	blob.polygon = pts
	blob.color = Color(0.95, 0.40, 0.10)
	_body.add_child(blob)
	_parts["blob"] = blob
	var crust := Polygon2D.new()
	crust.polygon = PackedVector2Array([Vector2(-r * 0.7, -hh * 0.2), Vector2(-r * 0.2, -hh * 0.42), Vector2(r * 0.3, -hh * 0.4), Vector2(r * 0.1, -hh * 0.25),
			Vector2(-r * 0.4, -hh * 0.15)])
	crust.color = Color(0.22, 0.10, 0.07)
	_body.add_child(crust)
	var hot := Polygon2D.new()
	hot.polygon = Util.circle(r * 0.35, 10)
	hot.color = Color(1.0, 0.8, 0.35)
	hot.position = Vector2(-r * 0.1, hh * 0.12)
	_body.add_child(hot)
	_parts["hot"] = hot
	for s in [-1, 1]:
		var e := Polygon2D.new()
		e.polygon = Util.circle(maxf(2.0, r * 0.1), 6)
		e.color = Color(0.15, 0.05, 0.02)
		e.position = Vector2(r * 0.35 + s * r * 0.18, -hh * 0.05)
		_body.add_child(e)

func play(n: String) -> void:
	_act = n
	_act_t = 0.0

func hurt() -> void:
	_hurt = 0.12

func muzzle() -> Vector2:
	return global_position

func _process(delta: float) -> void:
	if bot != null and not is_instance_valid(bot):
		return
	_t += delta
	_hurt = maxf(0.0, _hurt - delta)
	modulate = Color(1.0, 0.55, 0.55) if _hurt > 0.0 else Color.WHITE
	scale.x = move_toward(scale.x, float(_facing()), delta * 10.0)
	if absf(scale.x) < 0.15:
		scale.x = 0.15 * float(_facing())
	var v := _vel()
	match kind:
		"crow":
			var flap := sin(_t * 16.0) * 0.9
			_parts["wing_f"].rotation = -flap
			_parts["wing_b"].rotation = flap * 0.8
			_body.position.y = sin(_t * 16.0) * 0.5
			_body.rotation = clampf(v.y / 900.0, -0.5, 0.5)
		"wisp":
			_body.position.y = sin(_t * 2.5) * 3.0
			for k in 3:
				var fl: Polygon2D = _parts["fl%d" % k]
				fl.scale = Vector2(1.0, 1.0 + 0.25 * sin(_t * (9.0 + k * 3.0)))
			_glow.scale = Vector2.ONE * (1.0 + 0.15 * sin(_t * 5.0))
		"leech":
			var spd := absf(v.x)
			for k in _segs.size():
				var sp: Sprite2D = _segs[k]
				sp.position.y = -absf(sin(_t * (4.0 + spd * 0.02) - k * 0.7)) * 1.6
			_parts["head"].position.y = -absf(sin(_t * 4.0 + 0.7)) * 1.6
		"ice_wraith":
			_body.position.y = sin(_t * 2.2) * 3.0
			for k in 3:
				var tl: Polygon2D = _parts["tl%d" % k]
				tl.scale = Vector2(1.0, 1.0 + 0.3 * sin(_t * (7.0 + k * 2.0)))
			for b in _bugs:
				var a2: float = b["a"] + _t * 2.5
				(b["n"] as Node2D).position = Vector2(cos(a2) * b["r"], sin(a2) * b["r"] * 0.5)
				(b["n"] as Node2D).rotation = a2
			_glow.scale = Vector2.ONE * (1.0 + 0.12 * sin(_t * 4.0))
		"harpy", "gargoyle":
			var fast := 13.0 if kind == "harpy" else 8.0
			var flap := sin(_t * fast) * 0.55
			if kind == "gargoyle" and bot and bot.has_meta("stone"):
				flap = 0.75                                      # окаменела: крылья сложены
			_parts["wing_f"].rotation = flap - 0.1
			_parts["wing_b"].rotation = flap * 0.8 - 0.25
			_body.position.y = sin(_t * fast) * 0.5
			_body.rotation = clampf(v.y / 900.0, -0.5, 0.5)
		"ball_lightning":
			_body.position.y = sin(_t * 3.0) * 2.5
			_glow.scale = Vector2.ONE * (1.0 + 0.2 * sin(_t * 17.0))
			if fmod(_t, 0.08) < 0.02:
				var r := _size().x * 0.5
				for l in _segs:
					var pts := PackedVector2Array([Vector2.ZERO])
					var q := Vector2.ZERO
					var a := randf() * TAU
					for k in 4:
						q += Vector2.from_angle(a + randf_range(-0.9, 0.9)) * r * 0.4
						pts.append(q)
					(l as Line2D).points = pts
		"magma_blob", "magma_blob_s":
			var spd := absf(v.x)
			var sq := 0.08 * sin(_t * (6.0 + spd * 0.02))
			_body.scale = Vector2(1.0 + sq, 1.0 - sq)
			_parts["hot"].scale = Vector2.ONE * (0.8 + 0.3 * absf(sin(_t * 3.0)))
			_glow.scale = Vector2.ONE * (1.0 + 0.1 * sin(_t * 5.0))
		"mosquito":
			for b in _bugs:
				var a: float = b["a"] + _t * (5.0 + b["r"] * 0.3)
				(b["n"] as Node2D).position = Vector2(cos(a) * b["r"] * 1.6, sin(a * 1.3) * b["r"])
				(b["w"] as Sprite2D).scale.y = 0.4 + absf(sin(_t * 40.0 + a))
