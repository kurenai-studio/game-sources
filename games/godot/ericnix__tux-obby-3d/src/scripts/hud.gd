extends CanvasLayer
class_name Hud
## Interface do jogo: HUD, menu inicial, pausa e tela de vitória.

signal play_pressed
signal resume_pressed
signal restart_pressed
signal quit_pressed

const FONT_REG: FontFile = preload("res://assets/fonts/LiberationSans-Regular.ttf")
const FONT_BOLD: FontFile = preload("res://assets/fonts/LiberationSans-Bold.ttf")

const CREAM := Color("f6efe2")
const MUTED := Color("a9b2cc")
const TEAL := Color("5cf0cc")
const ORANGE := Color("ffa53d")
const RED := Color("ff6262")
const PANEL_BG := Color(0.045, 0.058, 0.10, 0.86)
const PANEL_BORDER := Color(0.32, 0.85, 0.76, 0.35)

var timer_label: Label
var deaths_label: Label
var fish_label: Label
var checkpoint_label: Label
var best_label: Label
var notify_label: Label
var hint_label: Label
var start_overlay: Control
var pause_overlay: Control
var win_overlay: Control
var win_time_label: Label
var win_deaths_label: Label
var win_fish_label: Label
var win_record_label: Label
var start_best_label: Label
var _flash: ColorRect
var _fade: ColorRect
var _notify_tween: Tween
var _root: Control
var _left_panel: PanelContainer
var _right_panel: PanelContainer
var _lang_buttons: Dictionary = {}
var _time_value := 0.0
var _deaths_value := 0
var _fish_value := 0
var _fish_total := 0
var _checkpoint_value := 0
var _checkpoint_total := 0
var _best_value := 0.0
var _win_time_value := 0.0
var _win_deaths_value := 0
var _win_fish_value := 0
var _win_fish_total := 0
var _win_best_value := 0.0
var _win_new_record := false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 10
	_build()
	Loc.locale_changed.connect(_on_locale_changed)


func _build() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_root)

	# ---------------------------------------------------------------- topo esquerdo
	var left_panel := _panel(Vector2(22, 22), Vector2(430, 122))
	_left_panel = left_panel
	left_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var left_box := VBoxContainer.new()
	left_box.add_theme_constant_override("separation", 0)
	left_panel.add_child(left_box)
	timer_label = _label(left_box, "00:00.00", 42, CREAM, true, 8)
	var stats := HBoxContainer.new()
	stats.add_theme_constant_override("separation", 16)
	left_box.add_child(stats)
	deaths_label = _label(stats, Loc.t("hud_deaths", [0]), 15, MUTED)
	fish_label = _label(stats, Loc.t("hud_fish", [0, 0]), 15, ORANGE)
	checkpoint_label = _label(stats, Loc.t("hud_checkpoint", [0, 5]), 15, TEAL)

	# ---------------------------------------------------------------- topo direito
	var right_panel := _panel(Vector2(-262, 22), Vector2(240, 92), Control.PRESET_TOP_RIGHT)
	_right_panel = right_panel
	right_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var right_box := VBoxContainer.new()
	right_box.alignment = BoxContainer.ALIGNMENT_END
	right_panel.add_child(right_box)
	var best_title := _label(right_box, Loc.t("hud_best_title"), 12, MUTED)
	Loc.bind_text(best_title, "hud_best_title")
	best_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	best_label = _label(right_box, "--:--.--", 24, CREAM, true)
	best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT

	# ---------------------------------------------------------------- notificação
	notify_label = _label(_root, "", 56, TEAL, true, 12)
	notify_label.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	notify_label.offset_left = 0
	notify_label.offset_right = 0
	notify_label.offset_top = 150
	notify_label.offset_bottom = 230
	notify_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notify_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	notify_label.modulate.a = 0.0

	hint_label = _label(_root, Loc.t("hud_hint"), 16, MUTED)
	hint_label.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	hint_label.offset_left = -520
	hint_label.offset_right = 520
	hint_label.offset_top = -54
	hint_label.offset_bottom = -22
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(hint_label, "hud_hint")

	# ---------------------------------------------------------------- efeitos
	_flash = ColorRect.new()
	_flash.color = Color(1.0, 0.15, 0.12, 0.0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_flash)

	_fade = ColorRect.new()
	_fade.color = Color(0.02, 0.025, 0.05, 0.0)
	_fade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(_fade)

	# ---------------------------------------------------------------- overlays
	_build_start_overlay()
	_build_pause_overlay()
	_build_win_overlay()

	start_overlay.visible = false
	pause_overlay.visible = false
	win_overlay.visible = false


func _build_start_overlay() -> void:
	var overlay := _overlay()
	start_overlay = overlay
	var panel := _center_panel(overlay, Vector2(720, 0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	panel.add_child(box)

	var kicker := _label(box, Loc.t("menu_kicker"), 14, TEAL, true)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(kicker, "menu_kicker")
	var title := _label(box, "TUX OBBY 3D", 68, CREAM, true, 14)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("b65416"))
	var subtitle := _label(box, Loc.t("menu_subtitle"), 20, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(subtitle, "menu_subtitle")
	_box_gap(box, 4)

	# Seletor de idioma: a escolha e imediata e fica salva entre partidas.
	var lang_row := HBoxContainer.new()
	lang_row.alignment = BoxContainer.ALIGNMENT_CENTER
	lang_row.add_theme_constant_override("separation", 8)
	box.add_child(lang_row)
	var lang_label := _label(lang_row, Loc.t("language"), 13, MUTED, true)
	lang_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	Loc.bind_text(lang_label, "language")
	for entry in [["pt_BR", "PORTUGUÊS"], ["en", "ENGLISH"], ["es", "ESPAÑOL"]]:
		_lang_button(lang_row, entry[1], entry[0])
	_update_language_buttons()

	_box_gap(box, 10)
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 22)
	grid.add_theme_constant_override("v_separation", 4)
	box.add_child(grid)
	_control_row(grid, "key_wasd", "menu_controls_move")
	_control_row(grid, "key_mouse", "menu_controls_camera")
	_control_row(grid, "key_space", "menu_controls_jump")
	_control_row(grid, "key_shift", "menu_controls_sprint")
	_control_row(grid, "key_r", "menu_controls_checkpoint")
	_control_row(grid, "key_esc", "menu_controls_pause")

	_box_gap(box, 12)
	var play := _button(box, Loc.t("menu_play"), func() -> void: play_pressed.emit())
	Loc.bind_text(play, "menu_play")
	play.add_theme_font_size_override("font_size", 26)
	play.custom_minimum_size = Vector2(0, 56)
	start_best_label = _label(box, Loc.t("menu_best", ["--:--.--"]), 15, MUTED)
	start_best_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var tip := _label(box, Loc.t("menu_tip"), 14, Color("7d89a8"))
	tip.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(tip, "menu_tip")
	var pulse := _label(box, Loc.t("menu_good_luck"), 16, ORANGE, true)
	pulse.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(pulse, "menu_good_luck")
	var tween := create_tween().set_loops()
	tween.tween_property(pulse, "modulate:a", 0.25, 1.1)
	tween.tween_property(pulse, "modulate:a", 1.0, 1.1)


func _build_pause_overlay() -> void:
	var overlay := _overlay()
	pause_overlay = overlay
	var panel := _center_panel(overlay, Vector2(520, 0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var title := _label(box, Loc.t("pause_title"), 54, CREAM, true, 10)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(title, "pause_title")
	var subtitle := _label(box, Loc.t("pause_subtitle"), 16, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(subtitle, "pause_subtitle")
	_box_gap(box, 10)
	var cont := _button(box, Loc.t("pause_resume"), func() -> void: resume_pressed.emit())
	Loc.bind_text(cont, "pause_resume")
	cont.add_theme_font_size_override("font_size", 22)
	var restart := _button(box, Loc.t("pause_restart"), func() -> void: restart_pressed.emit())
	Loc.bind_text(restart, "pause_restart")
	restart.add_theme_font_size_override("font_size", 22)
	var quit := _button(box, Loc.t("pause_quit"), func() -> void: quit_pressed.emit())
	Loc.bind_text(quit, "pause_quit")
	quit.add_theme_font_size_override("font_size", 22)
	var hint := _label(box, Loc.t("pause_hint"), 14, MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(hint, "pause_hint")


func _build_win_overlay() -> void:
	var overlay := _overlay()
	win_overlay = overlay
	var panel := _center_panel(overlay, Vector2(640, 0))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	panel.add_child(box)
	var kicker := _label(box, Loc.t("win_kicker"), 14, TEAL, true)
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(kicker, "win_kicker")
	var title := _label(box, Loc.t("win_title"), 52, CREAM, true, 12)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_outline_color", Color("b65416"))
	Loc.bind_text(title, "win_title")
	var subtitle := _label(box, Loc.t("win_subtitle"), 16, MUTED)
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(subtitle, "win_subtitle")
	_box_gap(box, 14)

	var stats := GridContainer.new()
	stats.columns = 2
	stats.add_theme_constant_override("h_separation", 30)
	stats.add_theme_constant_override("v_separation", 6)
	box.add_child(stats)
	_add_stat_row(stats, "win_time")
	_add_stat_row(stats, "win_deaths")
	_add_stat_row(stats, "win_fish")
	win_record_label = _label(box, "", 18, ORANGE, true)
	win_record_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	_box_gap(box, 14)
	var again := _button(box, Loc.t("win_again"), func() -> void: restart_pressed.emit())
	Loc.bind_text(again, "win_again")
	again.add_theme_font_size_override("font_size", 24)
	var quit := _button(box, Loc.t("win_quit"), func() -> void: quit_pressed.emit())
	Loc.bind_text(quit, "win_quit")
	quit.add_theme_font_size_override("font_size", 20)
	var hint := _label(box, Loc.t("win_hint"), 14, MUTED)
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Loc.bind_text(hint, "win_hint")


func _add_stat_row(grid: GridContainer, key: String) -> void:
	var key_label := _label(grid, Loc.t(key), 16, MUTED)
	Loc.bind_text(key_label, key)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	var value := _label(grid, "—", 22, CREAM, true)
	match key:
		"win_time": win_time_label = value
		"win_deaths": win_deaths_label = value
		"win_fish": win_fish_label = value


# ---------------------------------------------------------------- helpers de UI

func _label(parent: Node, text: String, size: int, color: Color, bold := false, outline := 4) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", FONT_BOLD if bold else FONT_REG)
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.015, 0.02, 0.04, 0.95))
	label.add_theme_constant_override("outline_size", outline)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _panel(pos: Vector2, size: Vector2, preset := Control.PRESET_TOP_LEFT) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	_root.add_child(panel)
	if preset == Control.PRESET_TOP_LEFT:
		panel.position = pos
		panel.size = size
	else:
		panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		panel.position = pos
		panel.size = size
	return panel


func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL_BG
	style.border_color = PANEL_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(16)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	style.shadow_color = Color(0, 0, 0, 0.35)
	style.shadow_size = 10
	return style


func _overlay() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.025, 0.055, 0.72)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	_root.add_child(overlay)
	return overlay


func _center_panel(overlay: Control, min_size: Vector2) -> PanelContainer:
	var center := overlay.get_child(1) as CenterContainer
	var style := _panel_style()
	style.bg_color = Color(0.04, 0.052, 0.09, 0.94)
	style.border_color = Color(0.35, 0.9, 0.8, 0.5)
	style.set_corner_radius_all(24)
	style.content_margin_left = 52
	style.content_margin_right = 52
	style.content_margin_top = 34
	style.content_margin_bottom = 34
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", style)
	panel.custom_minimum_size = min_size
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	center.add_child(panel)
	return panel


func _button(parent: Node, text: String, callback: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 46)
	button.add_theme_font_override("font", FONT_BOLD)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", Color("062019"))
	button.add_theme_color_override("font_hover_color", Color("02120e"))
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("5cf0cc")
	normal.set_corner_radius_all(12)
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("8affdd")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("38c6a7")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button


func _control_row(grid: GridContainer, key_key: String, description_key: String) -> void:
	var key_label := _label(grid, Loc.t(key_key), 18, TEAL, true, 3)
	Loc.bind_text(key_label, key_key)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	key_label.custom_minimum_size = Vector2(110, 0)
	var desc := _label(grid, Loc.t(description_key), 17, CREAM)
	Loc.bind_text(desc, description_key)
	desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _box_gap(box: VBoxContainer, height: int) -> void:
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, height)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)


# ---------------------------------------------------------------- API pública

static func format_time(seconds: float) -> String:
	var clamped := maxf(0.0, seconds)
	var minutes := int(clamped / 60.0)
	var secs := int(clamped) % 60
	var cents := int((clamped - floor(clamped)) * 100.0)
	return "%02d:%02d.%02d" % [minutes, secs, cents]


func set_time(seconds: float) -> void:
	_time_value = seconds
	timer_label.text = format_time(seconds)


func set_deaths(value: int) -> void:
	_deaths_value = value
	deaths_label.text = Loc.t("hud_deaths", [value])


func set_fish(value: int, total: int) -> void:
	_fish_value = value
	_fish_total = total
	fish_label.text = Loc.t("hud_fish", [value, total])


func set_checkpoint(value: int, total: int) -> void:
	_checkpoint_value = value
	_checkpoint_total = total
	checkpoint_label.text = Loc.t("hud_checkpoint", [value, total])


func set_best(seconds: float) -> void:
	_best_value = seconds
	var text := "--:--.--" if seconds <= 0.0 else format_time(seconds)
	best_label.text = text
	start_best_label.text = Loc.t("menu_best", [text])


func _on_locale_changed(_locale: String) -> void:
	_update_language_buttons()
	set_time(_time_value)
	set_deaths(_deaths_value)
	set_fish(_fish_value, _fish_total)
	set_checkpoint(_checkpoint_value, _checkpoint_total)
	set_best(_best_value)
	if win_overlay.visible:
		_apply_win_texts()


func _apply_win_texts() -> void:
	win_time_label.text = format_time(_win_time_value)
	win_deaths_label.text = str(_win_deaths_value)
	win_fish_label.text = "%d/%d" % [_win_fish_value, _win_fish_total]
	win_record_label.text = Loc.t("win_new_record") if _win_new_record else Loc.t("win_best", [format_time(_win_best_value)])
	win_record_label.add_theme_color_override("font_color", ORANGE if _win_new_record else MUTED)


func _lang_button(parent: Node, text: String, code: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(0, 30)
	button.add_theme_font_override("font", FONT_BOLD)
	button.add_theme_font_size_override("font_size", 12)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(func() -> void: Loc.set_locale(code))
	parent.add_child(button)
	_lang_buttons[code] = button
	_style_lang_button(button, false)
	return button


func _style_lang_button(button: Button, active: bool) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = TEAL if active else Color(0.09, 0.12, 0.19, 0.92)
	normal.border_color = Color(0.55, 1.0, 0.9, 0.8) if active else Color(0.4, 0.55, 0.7, 0.35)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(9)
	normal.content_margin_left = 12
	normal.content_margin_right = 12
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("8affdd") if active else Color(0.15, 0.2, 0.29, 0.98)
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("38c6a7") if active else Color(0.12, 0.16, 0.24, 1.0)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover)
	var fg := Color("062019") if active else MUTED
	var fg_hover := Color("02120e") if active else CREAM
	button.add_theme_color_override("font_color", fg)
	button.add_theme_color_override("font_hover_color", fg_hover)
	button.add_theme_color_override("font_pressed_color", fg_hover)
	button.add_theme_color_override("font_focus_color", fg_hover)


func _update_language_buttons() -> void:
	for code in _lang_buttons:
		var button: Button = _lang_buttons[code]
		if is_instance_valid(button):
			_style_lang_button(button, code == Loc.current_locale)


func notify(text: String, color: Color = TEAL) -> void:
	notify_label.text = text
	notify_label.add_theme_color_override("font_color", color)
	notify_label.modulate.a = 0.0
	notify_label.position.y = 0.0
	if _notify_tween and _notify_tween.is_valid():
		_notify_tween.kill()
	_notify_tween = create_tween()
	_notify_tween.set_parallel(true)
	_notify_tween.tween_property(notify_label, "modulate:a", 1.0, 0.13)
	_notify_tween.tween_property(notify_label, "position:y", -10.0, 0.25)
	_notify_tween.chain().tween_interval(1.0)
	_notify_tween.chain().tween_property(notify_label, "modulate:a", 0.0, 0.5)


func flash_death() -> void:
	_flash.color.a = 0.34
	var tween := create_tween()
	tween.tween_property(_flash, "color:a", 0.0, 0.55)


func fade_black(duration: float, target := 1.0) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "color:a", target, maxf(duration, 0.01))


func show_start(best: float) -> void:
	start_overlay.visible = true
	pause_overlay.visible = false
	win_overlay.visible = false
	hint_label.visible = false
	_left_panel.visible = false
	_right_panel.visible = false
	set_best(best)


func hide_start() -> void:
	start_overlay.visible = false
	_left_panel.visible = true
	_right_panel.visible = true
	hint_label.visible = true
	hint_label.modulate.a = 1.0
	var tween := create_tween()
	tween.tween_interval(9.0)
	tween.tween_property(hint_label, "modulate:a", 0.0, 1.5)


func show_pause() -> void:
	pause_overlay.visible = true


func hide_pause() -> void:
	pause_overlay.visible = false


func show_win(time: float, deaths: int, fish: int, total: int, new_record: bool, best: float) -> void:
	win_overlay.visible = true
	pause_overlay.visible = false
	start_overlay.visible = false
	hint_label.visible = false
	_left_panel.visible = false
	_right_panel.visible = false
	_win_time_value = time
	_win_deaths_value = deaths
	_win_fish_value = fish
	_win_fish_total = total
	_win_new_record = new_record
	_win_best_value = best
	_apply_win_texts()


func hide_win() -> void:
	win_overlay.visible = false
