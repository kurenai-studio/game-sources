extends CanvasLayer

const UI_STYLE := preload("res://scripts/ui/UiStyles.gd")

var health_bar: ProgressBar
var health_label: Label
var xp_bar: ProgressBar
var level_label: Label
var score_label: Label
var wave_label: Label
var kill_label: Label
var time_label: Label
var dash_bar: ProgressBar
var boss_wrap: VBoxContainer
var boss_bar: ProgressBar
var boss_label: Label
var wave_banner: Label
var banner_tween: Tween
var pause_menu: Control
var game_over: Control
var upgrade_menu: Control

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	_build_overlays()

func _build_hud() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	var left := PanelContainer.new()
	left.position = Vector2(24, 22)
	left.size = Vector2(365, 116)
	left.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.018, 0.035, 0.07, 0.88), Color(0.16, 0.65, 0.8, 0.42), 9))
	root.add_child(left)
	var left_col := VBoxContainer.new()
	left_col.add_theme_constant_override("separation", 8)
	left.add_child(left_col)
	var health_row := HBoxContainer.new()
	left_col.add_child(health_row)
	health_label = UI_STYLE.label("CORE  100 / 100", 16, Color("effbff"))
	health_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	health_row.add_child(health_label)
	level_label = UI_STYLE.label("LV 01", 16, Color("ffe76a"))
	health_row.add_child(level_label)
	health_bar = _bar(Color("28e6c1"), 20)
	health_bar.max_value = 100
	health_bar.value = 100
	left_col.add_child(health_bar)
	xp_bar = _bar(Color("b359ff"), 10)
	xp_bar.max_value = 55
	xp_bar.value = 0
	left_col.add_child(xp_bar)

	var right := PanelContainer.new()
	right.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	right.position = Vector2(-328, 22)
	right.size = Vector2(304, 145)
	right.add_theme_stylebox_override("panel", UI_STYLE.panel(Color(0.018, 0.035, 0.07, 0.88), Color(0.16, 0.65, 0.8, 0.42), 9))
	root.add_child(right)
	var stats := VBoxContainer.new()
	stats.add_theme_constant_override("separation", 5)
	right.add_child(stats)
	score_label = _stat_line("SCORE", "0000000", stats, Color("7df6ff"))
	wave_label = _stat_line("WAVE", "01", stats, Color("ff70c6"))
	kill_label = _stat_line("DEFEATED", "0", stats)
	time_label = _stat_line("SURVIVAL", "00:00", stats)

	var dash_wrap := VBoxContainer.new()
	dash_wrap.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	dash_wrap.position = Vector2(25, -76)
	dash_wrap.size = Vector2(225, 52)
	root.add_child(dash_wrap)
	dash_wrap.add_child(UI_STYLE.label("DASH CAPACITOR  [SPACE]", 13, Color("94c8d8")))
	dash_bar = _bar(Color("42e8ff"), 9)
	dash_bar.max_value = 1.0
	dash_bar.value = 1.0
	dash_wrap.add_child(dash_bar)

	boss_wrap = VBoxContainer.new()
	boss_wrap.anchor_left = 0.5
	boss_wrap.anchor_right = 0.5
	boss_wrap.offset_left = -260.0
	boss_wrap.offset_right = 260.0
	boss_wrap.offset_top = 24.0
	boss_wrap.offset_bottom = 82.0
	boss_wrap.visible = false
	root.add_child(boss_wrap)
	boss_label = UI_STYLE.label("VOID ARCHON", 16, Color("ff75dc"))
	boss_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_wrap.add_child(boss_label)
	boss_bar = _bar(Color("d931bc"), 16)
	boss_bar.max_value = 100
	boss_wrap.add_child(boss_bar)

	wave_banner = UI_STYLE.label("WAVE 1", 42, Color("88f7ff"))
	wave_banner.set_anchors_preset(Control.PRESET_CENTER_TOP)
	wave_banner.position = Vector2(-250, 175)
	wave_banner.size = Vector2(500, 70)
	wave_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	wave_banner.modulate.a = 0.0
	root.add_child(wave_banner)

func _build_overlays() -> void:
	pause_menu = preload("res://scenes/ui/PauseMenu.tscn").instantiate()
	game_over = preload("res://scenes/ui/GameOver.tscn").instantiate()
	upgrade_menu = preload("res://scenes/ui/UpgradeMenu.tscn").instantiate()
	add_child(pause_menu)
	add_child(game_over)
	add_child(upgrade_menu)

func _bar(fill_color: Color, height: float) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.custom_minimum_size.y = height
	bar.show_percentage = false
	bar.add_theme_stylebox_override("background", UI_STYLE.panel(Color(0.005, 0.012, 0.025, 0.95), Color(0.08, 0.22, 0.3, 0.5), 4))
	bar.add_theme_stylebox_override("fill", UI_STYLE.panel(fill_color, fill_color.lightened(0.2), 4))
	return bar

func _stat_line(caption: String, value: String, parent: Control, tint: Color = Color("d0deea")) -> Label:
	var row := HBoxContainer.new()
	parent.add_child(row)
	var key := UI_STYLE.label(caption, 14, Color("6f8ca2"))
	key.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(key)
	var output := UI_STYLE.label(value, 16, tint)
	row.add_child(output)
	return output

func update_health(current: float, maximum: float) -> void:
	health_bar.max_value = maximum
	health_bar.value = current
	health_label.text = "CORE  %d / %d" % [ceil(current), ceil(maximum)]

func update_xp(current: int, needed: int, level: int) -> void:
	xp_bar.max_value = needed
	xp_bar.value = current
	level_label.text = "LV %02d" % level

func update_dash(ratio: float) -> void:
	dash_bar.value = clampf(ratio, 0.0, 1.0)

func update_stats() -> void:
	score_label.text = "%07d" % GameManager.score
	wave_label.text = "%02d" % GameManager.wave
	kill_label.text = str(GameManager.kills)
	time_label.text = GameManager.format_time(GameManager.survival_time)

func announce_wave(number: int, is_boss: bool) -> void:
	wave_banner.text = "BOSS WAVE  %02d" % number if is_boss else "WAVE  %02d" % number
	wave_banner.add_theme_color_override("font_color", Color("ff67cf") if is_boss else Color("88f7ff"))
	if banner_tween and banner_tween.is_valid():
		banner_tween.kill()
	wave_banner.modulate.a = 0.0
	wave_banner.scale = Vector2(0.85, 0.85)
	banner_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	banner_tween.tween_property(wave_banner, "modulate:a", 1.0, 0.25)
	banner_tween.parallel().tween_property(wave_banner, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK)
	banner_tween.tween_interval(1.3)
	banner_tween.tween_property(wave_banner, "modulate:a", 0.0, 0.45)

func show_boss(current: float, maximum: float) -> void:
	boss_wrap.visible = true
	boss_bar.max_value = maximum
	boss_bar.value = current

func hide_boss() -> void:
	boss_wrap.visible = false
