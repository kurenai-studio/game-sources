class_name Merchant
extends Node2D
# Торговец за стойкой: кепка, нахмуренные брови, пышные усы, борода,
# коричневая куртка и фартук. Стоит и дышит. Когда переставляет товары —
# поворачивается спиной и быстро машет руками.
# Рисунок 40 × 48 «пикселей», точка (0, 0) — середина нижнего края.

const SKIN := Color(0.93, 0.70, 0.58)
const CHEEK := Color(0.88, 0.50, 0.45)
const HAIR := Color(0.33, 0.20, 0.12)
const CAP := Color(0.36, 0.22, 0.13)
const JACKET := Color(0.45, 0.27, 0.15)
const APRON := Color(0.80, 0.72, 0.55)
const OUT := Color(0.12, 0.08, 0.06)

var _body: Sprite2D
var _arm_l: Sprite2D
var _arm_r: Sprite2D
var _front_tex: Texture2D
var _back_tex: Texture2D
var _t := 0.0
var busy := false            # переставляет товары
var _back := false

func _ready() -> void:
	_front_tex = ImageTexture.create_from_image(_draw_body(false))
	_back_tex = ImageTexture.create_from_image(_draw_body(true))
	var arm := ImageTexture.create_from_image(_draw_arm())
	_body = Sprite2D.new()
	_body.texture = _front_tex
	_body.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	_body.centered = false
	_body.offset = Vector2(-20, -48)
	add_child(_body)
	_arm_l = _part(arm, Vector2(3, 1), Vector2(-13, -27))
	_arm_r = _part(arm, Vector2(3, 1), Vector2(13, -27))
	_arm_r.scale.x = -1

func _part(tex: Texture2D, pivot: Vector2, pos: Vector2) -> Sprite2D:
	var s := Sprite2D.new()
	s.texture = tex
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -pivot
	s.position = pos
	add_child(s)
	return s

static func _r(im: Image, x: int, y: int, w: int, h: int, c: Color) -> void:
	im.fill_rect(Rect2i(x, y, w, h), c)

func _draw_body(back: bool) -> Image:
	var im := Image.create(40, 48, false, Image.FORMAT_RGBA8)
	# туловище: куртка, фартук спереди
	_r(im, 6, 28, 28, 20, OUT)
	_r(im, 7, 29, 26, 19, JACKET)
	_r(im, 7, 29, 26, 2, JACKET.lightened(0.15))
	if not back:
		_r(im, 13, 30, 14, 18, APRON)
		_r(im, 13, 30, 14, 1, APRON.lightened(0.15))
		_r(im, 12, 30, 1, 18, OUT)
		_r(im, 27, 30, 1, 18, OUT)
		_r(im, 16, 40, 8, 1, APRON.darkened(0.15))        # карман
	else:
		_r(im, 19, 30, 2, 18, JACKET.darkened(0.2))       # шов на спине
		_r(im, 12, 40, 16, 1, APRON)                       # завязки фартука
		_r(im, 18, 41, 4, 3, APRON)
	# голова
	_r(im, 10, 6, 20, 23, OUT)
	_r(im, 11, 7, 18, 21, SKIN if not back else HAIR)
	_r(im, 8, 15, 3, 6, SKIN)                              # уши
	_r(im, 29, 15, 3, 6, SKIN)
	_r(im, 8, 15, 1, 6, OUT)
	_r(im, 31, 15, 1, 6, OUT)
	if not back:
		# брови — нахмурены
		for i in 5:
			im.set_pixel(13 + i, 13 + i / 2, OUT)
			im.set_pixel(13 + i, 14 + i / 2, OUT)
			im.set_pixel(26 - i, 13 + i / 2, OUT)
			im.set_pixel(26 - i, 14 + i / 2, OUT)
		# глаза
		_r(im, 14, 16, 3, 2, Color.WHITE)
		_r(im, 23, 16, 3, 2, Color.WHITE)
		_r(im, 16, 16, 1, 2, OUT)
		_r(im, 23, 16, 1, 2, OUT)
		# нос и щёки
		_r(im, 19, 17, 2, 4, SKIN.darkened(0.12))
		_r(im, 12, 19, 4, 3, CHEEK)
		_r(im, 24, 19, 4, 3, CHEEK)
		# усы
		_r(im, 14, 21, 12, 3, HAIR)
		_r(im, 13, 22, 2, 3, HAIR)
		_r(im, 25, 22, 2, 3, HAIR)
		_r(im, 15, 21, 10, 1, HAIR.lightened(0.15))
		# рот и борода
		_r(im, 17, 24, 6, 1, Color(0.45, 0.2, 0.18))
		_r(im, 13, 25, 14, 4, HAIR.darkened(0.1))
		_r(im, 15, 29, 10, 2, HAIR.darkened(0.1))
	else:
		_r(im, 11, 24, 18, 4, HAIR.darkened(0.15))        # затылок
	# кепка с околышем
	_r(im, 9, 1, 22, 9, OUT)
	_r(im, 10, 2, 20, 7, CAP)
	_r(im, 10, 2, 20, 1, CAP.lightened(0.2))
	_r(im, 10, 7, 20, 2, CAP.darkened(0.35))
	if not back:
		_r(im, 9, 9, 22, 1, OUT)
	return im

func _draw_arm() -> Image:
	var im := Image.create(7, 20, false, Image.FORMAT_RGBA8)
	_r(im, 0, 0, 7, 16, OUT)
	_r(im, 1, 1, 5, 14, JACKET)
	_r(im, 1, 1, 5, 2, JACKET.lightened(0.15))
	_r(im, 0, 15, 7, 5, OUT)
	_r(im, 1, 15, 5, 4, SKIN)                     # кисть
	return im

# Повернуться спиной (true) или лицом (false)
func turn(to_back: bool, time := 0.14) -> void:
	if _back == to_back:
		return
	_back = to_back
	var t := create_tween()
	t.tween_property(_body, "scale:x", 0.0, time / 2.0)
	t.tween_callback(func(): _body.texture = _back_tex if to_back else _front_tex)
	t.tween_property(_body, "scale:x", 1.0, time / 2.0)

func _process(delta: float) -> void:
	_t += delta
	if busy:
		# быстро машет руками, переставляя товары
		_arm_l.rotation = sin(_t * 32.0) * 1.4 + 0.6
		_arm_r.rotation = -sin(_t * 32.0 + 1.3) * 1.4 - 0.6
		_body.position.y = absf(sin(_t * 16.0)) * -1.0
		_body.position.x = sin(_t * 9.0) * 1.0
	else:
		# спокойно дышит: грудь чуть поднимается, плечи с ней
		var b := sin(_t * 2.2)
		_body.scale.y = 1.0 + b * 0.018
		_body.position = Vector2.ZERO
		_arm_l.rotation = lerp_angle(_arm_l.rotation, -0.32 + b * 0.02, minf(1.0, delta * 10.0))
		_arm_r.rotation = lerp_angle(_arm_r.rotation, 0.32 - b * 0.02, minf(1.0, delta * 10.0))
		_arm_l.position.y = -27 - b * 0.4
		_arm_r.position.y = -27 - b * 0.4
