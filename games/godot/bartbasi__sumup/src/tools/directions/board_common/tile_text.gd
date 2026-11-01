extends RefCounted
## Tile number text for one tile size: label, font size, width and cap height
## for every tile value, worked out once per size so drawing a tile does no
## string or font work beyond the draw call itself.
##
## Labels come from MockState.tile_label(), font and size from the tokens.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")

## Values from 2 (index 0) up to 2 to the power of MAX_INDEX + 1, the
## highest value MockState.tile_label() keeps to 4 characters.
const MAX_INDEX: int = 48
## Godot's text outline size reaches about a quarter of its value past the
## glyph edge (measured on the capture renderer), so an outline that reaches
## n px past the edge needs size 4 n. Engine behavior, not a design token.
const OUTLINE_SIZE_PER_PX: float = 4.0
## Size the cap height is measured at, large so rounding is negligible.
const MEASURE_SIZE: int = 400
## Cap height as a fraction of the font size, used only if measuring fails.
## Roboto is 0.711, Segoe UI 0.700.
const FALLBACK_CAP_RATIO: float = 0.71

var font: Font = null
var _tokens: DirectionTokens = null
var _labels: PackedStringArray = PackedStringArray()
var _sizes: PackedInt32Array = PackedInt32Array()
var _widths: PackedFloat32Array = PackedFloat32Array()
var _cap_ratio: float = FALLBACK_CAP_RATIO
var _side: float = -1.0


func setup(tokens: DirectionTokens) -> void:
	_tokens = tokens
	font = tokens.font("tile")
	_labels.resize(MAX_INDEX + 1)
	_sizes.resize(MAX_INDEX + 1)
	_widths.resize(MAX_INDEX + 1)
	for index: int in MAX_INDEX + 1:
		_labels[index] = MockState.tile_label(2 << index)
	_cap_ratio = _measure_cap_ratio()
	_side = -1.0


## Recomputes sizes and widths for a tile side (Nova: orb diameter). Cheap to
## call every draw: it returns at once when the side has not changed.
func set_side(side: float) -> void:
	if is_equal_approx(side, _side):
		return
	_side = side
	for index: int in MAX_INDEX + 1:
		var label: String = _labels[index]
		var font_size: int = _tokens.tile_font_size(side, label)
		_sizes[index] = font_size
		_widths[index] = font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1.0, font_size).x


## Index for a tile value: 0 for 2, 1 for 4, and so on. -1 when the value is
## not a power of two of at least 2, or is beyond MAX_INDEX.
static func index_of(value: int) -> int:
	if value < 2 or (value & (value - 1)) != 0:
		return -1
	var index: int = 0
	var v: int = value
	while v > 2:
		v = v >> 1
		index += 1
	return index if index <= MAX_INDEX else -1


func label(index: int) -> String:
	return _labels[index]


func font_size(index: int) -> int:
	return _sizes[index]


func width(index: int) -> float:
	return _widths[index]


## Height of the digits and capitals above the baseline, in px.
func cap_height(index: int) -> float:
	return float(_sizes[index]) * _cap_ratio


## Draws a label centered on a point: the digits' visual middle, not the
## line box middle, sits on center.
func draw_centered(item: CanvasItem, center: Vector2, index: int, ink: Color) -> void:
	var baseline: Vector2 = Vector2(center.x - _widths[index] * 0.5, center.y + cap_height(index) * 0.5)
	item.draw_string(font, baseline, _labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _sizes[index], ink)


## Draws a label with the top of its digits at top_left.y and its left edge at
## top_left.x.
func draw_top_left(item: CanvasItem, top_left: Vector2, index: int, ink: Color) -> void:
	var baseline: Vector2 = Vector2(top_left.x, top_left.y + cap_height(index))
	item.draw_string(font, baseline, _labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _sizes[index], ink)


## Draws only an outline round a label placed as by draw_top_left(),
## reaching reach px past the glyph edges.
func draw_top_left_outline(item: CanvasItem, top_left: Vector2, index: int, reach: float, outline_color: Color) -> void:
	var outline_size: int = maxi(1, roundi(reach * OUTLINE_SIZE_PER_PX))
	var baseline: Vector2 = Vector2(top_left.x, top_left.y + cap_height(index))
	item.draw_string_outline(font, baseline, _labels[index], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _sizes[index], outline_size, outline_color)


## Box the label's digits cover when drawn with draw_top_left().
func box_top_left(top_left: Vector2, index: int) -> Rect2:
	return Rect2(top_left, Vector2(_widths[index], cap_height(index)))


## Cap height of the tile font as a fraction of its size, read from the
## rendered glyph of "H". Falls back to FALLBACK_CAP_RATIO.
func _measure_cap_ratio() -> float:
	var text_server: TextServer = TextServerManager.get_primary_interface()
	var line: TextLine = TextLine.new()
	if not line.add_string("H", font, MEASURE_SIZE):
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
