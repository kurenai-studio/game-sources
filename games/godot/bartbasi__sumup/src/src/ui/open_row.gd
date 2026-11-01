extends PanelContainer
## A row that opens a screen (DESIGN_SYSTEM.md 7.7 and 7.11): Settings' About
## row and About's license rows.
## - row_height tall and never less than touch_min (2.7, QA6-05); the whole
##   row is the touch target.
## - On the left the title in the body role, with an optional detail line
##   under it in RowDetailLabel (names keep their capitals, 3.4); on the right
##   the chevron icon, icon_hud box, ink_muted.
## - It draws the Theme's RowButton look: normal at rest, pressed while a
##   finger is down on it.
## - It opens only on a tap: finger down and up on the row, moving less than
##   the 24 px deadzone, with no scroll in between. It never accepts an event,
##   so a drag that starts on it reaches the ScrollContainer and scrolls.
## Only mouse events are read: on a phone Godot sends each touch as an
## emulated mouse event too, so a touch counts once (QA6-01).

signal tapped()

const UiParts: GDScript = preload("res://src/ui/ui_parts.gd")
## DESIGN_SYSTEM.md 7.9: the reading screen scroll deadzone (8 dp).
const DEADZONE: float = 24.0

var _skin: SkinData = null
var _title: Label = null
var _detail: Label = null
var _chevron: SkinIcon = null
var _down: bool = false
var _down_at: Vector2 = Vector2.ZERO
var _scroll: ScrollContainer = null
var _scroll_at: int = 0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	size_flags_horizontal = Control.SIZE_EXPAND_FILL


func setup(skin: SkinData, title: String, detail: String = "") -> void:
	_skin = skin
	UiParts.clear(self)
	custom_minimum_size = Vector2(0.0, maxf(skin.num(&"row_height"), skin.num(&"touch_min")))
	var line: HBoxContainer = UiParts.hbox(skin.num(&"space_s"))
	add_child(line)
	var texts: VBoxContainer = UiParts.vbox(0.0)
	texts.alignment = BoxContainer.ALIGNMENT_CENTER
	texts.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(texts)
	_title = UiParts.paragraph(skin, &"BodyLabel", title, HORIZONTAL_ALIGNMENT_LEFT)
	_title.name = "Title"
	texts.add_child(_title)
	_detail = null
	if not detail.is_empty():
		_detail = UiParts.name_label(skin, &"RowDetailLabel", detail)
		_detail.name = "Detail"
		_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		texts.add_child(_detail)
	_chevron = UiKit.make_icon(skin)
	_chevron.name = "Chevron"
	var side: float = skin.num(&"icon_hud")
	_chevron.custom_minimum_size = Vector2(side, side)
	_chevron.size = Vector2(side, side)
	_chevron.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_chevron.set_icon(&"chevron")
	_chevron.set_color(skin.color(&"ink_muted"))
	line.add_child(_chevron)
	_apply_look()


func title_text() -> String:
	return _title.text if _title != null else ""


func detail_text() -> String:
	return _detail.text if _detail != null else ""


## True while a finger is down on the row (the pressed look). For tests.
func is_held() -> bool:
	return _down


## Drops a press already on the row, so its release does nothing. For a
## screen that hides the row while a finger may be on it.
func cancel_hold() -> void:
	_cancel()


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button != null and button.button_index == MOUSE_BUTTON_LEFT:
		if button.pressed:
			_press(button.global_position)
		else:
			_release(button.global_position)
		return
	var motion: InputEventMouseMotion = event as InputEventMouseMotion
	if motion != null and _down and motion.global_position.distance_to(_down_at) > DEADZONE:
		_cancel()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_SCROLL_BEGIN, NOTIFICATION_VISIBILITY_CHANGED:
			_cancel()
		NOTIFICATION_ENTER_TREE, NOTIFICATION_THEME_CHANGED:
			_apply_look()


## The Theme's RowButton look for the current state, as this panel's box.
## Set only when it changes, since setting it notifies a theme change.
func _apply_look() -> void:
	if not is_inside_tree():
		return
	var style: StyleBox = get_theme_stylebox(&"pressed" if _down else &"normal", &"RowButton")
	if style != null and get_theme_stylebox(&"panel") != style:
		add_theme_stylebox_override(&"panel", style)


func _press(at: Vector2) -> void:
	_down = true
	_down_at = at
	_scroll = _find_scroll()
	_scroll_at = _scroll.scroll_vertical if _scroll != null else 0
	_apply_look()


func _release(at: Vector2) -> void:
	if not _down:
		return
	var still: bool = at.distance_to(_down_at) <= DEADZONE
	var not_scrolled: bool = _scroll == null or not is_instance_valid(_scroll) or _scroll.scroll_vertical == _scroll_at
	_cancel()
	if still and not_scrolled:
		tapped.emit()


func _cancel() -> void:
	if _down:
		_down = false
		_apply_look()


func _find_scroll() -> ScrollContainer:
	var node: Node = get_parent()
	while node != null:
		if node is ScrollContainer:
			return node as ScrollContainer
		node = node.get_parent()
	return null
