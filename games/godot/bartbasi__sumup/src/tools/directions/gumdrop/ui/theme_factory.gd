extends RefCounted
## Gumdrop Theme: every button, chip, pill and card is a soft raised candy
## with a darker lip underneath. A pressed button sinks onto its lip; a
## disabled one lies flat with no lip, lower than the others.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const ThemeKit: GDScript = preload("res://tools/directions/ui_common/theme_kit.gd")


static func build(tokens: DirectionTokens) -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font = tokens.font("body")
	theme.default_font_size = tokens.font_size("body")
	for type_name: String in ThemeKit.VARIATIONS:
		ThemeKit.variation(theme, type_name, ThemeKit.VARIATIONS[type_name])

	# Labels.
	theme.set_font("font", "Label", tokens.font("body"))
	theme.set_font_size("font_size", "Label", tokens.font_size("body"))
	theme.set_color("font_color", "Label", tokens.color("ink"))
	ThemeKit.label_variation(theme, "DisplayLabel", tokens.font("display"), tokens.font_size("display"), tokens.color("ink"))
	ThemeKit.label_variation(theme, "TitleLabel", tokens.font("title"), tokens.font_size("title"), tokens.color("ink"))
	ThemeKit.label_variation(theme, "BodyLabel", tokens.font("body"), tokens.font_size("body"), tokens.color("ink"))
	ThemeKit.label_variation(theme, "MutedLabel", tokens.font("body"), tokens.font_size("body"), tokens.color("ink_soft"))
	ThemeKit.label_variation(theme, "CaptionLabel", tokens.font("label"), tokens.font_size("label"), tokens.color("ink_soft"))

	# Buttons: face touch_min tall with the lip below it.
	var face: float = tokens.num("touch_min")
	var body_line: float = ThemeKit.line_height(tokens, "body")
	var side: float = tokens.num("space_m")
	var primary: Dictionary[String, StyleBox] = _button_styles(tokens, "accent", "accent_pressed", "accent_lip", face, body_line, side)
	ThemeKit.button_type(theme, "PrimaryButton", primary, tokens.font("body"), tokens.font_size("body"),
		tokens.color("ink_dark"), tokens.color("ink_dark"), tokens.color("disabled_ink"))
	var secondary: Dictionary[String, StyleBox] = _button_styles(tokens, "surface_raised", "surface_raised", "surface_lip", face, body_line, side)
	ThemeKit.button_type(theme, "SecondaryButton", secondary, tokens.font("body"), tokens.font_size("body"),
		tokens.color("ink"), tokens.color("ink"), tokens.color("disabled_ink"))
	ThemeKit.button_type(theme, "Button", secondary, tokens.font("body"), tokens.font_size("body"),
		tokens.color("ink"), tokens.color("ink"), tokens.color("disabled_ink"))

	# Chips: a smaller face so the whole chip, lip included, is touch_min tall.
	# Selected is the pink candy with dark text.
	var chip_face: float = face - tokens.num("button_lip")
	var chip_side: float = tokens.num("space_s")
	var chip: Dictionary[String, StyleBox] = _button_styles(tokens, "surface_raised", "surface_raised", "surface_lip", chip_face, body_line, chip_side)
	var selected: Dictionary[String, StyleBox] = _button_styles(tokens, "accent", "accent_pressed", "accent_lip", chip_face, body_line, chip_side)
	chip["pressed"] = selected["normal"]
	chip["hover_pressed"] = selected["normal"]
	ThemeKit.button_type(theme, "ChipButton", chip, tokens.font("body"), tokens.font_size("body"),
		tokens.color("ink"), tokens.color("ink_dark"), tokens.color("disabled_ink"))

	# Panels.
	theme.set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	var lip: float = tokens.num("button_lip")
	var card: StyleBoxFlat = _raised(tokens.color("surface"), tokens.color("surface_lip"), tokens.num("card_radius"), lip)
	ThemeKit.pad(card, side, side, side, side + lip)
	theme.set_stylebox("panel", "CardPanel", card)
	var pill_face: float = tokens.num("pill_height") - lip
	var pill: StyleBoxFlat = _raised(tokens.color("surface"), tokens.color("surface_lip"), tokens.num("pill_radius"), lip)
	var pill_pad: float = maxf(0.0, (pill_face - body_line) * 0.5)
	ThemeKit.pad(pill, chip_side, pill_pad, chip_side, pill_pad + lip)
	theme.set_stylebox("panel", "PillPanel", pill)
	var label_line: float = ThemeKit.line_height(tokens, "label")
	var hint: StyleBoxFlat = _raised(tokens.color("lemon"), tokens.color("lemon_lip"), tokens.num("pill_radius"), lip)
	var hint_pad: float = maxf(0.0, (pill_face - label_line) * 0.5)
	ThemeKit.pad(hint, side, hint_pad, side, hint_pad + lip)
	theme.set_stylebox("panel", "HintPanel", hint)

	# Divider: a divider_width px line with round ends in the divider color,
	# visible on bg and on cards. A separator draws its style at the style's
	# minimum height, so the content margins set the line's thickness.
	var width: float = tokens.num("divider_width")
	var groove: StyleBoxFlat = ThemeKit.box(tokens.color("divider"), width * 0.5)
	ThemeKit.pad(groove, 0.0, width * 0.5, 0.0, width * 0.5)
	theme.set_stylebox("separator", "HSeparator", groove)
	theme.set_constant("separation", "HSeparator", roundi(width))
	theme.set_stylebox("separator", "Hairline", groove)
	theme.set_constant("separation", "Hairline", roundi(width))
	return theme


## A raised box: face in fill, lip px of lip_color along the bottom.
static func _raised(fill: Color, lip_color: Color, radius: float, lip: float) -> StyleBoxFlat:
	var made: StyleBoxFlat = ThemeKit.box(fill, radius)
	made.border_color = lip_color
	made.border_width_bottom = roundi(lip)
	return made


## Normal, hover, pressed, hover_pressed, disabled and focus styles for a
## raised button whose face is face px tall with the lip below it.
static func _button_styles(tokens: DirectionTokens, fill: String, pressed_fill: String, lip_color: String, face: float, line: float, side: float) -> Dictionary[String, StyleBox]:
	var radius: float = tokens.num("button_radius")
	var lip: float = tokens.num("button_lip")
	var text_pad: float = maxf(0.0, (face - line) * 0.5)

	var normal: StyleBoxFlat = _raised(tokens.color(fill), tokens.color(lip_color), radius, lip)
	ThemeKit.pad(normal, side, text_pad, side, text_pad + lip)

	# Pressed: the face sinks onto the lip, the text moves down with it.
	var pressed_lip: float = tokens.num("button_lip_pressed")
	var sink: float = lip - pressed_lip
	var pressed: StyleBoxFlat = _raised(tokens.color(pressed_fill), tokens.color(lip_color), radius, pressed_lip)
	pressed.expand_margin_top = -sink
	ThemeKit.pad(pressed, side, text_pad + sink, side, text_pad + pressed_lip)

	# Disabled: flat, no lip, sitting at the bottom of the lip's space.
	var disabled: StyleBoxFlat = ThemeKit.box(tokens.color("disabled_surface"), radius)
	disabled.expand_margin_top = -lip
	ThemeKit.pad(disabled, side, text_pad + lip, side, text_pad)

	var focus: StyleBoxFlat = ThemeKit.focus_ring(tokens.color("accent"), tokens.num("focus_width"), radius, tokens.num("focus_gap"))
	return {
		"normal": normal,
		"hover": normal,
		"pressed": pressed,
		"hover_pressed": pressed,
		"disabled": disabled,
		"focus": focus,
	}
