# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name UiTheme
extends RefCounted
## The Godot Theme for every screen, built in code (docs/art/THEME.md).
##
## Outfit everywhere (SIL Open Font License 1.1, src/theme/fonts/). Sizes are
## in the project's logical pixels (1080 wide base): on the Fold5 cover screen
## one dp is about 3.1 of them, so body text at 46 is about 15 dp.
##
## Type variations, set with `theme_type_variation`:
## - Button: dark raised button with light text.
## - PrimaryButton: the honey button with dark text (Play, Start wave).
## - CardButton: a cream card with dark text (tower cards, mode cards).
## - QuietButton: no fill, soft text (the quiet coffee row in Pause).
## - PanelContainer and Panel: the dark panel. CardPanel: the cream card.
## - Label: light text for dark panels. TitleLabel: big and bold.
##   SoftLabel: secondary text on dark panels. CardLabel and CardMutedLabel:
##   dark and muted text on a CardPanel. Labels never sit straight on the map:
##   put them on a panel, or draw map text with an ink outline.

const FONT_SMALL: int = 40
const FONT_BODY: int = 46
const FONT_BUTTON: int = 52
const FONT_TITLE: int = 76
const FONT_HUGE: int = 112
const WEIGHT_REGULAR: int = 450
const WEIGHT_BOLD: int = 650
const WEIGHT_HEAVY: int = 800
const RADIUS: int = 30
const BORDER: int = 4
const PAD_X: int = 36
const PAD_Y: int = 22

const OUTFIT: FontFile = preload("res://src/theme/fonts/Outfit[wght].ttf")

static var _fonts: Dictionary[int, FontVariation] = {}


## Outfit at a weight from 100 to 900. Cached, so every caller shares one.
static func font(weight: int = WEIGHT_REGULAR) -> FontVariation:
	var w: int = clampi(weight, 100, 900)
	if _fonts.has(w):
		return _fonts[w]
	var f: FontVariation = FontVariation.new()
	f.base_font = OUTFIT
	var wght: int = TextServerManager.get_primary_interface().name_to_tag("wght")
	f.variation_opentype = {wght: w}
	_fonts[w] = f
	return f


static func build() -> Theme:
	var t: Theme = Theme.new()
	t.default_font = font(WEIGHT_REGULAR)
	t.default_font_size = FONT_BODY
	_labels(t)
	_button(t, &"Button", Palette.PANEL_RAISED, Palette.PANEL_HOVER, Palette.PANEL, Palette.PANEL_EDGE, Palette.TEXT_LIGHT, Palette.TEXT_SOFT)
	_button(t, &"PrimaryButton", Palette.HONEY, Palette.HONEY, Palette.HONEY_PRESSED, Palette.INK_LINE, Palette.TEXT_DARK, Palette.TEXT_MUTED)
	_button(t, &"CardButton", Palette.CARD, Palette.CARD, Palette.CARD_DIM, Palette.INK_LINE, Palette.TEXT_DARK, Palette.TEXT_MUTED)
	_quiet_button(t)
	t.set_type_variation(&"PrimaryButton", &"Button")
	t.set_type_variation(&"CardButton", &"Button")
	t.set_type_variation(&"QuietButton", &"Button")
	t.set_font(&"font", &"PrimaryButton", font(WEIGHT_BOLD))
	t.set_font_size(&"font_size", &"PrimaryButton", FONT_BUTTON)
	var dark: StyleBoxFlat = _box(Palette.PANEL, Palette.PANEL_EDGE, RADIUS + 4, BORDER - 1)
	dark.set_content_margin_all(32)
	t.set_stylebox(&"panel", &"PanelContainer", dark)
	t.set_stylebox(&"panel", &"Panel", dark)
	var card: StyleBoxFlat = _box(Palette.CARD, Palette.INK_LINE, RADIUS, BORDER - 1)
	card.set_content_margin_all(32)
	t.set_type_variation(&"CardPanel", &"PanelContainer")
	t.set_stylebox(&"panel", &"CardPanel", card)
	_scrollbar(t)
	return t


## For tests and reviews: every label variation and the backgrounds it may sit on.
static func label_backgrounds() -> Dictionary[StringName, Array]:
	return {
		&"Label": [Palette.PANEL, Palette.PANEL_RAISED, Palette.SKY_TOP],
		&"TitleLabel": [Palette.PANEL, Palette.PANEL_RAISED, Palette.SKY_TOP],
		&"SoftLabel": [Palette.PANEL, Palette.PANEL_RAISED],
		&"CardLabel": [Palette.CARD, Palette.CARD_DIM],
		&"CardMutedLabel": [Palette.CARD, Palette.CARD_DIM],
	}


static func _labels(t: Theme) -> void:
	t.set_color(&"font_color", &"Label", Palette.TEXT_LIGHT)
	t.set_color(&"font_outline_color", &"Label", Palette.INK_LINE)
	t.set_constant(&"line_spacing", &"Label", 4)
	var variations: Dictionary[StringName, Color] = {
		&"TitleLabel": Palette.TEXT_LIGHT, &"SoftLabel": Palette.TEXT_SOFT,
		&"CardLabel": Palette.TEXT_DARK, &"CardMutedLabel": Palette.TEXT_MUTED,
	}
	for v: StringName in variations:
		t.set_type_variation(v, &"Label")
		t.set_color(&"font_color", v, variations[v])
	t.set_font(&"font", &"TitleLabel", font(WEIGHT_BOLD))
	t.set_font_size(&"font_size", &"TitleLabel", FONT_TITLE)
	t.set_font(&"font", &"CardLabel", font(WEIGHT_BOLD))
	t.set_font_size(&"font_size", &"SoftLabel", FONT_SMALL)
	t.set_font_size(&"font_size", &"CardMutedLabel", FONT_SMALL)


static func _button(t: Theme, type: StringName, normal: Color, hover: Color, pressed: Color, edge: Color, text: Color, disabled_text: Color) -> void:
	t.set_stylebox(&"normal", type, _box(normal, edge, RADIUS, BORDER))
	t.set_stylebox(&"hover", type, _box(hover, edge, RADIUS, BORDER))
	t.set_stylebox(&"pressed", type, _box(pressed, Palette.HONEY if type == &"Button" else edge, RADIUS, BORDER + 2))
	t.set_stylebox(&"hover_pressed", type, _box(pressed, Palette.HONEY if type == &"Button" else edge, RADIUS, BORDER + 2))
	var off: StyleBoxFlat = _box(normal, edge, RADIUS, BORDER)
	off.shadow_size = 0
	t.set_stylebox(&"disabled", type, off)
	# Touch only: no focus ring after a tap.
	t.set_stylebox(&"focus", type, StyleBoxEmpty.new())
	for state: StringName in [&"font_color", &"font_hover_color", &"font_pressed_color", &"font_hover_pressed_color", &"font_focus_color"]:
		t.set_color(state, type, text)
	t.set_color(&"font_disabled_color", type, disabled_text)
	t.set_color(&"icon_normal_color", type, text)
	t.set_color(&"icon_disabled_color", type, disabled_text)
	t.set_font(&"font", type, font(WEIGHT_BOLD))
	t.set_font_size(&"font_size", type, FONT_BUTTON if type == &"Button" else FONT_BODY)
	t.set_constant(&"h_separation", type, 16)


static func _quiet_button(t: Theme) -> void:
	var clear: StyleBoxFlat = _box(Color(Palette.PANEL, 0.0), Color(Palette.PANEL_EDGE, 0.0), RADIUS, 0)
	clear.shadow_size = 0
	var touched: StyleBoxFlat = _box(Palette.PANEL_RAISED, Palette.PANEL_EDGE, RADIUS, 2)
	touched.shadow_size = 0
	for state: StringName in [&"normal", &"hover", &"disabled"]:
		t.set_stylebox(state, &"QuietButton", clear)
	t.set_stylebox(&"pressed", &"QuietButton", touched)
	t.set_stylebox(&"hover_pressed", &"QuietButton", touched)
	t.set_stylebox(&"focus", &"QuietButton", StyleBoxEmpty.new())
	for state: StringName in [&"font_color", &"font_hover_color", &"font_focus_color", &"font_disabled_color"]:
		t.set_color(state, &"QuietButton", Palette.TEXT_SOFT)
	t.set_color(&"font_pressed_color", &"QuietButton", Palette.TEXT_LIGHT)
	t.set_color(&"font_hover_pressed_color", &"QuietButton", Palette.TEXT_LIGHT)
	t.set_font(&"font", &"QuietButton", font(WEIGHT_REGULAR))
	t.set_font_size(&"font_size", &"QuietButton", FONT_SMALL)


static func _scrollbar(t: Theme) -> void:
	var track: StyleBoxFlat = _box(Color(Palette.PANEL, 0.0), Color(Palette.PANEL, 0.0), 10, 0)
	track.shadow_size = 0
	track.content_margin_left = 14.0
	track.content_margin_right = 14.0
	var grab: StyleBoxFlat = _box(Palette.PANEL_EDGE, Palette.PANEL_EDGE, 10, 0)
	grab.shadow_size = 0
	var grab_on: StyleBoxFlat = _box(Palette.TEXT_SOFT, Palette.TEXT_SOFT, 10, 0)
	grab_on.shadow_size = 0
	t.set_stylebox(&"scroll", &"VScrollBar", track)
	t.set_stylebox(&"grabber", &"VScrollBar", grab)
	t.set_stylebox(&"grabber_highlight", &"VScrollBar", grab_on)
	t.set_stylebox(&"grabber_pressed", &"VScrollBar", grab_on)


static func _box(fill: Color, edge: Color, radius: int, border: int) -> StyleBoxFlat:
	var sb: StyleBoxFlat = StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = edge
	sb.set_border_width_all(border)
	sb.set_corner_radius_all(radius)
	sb.corner_detail = 8
	sb.anti_aliasing = true
	sb.shadow_color = Color(0.04, 0.02, 0.08, 0.35)
	sb.shadow_size = 6
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = PAD_X
	sb.content_margin_right = PAD_X
	sb.content_margin_top = PAD_Y
	sb.content_margin_bottom = PAD_Y
	return sb
