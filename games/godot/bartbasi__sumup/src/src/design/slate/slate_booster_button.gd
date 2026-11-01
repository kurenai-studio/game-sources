extends "res://src/design/shared/booster_button_base.gd"
## One column of Slate's booster strip (DESIGN_SYSTEM.md 5.7): the
## icon_booster icon, then the booster's name and its cost in the label role,
## left aligned space_s in from the column's edge.
##   Pressed: the column fills surface.
##   Active: the column fills ink (the paper), content in ink_dark.
##   Disabled: content in disabled_ink, the cost struck through with a
##     hairline line.
##   Free: the star and "FREE" left aligned where the cost was, in accent
##     (normal and pressed), ink_dark (active) or disabled_ink (disabled, the
##     hairline strike across the whole group).
## Text pairs: ink on bg, ink on surface, ink_dark on ink, disabled_ink on bg,
## accent on bg and on surface.

const SlateIcon: GDScript = preload("res://src/design/slate/slate_icon.gd")

## Grid units of empty space at the left of the 24 unit icon grid, so the
## drawn icon lines up with the text under it. A fact of the icon drawings.
const ICON_INSET_UNITS: float = 3.0

var _icon: SkinIcon = null
var _font: Font = null
var _font_size: int = 1
var _name_text: String = ""
var _name_origin: Vector2 = Vector2.ZERO
var _cost_origin: Vector2 = Vector2.ZERO
var _strike_from: Vector2 = Vector2.ZERO
var _strike_to: Vector2 = Vector2.ZERO


func _on_setup() -> void:
	_font = _skin.font(&"label")
	_font_size = _skin.font_size(&"label")
	if _icon == null:
		_icon = SlateIcon.new()
		add_child(_icon)
	_icon.setup(_skin)
	_on_booster_changed()


func _on_booster_changed() -> void:
	if _icon == null or booster_id == &"":
		return
	_icon.set_icon(booster_id)
	_name_text = UiCopy.booster_name(_skin, &"label", booster_id)


func _apply(_was: int) -> void:
	if _icon != null:
		_icon.set_look(look)
	_layout()


func _layout() -> void:
	if _skin == null or _icon == null:
		return
	var inset: float = _skin.num(&"space_s")
	var gap: float = _skin.num(&"space_xs")
	var line: float = _font.get_height(_font_size)
	var icon_side: float = _skin.num(&"icon_booster")
	var top: float = (size.y - icon_side - gap - line * 2.0) * 0.5
	_icon.size = Vector2(icon_side, icon_side)
	_icon.position = Vector2(inset - ICON_INSET_UNITS * icon_side / 24.0, top)
	var ascent: float = _font.get_ascent(_font_size)
	_name_origin = Vector2(inset, top + icon_side + gap + ascent)
	_cost_origin = Vector2(inset, _name_origin.y + line)
	var cost_width: float = _font.get_string_size(cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x
	if free:
		cost_width = _free_width()
	var middle: float = roundf(_cost_origin.y - float(_font_size) * FontMetrics.CAP_HEIGHT * 0.5)
	var hairline: float = _skin.num(&"hairline")
	_strike_from = Vector2(inset - hairline, middle)
	_strike_to = Vector2(inset + cost_width + hairline, middle)
	_place_free(inset, _cost_origin.y, _free_ink())
	queue_redraw()


## The Free group's color for the look.
func _free_ink() -> Color:
	if look == SkinIcon.LOOK_ACTIVE:
		return _skin.color(&"ink_dark")
	if look == SkinIcon.LOOK_DISABLED:
		return _skin.color(&"disabled_ink")
	return _skin.color(&"accent")


func _ink() -> Color:
	if look == SkinIcon.LOOK_ACTIVE:
		return _skin.color(&"ink_dark")
	if look == SkinIcon.LOOK_DISABLED:
		return _skin.color(&"disabled_ink")
	return _skin.color(&"ink")


func _draw() -> void:
	if _skin == null:
		return
	var column: Rect2 = Rect2(Vector2.ZERO, size)
	if look == SkinIcon.LOOK_ACTIVE:
		draw_rect(column, _skin.color(&"ink"))
	elif held:
		draw_rect(column, _skin.color(&"surface"))
	var ink: Color = _ink()
	draw_string(_font, _name_origin, _name_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, ink)
	if free:
		draw_string(_font, _free_origin, free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, _free_ink())
	else:
		draw_string(_font, _cost_origin, cost_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, ink)
	if look == SkinIcon.LOOK_DISABLED:
		draw_line(_strike_from, _strike_to, ink, _skin.num(&"hairline"))
