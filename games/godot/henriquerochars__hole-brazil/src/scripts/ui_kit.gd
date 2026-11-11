extends RefCounted
## Reusable editorial UI primitives. All artwork is drawn in native Godot or PixelLab.
const PAPER := Color("f5efe0")
const INK := Color("18141e")
const MUTED := Color("625d63")
const GREEN := Color("197c43")
const GOLD := Color("f4b41a")
const RED := Color("c92d3c")
const BLUE := Color("1d63b8")
const PALE := Color("e4d9c3")

static func font(display: bool = false) -> Font:
	var path := "res://assets/fonts/BarlowCondensed-Bold.ttf" if display else "res://assets/fonts/Barlow-SemiBold.ttf"
	if ResourceLoader.exists(path):
		return load(path) as Font
	return ThemeDB.fallback_font

static func label(value: String, size: int = 20, color: Color = INK, display: bool = false) -> Label:
	var node := Label.new()
	node.text = value
	node.add_theme_font_override("font", font(display))
	node.add_theme_font_size_override("font_size", size)
	node.add_theme_color_override("font_color", color)
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func body(value: String, size: int = 20, color: Color = MUTED) -> Label:
	var node := label(value, size, color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return node

static func style(color: Color, border: Color = INK, width: int = 2, shadow: bool = true) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(3)
	box.content_margin_left = 18
	box.content_margin_right = 18
	box.content_margin_top = 14
	box.content_margin_bottom = 14
	if shadow:
		box.shadow_color = INK
		box.shadow_size = 0
		box.shadow_offset = Vector2(0, 4)
	return box

static func panel(color: Color = PAPER, border: Color = INK) -> PanelContainer:
	var node := PanelContainer.new()
	node.add_theme_stylebox_override("panel", style(color, border))
	return node

static func button(value: String, callback: Callable, primary: bool = false) -> Button:
	var node := Button.new()
	node.text = value
	node.custom_minimum_size.y = 60
	node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", font(true))
	node.add_theme_font_size_override("font_size", 25)
	node.add_theme_color_override("font_color", PAPER if primary else INK)
	node.add_theme_color_override("font_hover_color", PAPER if primary else INK)
	node.add_theme_color_override("font_pressed_color", PAPER if primary else INK)
	node.add_theme_stylebox_override("normal", style(GREEN if primary else PAPER))
	node.add_theme_stylebox_override("hover", style(Color("249351") if primary else Color("fff9ec")))
	node.add_theme_stylebox_override("pressed", style(Color("125b31") if primary else PALE, INK, 2, false))
	node.add_theme_stylebox_override("focus", style(Color(0, 0, 0, 0), GOLD, 3, false))
	node.pressed.connect(callback, CONNECT_DEFERRED)
	return node

static func rule() -> ColorRect:
	var node := ColorRect.new()
	node.color = INK
	node.custom_minimum_size.y = 2
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func portrait(path: String, side: int = 96) -> TextureRect:
	var node := TextureRect.new()
	node.custom_minimum_size = Vector2(side, side)
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if ResourceLoader.exists(path):
		node.texture = load(path) as Texture2D
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return node

static func framed_portrait(path: String, side: int = 96) -> PanelContainer:
	var frame := PanelContainer.new()
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var frame_style := style(PALE, INK, 1, false)
	frame_style.set_content_margin_all(3)
	frame.add_theme_stylebox_override("panel", frame_style)
	frame.add_child(portrait(path, side))
	return frame

class Hero extends Control:
	var clock: float = 0.0
	var congress: Texture2D
	func _ready() -> void:
		mouse_filter = MOUSE_FILTER_IGNORE
		if ResourceLoader.exists("res://assets/art/congress.png"):
			congress = load("res://assets/art/congress.png")
		texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	func _process(delta: float) -> void:
		clock += delta
		queue_redraw()
	func _draw() -> void:
		var w := size.x
		var h := size.y
		draw_rect(Rect2(0, 0, w, h), Color("a6c9c3"))
		draw_circle(Vector2(w * 0.78, h * 0.24), 37, Color("f4b41a"))
		for i in range(10):
			var x := float(i) * w / 9.0
			draw_line(Vector2(x, h * 0.62), Vector2(w * 0.5 + (x - w * 0.5) * 2.0, h), Color("c7bea9"), 1)
		draw_rect(Rect2(0, h * 0.64, w, h * 0.36), Color("ded3b7"))
		for i in range(5):
			draw_line(Vector2(0, h * 0.67 + i * 20), Vector2(w, h * 0.67 + i * 20), Color("c7bea9"), 1)
		if congress:
			var bounds := Vector2(w * 0.6, h * 0.72)
			var factor := minf(bounds.x / congress.get_width(), bounds.y / congress.get_height())
			var art_size := congress.get_size() * factor
			draw_texture_rect(congress, Rect2(Vector2((w - art_size.x) * 0.5, h * 0.67 - art_size.y), art_size), false)
		else:
			draw_rect(Rect2(w * 0.44, h * 0.15, 22, h * 0.45), Color("f5efe0"))
			draw_rect(Rect2(w * 0.51, h * 0.15, 22, h * 0.45), Color("f5efe0"))
			draw_rect(Rect2(w * 0.18, h * 0.57, w * 0.64, 16), Color("f5efe0"))
			draw_arc(Vector2(w * 0.31, h * 0.57), 35, PI, TAU, 32, Color("f5efe0"), 17)
			draw_arc(Vector2(w * 0.71, h * 0.45), 35, 0, PI, 32, Color("f5efe0"), 17)
		var center := Vector2(w * 0.51, h * 0.83)
		draw_set_transform(center, 0, Vector2(1, 0.4))
		draw_circle(Vector2.ZERO, 76, Color("a99a76"))
		draw_circle(Vector2.ZERO, 68, INK)
		draw_arc(Vector2.ZERO, 62, 0, TAU, 64, GOLD, 4)
		draw_set_transform(Vector2.ZERO)
		for i in range(5):
			var a := clock * 0.5 + i * 1.256
			var p := center + Vector2(cos(a) * 88, sin(a) * 26 - 16)
			draw_set_transform(p, a * 0.3)
			draw_rect(Rect2(-7, -10, 14, 20), PAPER)
			draw_rect(Rect2(-5, -6, 10, 3), RED)
			draw_set_transform(Vector2.ZERO)
		draw_rect(Rect2(0, 0, w, h), INK, false, 2)
