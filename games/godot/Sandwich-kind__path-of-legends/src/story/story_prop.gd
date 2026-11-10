class_name StoryProp
extends Node2D
# ---------- Предмет мира, с которым можно взаимодействовать ----------
# kind: chest (сундук), sign (табличка), door (дверь погреба), campfire (костёр — место отдыха).
# Подойди ближе radius и нажми «Взаимодействие».

var kind := "chest"
var id := ""                  # имя в сохранении (открытые сундуки и двери)
var radius := 95.0
var text := ""                # надпись на табличке
var opened := false
var _lid: Sprite2D
var _door: Sprite2D
var _flames: Array = []
var _t := 0.0

var K := 3.0                # во сколько раз растянут рисунок

func prompt() -> String:
	match kind:
		"chest":
			return "Открыть сундук" if not opened else "Сундук"
		"sign":
			return "Прочитать"
		"door":
			return "Открыть дверь" if not opened else "Войти"
		"campfire":
			return "Отдохнуть у костра"
	return ""

func _ready() -> void:
	z_index = -2
	match kind:
		"chest":
			_build_chest()
		"sign":
			_build_sign()
		"door":
			K = 4.0
			_build_door()
		"campfire":
			_build_fire()

func _spr(img: Image, pivot: Vector2, pos: Vector2) -> Sprite2D:
	BotRig._volume(img)
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -pivot
	s.position = pos
	s.scale = Vector2(K, K)
	add_child(s)
	return s

# ----- сундук: окованный деревянный ящик, крышка откидывается -----
func _build_chest() -> void:
	var wood := Color(0.55, 0.34, 0.18)
	var iron := Color(0.42, 0.42, 0.46)
	var body := BotRig._img(22, 11)
	BotRig._box(body, 0, 0, 22, 11, wood)
	for x in [0, 10, 20]:
		body.fill_rect(Rect2i(x, 0, 2, 11), iron)
	body.fill_rect(Rect2i(0, 9, 22, 2), iron.darkened(0.2))
	for y in range(2, 9, 3):
		body.fill_rect(Rect2i(3, y, 6, 1), wood.darkened(0.2))
		body.fill_rect(Rect2i(13, y, 6, 1), wood.darkened(0.2))
	BotRig._box(body, 9, 1, 4, 5, Color(0.85, 0.7, 0.3))        # замок
	body.set_pixel(10, 3, Color(0.15, 0.12, 0.1))
	_spr(body, Vector2(11, 11), Vector2.ZERO)
	var lid := BotRig._img(22, 7)
	BotRig._box(lid, 0, 0, 22, 7, wood.lightened(0.08))
	for x in [0, 10, 20]:
		lid.fill_rect(Rect2i(x, 0, 2, 7), iron)
	lid.fill_rect(Rect2i(1, 0, 20, 1), wood.lightened(0.3))
	_lid = _spr(lid, Vector2(0, 7), Vector2(-11 * K, -11 * K))      # петли сзади — слева
	if opened:
		_lid.rotation = -1.9

func open_lid() -> void:
	opened = true
	var t := create_tween()
	t.tween_property(_lid, "rotation", -1.9, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	Fx.sparks(get_parent(), global_position + Vector2(0, -40), Color(1.0, 0.9, 0.5), 14, 180.0, 3.0)

# ----- табличка на столбе -----
func _build_sign() -> void:
	var img := BotRig._img(22, 24)
	img.fill_rect(Rect2i(10, 9, 3, 15), Color(0.42, 0.28, 0.15))
	BotRig._box(img, 0, 1, 22, 10, Color(0.68, 0.50, 0.30))
	for y in [4, 7]:
		img.fill_rect(Rect2i(3, y, 16, 1), Color(0.35, 0.22, 0.12))
	img.fill_rect(Rect2i(0, 0, 22, 1), Color(0.5, 0.35, 0.2))
	_spr(img, Vector2(11, 24), Vector2.ZERO)

# ----- погреб: каменный вход в холм с деревянной дверью -----
func _build_door() -> void:
	var stone := Color(0.50, 0.48, 0.46)
	var img := BotRig._img(40, 30)
	for y in 30:
		var hw := int(20.0 * sqrt(clampf(1.0 - pow((30.0 - y) / 30.0, 2.0), 0.0, 1.0)))
		img.fill_rect(Rect2i(20 - hw, y, hw * 2, 1), Color(0.36, 0.52, 0.26) if y < 6 else Color(0.40, 0.34, 0.24))
	BotRig._box(img, 9, 8, 22, 22, stone)
	for k in 8:
		img.set_pixel(10 + (k * 7) % 20, 9 + (k * 5) % 20, stone.darkened(0.2))
	img.fill_rect(Rect2i(13, 12, 14, 18), Color(0.08, 0.06, 0.05))
	_spr(img, Vector2(20, 30), Vector2.ZERO)
	var door := BotRig._img(14, 18)
	BotRig._box(door, 0, 0, 14, 18, Color(0.45, 0.28, 0.14))
	for x in [4, 9]:
		door.fill_rect(Rect2i(x, 1, 1, 16), Color(0.32, 0.2, 0.1))
	for y in [3, 13]:
		door.fill_rect(Rect2i(0, y, 14, 2), Color(0.38, 0.38, 0.42))
	BotRig._box(door, 10, 8, 3, 3, Color(0.85, 0.7, 0.3))
	_door = _spr(door, Vector2(0, 18), Vector2(-7 * K, 0))
	if opened:
		_door.scale.x = K * 0.15

func open_door() -> void:
	opened = true
	var t := create_tween()
	t.tween_property(_door, "scale:x", K * 0.15, 0.5)

# ----- костёр -----
func _build_fire() -> void:
	var img := BotRig._img(18, 6)
	for k in 5:
		BotRig._box(img, k * 3, 2 + (k % 2), 6, 3, Color(0.42, 0.28, 0.16))
	for k in 6:
		BotRig._box(img, k * 3, 4, 3, 2, Color(0.5, 0.5, 0.52))
	_spr(img, Vector2(9, 6), Vector2.ZERO)
	for i in 3:
		var f := Polygon2D.new()
		f.polygon = PackedVector2Array([Vector2(-10, 0), Vector2(0, -34), Vector2(10, 0)])
		f.color = [Color(1.0, 0.35, 0.05, 0.85), Color(1.0, 0.6, 0.15, 0.9), Color(1.0, 0.9, 0.4, 0.95)][i]
		f.scale = Vector2.ONE * (1.0 - i * 0.28)
		f.position = Vector2(0, -8)
		add_child(f)
		_flames.append(f)
	var glow := Torch.make_glow(220.0, Color(1.0, 0.6, 0.3))
	glow.position = Vector2(0, -20)
	glow.modulate.a = 0.5
	add_child(glow)

func _process(delta: float) -> void:
	_t += delta
	for i in _flames.size():
		var f: Polygon2D = _flames[i]
		f.scale.y = (1.0 - i * 0.28) * (0.85 + 0.2 * sin(_t * (9.0 + i * 3.0) + i))
		f.skew = 0.12 * sin(_t * 5.0 + i)
