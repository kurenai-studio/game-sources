extends Control
## Gumdrop booster: a raised candy button with the icon on its face and the
## cost under the icon. Active stands higher in hot pink and its icon
## wobbles; disabled lies flat with no lip and ignores taps. The control's
## rect holds the face and the lip at rest.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal pressed(booster_id: String)

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const IconView: GDScript = preload("res://tools/directions/gumdrop/ui/icon_view.gd")
const Candy: GDScript = preload("res://tools/directions/gumdrop/ui/candy.gd")
const Motion: GDScript = preload("res://tools/directions/ui_common/motion.gd")

var _tokens: DirectionTokens = null
var _id: String = ""
var _look: int = IconView.LOOK_NORMAL
var _styles: Array[StyleBoxFlat] = []
var _inks: Array[Color] = []
var _icon: IconView = null
var _cost_text: String = ""
var _font: Font = null
var _font_size: int = 16
var _text_origin: Vector2 = Vector2.ZERO


func setup(tokens: DirectionTokens, booster_id: String, cost: int) -> void:
	_tokens = tokens
	_id = booster_id
	# Costs keep the tile label format exactly (D-32), so no case rule: "2K", never "2k".
	_cost_text = MockState.cost_label(cost)
	_font = tokens.font("label")
	_font_size = tokens.font_size("label")
	var radius: float = tokens.num("button_radius")
	_styles = [
		Candy.style(tokens, Candy.LOOK_NORMAL, radius),
		Candy.style(tokens, Candy.LOOK_ACTIVE, radius),
		Candy.style(tokens, Candy.LOOK_DISABLED, radius),
	]
	# Cost text pairs: ink on surface_raised, ink_dark on accent,
	# disabled_ink on disabled_surface.
	_inks = [tokens.color("ink"), tokens.color("ink_dark"), tokens.color("disabled_ink")]
	if _icon == null:
		_icon = IconView.new()
		add_child(_icon)
	_icon.setup(tokens)
	_icon.set_icon(booster_id)
	custom_minimum_size = Vector2(tokens.num("touch_min"), tokens.num("touch_min"))
	set_look(_look)


func set_look(look: int) -> void:
	var was_active: bool = _look == IconView.LOOK_ACTIVE
	_look = look
	if _icon == null:
		return
	_icon.set_look(look)
	_layout()
	if look == IconView.LOOK_ACTIVE and not was_active:
		Motion.pulse(_icon, _tokens)
	elif look != IconView.LOOK_ACTIVE:
		Motion.stop_pulse(_icon)
	queue_redraw()


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _layout() -> void:
	if _tokens == null or _icon == null:
		return
	var face: Rect2 = Candy.face_rect(_tokens, Rect2(Vector2.ZERO, size), _look)
	var icon_side: float = _tokens.num("booster_icon")
	var line: float = _font.get_height(_font_size)
	var block: float = icon_side + line
	var top: float = face.position.y + (face.size.y - block) * 0.5
	_icon.size = Vector2(icon_side, icon_side)
	_icon.position = Vector2(face.get_center().x - icon_side * 0.5, top)
	_icon.pivot_offset = _icon.size * 0.5
	_text_origin = Vector2(face.position.x, top + icon_side + _font.get_ascent(_font_size))
	queue_redraw()


func _draw() -> void:
	if _tokens == null:
		return
	draw_style_box(_styles[_look], Candy.style_rect(_tokens, Rect2(Vector2.ZERO, size), _look))
	draw_string(_font, _text_origin, _cost_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, _font_size, _inks[_look])


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
			pressed.emit(_id)
