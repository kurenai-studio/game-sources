class_name DeepRig
extends Node2D
# ---------- Модели существ Драгоценных и Кристальных пещер ----------
#   gem_beetle   — самоцветный жук: панцирь-самоцвет, сворачивается в катящийся шар;
#   shardling*   — осколочник (три размера): ходячая друза на тонких ножках;
#   prismatic    — призматик: парящая призма, внутри горит свет;
#   resonator    — резонатор: кристальный камертон, гудит и дрожит;
#   crystal_moth — хрустальная моль: стеклянные крылья с узором;
#   baron_gryz   — Барон Грызь на буровой машине: бур спереди, котёл сзади.
# API как у BotRig: play(), hurt(), muzzle(). Картинки с объёмом (свет сверху,
# тень снизу) и переливом самоцветов.

const KINDS := ["gem_beetle", "shardling", "shardling_s", "shardling_xs", "prismatic", "resonator", "crystal_moth", "baron_gryz"]

var bot: Player
var kind := "gem_beetle"
var size := Vector2(50, 30)
var puppet_vx := 0.0
var puppet_facing := 1
var rolling := false          # жук катится шаром
var buzzing := 0.0            # резонатор гудит (0..1)
var drilling := false         # бур крутится быстрее
var px := 2.0

var _art: Node2D
var _body: Node2D
var _parts := {}              # имя -> Sprite2D
var _legs: Array = []
var _t := 0.0
var _phase := 0.0
var _act := ""
var _act_t := 0.0
var _act_len := 0.3
var _hurt := 0.0
var _glow: Polygon2D

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
		"gem_beetle": _build_beetle()
		"shardling", "shardling_s", "shardling_xs": _build_shardling()
		"prismatic": _build_prismatic()
		"resonator": _build_resonator()
		"crystal_moth": _build_moth()
		"baron_gryz": _build_baron()

# ---------- Рисование ----------
func _img(w: int, h: int) -> Image:
	return Image.create(maxi(w, 1), maxi(h, 1), false, Image.FORMAT_RGBA8)

func _spr(parent: Node, img: Image, pivot: Vector2, pos: Vector2, shimmer := 0.0) -> Sprite2D:
	BotRig._volume(img)
	var s := Sprite2D.new()
	s.texture = ImageTexture.create_from_image(img)
	s.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	s.centered = false
	s.offset = -pivot
	s.position = pos
	parent.add_child(s)
	if shimmer > 0.0:
		Shimmer.apply(s, shimmer)
	return s

func _setup(img_w: float) -> void:
	px = _size().x / img_w
	_art.scale = Vector2(px, px)
	_art.position = Vector2(0, _size().y / 2)

# Самоцветный жук: 28 × 16
func _build_beetle() -> void:
	_setup(28.0)
	var shell := Color(0.18, 0.72, 0.42)
	for k in 3:                                       # дальние лапки
		var l := _leg_img(Color(0.15, 0.12, 0.14))
		var s := _spr(_art, l, Vector2(1, 0), Vector2(-7 + k * 7, -5))
		s.modulate = Color(0.7, 0.7, 0.75)
		_legs.append({"s": s, "phase": k * 2.1})
	_art.move_child(_body, _art.get_child_count() - 1)
	var im := _img(24, 13)
	for y in 13:
		var hw := int(12.0 * sqrt(clampf(1.0 - pow((12.5 - y) / 12.5, 2.0), 0.0, 1.0)))
		for x in range(12 - hw, 12 + hw):
			var c := shell
			if (x + y * 2) % 6 < 2:
				c = shell.lightened(0.2)
			if x == 12:
				c = shell.darkened(0.35)                 # шов надкрылий
			im.set_pixel(x, y, c)
	for g in [[6, 6], [17, 5], [10, 9], [15, 10]]:
		DeepArt.gem(im, g[0], g[1], 1, DeepArt.GEMS[(g[0] + g[1]) % 5])
	_parts["shell"] = _spr(_body, im, Vector2(12, 13), Vector2(0, -3), 0.22)
	var head := _img(7, 6)
	BotRig._box(head, 0, 0, 6, 6, Color(0.16, 0.14, 0.16))
	head.set_pixel(4, 2, Color(0.9, 1.0, 0.6))
	head.fill_rect(Rect2i(5, 4, 2, 1), Color(0.75, 0.7, 0.55))        # жвалы
	_parts["head"] = _spr(_body, head, Vector2(0, 5), Vector2(11, -3))
	for k in 3:                                       # ближние лапки
		var l2 := _leg_img(Color(0.2, 0.16, 0.18))
		_legs.append({"s": _spr(_art, l2, Vector2(1, 0), Vector2(-6 + k * 7, -4)), "phase": k * 2.1 + PI})

func _leg_img(c: Color) -> Image:
	var l := _img(4, 6)
	l.fill_rect(Rect2i(0, 0, 2, 3), c)
	l.fill_rect(Rect2i(1, 3, 2, 3), c.lightened(0.1))
	return l

# Осколочник: 22 × 16
func _build_shardling() -> void:
	_setup(22.0)
	var c := DeepArt.CRYSTAL if kind != "shardling_s" else DeepArt.CRYSTAL_V
	for k in 2:
		var l := _img(2, 7)
		l.fill_rect(Rect2i(0, 0, 2, 7), c.darkened(0.3))
		var s := _spr(_art, l, Vector2(1, 0), Vector2(-5 + k * 9, -6))
		s.modulate = Color(0.7, 0.7, 0.8)
		_legs.append({"s": s, "phase": k * PI})
	_art.move_child(_body, _art.get_child_count() - 1)
	var im := _img(20, 14)
	for sp in [[5, 6, 4, 9], [11, 4, 5, 13], [16, 7, 3, 8]]:
		for yy in sp[3]:
			var hw := int(round(sp[2] * (1.0 - float(yy) / sp[3])))
			for x in range(sp[1] - hw + sp[0] - sp[1], sp[0] + hw + 1):
				var col := c.lightened(0.2) if x < sp[0] else c.darkened(0.08)
				if x == sp[0]:
					col = c.lightened(0.4)
				col.a = 0.95
				if x >= 0 and x < 20:
					im.set_pixel(x, 13 - yy, col)
	im.fill_rect(Rect2i(13, 9, 2, 2), Color(0.1, 0.1, 0.25))
	im.set_pixel(14, 9, Color(1, 1, 1))
	_parts["body"] = _spr(_body, im, Vector2(10, 14), Vector2(0, -5), 0.25)
	for k in 2:
		var l2 := _img(2, 7)
		l2.fill_rect(Rect2i(0, 0, 2, 7), c.darkened(0.15))
		_legs.append({"s": _spr(_art, l2, Vector2(1, 0), Vector2(-3 + k * 9, -6)), "phase": k * PI + PI / 2})

# Призматик: 20 × 32, парит над землёй
func _build_prismatic() -> void:
	_setup(20.0)
	var im := _img(18, 26)
	for y in 26:
		var t := float(y) / 25.0
		var hw := int(round(8.0 * (t if t < 0.7 else (1.0 - t) / 0.3 * 0.7)))
		for x in range(9 - hw, 9 + hw + 1):
			var col := Color(0.85, 0.92, 1.0) if x < 9 else Color(0.62, 0.70, 1.0)
			if x == 9 - hw or x == 9 + hw:
				col = Color(1, 1, 1)
			col.a = 0.92
			im.set_pixel(x, y, col)
	_parts["body"] = _spr(_body, im, Vector2(9, 26), Vector2(0, -6), 0.3)
	_glow = Polygon2D.new()
	_glow.polygon = Util.circle(3.0, 12)
	_glow.color = Color(1.0, 0.95, 0.8, 0.9)
	_glow.position = Vector2(0, -6 - 26 * 0.62)
	_body.add_child(_glow)
	var base := _img(14, 3)
	BotRig._box(base, 0, 0, 14, 3, Color(0.4, 0.5, 0.8))
	_parts["base"] = _spr(_art, base, Vector2(7, 3), Vector2(0, 0))

# Резонатор: 20 × 34 — камертон из кристалла на подставке
func _build_resonator() -> void:
	_setup(20.0)
	var c := DeepArt.CRYSTAL_V
	var stand := _img(14, 7)
	for y in 7:
		var hw := 3 + y
		stand.fill_rect(Rect2i(7 - hw, y, hw * 2, 1), Color(0.35, 0.40, 0.65).lightened(0.05 * (y % 2)))
	_parts["stand"] = _spr(_art, stand, Vector2(7, 7), Vector2(0, 0))
	var stem := _img(4, 10)
	BotRig._crystal_box(stem, 0, 0, 4, 10, c)
	_parts["stem"] = _spr(_body, stem, Vector2(2, 10), Vector2(0, -6))
	for side in [-1, 1]:
		var prong := _img(4, 16)
		BotRig._crystal_box(prong, 0, 0, 4, 16, c.lightened(0.1))
		prong.set_pixel(1, 2, Color(1, 1, 1))
		var s := _spr(_body, prong, Vector2(2, 16), Vector2(side * 4, -15), 0.3)
		_parts["prong%d" % side] = s
	var bridge := _img(12, 3)
	BotRig._crystal_box(bridge, 0, 0, 12, 3, c)
	_spr(_body, bridge, Vector2(6, 3), Vector2(0, -14))

# Хрустальная моль: 24 × 16
func _build_moth() -> void:
	px = _size().x / 24.0
	_art.scale = Vector2(px, px)
	_art.position = Vector2.ZERO
	var wing := _img(12, 10)
	for y in 10:
		var hw := int(11.0 * sin(PI * (y + 0.5) / 10.0))
		for x in hw:
			var col := Color(0.82, 0.78, 1.0, 0.75).lerp(Color(0.6, 0.85, 1.0, 0.75), float(x) / 12.0)
			if (x + y) % 4 == 0:
				col = col.lightened(0.25)
			if x == hw - 1:
				col = Color(1, 1, 1, 0.9)
			wing.set_pixel(x, y, col)
	DeepArt.gem(wing, 5, 4, 1, DeepArt.GEMS[3])
	_parts["wing_b"] = _spr(_body, wing, Vector2(0, 2), Vector2(-1, -2), 0.25)
	_parts["wing_b"].scale.x = -1
	_parts["wing_b"].modulate = Color(0.75, 0.75, 0.85)
	var body := _img(10, 5)
	BotRig._box(body, 0, 0, 10, 5, Color(0.55, 0.50, 0.72))
	body.set_pixel(8, 1, Color(0.9, 1.0, 1.0))
	_spr(_body, body, Vector2(5, 2.5), Vector2(0, 0))
	_parts["wing_f"] = _spr(_body, wing, Vector2(0, 2), Vector2(1, -2), 0.25)

# Буровая машина Барона: 56 × 42
func _build_baron() -> void:
	_setup(56.0)
	var iron := Color(0.36, 0.34, 0.38)
	# котёл сзади (уязвимое место) — светится
	var boiler := _img(14, 18)
	BotRig._box(boiler, 0, 0, 14, 18, Color(0.55, 0.32, 0.18))
	for y in [4, 10, 15]:
		boiler.fill_rect(Rect2i(0, y, 14, 1), Color(0.35, 0.2, 0.1))
	BotRig._box(boiler, 4, 6, 6, 5, Color(1.0, 0.55, 0.15))
	boiler.fill_rect(Rect2i(5, 7, 4, 3), Color(1.0, 0.85, 0.4))
	boiler.fill_rect(Rect2i(5, 0, 3, 4), Color(0.25, 0.25, 0.28))        # труба
	_parts["boiler"] = _spr(_body, boiler, Vector2(7, 18), Vector2(-20, -8))
	_glow = Polygon2D.new()
	_glow.polygon = Util.circle(5.0, 12)
	_glow.color = Color(1.0, 0.6, 0.2, 0.6)
	_glow.position = Vector2(-20, -16.5)
	_body.add_child(_glow)
	# корпус на гусеницах
	var hull := _img(36, 16)
	BotRig._box(hull, 0, 0, 36, 12, iron)
	for x in range(3, 34, 6):
		hull.set_pixel(x, 2, iron.lightened(0.4))                           # заклёпки
	hull.fill_rect(Rect2i(0, 5, 36, 1), iron.darkened(0.3))
	for i in 4:
		DeepArt.gem(hull, 8 + i * 6, 8, 1, DeepArt.GEMS[i])                # добыча в кузове
	BotRig._box(hull, 0, 11, 36, 5, Color(0.16, 0.16, 0.18))
	for x in range(2, 35, 4):
		hull.fill_rect(Rect2i(x, 12, 2, 3), Color(0.32, 0.32, 0.35))         # траки
	_parts["hull"] = _spr(_body, hull, Vector2(18, 16), Vector2(-2, 0))
	# бур спереди
	var drill := _img(18, 14)
	for x in 18:
		var hw := int(round(7.0 * (1.0 - float(x) / 18.0)))
		for y in range(maxi(0, 7 - hw), mini(14, 7 + hw + 1)):
			var stripe := (x + y) % 4 < 2
			drill.set_pixel(x, y, Color(0.75, 0.75, 0.8) if stripe else Color(0.5, 0.5, 0.56))
	_parts["drill"] = _spr(_body, drill, Vector2(0, 7), Vector2(16, -7))
	# сам Барон: кобольд в цилиндре и с моноклем
	var baron := _img(12, 16)
	BotRig._box(baron, 2, 7, 8, 9, Color(0.45, 0.18, 0.22))                 # камзол
	baron.fill_rect(Rect2i(5, 8, 2, 7), Color(0.9, 0.75, 0.3))
	BotRig._box(baron, 2, 2, 8, 6, Color(0.70, 0.45, 0.26))                  # голова
	baron.fill_rect(Rect2i(9, 4, 3, 3), Color(0.70, 0.45, 0.26))             # морда
	baron.fill_rect(Rect2i(7, 4, 2, 2), Color(1.0, 0.8, 0.2))
	baron.set_pixel(8, 4, Color(0.1, 0.05, 0.05))
	baron.fill_rect(Rect2i(6, 3, 4, 1), Color(0.9, 0.85, 0.6))               # монокль
	BotRig._box(baron, 2, 0, 8, 3, Color(0.12, 0.10, 0.12))                  # цилиндр
	baron.fill_rect(Rect2i(1, 2, 10, 1), Color(0.12, 0.10, 0.12))
	_parts["baron"] = _spr(_body, baron, Vector2(6, 16), Vector2(-4, -12))

# ---------- Анимации ----------
func play(n: String) -> void:
	_act = n
	_act_t = 0.0
	_act_len = {"roar": 0.9, "summon": 0.8, "throw": 0.35, "punch": 0.3, "cast": 0.7, "swing": 0.6, "slam": 0.55}.get(n, 0.3)

func hurt() -> void:
	_hurt = 0.12

func muzzle() -> Vector2:
	match kind:
		"prismatic":
			return _glow.global_position
		"baron_gryz":
			return _parts["baron"].global_position + Vector2(0, -12 * px)
		"resonator":
			return _body.global_position + Vector2(0, -20 * px)
	return global_position

func boiler_pos() -> Vector2:
	return _glow.global_position if _glow else global_position

func _process(delta: float) -> void:
	if bot != null and not is_instance_valid(bot):
		return
	_t += delta
	_hurt = maxf(0.0, _hurt - delta)
	modulate = Color(1.0, 0.55, 0.55) if _hurt > 0.0 else Color.WHITE
	scale.x = move_toward(scale.x, float(_facing()), delta * 10.0)
	if absf(scale.x) < 0.15:
		scale.x = 0.15 * float(_facing())
	if _act != "":
		_act_t += delta
		if _act_t >= _act_len:
			_act = ""
	var p := clampf(_act_t / _act_len, 0.0, 1.0) if _act != "" else 0.0
	var v := _vel()
	var spd := absf(v.x)
	var moving := spd > 15.0 and _floor()
	if moving:
		_phase += delta * spd / (5.0 * px)
	for L in _legs:
		var s: Sprite2D = L["s"]
		s.visible = not rolling
		s.rotation = sin(_phase + L["phase"]) * 0.5 if moving else 0.0
	match kind:
		"gem_beetle":
			var sh: Sprite2D = _parts["shell"]
			_parts["head"].visible = not rolling
			if rolling:
				_body.rotation += delta * 14.0 * signf(v.x if v.x != 0.0 else 1.0) * signf(scale.x)
				_body.position.y = -2.0
			else:
				_body.rotation = lerp_angle(_body.rotation, 0.0, minf(1.0, 12.0 * delta))
				_body.position.y = -absf(sin(_phase)) * 0.5 if moving else 0.0
				_parts["head"].position.x = 11.0 + (2.0 * sin(PI * p) if _act == "punch" else 0.0)
			sh.scale = Vector2.ONE
		"shardling", "shardling_s", "shardling_xs":
			_body.position.y = -absf(sin(_phase)) * 0.8 if moving else sin(_t * 3.0) * 0.3
			_body.rotation = 0.2 * sin(PI * p) if _act == "punch" else 0.0
		"prismatic":
			_body.position.y = -4.0 + sin(_t * 2.2) * 1.5
			_body.rotation = sin(_t * 1.3) * 0.06
			var charge := 1.0 if _act == "cast" else 0.0
			_glow.scale = Vector2.ONE * (1.0 + 0.3 * sin(_t * 6.0) + charge * 1.2 * p)
			_glow.color = Color(1.0, 0.95, 0.8, 0.8).lerp(Color(1.0, 0.4, 0.5, 1.0), charge * p)
		"resonator":
			var b := maxf(buzzing, 1.0 if _act == "cast" else 0.0)
			for side in [-1, 1]:
				var pr: Sprite2D = _parts["prong%d" % side]
				pr.rotation = side * (0.04 + 0.06 * b) * sin(_t * 60.0)
			_body.position.y = sin(_t * 2.0) * 0.3
		"crystal_moth":
			var flap := sin(_t * 18.0) * 0.8
			_parts["wing_f"].rotation = -flap
			_parts["wing_b"].rotation = flap
			_body.position.y = sin(_t * 18.0) * 0.6
			_body.rotation = clampf(v.x / 900.0, -0.3, 0.3) * signf(scale.x)
		"baron_gryz":
			var dr: Sprite2D = _parts["drill"]
			var fast := drilling or _act in ["swing", "punch"]
			dr.scale.y = 1.0 + (0.08 if fast else 0.03) * sin(_t * (50.0 if fast else 20.0))
			dr.position.x = 16.0 + (3.0 * sin(PI * p) if _act in ["swing", "punch"] else 0.0)
			_glow.scale = Vector2.ONE * (1.0 + 0.2 * sin(_t * 5.0))
			_body.position.y = -absf(sin(_phase * 2.0)) * 0.3 if moving else 0.0
			_parts["baron"].rotation = -0.2 * sin(PI * p) if _act in ["throw", "roar"] else 0.0
