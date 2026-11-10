class_name UiTheme
extends RefCounted
## Builds the Theme for a panel skin: the font, the text colours and the stitched button boxes.
## The colour constants are the neutral defaults for things that are not skinned.

const INK: Color = Color("2b2d42")
const PAPER_LIGHT: Color = Color("fffaf0")
const MUTED: Color = Color("8a7f6a")


static func make(skin: PanelSkin) -> Theme:
	var theme: Theme = Theme.new()
	theme.default_font = skin.font()
	theme.default_font_size = PanelSkin.FONT_SIZE
	theme.set_color("font_color", "Label", skin.ink)
	theme.set_constant("line_spacing", "Label", PanelSkin.LINE_SPACING)
	_style_scrollbar(theme, skin)
	theme.set_stylebox("normal", "Button", _button_box(skin, &"normal"))
	theme.set_stylebox("hover", "Button", _button_box(skin, &"hover"))
	theme.set_stylebox("pressed", "Button", _button_box(skin, &"pressed"))
	theme.set_stylebox("disabled", "Button", _button_box(skin, &"disabled"))
	theme.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	for state: String in ["font_color", "font_hover_color", "font_pressed_color"]:
		theme.set_color(state, "Button", skin.button_text)
	theme.set_color("font_disabled_color", "Button", skin.button_text_disabled)
	return theme


## The panel's own background: the skin's art, drawn at its exact size (`height` rows).
static func panel_box(skin: PanelSkin, height: int = PanelSkin.PANEL_HEIGHT) -> StyleBoxTexture:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = skin.panel_texture(height)
	box.content_margin_left = skin.content_margins.position.x
	box.content_margin_top = skin.content_margins.position.y
	box.content_margin_right = skin.content_margins.size.x
	box.content_margin_bottom = skin.content_margins.size.y
	return box


static func _style_scrollbar(theme: Theme, skin: PanelSkin) -> void:
	var track: StyleBoxFlat = StyleBoxFlat.new()
	track.bg_color = skin.scroll_track
	track.set_border_width_all(1)
	track.border_color = INK
	track.content_margin_left = 2.0
	track.content_margin_right = 2.0
	theme.set_stylebox("scroll", "VScrollBar", track)
	theme.set_stylebox("scroll_focus", "VScrollBar", track)
	var grabber: StyleBoxFlat = StyleBoxFlat.new()
	grabber.bg_color = skin.scroll_grabber
	grabber.set_border_width_all(1)
	grabber.border_color = INK
	for name: String in ["grabber", "grabber_highlight", "grabber_pressed"]:
		theme.set_stylebox(name, "VScrollBar", grabber)
	for arrow: String in ["increment", "decrement", "increment_highlight", "decrement_highlight", "increment_pressed", "decrement_pressed"]:
		theme.set_icon(arrow, "VScrollBar", PlaceholderTexture2D.new())


static func _button_box(skin: PanelSkin, state: StringName) -> StyleBoxTexture:
	var box: StyleBoxTexture = StyleBoxTexture.new()
	box.texture = skin.piece(skin.button_regions[state])
	box.set_texture_margin_all(PanelSkin.BUTTON_MARGIN)
	box.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
	box.content_margin_left = 7.0
	box.content_margin_right = 7.0
	box.content_margin_top = 3.0
	box.content_margin_bottom = 3.0
	return box
