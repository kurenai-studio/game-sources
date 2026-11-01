extends "res://tools/directions/board_common/board_base.gd"
## The Nova board: orbs floating on the backdrop with no tray and no grid. The
## chain is a beam of light under the orbs, its glow taking the chained orbs'
## colors, with a white core. The preview is a small orb in the gap where
## four orbs meet, at the top left corner of the last chain orb's cell. Slow,
## smooth glides and blooms of light.
##
## Draw order: every glow, then the beam, then every orb, so no glow and no
## beam ever crosses an orb's number.
##
## Effect functions (see board_base.gd for the players):
##   spawn_frame(fx, progress)        fade and grow in from from_scale and
##                                    from_alpha, sine ease, glow blooming in
##   pop_frame(fx, progress)          glow blooms to peak_glow and settles
##   fall_frame(fx, progress, drop)   cubic ease out
##   play_spawn(), play_chain_to(), play_merge(), play_fall()
## Merging orbs glide along the beam path, not straight.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const TilePainter: GDScript = preload("res://tools/directions/nova/board/tile_painter.gd")

var _painter: TilePainter = null
var _preview_painter: TilePainter = null
var _rest_fx: TileFx = TileFx.new()
var _segment: PackedVector2Array = PackedVector2Array()
var _segment_colors: PackedColorArray = PackedColorArray()


func spawn_frame(fx: TileFx, progress: float) -> void:
	fx.reset()
	var amount: float = MotionMath.eased(tokens, "spawn", progress)
	fx.scale = Vector2.ONE * lerpf(MotionMath.extra(tokens, "spawn", "from_scale"), 1.0, amount)
	fx.alpha = lerpf(MotionMath.extra(tokens, "spawn", "from_alpha"), 1.0, amount)
	fx.glow = amount + tokens.num("spawn_bloom") * sin(PI * clampf(amount, 0.0, 1.0))


func pop_frame(fx: TileFx, progress: float) -> void:
	fx.reset()
	var amount: float = MotionMath.eased(tokens, "merge_pop", progress)
	fx.glow = lerpf(MotionMath.extra(tokens, "merge_pop", "peak_glow"), 1.0, amount)
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
	_preview_painter = TilePainter.new()
	_preview_painter.setup(tokens)
	_segment.resize(2)
	_segment_colors.resize(2)


func _on_layout() -> void:
	_painter.set_side(_side)
	_preview_painter.set_side(_side * tokens.num("preview_scale"))


func _draw() -> void:
	if tokens == null:
		return
	var target_index: int = _index(_target) if _target != NO_CELL else -1
	for index: int in CELL_COUNT:
		if _cells[index] == 0:
			continue
		var glow: float = 1.0
		if _chain_index[index] >= 0:
			glow = lerpf(1.0, tokens.num("chain_glow"), _chain_amount[index])
		if index == target_index:
			glow = tokens.num("target_glow")
		_painter.draw_glow(self, _center_of(index), _cells[index], glow, _fx[index])
	_draw_beam()
	for layer: int in TileFx.LAYER_TOP + 1:
		for index: int in CELL_COUNT:
			if _cells[index] == 0 or _fx[index].layer != layer:
				continue
			var chain: float = _chain_amount[index] if _chain_index[index] >= 0 else 0.0
			_painter.draw_orb(self, _center_of(index), _cells[index], chain, _fx[index])
	if target_index >= 0:
		var turn: float = 0.0
		var breath: float = 0.0
		var period: float = tokens.duration("target_pulse")
		if _targeting and period > 0.0:
			turn = tokens.num("orbit_turn") * _pulse_time / period
			breath = MotionMath.loop_wave(tokens, "target_pulse", _pulse_time)
		_painter.draw_orbit(self, _center_of(target_index), turn, breath)
	_draw_preview()


## The beam: a wide soft glow in the chained orbs' colors, then the white
## core with round joints and ends.
func _draw_beam() -> void:
	_build_line()
	if _line_count < 2:
		return
	var glow_width: float = tokens.num("beam_glow_width") * _scale
	var glow_alpha: float = tokens.num("beam_glow_alpha")
	for i: int in _line_count - 1:
		_segment[0] = _line_points[i]
		_segment[1] = _line_points[i + 1]
		var from_color: Color = tokens.fill_for(_cells[_index(_chain[_line_owner(i)])])
		var to_color: Color = tokens.fill_for(_cells[_index(_chain[_line_owner(i + 1)])])
		from_color.a = glow_alpha
		to_color.a = glow_alpha
		_segment_colors[0] = from_color
		_segment_colors[1] = to_color
		draw_polyline_colors(_segment, _segment_colors, glow_width, true)
	var core: Color = tokens.color("chain")
	var core_width: float = tokens.num("beam_width") * _scale
	for i: int in _line_count - 1:
		draw_line(_line_points[i], _line_points[i + 1], core, core_width, true)
	for i: int in _line_count:
		draw_circle(_line_points[i], core_width * 0.5, core, true, -1.0, true)


## The preview: a small orb with glow on the gap crossing at the top left
## corner of the last chain orb's cell (top right when it is in column 0),
## in the open space where four orbs meet, clear of their rims.
func _draw_preview() -> void:
	if _preview <= 0 or _chain.is_empty():
		return
	var last: Vector2i = _chain.back()
	var corner: Vector2 = Vector2(last) + (Vector2(1.0, 0.0) if last.x == 0 else Vector2.ZERO)
	var preview_center: Vector2 = cell_point(corner)
	_preview_painter.draw_glow(self, preview_center, _preview, 1.0, _rest_fx)
	_preview_painter.draw_orb(self, preview_center, _preview, 0.0, _rest_fx)
