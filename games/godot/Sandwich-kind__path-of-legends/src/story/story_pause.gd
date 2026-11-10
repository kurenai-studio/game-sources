class_name StoryPause
extends CanvasLayer
# ---------- Меню паузы Истории ----------
# Продолжить · Сохранить · Настройки · В главное меню

var mode
var _vs := Vector2.ZERO
var _box: Control

func _ready() -> void:
	layer = 20
	_vs = Config.screen(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = _vs
	add_child(dim)
	_main()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("p1_menu") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		queue_free()

func _clear(w: float, h: float, title: String) -> void:
	if _box:
		_box.queue_free()
	_box = Panel.new()
	_box.size = Vector2(w, h)
	_box.position = (_vs - _box.size) / 2
	_box.add_theme_stylebox_override("panel", StoryHud.box(Color(0.10, 0.08, 0.07, 0.97), Color(0.8, 0.6, 0.3), 14, 3))
	add_child(_box)
	var t := Label.new()
	t.text = title
	t.size = Vector2(w, 50)
	t.position = Vector2(0, 14)
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	t.add_theme_font_size_override("font_size", 30)
	t.add_theme_color_override("font_color", Color(1.0, 0.85, 0.45))
	_box.add_child(t)

func _button(text: String, y: float, fn: Callable) -> Button:
	var b := Button.new()
	b.text = text
	b.size = Vector2(_box.size.x - 80, 58)
	b.position = Vector2(40, y)
	b.add_theme_font_size_override("font_size", 22)

	b.pressed.connect(fn)
	_box.add_child(b)
	return b

func _main() -> void:
	_clear(420, 536, "Пауза")
	_button("Продолжить", 80, queue_free)
	_button("Задания", 148, func():
		queue_free()
		mode.open_quests.call_deferred())
	var sv := _button("Сохранить", 216, func(): pass)
	sv.pressed.connect(func():
		mode.save_game()
		sv.text = "Сохранено ✓")
	_button("Настройки", 284, _settings)
	_button("Управление", 352, func():
		var c := ControlsScreen.new()
		c.overlay = true
		c._mode = "story"
		c.layer = 21
		c.process_mode = Node.PROCESS_MODE_ALWAYS
		c.back_pressed.connect(c.queue_free)
		add_child(c))
	_button("В главное меню", 420, _confirm_exit)

func _confirm_exit() -> void:
	_clear(460, 260, "Выйти в меню?")
	var l := Label.new()
	l.text = "Несохранённый прогресс будет потерян."
	l.size = Vector2(460, 30)
	l.position = Vector2(0, 74)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 17)
	_box.add_child(l)
	var a := Button.new()
	a.text = "Сохранить и выйти"
	a.size = Vector2(380, 54)
	a.position = Vector2(40, 116)
	a.add_theme_font_size_override("font_size", 20)
	a.focus_mode = Control.FOCUS_ALL
	a.pressed.connect(func():
		mode.save_game()
		mode.quit_to_menu())
	_box.add_child(a)
	var b := Button.new()
	b.text = "Выйти без сохранения"
	b.size = Vector2(185, 46)
	b.position = Vector2(40, 182)
	b.add_theme_font_size_override("font_size", 15)

	b.pressed.connect(mode.quit_to_menu)
	_box.add_child(b)
	var c := Button.new()
	c.text = "Отмена"
	c.size = Vector2(185, 46)
	c.position = Vector2(235, 182)
	c.add_theme_font_size_override("font_size", 17)
	c.focus_mode = Control.FOCUS_ALL
	c.pressed.connect(_main)
	_box.add_child(c)

# ----- Настройки — общий экран; после закрытия кнопки на экране перестраиваются -----
func _settings() -> void:
	var c := SettingsScreen.new()
	c.overlay = true
	c.layer = 21
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	c.back_pressed.connect(func():
		c.queue_free()
		mode._show_dmg = bool(StorySettings.get_value("damage_numbers"))
		mode.hud.build_buttons(mode.hero, mode.kit)
		mode.hero.ui = mode.hud.ui)
	add_child(c)
