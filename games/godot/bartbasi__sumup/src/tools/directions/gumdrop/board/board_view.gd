extends "res://tools/directions/board_common/board_base.gd"
## The Gumdrop board: candy tiles in a rounded tray, a white rope under the
## tiles that shows in the gaps like beads on a string, and the preview as a
## ringed mini tile on the gap crossing by the last chain tile. Springy motion
## with overshoot.
##
## Effect functions (see board_base.gd for the players):
##   spawn_frame(fx, progress)        pop in from from_scale, back ease
##   pop_frame(fx, progress)          merge result at peak_scale, elastic settle
##   fall_frame(fx, progress, drop)   back ease with a squash on landing
##   play_spawn(), play_chain_to(), play_merge(), play_fall()
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const TilePainter: GDScript = preload("res://tools/directions/gumdrop/board/tile_painter.gd")

## Peak overshoot of Godot's back ease out (it overshoots by 10 percent).
## The squash grows with the overshoot and is full at this point.
const BACK_OVERSHOOT: float = 0.1

var _painter: TilePainter = null
var _preview_painter: TilePainter = null
var _rest_fx: TileFx = TileFx.new()
var _tray_box: StyleBoxFlat = null


func spawn_frame(fx: TileFx, progress: float) -> void:
	fx.reset()
	var amount: float = MotionMath.eased(tokens, "spawn", progress)
	var from_scale: float = MotionMath.extra(tokens, "spawn", "from_scale")
	fx.scale = Vector2.ONE * lerpf(from_scale, 1.0, amount)


func pop_frame(fx: TileFx, progress: float) -> void:
	fx.reset()
	var amount: float = MotionMath.eased(tokens, "merge_pop", progress)
	var peak: float = MotionMath.extra(tokens, "merge_pop", "peak_scale")
	fx.scale = Vector2.ONE * lerpf(peak, 1.0, amount)
	fx.layer = TileFx.LAYER_TOP


func fall_frame(fx: TileFx, progress: float, drop: float) -> void:
	fx.reset()
	var amount: float = MotionMath.eased(tokens, "fall", progress)
	fx.offset.y = -drop * (1.0 - amount)
	var squash: float = MotionMath.extra(tokens, "fall", "squash") * clampf((amount - 1.0) / BACK_OVERSHOOT, 0.0, 1.0)
	fx.scale = Vector2(1.0 + squash, 1.0 - squash)
	fx.pivot = Vector2(0.0, 0.5)
	fx.layer = TileFx.LAYER_MOVING


func _reference_metrics() -> Vector3:
	return TilePainter.reference_metrics(tokens)


func _setup_painters() -> void:
	_painter = TilePainter.new()
	_painter.setup(tokens)
	_preview_painter = TilePainter.new()
	_preview_painter.setup(tokens)
	_tray_box = StyleBoxFlat.new()
	_tray_box.bg_color = tokens.color("tray")
	_tray_box.anti_aliasing = true
	_tray_box.corner_detail = TilePainter.CORNER_DETAIL


func _on_layout() -> void:
	_painter.set_side(_side)
	_preview_painter.set_side(tokens.num("preview_scale") * _side)
	_tray_box.set_corner_radius_all(roundi(tokens.num("tray_radius") * _scale))


func _draw() -> void:
	if tokens == null:
		return
	_tray_box.draw(get_canvas_item(), _board_rect)
	for index: int in CELL_COUNT:
		var fx: TileFx = _fx[index]
		if _cells[index] == 0 or fx.offset != Vector2.ZERO or fx.scale.x < 1.0 or fx.hidden:
			_painter.draw_slot(self, _center_of(index))
	_draw_rope()
	var target_index: int = _index(_target) if _target != NO_CELL else -1
	for layer: int in TileFx.LAYER_TOP + 1:
		for index: int in CELL_COUNT:
			if _cells[index] == 0 or index == target_index:
				continue
			if _fx[index].layer != layer:
				continue
			var chain: float = _chain_amount[index] if _chain_index[index] >= 0 else 0.0
			_painter.draw_tile(self, _center_of(index), _cells[index], chain, false, _fx[index])
	if target_index >= 0 and _cells[target_index] != 0:
		_painter.draw_tile(self, _center_of(target_index), _cells[target_index], 0.0, true, _fx[target_index], _wobble())
	_draw_preview()


## The rope: round capped and round jointed, under the tiles.
func _draw_rope() -> void:
	_build_line()
	if _line_count == 0:
		return
	var rope_color: Color = tokens.color("chain")
	var width: float = tokens.num("rope_width") * _scale
	for i: int in _line_count - 1:
		draw_line(_line_points[i], _line_points[i + 1], rope_color, width, true)
	for i: int in _line_count:
		draw_circle(_line_points[i], width * 0.5, rope_color, true, -1.0, true)


## Target wobble angle on the target_pulse loop, 0 at the start of the loop.
func _wobble() -> float:
	if not _targeting:
		return 0.0
	var quarter: float = tokens.duration("target_pulse") * 0.25
	var wave: float = MotionMath.loop_wave(tokens, "target_pulse", _pulse_time + quarter)
	return deg_to_rad(MotionMath.extra(tokens, "target_pulse", "wobble_degrees")) * (wave * 2.0 - 1.0)


## The preview: the result as a mini tile with its lip and a preview_ring
## ring in chain, centered on the gap crossing at the top left corner of the
## last chain tile (top right when that tile is in column 0). It covers only
## the rounded corners of the four tiles round the crossing, never a number.
func _draw_preview() -> void:
	if _preview <= 0 or _chain.is_empty():
		return
	var last: Vector2i = _chain.back()
	var corner: Vector2 = Vector2(last) + (Vector2(1.0, 0.0) if last.x == 0 else Vector2.ZERO)
	var center: Vector2 = cell_point(corner)
	_preview_painter.draw_outer_ring(self, center, tokens.num("preview_ring") * _scale)
	_preview_painter.draw_tile(self, center, _preview, 0.0, false, _rest_fx)
