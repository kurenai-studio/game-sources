extends Control
## Gumdrop icon button: an icon on a raised candy squircle, used for the
## HUD settings button and the icon review rows. The control's rect is the
## touch area; the squircle is centered in it.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal pressed

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const IconView: GDScript = preload("res://tools/directions/gumdrop/ui/icon_view.gd")
const Candy: GDScript = preload("res://tools/directions/gumdrop/ui/candy.gd")
const Motion: GDScript = preload("res://tools/directions/ui_common/motion.gd")

var _tokens: DirectionTokens = null
var _look: int = IconView.LOOK_NORMAL
var _face_side: float = 0.0
var _icon_side: float = 0.0
var _styles: Array[StyleBoxFlat] = []
var _icon: IconView = null


## face_side is the width of the squircle face, icon_side the icon size.
func setup(tokens: DirectionTokens, icon_name: String, face_side: float, icon_side: float) -> void:
	_tokens = tokens
	_face_side = face_side
	_icon_side = icon_side
	var radius: float = tokens.num("button_radius") * face_side / tokens.num("touch_min")
	_styles = [
		Candy.style(tokens, Candy.LOOK_NORMAL, radius),
		Candy.style(tokens, Candy.LOOK_ACTIVE, radius),
		Candy.style(tokens, Candy.LOOK_DISABLED, radius),
	]
	if _icon == null:
		_icon = IconView.new()
		add_child(_icon)
	_icon.setup(tokens)
	_icon.set_icon(icon_name)
	var lip: float = tokens.num("button_lip")
	custom_minimum_size = Vector2(maxf(face_side, tokens.num("touch_min")), maxf(face_side + lip, tokens.num("touch_min")))
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


func _rest_rect() -> Rect2:
	var lip: float = _tokens.num("button_lip")
	var rest_size: Vector2 = Vector2(_face_side, _face_side + lip)
	return Rect2((size - rest_size) * 0.5, rest_size)


func _place_icon() -> void:
	if _tokens == null or _icon == null:
		return
	var face: Rect2 = Candy.face_rect(_tokens, _rest_rect(), _look)
	_icon.size = Vector2(_icon_side, _icon_side)
	_icon.position = face.get_center() - _icon.size * 0.5


func _draw() -> void:
	if _tokens == null:
		return
	draw_style_box(_styles[_look], Candy.style_rect(_tokens, _rest_rect(), _look))


func _gui_input(event: InputEvent) -> void:
	var button: InputEventMouseButton = event as InputEventMouseButton
	if button == null or button.button_index != MOUSE_BUTTON_LEFT or _tokens == null:
		return
	accept_event()
	if _look == IconView.LOOK_DISABLED:
		return
	if button.pressed:
		Motion.press(self, _tokens)
	else:
		Motion.release(self, _tokens)
		if Rect2(Vector2.ZERO, size).has_point(button.position):
			pressed.emit()
