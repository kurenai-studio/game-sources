class_name UI
extends RefCounted
## UI helpers: pixel theme, buttons, labels, panels.

const FONT_PATH := "res://assets/fonts/Tiny5-Regular.ttf"
const TITLE_FONT_PATH := "res://assets/fonts/PressStart2P-Regular.ttf"

static var _font: FontFile
static var _title_font: FontFile
static var _boxes := {}


static func _pixelize(f: FontFile, subpixel := false) -> FontFile:
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.hinting = TextServer.HINTING_NONE
	# Tiny5 is drawn for 8 px but used at 10: with whole-pixel positions a glyph can overlap the next one
	# ("Refinery" read "ReA`nery"), subpixel positions keep them apart
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_AUTO if subpixel else TextServer.SUBPIXEL_POSITIONING_DISABLED
	f.generate_mipmaps = false
	return f


static func font() -> FontFile:
	if _font == null:
		_font = _pixelize(load(FONT_PATH), true)
	return _font


static func title_font() -> FontFile:
	if _title_font == null:
		_title_font = _pixelize(load(TITLE_FONT_PATH))
		# Press Start 2P has "fi" / "fl" ligatures that drop the i / l ("Acid Refnery")
		var ts := TextServerManager.get_primary_interface()
		_title_font.opentype_feature_overrides = {ts.name_to_tag("liga"): 0}
	return _title_font


static func box(name: String, margin := 4, content := Vector4(6, 3, 6, 4)) -> StyleBoxTexture:
	var key := "%s_%d_%s" % [name, margin, content]
	if _boxes.has(key):
		return _boxes[key]
	var sb := StyleBoxTexture.new()
	sb.texture = load("res://assets/ui/%s.png" % name)
	sb.texture_margin_left = margin
	sb.texture_margin_right = margin
	sb.texture_margin_top = margin
	sb.texture_margin_bottom = margin
	sb.content_margin_left = content.x
	sb.content_margin_top = content.y
	sb.content_margin_right = content.z
	sb.content_margin_bottom = content.w
	_boxes[key] = sb
	return sb


static func build_theme() -> Theme:
	var t := Theme.new()
	t.default_font = font()
	t.default_font_size = 10
	t.set_color("font_color", "Label", Color.WHITE)
	t.set_color("font_shadow_color", "Label", Color(0.094, 0.078, 0.145, 1))
	t.set_constant("shadow_offset_x", "Label", 1)
	t.set_constant("shadow_offset_y", "Label", 1)
	t.set_constant("line_spacing", "Label", 0)
	style_button_theme(t, "Button", "blue")
	t.set_stylebox("panel", "Panel", box("panel"))
	t.set_stylebox("panel", "PanelContainer", box("panel", 4, Vector4(6, 6, 6, 6)))
	t.set_constant("separation", "VBoxContainer", 3)
	t.set_constant("separation", "HBoxContainer", 4)
	t.set_stylebox("panel", "TooltipPanel", box("panel_dark", 4, Vector4(4, 3, 4, 3)))
	t.set_color("font_color", "TooltipLabel", Color.WHITE)
	t.set_font_size("font_size", "TooltipLabel", 10)
	return t


static func style_button_theme(t: Theme, type: String, color: String) -> void:
	t.set_stylebox("normal", type, box("btn_" + color))
	t.set_stylebox("hover", type, box("btn_%s_hover" % color))
	t.set_stylebox("pressed", type, box("btn_%s_pressed" % color, 4, Vector4(6, 4, 6, 3)))
	t.set_stylebox("disabled", type, box("btn_disabled"))
	t.set_stylebox("focus", type, StyleBoxEmpty.new())
	t.set_color("font_color", type, Color.WHITE)
	t.set_color("font_hover_color", type, Color.WHITE)
	t.set_color("font_pressed_color", type, Color("fee761"))
	t.set_color("font_disabled_color", type, Color("8b9bb4"))
	t.set_color("font_outline_color", type, Color(0.094, 0.078, 0.145, 1))
	t.set_constant("outline_size", type, 0)
	t.set_constant("h_separation", type, 4)


static func color_button(b: Button, color: String) -> void:
	b.add_theme_stylebox_override("normal", box("btn_" + color))
	b.add_theme_stylebox_override("hover", box("btn_%s_hover" % color))
	b.add_theme_stylebox_override("pressed", box("btn_%s_pressed" % color, 4, Vector4(6, 4, 6, 3)))


static func button(text: String, color := "blue", min_size := Vector2.ZERO, font_size := 10) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	b.custom_minimum_size = min_size
	b.add_theme_font_size_override("font_size", font_size)
	color_button(b, color)
	b.mouse_entered.connect(func(): if not b.disabled: Sfx.play("click"))
	return b


static func label(text: String, size := 10, color := Color.WHITE, align := HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func title(text: String, size := 16, color := Color("fee761")) -> Label:
	var l := label(text, size, color, HORIZONTAL_ALIGNMENT_CENTER)
	l.add_theme_font_override("font", title_font())
	l.add_theme_constant_override("shadow_offset_x", 2)
	l.add_theme_constant_override("shadow_offset_y", 2)
	return l


static func icon(name: String) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load("res://assets/ui/icons/%s.png" % name)
	r.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func sprite_rect(path: String, scale := 1) -> TextureRect:
	var r := TextureRect.new()
	r.texture = load(path)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = r.texture.get_size() * scale
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return r


static func panel(kind := "panel", pad := 6) -> PanelContainer:
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", box(kind, 4, Vector4(pad, pad, pad, pad)))
	return p


static func dim_rect(alpha := 0.55) -> ColorRect:
	var c := ColorRect.new()
	c.color = Color(0.06, 0.05, 0.1, alpha)
	c.position = Vector2.ZERO
	c.size = Vector2(640, 360)
	c.mouse_filter = Control.MOUSE_FILTER_STOP
	return c


static func fmt_num(v: float) -> String:
	if absf(v - roundf(v)) < 0.05:
		return str(int(roundf(v)))
	return "%.1f" % v


## Pixel art scrollbar (textures from tools/gen_art.py gen_scrollbar). `step` is how far an arrow click scrolls:
## a ScrollContainer's bar keeps the default step, which barely moves it.
static func style_scrollbar(bar: VScrollBar, step := 24.0) -> void:
	bar.custom_step = step
	bar.custom_minimum_size.x = 7
	var track := box("scroll_track", 3, Vector4(0, 0, 0, 0))
	bar.add_theme_stylebox_override("scroll", track)
	bar.add_theme_stylebox_override("scroll_focus", track)
	for st in [["grabber", ""], ["grabber_highlight", "_hover"], ["grabber_pressed", "_pressed"]]:
		var g := StyleBoxTexture.new()
		g.texture = load("res://assets/ui/scroll_grab%s.png" % st[1])
		g.texture_margin_left = 2
		g.texture_margin_right = 2
		g.texture_margin_top = 3
		g.texture_margin_bottom = 3
		g.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE   # the ridges repeat along it
		bar.add_theme_stylebox_override(st[0], g)
	for dir in [["decrement", "up"], ["increment", "down"]]:
		bar.add_theme_icon_override(dir[0], load("res://assets/ui/scroll_%s.png" % dir[1]))
		bar.add_theme_icon_override(dir[0] + "_highlight", load("res://assets/ui/scroll_%s_hover.png" % dir[1]))
		bar.add_theme_icon_override(dir[0] + "_pressed", load("res://assets/ui/scroll_%s_pressed.png" % dir[1]))
