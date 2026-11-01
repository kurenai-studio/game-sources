extends RefCounted
## Tile number text for one skin at one tile side: the label, its font size,
## width and cap height for every tile exponent, so drawing a tile does no
## string work beyond the one draw call itself.
##
## Every method takes the tile's exponent k (the tile is 2^k, ARCHITECTURE.md
## 17), from 1 to SkinData.max_exponent(). Labels come from
## NumberFormat.tile_label (GDD D-31), up to 6 characters (DESIGN_SYSTEM.md
## 2.5). Font and size come from the skin (SkinData.font(&"tile") and
## SkinData.tile_font_size). A label is made the first time it is needed and
## kept; its size is measured the first time it is drawn at a side, then kept
## until the side changes. A board shows a handful of exponents at a time, so
## the caches stay small even though k reaches 65535.

## Size the cap height is measured at, large so rounding does not matter.
const MEASURE_SIZE: int = 400
## Cap height as a share of the font size, used only if measuring fails.
## Roboto and Outfit both sit near this.
const FALLBACK_CAP_RATIO: float = 0.7

## Label text per exponent, shared by every skin.
static var _labels: Dictionary[int, String] = {}
## Cap ratio per font, measured once.
static var _cap_ratios: Dictionary[int, float] = {}

var font: Font = null
var _skin: SkinData = null
## Font size and width per exponent at the current side.
var _sizes: Dictionary[int, int] = {}
var _widths: Dictionary[int, float] = {}
var _cap_ratio: float = FALLBACK_CAP_RATIO
var _side: float = -1.0


func setup(skin: SkinData) -> void:
	_skin = skin
	font = skin.font(&"tile")
	_sizes.clear()
	_widths.clear()
	_cap_ratio = _cap_ratio_of(font)
	_side = -1.0


## Sets the tile side (Nova: the orb diameter). Sizes are measured again
## lazily. Returns at once when the side has not changed.
func set_side(side: float) -> void:
	if is_equal_approx(side, _side):
		return
	_side = side
	_sizes.clear()
	_widths.clear()


## The label of the tile 2^exponent. "" for anything that is not a tile.
static func label(exponent: int) -> String:
	if not SkinData.is_tile(exponent):
		return ""
	if not _labels.has(exponent):
		_labels[exponent] = NumberFormat.tile_label(exponent)
	return _labels[exponent]


func font_size(exponent: int) -> int:
	_measure(exponent)
	return _sizes.get(exponent, 1)


func width(exponent: int) -> float:
	_measure(exponent)
	return _widths.get(exponent, 0.0)


## Height of the digits above the baseline, in px.
func cap_height(exponent: int) -> float:
	return float(font_size(exponent)) * _cap_ratio


## Draws a label into a canvas item so the middle of its digits sits on
## center.
func draw_centered(canvas: RID, center: Vector2, exponent: int, ink: Color) -> void:
	if not _measure(exponent):
		return
	var size: int = _sizes[exponent]
	var baseline: Vector2 = Vector2(center.x - _widths[exponent] * 0.5, center.y + float(size) * _cap_ratio * 0.5)
	font.draw_string(canvas, baseline, _labels[exponent], HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, ink)


## Draws a label into a canvas item with the top of its digits at
## top_left.y and its left edge at top_left.x.
func draw_top_left(canvas: RID, top_left: Vector2, exponent: int, ink: Color) -> void:
	if not _measure(exponent):
		return
	var size: int = _sizes[exponent]
	var baseline: Vector2 = Vector2(top_left.x, top_left.y + float(size) * _cap_ratio)
	font.draw_string(canvas, baseline, _labels[exponent], HORIZONTAL_ALIGNMENT_LEFT, -1.0, size, ink)


## The box a label drawn with draw_top_left() covers: its width by its cap
## height.
func box_top_left(top_left: Vector2, exponent: int) -> Rect2:
	return Rect2(top_left, Vector2(width(exponent), cap_height(exponent)))


## Makes sure the label, size and width of an exponent are known at this
## side. false for anything that is not a tile.
func _measure(exponent: int) -> bool:
	if _sizes.has(exponent):
		return true
	var text: String = label(exponent)
	if text.is_empty():
		return false
	var size: int = _skin.tile_font_size(maxf(_side, 1.0), text)
	_sizes[exponent] = size
	_widths[exponent] = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, size).x
	return true


## Cap height of a font as a share of its size, read from the rendered glyph
## of "H". Measured once per font.
static func _cap_ratio_of(text_font: Font) -> float:
	var key: int = text_font.get_instance_id()
	if _cap_ratios.has(key):
		return _cap_ratios[key]
	var ratio: float = _measure_cap_ratio(text_font)
	_cap_ratios[key] = ratio
	return ratio


static func _measure_cap_ratio(text_font: Font) -> float:
	var text_server: TextServer = TextServerManager.get_primary_interface()
	var line: TextLine = TextLine.new()
	if not line.add_string("H", text_font, MEASURE_SIZE):
		return FALLBACK_CAP_RATIO
	var glyphs: Array[Dictionary] = text_server.shaped_text_get_glyphs(line.get_rid())
	if glyphs.is_empty():
		return FALLBACK_CAP_RATIO
	var glyph: Dictionary = glyphs[0]
	var font_rid: RID = glyph.get("font_rid", RID())
	var glyph_index: int = int(glyph.get("index", 0))
	if not font_rid.is_valid():
		return FALLBACK_CAP_RATIO
	var size_key: Vector2i = Vector2i(MEASURE_SIZE, 0)
	text_server.font_render_glyph(font_rid, size_key, glyph_index)
	var glyph_offset: Vector2 = text_server.font_get_glyph_offset(font_rid, size_key, glyph_index)
	var glyph_size: Vector2 = text_server.font_get_glyph_size(font_rid, size_key, glyph_index)
	if glyph_size.y <= 0.0 or glyph_offset.y >= 0.0:
		return FALLBACK_CAP_RATIO
	var ratio: float = -glyph_offset.y / float(MEASURE_SIZE)
	if ratio < 0.5 or ratio > 0.9:
		return FALLBACK_CAP_RATIO
	return ratio
