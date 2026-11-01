extends Control
## Slate booster: one column of the booster strip. The icon, then the name
## and the cost in the label role, all left aligned. Active fills the whole
## column with paper and sets the content in ink_dark. Disabled sets the
## content in disabled_ink with the cost struck through, and ignores taps.
## While held, the column steps to surface, with no scaling.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

signal pressed(booster_id: String)

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const IconView: GDScript = preload("res://tools/directions/slate/ui/icon_view.gd")
const Motion: GDScript = preload("res://tools/directions/ui_common/motion.gd")

## Grid units of empty space at the left of an icon's 24 unit grid, so the
## drawn icon lines up with the text below it.
const ICON_INSET_UNITS: float = 3.0

var _tokens: DirectionTokens = null
var _id: String = ""
var _look: int = IconView.LOOK_NORMAL
var _held: bool = false
var _icon: IconView = null
var _name_text: String = ""
var _cost_text: String = ""
var _font: Font = null
var _font_size: int = 16
var _name_origin: Vector2 = Vector2.ZERO
var _cost_origin: Vector2 = Vector2.ZERO
var _strike_from: Vector2 = Vector2.ZERO
var _strike_to: Vector2 = Vector2.ZERO


func setup(tokens: DirectionTokens, booster_id: String, cost: int) -> void:
	_tokens = tokens
	_id = booster_id
	_name_text = tokens.cased("label", MockState.booster_name(booster_id))
	# Costs keep the tile label format exactly (D-32), so no case rule: "2K", never "2k".
	_cost_text = MockState.cost_label(cost)
	_font = tokens.font("label")
	_font_size = tokens.font_size("label")
	if _icon == null:
		_icon = IconView.new()
		add_child(_icon)
	_icon.setup(tokens)
	_icon.set_icon(booster_id)
	custom_minimum_size = Vector2(tokens.num("touch_min"), tokens.num("touch_min"))
	_layout()
	set_look(_look)


func set_look(look: int) -> void:
	_look = look
	if _look == IconView.LOOK_DISABLED:
		_held = false
	if _icon != null:
		_icon.set_look(look)
		_tint_icon()
	queue_redraw()


func _notification(what: int) -> void:
	# Also lay out on entering the tree: a control sized while outside the
	# tree gets no resize notification.
	if what == NOTIFICATION_RESIZED or what == NOTIFICATION_POST_ENTER_TREE:
		_layout()


func _layout() -> void:
	if _tokens == null:
		return
	var inset: float = _tokens.num("space_s")
	var line: float = _font.get_height(_font_size)
	var gap: float = _tokens.num("space_xs")
	var icon_side: float = _tokens.num("booster_icon")
	var block: float = icon_side + gap + line * 2.0
	var top: float = (size.y - block) * 0.5
	_icon.size = Vector2(icon_side, icon_side)
	_icon.position = Vector2(inset - ICON_INSET_UNITS * icon_side / 24.0, top)
	var ascent: float = _font.get_ascent(_font_size)
	_name_origin = Vector2(inset, top + icon_side + gap + ascent)
	_cost_origin = Vector2(inset, _name_origin.y + line)
	# The strike runs through the middle of the digits (about 0.36 of the
	# font size above the baseline) and reaches one rule width past them.
	var cost_width: float = _font.get_string_size(_cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x
	var middle: float = roundf(_cost_origin.y - float(_font_size) * 0.36)
	var rule: float = _tokens.num("rule_width")
	_strike_from = Vector2(inset - rule, middle)
	_strike_to = Vector2(inset + cost_width + rule, middle)
	queue_redraw()


func _ink() -> Color:
	# Text pairs: ink on bg, ink_dark on ink (paper), disabled_ink on bg,
	# and ink on surface while held.
	if _look == IconView.LOOK_ACTIVE:
		return _tokens.color("ink_dark")
	if _look == IconView.LOOK_DISABLED:
		return _tokens.color("disabled_ink")
	return _tokens.color("ink")


func _tint_icon() -> void:
	if _tokens != null:
		_icon.set_color(_ink())


func _draw() -> void:
	if _tokens == null:
		return
	var column: Rect2 = Rect2(Vector2.ZERO, size)
	if _look == IconView.LOOK_ACTIVE:
		draw_rect(column, _tokens.color("ink"))
	elif _held:
		draw_rect(column, _tokens.color("surface"))
	var ink: Color = _ink()
	draw_string(_font, _name_origin, _name_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, ink)
	draw_string(_font, _cost_origin, _cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, ink)
	if _look == IconView.LOOK_DISABLED:
		draw_line(_strike_from, _strike_to, ink, _tokens.num("rule_width"))


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
			pressed.emit(_id)
