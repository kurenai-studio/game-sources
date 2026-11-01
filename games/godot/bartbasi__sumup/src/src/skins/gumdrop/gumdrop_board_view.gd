extends "res://src/skins/common/common_board_view.gd"
## The Gumdrop board (DESIGN_SYSTEM.md 4.7): candy tiles in a rounded tray,
## a white rope under the tiles that shows in the gaps like beads on a
## string and runs on to the finger, and the merge preview as a ringed mini
## tile on the gap crossing by the last chain tile. Springy motion.
##
## Layers: back (tray and empty slots), line (the rope), tiles (each tile in
## its own item; a chained tile's press_scale and the selected tile's wobble
## are its item's transform), top (the preview and the candy bursts).

const GumdropTilePainter: GDScript = preload("res://src/skins/gumdrop/gumdrop_tile_painter.gd")

var _tiles: GumdropTilePainter = null
var _preview_painter: GumdropTilePainter = null
var _tray_box: StyleBoxFlat = null
var _burst_directions: PackedVector2Array = PackedVector2Array()

var _from_scale: float = 0.0
var _peak_scale: float = 1.0
var _squash: float = 0.0
## How far the fall's back ease overshoots; the squash is full there.
var _fall_overshoot: float = 0.0
var _wobble: float = 0.0
var _burst_size: float = 0.0
var _burst_reach: float = 0.0
var _burst_fade: float = 0.0


func _make_painter() -> TilePainter:
	return GumdropTilePainter.new() as TilePainter


func _setup_look() -> void:
	_tiles = _painter as GumdropTilePainter
	_preview_painter = GumdropTilePainter.new()
	_preview_painter.setup(skin)
	_tray_box = GumdropTilePainter.make_box(GumdropTilePainter.CORNER_DETAIL)
	_tray_box.bg_color = skin.color(&"tray")
	_from_scale = MotionMath.extra(skin, &"spawn", "from_scale")
	_peak_scale = MotionMath.extra(skin, &"merge_pop", "peak_scale")
	_squash = MotionMath.extra(skin, &"fall", "squash")
	_fall_overshoot = MotionMath.curve_range(skin, &"fall").y - 1.0
	_wobble = deg_to_rad(MotionMath.extra(skin, &"target_pulse", "wobble_degrees"))
	_burst_size = MotionMath.extra(skin, &"clear", "burst_dot_size")
	_burst_reach = MotionMath.extra(skin, &"clear", "burst_reach")
	_burst_fade = MotionMath.extra(skin, &"clear", "burst_fade")
	var dots: int = roundi(MotionMath.extra(skin, &"clear", "burst_dots"))
	_burst_directions.clear()
	for i: int in maxi(dots, 0):
		var angle: float = TAU * float(i) / float(dots)
		_burst_directions.append(Vector2(sin(angle), -cos(angle)))


func _on_layout() -> void:
	var preview_scale: float = skin.num(&"preview_scale")
	_preview_painter.set_side(_side * preview_scale, _unit * preview_scale)
	_tray_box.set_corner_radius_all(roundi(skin.num(&"tray_radius") * _unit))


# Effects.

func _spawn_frame(fx: TileFx, progress: float) -> void:
	fx.scale *= lerpf(_from_scale, 1.0, MotionMath.eased(skin, &"spawn", progress))


func _pop_frame(fx: TileFx, progress: float) -> void:
	fx.scale *= lerpf(_peak_scale, 1.0, MotionMath.eased(skin, &"merge_pop", progress))
	fx.raise_layer(TileFx.LAYER_TOP)


## Back ease out. The tile stops on its cell rather than sinking into the
## tile below; the curve's overshoot becomes the squash on landing (scale y
## 1 - squash, x 1 + squash / 2, then back).
func _fall_frame(fx: TileFx, progress: float, offset: Vector2) -> void:
	var amount: float = MotionMath.eased(skin, &"fall", progress)
	fx.offset += offset * (1.0 - minf(amount, 1.0))
	if amount > 1.0 and _fall_overshoot > 0.0:
		var squash: float = _squash * clampf((amount - 1.0) / _fall_overshoot, 0.0, 1.0)
		fx.scale *= Vector2(1.0 + squash * 0.5, 1.0 - squash)
		fx.pivot = Vector2(0.0, 0.5)
	fx.raise_layer(TileFx.LAYER_MOVING)


## Back ease in: the tile squashes into the tray as the curve dips below 0,
## then shrinks to nothing.
func _clear_frame(fx: TileFx, progress: float) -> void:
	var amount: float = MotionMath.eased(skin, &"clear", progress)
	var shrink: float = 1.0 - maxf(amount, 0.0)
	var squash: float = maxf(-amount, 0.0)
	fx.scale *= Vector2(shrink * (1.0 + squash * 0.5), shrink * (1.0 - squash))
	fx.pivot = Vector2(0.0, 0.5)


## Each cleared tile bursts into candy dots when it has shrunk away.
func _on_clear_ghost(ghost: BoardEffect) -> void:
	_add_decor(BoardEffect.BURST, ghost.origin, ghost.value, ghost.start + ghost.length, _burst_fade)


# Tiles.

func _draw_item(tile: RID, _under: RID, value: int, chain_amount: float, join: float, press: float, select: float, _flash: bool, _glow: float, _moving: bool) -> void:
	_tiles.draw_tile(tile, Transform2D.IDENTITY, value, chain_amount, join, press, select)


func _item_scale(chain_amount: float) -> float:
	return _tiles.chain_scale(chain_amount)


## The selected tile wobbles by wobble_degrees on the target_pulse loop,
## starting level.
func _item_turn(index: int) -> float:
	var select: float = _select_fade.value[index]
	if select <= 0.0 or _pulse_period <= 0.0 or index != _index_of(_selected):
		return 0.0
	var wave: float = MotionMath.loop_wave(skin, &"target_pulse", _pulse_time() + _pulse_period * 0.25)
	return _wobble * (wave * 2.0 - 1.0) * select


## The tail to the finger stays on the tray: its round end reaches the
## tray's outer edge and no further (DESIGN_SYSTEM.md 4.7).
func _tail_bounds() -> Rect2:
	return _board_rect.grow(-skin.num(&"chain_width") * _unit * 0.5)


func _top_animates() -> bool:
	for effect: BoardEffect in _effects:
		if effect.kind == BoardEffect.BURST:
			return true
	return false


# Layers.

func _draw_layer(layer: int, item: CanvasItem) -> void:
	var canvas: RID = item.get_canvas_item()
	match layer:
		LAYER_BACK:
			_tray_box.draw(canvas, _board_rect)
			for index: int in cell_count:
				if _empty_mask[index] != 0:
					_tiles.draw_slot(canvas, _rect_of(index))
		LAYER_LINE:
			_draw_rope(item)
		LAYER_TOP:
			if _show_preview():
				_preview_painter.draw_preview(canvas, _preview_center(), _preview, skin.num(&"preview_ring") * _unit)
			_draw_bursts(canvas)


## The rope: chain_width wide, round caps and joins, under the tiles.
func _draw_rope(item: CanvasItem) -> void:
	var count: int = _build_line_points()
	if count < 2:
		return
	var color: Color = skin.color(&"chain")
	var width: float = skin.num(&"chain_width") * _unit
	for i: int in count - 1:
		item.draw_line(_line_points[i], _line_points[i + 1], color, width, true)
	for i: int in count:
		item.draw_circle(_line_points[i], width * 0.5, color, true, -1.0, true)


## Candy dots in the cleared tile's fill, flying out burst_reach of the side
## round the circle and fading over burst_fade. They fly with the clear's
## transition eased out, so they spring out where the tile sprang in.
func _draw_bursts(canvas: RID) -> void:
	for effect: BoardEffect in _effects:
		if effect.kind != BoardEffect.BURST or not _has_started(effect):
			continue
		var progress: float = _progress(effect)
		var reach: float = _burst_reach * _side * MotionMath.eased(skin, &"clear", progress, Tween.EASE_OUT)
		var color: Color = skin.fill_for(effect.value)
		color.a *= 1.0 - progress
		var radius: float = _burst_size * _side * 0.5
		var center: Vector2 = _ghost_center(effect)
		for direction: Vector2 in _burst_directions:
			RenderingServer.canvas_item_add_circle(canvas, center + direction * reach, radius, color, true)
