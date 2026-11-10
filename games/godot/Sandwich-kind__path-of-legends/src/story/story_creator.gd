class_name StoryCreator
extends CanvasLayer
# ---------- Создание персонажа ----------
# Слева — герой во весь рост (в кожаной рубахе и штанах, как в начале игры).
# Справа — выбор внешности стрелками «‹ ›» и имя.

signal back_pressed
signal created(slot: int, data: Dictionary)

var slot := 1
var look := StoryLook.default_look()
var _vs := Vector2.ZERO
var _holder: Node2D
var _rig: BotRig
var _vals := {}
var _name_edit: LineEdit

const START_GEAR := {"chest": "leather_shirt", "legs": "leather_pants"}

func _ready() -> void:
	_vs = Config.screen(self)
	StorySlots.backdrop(self, _vs)
	look["skin"] = randi() % StoryLook.SKINS.size()
	look["hair_color"] = randi() % 4
	var t := Label.new()
	t.text = "Создание героя"
	t.size = Vector2(_vs.x, 60)
	t.position = Vector2(0, 18)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 40)
	t.add_theme_color_override("font_color", Color(1.0, 0.86, 0.4))
	t.add_theme_constant_override("outline_size", 10)
	t.add_theme_color_override("font_outline_color", Color(0.25, 0.12, 0.08))
	add_child(t)
	var back := Button.new()
	back.text = "Назад"
	back.position = Vector2(24, 20)
	back.size = Vector2(150, 54)
	back.add_theme_font_size_override("font_size", 22)
	back.pressed.connect(func(): back_pressed.emit())
	add_child(back)
	# площадка с героем
	var stage := Panel.new()
	var sw := minf(380.0, _vs.x * 0.32)
	stage.position = Vector2(40, 90)
	stage.size = Vector2(sw, _vs.y - 120)
	stage.add_theme_stylebox_override("panel", StoryHud.box(Color(0.18, 0.24, 0.16, 0.9), Color(0.8, 0.6, 0.3), 14, 3))
	add_child(stage)
	var floor_y := stage.size.y - 70.0
	var gr := ColorRect.new()
	gr.color = Color(0, 0, 0, 0.25)
	gr.position = Vector2(40, floor_y)
	gr.size = Vector2(sw - 80, 8)
	stage.add_child(gr)
	_holder = Node2D.new()
	var k := 5.4
	_holder.scale = Vector2(k, k)
	_holder.position = Vector2(sw / 2, floor_y - Player.SIZE.y * k / 2)
	stage.add_child(_holder)
	var hint := Label.new()
	hint.text = "Начнёшь в простой кожаной\nрубахе и штанах"
	hint.size = Vector2(sw, 50)
	hint.position = Vector2(0, floor_y + 12)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.add_theme_font_size_override("font_size", 14)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.6))
	stage.add_child(hint)
	# выбор внешности
	var px := 40.0 + sw + 30.0
	var pw := _vs.x - px - 40.0
	var opts := Panel.new()
	opts.position = Vector2(px, 90)
	opts.size = Vector2(pw, _vs.y - 120)
	opts.add_theme_stylebox_override("panel", StoryHud.box(Color(0.12, 0.09, 0.07, 0.92), Color(0.8, 0.6, 0.3), 14, 3))
	add_child(opts)
	var y := 18.0
	var name_l := Label.new()
	name_l.text = "Имя"
	name_l.position = Vector2(24, y + 8)
	name_l.add_theme_font_size_override("font_size", 20)
	opts.add_child(name_l)
	_name_edit = LineEdit.new()
	_name_edit.text = StoryLook.random_name("m")
	_name_edit.max_length = 16
	_name_edit.position = Vector2(200, y)
	_name_edit.size = Vector2(pw - 400, 44)
	_name_edit.add_theme_font_size_override("font_size", 20)
	opts.add_child(_name_edit)
	var rnd := Button.new()
	rnd.text = "Случайное"
	rnd.position = Vector2(pw - 190, y)
	rnd.size = Vector2(166, 44)
	rnd.add_theme_font_size_override("font_size", 17)
	rnd.pressed.connect(func(): _name_edit.text = StoryLook.random_name(look["gender"]))
	opts.add_child(rnd)
	y += 58.0
	var rows := [["gender", "Пол"], ["build", "Телосложение"], ["skin", "Цвет кожи"], ["eyes", "Цвет глаз"],
			["hair", "Причёска"], ["hair_color", "Цвет волос"], ["beard", "Борода"], ["mark", "Отметины"]]
	var rh := minf(52.0, (opts.size.y - y - 90.0) / rows.size())
	for r in rows:
		_row(opts, r[0], r[1], y, pw)
		y += rh
	var go := Button.new()
	go.text = "Начать путь"
	go.size = Vector2(300, 64)
	go.position = Vector2((pw - 300) / 2, opts.size.y - 80)
	go.add_theme_font_size_override("font_size", 26)
	go.pressed.connect(_start)
	go.set_meta("pad_default", true)
	opts.add_child(go)
	_update()

func _row(parent: Control, key: String, title: String, y: float, pw: float) -> void:
	var l := Label.new()
	l.text = title
	l.position = Vector2(24, y + 8)
	l.add_theme_font_size_override("font_size", 19)
	parent.add_child(l)
	var minus := Button.new()
	minus.text = "‹"
	minus.position = Vector2(200, y)
	minus.size = Vector2(54, 44)
	minus.add_theme_font_size_override("font_size", 26)
	minus.pressed.connect(_step.bind(key, -1))
	parent.add_child(minus)
	var v := Label.new()
	v.position = Vector2(260, y + 6)
	v.size = Vector2(pw - 340 - 60, 34)
	v.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	v.add_theme_font_size_override("font_size", 19)
	v.add_theme_color_override("font_color", Color(1.0, 0.92, 0.7))
	parent.add_child(v)
	var plus := Button.new()
	plus.text = "›"
	plus.position = Vector2(pw - 80 - 60 + 6, y)
	plus.size = Vector2(54, 44)
	plus.add_theme_font_size_override("font_size", 26)
	plus.pressed.connect(_step.bind(key, 1))
	parent.add_child(plus)
	_vals[key] = v

func _options(key: String) -> Array:
	match key:
		"gender":
			return ["m", "f"]
		"build":
			return StoryLook.BUILDS
		"hair":
			return StoryLook.HAIRS
		"beard":
			return StoryLook.BEARDS
		"mark":
			return StoryLook.MARKS
		"skin":
			return range(StoryLook.SKINS.size())
		"eyes":
			return range(StoryLook.EYES.size())
		"hair_color":
			return range(StoryLook.HAIR_COLORS.size())
	return []

func _step(key: String, d: int) -> void:
	if key == "beard" and look["gender"] == "f":
		return
	var o := _options(key)
	var i := o.find(look[key])
	look[key] = o[posmod(i + d, o.size())]
	if key == "gender":
		var was_default: bool = _name_edit.text in StoryLook.NAMES_M or _name_edit.text in StoryLook.NAMES_F
		if was_default:
			_name_edit.text = StoryLook.random_name(look["gender"])
		if look["gender"] == "f":
			look["beard"] = "none"
			if look["hair"] == "short":
				look["hair"] = "long"
	_update()

func _update() -> void:
	if _rig:
		_rig.queue_free()
	_rig = BotRig.new()
	_rig.kind = "story"
	_rig.size = Player.SIZE
	_rig.custom_spec = StoryLook.spec(look, START_GEAR)
	_holder.add_child(_rig)
	for k in _vals:
		var l: Label = _vals[k]
		match k:
			"gender":
				l.text = "Мужской" if look["gender"] == "m" else "Женский"
			"build":
				l.text = StoryLook.BUILD_NAME[look["build"]]
			"hair":
				l.text = StoryLook.HAIR_NAME[look["hair"]]
			"beard":
				l.text = StoryLook.BEARD_NAME[look["beard"]] if look["gender"] == "m" else "—"
			"mark":
				l.text = StoryLook.MARK_NAME[look["mark"]]
			_:
				l.text = "%d из %d" % [int(look[k]) + 1, _options(k).size()]
		var cols := {"skin": StoryLook.SKINS, "eyes": StoryLook.EYES, "hair_color": StoryLook.HAIR_COLORS}
		if cols.has(k):
			l.add_theme_color_override("font_color", (cols[k] as Array)[int(look[k])].lightened(0.15))

func _start() -> void:
	var nm := _name_edit.text.strip_edges()
	if nm == "":
		nm = StoryLook.random_name(look["gender"])
	var d := StorySave.new_game(nm, look.duplicate())
	StorySave.save_slot(slot, d)
	created.emit(slot, d)
