extends Control
## Nova icon button: a thin icon in a ring, used for the HUD settings button
## and the icon review rows. The control's rect is the touch area; the ring
## is centered in it. Active fills the ring with aurora cyan inside a soft
## cyan and violet glow; disabled fades the ring.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal pressed

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const IconView: GDScript = preload("res://tools/directions/nova/ui/icon_view.gd")
const RingGlow: GDScript = preload("res://tools/directions/nova/ui/ring_glow.gd")
const Motion: GDScript = preload("res://tools/directions/ui_common/motion.gd")

var _tokens: DirectionTokens = null
var _look: int = IconView.LOOK_NORMAL
var _ring_side: float = 0.0
var _icon_side: float = 0.0
var _glow: RingGlow = null
var _icon: IconView = null


## face_side is the ring diameter, icon_side the icon size.
func setup(tokens: DirectionTokens, icon_name: String, face_side: float, icon_side: float) -> void:
	_tokens = tokens
	_ring_side = face_side
	_icon_side = icon_side
	if _icon == null:
		_glow = RingGlow.new()
		add_child(_glow)
		_icon = IconView.new()
		add_child(_icon)
	_glow.setup(tokens)
	_icon.setup(tokens)
	_icon.set_icon(icon_name)
	custom_minimum_size = Vector2(maxf(face_side, tokens.num("touch_min")), maxf(face_side, tokens.num("touch_min")))
	set_look(_look)


func set_look(look: int) -> void:
	_look = look
	if _icon == null:
		return
	_icon.set_look(look)
	if look == IconView.LOOK_ACTIVE:
		_icon.set_color(_tokens.color("ink_dark"))
	elif look == IconView.LOOK_DISABLED:
		_icon.set_color(_tokens.color("disabled_ink"))
	else:
		_icon.set_color(_tokens.color("ink"))
	_glow.visible = look == IconView.LOOK_ACTIVE
	_place()
	queue_redraw()


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_place()


func _place() -> void:
	if _icon == null:
		return
	_icon.size = Vector2(_icon_side, _icon_side)
	_icon.position = (size - _icon.size) * 0.5
	_glow.place(size * 0.5, _ring_side * 0.5)


func _draw() -> void:
	if _tokens == null:
		return
	var center: Vector2 = size * 0.5
	var radius: float = _ring_side * 0.5
	var width: float = _tokens.num("ring_width")
	if _look == IconView.LOOK_ACTIVE:
		draw_circle(center, radius, _tokens.color("accent"), true, -1.0, true)
	elif _look == IconView.LOOK_DISABLED:
		draw_circle(center, radius - width * 0.5, Color(_tokens.color("ring"), _tokens.num("disabled_ring_alpha")), false, width, true)
	else:
		draw_circle(center, radius - width * 0.5, _tokens.color("ring"), false, width, true)


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
