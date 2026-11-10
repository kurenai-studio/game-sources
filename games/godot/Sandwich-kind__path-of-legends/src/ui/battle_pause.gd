class_name BattlePause
extends CanvasLayer
# ---------- Пауза в Дуэли и на Арене ----------
# Открывается кнопкой «Меню» на экране, кнопкой Start на геймпаде или Esc.
# Продолжить · Настройки · Управление · (Дуэль) Начать матч заново · В главное меню
# Пока окно открыто, игра стоит. Start / B / Esc — продолжить.

var main                      # главный узел игры (main.gd)
var kind := "duel"            # "duel" или "arena"
var _vs := Vector2.ZERO
var _box: Control
var _closing := false
var _sub: CanvasLayer         # открытые поверх «Настройки» или «Управление»

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_vs = Config.screen(self)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.size = _vs
	add_child(dim)
	_main()

func _unhandled_input(event: InputEvent) -> void:
	if _closing or (_sub and is_instance_valid(_sub)):
		return
	var start: bool = event is InputEventJoypadButton and event.pressed and event.button_index == JOY_BUTTON_START
	if start or event.is_action_pressed("p1_menu") or event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		resume()

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

func _button(text: String, y: float, fn: Callable, w := -1.0, x := 40.0, font := 22) -> Button:
	var b := Button.new()
	b.text = text
	b.size = Vector2(_box.size.x - 80 if w < 0.0 else w, 58)
	b.position = Vector2(x, y)
	b.add_theme_font_size_override("font_size", font)
	b.focus_mode = Control.FOCUS_ALL
	b.pressed.connect(fn)
	_box.add_child(b)
	return b

func _main() -> void:
	var items := [["Продолжить", resume], ["Настройки", _settings], ["Управление", _controls]]
	if kind == "duel":
		items.append(["Начать матч заново", _restart])
	items.append(["В главное меню", _confirm_exit])
	_clear(440, 92 + items.size() * 68 + 10, "Пауза")
	for i in items.size():
		var b := _button(items[i][0], 80 + i * 68, items[i][1])
		if i == 0:
			b.set_meta("pad_default", true)
			b.grab_focus.call_deferred()

func resume() -> void:
	if _closing:
		return
	_closing = true
	get_tree().paused = false
	queue_free()

func _restart() -> void:
	_closing = true
	get_tree().paused = false
	var m = main
	queue_free()
	m.start_duel.call_deferred()

func _confirm_exit() -> void:
	_clear(500, 236, "Выйти в главное меню?")
	var l := Label.new()
	if kind == "arena":
		var key := "coop" if main.arena_coop else "solo"
		var p := Save.arena_progress(key)
		l.text = "Прогресс сохранён: потом можно продолжить с волны %d." % int(p.get("wave", 1)) if not p.is_empty() else "Прогресс Арены сохраняется после каждой волны."
	else:
		l.text = "Матч не будет засчитан."
	l.size = Vector2(460, 50)
	l.position = Vector2(20, 72)
	l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 17)
	_box.add_child(l)
	var yes := _button("Выйти", 150, _exit, 200, 40, 22)
	var no := _button("Отмена", 150, _main, 200, 260, 22)
	no.set_meta("pad_default", true)
	no.grab_focus.call_deferred()
	yes.add_theme_color_override("font_color", Color(1.0, 0.7, 0.6))

func _exit() -> void:
	_closing = true
	get_tree().paused = false
	var m = main
	queue_free()
	m.show_menu.call_deferred()

# «Настройки» и «Управление» — те же экраны, что в меню, но поверх паузы
func _settings() -> void:
	var c := SettingsScreen.new()
	c.overlay = true
	_open_sub(c)
	c.back_pressed.connect(func():
		c.queue_free()
		main.rebuild_controls()          # новые кнопки (крестовина, размер, прозрачность) — сразу
		_refocus())

func _controls() -> void:
	var c := ControlsScreen.new()
	c.overlay = true
	c._mode = "fight"
	_open_sub(c)
	c.back_pressed.connect(func():
		c.queue_free()
		_refocus())

func _open_sub(c: CanvasLayer) -> void:
	c.layer = 21
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	_sub = c
	add_child(c)
	# геймпад: выбор сразу переходит в открытое окно
	var vp := get_viewport()
	var ow := vp.gui_get_focus_owner()
	if ow:
		ow.release_focus()
	(func(): Pad.focus_first(c)).call_deferred()

func _refocus() -> void:
	_sub = null
	for b in _box.get_children():
		if b is Button and b.has_meta("pad_default"):
			b.grab_focus.call_deferred()
