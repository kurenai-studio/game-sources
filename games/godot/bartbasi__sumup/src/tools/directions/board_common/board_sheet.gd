extends Control
## Static review sheet for one direction's tiles, 1080 by 2400:
##   1. the full ramp, 2 to 131072 plus 262144, at the real board tile size
##   2. states: 64 and 1024 in normal, chained and target state
##   3. small size check: 1024, 2K and 128K at 75 percent of the tile size
##   4. effect frames: spawn and merge pop frozen at 0, a third, two thirds
##      and the end of their durations
## Each direction's board_sheet.tscn sets direction_id.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

const Directions: GDScript = preload("res://tools/directions/shared/directions.gd")
const DirectionTokens: GDScript = preload("res://tools/directions/shared/direction_tokens.gd")
const MockState: GDScript = preload("res://tools/directions/shared/mock_state.gd")
const BoardBase: GDScript = preload("res://tools/directions/board_common/board_base.gd")
const TileFx: GDScript = preload("res://tools/directions/board_common/tile_fx.gd")

# Sheet layout only, not design tokens.
const SIDE_MARGIN: float = 40.0
const TOP: float = 52.0
const COLUMN_PITCH: float = 200.0
const FRAME_PITCH: float = 250.0
const CAPTION_GAP: float = 14.0
const ROW_SPACE: float = 20.0
const SECTION_SPACE: float = 32.0
const SMALL_SCALE: float = 0.75
const FRAME_OVERFLOW: float = 0.12
const PLATE_PADDING: Vector2 = Vector2(12.0, 8.0)
const PLATE_RADIUS: int = 10
const STATE_VALUES: PackedInt32Array = [64, 1024]
const SMALL_VALUES: PackedInt32Array = [1024, 2048, 131072]
const BEYOND_VALUE: int = 262144
const FRAME_PROGRESS: PackedFloat32Array = [0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0]
const FRAME_NAMES: PackedStringArray = ["0", "1/3", "2/3", "End"]
const SPAWN_VALUE: int = 2

## Folder name of the direction, for example "gumdrop".
@export var direction_id: String = ""

var _tokens: DirectionTokens = null
var _tile_script: GDScript = null
var _board: BoardBase = null
var _caption_font: Font = null
var _caption_size: int = 0
var _caption_color: Color = Color.WHITE
var _plate: StyleBoxFlat = null
var _overlay: Control = null
var _captions: PackedStringArray = PackedStringArray()
## Per caption: x, baseline y, width, and alignment (0 left, 1 center).
var _caption_boxes: PackedVector4Array = PackedVector4Array()


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_tokens = Directions.load_tokens(direction_id)
	if _tokens == null:
		return
	_tile_script = load("%s/%s/board/tile_view.gd" % [Directions.ROOT, direction_id]) as GDScript
	_pick_caption_pair()
	# A hidden board gives the real tile size and the effect frame functions.
	var board_script: GDScript = load("%s/%s/board/board_view.gd" % [Directions.ROOT, direction_id]) as GDScript
	_board = board_script.new() as BoardBase
	_board.visible = false
	add_child(_board)
	_board.setup(_tokens)
	var width: float = MockState.CANVAS_SIZE.x - 2.0 * _tokens.num("board_margin")
	_board.size = Vector2(width, _board.preferred_height(width))
	var side: float = _board.tile_side()
	_layout(side)
	# Captions draw on a layer above the tiles, so glows and rays that reach
	# past a tile never run under caption text.
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_captions)
	queue_redraw()


func _layout(side: float) -> void:
	var caption_line: float = float(_caption_size)
	var y: float = TOP

	# 1. The ramp, five per row, each value in full under its tile.
	_caption("%s ramp, 2 to 128K and above" % _tokens.display_name, Vector2(SIDE_MARGIN, y + caption_line), 1000.0, false)
	y += caption_line + CAPTION_GAP * 2.0
	var ramp: PackedInt32Array = PackedInt32Array()
	var value: int = DirectionTokens.RAMP_LOW
	while value <= DirectionTokens.RAMP_HIGH:
		ramp.append(value)
		value *= 2
	ramp.append(BEYOND_VALUE)
	var row_pitch: float = side + CAPTION_GAP + caption_line + ROW_SPACE
	for i: int in ramp.size():
		var column: int = i % 5
		var row: int = i / 5
		var cell_x: float = SIDE_MARGIN + column * COLUMN_PITCH
		var top: float = y + row * row_pitch
		_add_tile(ramp[i], Vector2(cell_x + (COLUMN_PITCH - side) * 0.5, top), side, 0)
		_caption(MockState.format_number(ramp[i]), Vector2(cell_x, top + side + CAPTION_GAP + caption_line), COLUMN_PITCH, true)
	y += ceilf(ramp.size() / 5.0) * row_pitch + SECTION_SPACE * 0.5

	# 2. States, and 3. the small size check beside them.
	var state_names: PackedStringArray = ["Normal", "Chained", "Target"]
	for column: int in 3:
		_caption(state_names[column], Vector2(SIDE_MARGIN + column * COLUMN_PITCH, y + caption_line), COLUMN_PITCH, true)
	var small_x: float = SIDE_MARGIN + 3.0 * COLUMN_PITCH + 60.0
	var small_side: float = side * SMALL_SCALE
	_caption("Small, 75%", Vector2(small_x, y + caption_line), small_side + 120.0, false)
	y += caption_line + CAPTION_GAP * 2.0
	var state_top: float = y
	for row: int in STATE_VALUES.size():
		for column: int in 3:
			var cell_x: float = SIDE_MARGIN + column * COLUMN_PITCH
			_add_tile(STATE_VALUES[row], Vector2(cell_x + (COLUMN_PITCH - side) * 0.5, y), side, column)
		y += side + ROW_SPACE * 1.5
	var small_pitch: float = (y - state_top) / float(SMALL_VALUES.size())
	for i: int in SMALL_VALUES.size():
		_add_tile(SMALL_VALUES[i], Vector2(small_x, state_top + i * small_pitch), small_side, 0)
	y += SECTION_SPACE * 0.5

	# 4. Effect frames, frozen at fixed progress values. A popping tile
	# grows past its rect, so these captions sit a little lower.
	var frame_gap: float = CAPTION_GAP + side * FRAME_OVERFLOW
	for effect: int in 2:
		var title: String = "Spawn, %d ms" % roundi(_tokens.duration("spawn") * 1000.0)
		if effect == 1:
			title = "Merge pop to %d, %d ms" % [MockState.CHAIN_PREVIEW, roundi(_tokens.duration("merge_pop") * 1000.0)]
		_caption(title, Vector2(SIDE_MARGIN, y + caption_line), 1000.0, false)
		y += caption_line + CAPTION_GAP * 2.0
		for frame: int in FRAME_PROGRESS.size():
			var fx: TileFx = TileFx.new()
			if effect == 0:
				_board.spawn_frame(fx, FRAME_PROGRESS[frame])
			else:
				_board.pop_frame(fx, FRAME_PROGRESS[frame])
			var cell_x: float = SIDE_MARGIN + frame * FRAME_PITCH
			var tile: Control = _add_tile(SPAWN_VALUE if effect == 0 else MockState.CHAIN_PREVIEW, Vector2(cell_x + (FRAME_PITCH - side) * 0.5, y), side, 0)
			tile.call("set_fx", fx)
			_caption(FRAME_NAMES[frame], Vector2(cell_x, y + side + frame_gap + caption_line), FRAME_PITCH, true)
		y += side + frame_gap + caption_line + ROW_SPACE + SECTION_SPACE * 0.5


func _add_tile(value: int, top_left: Vector2, side: float, state: int) -> Control:
	var tile: Control = _tile_script.new() as Control
	add_child(tile)
	tile.position = top_left
	tile.size = Vector2(side, side)
	tile.call("setup", _tokens)
	tile.call("set_value", value)
	tile.call("set_state", state)
	return tile


func _caption(text: String, baseline_left: Vector2, width: float, centered: bool) -> void:
	_captions.append(_tokens.cased("label", text))
	_caption_boxes.append(Vector4(baseline_left.x, baseline_left.y, width, 1.0 if centered else 0.0))


## Captions use the direction's label text pair, and each sits on a plate of
## that pair's background color. On bg the plate is invisible, but where a
## glow or ray from a tile reaches under a caption, the plate keeps the text
## on its flat listed background.
func _pick_caption_pair() -> void:
	_caption_font = _tokens.font("label")
	_caption_size = _tokens.font_size("label")
	var chosen: Dictionary = {}
	for entry: Dictionary in _tokens.text_pairs:
		var fg: String = String(entry["fg"])
		if fg != "ink_soft" and fg != "ink_muted":
			continue
		if chosen.is_empty() or String(entry["bg"]) == "bg":
			chosen = entry
	if chosen.is_empty():
		chosen = _tokens.text_pairs[0]
	_caption_color = _tokens.color(String(chosen["fg"]))
	_plate = StyleBoxFlat.new()
	_plate.bg_color = _tokens.color(String(chosen["bg"]))
	_plate.set_corner_radius_all(PLATE_RADIUS)
	_plate.anti_aliasing = true


func _draw() -> void:
	if _tokens != null:
		draw_rect(Rect2(Vector2.ZERO, size), _tokens.color("bg"))


func _draw_captions() -> void:
	for i: int in _captions.size():
		var box: Vector4 = _caption_boxes[i]
		var text_width: float = _caption_font.get_string_size(_captions[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _caption_size).x
		var left: float = box.x + (box.z - text_width) * 0.5 if box.w > 0.5 else box.x
		if _plate != null:
			var ascent: float = _caption_font.get_ascent(_caption_size)
			var descent: float = _caption_font.get_descent(_caption_size)
			var plate: Rect2 = Rect2(left, box.y - ascent, text_width, ascent + descent).grow_individual(PLATE_PADDING.x, PLATE_PADDING.y, PLATE_PADDING.x, PLATE_PADDING.y)
			_plate.draw(_overlay.get_canvas_item(), plate)
		_overlay.draw_string(_caption_font, Vector2(left, box.y), _captions[i], HORIZONTAL_ALIGNMENT_LEFT, -1.0, _caption_size, _caption_color)
