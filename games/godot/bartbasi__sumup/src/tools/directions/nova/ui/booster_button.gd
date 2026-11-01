extends Control
## Nova booster: a ring button with a thin icon, and the cost under it, with
## no container. Active fills the ring with aurora cyan inside a breathing
## cyan and violet glow, icon in ink_dark, cost in accent. Disabled fades
## the ring, sets icon and cost in disabled_ink, and ignores taps. The
## control's rect holds the glow area and the cost line; the cost always
## sits below the glow, never on it.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal pressed(booster_id: String)

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const IconView: GDScript = preload("res://tools/directions/nova/ui/icon_view.gd")
const RingGlow: GDScript = preload("res://tools/directions/nova/ui/ring_glow.gd")
const Motion: GDScript = preload("res://tools/directions/ui_common/motion.gd")

var _tokens: DirectionTokens = null
var _id: String = ""
var _look: int = IconView.LOOK_NORMAL
var _glow: RingGlow = null
var _icon: IconView = null
var _cost_text: String = ""
var _font: Font = null
var _font_size: int = 16
var _center: Vector2 = Vector2.ZERO
var _text_origin: Vector2 = Vector2.ZERO


## Height a booster needs: the glow area and one cost line.
static func needed_height(tokens: DirectionTokens) -> float:
	return tokens.num("ring_button") * tokens.num("ring_glow_spread") + tokens.font("label").get_height(tokens.font_size("label"))


func setup(tokens: DirectionTokens, booster_id: String, cost: int) -> void:
	_tokens = tokens
	_id = booster_id
	# Costs keep the tile label format exactly (D-32), so no case rule: "2K", never "2k".
	_cost_text = MockState.cost_label(cost)
	_font = tokens.font("label")
	_font_size = tokens.font_size("label")
	if _icon == null:
		_glow = RingGlow.new()
		add_child(_glow)
		_icon = IconView.new()
		add_child(_icon)
	_glow.setup(tokens)
	_icon.setup(tokens)
	_icon.set_icon(booster_id)
	custom_minimum_size = Vector2(tokens.num("ring_button"), needed_height(tokens))
	_layout()
	set_look(_look)


func set_look(look: int) -> void:
	var was_active: bool = _look == IconView.LOOK_ACTIVE
	_look = look
	if _icon == null:
		return
	_icon.set_look(look)
	_icon.set_color(_ink(true))
	_glow.visible = look == IconView.LOOK_ACTIVE
	if look == IconView.LOOK_ACTIVE and not was_active:
		Motion.pulse(_glow, _tokens)
	elif look != IconView.LOOK_ACTIVE:
		Motion.stop_pulse(_glow)
	queue_redraw()


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _layout() -> void:
	if _tokens == null:
		return
	var radius: float = _tokens.num("ring_button") * 0.5
	var glow_radius: float = radius * _tokens.num("ring_glow_spread")
	_center = Vector2(size.x * 0.5, glow_radius)
	_glow.place(_center, radius)
	var icon_side: float = _tokens.num("booster_icon")
	_icon.size = Vector2(icon_side, icon_side)
	_icon.position = _center - _icon.size * 0.5
	_text_origin = Vector2(0.0, glow_radius * 2.0 + _font.get_ascent(_font_size))
	queue_redraw()


## Icon color (on the ring) or cost color (on the backdrop) for the look.
## Cost text pairs: ink, accent and disabled_ink on bg_glow.
func _ink(for_icon: bool) -> Color:
	if _look == IconView.LOOK_ACTIVE:
		return _tokens.color("ink_dark") if for_icon else _tokens.color("accent")
	if _look == IconView.LOOK_DISABLED:
		return _tokens.color("disabled_ink")
	return _tokens.color("ink")


func _draw() -> void:
	if _tokens == null:
		return
	var radius: float = _tokens.num("ring_button") * 0.5
	var width: float = _tokens.num("ring_width")
	if _look == IconView.LOOK_ACTIVE:
		draw_circle(_center, radius, _tokens.color("accent"), true, -1.0, true)
	elif _look == IconView.LOOK_DISABLED:
		draw_circle(_center, radius - width * 0.5, Color(_tokens.color("ring"), _tokens.num("disabled_ring_alpha")), false, width, true)
	else:
		draw_circle(_center, radius - width * 0.5, _tokens.color("ring"), false, width, true)
	draw_string(_font, _text_origin, _cost_text, HORIZONTAL_ALIGNMENT_CENTER, size.x, _font_size, _ink(false))


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
