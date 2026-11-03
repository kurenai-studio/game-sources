class_name UiTheme
extends RefCounted
## Single source of truth for the visual language. tools/build_theme.gd bakes this to ui/theme.tres.

const BG := Color("0a0d18")
const PANEL := Color("121829")
const PANEL_2 := Color("1b2338")
const ACCENT := Color("3ee6ff")
const ACCENT_2 := Color("ff4f9a")
const GOLD := Color("ffcf4a")
const TEXT := Color("e8ecff")
const MUTED := Color("8b94b9")
const DANGER := Color("ff4d5e")
const SUCCESS := Color("5dff9a")
const RARITY_COLORS: Array[Color] = [Color("a9bbdf"), Color("3ee6ff"), Color("c76bff")]


static func _font(path: String, weight: int) -> FontVariation:
	var fv := FontVariation.new()
	fv.base_font = load(path)
	fv.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): weight}
	return fv


static func body_font(weight: int = 500) -> FontVariation:
	return _font("res://assets/fonts/Outfit.ttf", weight)


static func title_font(weight: int = 800) -> FontVariation:
	return _font("res://assets/fonts/Orbitron.ttf", weight)


static func box(bg: Color, border: Color = Color.TRANSPARENT, border_w: int = 0, radius: int = 10,
		pad: Vector4 = Vector4(18, 10, 18, 10)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(border_w)
	s.set_corner_radius_all(radius)
	s.content_margin_left = pad.x
	s.content_margin_top = pad.y
	s.content_margin_right = pad.z
	s.content_margin_bottom = pad.w
	s.anti_aliasing = true
	return s


static func _circle_texture(size: int, color: Color) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var c := Vector2(size, size) / 2.0
	for y in size:
		for x in size:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(c)
			var a := clampf(size / 2.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(color, a))
	return ImageTexture.create_from_image(img)


static func build() -> Theme:
	var t := Theme.new()
	t.default_font = body_font(500)
	t.default_font_size = 20

	var focus := box(Color.TRANSPARENT, ACCENT, 3, 12)
	focus.draw_center = false
	focus.expand_margin_left = 3
	focus.expand_margin_right = 3
	focus.expand_margin_top = 3
	focus.expand_margin_bottom = 3
	for type in ["Button", "OptionButton", "CheckButton"]:
		t.set_stylebox("normal", type, box(PANEL_2, Color(ACCENT, 0.25), 2, 10))
		t.set_stylebox("hover", type, box(Color("24304d"), ACCENT, 2, 10))
		t.set_stylebox("pressed", type, box(ACCENT.darkened(0.15), ACCENT, 2, 10))
		t.set_stylebox("hover_pressed", type, box(ACCENT, ACCENT, 2, 10))
		t.set_stylebox("disabled", type, box(Color(PANEL_2, 0.5), Color(MUTED, 0.2), 2, 10))
		t.set_stylebox("focus", type, focus)
		t.set_color("font_color", type, TEXT)
		t.set_color("font_hover_color", type, Color.WHITE)
		t.set_color("font_focus_color", type, Color.WHITE)
		t.set_color("font_pressed_color", type, BG)
		t.set_color("font_hover_pressed_color", type, BG)
		t.set_color("font_disabled_color", type, MUTED)
		t.set_font_size("font_size", type, 22)

	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.55))
	t.set_constant("shadow_offset_y", "Label", 2)
	t.set_constant("shadow_offset_x", "Label", 0)

	t.set_type_variation("TitleLabel", "Label")
	t.set_font("font", "TitleLabel", title_font(900))
	t.set_font_size("font_size", "TitleLabel", 84)
	t.set_color("font_outline_color", "TitleLabel", Color(ACCENT, 0.35))
	t.set_constant("outline_size", "TitleLabel", 10)

	t.set_type_variation("HeaderLabel", "Label")
	t.set_font("font", "HeaderLabel", title_font(700))
	t.set_font_size("font_size", "HeaderLabel", 34)

	t.set_type_variation("HudLabel", "Label")
	t.set_font("font", "HudLabel", title_font(700))
	t.set_font_size("font_size", "HudLabel", 22)
	t.set_color("font_outline_color", "HudLabel", Color(0, 0, 0, 0.7))
	t.set_constant("outline_size", "HudLabel", 6)

	t.set_type_variation("MutedLabel", "Label")
	t.set_color("font_color", "MutedLabel", MUTED)
	t.set_font_size("font_size", "MutedLabel", 17)

	t.set_type_variation("AccentLabel", "Label")
	t.set_color("font_color", "AccentLabel", ACCENT)
	t.set_font("font", "AccentLabel", body_font(700))

	t.set_type_variation("GoldLabel", "Label")
	t.set_color("font_color", "GoldLabel", GOLD)
	t.set_font("font", "GoldLabel", title_font(700))
	t.set_font_size("font_size", "GoldLabel", 22)

	var panel := box(Color(PANEL, 0.94), Color(ACCENT, 0.22), 1, 18, Vector4(28, 24, 28, 24))
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 18
	t.set_stylebox("panel", "PanelContainer", panel)
	t.set_stylebox("panel", "Panel", panel)
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", box(Color(PANEL_2, 0.92), Color(1, 1, 1, 0.06), 1, 14, Vector4(18, 14, 18, 14)))

	t.set_stylebox("background", "ProgressBar", box(Color(1, 1, 1, 0.08), Color.TRANSPARENT, 0, 6, Vector4.ZERO))
	t.set_stylebox("fill", "ProgressBar", box(ACCENT, Color.TRANSPARENT, 0, 6, Vector4.ZERO))
	t.set_constant("outline_size", "ProgressBar", 0)

	t.set_stylebox("slider", "HSlider", box(Color(1, 1, 1, 0.1), Color.TRANSPARENT, 0, 4, Vector4(0, 4, 0, 4)))
	t.set_stylebox("grabber_area", "HSlider", box(ACCENT, Color.TRANSPARENT, 0, 4, Vector4(0, 4, 0, 4)))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(ACCENT.lightened(0.2), Color.TRANSPARENT, 0, 4, Vector4(0, 4, 0, 4)))
	t.set_icon("grabber", "HSlider", _circle_texture(22, Color.WHITE))
	t.set_icon("grabber_highlight", "HSlider", _circle_texture(24, ACCENT))
	t.set_stylebox("focus", "HSlider", focus)

	t.set_stylebox("panel", "PopupMenu", box(PANEL, ACCENT, 1, 10, Vector4(8, 8, 8, 8)))
	t.set_stylebox("hover", "PopupMenu", box(Color(ACCENT, 0.25), Color.TRANSPARENT, 0, 6))
	t.set_stylebox("panel", "TooltipPanel", box(PANEL, ACCENT, 1, 8))
	return t
