class_name AchievementsPanel
extends VBoxContainer
## Title-screen page: every achievement, unlocked ones
## in color, locked ones dimmed. Back returns to the menu.

signal back_pressed

const ROW_WIDTH := 400.0
const ROW_GAP := 16
const LOCKED_COLOR := Color(0.45, 0.43, 0.52)

var _rows: int = 0
var _back_button: Button


func _init() -> void:
	var progress := Progress.current()
	add_theme_constant_override(&"separation", 3)
	alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(UiKit.label("Achievements", UiKit.HEADER_FONT_SIZE, UiKit.ACCENT_COLOR))
	add_child(UiKit.label("%d/%d unlocked" % [progress.unlocked.size(), Achievements.LIST.size()], UiKit.SMALL_FONT_SIZE, UiKit.MUTED_COLOR))
	for entry in Achievements.LIST:
		add_child(_row(entry, progress.is_unlocked(entry.id)))
		_rows += 1
	_back_button = UiKit.button("Back")
	_back_button.pressed.connect(func() -> void: back_pressed.emit())
	var center := CenterContainer.new()
	center.add_child(_back_button)
	add_child(center)


func row_count() -> int:
	return _rows


func focus_first() -> void:
	if _back_button.is_inside_tree():
		UiKit.grab_focus_quietly(_back_button)


func _row(entry: Dictionary, unlocked: bool) -> Control:
	var row := HBoxContainer.new()
	row.custom_minimum_size.x = ROW_WIDTH
	row.add_theme_constant_override(&"separation", ROW_GAP)
	var title := UiKit.label(entry.title, UiKit.SMALL_FONT_SIZE, UiKit.ACCENT_COLOR if unlocked else LOCKED_COLOR)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(title)
	var text := UiKit.label(entry.text, UiKit.SMALL_FONT_SIZE, UiKit.TEXT_COLOR if unlocked else LOCKED_COLOR)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(text)
	return row
