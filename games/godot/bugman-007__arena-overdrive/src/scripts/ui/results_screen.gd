class_name ResultsScreen
extends Control
## End-of-run results with animated stat count-ups, unlocked achievements and rewards.

signal retry_requested
signal menu_requested

var _panel: PanelContainer
var _grid: GridContainer
var _title: Label
var _subtitle: Label
var _ach: VBoxContainer
var _retry: Button


func _ready() -> void:
	UiKit.full_rect(self)
	process_mode = Node.PROCESS_MODE_ALWAYS
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.82)
	UiKit.full_rect(dim)
	add_child(dim)
	var center := CenterContainer.new()
	UiKit.full_rect(center)
	add_child(center)
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(760, 0)
	center.add_child(_panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 14)
	_panel.add_child(v)
	_title = UiKit.label("RUN_OVER", "TitleLabel", 58, HORIZONTAL_ALIGNMENT_CENTER)
	_title.add_theme_color_override("font_color", UiTheme.ACCENT_2)
	v.add_child(_title)
	_subtitle = UiKit.label("", "AccentLabel", 20, HORIZONTAL_ALIGNMENT_CENTER)
	v.add_child(_subtitle)
	_grid = GridContainer.new()
	_grid.columns = 4
	_grid.add_theme_constant_override("h_separation", 26)
	_grid.add_theme_constant_override("v_separation", 10)
	v.add_child(_grid)
	_ach = VBoxContainer.new()
	v.add_child(_ach)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 20)
	v.add_child(row)
	_retry = UiKit.button("RETRY", Vector2(260, 58))
	_retry.pressed.connect(func() -> void: retry_requested.emit())
	var menu := UiKit.button("MAIN_MENU", Vector2(260, 58))
	menu.pressed.connect(func() -> void: menu_requested.emit())
	row.add_child(_retry)
	row.add_child(menu)
	UiKit.focus_chain([_retry, menu], true)
	hide()


static func format_time(seconds: float) -> String:
	var s := int(seconds)
	return "%d:%02d" % [s / 60, s % 60]


func present(results: Dictionary, achievements: Array[StringName], new_best: bool) -> void:
	for c in _grid.get_children():
		c.queue_free()
	for c in _ach.get_children():
		c.queue_free()
	_subtitle.text = tr("RESULTS_SUBTITLE") % [tr(String(results.get("character_name", ""))), int(results.get("wave", 0))]
	var rows := [
		["STAT_SCORE", int(results.get("score", 0)), UiTheme.ACCENT],
		["STAT_KILLS", int(results.get("kills", 0)), UiTheme.TEXT],
		["STAT_LEVEL", int(results.get("level", 1)), UiTheme.TEXT],
		["STAT_MAX_COMBO", int(results.get("max_combo", 0)), UiTheme.ACCENT_2],
		["STAT_DAMAGE", int(results.get("damage_dealt", 0)), UiTheme.TEXT],
		["STAT_BOSSES", int(results.get("bosses", 0)), UiTheme.TEXT],
		["STAT_COINS", int(results.get("coins", 0)), UiTheme.GOLD],
		["STAT_TIME", -1, UiTheme.TEXT],
	]
	var i := 0
	for r in rows:
		_grid.add_child(UiKit.label(r[0], "MutedLabel", 17))
		var value := UiKit.label("0", "HudLabel", 24)
		value.add_theme_color_override("font_color", r[2])
		value.custom_minimum_size = Vector2(120, 0)
		_grid.add_child(value)
		if int(r[1]) < 0:
			value.text = format_time(float(results.get("time", 0.0)))
		else:
			var target: int = r[1]
			var tw := value.create_tween().set_ignore_time_scale(true)
			tw.tween_method(func(x: float) -> void: value.text = str(int(x)), 0.0, float(target), 0.9).set_delay(0.2 + i * 0.06).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		i += 1
	if new_best:
		var best := UiKit.label("NEW_BEST", "GoldLabel", 24, HORIZONTAL_ALIGNMENT_CENTER)
		_ach.add_child(best)
		UiKit.animate_in(best, 0.9, 0.5)
	for id in achievements:
		var l := UiKit.label("★  " + tr(Achievements.name_key(id)), "GoldLabel", 18, HORIZONTAL_ALIGNMENT_CENTER)
		_ach.add_child(l)
	show()
	UiKit.animate_in(_panel, 0.0, 0.85)
	_retry.grab_focus.call_deferred()
