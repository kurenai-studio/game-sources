# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name GateTray
extends BattlePanel
## The gate strip (RULES 7.1, 7.2, 7.6): how many gates are in hand, a gate to drag
## onto a socket, and the sentence that says gates are locked during a wave. Gate
## refusals (BattleText.refusal) show in its message box. A gate dragged from here
## is reported with global positions; the battle screen runs the drag.
##
## The strip is hidden on a level with no gates. In portrait it is a small chip in the
## HUD's first row (set_chip): the gate picture and the number in hand, with a lock while
## a wave runs. The same tap and drag work from it. The sentences stay in the strip of the
## landscape side panel, on the level card and in Info.

signal drag_began(global_point: Vector2)
signal drag_moved(global_point: Vector2)
signal drag_ended(global_point: Vector2)

## The chip is at least 48 dp wide and tall (150 px at 3.14 px per dp, on the Fold5 cover).
const CHIP_WIDTH: float = 152.0

var icon: GlyphIcon
var title_label: Label
var detail_label: Label
var count_label: Label
var lock_mark: TextureRect
var chip: bool = false

var _text_box: VBoxContainer
var _dragging: bool = false
var _pressing: bool = false
var _press_at: Vector2 = Vector2.ZERO
var _state: String = ""
## The sentence for the strip as it is now. A tap on the chip shows it (item 6).
var _sentence: String = ""
var _down: bool = false
var _travel: float = 0.0


func _init() -> void:
	super()
	var row: HBoxContainer = HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override(&"separation", 18)
	icon = GlyphIcon.new(72.0).show_glyph(&"gate")
	row.add_child(icon)
	var text: VBoxContainer = VBoxContainer.new()
	_text_box = text
	text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.add_theme_constant_override(&"separation", 0)
	title_label = UiKit.heading("")
	text.add_child(title_label)
	detail_label = UiKit.label("", &"SoftLabel")
	text.add_child(detail_label)
	row.add_child(text)
	count_label = UiKit.heading("0")
	count_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	count_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	count_label.visible = false
	row.add_child(count_label)
	lock_mark = TextureRect.new()
	lock_mark.texture = IconTex.make(&"lock", 64)
	lock_mark.custom_minimum_size = Vector2(40.0, 40.0)
	lock_mark.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	lock_mark.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	lock_mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	lock_mark.modulate = Palette.TEXT_SOFT
	lock_mark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock_mark.visible = false
	row.add_child(lock_mark)
	column.add_child(row)
	column.add_child(feedback_box)
	visible = false


## The explaining line shows in the roomy side panel. In portrait every pixel of height
## goes to the map, so the strip is one line.
func set_wide(value: bool) -> void:
	super(value)
	detail_label.visible = not value


## The small chip of the portrait HUD (true) or the strip with its sentences (false).
func set_chip(value: bool) -> void:
	chip = value
	_text_box.visible = not value
	count_label.visible = value
	if value:
		add_theme_stylebox_override(&"panel", UiKit.box(Palette.PANEL_RAISED, Palette.PANEL_EDGE, 4, UiTheme.RADIUS, 10))
		custom_minimum_size = Vector2(CHIP_WIDTH, Layout.MIN_TOUCH)
		size_flags_vertical = Control.SIZE_FILL
		size_flags_horizontal = Control.SIZE_SHRINK_END
	else:
		custom_minimum_size = Vector2.ZERO
		size_flags_vertical = Control.SIZE_FILL
		size_flags_horizontal = Control.SIZE_FILL
		set_tight(not wide)
	_show_chip_marks()


## The number in hand, and the lock while gates cannot move.
func _show_chip_marks() -> void:
	var locked: bool = chip and battle != null and battle.phase != Battle.Phase.BUILD
	lock_mark.visible = locked
	count_label.visible = chip and not locked
	if battle != null:
		count_label.text = str(battle.gates_in_hand)


func refresh() -> void:
	if battle == null:
		return
	var in_hand: int = battle.gates_in_hand
	var placed: int = battle.gates.size()
	visible = in_hand + placed > 0
	var text: String
	var detail: String
	if battle.phase != Battle.Phase.BUILD:
		text = "Gates: locked"
		detail = BattleText.refusal(&"gates_locked")
	elif in_hand > 0:
		text = "Gates: %d in hand" % in_hand
		detail = "Drag one onto a marked road, or tap a marked road."
	else:
		text = "Gates: all placed"
		detail = "Drag a gate to move it. Tap a gate to take it back."
	_show_chip_marks()
	_sentence = detail
	var state: String = "%s|%s" % [text, detail]
	if state == _state:
		return
	_state = state
	title_label.text = text
	detail_label.text = detail


## True while a gate drag started here is going on.
func is_dragging() -> bool:
	return _dragging


## Drops a drag in progress without reporting an end (a layout change).
func cancel_drag() -> void:
	_dragging = false
	_pressing = false
	_down = false


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_pressing = _can_drag()
			_dragging = false
			_down = true
			_travel = 0.0
			_press_at = _global_of(button.position)
		else:
			var tapped: bool = _down and not _dragging and _travel < TapButton.DEADZONE
			if _dragging:
				_dragging = false
				drag_ended.emit(_global_of(button.position))
			_pressing = false
			_down = false
			if tapped:
				tap()
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _down:
		var at: Vector2 = _global_of(motion.position)
		_travel = maxf(_travel, at.distance_to(_press_at))
		if _pressing:
			if not _dragging and at.distance_to(_press_at) >= TapButton.DEADZONE:
				_dragging = true
				drag_began.emit(at)
			if _dragging:
				drag_moved.emit(at)


## A tap on the portrait chip shows its sentence in the dock, because the chip has no
## words of its own. In the landscape strip the sentence is already on screen.
func tap() -> void:
	if chip and not _sentence.is_empty():
		show_feedback(_sentence)


func _can_drag() -> bool:
	return battle != null and battle.phase == Battle.Phase.BUILD and battle.gates_in_hand > 0


func _global_of(local: Vector2) -> Vector2:
	return get_global_transform() * local


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED or what == NOTIFICATION_EXIT_TREE:
		_dragging = false
		_pressing = false
		_down = false
