extends "res://src/design/shared/booster_button_base.gd"
## One Gumdrop booster button (DESIGN_SYSTEM.md 4.7): a raised surface_raised
## face with radius_button corners and a button_lip lip, the icon_booster icon
## over the cost (label role, a tile label).
##   Pressed: Motion.press scale, lip down to button_lip_pressed.
##   Active: accent face on an accent_lip lip, raised active_raise; icon and
##     cost ink_dark; the icon wobbles on target_pulse.
##   Disabled: flat, sitting lower, disabled_surface; icon and cost
##     disabled_ink.
##   Free: the star and "Free" centered where the cost was, in badge (normal
##     and pressed), ink_dark (active) or disabled_ink (disabled).
## Text pairs: ink and badge on surface_raised, ink_dark on accent,
## disabled_ink on disabled_surface.
##
## Touch (QA6-05): the control is the button's touch area, which the bar sets
## to the dock face's whole height and across to the middle of the gaps
## beside it. The button draws in its rest rect inside it (face and lip),
## which the bar gives with set_rest_rect(); without one it draws in the
## whole control.

const Candy: GDScript = preload("res://src/design/gumdrop/gumdrop_candy.gd")
const GumdropIcon: GDScript = preload("res://src/design/gumdrop/gumdrop_icon.gd")

## Styles by look, at rest and held.
var _styles: Array[StyleBoxFlat] = []
var _held_styles: Array[StyleBoxFlat] = []
var _inks: Array[Color] = []
var _free_inks: Array[Color] = []
var _icon: SkinIcon = null
var _font: Font = null
var _font_size: int = 1
var _text_origin: Vector2 = Vector2.ZERO
## The face and lip at rest, local. Empty: the whole control.
var _rest_set: Rect2 = Rect2()


func _on_setup() -> void:
	var radius: float = _skin.num(&"radius_button")
	_styles.clear()
	_held_styles.clear()
	for each_look: int in [Candy.LOOK_NORMAL, Candy.LOOK_ACTIVE, Candy.LOOK_DISABLED]:
		_styles.append(Candy.style(_skin, each_look, false, radius))
		_held_styles.append(Candy.style(_skin, each_look, true, radius))
	_inks = [_skin.color(&"ink"), _skin.color(&"ink_dark"), _skin.color(&"disabled_ink")]
	_free_inks = [_skin.color(&"badge"), _skin.color(&"ink_dark"), _skin.color(&"disabled_ink")]
	_font = _skin.font(&"label")
	_font_size = _skin.font_size(&"label")
	if _icon == null:
		_icon = GumdropIcon.new()
		add_child(_icon)
	_icon.setup(_skin)
	if booster_id != &"":
		_icon.set_icon(booster_id)


## The face and lip at rest inside the touch area, local.
func set_rest_rect(rect: Rect2) -> void:
	_rest_set = rect
	_layout()


## The face and lip at rest, local.
func rest_rect() -> Rect2:
	return _rest_set if _rest_set.has_area() else Rect2(Vector2.ZERO, size)


func _on_booster_changed() -> void:
	if _icon != null:
		_icon.set_icon(booster_id)


func _apply(was: int) -> void:
	if _icon == null:
		return
	_icon.set_look(look)
	if look == SkinIcon.LOOK_ACTIVE and was != SkinIcon.LOOK_ACTIVE:
		Motion.pulse(_icon, _skin)
	elif look != SkinIcon.LOOK_ACTIVE:
		Motion.stop_pulse(_icon)
	_layout()


func _held_changed() -> void:
	_layout()


## Presses around the face's center, which sits off center in the outer
## buttons' touch areas.
func _press_pivot() -> Vector2:
	return rest_rect().get_center()


func _layout() -> void:
	if _skin == null or _icon == null:
		return
	var rest: Rect2 = rest_rect()
	var face: Rect2 = Candy.face_rect(_skin, rest, look, held)
	var icon_side: float = _skin.num(&"icon_booster")
	var line: float = _font.get_height(_font_size)
	var top: float = face.position.y + (face.size.y - icon_side - line) * 0.5
	_icon.size = Vector2(icon_side, icon_side)
	_icon.position = Vector2(face.get_center().x - icon_side * 0.5, top)
	_icon.pivot_offset = _icon.size * 0.5
	_text_origin = Vector2(rest.position.x, top + icon_side + _font.get_ascent(_font_size))
	_place_free(face.get_center().x - _free_width() * 0.5, _text_origin.y, _free_inks[look])
	queue_redraw()


func _draw() -> void:
	if _skin == null:
		return
	var rest: Rect2 = rest_rect()
	var style: StyleBoxFlat = _held_styles[look] if held else _styles[look]
	draw_style_box(style, Candy.style_rect(_skin, rest, look, held))
	if free:
		draw_string(_font, _free_origin, free_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, _free_inks[look])
	else:
		draw_string(_font, _text_origin, cost_text, HORIZONTAL_ALIGNMENT_CENTER, rest.size.x, _font_size, _inks[look])
