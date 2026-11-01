extends "res://tools/directions/board_common/board_base.gd"
## The Slate board: flat tiles on the bare background, no tray. The chain is
## a straight paper line with a dark edge and square nodes, drawn node to
## node in one piece with no tail to the finger. Draw order: fills, frames,
## line, nodes, numbers. Numbers on chained tiles get an outline in their own
## fill first, so the line stops cleanly at the glyph edge and no line ever
## shows inside a number. No preview on the board: the header shows it.
## Fast, exact motion: wipes and cuts, nothing bounces.
##
## Effect functions (see board_base.gd for the players):
##   spawn_frame(fx, progress)        wipe down from the top edge, expo ease
##   pop_frame(fx, progress)          paper flash, then a cut to the color
##   fall_frame(fx, progress, drop)   quart ease out, no bounce
##   play_spawn(), play_chain_to(), play_merge(), play_fall()
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const TilePainter: GDScript = preload("res://tools/directions/slate/board/tile_painter.gd")

var _painter: TilePainter = null


func spawn_frame(fx: TileFx, progress: float) -> void:
	fx.reset()
	var amount: float = MotionMath.eased(tokens, "spawn", progress)
	var from_scale_y: float = MotionMath.extra(tokens, "spawn", "from_scale_y")
	fx.scale = Vector2(1.0, lerpf(from_scale_y, 1.0, amount))
	fx.pivot = Vector2(0.0, -0.5)


func pop_frame(fx: TileFx, progress: float) -> void:
	fx.reset()
	var amount: float = MotionMath.eased(tokens, "merge_pop", progress)
	# Paper shows while the flash level is at least flash_cut, then the tile
	# cuts to its color.
	var level: float = MotionMath.extra(tokens, "merge_pop", "flash") * (1.0 - amount)
	fx.flash = progress < 1.0 and level >= tokens.num("flash_cut")
	fx.layer = TileFx.LAYER_TOP


func fall_frame(fx: TileFx, progress: float, drop: float) -> void:
	fx.reset()
	var amount: float = MotionMath.eased(tokens, "fall", progress)
	fx.offset.y = -drop * (1.0 - amount)
	fx.layer = TileFx.LAYER_MOVING


func _reference_metrics() -> Vector3:
	return TilePainter.reference_metrics(tokens)


func _setup_painters() -> void:
	_painter = TilePainter.new()
	_painter.setup(tokens)


func _on_layout() -> void:
	_painter.set_side(_side)


func _travel_follows_path() -> bool:
	return false


func _line_cuts_on_merge() -> bool:
	return true


func _line_has_tail() -> bool:
	return false


func _draw() -> void:
	if tokens == null:
		return
	# Empty cells, and the cells under tiles that are moving or wiping in.
	for index: int in CELL_COUNT:
		var fx: TileFx = _fx[index]
		if _cells[index] == 0 or fx.offset != Vector2.ZERO or fx.scale.y < 1.0 or fx.hidden:
			_painter.draw_empty(self, _center_of(index))
	# Resting tiles: fills and frames, then the line and nodes, then numbers.
	for index: int in CELL_COUNT:
		if _cells[index] != 0 and _fx[index].layer == TileFx.LAYER_REST:
			_painter.draw_body(self, _center_of(index), _cells[index], _chain_of(index), _fx[index])
	_draw_chain_line()
	for i: int in _chain.size():
		var index: int = _index(_chain[i])
		if not _line_hidden and _fx[index].layer == TileFx.LAYER_REST:
			_painter.draw_node(self, _center_of(index), _chain_amount[index])
	for index: int in CELL_COUNT:
		if _cells[index] != 0 and _fx[index].layer == TileFx.LAYER_REST:
			_painter.draw_number(self, _center_of(index), _cells[index], _fx[index], _chain_of(index))
	# Moving tiles over the rest, the tile a merge lands on over everything.
	for layer: int in range(TileFx.LAYER_MOVING, TileFx.LAYER_TOP + 1):
		for index: int in CELL_COUNT:
			if _cells[index] != 0 and _fx[index].layer == layer:
				_painter.draw_body(self, _center_of(index), _cells[index], _chain_of(index), _fx[index])
				_painter.draw_number(self, _center_of(index), _cells[index], _fx[index], _chain_of(index))
	if _target != NO_CELL:
		_painter.draw_brackets(self, cell_center(_target))


func _chain_of(index: int) -> float:
	return _chain_amount[index] if _chain_index[index] >= 0 else 0.0


## The chain line: the dark edge line first, then the paper line on top,
## straight segments from node to node. The segment to a tile that is still
## joining grows in with it.
func _draw_chain_line() -> void:
	_build_line()
	if _line_count < 2:
		return
	var core: float = tokens.num("line_width") * _scale
	var outer: float = core + 2.0 * tokens.num("line_edge") * _scale
	for pass_index: int in 2:
		var width: float = outer if pass_index == 0 else core
		var line_color: Color = tokens.color("chain_edge") if pass_index == 0 else tokens.color("chain")
		for i: int in _line_count - 1:
			var a: Vector2 = _line_points[i]
			var b: Vector2 = a.lerp(_line_points[i + 1], _chain_amount[_index(_chain[i + 1])])
			draw_line(a, b, line_color, width, true)
