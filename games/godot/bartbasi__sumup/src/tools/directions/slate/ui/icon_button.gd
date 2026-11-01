extends Control
## Slate icon button: a bare icon with no container, used for the HUD
## settings button and the icon review rows. The control's rect is the full
## touch area. Active sits on a paper block; while held, a surface block
## shows behind the icon, with no scaling.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal pressed

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const IconView: GDScript = preload("res://tools/directions/slate/ui/icon_view.gd")
const Motion: GDScript = preload("res://tools/directions/ui_common/motion.gd")

var _tokens: DirectionTokens = null
var _look: int = IconView.LOOK_NORMAL
var _face_side: float = 0.0
var _icon_side: float = 0.0
var _held: bool = false
var _icon: IconView = null


## face_side is the side of the block behind the icon when active or held,
## icon_side the icon size.
func setup(tokens: DirectionTokens, icon_name: String, face_side: float, icon_side: float) -> void:
	_tokens = tokens
	_face_side = face_side
	_icon_side = icon_side
	if _icon == null:
		_icon = IconView.new()
		add_child(_icon)
	_icon.setup(tokens)
	_icon.set_icon(icon_name)
	custom_minimum_size = Vector2(maxf(face_side, tokens.num("touch_min")), maxf(face_side, tokens.num("touch_min")))
	set_look(_look)


func set_look(look: int) -> void:
	_look = look
	if _icon != null:
		_icon.set_look(look)
	_place_icon()
	queue_redraw()


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_place_icon()


func _place_icon() -> void:
	if _icon == null:
		return
	_icon.size = Vector2(_icon_side, _icon_side)
	_icon.position = (size - _icon.size) * 0.5


func _draw() -> void:
	if _tokens == null:
		return
	var block: Rect2 = Rect2((size - Vector2(_face_side, _face_side)) * 0.5, Vector2(_face_side, _face_side))
	if _look == IconView.LOOK_ACTIVE:
		draw_rect(block, _tokens.color("ink"))
	elif _held:
		draw_rect(block, _tokens.color("surface"))


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT or _tokens == null:
		return
	accept_event()
	if _look == IconView.LOOK_DISABLED:
		return
	_held = button.pressed
	queue_redraw()
	if button.pressed:
		Motion.press(self, _tokens)
	else:
		Motion.release(self, _tokens)
		if Rect2(Vector2.ZERO, size).has_point(button.position):
			pressed.emit()
