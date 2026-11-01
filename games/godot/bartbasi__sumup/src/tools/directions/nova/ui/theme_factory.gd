extends RefCounted
## Nova Theme: floating light, almost no containers. The primary button is
## an aurora cyan pill; the secondary button is a thin ring outline that
## fills with surface_raised when pressed. Cards are the dark settings sheet
## with rounded top corners.
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
	ThemeKit.label_variation(theme, "MutedLabel", tokens.font("body"), tokens.font_size("body"), tokens.color("ink_muted"))
	ThemeKit.label_variation(theme, "CaptionLabel", tokens.font("label"), tokens.font_size("label"), tokens.color("ink_muted"))

	# Buttons are pills touch_min tall.
	var height: float = tokens.num("touch_min")
	var radius: float = height * 0.5
	var ring: float = tokens.num("ring_width")
	var body_line: float = ThemeKit.line_height(tokens, "body")
	var side: float = tokens.num("space_m")
	var text_pad: float = maxf(0.0, (height - body_line) * 0.5)
	# The focus outline is ring_width wide, focus_gap outside the button.
	var focus: StyleBoxFlat = ThemeKit.focus_ring(tokens.color("accent"), ring, radius, tokens.num("focus_gap"))

	# Disabled, for every button: a faint ring, text in disabled_ink.
	var disabled: StyleBoxFlat = _ring(Color(tokens.color("ring"), tokens.num("disabled_ring_alpha")), radius, ring)
	ThemeKit.pad(disabled, side, text_pad, side, text_pad)

	var primary: StyleBoxFlat = ThemeKit.box(tokens.color("accent"), radius)
	ThemeKit.pad(primary, side, text_pad, side, text_pad)
	var primary_pressed: StyleBoxFlat = ThemeKit.box(tokens.color("accent_pressed"), radius)
	ThemeKit.pad(primary_pressed, side, text_pad, side, text_pad)
	ThemeKit.button_type(theme, "PrimaryButton", _styles(primary, primary_pressed, disabled, focus),
		tokens.font("body"), tokens.font_size("body"), tokens.color("ink_dark"), tokens.color("ink_dark"), tokens.color("disabled_ink"))

	var secondary: StyleBoxFlat = _ring(tokens.color("ring"), radius, ring)
	ThemeKit.pad(secondary, side, text_pad, side, text_pad)
	var secondary_pressed: StyleBoxFlat = _ring(tokens.color("ring"), radius, ring)
	secondary_pressed.draw_center = true
	secondary_pressed.bg_color = tokens.color("surface_raised")
	ThemeKit.pad(secondary_pressed, side, text_pad, side, text_pad)
	var secondary_styles: Dictionary[String, StyleBox] = _styles(secondary, secondary_pressed, disabled, focus)
	ThemeKit.button_type(theme, "SecondaryButton", secondary_styles,
		tokens.font("body"), tokens.font_size("body"), tokens.color("ink"), tokens.color("ink"), tokens.color("disabled_ink"))
	ThemeKit.button_type(theme, "Button", secondary_styles,
		tokens.font("body"), tokens.font_size("body"), tokens.color("ink"), tokens.color("ink"), tokens.color("disabled_ink"))

	# Chips: surface_raised pills; selected is aurora cyan with ink_dark.
	var chip_side: float = tokens.num("space_s")
	var chip: StyleBoxFlat = ThemeKit.box(tokens.color("surface_raised"), radius)
	ThemeKit.pad(chip, chip_side, text_pad, chip_side, text_pad)
	var chip_selected: StyleBoxFlat = ThemeKit.box(tokens.color("accent"), radius)
	ThemeKit.pad(chip_selected, chip_side, text_pad, chip_side, text_pad)
	ThemeKit.button_type(theme, "ChipButton", _styles(chip, chip_selected, disabled, focus),
		tokens.font("body"), tokens.font_size("body"), tokens.color("ink"), tokens.color("ink_dark"), tokens.color("disabled_ink"))

	# Panels. The card is the settings sheet: surface, rounded top corners.
	theme.set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	var card: StyleBoxFlat = ThemeKit.box(tokens.color("surface"), 0.0)
	card.corner_radius_top_left = roundi(tokens.num("sheet_radius"))
	card.corner_radius_top_right = roundi(tokens.num("sheet_radius"))
	var card_pad: float = tokens.num("space_m")
	ThemeKit.pad(card, card_pad, card_pad, card_pad, card_pad)
	theme.set_stylebox("panel", "CardPanel", card)
	theme.set_stylebox("panel", "PillPanel", StyleBoxEmpty.new())
	theme.set_stylebox("panel", "HintPanel", StyleBoxEmpty.new())

	var divider: StyleBoxLine = StyleBoxLine.new()
	divider.color = tokens.color("ring")
	var divider_width: int = roundi(tokens.num("divider_width"))
	divider.thickness = divider_width
	theme.set_stylebox("separator", "HSeparator", divider)
	theme.set_constant("separation", "HSeparator", divider_width)
	theme.set_stylebox("separator", "Hairline", divider)
	theme.set_constant("separation", "Hairline", divider_width)
	return theme


## An outline only pill.
static func _ring(color: Color, radius: float, width: float) -> StyleBoxFlat:
	var made: StyleBoxFlat = ThemeKit.box(Color(color, 0.0), radius)
	made.draw_center = false
	made.border_color = color
	made.set_border_width_all(roundi(width))
	return made


static func _styles(normal: StyleBox, pressed: StyleBox, disabled: StyleBox, focus: StyleBox) -> Dictionary[String, StyleBox]:
	return {
		"normal": normal,
		"hover": normal,
		"pressed": pressed,
		"hover_pressed": pressed,
		"disabled": disabled,
		"focus": focus,
	}
