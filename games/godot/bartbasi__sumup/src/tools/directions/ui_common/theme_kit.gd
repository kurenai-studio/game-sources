extends RefCounted
## Small shared helpers for the three theme factories. They only save
## typing; every color, size and font is passed in by the direction.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")

## The type variations every direction defines, with their base types.
const VARIATIONS: Dictionary[String, String] = {
	"DisplayLabel": "Label",
	"TitleLabel": "Label",
	"BodyLabel": "Label",
	"MutedLabel": "Label",
	"CaptionLabel": "Label",
	"PrimaryButton": "Button",
	"SecondaryButton": "Button",
	"ChipButton": "Button",
	"CardPanel": "PanelContainer",
	"PillPanel": "PanelContainer",
	"HintPanel": "PanelContainer",
	"Hairline": "HSeparator",
}

## Button style names, in the order the factories pass them.
const BUTTON_STYLES: PackedStringArray = ["normal", "hover", "pressed", "hover_pressed", "disabled", "focus"]


## A flat, antialiased box.
static func box(fill: Color, radius: float) -> StyleBoxFlat:
	var made: StyleBoxFlat = StyleBoxFlat.new()
	made.bg_color = fill
	made.set_corner_radius_all(roundi(radius))
	made.corner_detail = 12
	made.anti_aliasing = true
	return made


## Sets all four content margins.
static func pad(target: StyleBox, left: float, top: float, right: float, bottom: float) -> void:
	target.content_margin_left = left
	target.content_margin_top = top
	target.content_margin_right = right
	target.content_margin_bottom = bottom


## An outline only box for the focus state, grown outside the control by gap.
static func focus_ring(color: Color, width: float, radius: float, gap: float) -> StyleBoxFlat:
	var made: StyleBoxFlat = box(Color(color, 0.0), radius + gap)
	made.draw_center = false
	made.border_color = color
	made.set_border_width_all(roundi(width))
	made.set_expand_margin_all(gap + width)
	return made


## Makes type_name a variation of base_type.
static func variation(theme: Theme, type_name: String, base_type: String) -> void:
	theme.add_type(type_name)
	theme.set_type_variation(type_name, base_type)


## A Label variation with its font, size and color.
static func label_variation(theme: Theme, type_name: String, font: Font, font_size: int, color: Color) -> void:
	variation(theme, type_name, "Label")
	theme.set_font("font", type_name, font)
	theme.set_font_size("font_size", type_name, font_size)
	theme.set_color("font_color", type_name, color)


## Sets a Button type's styles from a dictionary keyed by BUTTON_STYLES, and
## its text colors for normal, pressed and disabled. Hover matches normal and
## hover_pressed matches pressed, since this is a touch game.
static func button_type(theme: Theme, type_name: String, styles: Dictionary[String, StyleBox], font: Font, font_size: int, ink: Color, pressed_ink: Color, disabled_ink: Color) -> void:
	for style_name: String in BUTTON_STYLES:
		theme.set_stylebox(style_name, type_name, styles[style_name])
	theme.set_font("font", type_name, font)
	theme.set_font_size("font_size", type_name, font_size)
	theme.set_color("font_color", type_name, ink)
	theme.set_color("font_hover_color", type_name, ink)
	theme.set_color("font_focus_color", type_name, ink)
	theme.set_color("font_pressed_color", type_name, pressed_ink)
	theme.set_color("font_hover_pressed_color", type_name, pressed_ink)
	theme.set_color("font_disabled_color", type_name, disabled_ink)


## Height in px of one line of text in a type role.
static func line_height(tokens: DirectionTokens, role: String) -> float:
	return tokens.font(role).get_height(tokens.font_size(role))
