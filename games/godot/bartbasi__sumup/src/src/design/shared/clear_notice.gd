extends Control
## The clear notice's content (D-38, D-45, AT-104): a mini tile of each value
## the notice names with a strike line across it, then the copy, and when the
## move earned stars, "+n" and a filled star, on a badge box. The skin's HUD
## builds it, places it and animates it; this only lays out and draws. It
## never takes input.
##
## Layout, left to right: pad_left, the tiles space_xs apart, space_xs, the
## text; with stars, space_s, "+n" in the same role and badge_ink, a gap of
## 0.25 of the role's font size, the star (its box the font size, centered on
## the copy's cap middle, DESIGN_SYSTEM.md 4.7 and 7.9); then pad_right. The
## box fills the whole control, so a HUD can stretch it (Slate's full width
## bar); the content keeps its place on the left.

const UiCopy: GDScript = preload("res://src/design/shared/ui_copy.gd")
## Cap height (DESIGN_SYSTEM.md 3.4), defined once.
const FontMetrics: GDScript = preload("res://src/design/shared/font_metrics.gd")
## The gap between "+n" and the star, as a share of the font size (7.9).
const STAR_GAP: float = 0.25
## The longest label a mini tile draws (4.7).
const MINI_LABEL_MAX: int = 3

## The copy shown, cased. For tests and for screens' accessibility.
var text: String = ""
## "+n" when the move earned stars, else "".
var stars_text: String = ""

var _skin: SkinData = null
var _box: StyleBox = null
var _font: Font = null
var _font_size: int = 1
var _ink: Color = Color.BLACK
var _tiles: Array[Control] = []
var _strikes: Control = null
var _text_origin: Vector2 = Vector2.ZERO
var _strike_width: float = 1.0
## Strike lines, two points each, in this control's space.
var _strike_points: PackedVector2Array = PackedVector2Array()
## Height of the box's face: the part above any lip.
var _face_height: float = 0.0
var _content_width: float = 0.0
var _stars_origin: Vector2 = Vector2.ZERO
## The filled star after "+n", or null.
var _star: SkinIcon = null


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Builds the notice for values (tile exponents, ascending) with the skin's
## tokens.
##   role: the type role of the copy (body for Gumdrop, label for the others)
##   box: the badge box, drawn over the whole control
##   height: notice_height; lip: the part of it under the face (0 for none)
##   pad_left, pad_right: space before the first tile and after the text
##   max_width: widest the content may be; with too many values to fit, only
##     the lowest and the highest get a tile
##   stars: stars the move earned; above 0 adds "+n" and the star
func build(skin: SkinData, values: PackedInt64Array, role: StringName, box: StyleBox, height: float, lip: float, pad_left: float, pad_right: float, max_width: float, stars: int = 0) -> void:
	_skin = skin
	_box = box
	_font = skin.font(role)
	_font_size = skin.font_size(role)
	_ink = skin.color(&"badge_ink")
	_strike_width = skin.num(&"notice_strike")
	_face_height = height - lip
	text = UiCopy.clear_notice(skin, role, values)
	stars_text = UiCopy.stars_earned(skin, role, stars) if stars > 0 else ""
	for tile: Control in _tiles:
		remove_child(tile)
		tile.queue_free()
	_tiles.clear()
	if _strikes == null:
		_strikes = Control.new()
		_strikes.name = "Strikes"
		_strikes.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_strikes.draw.connect(_draw_strikes)
		add_child(_strikes)

	var gap: float = skin.num(&"space_xs")
	var side: float = skin.num(&"notice_tile_scale") * height
	var text_width: float = _font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x
	var stars_width: float = 0.0
	if not stars_text.is_empty():
		stars_width = skin.num(&"space_s") + _font.get_string_size(stars_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x 			+ float(_font_size) * (STAR_GAP + 1.0)
	var shown: PackedInt64Array = values
	var fixed: float = pad_left + text_width + stars_width + pad_right
	if values.size() > 2 and fixed + (side + gap) * float(values.size()) > max_width:
		shown = PackedInt64Array([values[0], values[values.size() - 1]])
	var x: float = pad_left
	var tile_top: float = (_face_height - side) * 0.5
	_strike_points.clear()
	for value: int in shown:
		var tile: Control = _make_tile(skin, value)
		tile.position = Vector2(x, tile_top)
		tile.size = Vector2(side, side)
		add_child(tile)
		_tiles.append(tile)
		# The strike runs corner to corner, bottom left to top right.
		_strike_points.append(Vector2(x, tile_top + side))
		_strike_points.append(Vector2(x + side, tile_top))
		x += side + gap
	move_child(_strikes, get_child_count() - 1)
	var line_height: float = _font.get_height(_font_size)
	_text_origin = Vector2(x, (_face_height - line_height) * 0.5 + _font.get_ascent(_font_size))
	_place_star(skin, x + text_width)
	_content_width = x + text_width + stars_width + pad_right
	size = Vector2(_content_width, height)
	queue_redraw()


## The star's center in this control's space, or (-1, -1) with no stars.
## The star earned effect leaves from here.
func star_center() -> Vector2:
	if _star == null or not _star.visible:
		return Vector2(-1.0, -1.0)
	return _star.position + _star.size * 0.5


## "+n" and the star after the copy, which ends at text_end.
func _place_star(skin: SkinData, text_end: float) -> void:
	if stars_text.is_empty():
		if _star != null:
			_star.visible = false
		return
	_stars_origin = Vector2(text_end + skin.num(&"space_s"), _text_origin.y)
	if _star == null:
		_star = UiKit.make_icon(skin)
		_star.name = "Star"
		add_child(_star)
		_star.set_icon(&"star")
	_star.visible = true
	_star.set_color(_ink)
	var star_side: float = float(_font_size)
	var plus_width: float = _font.get_string_size(stars_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size).x
	var cap_middle: float = _text_origin.y - FontMetrics.CAP_HEIGHT * float(_font_size) * 0.5
	_star.size = Vector2(star_side, star_side)
	_star.position = Vector2(_stars_origin.x + plus_width + STAR_GAP * float(_font_size), cap_middle - star_side * 0.5)


## Width the content needs.
func content_width() -> float:
	return _content_width


## The mini tiles, for tests.
func tiles() -> Array[Control]:
	return _tiles


## A mini tile from the skin's own tile view (already set up by the factory).
## A mini tile of the exponent value. Its label shows only when it has 3
## characters or fewer (2, 512, 64K, 4aa); a longer one would be 2.6 to 4 dp
## tall under the strike, so the tile is a color chip and the copy beside it
## names the value (DESIGN_SYSTEM.md 4.7, 14.1).
func _make_tile(skin: SkinData, value: int) -> SkinTileView:
	var tile: SkinTileView = SkinCatalog.make_tile_view(skin)
	tile.set_label_shown(NumberFormat.tile_label(value).length() <= MINI_LABEL_MAX)
	tile.set_value(value)
	tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tile


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and _strikes != null:
		_strikes.size = size


func _draw() -> void:
	if _skin == null:
		return
	draw_style_box(_box, Rect2(Vector2.ZERO, size))
	# Text pair: badge_ink on badge.
	draw_string(_font, _text_origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, _ink)
	if not stars_text.is_empty():
		draw_string(_font, _stars_origin, stars_text, HORIZONTAL_ALIGNMENT_LEFT, -1.0, _font_size, _ink)


func _draw_strikes() -> void:
	for i: int in range(0, _strike_points.size(), 2):
		_strikes.draw_line(_strike_points[i], _strike_points[i + 1], _ink, _strike_width, true)
