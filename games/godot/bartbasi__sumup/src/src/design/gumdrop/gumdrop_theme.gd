extends RefCounted
## Gumdrop's Theme (DESIGN_SYSTEM.md 4.7): every button, chip, pill and card
## is soft raised candy with a darker lip underneath. A pressed button sinks
## onto a thinner lip; a disabled one lies flat with no lip, lower than the
## others. Every button is button_height tall, lip included.

const ThemeKit: GDScript = preload("res://src/design/shared/theme_kit.gd")
const Candy: GDScript = preload("res://src/design/gumdrop/gumdrop_candy.gd")


static func build(skin: SkinData) -> Theme:
	var theme: Theme = ThemeKit.new_theme(skin)
	var ink: Color = skin.color(&"ink")
	var ink_dark: Color = skin.color(&"ink_dark")
	var disabled_ink: Color = skin.color(&"disabled_ink")

	# Labels. Text pairs: ink and ink_muted on bg, surface and surface_raised;
	# badge_ink on badge.
	ThemeKit.label_type(theme, &"DisplayLabel", skin, &"display", ink)
	ThemeKit.label_type(theme, &"TitleLabel", skin, &"title", ink)
	ThemeKit.label_type(theme, &"BodyLabel", skin, &"body", ink)
	ThemeKit.label_type(theme, &"MutedLabel", skin, &"body", skin.color(&"ink_muted"))
	ThemeKit.label_type(theme, &"CaptionLabel", skin, &"label", skin.color(&"ink_muted"))
	ThemeKit.label_type(theme, &"SignalLabel", skin, &"title", ink)
	ThemeKit.label_type(theme, &"BadgeLabel", skin, &"label", skin.color(&"badge_ink"))
	ThemeKit.label_type(theme, &"HintLabel", skin, &"label", skin.color(&"badge_ink"))

	# Buttons. Text pairs: ink_dark on accent and accent_pressed, ink on
	# surface_raised, disabled_ink on disabled_surface.
	var radius: float = skin.num(&"radius_button")
	var side: float = skin.num(&"space_m")
	var primary: Dictionary[StringName, StyleBox] = _button_styles(skin, &"accent", &"accent_pressed", &"accent_lip", radius, side)
	ThemeKit.button_type(theme, &"PrimaryButton", primary, skin, ink_dark, ink_dark, disabled_ink)
	var secondary: Dictionary[StringName, StyleBox] = _button_styles(skin, &"surface_raised", &"surface_raised", &"surface_lip", radius, side)
	ThemeKit.button_type(theme, &"SecondaryButton", secondary, skin, ink, ink, disabled_ink)
	ThemeKit.button_type(theme, &"Button", secondary, skin, ink, ink, disabled_ink)

	# Chips: surface_raised candy with radius_chip corners. A selected chip
	# (a toggle button held down) is the raised accent candy with ink_dark.
	var chip_radius: float = skin.num(&"radius_chip")
	var chip_side: float = skin.num(&"space_s")
	var chip: Dictionary[StringName, StyleBox] = _button_styles(skin, &"surface_raised", &"surface_raised", &"surface_lip", chip_radius, chip_side)
	var selected: Dictionary[StringName, StyleBox] = _button_styles(skin, &"accent", &"accent", &"accent_lip", chip_radius, chip_side)
	chip[&"pressed"] = selected[&"normal"]
	chip[&"hover_pressed"] = selected[&"normal"]
	ThemeKit.button_type(theme, &"ChipButton", chip, skin, ink, ink_dark, disabled_ink)

	ThemeKit.button_type(theme, &"IconButton", icon_button_styles(skin), skin, ink, ink, disabled_ink)

	# Panels. Cards and sheets are lipped surface cards. Text pairs: ink and
	# ink_muted on surface.
	var lip: float = skin.num(&"button_lip")
	var pad: float = skin.num(&"space_m")
	var card: StyleBoxFlat = Candy.raised(skin.color(&"surface"), skin.color(&"surface_lip"), skin.num(&"radius_card"), lip)
	ThemeKit.pad(card, pad, pad, pad, pad + lip)
	theme.set_stylebox(&"panel", &"CardPanel", card)

	var pill: StyleBoxFlat = Candy.raised(skin.color(&"surface"), skin.color(&"surface_lip"), skin.num(&"pill_radius"), lip)
	var pill_pad: float = maxf(0.0, (skin.num(&"pill_height") - lip - ThemeKit.line_height(skin, &"body")) * 0.5)
	ThemeKit.pad(pill, skin.num(&"space_s"), pill_pad, skin.num(&"space_s"), pill_pad + lip)
	theme.set_stylebox(&"panel", &"PillPanel", pill)

	# Badges (7.8) and the hint pill: a lemon pill, the label line plus
	# space_xs above and below, sides space_s, with a badge_lip lip.
	var badge_face: float = ThemeKit.line_height(skin, &"label") + skin.num(&"space_xs") * 2.0
	var badge: StyleBoxFlat = Candy.badge(skin, badge_face)
	ThemeKit.pad(badge, skin.num(&"space_s"), skin.num(&"space_xs"), skin.num(&"space_s"), skin.num(&"space_xs") + lip)
	theme.set_stylebox(&"panel", &"BadgePanel", badge)
	theme.set_stylebox(&"panel", &"HintPanel", badge)

	# Divider: a hairline rounded line in line, visible on bg and on cards.
	ThemeKit.divider(theme, &"Hairline", skin.color(&"line"), skin.num(&"hairline"), true)
	ThemeKit.divider(theme, &"HSeparator", skin.color(&"line"), skin.num(&"hairline"), true)

	# Reading screens (7.11): each section is a lipped card like CardPanel;
	# a pressed row fills surface_raised with radius_chip corners; the scroll
	# indicator is a pill.
	var section: StyleBoxFlat = Candy.raised(skin.color(&"surface"), skin.color(&"surface_lip"), skin.num(&"radius_card"), lip)
	ThemeKit.pad(section, pad, pad, pad, pad + lip)
	var row_pressed: StyleBoxFlat = ThemeKit.box(skin.color(&"surface_raised"), skin.num(&"radius_chip"))
	var row_focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), skin.num(&"focus_width"), skin.num(&"radius_chip"), skin.num(&"focus_gap") + skin.num(&"space_s"))
	ThemeKit.reading_types(theme, skin, section, row_pressed, row_focus, skin.num(&"scroll_bar") * 0.5)
	return theme


## Normal, hover, pressed, hover_pressed, disabled and focus styles for a
## raised button button_height tall, lip included.
static func _button_styles(skin: SkinData, fill: StringName, pressed_fill: StringName, lip_color: StringName, radius: float, side: float) -> Dictionary[StringName, StyleBox]:
	var lip: float = skin.num(&"button_lip")
	var pressed_lip: float = skin.num(&"button_lip_pressed")
	var sink: float = lip - pressed_lip
	var text_pad: float = maxf(0.0, (skin.num(&"button_height") - lip - ThemeKit.line_height(skin, &"body")) * 0.5)

	var normal: StyleBoxFlat = Candy.raised(skin.color(fill), skin.color(lip_color), radius, lip)
	ThemeKit.pad(normal, side, text_pad, side, text_pad + lip)

	# Pressed: the face sinks onto a thinner lip; the text moves down with it.
	var pressed: StyleBoxFlat = Candy.raised(skin.color(pressed_fill), skin.color(lip_color), radius, pressed_lip)
	pressed.expand_margin_top = -sink
	ThemeKit.pad(pressed, side, text_pad + sink, side, text_pad + pressed_lip)

	# Disabled: flat, no lip, sitting at the bottom of the lip's space.
	var disabled: StyleBoxFlat = ThemeKit.box(skin.color(&"disabled_surface"), radius)
	disabled.expand_margin_top = -lip
	ThemeKit.pad(disabled, side, text_pad + lip, side, text_pad)

	var focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), skin.num(&"focus_width"), radius, skin.num(&"focus_gap"))
	return ThemeKit.styles(normal, pressed, disabled, focus)


## IconButton: a raised squircle face hud_button_face wide (corners tile_radius
## of the face, like a tile) centered in a touch_min square button, its lip
## below the face. UiKit.make_icon_button draws these too, with the icon on
## the face.
static func icon_button_styles(skin: SkinData) -> Dictionary[StringName, StyleBox]:
	var touch: float = skin.num(&"touch_min")
	var face: float = skin.num(&"hud_button_face")
	var lip: float = skin.num(&"button_lip")
	var pressed_lip: float = skin.num(&"button_lip_pressed")
	var radius: float = skin.num(&"tile_radius") * face
	var inset: float = (touch - face) * 0.5
	var below: float = touch - inset - face - lip

	var normal: StyleBoxFlat = Candy.raised(skin.color(&"surface_raised"), skin.color(&"surface_lip"), radius, lip)
	_inset(normal, inset, inset, below)
	var pressed: StyleBoxFlat = Candy.raised(skin.color(&"surface_raised"), skin.color(&"surface_lip"), radius, pressed_lip)
	_inset(pressed, inset, inset + lip - pressed_lip, below)
	var disabled: StyleBoxFlat = ThemeKit.box(skin.color(&"disabled_surface"), radius)
	_inset(disabled, inset, inset + lip, below)
	var focus: StyleBoxFlat = ThemeKit.focus_ring(skin.color(&"accent"), skin.num(&"focus_width"), radius, skin.num(&"focus_gap"), Vector4(inset, inset, inset, below))
	var made: Dictionary[StringName, StyleBox] = ThemeKit.styles(normal, pressed, disabled, focus)
	for style: StyleBox in [normal, pressed, disabled, focus]:
		ThemeKit.pad(style, touch * 0.5, touch * 0.5, touch * 0.5, touch * 0.5)
	return made


## Draws the box inset from the control's sides, top and bottom.
static func _inset(target: StyleBoxFlat, side: float, top: float, bottom: float) -> void:
	target.expand_margin_left = -side
	target.expand_margin_right = -side
	target.expand_margin_top = -top
	target.expand_margin_bottom = -bottom
