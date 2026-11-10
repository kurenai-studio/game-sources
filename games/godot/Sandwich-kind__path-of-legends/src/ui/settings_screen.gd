class_name SettingsScreen
extends CanvasLayer
# ---------- Настройки (общие для всей игры, user://settings.json) ----------
# Экранные кнопки (поверх игры или полосой снизу), движение (стик или крестовина),
# прозрачность кнопок, числа урона, звук.

signal back_pressed

var overlay := false
var _vs := Vector2.ZERO
var _box: Control

func _ready() -> void:
	_vs = Config.screen(self)
	if overlay:
		var dim := ColorRect.new()
		dim.color = Color(0.05, 0.04, 0.05, 0.92)
		dim.size = _vs
		add_child(dim)
	else:
		StorySlots.backdrop(self, _vs)
	var t := Label.new()
	t.text = "Настройки"
	t.size = Vector2(_vs.x, 60)
	t.position = Vector2(0, 16)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 42)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.4))
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
	PadGlyph.attach(back, "B")
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if overlay and (event.is_action_pressed("ui_cancel") or event.is_action_pressed("p1_menu")):
		get_viewport().set_input_as_handled()
		back_pressed.emit()

func _build() -> void:
	if _box:
		_box.queue_free()
	_box = Panel.new()
	_box.size = Vector2(minf(820.0, _vs.x - 60), 520)
	_box.position = Vector2((_vs.x - _box.size.x) / 2, 96)
	_box.add_theme_stylebox_override("panel", StoryHud.box(Color(0.10, 0.08, 0.07, 0.95), Color(0.8, 0.6, 0.3), 14, 3))
	add_child(_box)
	var s := StorySettings.load_all()
	var w := _box.size.x
	var y := 22.0
	_section("Экранные кнопки (телефон)", y)
	y += 36.0
	y = _choice("Где кнопки", "touch_panel", [[false, "На экране"], [true, "Полоса снизу"]], s, y)
	y = _choice("Движение", "touch_move", [["stick", "Виртуальный стик"], ["dpad", "Крестовина"]], s, y)
	y = _slider("Видимость кнопок", "touch_alpha", 20, 100, s, y)
	y = _slider("Размер крестовины, %", "dpad_size", 60, 160, s, y)
	var note := _label("Размер — для режима «Крестовина». Изменения — со следующего боя (в Истории — после закрытия меню). С контроллером экранные кнопки прячутся.",
			Vector2(30, y), 14, Color(1, 1, 1, 0.55))
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.update_minimum_size()
	note.size = Vector2(w - 60, 40)
	y += 50.0
	_section("Игра", y)
	y += 36.0
	# флажки в два столбца, чтобы всё поместилось на одном экране
	var rows := [["damage_numbers", "Показывать числа урона"], ["screen_shake", "Тряска экрана"],
			["touch_on_pc", "Экранные кнопки на компьютере"]]
	for i in rows.size():
		var row: Array = rows[i]
		var cb := CheckButton.new()
		cb.text = row[1]
		cb.button_pressed = bool(s.get(row[0], true))
		cb.position = Vector2(30 + (i % 2) * (w / 2 - 10), y + (i / 2) * 42.0)
		cb.size = Vector2(w / 2 - 40, 40)
		cb.add_theme_font_size_override("font_size", 17)
		var key: String = row[0]
		cb.toggled.connect(func(on: bool): StorySettings.set_value(key, on))
		_box.add_child(cb)
	y += 42.0 * ceili(rows.size() / 2.0)
	y = _slider("Музыка", "music", 0, 100, s, y)
	y = _slider("Звуки", "sfx", 0, 100, s, y)

func _section(t: String, y: float) -> void:
	_label(t, Vector2(30, y), 20, Color(1.0, 0.85, 0.45))

func _label(t: String, pos: Vector2, size: int, c := Color(1, 0.95, 0.85)) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", c)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(l)
	return l

# Выбор из вариантов кнопками
func _choice(title: String, key: String, opts: Array, s: Dictionary, y: float) -> float:
	_label(title, Vector2(30, y + 8), 18)
	var x := 260.0
	for o in opts:
		var b := Button.new()
		b.text = o[1]
		b.position = Vector2(x, y)
		b.size = Vector2(240, 42)
		b.add_theme_font_size_override("font_size", 17)
		var on: bool = s.get(key) == o[0]
		b.modulate = Color(1.25, 1.15, 0.8) if on else Color(0.7, 0.7, 0.7)
		var v = o[0]
		b.pressed.connect(func():
			StorySettings.set_value(key, v)
			_build()
			_refocus(o[1]))
		_box.add_child(b)
		x += 252.0
	return y + 50.0

func _refocus(text: String) -> void:
	await get_tree().process_frame
	for c in _box.get_children():
		if c is Button and c.text == text:
			c.grab_focus()

func _slider(title: String, key: String, lo: float, hi: float, s: Dictionary, y: float) -> float:
	_label(title, Vector2(30, y + 6), 18)
	var sl := HSlider.new()
	sl.min_value = lo
	sl.max_value = hi
	sl.step = 5
	sl.value = float(s.get(key, hi))
	sl.position = Vector2(260, y + 10)
	sl.size = Vector2(_box.size.x - 380, 30)
	var val := _label(str(int(sl.value)), Vector2(_box.size.x - 100, y + 6), 18)
	sl.value_changed.connect(func(v: float):
		StorySettings.set_value(key, v)
		val.text = str(int(v)))
	_box.add_child(sl)
	return y + 46.0
