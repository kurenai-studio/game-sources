extends RefCounted
## Nova's Theme (DESIGN_SYSTEM.md 6.7): floating light, almost no containers.
## The primary button is an accent pill; the secondary button is a ring
## outline pill in line that fills surface_raised when pressed; chips are
## surface_raised pills. The sheet is surface with radius_card top corners.

const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")


static func build(skin: SkinData) -> Theme:
	var theme: Theme = ThemeKit.new_theme(skin)
	var ink: Color = skin.color(&"ink")
	var ink_dark: Color = skin.color(&"ink_dark")
	var disabled_ink: Color = skin.color(&"disabled_ink")
	var muted: Color = skin.color(&"ink_muted")

	# Labels. Text pairs: ink and ink_muted on the backdrop (bg_glow is the
	# worst case), on surface, surface_raised and the scrim; badge_ink on badge.
	ThemeKit.label_type(theme, &"DisplayLabel", skin, &"display", ink)
	ThemeKit.label_type(theme, &"TitleLabel", skin, &"title", ink)
	ThemeKit.label_type(theme, &"BodyLabel", skin, &"body", ink)
	ThemeKit.label_type(theme, &"MutedLabel", skin, &"body", muted)
	ThemeKit.label_type(theme, &"CaptionLabel", skin, &"label", muted)
	ThemeKit.label_type(theme, &"SignalLabel", skin, &"title", ink)
	ThemeKit.label_type(theme, &"BadgeLabel", skin, &"label", skin.color(&"badge_ink"))
	ThemeKit.label_type(theme, &"HintLabel", skin, &"label", muted)

	var radius: float = skin.num(&"radius_button")
	var ring: float = skin.num(&"ring_width")
	var side: float = skin.num(&"space_m")
	var text_pad: float = maxf(0.0, (skin.num(&"button_height") - ThemeKit.line_height(skin, &"body")) * 0.5)
	# The focus ring is ring_width wide, focus_gap outside the button.
	var focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), ring, radius, skin.num(&"focus_gap"))

	# Disabled, for every button: a faint ring at disabled_ring_alpha, text in
	# disabled_ink. Text pair: disabled_ink on bg_glow.
	var faint: Color = Color(skin.color(&"line"), skin.num(&"disabled_ring_alpha"))
	var disabled: StyleBoxFlat = _padded(ThemeKit.outline(faint, ring, radius), side, text_pad)

	# Primary: an accent pill, accent_pressed when pressed. Text pairs: ink_dark
	# on accent and accent_pressed.
	var primary: StyleBoxFlat = _padded(ThemeKit.box(skin.color(&"accent"), radius), side, text_pad)
	var primary_pressed: StyleBoxFlat = _padded(ThemeKit.box(skin.color(&"accent_pressed"), radius), side, text_pad)
	ThemeKit.button_type(theme, &"PrimaryButton", ThemeKit.styles(primary, primary_pressed, disabled, focus), skin, ink_dark, ink_dark, disabled_ink)

	# Secondary: a ring outline pill in line; pressed fills surface_raised.
	# Text pairs: ink on surface (the sheet) and on surface_raised.
	var secondary: StyleBoxFlat = _padded(ThemeKit.outline(skin.color(&"line"), ring, radius), side, text_pad)
	var secondary_pressed: StyleBoxFlat = _padded(ThemeKit.box(skin.color(&"surface_raised"), radius), side, text_pad)
	secondary_pressed.border_color = skin.color(&"line")
	secondary_pressed.set_border_width_all(roundi(ring))
	var secondary_styles: Dictionary[StringName, StyleBox] = ThemeKit.styles(secondary, secondary_pressed, disabled, focus)
	ThemeKit.button_type(theme, &"SecondaryButton", secondary_styles, skin, ink, ink, disabled_ink)
	ThemeKit.button_type(theme, &"Button", secondary_styles, skin, ink, ink, disabled_ink)

	# Chips: surface_raised pills; selected (a toggle button held down) fills
	# accent. Text pairs: ink on surface_raised, ink_dark on accent.
	var chip_radius: float = skin.num(&"radius_chip")
	var chip_side: float = skin.num(&"space_s")
	var chip: StyleBoxFlat = _padded(ThemeKit.box(skin.color(&"surface_raised"), chip_radius), chip_side, text_pad)
	var chip_selected: StyleBoxFlat = _padded(ThemeKit.box(skin.color(&"accent"), chip_radius), chip_side, text_pad)
	var chip_disabled: StyleBoxFlat = _padded(ThemeKit.outline(faint, ring, chip_radius), chip_side, text_pad)
	var chip_focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), ring, chip_radius, skin.num(&"focus_gap"))
	ThemeKit.button_type(theme, &"ChipButton", ThemeKit.styles(chip, chip_selected, chip_disabled, chip_focus), skin, ink, ink_dark, disabled_ink)

	ThemeKit.button_type(theme, &"IconButton", icon_button_styles(skin), skin, ink, ink, disabled_ink)

	# The sheet: surface, radius_card top corners, space_m padding.
	var pad: float = skin.num(&"space_m")
	var sheet: StyleBoxFlat = ThemeKit.box(skin.color(&"surface"), 0.0)
	sheet.corner_radius_top_left = roundi(skin.num(&"radius_card"))
	sheet.corner_radius_top_right = roundi(skin.num(&"radius_card"))
	ThemeKit.pad(sheet, pad, pad, pad, pad)
	theme.set_stylebox(&"panel", &"CardPanel", sheet)
	theme.set_stylebox(&"panel", &"PillPanel", StyleBoxEmpty.new())
	# The hint has no panel: centered ink_muted text (HintLabel).
	theme.set_stylebox(&"panel", &"HintPanel", StyleBoxEmpty.new())

	# Badges (7.8): full pills in badge, the label line plus space_xs above and
	# below, sides space_s.
	var badge_height: float = ThemeKit.line_height(skin, &"label") + skin.num(&"space_xs") * 2.0
	var badge: StyleBoxFlat = ThemeKit.box(skin.color(&"badge"), badge_height * 0.5)
	ThemeKit.pad(badge, skin.num(&"space_s"), skin.num(&"space_xs"), skin.num(&"space_s"), skin.num(&"space_xs"))
	theme.set_stylebox(&"panel", &"BadgePanel", badge)

	ThemeKit.divider(theme, &"Hairline", skin.color(&"line"), skin.num(&"hairline"), false)
	ThemeKit.divider(theme, &"HSeparator", skin.color(&"line"), skin.num(&"hairline"), false)

	# Reading screens (7.11): no box and no lines (sections stand space_l
	# apart, set by the screen); a pressed row fills surface_raised with
	# radius_chip corners; the scroll indicator is a pill.
	var row_pressed: StyleBoxFlat = ThemeKit.box(skin.color(&"surface_raised"), skin.num(&"radius_chip"))
	var row_focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), ring, skin.num(&"radius_chip"), skin.num(&"focus_gap") + skin.num(&"space_s"))
	ThemeKit.reading_types(theme, skin, StyleBoxEmpty.new(), row_pressed, row_focus, skin.num(&"scroll_bar") * 0.5)
	return theme


## IconButton: a hud_ring ring in line, ring_width wide, centered in a
## touch_min square button. Pressed brightens the ring to ink; disabled
## fades it to disabled_ring_alpha. UiKit.make_icon_button draws these too,
## with the icon in the ring.
static func icon_button_styles(skin: SkinData) -> Dictionary[StringName, StyleBox]:
	var touch: float = skin.num(&"touch_min")
	var ring_side: float = skin.num(&"hud_ring")
	var ring: float = skin.num(&"ring_width")
	var radius: float = ring_side * 0.5
	var inset: float = (touch - ring_side) * 0.5
	var normal: StyleBoxFlat = ThemeKit.outline(skin.color(&"line"), ring, radius)
	var pressed: StyleBoxFlat = ThemeKit.outline(skin.color(&"ink"), ring, radius)
	var disabled: StyleBoxFlat = ThemeKit.outline(Color(skin.color(&"line"), skin.num(&"disabled_ring_alpha")), ring, radius)
	for style: StyleBoxFlat in [normal, pressed, disabled]:
		style.set_expand_margin_all(-inset)
	var focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), ring, radius, skin.num(&"focus_gap"), Vector4(inset, inset, inset, inset))
	var made: Dictionary[StringName, StyleBox] = ThemeKit.styles(normal, pressed, disabled, focus)
	for style: StyleBox in [normal, pressed, disabled, focus]:
		ThemeKit.pad(style, touch * 0.5, touch * 0.5, touch * 0.5, touch * 0.5)
	return made


static func _padded(style: StyleBoxFlat, side: float, text_pad: float) -> StyleBoxFlat:
	ThemeKit.pad(style, side, text_pad, side, text_pad)
	return style
