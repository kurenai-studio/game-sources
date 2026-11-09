class_name ResultsScreen
extends CanvasLayer
## End-of-run screen: win or death, time, kills, level and every upgrade
## taken with its level. Retry restarts the run, Main Menu leaves it.

signal retry_requested
signal main_menu_requested

const LAYER := 15
const ICON_SIZE := Vector2(16, 16)
const UPGRADE_COLUMNS := 8
const WIN_COLOR := Color(0.55, 0.95, 0.55)
const LOSS_COLOR := Color(1.0, 0.4, 0.4)
## Buttons ignore input this long after opening, so a gameplay press at
## the moment of death does not retry blindly.
const INPUT_GRACE := 0.4

var _title: Label
var _stats: Label
var _score: Label
var _score_lines: Label
var _new_best: Label
var _upgrades_header: Label
var _upgrade_grid: GridContainer
var _retry_button: Button
var _buttons: Array[Button] = []


static func title_text(won: bool) -> String:
	return "YOU WIN" if won else "YOU DIED"


static func stats_text(seconds: float, kills: int, level: int) -> String:
	return ("Time %s   Kills %d   Level %d" % [Run.format_time(seconds), kills, level]).to_upper()


func _init() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()
	visible = false


## Fills and shows the screen. [param levels] holds each upgrade's level,
## in the same order as [param upgrades].
func open(won: bool, seconds: float, kills: int, level: int, upgrades: Array[Upgrade], levels: Array[int]) -> void:
	_title.text = title_text(won)
	_title.add_theme_color_override(&"font_color", WIN_COLOR if won else LOSS_COLOR)
	_stats.text = stats_text(seconds, kills, level)
	_fill_upgrades(upgrades, levels)
	visible = true
	if not is_inside_tree():
		return
	_set_buttons_disabled(true)
	get_tree().create_timer(INPUT_GRACE, true).timeout.connect(_accept_input)


## The run's score, one line per part, and NEW BEST when it is a record.
func show_score(score: int, lines: PackedStringArray, new_best: bool) -> void:
	_score.text = "SCORE %d" % score
	_score_lines.text = "\n".join(lines)
	_new_best.visible = new_best


func score_text() -> String:
	return _score.text


func is_new_best_shown() -> bool:
	return _new_best.visible


func title() -> String:
	return _title.text


func upgrade_slot_count() -> int:
	return _upgrade_grid.get_child_count()


func _fill_upgrades(upgrades: Array[Upgrade], levels: Array[int]) -> void:
	for child in _upgrade_grid.get_children():
		_upgrade_grid.remove_child(child)
		child.queue_free()
	for i in upgrades.size():
		var level := levels[i] if i < levels.size() else 1
		_upgrade_grid.add_child(_upgrade_slot(upgrades[i], level))
	_upgrades_header.text = ("Upgrades" if not upgrades.is_empty() else "No upgrades").to_upper()


func _upgrade_slot(upgrade: Upgrade, level: int) -> Control:
	var slot := VBoxContainer.new()
	slot.add_theme_constant_override(&"separation", 1)
	slot.tooltip_text = upgrade.title
	var icon := TextureRect.new()
	icon.texture = upgrade.icon
	icon.custom_minimum_size = ICON_SIZE
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	slot.add_child(icon)
	slot.add_child(UiKit.label(str(level), UiKit.SMALL_FONT_SIZE, UiKit.ACCENT_COLOR))
	return slot


func _accept_input() -> void:
	_set_buttons_disabled(false)
	UiKit.grab_focus_quietly(_retry_button)


func _set_buttons_disabled(disabled: bool) -> void:
	for button in _buttons:
		button.disabled = disabled


func _build() -> void:
	var column := UiKit.column()
	_title = UiKit.label("", UiKit.TITLE_FONT_SIZE, LOSS_COLOR)
	column.add_child(_title)
	_stats = UiKit.label("")
	column.add_child(_stats)
	_score = UiKit.label("", UiKit.HEADER_FONT_SIZE, UiKit.ACCENT_COLOR)
	column.add_child(_score)
	_new_best = UiKit.label("New best!", UiKit.SMALL_FONT_SIZE, WIN_COLOR)
	_new_best.visible = false
	column.add_child(_new_best)
	_score_lines = UiKit.label("", UiKit.SMALL_FONT_SIZE, UiKit.MUTED_COLOR)
	column.add_child(_score_lines)
	_upgrades_header = UiKit.label("Upgrades", UiKit.SMALL_FONT_SIZE, UiKit.MUTED_COLOR)
	column.add_child(_upgrades_header)
	var grid_center := CenterContainer.new()
	_upgrade_grid = GridContainer.new()
	_upgrade_grid.columns = UPGRADE_COLUMNS
	_upgrade_grid.add_theme_constant_override(&"h_separation", UiKit.SEPARATION)
	_upgrade_grid.add_theme_constant_override(&"v_separation", UiKit.SEPARATION)
	grid_center.add_child(_upgrade_grid)
	column.add_child(grid_center)
	var row := HBoxContainer.new()
	row.add_theme_constant_override(&"separation", UiKit.SEPARATION)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	_retry_button = UiKit.button("Retry")
	_retry_button.pressed.connect(func() -> void: retry_requested.emit())
	row.add_child(_retry_button)
	var menu_button := UiKit.button("Main Menu")
	menu_button.pressed.connect(func() -> void: main_menu_requested.emit())
	row.add_child(menu_button)
	_buttons = [_retry_button, menu_button]
	column.add_child(row)
	add_child(UiKit.dimmed_center(UiKit.panel(column)))
