extends "res://src/skins/common/common_board_view.gd"
## The Slate board (DESIGN_SYSTEM.md 5.7): flat tiles on the bare background,
## no tray. An empty cell shows a hairline frame. The chain is a straight
## paper line with a dark edge and square nodes, drawn node to node in one
## piece with no tail to the finger. No preview on the board: the HUD's
## context row shows it. Fast, exact motion: wipes and cuts, nothing bounces.
##
## Layers: back (empty frames), under (resting tiles' fills and frames),
## line, tiles (resting tiles' nodes, label plates and numbers; moving tiles
## whole), top (the press and selection brackets). So the order is fills,
## frames, line, nodes, label plates, numbers.

const SlateTilePainter: GDScript = preload("res://src/skins/slate/slate_tile_painter.gd")

var _tiles: SlateTilePainter = null
var _from_scale_y: float = 0.0
var _flash: float = 0.0
var _flash_cut: float = 0.0


func _make_painter() -> TilePainter:
	return SlateTilePainter.new() as TilePainter


func _setup_look() -> void:
	_tiles = _painter as SlateTilePainter
	_from_scale_y = MotionMath.extra(skin, &"spawn", "from_scale_y")
	_flash = MotionMath.extra(skin, &"merge_pop", "flash")
	_flash_cut = skin.num(&"flash_cut")


func _line_has_tail() -> bool:
	return false


func _travel_follows_path() -> bool:
	return false


func _line_cuts_on_merge() -> bool:
	return true


# Effects.

## Wipes down from the top edge.
func _spawn_frame(fx: TileFx, progress: float) -> void:
	fx.scale.y *= lerpf(_from_scale_y, 1.0, MotionMath.eased(skin, &"spawn", progress))
	fx.pivot = Vector2(0.0, -0.5)


## The result shows paper while the flash level is at least flash_cut, then
## cuts to its own color.
func _pop_frame(fx: TileFx, progress: float) -> void:
	var level: float = _flash * (1.0 - MotionMath.eased(skin, &"merge_pop", progress))
	if level >= _flash_cut:
		fx.flash = true
	fx.raise_layer(TileFx.LAYER_TOP)


## Wipes up to nothing, pivot at the top.
func _clear_frame(fx: TileFx, progress: float) -> void:
	fx.scale.y *= 1.0 - MotionMath.eased(skin, &"clear", progress)
	fx.pivot = Vector2(0.0, -0.5)


## A tile wiping in shows its empty frame behind it.
func _shows_empty(index: int) -> bool:
	var fx: TileFx = _fx[index]
	return _cells[index] <= 0 or fx.hidden or fx.offset != Vector2.ZERO or fx.scale.y < 1.0


# Tiles.

func _draw_item(tile: RID, under: RID, value: int, chain_amount: float, join: float, _press: float, _select: float, flash: bool, _glow: float, moving: bool) -> void:
	if moving:
		_tiles.draw_whole(tile, Transform2D.IDENTITY, value, flash, chain_amount, join)
		return
	_tiles.draw_body(under, Transform2D.IDENTITY, value, flash, chain_amount, join)
	_tiles.draw_marks(tile, Transform2D.IDENTITY, value, flash, chain_amount, join)


# Layers.

func _draw_layer(layer: int, item: CanvasItem) -> void:
	var canvas: RID = item.get_canvas_item()
	match layer:
		LAYER_BACK:
			for index: int in cell_count:
				if _empty_mask[index] != 0:
					_tiles.draw_empty(canvas, _rect_of(index))
		LAYER_LINE:
			_draw_line(item)
		LAYER_TOP:
			_draw_brackets(canvas)


## Press feedback and Swap's selection: corner brackets, plus the selected
## frame. They hold still.
func _draw_brackets(canvas: RID) -> void:
	for index: int in cell_count:
		var press: float = _press_fade.value[index]
		var select: float = _select_fade.value[index]
		if press <= 0.0 and select <= 0.0:
			continue
		var rect: Rect2 = _rect_of(index)
		if select > 0.0:
			_tiles.draw_selected_frame(canvas, rect, select)
		_tiles.draw_brackets(canvas, rect, maxf(press, select))


## The chain line node to node: the chain_edge line first, then the chain
## line on top. The segment to a tile that is joining grows in with it.
func _draw_line(item: CanvasItem) -> void:
	var count: int = _build_line_points()
	if count < 2:
		return
	var widths: Vector2 = _tiles.line_widths()
	var core: float = widths.x
	var outer: float = core + 2.0 * widths.y
	var edge_color: Color = skin.color(&"chain_edge")
	var core_color: Color = skin.color(&"chain")
	for pass_index: int in 2:
		var width: float = outer if pass_index == 0 else core
		var color: Color = edge_color if pass_index == 0 else core_color
		for i: int in count - 1:
			var from: Vector2 = _line_points[i]
			var joined: float = _chain_fade.value[_index_of(_line_cells[_line_owner[i + 1]])]
			item.draw_line(from, from.lerp(_line_points[i + 1], joined), color, width, true)
