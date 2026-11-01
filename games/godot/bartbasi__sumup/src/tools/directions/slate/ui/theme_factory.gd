extends RefCounted
## Slate Theme: no boxes and no shadows. Buttons are plain rectangles with
## nearly square corners, button_height tall; secondary buttons and cards
## are drawn with rule hairlines. Pressed is a flat step to surface.
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

	var radius: float = tokens.num("button_radius")
	var rule: float = tokens.num("rule_width")
	var body_line: float = ThemeKit.line_height(tokens, "body")
	var side: float = tokens.num("space_m")
	var text_pad: float = maxf(0.0, (tokens.num("button_height") - body_line) * 0.5)
	var focus: StyleBoxFlat = ThemeKit.focus_ring(tokens.color("accent"), tokens.num("focus_width"), radius, tokens.num("focus_gap"))

	# Disabled, for every button: a ruled outline on bg, text in disabled_ink.
	var disabled: StyleBoxFlat = _ruled(tokens, "bg", radius, rule)
	ThemeKit.pad(disabled, side, text_pad, side, text_pad)

	# Primary: solid vermilion, a darker step when pressed. Text ink_dark.
	var primary: StyleBoxFlat = ThemeKit.box(tokens.color("accent"), radius)
	ThemeKit.pad(primary, side, text_pad, side, text_pad)
	var primary_pressed: StyleBoxFlat = ThemeKit.box(tokens.color("accent_pressed"), radius)
	ThemeKit.pad(primary_pressed, side, text_pad, side, text_pad)
	ThemeKit.button_type(theme, "PrimaryButton", _styles(primary, primary_pressed, disabled, focus),
		tokens.font("body"), tokens.font_size("body"), tokens.color("ink_dark"), tokens.color("ink_dark"), tokens.color("disabled_ink"))

	# Secondary: a ruled outline on bg; pressed fills with surface. Text ink.
	var secondary: StyleBoxFlat = _ruled(tokens, "bg", radius, rule)
	ThemeKit.pad(secondary, side, text_pad, side, text_pad)
	var secondary_pressed: StyleBoxFlat = _ruled(tokens, "surface", radius, rule)
	ThemeKit.pad(secondary_pressed, side, text_pad, side, text_pad)
	var secondary_styles: Dictionary[String, StyleBox] = _styles(secondary, secondary_pressed, disabled, focus)
	ThemeKit.button_type(theme, "SecondaryButton", secondary_styles,
		tokens.font("body"), tokens.font_size("body"), tokens.color("ink"), tokens.color("ink"), tokens.color("disabled_ink"))
	ThemeKit.button_type(theme, "Button", secondary_styles,
		tokens.font("body"), tokens.font_size("body"), tokens.color("ink"), tokens.color("ink"), tokens.color("disabled_ink"))

	# Chips: segments on surface; selected is a paper block with ink_dark.
	var chip_pad: float = maxf(0.0, (tokens.num("touch_min") - body_line) * 0.5)
	var chip_side: float = tokens.num("space_s")
	var chip: StyleBoxFlat = ThemeKit.box(tokens.color("surface"), radius)
	ThemeKit.pad(chip, chip_side, chip_pad, chip_side, chip_pad)
	var chip_selected: StyleBoxFlat = ThemeKit.box(tokens.color("ink"), radius)
	ThemeKit.pad(chip_selected, chip_side, chip_pad, chip_side, chip_pad)
	var chip_disabled: StyleBoxFlat = _ruled(tokens, "bg", radius, rule)
	ThemeKit.pad(chip_disabled, chip_side, chip_pad, chip_side, chip_pad)
	ThemeKit.button_type(theme, "ChipButton", _styles(chip, chip_selected, chip_disabled, focus),
		tokens.font("body"), tokens.font_size("body"), tokens.color("ink"), tokens.color("ink_dark"), tokens.color("disabled_ink"))

	# Panels. A card is a page section: bg with a rule above and below,
	# text flush with the rules.
	theme.set_stylebox("panel", "PanelContainer", StyleBoxEmpty.new())
	var card: StyleBoxFlat = ThemeKit.box(tokens.color("bg"), 0.0)
	card.border_color = tokens.color("rule")
	card.border_width_top = roundi(rule)
	card.border_width_bottom = roundi(rule)
	ThemeKit.pad(card, 0.0, tokens.num("space_m"), 0.0, tokens.num("space_m"))
	theme.set_stylebox("panel", "CardPanel", card)
	theme.set_stylebox("panel", "PillPanel", StyleBoxEmpty.new())
	var hint: StyleBoxFlat = ThemeKit.box(tokens.color("accent"), 0.0)
	ThemeKit.pad(hint, tokens.num("board_margin"), tokens.num("space_s"), tokens.num("board_margin"), tokens.num("space_s"))
	theme.set_stylebox("panel", "HintPanel", hint)

	var hairline: StyleBoxLine = StyleBoxLine.new()
	hairline.color = tokens.color("rule")
	hairline.thickness = roundi(rule)
	theme.set_stylebox("separator", "HSeparator", hairline)
	theme.set_constant("separation", "HSeparator", roundi(rule))
	theme.set_stylebox("separator", "Hairline", hairline)
	theme.set_constant("separation", "Hairline", roundi(rule))
	return theme


## A box in a fill token with a rule outline.
static func _ruled(tokens: DirectionTokens, fill: String, radius: float, rule: float) -> StyleBoxFlat:
	var made: StyleBoxFlat = ThemeKit.box(tokens.color(fill), radius)
	made.border_color = tokens.color("rule")
	made.set_border_width_all(roundi(rule))
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
