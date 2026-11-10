class_name CreatureRig
extends Node2D
# Модели зверей и чудищ из отдельных частей (как BotRig у людей):
#   lion         — лев арены: туловище, голова с гривой, четыре лапы, хвост;
#   spider       — паук: голова-грудь, брюшко, восемь ног;
#   spider_queen — Паучья королева (мини-босс): крупнее, корона из шипов, яйца на брюшке;
#   bat          — летучая мышь: тельце, голова с ушами, два крыла.
# API тот же, что у BotRig: play(), hurt(), muzzle().

const DARK := Color(0.12, 0.1, 0.1)
const KINDS := ["lion", "spider", "spider_queen", "bat", "snow_wolf", "salamander", "cerberus"]
const QUADS := ["lion", "snow_wolf", "salamander", "cerberus"]      # четвероногие: лапы шагают широко

var bot: Player
var kind := "lion"
var size := Vector2(60, 40)
var puppet_vx := 0.0
var puppet_facing := 1
var px := 2.0

var _art: Node2D
var _body: Node2D             # всё, что качается вместе с туловищем
var _head: Sprite2D
var _tail: Sprite2D
var _legs: Array = []         # [{"s": Sprite2D, "front": bool, "phase": float}]
var _wing_f: Sprite2D
var _wing_b: Sprite2D
var _heads: Array = []        # у Цербера три головы: [{"s": Sprite2D, "base": Vector2, "ph": float}]
var _glows: Array = []
var _t := 0.0
var _phase := 0.0
var _act := ""
var _act_t := 0.0
var _act_len := 0.3
var _hurt := 0.0

func _size() -> Vector2:
	return bot.body_size if bot else size

func _vel() -> Vector2:
	return bot.velocity if bot else Vector2(puppet_vx, 0)

func _floor() -> bool:
	return bot.is_on_floor() if bot else true

func _facing() -> int:
	return bot.facing if bot else puppet_facing

func _ready() -> void:
	scale.x = float(_facing())
	_art = Node2D.new()
	add_child(_art)
	_body = Node2D.new()
	_art.add_child(_body)
	match kind:
		"lion": _build_lion()
		"spider", "spider_queen": _build_spider()
		"bat": _build_bat()
		"snow_wolf": _build_wolf()
		"salamander": _build_salamander()
		"cerberus": _build_cerberus()

# ---------- Рисование ----------
func _img(w: int, h: int) -> Image:
	return Image.create(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)

func _box(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	BotRig._box(im, x, y, w, h, c)

func _px(im: Image, x: int, y: int, c: Color) -> void:
	BotRig._px(im, x, y, c)

func _sprite(parent: Node, img: Image, pivot: Vector2, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -pivot
	s.position = pos
	parent.add_child(s)
	return s

# Лев: рисунок 34 × 20 «пикселей»
func _build_lion() -> void:
	px = _size().x / 34.0
	_art.scale = Vector2(px, px)
	_art.position = Vector2(0, _size().y / 2)
	var fur := Color(0.82, 0.60, 0.30)
	var mane := Color(0.55, 0.30, 0.14)
	var leg := _img(4, 9)
	_box(leg, 0, 0, 4, 9, fur.darkened(0.05))
	leg.fill_rect(Rect2i(0, 7, 4, 2), fur.darkened(0.3))
	for x in [-9.0, 7.0]:          # дальние лапы
		var l := _sprite(_art, leg, Vector2(2, 0), Vector2(x - 1, -9))
		l.modulate = Color(0.75, 0.75, 0.8)
		_legs.append({"s": l, "front": x > 0, "phase": PI})
	_art.move_child(_body, _art.get_child_count() - 1)
	var tail := _img(13, 4)
	tail.fill_rect(Rect2i(3, 1, 10, 2), fur)
	BotRig._box(tail, 0, 0, 4, 4, mane)
	_tail = _sprite(_body, tail, Vector2(12, 2), Vector2(-12, -15))
	var torso := _img(24, 10)
	_box(torso, 0, 0, 24, 10, fur)
	torso.fill_rect(Rect2i(2, 7, 20, 2), fur.lightened(0.15))
	_sprite(_body, torso, Vector2(12, 10), Vector2(0, -8))
	for x in [-9.0, 7.0]:          # ближние лапы
		var l := _sprite(_art, leg, Vector2(2, 0), Vector2(x + 1, -9))
		_legs.append({"s": l, "front": x > 0, "phase": 0.0})
	var head := _img(16, 15)
	for y in 15:                    # грива — круг
		var hw := int(7.5 * sin(PI * (y + 0.5) / 15.0)) + 1
		head.fill_rect(Rect2i(8 - hw, y, hw * 2, 1), mane)
	_box(head, 6, 3, 9, 9, fur)
	head.fill_rect(Rect2i(12, 5, 2, 2), DARK)          # глаз
	head.fill_rect(Rect2i(13, 9, 3, 2), Color(0.35, 0.2, 0.15))   # нос
	head.fill_rect(Rect2i(10, 11, 5, 1), Color(0.95, 0.92, 0.85)) # клыки
	_head = _sprite(_body, head, Vector2(6, 12), Vector2(10, -11))

# Паук и Паучья королева
func _build_spider() -> void:
	var queen := kind == "spider_queen"
	var w := 30.0 if queen else 24.0
	px = _size().x / w
	_art.scale = Vector2(px, px)
	_art.position = Vector2(0, _size().y / 2)
	var shell := Color(0.22, 0.18, 0.22) if not queen else Color(0.28, 0.12, 0.22)
	var leg := _img(13, 13)
	for i in 6:                      # бедро: вверх-наружу
		leg.fill_rect(Rect2i(1 + i, 7 - i, 1, 2), shell.lightened(0.15))
	for i in 6:                      # голень: вниз к земле
		leg.fill_rect(Rect2i(7 + i / 2 * 1 + (i % 2), 2 + i * 2, 1, 2), shell.lightened(0.1))
	_px(leg, 12, 12, shell.lightened(0.3))
	var attach_y := -6.0 if not queen else -8.0
	# дальние ноги (темнее), потом тело, потом ближние
	for k in 4:
		var front := k >= 2
		var l := _sprite(_art, leg, Vector2(1, 7), Vector2(-2 + k * 2, attach_y))
		l.scale = Vector2(1 if front else -1, 1) * (1.25 if queen else 1.0)
		l.modulate = Color(0.65, 0.65, 0.7)
		_legs.append({"s": l, "front": front, "phase": PI * (k % 2) + 0.5, "base": (0.15 + 0.25 * (k % 2)) * (1 if front else -1)})
	_art.move_child(_body, _art.get_child_count() - 1)
	var ab := _img(14 if queen else 11, 11 if queen else 9)
	_box(ab, 0, 0, ab.get_width(), ab.get_height(), shell)
	if queen:                        # узор и мешок с яйцами
		for i in 5:
			_px(ab, 2 + i * 2, 3 + (i % 2), Color(0.85, 0.2, 0.25))
		BotRig._box(ab, 2, ab.get_height() - 4, 6, 4, Color(0.92, 0.9, 0.82))
	else:
		ab.fill_rect(Rect2i(3, 3, 4, 1), Color(0.75, 0.2, 0.2))
	_tail = _sprite(_body, ab, Vector2(ab.get_width(), ab.get_height() / 2.0), Vector2(-2, attach_y - 2))
	var head := _img(10 if queen else 8, 9 if queen else 6)
	_box(head, 0, 1 if queen else 0, head.get_width(), head.get_height() - (1 if queen else 0), shell.lightened(0.05))
	var eye := Color(1.0, 0.2, 0.2) if queen else Color(0.9, 0.3, 0.3)
	for e in [[head.get_width() - 3, 2], [head.get_width() - 5, 2], [head.get_width() - 2, 4]]:
		_px(head, e[0], e[1] + (1 if queen else 0), eye)
	if queen:                        # корона из шипов
		for x in [1, 4, 7]:
			head.fill_rect(Rect2i(x, 0, 1, 2), Color(0.9, 0.75, 0.3))
	head.fill_rect(Rect2i(head.get_width() - 2, head.get_height() - 2, 2, 2), Color(0.8, 0.75, 0.6))  # жвалы
	_head = _sprite(_body, head, Vector2(0, head.get_height() / 2.0), Vector2(1, attach_y - 1))
	for k in 4:
		var front := k >= 2
		var l := _sprite(_art, leg, Vector2(1, 7), Vector2(-3 + k * 2, attach_y + 0.5))
		l.scale = Vector2(1 if front else -1, 1) * (1.25 if queen else 1.0)
		_legs.append({"s": l, "front": front, "phase": PI * ((k + 1) % 2) + 0.5, "base": (0.05 + 0.25 * (k % 2)) * (1 if front else -1)})

# Летучая мышь
func _build_bat() -> void:
	px = _size().x / 22.0
	_art.scale = Vector2(px, px)
	_art.position = Vector2(0, 0)
	var fur := Color(0.30, 0.22, 0.24)
	var wing := _img(11, 8)
	for i in 11:
		var hh := 7 - int(absf(sin(i * 0.6)) * 3.0)
		wing.fill_rect(Rect2i(i, 0, 1, hh), Color(0.38, 0.26, 0.30))
	wing.fill_rect(Rect2i(0, 0, 11, 1), Color(0.2, 0.14, 0.16))
	_wing_b = _sprite(_body, wing, Vector2(0, 0), Vector2(-1, -2))
	_wing_b.scale.x = -1
	_wing_b.modulate = Color(0.7, 0.7, 0.75)
	var body := _img(7, 8)
	_box(body, 0, 0, 7, 8, fur)
	_sprite(_body, body, Vector2(3.5, 4), Vector2(0, 0))
	var head := _img(7, 7)
	_box(head, 0, 2, 7, 5, fur.lightened(0.05))
	head.fill_rect(Rect2i(0, 0, 2, 3), fur)
	head.fill_rect(Rect2i(5, 0, 2, 3), fur)
	_px(head, 4, 4, Color(1.0, 0.25, 0.2))
	_px(head, 6, 4, Color(1.0, 0.25, 0.2))
	_px(head, 5, 6, Color(0.95, 0.95, 0.9))
	_head = _sprite(_body, head, Vector2(3.5, 6), Vector2(1, -3))
	_wing_f = _sprite(_body, wing, Vector2(0, 0), Vector2(1, -2))

# Снежный волк: рисунок 34 × 20, серебристая шерсть, острые уши, пушистый хвост
func _build_wolf() -> void:
	px = _size().x / 34.0
	_art.scale = Vector2(px, px)
	_art.position = Vector2(0, _size().y / 2)
	var fur := Color(0.80, 0.84, 0.92)
	var back := Color(0.52, 0.57, 0.68)
	var leg := _img(3, 9)
	_box(leg, 0, 0, 3, 9, fur.darkened(0.08))
	leg.fill_rect(Rect2i(0, 7, 3, 2), back.darkened(0.2))
	for x in [-9.0, 7.0]:
		var l := _sprite(_art, leg, Vector2(1.5, 0), Vector2(x - 1, -9))
		l.modulate = Color(0.75, 0.75, 0.82)
		_legs.append({"s": l, "front": x > 0, "phase": PI})
	_art.move_child(_body, _art.get_child_count() - 1)
	var tail := _img(12, 6)
	for x in 12:
		var hh := 2 + int(2.0 * sin(PI * x / 12.0))
		tail.fill_rect(Rect2i(x, 3 - hh / 2, 1, hh), fur if x > 2 else back)
	tail.fill_rect(Rect2i(9, 2, 3, 2), Color(0.95, 0.97, 1.0))
	_tail = _sprite(_body, tail, Vector2(11, 3), Vector2(-11, -15))
	var torso := _img(24, 10)
	_box(torso, 0, 0, 24, 10, fur)
	torso.fill_rect(Rect2i(1, 1, 22, 3), back)                     # тёмная спина
	torso.fill_rect(Rect2i(3, 8, 18, 1), fur.lightened(0.1))
	for k in 4:
		_px(torso, 4 + k * 5, 4, back.lightened(0.1))
	_sprite(_body, torso, Vector2(12, 10), Vector2(0, -8))
	for x in [-9.0, 7.0]:
		var l := _sprite(_art, leg, Vector2(1.5, 0), Vector2(x + 1, -9))
		_legs.append({"s": l, "front": x > 0, "phase": 0.0})
	var head := _img(15, 11)
	_box(head, 2, 3, 8, 7, fur)
	head.fill_rect(Rect2i(2, 3, 8, 2), back)
	_box(head, 9, 5, 6, 4, fur.lightened(0.05))                     # морда
	head.fill_rect(Rect2i(13, 5, 2, 1), DARK)                      # нос
	head.fill_rect(Rect2i(10, 8, 4, 1), Color(0.95, 0.95, 0.95))   # клыки
	for ex in [3, 6]:                                              # уши
		head.fill_rect(Rect2i(ex, 0, 2, 3), back)
		_px(head, ex, 0, back.darkened(0.2))
	head.fill_rect(Rect2i(8, 5, 2, 1), Color(0.45, 0.85, 1.0))     # ледяной глаз
	_head = _sprite(_body, head, Vector2(4, 9), Vector2(10, -11))
	var eg := Polygon2D.new()
	eg.polygon = Util.circle(1.4, 8)
	eg.color = Color(0.5, 0.9, 1.0, 0.5)
	eg.position = Vector2(5, -4.5)
	_head.add_child(eg)

# Саламандра: длинное низкое тело, короткие лапы, хвост, гребень из огоньков
func _build_salamander() -> void:
	px = _size().x / 40.0
	_art.scale = Vector2(px, px)
	_art.position = Vector2(0, _size().y / 2)
	var skin := Color(0.88, 0.36, 0.14)
	var spot := Color(0.18, 0.08, 0.06)
	var leg := _img(3, 5)
	_box(leg, 0, 0, 3, 5, skin.darkened(0.15))
	leg.fill_rect(Rect2i(0, 4, 3, 1), spot)
	for x in [-8.0, 9.0]:
		var l := _sprite(_art, leg, Vector2(1.5, 0), Vector2(x - 1, -5))
		l.modulate = Color(0.75, 0.7, 0.7)
		_legs.append({"s": l, "front": x > 0, "phase": PI})
	_art.move_child(_body, _art.get_child_count() - 1)
	var tail := _img(18, 5)
	for x in 18:
		var hh := 1 + int(3.0 * float(x) / 18.0)
		tail.fill_rect(Rect2i(x, 4 - hh, 1, hh), skin.darkened(0.05) if x % 4 else spot)
	_tail = _sprite(_body, tail, Vector2(17, 3), Vector2(-11, -6))
	var torso := _img(24, 7)
	_box(torso, 0, 0, 24, 7, skin)
	torso.fill_rect(Rect2i(1, 5, 22, 1), Color(1.0, 0.75, 0.35))   # светлое брюхо
	for k in 6:
		torso.fill_rect(Rect2i(2 + k * 4, 2 + k % 2, 2, 1), spot)
	_sprite(_body, torso, Vector2(12, 7), Vector2(0, -4))
	for k in 6:                                                     # гребень из огоньков
		var f := Polygon2D.new()
		f.polygon = PackedVector2Array([Vector2(-1.2, 0), Vector2(0, -3.0 - (k % 2)), Vector2(1.2, 0)])
		f.color = Color(1.0, 0.75, 0.2)
		f.position = Vector2(-9 + k * 3.6, -11)
		_body.add_child(f)
		_glows.append(f)
	for x in [-8.0, 9.0]:
		var l := _sprite(_art, leg, Vector2(1.5, 0), Vector2(x + 1, -5))
		_legs.append({"s": l, "front": x > 0, "phase": 0.0})
	var head := _img(11, 6)
	_box(head, 0, 0, 11, 6, skin.lightened(0.05))
	head.fill_rect(Rect2i(6, 1, 2, 2), Color(1.0, 0.9, 0.3))       # жёлтый глаз
	_px(head, 7, 2, DARK)
	head.fill_rect(Rect2i(4, 4, 7, 1), spot)                        # пасть
	_head = _sprite(_body, head, Vector2(1, 4), Vector2(11, -7))

# Цербер: три головы, огненная грива, ошейники с шипами, лавовые трещины на шкуре
func _build_cerberus() -> void:
	px = _size().x / 44.0
	_art.scale = Vector2(px, px)
	_art.position = Vector2(0, _size().y / 2)
	var hide := Color(0.20, 0.12, 0.12)
	var lava := Color(1.0, 0.45, 0.12)
	var leg := _img(6, 13)
	_box(leg, 0, 0, 6, 13, hide.lightened(0.04))
	leg.fill_rect(Rect2i(0, 11, 6, 2), hide.darkened(0.3))
	for k in 3:
		_px(leg, 1 + k * 2, 12, Color(0.85, 0.8, 0.7))                 # когти
	_px(leg, 2, 4, lava)
	_px(leg, 3, 5, lava)
	for x in [-11.0, 10.0]:
		var l := _sprite(_art, leg, Vector2(3, 0), Vector2(x - 1, -13))
		l.modulate = Color(0.7, 0.65, 0.65)
		_legs.append({"s": l, "front": x > 0, "phase": PI})
	_art.move_child(_body, _art.get_child_count() - 1)
	var tail := _img(14, 7)
	tail.fill_rect(Rect2i(3, 3, 11, 2), hide)
	tail.fill_rect(Rect2i(0, 1, 4, 5), lava)                           # огненный кончик
	tail.fill_rect(Rect2i(1, 2, 2, 3), Color(1.0, 0.85, 0.4))
	_tail = _sprite(_body, tail, Vector2(13, 4), Vector2(-15, -21))
	var torso := _img(30, 14)
	_box(torso, 0, 0, 30, 14, hide)
	torso.fill_rect(Rect2i(2, 11, 26, 2), hide.lightened(0.08))
	var q := Vector2i(3, 3)
	for i in 18:                                                       # лавовые трещины
		_px(torso, q.x, q.y, lava)
		q += Vector2i(1 + (i % 2), (1 if i % 3 == 0 else (-1 if i % 3 == 1 else 0)))
		q.y = clampi(q.y, 2, 10)
	for k in 6:                                                        # рёбра-шипы на хребте
		torso.fill_rect(Rect2i(4 + k * 4, 0, 2, 1), hide.lightened(0.2))
	_sprite(_body, torso, Vector2(15, 14), Vector2(-1, -12))
	for k in 7:                                                        # огненная грива на загривке
		var f := Polygon2D.new()
		f.polygon = PackedVector2Array([Vector2(-1.6, 0), Vector2(0, -5.0 - (k % 3)), Vector2(1.6, 0)])
		f.color = Color(1.0, 0.55 + 0.1 * (k % 2), 0.15)
		f.position = Vector2(4 + k * 1.7, -25 + absf(k - 3) * 0.6)
		_body.add_child(f)
		_glows.append(f)
	for x in [-11.0, 10.0]:
		var l := _sprite(_art, leg, Vector2(3, 0), Vector2(x + 1, -13))
		_legs.append({"s": l, "front": x > 0, "phase": 0.0})
	# три головы: дальняя (выше и темнее), средняя и ближняя
	var spots := [Vector2(10, -29), Vector2(15, -24), Vector2(14, -17)]
	for i in 3:
		var head := _img(14, 11)
		_box(head, 1, 1, 9, 8, hide.lightened(0.04))
		_box(head, 8, 4, 6, 5, hide.lightened(0.08))                   # морда
		head.fill_rect(Rect2i(9, 8, 5, 2), Color(0.45, 0.08, 0.06))    # раскрытая пасть
		head.fill_rect(Rect2i(9, 8, 5, 1), Color(0.95, 0.92, 0.85))    # клыки
		head.fill_rect(Rect2i(6, 3, 2, 2), Color(1.0, 0.75, 0.2))      # огненный глаз
		head.fill_rect(Rect2i(2, 0, 2, 2), hide.darkened(0.2))         # ухо
		head.fill_rect(Rect2i(0, 6, 3, 2), Color(0.45, 0.42, 0.45))     # ошейник
		_px(head, 0, 5, Color(0.75, 0.72, 0.75))
		var hs := _sprite(_body, head, Vector2(3, 8), spots[i])
		if i == 0:
			hs.modulate = Color(0.75, 0.7, 0.7)
			_body.move_child(hs, 0)
		_heads.append({"s": hs, "base": spots[i], "ph": i * 1.3})
		var eg := Polygon2D.new()
		eg.polygon = Util.circle(1.6, 8)
		eg.color = Color(1.0, 0.6, 0.2, 0.55)
		eg.position = Vector2(4, -4)
		hs.add_child(eg)
	_head = _heads[2]["s"]

# Точки пастей Цербера (для огненного дыхания)
func head_points() -> Array:
	var res: Array = []
	for h in _heads:
		var s: Sprite2D = h["s"]
		res.append(s.to_global(Vector2(9, 1)))
	if res.is_empty() and _head:
		res.append(_head.global_position)
	return res

# ---------- Анимации ----------
func play(n: String) -> void:
	_act = n
	_act_t = 0.0
	_act_len = {"pounce": 0.6, "roar": 0.9, "summon": 0.8, "throw": 0.35, "spit": 0.35, "punch": 0.3, "breath": 1.0}.get(n, 0.3)

func hurt() -> void:
	_hurt = 0.12

func muzzle() -> Vector2:
	if _head:
		return _head.global_position
	return global_position

func _process(delta: float) -> void:
	if bot != null and not is_instance_valid(bot):
		return
	_t += delta
	_hurt = maxf(0.0, _hurt - delta)
	modulate = Color(1.0, 0.55, 0.55) if _hurt > 0.0 else Color.WHITE
	scale.x = move_toward(scale.x, float(_facing()), delta * 14.0)
	if absf(scale.x) < 0.15:
		scale.x = 0.15 * (signf(scale.x) if scale.x != 0.0 else float(_facing()))
	if _act != "":
		_act_t += delta
		if _act_t >= _act_len:
			_act = ""
	var p := clampf(_act_t / _act_len, 0.0, 1.0) if _act != "" else 0.0
	var v := _vel()
	var spd := absf(v.x)
	var moving := spd > 15.0 and _floor()
	if moving:
		_phase += delta * spd / (6.0 * px)
	if kind == "bat":
		var flap := sin(_t * 20.0) * 0.9
		if _act == "punch":
			flap = -0.9
		_wing_f.rotation = -flap
		_wing_b.rotation = flap
		_body.position.y = sin(_t * 20.0) * 0.8
		_body.rotation = clampf(v.x / 900.0, -0.3, 0.3) * signf(scale.x)
		return
	var bob := -absf(sin(_phase)) * 0.6 if moving else sin(_t * 2.2) * 0.3
	var body_rot := 0.0
	var head_rot := sin(_t * 1.5) * 0.04
	var head_off := Vector2.ZERO
	var crouch := 0.0
	var stretch := 0.0
	if not _floor():
		stretch = 1.0
	match _act:
		"pounce":
			if p < 0.45:
				crouch = minf(1.0, p / 0.2)
			else:
				stretch = 1.0
		"punch":                    # укус: голова бросается вперёд
			head_off.x = 3.0 * sin(PI * p)
			head_rot = 0.15 * sin(PI * p)
		"roar", "summon":
			body_rot = -0.25 * sin(PI * p)
			head_rot = -0.35 * sin(PI * p)
		"spit", "throw", "breath":
			head_off.x = -1.5 * sin(PI * p)
			body_rot = -0.08 * sin(PI * p)
	_body.position.y = lerpf(_body.position.y, bob + crouch * 2.5, minf(1.0, 20.0 * delta))
	_body.rotation = lerp_angle(_body.rotation, body_rot - stretch * 0.12, minf(1.0, 14.0 * delta))
	if _head and _heads.is_empty():
		_head.rotation = lerp_angle(_head.rotation, head_rot, minf(1.0, 18.0 * delta))
		_head.position.x = lerpf(_head.position.x, _head_base().x + head_off.x, minf(1.0, 25.0 * delta))
	if _tail:
		_tail.rotation = sin(_t * (3.0 if kind in QUADS else 1.5)) * (0.25 if kind in QUADS else 0.05)
	for i in _heads.size():
		var hd: Dictionary = _heads[i]
		var hs: Sprite2D = hd["s"]
		var bob2 := sin(_t * 2.4 + float(hd["ph"])) * 0.6
		var lunge := 0.0
		if _act in ["punch", "spit", "throw", "breath"]:
			lunge = 2.0 * sin(PI * p) * (1.0 if i == int(_t * 3.0) % 3 or _act != "punch" else 0.3)
		hs.position = (hd["base"] as Vector2) + Vector2(lunge, bob2)
		var hr := head_rot + sin(_t * 1.7 + float(hd["ph"])) * 0.08 - (0.3 * sin(PI * p) if _act in ["roar", "summon"] else 0.0)
		hs.rotation = lerp_angle(hs.rotation, hr, minf(1.0, 14.0 * delta))
	for k in _glows.size():
		var g: Polygon2D = _glows[k]
		g.scale = Vector2(1.0, 0.8 + 0.35 * absf(sin(_t * 9.0 + k)))
	for L in _legs:
		var s: Sprite2D = L["s"]
		var target: float = L.get("base", 0.0)
		if moving:
			target += sin(_phase + L["phase"]) * (0.55 if kind in QUADS else 0.35)
		if stretch > 0.0:
			target = (-0.9 if L["front"] else 0.8) if kind in QUADS else target - 0.3
		if crouch > 0.0:
			target += (0.4 if L["front"] else -0.4) * crouch
		if _act in ["roar", "summon"] and L["front"] and not kind in QUADS:
			target -= 0.9 * sin(PI * p)     # королева встаёт на дыбы, поднимая передние лапы
		s.rotation = lerp_angle(s.rotation, target, minf(1.0, 22.0 * delta))

var _hb := Vector2.INF
func _head_base() -> Vector2:
	if _hb == Vector2.INF:
		_hb = _head.position
	return _hb
