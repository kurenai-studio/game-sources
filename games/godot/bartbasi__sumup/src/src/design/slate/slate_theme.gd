extends RefCounted
## Slate's Theme (DESIGN_SYSTEM.md 5.7): no boxes and no shadows. Buttons are
## flat rectangles with radius_button corners, button_height tall; the
## secondary button is a hairline outline in ink; pressed is a flat step to
## surface. Sheets are bg with a hairline on their open (top) edge. A Theme
## cannot set text alignment: screens left align Slate's primary buttons.

const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")


static func build(skin: SkinData) -> Theme:
	var theme: Theme = ThemeKit.new_theme(skin)
	var ink: Color = skin.color(&"ink")
	var ink_dark: Color = skin.color(&"ink_dark")
	var disabled_ink: Color = skin.color(&"disabled_ink")

	# Labels. Text pairs: ink and ink_muted on bg, surface and surface_raised;
	# accent on bg (the signal label); badge_ink on badge.
	ThemeKit.label_type(theme, &"DisplayLabel", skin, &"display", ink)
	ThemeKit.label_type(theme, &"TitleLabel", skin, &"title", ink)
	ThemeKit.label_type(theme, &"BodyLabel", skin, &"body", ink)
	ThemeKit.label_type(theme, &"MutedLabel", skin, &"body", skin.color(&"ink_muted"))
	ThemeKit.label_type(theme, &"CaptionLabel", skin, &"label", skin.color(&"ink_muted"))
	ThemeKit.label_type(theme, &"SignalLabel", skin, &"label", skin.color(&"accent"))
	ThemeKit.label_type(theme, &"BadgeLabel", skin, &"label", skin.color(&"badge_ink"))
	ThemeKit.label_type(theme, &"HintLabel", skin, &"label", skin.color(&"badge_ink"))

	var radius: float = skin.num(&"radius_button")
	var hairline: float = skin.num(&"hairline")
	var side: float = skin.num(&"space_m")
	var text_pad: float = maxf(0.0, (skin.num(&"button_height") - ThemeKit.line_height(skin, &"body")) * 0.5)
	var focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), skin.num(&"focus_width"), radius, skin.num(&"focus_gap"))

	# Disabled, for every button: a hairline outline in line on the page.
	# Text pair: disabled_ink on bg.
	var disabled: StyleBoxFlat = ThemeKit.outline(skin.color(&"line"), hairline, radius)
	ThemeKit.pad(disabled, side, text_pad, side, text_pad)

	# Primary: accent fill, a darker step when pressed. Text pairs: ink_dark on
	# accent and accent_pressed.
	var primary: StyleBoxFlat = _padded(ThemeKit.box(skin.color(&"accent"), radius), side, text_pad)
	var primary_pressed: StyleBoxFlat = _padded(ThemeKit.box(skin.color(&"accent_pressed"), radius), side, text_pad)
	ThemeKit.button_type(theme, &"PrimaryButton", ThemeKit.styles(primary, primary_pressed, disabled, focus), skin, ink_dark, ink_dark, disabled_ink)

	# Secondary: a hairline outline in ink; pressed fills surface. Text pairs:
	# ink on bg and on surface.
	var secondary: StyleBoxFlat = _padded(ThemeKit.outline(ink, hairline, radius), side, text_pad)
	var secondary_pressed: StyleBoxFlat = _padded(ThemeKit.box(skin.color(&"surface"), radius), side, text_pad)
	secondary_pressed.border_color = ink
	secondary_pressed.set_border_width_all(roundi(hairline))
	var secondary_styles: Dictionary[StringName, StyleBox] = ThemeKit.styles(secondary, secondary_pressed, disabled, focus)
	ThemeKit.button_type(theme, &"SecondaryButton", secondary_styles, skin, ink, ink, disabled_ink)
	ThemeKit.button_type(theme, &"Button", secondary_styles, skin, ink, ink, disabled_ink)

	# Chips: surface; selected (a toggle button held down) fills ink, the
	# paper, with ink_dark. Text pairs: ink on surface, ink_dark on ink.
	var chip_radius: float = skin.num(&"radius_chip")
	var chip_side: float = skin.num(&"space_s")
	var chip: StyleBoxFlat = _padded(ThemeKit.box(skin.color(&"surface"), chip_radius), chip_side, text_pad)
	var chip_selected: StyleBoxFlat = _padded(ThemeKit.box(ink, chip_radius), chip_side, text_pad)
	var chip_disabled: StyleBoxFlat = _padded(ThemeKit.outline(skin.color(&"line"), hairline, chip_radius), chip_side, text_pad)
	var chip_focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), skin.num(&"focus_width"), chip_radius, skin.num(&"focus_gap"))
	ThemeKit.button_type(theme, &"ChipButton", ThemeKit.styles(chip, chip_selected, chip_disabled, chip_focus), skin, ink, ink_dark, disabled_ink)

	ThemeKit.button_type(theme, &"IconButton", icon_button_styles(skin), skin, ink, ink, disabled_ink)

	# Panels. The sheet: bg with a hairline in line on its open (top) edge,
	# square corners, space_m padding. Text pairs: ink and ink_muted on bg.
	var pad: float = skin.num(&"space_m")
	var sheet: StyleBoxFlat = ThemeKit.box(skin.color(&"bg"), skin.num(&"radius_card"))
	sheet.border_color = skin.color(&"line")
	sheet.border_width_top = roundi(hairline)
	ThemeKit.pad(sheet, pad, pad, pad, pad)
	theme.set_stylebox(&"panel", &"CardPanel", sheet)
	theme.set_stylebox(&"panel", &"PillPanel", StyleBoxEmpty.new())

	# Badges (7.8) and the hint bar: badge fill with square corners, the label
	# line plus space_xs above and below, sides space_s.
	var badge: StyleBoxFlat = ThemeKit.box(skin.color(&"badge"), 0.0)
	ThemeKit.pad(badge, skin.num(&"space_s"), skin.num(&"space_xs"), skin.num(&"space_s"), skin.num(&"space_xs"))
	theme.set_stylebox(&"panel", &"BadgePanel", badge)
	theme.set_stylebox(&"panel", &"HintPanel", badge)

	ThemeKit.divider(theme, &"Hairline", skin.color(&"line"), hairline, false)
	ThemeKit.divider(theme, &"HSeparator", skin.color(&"line"), hairline, false)

	# Reading screens (7.11): no section box, only space_m above and below
	# its content (screens split sections with a Hairline); a pressed row
	# fills surface with square corners; the scroll indicator is a square
	# ended bar.
	var section: StyleBoxEmpty = StyleBoxEmpty.new()
	ThemeKit.pad(section, 0.0, pad, 0.0, pad)
	var row_pressed: StyleBoxFlat = ThemeKit.box(skin.color(&"surface"), 0.0)
	var row_focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), skin.num(&"focus_width"), 0.0, skin.num(&"focus_gap") + skin.num(&"space_s"))
	ThemeKit.reading_types(theme, skin, section, row_pressed, row_focus, 0.0)
	return theme


## IconButton: no container and the full touch area, touch_min square;
## pressed fills surface. UiKit.make_icon_button draws these too, with the
## icon centered.
static func icon_button_styles(skin: SkinData) -> Dictionary[StringName, StyleBox]:
	var touch: float = skin.num(&"touch_min")
	var radius: float = skin.num(&"radius_button")
	var normal: StyleBoxEmpty = StyleBoxEmpty.new()
	var pressed: StyleBoxFlat = ThemeKit.box(skin.color(&"surface"), radius)
	var disabled: StyleBoxEmpty = StyleBoxEmpty.new()
	var focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), skin.num(&"focus_width"), radius, skin.num(&"focus_gap"))
	for style: StyleBox in [normal, pressed, disabled, focus]:
		ThemeKit.pad(style, touch * 0.5, touch * 0.5, touch * 0.5, touch * 0.5)
	return ThemeKit.styles(normal, pressed, disabled, focus)


static func _padded(style: StyleBoxFlat, side: float, text_pad: float) -> StyleBoxFlat:
	ThemeKit.pad(style, side, text_pad, side, text_pad)
	return style
