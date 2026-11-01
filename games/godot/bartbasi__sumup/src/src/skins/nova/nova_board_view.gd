extends "res://src/skins/common/common_board_view.gd"
## The Nova board (DESIGN_SYSTEM.md 6.7): orbs floating on the backdrop with
## no tray and no grid. The chain is a beam of light under the orbs, its glow
## taking the chained orbs' colors, with a white core, running on to the
## finger. The preview is a small orb on the gap crossing by the last chain
## orb. Slow, smooth glides and blooms of light.
##
## Layers: back (the clear sparks), under (every glow), line (the beam),
## tiles (the orbs and their joinable orbits), top (the dashed target orbits
## and the preview). So no glow, spark or beam ever crosses an orb's number.

const NovaTilePainter: GDScript = preload("res://src/skins/nova/nova_tile_painter.gd")

var _tiles: NovaTilePainter = null
var _preview_painter: NovaTilePainter = null
var _segment: PackedVector2Array = PackedVector2Array()
var _segment_colors: PackedColorArray = PackedColorArray()

var _from_scale: float = 1.0
var _from_alpha: float = 1.0
var _spawn_bloom: float = 0.0
var _peak_glow: float = 1.0
var _to_scale: float = 1.0
var _orbit_turn: float = 0.0


func _make_painter() -> TilePainter:
	return NovaTilePainter.new() as TilePainter


func _setup_look() -> void:
	_tiles = _painter as NovaTilePainter
	_preview_painter = NovaTilePainter.new()
	_preview_painter.setup(skin)
	_segment.resize(2)
	_segment_colors.resize(2)
	_from_scale = MotionMath.extra(skin, &"spawn", "from_scale")
	_from_alpha = MotionMath.extra(skin, &"spawn", "from_alpha")
	_spawn_bloom = skin.num(&"spawn_bloom")
	_peak_glow = MotionMath.extra(skin, &"merge_pop", "peak_glow")
	_to_scale = MotionMath.extra(skin, &"clear", "to_scale")
	_orbit_turn = skin.num(&"orbit_turn")


func _on_layout() -> void:
	var preview_scale: float = skin.num(&"preview_scale")
	_preview_painter.set_side(_side * preview_scale, _unit * preview_scale)


## The bloom after a merge or a Double is a tail that never blocks input
## (DESIGN_SYSTEM.md 6.6).
func _pop_is_decor() -> bool:
	return true


# Effects.

## From from_scale and from_alpha, with spawn_bloom extra glow at the midpoint.
func _spawn_frame(fx: TileFx, progress: float) -> void:
	var amount: float = MotionMath.eased(skin, &"spawn", progress)
	fx.scale *= lerpf(_from_scale, 1.0, amount)
	fx.alpha *= lerpf(_from_alpha, 1.0, amount)
	fx.glow *= amount + _spawn_bloom * sin(PI * clampf(amount, 0.0, 1.0))


## The glow blooms to peak_glow times its glow and settles.
func _pop_frame(fx: TileFx, progress: float) -> void:
	fx.glow *= lerpf(_peak_glow, 1.0, MotionMath.eased(skin, &"merge_pop", progress))


## Dims and shrinks to to_scale; its glow goes out with it.
func _clear_frame(fx: TileFx, progress: float) -> void:
	var amount: float = MotionMath.eased(skin, &"clear", progress)
	fx.scale *= lerpf(1.0, _to_scale, amount)
	fx.alpha *= 1.0 - amount
	fx.glow *= 1.0 - amount


## A leaving orb in a Shuffle or Undo dims and shrinks the same way.
func _depart_frame(fx: TileFx, progress: float) -> void:
	_clear_frame(fx, progress)


# Tiles.

func _draw_item(tile: RID, under: RID, value: int, chain_amount: float, join: float, press: float, select: float, _flash: bool, glow: float, _moving: bool) -> void:
	var amount: float = glow * _tiles.glow_of(chain_amount, join, maxf(press, select))
	_tiles.draw_glow(under, Transform2D.IDENTITY, value, amount)
	_tiles.draw_orb(tile, Transform2D.IDENTITY, value, chain_amount, join)


## The beam's tail to the finger stays on the board: its round end reaches
## the board view's edge and no further (DESIGN_SYSTEM.md 6.7).
func _tail_bounds() -> Rect2:
	return Rect2(Vector2.ZERO, size).grow(-skin.num(&"chain_width") * _unit * 0.5)


func _back_animates() -> bool:
	for effect: BoardEffect in _effects:
		if effect.kind == BoardEffect.CLEAR:
			return true
	return false


func _top_animates() -> bool:
	return _pulse_running()


# Layers.

func _draw_layer(layer: int, item: CanvasItem) -> void:
	var canvas: RID = item.get_canvas_item()
	match layer:
		LAYER_BACK:
			for effect: BoardEffect in _effects:
				if effect.kind == BoardEffect.CLEAR and _has_started(effect):
					_tiles.draw_sparks(canvas, _ghost_center(effect), effect.value, _progress(effect))
		LAYER_LINE:
			_draw_beam(item)
		LAYER_TOP:
			_draw_top(canvas)


## The beam: a beam_glow_width glow at beam_glow_alpha in the chained orbs'
## colors along its length, then the chain_width core with round joins and
## ends.
func _draw_beam(item: CanvasItem) -> void:
	var count: int = _build_line_points()
	if count < 2:
		return
	var glow_width: float = skin.num(&"beam_glow_width") * _unit
	var glow_alpha: float = skin.num(&"beam_glow_alpha")
	for i: int in count - 1:
		_segment[0] = _line_points[i]
		_segment[1] = _line_points[i + 1]
		var from_color: Color = skin.fill_for(_line_values[_line_owner[i]])
		var to_color: Color = skin.fill_for(_line_values[_line_owner[i + 1]])
		from_color.a = glow_alpha
		to_color.a = glow_alpha
		_segment_colors[0] = from_color
		_segment_colors[1] = to_color
		item.draw_polyline_colors(_segment, _segment_colors, glow_width, true)
	var core: Color = skin.color(&"chain")
	var core_width: float = skin.num(&"chain_width") * _unit
	for i: int in count - 1:
		item.draw_line(_line_points[i], _line_points[i + 1], core, core_width, true)
	for i: int in count:
		item.draw_circle(_line_points[i], core_width * 0.5, core, true, -1.0, true)


## Press feedback: a still dashed orbit. Swap's selected tile: the dashed
## orbit turning orbit_turn per loop and breathing by orbit_breath on
## target_pulse. Then the preview.
func _draw_top(canvas: RID) -> void:
	var selected: int = _index_of(_selected)
	for index: int in cell_count:
		var press: float = _press_fade.value[index]
		var select: float = _select_fade.value[index]
		if (press <= 0.0 and select <= 0.0) or _cells[index] <= 0:
			continue
		var turn: float = 0.0
		var breath: float = 0.0
		if index == selected and _pulse_period > 0.0:
			turn = _orbit_turn * _pulse_time() / _pulse_period
			breath = MotionMath.loop_wave(skin, &"target_pulse", _pulse_time())
		_tiles.draw_dashed_orbit(canvas, _center_of(index), turn, breath, maxf(press, select))
	if _show_preview():
		var center: Vector2 = _preview_center()
		_preview_painter.draw_glow(canvas, TilePainter.at(center), _preview, 1.0)
		_preview_painter.draw_orb(canvas, TilePainter.at(center), _preview, 0.0, 0.0)
