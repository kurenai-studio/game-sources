class_name Kit
extends RefCounted
## The look of the game's words and buttons, in one place: the three pixel
## fonts (small, big, led), labels with a drop shadow, chunky arcade buttons
## and panels. Every screen builds from these so they all match.

const INK := Color("24152e")
const PAPER := Color("fffaf0")
const MUSTARD := Color("f7d331")
const KETCHUP := Color("e0383a")
const RELISH := Color("7ad448")
const SKY := Color("6aa2e2")
const NAVY := Color("1e2a7a")
const PLUM := Color("3a2a4a")
const GOLD := Color("ffd25a")
const SILVER := Color("d4d4e0")
const BRONZE := Color("d0902e")
const AMBER := Color("ffd060")
const GREY := Color("a8a6ba")

const GRADE_COLOURS := {
	"perfect": Color("fff07a"), "good": Color("8ad42a"), "ok": Color("6a92e2"),
	"miss": Color("a8a6ba"), "fumble": Color("ff6a6a"), "late": Color("ff9a5a"), "early": Color("ff9a5a"),
	"off": Color("ff9a5a"),
}
const GRADE_WORDS := {
	"perfect": "PERFECT!", "good": "GOOD", "ok": "OK", "miss": "MISS", "fumble": "WOBBLE!",
	"late": "LATE", "early": "EARLY", "off": "OFF BEAT",
}
## Each player's colour, on the scoreboard, the card and their phone.
const PLAYER_COLOURS := [Color("f7d331"), Color("7ad448"), Color("6ac2ff"), Color("ff8ad0")]


static func player_colour(player: int) -> Color:
	return PLAYER_COLOURS[clampi(player, 0, PLAYER_COLOURS.size() - 1)] if player >= 0 else GREY

static var _fonts: Dictionary = {}


static func font(name := "small") -> Font:
	if not _fonts.has(name):
		_fonts[name] = load("res://assets/fonts/%s.fnt" % name)
	return _fonts[name]


static func label(text: String, size := "small", colour := PAPER, shadow := true) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_override("font", font(size))
	l.add_theme_font_size_override("font_size", 9 if size == "small" else (18 if size == "big" else 18))
	l.add_theme_color_override("font_color", colour)
	if shadow:
		l.add_theme_color_override("font_shadow_color", INK)
		l.add_theme_constant_override("shadow_offset_x", 1 if size != "big" else 2)
		l.add_theme_constant_override("shadow_offset_y", 1 if size != "big" else 2)
	l.add_theme_constant_override("line_spacing", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


static func box(bg: Color, border := INK, width := 1, shadow := 2) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(width)
	s.set_corner_radius_all(0)
	s.anti_aliasing = false
	if shadow > 0:
		s.shadow_color = Color(INK, 0.85)
		s.shadow_size = 0
		s.shadow_offset = Vector2(shadow, shadow)
	s.content_margin_left = 6
	s.content_margin_right = 6
	s.content_margin_top = 3
	s.content_margin_bottom = 3
	return s


## A chunky arcade button: coloured face, ink rim, a lighter top edge, and it
## sinks a pixel when pressed.
static func button(text: String, colour := KETCHUP, size := "small", min_w := 0) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_ALL
	b.add_theme_font_override("font", font(size))
	b.add_theme_font_size_override("font_size", 9 if size == "small" else 18)
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		b.add_theme_color_override(state, PAPER)
	b.add_theme_color_override("font_shadow_color", INK)
	b.add_theme_constant_override("shadow_offset_x", 1)
	b.add_theme_constant_override("shadow_offset_y", 1)
	var normal := _face(colour, false)
	var hover := _face(colour.lightened(0.12), false)
	var pressed := _face(colour.darkened(0.15), true)
	var focus := _face(colour.lightened(0.12), false)
	focus.border_color = MUSTARD
	b.add_theme_stylebox_override("normal", normal)
	b.add_theme_stylebox_override("hover", hover)
	b.add_theme_stylebox_override("pressed", pressed)
	b.add_theme_stylebox_override("focus", focus)
	b.add_theme_stylebox_override("disabled", _face(GREY.darkened(0.3), false))
	if min_w > 0:
		b.custom_minimum_size.x = min_w
	b.custom_minimum_size.y = 20 if size == "small" else 30
	return b


## A smaller button for tight rows (arrows, toggles).
static func small_button(text: String, colour := KETCHUP, min_w := 0) -> Button:
	var b := button(text, colour, "small", min_w)
	for st in ["normal", "hover", "pressed", "focus"]:
		var sb: StyleBoxFlat = b.get_theme_stylebox(st).duplicate()
		var down: bool = st == "pressed"
		sb.content_margin_left = 3
		sb.content_margin_right = 3
		sb.content_margin_top = 3 + (1 if down else 0)
		sb.content_margin_bottom = 0 if down else 1
		sb.border_width_bottom = 1 if down else 2
		b.add_theme_stylebox_override(st, sb)
	b.custom_minimum_size.y = 14
	return b


static func _face(colour: Color, down: bool) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = colour
	s.border_color = INK
	s.set_border_width_all(1)
	s.border_width_top = 1
	s.border_width_bottom = 1 if down else 3
	s.anti_aliasing = false
	s.content_margin_left = 8
	s.content_margin_right = 8
	# the fonts' capitals sit in the top of their line (small: 7 of 11 pixels),
	# so the line goes a little low to put them in the middle of the face
	s.content_margin_top = 6 + (1 if down else 0)
	s.content_margin_bottom = 4 + (0 if down else 1)
	s.expand_margin_top = 0
	return s


## Keep a control in the middle of the screen (nudged by `offset`), whenever
## it or the screen changes size; never off the top or the left.
static func centre(c: Control, offset := Vector2.ZERO) -> void:
	var place := func() -> void:
		if is_instance_valid(c) and c.is_inside_tree():
			var sz := c.get_combined_minimum_size()
			if c.size != sz:
				c.size = sz                    # (shrink back to fit, too)
			c.position = ((c.get_viewport_rect().size - sz) / 2.0 + offset).round().max(Vector2.ZERO)
	c.resized.connect(place)
	c.tree_entered.connect(func() -> void: place.call_deferred())
	place.call_deferred()                    # (it may be in the tree already)


static func panel(bg := Color("2a1e3e"), border := INK) -> PanelContainer:
	var p := PanelContainer.new()
	var s := box(bg, border, 1, 2)
	s.content_margin_left = 8
	s.content_margin_right = 8
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", s)
	return p


## Pin a control to a spot on its parent: anchor (0-1 each way) plus an offset
## and a size, in pixels.
static func pin(c: Control, anchor: Vector2, offset: Vector2, size := Vector2.ZERO) -> void:
	c.anchor_left = anchor.x
	c.anchor_right = anchor.x
	c.anchor_top = anchor.y
	c.anchor_bottom = anchor.y
	c.offset_left = offset.x
	c.offset_top = offset.y
	c.offset_right = offset.x + size.x
	c.offset_bottom = offset.y + size.y


static func fill(c: Control) -> void:
	c.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


static var _flags: Dictionary = {}


## A small flag for a nation code, as a texture region (kept, so a flag drawn
## in a _draw() lives until the frame is shown).
static func flag(code: String, size := "m") -> AtlasTexture:
	var key := code + ":" + size
	if not _flags.has(key):
		_flags[key] = _make_flag(code, size)
	return _flags[key]


static var _flag_order: Array = []


## Where each flag is in the atlas (tools/gen_art.py writes the order).
static func flag_order() -> Array:
	if _flag_order.is_empty():
		var f := FileAccess.open("res://assets/art/flags/flags.json", FileAccess.READ)
		var d: Variant = JSON.parse_string(f.get_as_text()) if f else null
		_flag_order = d.get("order", []) if d is Dictionary else []
	return _flag_order


static func _make_flag(code: String, size: String) -> AtlasTexture:
	var dims := {"s": Vector2(14, 10), "m": Vector2(23, 16), "l": Vector2(44, 30)}
	var i := maxi(0, flag_order().find(code))
	var a := AtlasTexture.new()
	a.atlas = load("res://assets/art/flags/flags_%s.png" % size)
	var d: Vector2 = dims[size]
	a.region = Rect2(i * d.x, 0, d.x, d.y)
	return a


static func flag_rect(code: String, size := "m") -> TextureRect:
	var t := TextureRect.new()
	t.texture = flag(code, size)
	t.stretch_mode = TextureRect.STRETCH_KEEP
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return t


## Words drawn with an ink outline all round and a drop shadow, so they read
## over anything (a busy crowd, the sky).
static func outlined(ci: CanvasItem, f: Font, p: Vector2, text: String, size: int, col: Color) -> void:
	var ink := Color(INK, col.a)
	var d := 2 if size >= 18 else 1
	ci.draw_string(f, p + Vector2(d + 1, d + 1), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
	for o in [Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1), Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1)]:
		ci.draw_string(f, p + o, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, ink)
	ci.draw_string(f, p, text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


static var _icons: Dictionary = {}
static var _icon_order: Array = []


## An event's pictogram (assets/art/ui/icons.png), kept like the flags.
static func icon(id: String) -> AtlasTexture:
	if _icon_order.is_empty():
		var f := FileAccess.open("res://assets/art/ui/icons.json", FileAccess.READ)
		var d: Variant = JSON.parse_string(f.get_as_text()) if f else {}
		_icon_order = d.get("order", []) if d is Dictionary else []
	if not _icons.has(id):
		var a := AtlasTexture.new()
		a.atlas = load("res://assets/art/ui/icons.png")
		var i := maxi(0, _icon_order.find(id))
		a.region = Rect2(i * 32, 0, 32, 32)
		_icons[id] = a
	return _icons[id]


## A button for an event: its pictogram and its name.
static func event_button(id: String, colour: Color, min_w := 140) -> Button:
	var b := small_button(String(Catalog.event(id).get("name", id)).to_upper(), colour, min_w)
	b.icon = icon(id)
	b.expand_icon = false
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_constant_override("h_separation", 4)
	b.custom_minimum_size.y = 34
	return b
