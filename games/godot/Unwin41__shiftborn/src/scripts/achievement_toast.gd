class_name AchievementToast
extends CanvasLayer
## A small "ACHIEVEMENT" card that slides in at the top right, one at a
## time, for every newly unlocked achievement.

const LAYER := 12
const SHOW_TIME := 2.4
const SLIDE_TIME := 0.2
const MARGIN := 8.0
const OFFSCREEN := 220.0

var _queue: Array[StringName] = []
var _busy: bool = false
var _panel: PanelContainer
var _title: Label


func _init() -> void:
	layer = LAYER
	process_mode = Node.PROCESS_MODE_ALWAYS
	var column := UiKit.column()
	column.add_child(UiKit.label("Achievement", UiKit.SMALL_FONT_SIZE, UiKit.MUTED_COLOR))
	_title = UiKit.label("", UiKit.SMALL_FONT_SIZE, UiKit.ACCENT_COLOR)
	column.add_child(_title)
	_panel = UiKit.panel(column)
	_panel.visible = false
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_panel)


func show_unlocked(id: StringName) -> void:
	_queue.append(id)
	if not _busy and is_inside_tree():
		_next()


func pending() -> int:
	return _queue.size()


func _next() -> void:
	if _queue.is_empty():
		_busy = false
		_panel.visible = false
		return
	_busy = true
	_title.text = Achievements.title_of(_queue.pop_front()).to_upper()
	AudioManager.play(&"card_pick")
	_panel.visible = true
	_panel.reset_size()
	var width := get_viewport().get_visible_rect().size.x
	var shown_x := width - _panel.size.x - MARGIN
	_panel.position = Vector2(width + OFFSCREEN, MARGIN + 28.0)
	var tween := create_tween().set_ignore_time_scale()
	tween.tween_property(_panel, ^"position:x", shown_x, SLIDE_TIME)
	tween.tween_interval(SHOW_TIME)
	tween.tween_property(_panel, ^"position:x", width + OFFSCREEN, SLIDE_TIME)
	tween.tween_callback(_next)
