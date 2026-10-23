extends Control

const RunEngine = preload("res://scripts/run_engine.gd")
const SAVE_PATH := "user://fold_three_record.cfg"
const SAMPLE_RATE := 22050
const ACHIEVEMENTS: Array[Dictionary] = [
	{"id": "first_line", "title": "第一道线", "desc": "完成一次三连消除"},
	{"id": "cross_line", "title": "交叉点", "desc": "一次完成双线同消"},
	{"id": "three_way", "title": "三线汇聚", "desc": "一次完成三线同消"},
	{"id": "builder", "title": "构筑成型", "desc": "一局获得 3 条词条"},
	{"id": "cascade", "title": "连锁反应", "desc": "达成 3 段级联"},
	{"id": "rescue", "title": "一线生机", "desc": "触发一次救场"},
	{"id": "score_500", "title": "破局者", "desc": "单局达到 500 分"},
]

const C_BG := Color("#0A111A")
const C_BG_ALT := Color("#0D1723")
const C_PANEL := Color("#111B29")
const C_PANEL_HI := Color("#162337")
const C_LINE := Color("#2A3A50")
const C_TEXT := Color("#F5EEDF")
const C_MUTED := Color("#8494A9")
const C_FAINT := Color("#596A80")
const C_GOLD := Color("#F1C968")
const C_CORAL := Color("#EF7B66")
const C_MINT := Color("#75D0A8")
const C_BLUE := Color("#75B7E6")
const C_PURPLE := Color("#A88DE8")

var engine = RunEngine.new()
var ui_root: Control
var best_score := 0
var runs_played := 0
var best_rule_count := 0
var best_cascade_record := 0
var unlocked_achievements: Dictionary = {}
var run_started_ms := 0
var run_ended_ms := 0
var action_lock := false
var run_recorded := false
var sound_enabled := true

var score_label: Label
var score_gain_label: Label
var best_label: Label
var record_header_label: Label
var time_label: Label
var turn_label: Label
var pending_panel: Panel
var pending_value_label: Label
var pending_kind_label: Label
var next_value_label: Label
var threshold_label: Label
var threshold_bar: ProgressBar
var streak_label: Label
var stats_label: Label
var board_status_label: Label
var board_hint_label: Label
var cell_buttons: Array[Button] = []
var cell_hint_labels: Array[Label] = []
var board_panel: Panel
var rules_vbox: VBoxContainer
var rules_count_label: Label
var rules_empty_label: Label
var rules_footer_label: Label
var fullscreen_button: Button
var sound_button: Button

var reward_overlay: ColorRect
var reward_title: Label
var reward_subtitle: Label
var reward_buttons: Array[Button] = []
var reward_refs: Array[Dictionary] = []

var game_over_overlay: ColorRect
var game_over_score: Label
var game_over_best: Label
var game_over_stats: Label
var game_over_rules: Label
var game_over_duration: Label
var game_over_achievement: Label
var game_over_rank: Label
var restart_button: Button
var copy_button: Button

var score_tween: Tween
var pending_tween: Tween
var overlay_tween: Tween
var board_shake_tween: Tween
var sfx_players: Dictionary = {}


func _ready() -> void:
	theme = _build_theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS
	get_window().min_size = Vector2i(720, 405)
	_load_record()
	_build_audio()
	_build_interface()
	_apply_audio_setting()
	start_new_run()
	queue_redraw()


func start_new_run(seed_value: int = -1) -> void:
	engine.start_run(seed_value)
	run_started_ms = Time.get_ticks_msec()
	run_ended_ms = 0
	run_recorded = false
	action_lock = false
	reward_overlay.visible = false
	game_over_overlay.visible = false
	_refresh_ui()
	_set_status("选择一个空格，落下当前方块")
	_pulse_pending_tile()


func _process(_delta: float) -> void:
	if time_label == null:
		return
	var elapsed := _current_elapsed_msec()
	time_label.text = "本局  %s" % _format_duration(elapsed)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_layout_content()
		queue_redraw()


func _draw() -> void:
	var view_size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, view_size), C_BG)
	draw_circle(Vector2(view_size.x - 55.0, -40.0), 300.0, Color(0.67, 0.82, 1.0, 0.035))
	draw_circle(Vector2(52.0, view_size.y + 55.0), 280.0, Color(1.0, 0.54, 0.40, 0.035))
	draw_circle(Vector2(view_size.x * 0.57, view_size.y * 0.52), 390.0, Color(0.44, 0.90, 0.70, 0.018))

	for x in range(0, int(view_size.x) + 1, 64):
		draw_line(Vector2(x, 0), Vector2(x, view_size.y), Color(1, 1, 1, 0.018), 1.0)
	for y in range(0, int(view_size.y) + 1, 64):
		draw_line(Vector2(0, y), Vector2(view_size.x, y), Color(1, 1, 1, 0.018), 1.0)

	draw_line(Vector2(32, 92), Vector2(view_size.x - 32, 92), Color(1, 1, 1, 0.07), 1.0)
	draw_circle(Vector2(44, 191), 2.0, C_GOLD)
	draw_circle(Vector2(44, 341), 2.0, C_CORAL)
	draw_circle(Vector2(44, 491), 2.0, C_MINT)


func _build_theme() -> Theme:
	var app_theme := Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray([
		"Microsoft YaHei UI",
		"PingFang SC",
		"Noto Sans CJK SC",
		"Source Han Sans SC",
		"Arial",
	])
	app_theme.default_font = font
	app_theme.default_font_size = 16
	return app_theme


func _build_interface() -> void:
	ui_root = Control.new()
	ui_root.position = Vector2.ZERO
	ui_root.size = Vector2(1280, 720)
	ui_root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(ui_root)
	_layout_content()
	_build_header()
	_build_left_panel()
	_build_board_panel()
	_build_rules_panel()
	_build_reward_overlay()
	_build_game_over_overlay()


func _layout_content() -> void:
	if ui_root == null:
		return
	var viewport_size := get_viewport_rect().size
	var design_size := Vector2(1280, 720)
	var fit_scale := minf(viewport_size.x / design_size.x, viewport_size.y / design_size.y)
	fit_scale = maxf(fit_scale, 0.01)
	ui_root.scale = Vector2(fit_scale, fit_scale)
	ui_root.position = (viewport_size - design_size * fit_scale) * 0.5


func _build_header() -> void:
	var brand_rule := ColorRect.new()
	brand_rule.position = Vector2(43, 29)
	brand_rule.size = Vector2(4, 43)
	brand_rule.color = C_CORAL
	brand_rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui_root.add_child(brand_rule)

	_add_label(ui_root, "叠三", Vector2(59, 20), Vector2(180, 38), 28, C_TEXT)
	_add_label(ui_root, "FOLD / THREE", Vector2(60, 55), Vector2(220, 18), 10, C_MUTED)
	_add_label(ui_root, "三种相同，一线消融。", Vector2(270, 31), Vector2(280, 24), 13, C_FAINT)

	time_label = _add_label(ui_root, "本局  00:00", Vector2(655, 29), Vector2(140, 28), 13, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	record_header_label = _add_label(ui_root, "最高  0", Vector2(812, 28), Vector2(176, 28), 13, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	fullscreen_button = _header_button(Vector2(1010, 23), "全屏")
	sound_button = _header_button(Vector2(1108, 23), "声音 开")
	fullscreen_button.pressed.connect(_toggle_fullscreen)
	sound_button.pressed.connect(_toggle_sound)


func _build_left_panel() -> void:
	var panel := _make_panel(ui_root, Rect2(44, 110, 268, 556), C_PANEL, 24, Color(1, 1, 1, 0.045), 1, 8)
	_add_label(panel, "TILE  /  当前落子", Vector2(22, 20), Vector2(220, 20), 12, C_MUTED)

	pending_panel = _make_panel(panel, Rect2(22, 49, 224, 142), C_BG_ALT, 22, Color(1, 1, 1, 0.08), 1, 4)
	pending_panel.pivot_offset = pending_panel.size / 2.0
	pending_panel.clip_contents = true
	pending_value_label = _add_label(pending_panel, "1", Vector2(14, 6), Vector2(108, 92), 56, C_TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	pending_value_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pending_kind_label = _add_label(pending_panel, "普通方块", Vector2(14, 105), Vector2(108, 20), 10, Color(1, 1, 1, 0.65), HORIZONTAL_ALIGNMENT_CENTER)

	var preview_divider := ColorRect.new()
	preview_divider.position = Vector2(133, 20)
	preview_divider.size = Vector2(1, 102)
	preview_divider.color = Color(1, 1, 1, 0.09)
	preview_divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pending_panel.add_child(preview_divider)
	_add_label(pending_panel, "NEXT", Vector2(150, 27), Vector2(58, 18), 9, Color(1, 1, 1, 0.45), HORIZONTAL_ALIGNMENT_CENTER)
	_add_label(pending_panel, "下一块", Vector2(150, 46), Vector2(58, 18), 10, C_FAINT, HORIZONTAL_ALIGNMENT_CENTER)
	next_value_label = _add_label(pending_panel, "1", Vector2(148, 66), Vector2(62, 48), 32, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	_add_label(panel, "SCORE  /  得分", Vector2(22, 210), Vector2(200, 20), 11, C_MUTED)
	score_label = _add_label(panel, "0", Vector2(20, 226), Vector2(174, 66), 52, C_TEXT)
	score_label.pivot_offset = Vector2(36, 30)
	score_gain_label = _add_label(panel, "", Vector2(142, 238), Vector2(102, 32), 18, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	score_gain_label.modulate.a = 0.0
	best_label = _add_label(panel, "最高记录  0", Vector2(23, 288), Vector2(220, 20), 12, C_FAINT)

	var divider := ColorRect.new()
	divider.position = Vector2(22, 320)
	divider.size = Vector2(224, 1)
	divider.color = Color(1, 1, 1, 0.07)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(divider)

	_add_label(panel, "下一条词条", Vector2(22, 337), Vector2(140, 18), 11, C_MUTED)
	threshold_label = _add_label(panel, "0 / 80", Vector2(156, 336), Vector2(90, 20), 12, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	threshold_bar = ProgressBar.new()
	threshold_bar.position = Vector2(22, 365)
	threshold_bar.size = Vector2(224, 8)
	threshold_bar.show_percentage = false
	threshold_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	threshold_bar.add_theme_stylebox_override("background", _flat_style(C_BG_ALT, 4))
	threshold_bar.add_theme_stylebox_override("fill", _flat_style(C_GOLD, 4))
	panel.add_child(threshold_bar)

	stats_label = _add_label(panel, "连线 0   ·   最高级联 ×1", Vector2(22, 391), Vector2(224, 20), 11, C_FAINT)
	streak_label = _add_label(panel, "热度 0  ·  救场 0", Vector2(22, 411), Vector2(224, 20), 11, C_FAINT)

	var guide := _make_panel(panel, Rect2(16, 447, 236, 94), Color(1, 1, 1, 0.025), 16, Color(1, 1, 1, 0.045), 1)
	_add_label(guide, "01  点击任意空格落子", Vector2(14, 12), Vector2(205, 20), 12, C_TEXT)
	_add_label(guide, "02  横 / 竖 / 斜三同即消", Vector2(14, 35), Vector2(205, 20), 12, C_MUTED)
	_add_label(guide, "03  满盘且无连线时结束", Vector2(14, 58), Vector2(205, 20), 12, C_MUTED)


func _build_board_panel() -> void:
	board_panel = _make_panel(ui_root, Rect2(344, 110, 472, 556), C_PANEL, 26, Color(1, 1, 1, 0.055), 1, 10)
	_add_label(board_panel, "3 × 3  场域", Vector2(24, 19), Vector2(230, 28), 18, C_TEXT)
	turn_label = _add_label(board_panel, "第 01 轮", Vector2(294, 23), Vector2(154, 20), 12, C_MUTED, HORIZONTAL_ALIGNMENT_RIGHT)
	board_hint_label = _add_label(board_panel, "落下后自动结算", Vector2(24, 42), Vector2(260, 18), 11, C_FAINT)

	for row in range(3):
		for col in range(3):
			var index := row * 3 + col
			var cell := Button.new()
			cell.position = Vector2(22 + col * 140, 66 + row * 140)
			cell.size = Vector2(128, 128)
			cell.focus_mode = Control.FOCUS_NONE
			cell.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
			cell.alignment = HORIZONTAL_ALIGNMENT_CENTER
			cell.add_theme_font_size_override("font_size", 46)
			cell.pressed.connect(_on_cell_pressed.bind(index))
			board_panel.add_child(cell)
			cell_buttons.append(cell)
			var hint := _add_label(cell, "", Vector2(8, 7), Vector2(52, 18), 10, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
			cell_hint_labels.append(hint)

	board_status_label = _add_label(board_panel, "选择一个空格", Vector2(24, 494), Vector2(424, 34), 13, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER)
	board_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func _build_rules_panel() -> void:
	var panel := _make_panel(ui_root, Rect2(844, 110, 392, 556), C_PANEL, 26, Color(1, 1, 1, 0.055), 1, 10)
	_add_label(panel, "规则构筑", Vector2(24, 19), Vector2(220, 28), 18, C_TEXT)
	_add_label(panel, "RULE STACK", Vector2(25, 45), Vector2(200, 18), 10, C_FAINT)
	rules_count_label = _add_label(panel, "0 条", Vector2(268, 23), Vector2(100, 24), 12, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)

	var divider := ColorRect.new()
	divider.position = Vector2(24, 74)
	divider.size = Vector2(344, 1)
	divider.color = Color(1, 1, 1, 0.07)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(divider)

	var scroll := ScrollContainer.new()
	scroll.position = Vector2(20, 86)
	scroll.size = Vector2(352, 430)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	panel.add_child(scroll)

	rules_vbox = VBoxContainer.new()
	rules_vbox.custom_minimum_size = Vector2(332, 0)
	rules_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rules_vbox.add_theme_constant_override("separation", 10)
	scroll.add_child(rules_vbox)

	rules_empty_label = _add_label(panel, "还没有词条。\n达到得分阈值后，从两条新规则中选择一条。", Vector2(48, 154), Vector2(296, 74), 13, C_FAINT, HORIZONTAL_ALIGNMENT_CENTER)
	rules_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	rules_footer_label = _add_label(panel, "所有效果永久生效 · 成就 0 / 7", Vector2(22, 525), Vector2(348, 20), 11, C_FAINT, HORIZONTAL_ALIGNMENT_CENTER)


func _build_reward_overlay() -> void:
	reward_overlay = ColorRect.new()
	reward_overlay.position = Vector2.ZERO
	reward_overlay.size = Vector2(1280, 720)
	reward_overlay.color = Color(0.025, 0.04, 0.06, 0.84)
	reward_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	reward_overlay.z_index = 100
	reward_overlay.visible = false
	ui_root.add_child(reward_overlay)

	var panel := _make_panel(reward_overlay, Rect2(200, 98, 880, 524), Color("#101A28"), 28, Color(1, 1, 1, 0.09), 1, 16)
	_add_label(panel, "规则裂变", Vector2(40, 28), Vector2(250, 18), 11, C_GOLD)
	reward_title = _add_label(panel, "选择一条新规则", Vector2(40, 48), Vector2(800, 45), 30, C_TEXT)
	reward_subtitle = _add_label(panel, "选择将永久加入本局构筑；相同规则可继续叠层。", Vector2(40, 92), Vector2(800, 22), 12, C_MUTED)

	for i in range(2):
		var card := Button.new()
		card.position = Vector2(40 + i * 410, 138)
		card.size = Vector2(380, 330)
		card.focus_mode = Control.FOCUS_NONE
		card.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		card.pressed.connect(_on_reward_pressed.bind(i))
		panel.add_child(card)
		reward_buttons.append(card)

		var accent := ColorRect.new()
		accent.position = Vector2(0, 24)
		accent.size = Vector2(5, 282)
		accent.color = C_GOLD
		accent.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(accent)

		var index_label := _add_label(card, "01", Vector2(22, 19), Vector2(60, 20), 11, C_FAINT)
		var category_label := _add_label(card, "得分", Vector2(274, 18), Vector2(84, 22), 11, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
		var title := _add_label(card, "规则名称", Vector2(22, 51), Vector2(332, 36), 24, C_TEXT)
		var desc := _add_label(card, "规则效果说明。", Vector2(22, 104), Vector2(332, 66), 14, C_TEXT)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		var divider := ColorRect.new()
		divider.position = Vector2(22, 187)
		divider.size = Vector2(336, 1)
		divider.color = Color(1, 1, 1, 0.08)
		divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(divider)
		var note := _add_label(card, "构筑提示", Vector2(22, 205), Vector2(336, 48), 12, C_MUTED)
		note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		var stack := _add_label(card, "当前 0 / 3", Vector2(22, 269), Vector2(170, 22), 12, C_FAINT)
		_add_label(card, "点击选入  →", Vector2(213, 266), Vector2(145, 26), 13, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)

		reward_refs.append({
			"accent": accent,
			"index": index_label,
			"category": category_label,
			"title": title,
			"desc": desc,
			"note": note,
			"stack": stack,
		})

	_add_label(panel, "提示：按当前构筑选择，而不是只看单次数值。", Vector2(41, 485), Vector2(798, 20), 11, C_FAINT)


func _build_game_over_overlay() -> void:
	game_over_overlay = ColorRect.new()
	game_over_overlay.position = Vector2.ZERO
	game_over_overlay.size = Vector2(1280, 720)
	game_over_overlay.color = Color(0.025, 0.04, 0.06, 0.88)
	game_over_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	game_over_overlay.z_index = 110
	game_over_overlay.visible = false
	ui_root.add_child(game_over_overlay)

	var panel := _make_panel(game_over_overlay, Rect2(300, 92, 680, 536), Color("#101A28"), 28, Color(1, 1, 1, 0.09), 1, 16)
	_add_label(panel, "RUN COMPLETE  /  本局记录", Vector2(46, 30), Vector2(580, 18), 11, C_CORAL)
	_add_label(panel, "场域已满", Vector2(45, 55), Vector2(360, 46), 32, C_TEXT)
	_add_label(panel, "没有可消除的三连线。", Vector2(47, 99), Vector2(420, 22), 12, C_MUTED)

	game_over_score = _add_label(panel, "0", Vector2(43, 133), Vector2(320, 88), 68, C_TEXT)
	_add_label(panel, "最终得分", Vector2(48, 220), Vector2(180, 20), 11, C_FAINT)
	game_over_rank = _add_label(panel, "B", Vector2(430, 88), Vector2(200, 54), 40, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	game_over_best = _add_label(panel, "最高记录 0", Vector2(438, 149), Vector2(190, 28), 14, C_GOLD, HORIZONTAL_ALIGNMENT_RIGHT)
	game_over_duration = _add_label(panel, "第 1 局 · 用时 00:00", Vector2(398, 181), Vector2(230, 22), 12, C_FAINT, HORIZONTAL_ALIGNMENT_RIGHT)

	var stat_panel := _make_panel(panel, Rect2(44, 256, 584, 72), Color(1, 1, 1, 0.025), 16, Color(1, 1, 1, 0.055), 1)
	game_over_stats = _add_label(stat_panel, "0 次连线   ·   最高级联 ×1   ·   最高同时 0 线", Vector2(18, 24), Vector2(548, 24), 13, C_MUTED, HORIZONTAL_ALIGNMENT_CENTER)

	_add_label(panel, "本局构筑", Vector2(46, 352), Vector2(180, 22), 11, C_FAINT)
	game_over_rules = _add_label(panel, "未获得词条", Vector2(46, 376), Vector2(584, 48), 14, C_TEXT)
	game_over_rules.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	game_over_achievement = _add_label(panel, "新成就 · 第一道线", Vector2(46, 432), Vector2(584, 20), 11, C_MINT)

	restart_button = Button.new()
	restart_button.position = Vector2(100, 472)
	restart_button.size = Vector2(228, 48)
	restart_button.text = "再来一局   →"
	restart_button.focus_mode = Control.FOCUS_NONE
	restart_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	restart_button.add_theme_font_size_override("font_size", 15)
	restart_button.add_theme_color_override("font_color", Color("#111721"))
	restart_button.add_theme_color_override("font_hover_color", Color("#111721"))
	restart_button.add_theme_stylebox_override("normal", _flat_style(C_GOLD, 15))
	restart_button.add_theme_stylebox_override("hover", _flat_style(C_GOLD.lightened(0.1), 15))
	restart_button.add_theme_stylebox_override("pressed", _flat_style(C_GOLD.darkened(0.08), 15))
	restart_button.pressed.connect(_on_restart_pressed)
	panel.add_child(restart_button)

	copy_button = Button.new()
	copy_button.position = Vector2(344, 472)
	copy_button.size = Vector2(228, 48)
	copy_button.text = "复制战绩"
	copy_button.focus_mode = Control.FOCUS_NONE
	copy_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	copy_button.add_theme_font_size_override("font_size", 14)
	copy_button.add_theme_color_override("font_color", C_TEXT)
	copy_button.add_theme_color_override("font_hover_color", C_GOLD)
	copy_button.add_theme_stylebox_override("normal", _flat_style(Color(1, 1, 1, 0.035), 15, Color(1, 1, 1, 0.12), 1))
	copy_button.add_theme_stylebox_override("hover", _flat_style(Color(1, 1, 1, 0.065), 15, C_GOLD, 1))
	copy_button.add_theme_stylebox_override("pressed", _flat_style(Color(1, 1, 1, 0.025), 15, C_GOLD.darkened(0.15), 1))
	copy_button.pressed.connect(_on_copy_result_pressed)
	panel.add_child(copy_button)


func _on_cell_pressed(index: int) -> void:
	if action_lock or engine.phase != RunEngine.PHASE_PLAYING:
		return
	action_lock = true
	var result: Dictionary = engine.place(index)
	_refresh_ui()
	_play_sfx("place")
	_animate_place_result(index, result)
	_set_status_from_resolution(result)

	if engine.phase == RunEngine.PHASE_REWARD:
		await get_tree().create_timer(0.55).timeout
		_show_reward()
	elif engine.phase == RunEngine.PHASE_GAME_OVER:
		await get_tree().create_timer(0.7).timeout
		_show_game_over()
	else:
		_pulse_pending_tile()
	action_lock = false


func _on_reward_pressed(card_index: int) -> void:
	if engine.phase != RunEngine.PHASE_REWARD:
		return
	if card_index < 0 or card_index >= engine.pending_choices.size():
		return
	var choice := String(engine.pending_choices[card_index])
	var result: Dictionary = engine.choose_rule(choice)
	if not bool(result.get("ok", false)):
		return
	reward_overlay.visible = false
	_play_sfx("rule")
	_refresh_ui()
	_set_status("词条已生效：%s" % String(engine.get_rule(choice).get("title", "")))
	if engine.phase == RunEngine.PHASE_REWARD:
		await get_tree().create_timer(0.35).timeout
		_show_reward()
	elif engine.phase == RunEngine.PHASE_GAME_OVER:
		await get_tree().create_timer(0.45).timeout
		_show_game_over()
	else:
		_pulse_pending_tile()


func _on_restart_pressed() -> void:
	game_over_overlay.visible = false
	start_new_run()


func _on_copy_result_pressed() -> void:
	var text := "我在《叠三》拿到 %s 分，评级 %s，收下 %d 条词条，最高级联 ×%d。来挑战我！" % [
		_format_number(engine.score), game_over_rank.text, engine.rewards_selected, engine.best_cascade
	]
	DisplayServer.clipboard_set(text)
	copy_button.text = "已复制 ✓"
	_play_sfx("rule")
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(copy_button):
		copy_button.text = "复制战绩"


func _refresh_ui() -> void:
	if score_label == null:
		return

	score_label.text = _format_number(engine.score)
	best_label.text = "最高记录  " + _format_number(best_score)
	record_header_label.text = "最高  " + _format_number(best_score)
	turn_label.text = "第 %02d 轮" % engine.turn
	threshold_label.text = "%d / %d" % [engine.score, engine.next_threshold()]
	threshold_bar.max_value = maxf(1.0, float(engine.next_threshold()))
	threshold_bar.value = clampf(float(engine.score), 0.0, float(engine.next_threshold()))
	stats_label.text = "连线 %d   ·   最高级联 ×%d" % [engine.lines_cleared, engine.best_cascade]
	streak_label.text = "热度 %d  ·  救场 %d" % [engine.streak, engine.rescue_charges]

	var empty_count := 0
	var imminent_count := 0
	for i in cell_buttons.size():
		var button := cell_buttons[i]
		var value := int(engine.board[i])
		var line_preview := 0
		if value == 0:
			empty_count += 1
			line_preview = _preview_line_count(i)
			if line_preview > 0:
				imminent_count += 1
		_style_cell(button, value, line_preview > 0)
		var hint := cell_hint_labels[i]
		hint.text = ("%d 线" % line_preview) if line_preview > 0 else ""
		if value == 0:
			button.text = "＋"
			button.add_theme_font_size_override("font_size", 30)
			button.add_theme_color_override("font_color", C_GOLD if line_preview > 0 else Color(0.61, 0.72, 0.84, 0.22))
			button.add_theme_color_override("font_hover_color", Color(0.95, 0.85, 0.55, 0.9))
			button.tooltip_text = "在此落下 %s，可完成 %d 条线" % [engine.pending_text(), line_preview] if line_preview > 0 else "在此落下 %s" % engine.pending_text()
		else:
			button.text = "✦" if value == RunEngine.WILD_VALUE else str(value)
			button.add_theme_font_size_override("font_size", 44 if button.text.length() < 3 else 34)
			button.add_theme_color_override("font_color", Color("#111722"))
			button.add_theme_color_override("font_hover_color", Color("#111722"))
			button.tooltip_text = "万能块" if value == RunEngine.WILD_VALUE else "数值 %d" % value

	_update_pending_card()
	_refresh_rules()
	if engine.phase == RunEngine.PHASE_PLAYING:
		if imminent_count > 0:
			board_hint_label.text = "可消位置 %d 个 · 当前方块能成线" % imminent_count
		elif empty_count <= 3:
			board_hint_label.text = "仅剩 %d 个空位 · 满盘无解即结束" % empty_count
		else:
			board_hint_label.text = "点击空格 · 落下 %s" % engine.pending_text()
	elif engine.phase == RunEngine.PHASE_REWARD:
		board_hint_label.text = "规则选择中 · 构筑暂停"
	else:
		board_hint_label.text = "本局结束"


func _update_pending_card() -> void:
	pending_value_label.text = engine.pending_text()
	pending_kind_label.text = "等待选择空格" if engine.has_pending else "正在结算"
	next_value_label.text = engine.next_text()
	var bg := C_BG_ALT
	var border := Color(1, 1, 1, 0.08)
	var text_color := C_TEXT
	var caption_color := Color(1, 1, 1, 0.65)
	if not engine.has_pending:
		text_color = C_FAINT
		pending_kind_label.text = "构筑暂停"
	elif engine.pending_value == RunEngine.WILD_VALUE:
		bg = C_GOLD.darkened(0.28)
		border = C_GOLD
		text_color = C_GOLD.lightened(0.2)
		pending_kind_label.text = "万能方块"
	else:
		bg = _value_color(engine.pending_value).darkened(0.46)
		border = _value_color(engine.pending_value)
		text_color = _value_color(engine.pending_value).lightened(0.16)
		pending_kind_label.text = "普通方块"
	pending_panel.add_theme_stylebox_override("panel", _flat_style(bg, 22, border, 1, Color(0, 0, 0, 0.22), 5))
	pending_value_label.add_theme_color_override("font_color", text_color)
	pending_kind_label.add_theme_color_override("font_color", caption_color)
	next_value_label.add_theme_color_override("font_color", _value_color(engine.next_value).lightened(0.28) if engine.next_value != RunEngine.WILD_VALUE else C_GOLD)


func _style_cell(button: Button, value: int, imminent: bool = false) -> void:
	if value == 0:
		var empty := _flat_style(Color("#242518") if imminent else Color("#0D1722"), 20, C_GOLD if imminent else Color("#26354A"), 2 if imminent else 1, Color(0, 0, 0, 0.18), 5 if imminent else 3)
		var hover := _flat_style(Color("#32311D") if imminent else Color("#172A39"), 20, C_GOLD, 2, Color(0, 0, 0, 0.22), 7)
		var pressed := _flat_style(Color("#191E18") if imminent else Color("#101F2B"), 20, C_GOLD, 2)
		button.add_theme_stylebox_override("normal", empty)
		button.add_theme_stylebox_override("hover", hover)
		button.add_theme_stylebox_override("pressed", pressed)
		button.add_theme_stylebox_override("disabled", empty)
		return

	var tile_color := _value_color(value)
	var normal := _flat_style(tile_color, 20, tile_color.lightened(0.16), 2, tile_color.darkened(0.3), 5)
	var hover := _flat_style(tile_color.lightened(0.07), 20, C_TEXT, 2, tile_color.darkened(0.25), 7)
	var pressed := _flat_style(tile_color.darkened(0.04), 20, tile_color.darkened(0.18), 2)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)


func _preview_line_count(index: int) -> int:
	if engine.phase != RunEngine.PHASE_PLAYING or not engine.has_pending:
		return 0
	if index < 0 or index >= engine.board.size() or engine.board[index] != 0:
		return 0
	engine.board[index] = engine.pending_value
	var match_count: int = engine.get_matches().size()
	engine.board[index] = 0
	return match_count


func _refresh_rules() -> void:
	for child in rules_vbox.get_children():
		child.free()

	var acquired_ids: Array[String] = []
	for definition in RunEngine.RULES:
		var id := String(definition["id"])
		if engine.get_rule_stack(id) > 0:
			acquired_ids.append(id)
	rules_count_label.text = "%d 条" % acquired_ids.size()
	rules_empty_label.visible = acquired_ids.is_empty()
	rules_footer_label.text = "永久堆叠 · 成就 %d/%d · 最佳构筑 %d 条" % [unlocked_achievements.size(), ACHIEVEMENTS.size(), best_rule_count]

	for rule_id in acquired_ids:
		var definition := engine.get_rule(rule_id)
		var accent := Color(String(definition["accent"]))
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(332, 100)
		card.add_theme_stylebox_override("panel", _flat_style(Color(1, 1, 1, 0.028), 15, Color(accent, 0.36), 1))
		rules_vbox.add_child(card)

		var margin := MarginContainer.new()
		margin.add_theme_constant_override("margin_left", 14)
		margin.add_theme_constant_override("margin_right", 13)
		margin.add_theme_constant_override("margin_top", 10)
		margin.add_theme_constant_override("margin_bottom", 10)
		card.add_child(margin)

		var content := VBoxContainer.new()
		content.add_theme_constant_override("separation", 3)
		margin.add_child(content)

		var top := HBoxContainer.new()
		top.add_theme_constant_override("separation", 8)
		content.add_child(top)
		var title := Label.new()
		title.text = String(definition["title"])
		title.add_theme_font_size_override("font_size", 14)
		title.add_theme_color_override("font_color", C_TEXT)
		title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		top.add_child(title)
		var tag := Label.new()
		tag.text = String(definition["category"])
		tag.add_theme_font_size_override("font_size", 10)
		tag.add_theme_color_override("font_color", accent)
		top.add_child(tag)
		var stack_label := Label.new()
		stack_label.text = "×%d" % engine.get_rule_stack(rule_id)
		stack_label.add_theme_font_size_override("font_size", 12)
		stack_label.add_theme_color_override("font_color", accent)
		top.add_child(stack_label)

		var description := Label.new()
		description.text = String(definition["desc"])
		description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		description.add_theme_font_size_override("font_size", 11)
		description.add_theme_color_override("font_color", C_MUTED)
		content.add_child(description)

		if rule_id == "second_wind":
			var rescue := Label.new()
			rescue.text = "可用救场 %d 次" % engine.rescue_charges
			rescue.add_theme_font_size_override("font_size", 10)
			rescue.add_theme_color_override("font_color", C_CORAL)
			content.add_child(rescue)

	rules_empty_label.visible = acquired_ids.is_empty()


func _show_reward() -> void:
	if engine.phase != RunEngine.PHASE_REWARD:
		return
	_play_sfx("reward")
	_refresh_ui()
	reward_title.text = "得分抵达 %s · 规则裂变" % _format_number(engine.score)
	reward_subtitle.text = "选择将永久加入本局构筑；下一条词条阈值会在选取后更新。"

	for i in reward_buttons.size():
		var card := reward_buttons[i]
		var refs: Dictionary = reward_refs[i]
		if i >= engine.pending_choices.size():
			card.visible = false
			continue
		card.visible = true
		var definition := engine.get_rule(String(engine.pending_choices[i]))
		var accent := Color(String(definition["accent"]))
		_refs_set_text(refs, "index", "0%d" % (i + 1))
		_refs_set_text(refs, "category", String(definition["category"]))
		_refs_set_text(refs, "title", String(definition["title"]))
		_refs_set_text(refs, "desc", String(definition["desc"]))
		var synergy := _synergy_hint(String(definition["id"]))
		_refs_set_text(refs, "note", ("联动  ·  " + synergy) if not synergy.is_empty() else ("提示  ·  " + String(definition["note"])))
		var current := engine.get_rule_stack(String(definition["id"]))
		_refs_set_text(refs, "stack", "同规则当前 %d 层 / 上限 %d" % [current, int(definition["max_stack"])])
		var accent_bar: ColorRect = refs["accent"]
		accent_bar.color = accent
		var category_label: Label = refs["category"]
		category_label.add_theme_color_override("font_color", accent)
		var title_label: Label = refs["title"]
		title_label.add_theme_color_override("font_color", C_TEXT)
		card.add_theme_stylebox_override("normal", _flat_style(Color("#131F2E"), 20, Color(accent, 0.44), 1, Color(0, 0, 0, 0.22), 5))
		card.add_theme_stylebox_override("hover", _flat_style(Color("#19283A"), 20, accent, 2, Color(0, 0, 0, 0.3), 8))
		card.add_theme_stylebox_override("pressed", _flat_style(Color("#101A27"), 20, accent, 2))

	reward_overlay.visible = true
	reward_overlay.modulate.a = 0.0
	if overlay_tween != null and overlay_tween.is_valid():
		overlay_tween.kill()
	overlay_tween = create_tween()
	overlay_tween.set_parallel(true)
	overlay_tween.tween_property(reward_overlay, "modulate:a", 1.0, 0.18)
	for card in reward_buttons:
		if card.visible:
			card.pivot_offset = card.size / 2.0
			card.scale = Vector2(0.97, 0.97)
			overlay_tween.tween_property(card, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _show_game_over() -> void:
	_play_sfx("game_over")
	var is_record := false
	var new_achievements: Array[String] = []
	if not run_recorded:
		run_ended_ms = Time.get_ticks_msec()
		runs_played += 1
		is_record = int(engine.score) > best_score
		best_score = maxi(best_score, int(engine.score))
		best_rule_count = maxi(best_rule_count, int(engine.rewards_selected))
		best_cascade_record = maxi(best_cascade_record, int(engine.best_cascade))
		new_achievements = _unlock_achievements()
		run_recorded = true
		_save_record()
	_refresh_ui()

	game_over_score.text = _format_number(engine.score)
	if is_record:
		game_over_best.text = "新纪录 · 最高 %s" % _format_number(best_score)
	elif int(engine.score) == best_score and best_score > 0:
		game_over_best.text = "追平最高 %s" % _format_number(best_score)
	elif best_score <= 0:
		game_over_best.text = "等待首个得分记录"
	else:
		game_over_best.text = "距纪录 %s 分" % _format_number(maxi(0, best_score - int(engine.score)))
	game_over_rank.text = _run_rank()
	game_over_duration.text = "第 %d 局 · 用时 %s" % [runs_played, _format_duration(_current_elapsed_msec())]
	game_over_stats.text = "%d 次连线   ·   最高级联 ×%d   ·   最高同时 %d 线" % [
		engine.lines_cleared, engine.best_cascade, engine.best_simultaneous
	]

	var build_parts: Array[String] = []
	for definition in RunEngine.RULES:
		var rule_id := String(definition["id"])
		var stack := engine.get_rule_stack(rule_id)
		if stack > 0:
			build_parts.append("%s ×%d" % [String(definition["title"]), stack])
	if build_parts.size() > 5:
		build_parts = build_parts.slice(0, 5)
		build_parts.append("等 %d 条" % engine.rewards_selected)
	game_over_rules.text = "  ·  ".join(build_parts) if not build_parts.is_empty() else "未获得词条"
	if not new_achievements.is_empty():
		game_over_achievement.text = "新成就 · %s   (%d/%d)" % [" / ".join(new_achievements), unlocked_achievements.size(), ACHIEVEMENTS.size()]
	elif unlocked_achievements.size() >= ACHIEVEMENTS.size():
		game_over_achievement.text = "全成就达成 · %d / %d" % [unlocked_achievements.size(), ACHIEVEMENTS.size()]
	else:
		game_over_achievement.text = "成就收集 %d / %d · 下一局继续解锁" % [unlocked_achievements.size(), ACHIEVEMENTS.size()]

	if run_ended_ms == 0:
		run_ended_ms = Time.get_ticks_msec()
	game_over_overlay.visible = true
	game_over_overlay.modulate.a = 0.0
	if overlay_tween != null and overlay_tween.is_valid():
		overlay_tween.kill()
	overlay_tween = create_tween()
	overlay_tween.set_parallel(true)
	overlay_tween.tween_property(game_over_overlay, "modulate:a", 1.0, 0.24)
	restart_button.pivot_offset = restart_button.size / 2.0
	restart_button.scale = Vector2(0.95, 0.95)
	overlay_tween.tween_property(restart_button, "scale", Vector2.ONE, 0.28).set_delay(0.08).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _animate_place_result(index: int, result: Dictionary) -> void:
	if index >= 0 and index < cell_buttons.size():
		var clicked := cell_buttons[index]
		clicked.pivot_offset = clicked.size / 2.0
		clicked.scale = Vector2(0.86, 0.86)
		var tween := create_tween()
		tween.tween_property(clicked, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	var resolution: Dictionary = result.get("resolution", engine.last_resolution)
	if not resolution.is_empty():
		var gain := int(resolution.get("score_gain", 0))
		if gain > 0:
			_animate_score(gain)
		var lines: Array = resolution.get("lines", [])
		if not lines.is_empty():
			_play_sfx("match")
			_shake_board()
			_flash_match_lines(lines)
		var results: Array = resolution.get("results", [])
		for result_cell in results:
			_pulse_cell(int(result_cell["index"]), 0.06)
		var rescue_index := -1
		for event in engine.turn_events:
			if String(event.get("kind", "")) == "rescue":
				rescue_index = int(event.get("index", -1))
		if rescue_index >= 0:
			_pulse_cell(rescue_index, 0.15)


func _animate_score(gain: int) -> void:
	score_gain_label.text = "+" + _format_number(gain)
	score_gain_label.position = Vector2(142, 238)
	score_gain_label.modulate = Color(1, 1, 1, 0)
	if score_tween != null and score_tween.is_valid():
		score_tween.kill()
	score_tween = create_tween()
	score_tween.set_parallel(true)
	score_tween.tween_property(score_gain_label, "modulate:a", 1.0, 0.12)
	score_tween.tween_property(score_gain_label, "position:y", 226.0, 0.55).set_ease(Tween.EASE_OUT)
	score_tween.tween_property(score_gain_label, "modulate:a", 0.0, 0.45).set_delay(0.45)
	score_label.scale = Vector2(1.08, 1.08)
	score_tween.tween_property(score_label, "scale", Vector2.ONE, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pulse_pending_tile() -> void:
	if pending_tween != null and pending_tween.is_valid():
		pending_tween.kill()
	pending_panel.scale = Vector2(0.93, 0.93)
	pending_tween = create_tween()
	pending_tween.tween_property(pending_panel, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _pulse_cell(index: int, delay: float) -> void:
	if index < 0 or index >= cell_buttons.size():
		return
	var cell := cell_buttons[index]
	cell.pivot_offset = cell.size / 2.0
	cell.scale = Vector2(0.82, 0.82)
	var tween := create_tween()
	tween.tween_interval(delay)
	tween.tween_property(cell, "scale", Vector2.ONE, 0.34).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _shake_board() -> void:
	if board_shake_tween != null and board_shake_tween.is_valid():
		board_shake_tween.kill()
	board_panel.position = Vector2(344, 110)
	board_shake_tween = create_tween()
	board_shake_tween.tween_property(board_panel, "position", Vector2(348, 110), 0.035)
	board_shake_tween.tween_property(board_panel, "position", Vector2(341, 110), 0.045)
	board_shake_tween.tween_property(board_panel, "position", Vector2(346, 110), 0.045)
	board_shake_tween.tween_property(board_panel, "position", Vector2(344, 110), 0.07)


func _flash_match_lines(lines: Array) -> void:
	var colors: Array[Color] = [C_GOLD, C_MINT, C_BLUE, C_PURPLE, C_CORAL]
	var seen: Dictionary = {}
	for i in lines.size():
		var line: Dictionary = lines[i]
		var signature := str(line.get("cells", []))
		if seen.has(signature):
			continue
		seen[signature] = true
		var line_node := Line2D.new()
		var points := PackedVector2Array()
		for cell_index in line.get("cells", []):
			var row := int(cell_index) / 3
			var col := int(cell_index) % 3
			points.append(Vector2(22 + col * 140 + 64, 66 + row * 140 + 64))
		line_node.points = points
		line_node.width = 4.0
		line_node.default_color = Color(colors[i % colors.size()], 0.92)
		line_node.antialiased = true
		line_node.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line_node.end_cap_mode = Line2D.LINE_CAP_ROUND
		line_node.z_index = 12
		board_panel.add_child(line_node)
		var tween := create_tween()
		tween.tween_interval(0.18)
		tween.tween_property(line_node, "modulate:a", 0.0, 0.38)
		tween.tween_callback(line_node.queue_free)


func _set_status_from_resolution(result: Dictionary) -> void:
	if not bool(result.get("ok", false)):
		return
	var resolution: Dictionary = result.get("resolution", {})
	var lines := int(resolution.get("lines_cleared", 0))
	var gain := int(resolution.get("score_gain", 0))
	var cascade := int(resolution.get("cascades", 0))
	var rescued := false
	for event in engine.turn_events:
		if String(event.get("kind", "")) == "rescue":
			rescued = true
	if rescued:
		_set_status("一线生机触发 · 移除最低块，继续布局")
	elif lines > 0:
		var text := "%d 条线消融  ·  +%s 分" % [lines, _format_number(gain)]
		if cascade > 1:
			text += "  ·  级联 ×%d" % cascade
		_set_status(text)
	elif gain > 0:
		_set_status("未成线  ·  词条额外 +%s 分" % _format_number(gain))
	else:
		_set_status("未成线  ·  棋盘还留着空间")


func _set_status(text: String) -> void:
	if board_status_label != null:
		board_status_label.text = text


func _refs_set_text(refs: Dictionary, key: String, text: String) -> void:
	var label: Label = refs[key]
	label.text = text


func _make_panel(parent: Node, rect: Rect2, bg: Color, radius: int, border: Color = Color.TRANSPARENT, border_width: int = 0, shadow: int = 0) -> Panel:
	var panel := Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.add_theme_stylebox_override("panel", _flat_style(bg, radius, border, border_width, Color(0, 0, 0, 0.22), shadow))
	parent.add_child(panel)
	return panel


func _add_label(parent: Node, text: String, pos: Vector2, label_size: Vector2, font_size: int, color: Color, alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var label := Label.new()
	label.text = text
	label.position = pos
	label.size = label_size
	label.custom_minimum_size = label_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(label)
	return label


func _flat_style(bg: Color, radius: int, border: Color = Color.TRANSPARENT, border_width: int = 0, shadow_color: Color = Color.TRANSPARENT, shadow_size: int = 0) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	style.border_width_left = border_width
	style.border_width_top = border_width
	style.border_width_right = border_width
	style.border_width_bottom = border_width
	style.shadow_color = shadow_color
	style.shadow_size = shadow_size
	style.shadow_offset = Vector2(0, maxi(2, shadow_size / 2))
	style.anti_aliasing = true
	return style


func _value_color(value: int) -> Color:
	if value == RunEngine.WILD_VALUE:
		return C_GOLD
	match value:
		1:
			return C_CORAL
		2:
			return C_GOLD
		3:
			return C_MINT
		4:
			return C_BLUE
		5:
			return C_PURPLE
		6:
			return Color("#F09AA5")
		7:
			return Color("#62C4C8")
		8:
			return Color("#E5A45E")
	return Color("#D9CC75").lerp(Color("#F0E4A8"), minf(0.45, float(value - 8) * 0.04))


func _format_number(value: int) -> String:
	var raw := str(value)
	var output := ""
	var counter := 0
	for i in range(raw.length() - 1, -1, -1):
		output = raw[i] + output
		counter += 1
		if counter % 3 == 0 and i > 0:
			output = "," + output
	return output


func _format_duration(msec: int) -> String:
	var seconds := maxi(0, msec / 1000)
	return "%02d:%02d" % [seconds / 60, seconds % 60]


func _current_elapsed_msec() -> int:
	if run_ended_ms > 0:
		return run_ended_ms - run_started_ms
	return Time.get_ticks_msec() - run_started_ms


func _header_button(button_position: Vector2, button_text: String) -> Button:
	var button := Button.new()
	button.position = button_position
	button.size = Vector2(88, 32)
	button.text = button_text
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", C_MUTED)
	button.add_theme_color_override("font_hover_color", C_GOLD)
	button.add_theme_stylebox_override("normal", _flat_style(Color(1, 1, 1, 0.025), 10, Color(1, 1, 1, 0.075), 1))
	button.add_theme_stylebox_override("hover", _flat_style(Color(1, 1, 1, 0.055), 10, Color(C_GOLD, 0.55), 1))
	button.add_theme_stylebox_override("pressed", _flat_style(Color(1, 1, 1, 0.02), 10, C_GOLD, 1))
	ui_root.add_child(button)
	return button


func _toggle_fullscreen() -> void:
	var current_mode := DisplayServer.window_get_mode()
	if current_mode == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(Vector2i(1280, 720))
		fullscreen_button.text = "全屏"
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_button.text = "窗口"
	_layout_content()


func _toggle_sound() -> void:
	sound_enabled = not sound_enabled
	_apply_audio_setting()
	_save_record()


func _apply_audio_setting() -> void:
	AudioServer.set_bus_mute(0, not sound_enabled)
	if sound_button != null:
		sound_button.text = "声音 开" if sound_enabled else "声音 关"


func _synergy_hint(rule_id: String) -> String:
	if rule_id == "odd_tide" and engine.get_rule_stack("streak_heat") > 0:
		return "连续热度已就位，奇数节奏会被再次放大。"
	if rule_id == "high_tide" and engine.get_rule_stack("heavy_flow") > 0:
		return "高值生成会直接喂养高位回响。"
	if rule_id == "diagonal_echo" and engine.get_rule_stack("center_cross") > 0:
		return "斜线共享中心，两组倍率会相乘。"
	if rule_id == "center_cross" and (engine.get_rule_stack("diagonal_echo") > 0 or engine.get_rule_stack("result_plus") > 0):
		return "中心是主要得分与升级的交汇点。"
	if rule_id == "cascade_hymn" and engine.get_rule_stack("result_plus") > 0:
		return "更高的中心产物更容易继续触发级联。"
	if rule_id == "single_note" and engine.get_rule_stack("empty_echo") > 0:
		return "单线保留空位，留白生息会同步计分。"
	if rule_id == "wild_line" and (engine.get_rule_stack("wild_seed") > 0 or engine.get_rule_stack("wild_echo") > 0):
		return "万能块出现后，连线倍率会立即接管。"
	if rule_id == "quiet_flow" and engine.get_rule_stack("empty_echo") > 0:
		return "低值连消与空位收益共同延长牌局。"
	if rule_id == "heavy_flow" and engine.get_rule_stack("high_tide") > 0:
		return "生成值被抬高，高位倍率会持续命中。"
	if rule_id == "twin_bonus" and engine.get_rule_stack("center_cross") > 0:
		return "中心交叉常带来多线同消，额外奖励更频繁。"
	if rule_id == "streak_heat" and engine.get_rule_stack("odd_tide") > 0:
		return "奇数连击是这套构筑的主要爆发点。"
	return ""


func _run_rank() -> String:
	var build_points := int(engine.score) + int(engine.rewards_selected) * 45 + int(engine.best_cascade) * 35 + int(engine.best_simultaneous) * 25
	if int(engine.score) >= 600 or build_points >= 1000:
		return "S"
	if int(engine.score) >= 320 or build_points >= 620:
		return "A"
	if int(engine.score) >= 150 or build_points >= 300:
		return "B"
	if int(engine.score) >= 50:
		return "C"
	return "D"


func _unlock_achievements() -> Array[String]:
	var newly_unlocked: Array[String] = []
	for definition in ACHIEVEMENTS:
		var achievement_id := String(definition["id"])
		if unlocked_achievements.has(achievement_id):
			continue
		if _achievement_met(achievement_id):
			unlocked_achievements[achievement_id] = true
			newly_unlocked.append(String(definition["title"]))
	return newly_unlocked


func _achievement_met(achievement_id: String) -> bool:
	match achievement_id:
		"first_line":
			return engine.lines_cleared >= 1
		"cross_line":
			return engine.best_simultaneous >= 2
		"three_way":
			return engine.best_simultaneous >= 3
		"builder":
			return engine.rewards_selected >= 3
		"cascade":
			return engine.best_cascade >= 3
		"rescue":
			return engine.rescues_used >= 1
		"score_500":
			return engine.score >= 500
	return false


func _load_record() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_score = int(config.get_value("record", "best_score", 0))
		runs_played = int(config.get_value("record", "runs_played", 0))
		best_rule_count = int(config.get_value("record", "best_rule_count", 0))
		best_cascade_record = int(config.get_value("record", "best_cascade", 0))
		sound_enabled = bool(config.get_value("preferences", "sound_enabled", true))
		var saved_achievements = config.get_value("record", "achievements", {})
		if saved_achievements is Dictionary:
			unlocked_achievements = saved_achievements.duplicate()


func _save_record() -> void:
	var config := ConfigFile.new()
	config.set_value("record", "best_score", best_score)
	config.set_value("record", "runs_played", runs_played)
	config.set_value("record", "best_rule_count", best_rule_count)
	config.set_value("record", "best_cascade", best_cascade_record)
	config.set_value("record", "achievements", unlocked_achievements)
	config.set_value("preferences", "sound_enabled", sound_enabled)
	config.save(SAVE_PATH)


func _build_audio() -> void:
	_add_sfx("place", [440.0], 0.045, 0.22)
	_add_sfx("match", [659.25, 880.0], 0.18, 0.2)
	_add_sfx("rule", [523.25, 783.99, 1046.5], 0.32, 0.15)
	_add_sfx("reward", [392.0, 523.25, 659.25, 783.99], 0.42, 0.13)
	_add_sfx("game_over", [196.0, 146.83], 0.55, 0.16)


func _add_sfx(sfx_name: String, frequencies: Array, duration: float, volume: float) -> void:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	var frame_count := maxi(1, int(duration * SAMPLE_RATE))
	var data := PackedByteArray()
	data.resize(frame_count * 2)
	var attack_frames := maxi(1, int(SAMPLE_RATE * 0.006))
	for frame in frame_count:
		var time := float(frame) / float(SAMPLE_RATE)
		var progress := float(frame) / float(frame_count)
		var attack := minf(1.0, float(frame) / float(attack_frames))
		var envelope := attack * pow(1.0 - progress, 1.8)
		var mixed := 0.0
		for frequency in frequencies:
			mixed += sin(TAU * float(frequency) * time)
		mixed = mixed / float(frequencies.size()) * envelope * volume
		var sample_word := int(clampf(mixed, -1.0, 1.0) * 32767.0)
		if sample_word < 0:
			sample_word += 65536
		data[frame * 2] = sample_word & 0xff
		data[frame * 2 + 1] = (sample_word >> 8) & 0xff
	stream.data = data

	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = -5.0
	player.max_polyphony = 1
	add_child(player)
	sfx_players[sfx_name] = player


func _play_sfx(sfx_name: String) -> void:
	if not sfx_players.has(sfx_name):
		return
	var player: AudioStreamPlayer = sfx_players[sfx_name]
	player.stop()
	player.play()
