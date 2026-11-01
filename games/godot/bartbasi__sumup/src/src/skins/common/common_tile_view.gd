extends SkinTileView
## Shared SkinTileView for the three skins: one resting tile of side
## min(size.x, size.y), centered in the rect, drawn by the skin's painter.
## Each skin's tile view only names its painter in _make_painter().
##
## Lengths the skin gives in px scale with the tile against the board tile,
## so a small tile keeps the board tile's proportions.

const TilePainter: GDScript = preload("res://src/skins/common/tile_painter.gd")

var _skin: SkinData = null
var _painter: TilePainter = null
var _value: int = 0
var _label_shown: bool = true


func setup(skin: SkinData) -> void:
	if skin == null:
		push_error("SkinTileView.setup() needs a skin")
		return
	_skin = skin
	_painter = _make_painter()
	_painter.setup(skin)
	queue_redraw()


## The tile's exponent. 0, or anything that is not a tile, shows nothing.
func set_value(value: int) -> void:
	if value == _value:
		return
	_value = value
	queue_redraw()


## Whether the tile draws its label. false keeps everything else.
func set_label_shown(shown: bool) -> void:
	if shown == _label_shown:
		return
	_label_shown = shown
	queue_redraw()


func _make_painter() -> TilePainter:
	push_error("tile view does not implement _make_painter()")
	return TilePainter.new()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if _painter == null or TilePainter.index_of(_value) < 0:
		return
	var tile_side: float = minf(size.x, size.y)
	if tile_side < 1.0:
		return
	_painter.set_side(tile_side, tile_side / _painter.reference_side())
	_painter.label_shown = _label_shown
	_painter.draw_single(get_canvas_item(), size * 0.5, _value)
