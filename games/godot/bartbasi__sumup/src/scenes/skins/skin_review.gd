extends Control
## Review page for one skin's production board and tile views, 1080 by 2400,
## for the senior-graphic-designer. Each scene in scenes/skins/ sets the skin
## and the page:
##   board      a mid game board with a chain, the preview and the joinable
##              highlight, placed as on the play screen
##   targeting  Swap targeting: the first tile selected, a finger down on a
##              second tile (press feedback)
##   tiers      every value from 2 to 128K and three above (the longest
##              labels), at the board tile size; the states on three
##              tiers; the small sizes
##   effects    frozen frames of merge, clear, fall and spawn
## Capture with tools/capture.tscn (see the report in the task brief).
##
## Every board here is the real SkinBoardView from SkinCatalog; frozen frames
## pause its effect clock and step it to the moment shown. Tiles are given by
## exponent k (the tile is 2^k, ARCHITECTURE.md 17).

const CommonBoardView: GDScript = preload("res://src/skins/common/common_board_view.gd")
const MotionMath: GDScript = preload("res://src/skins/common/motion_math.gd")

## The page's text: the label role in ink_muted on bg, a pair every skin lists.
const TEXT_ROLE: StringName = &"label"
# Page layout. These place review content only; nothing here is a skin value.
const PAGE_MARGIN: float = 40.0
const PAGE_TOP: float = 60.0
## Where the play screen's safe area starts on the capture canvas.
const SAFE_TOP: float = 120.0
const SECTION_GAP: float = 56.0
const CAPTION_GAP: float = 12.0
const FRAME_GAP: float = 20.0
const FRAME_COUNT: int = 4
## Samples used to find moments on a motion curve.
const CURVE_STEPS: int = 400
## A dip below 0 or an overshoot past 1 smaller than this is rounding in
## the curve (Godot's expo ease), not a back ease.
const CURVE_NOTICE: float = 0.01
const SMALL_SIDES: PackedFloat32Array = [72.0, 112.0]

## The board of the board and targeting pages, as exponents: the Phase 1
## mock board with a 128 and a 256 by the chain's end, so the joinable
## highlight shows.
const BOARD: Array[int] = [
	1, 4, 2, 1, 3,
	7, 10, 6, 3, 1,
	4, 7, 1, 5, 2,
	1, 2, 8, 4, 6,
	5, 3, 3, 1, 4,
	2, 11, 4, 2, 1,
	3, 1, 5, 8, 3,
	6, 2, 1, 3, 2,
]
## Exponents shown past the ramp on the tiers page: 256K, 128aa (2^67, the
## first 5 character label) and 128aaa (2^5827, the first 6 character label).
const ABOVE_RAMP: Array[int] = [18, 67, 5827]
const CHAIN: Array[Vector2i] = [
	Vector2i(1, 4), Vector2i(2, 4), Vector2i(3, 3), Vector2i(3, 2), Vector2i(2, 1), Vector2i(1, 2),
]
## The finger, in cell units from the grid origin: off the board to the
## left, so the tail shows stopping at the board's edge (DESIGN_SYSTEM.md 3.6).
const DRAG_CELLS: Vector2 = Vector2(-0.18, 2.95)
## The ring that marks the finger on the board page.
const FINGER_RADIUS: float = 28.0
const FINGER_STROKE: float = 3.0
const SWAP_SELECTED: Vector2i = Vector2i(1, 5)
const SWAP_PRESSED: Vector2i = Vector2i(3, 6)
## No finger (SkinBoardView.set_chain).
const NO_DRAG: Vector2 = Vector2(-1.0, -1.0)

@export var skin_id: StringName = &"gumdrop"
## board, targeting, tiers or effects.
@export var page: String = "board"

var _skin: SkinData = null
var _captions: PackedStringArray = PackedStringArray()
var _caption_spots: PackedVector2Array = PackedVector2Array()
var _caption_widths: PackedFloat32Array = PackedFloat32Array()
var _overlay: Control = null
## Where the finger is on the page, or NO_DRAG.
var _finger: Vector2 = NO_DRAG


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_skin = SkinCatalog.get_skin(skin_id)
	match page:
		"board":
			_build_board_page(false)
		"targeting":
			_build_board_page(true)
		"tiers":
			_build_tiers_page()
		"effects":
			_build_effects_page()
		_:
			push_error("unknown review page '%s'" % page)
	# Captions draw above everything, so no glow ever runs under their text.
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_overlay.draw.connect(_draw_captions)
	queue_redraw()


func _draw() -> void:
	if _skin != null:
		draw_rect(Rect2(Vector2.ZERO, size), _skin.color(&"bg"))


# Pages.

func _build_board_page(targeting: bool) -> void:
	var width: float = _canvas_width() - 2.0 * _skin.num(&"board_margin")
	var top: float = SAFE_TOP + _skin.num(&"hud_height") + _skin.num(&"space_s")
	var title: String = "%s: Swap, first tile selected, finger on a second" if targeting \
			else "%s: chain, preview, joinable, finger off the board"
	_caption(title % _skin.display_name, Vector2(PAGE_MARGIN, PAGE_TOP))
	var board: CommonBoardView = _make_board(5, 8, Vector2(_skin.num(&"board_margin"), top), width)
	board.set_board(_board_cells())
	if targeting:
		board.set_targeting(&"swap")
		board.set_swap_selected(SWAP_SELECTED)
		board.set_pressed_cell(SWAP_PRESSED)
		# A quarter of the target_pulse loop: the selection at its widest swing.
		board.advance_effects(maxf(_skin.duration(&"press"), _skin.duration(&"target_pulse") * 0.25))
		return
	var chain: Array[Vector2i] = CHAIN.duplicate()
	var config: GameConfig = GameConfig.new()
	var cells: PackedInt64Array = _board_cells()
	var values: PackedInt64Array = PackedInt64Array()
	for cell: Vector2i in chain:
		values.append(cells[CoreRules.index_of(cell, config.columns)])
	var finger: Vector2 = board.grid_origin() + DRAG_CELLS * board.cell_pitch()
	board.set_chain(chain, finger)
	_finger = board.position + finger
	board.set_joinable(CoreRules.joinable_cells(cells, BigNum.zero(), chain, config))
	board.set_preview(CoreRules.merge_result(values))
	board.advance_effects(maxf(_skin.duration(&"chain_add"), _skin.duration(&"joinable_in")))


func _build_tiers_page() -> void:
	var board_side: float = _reference_tile_side()
	var y: float = PAGE_TOP
	# Every value: 2 to 131072, then a few above the ramp.
	_caption("%s: every value at the board tile size" % _skin.display_name, Vector2(PAGE_MARGIN, y))
	y += _line_height() + CAPTION_GAP * 2.0
	var values: Array[int] = []
	for exponent: int in range(1, SkinData.RAMP_SIZE + 1):
		values.append(exponent)
	values.append_array(ABOVE_RAMP)
	var column_pitch: float = (_canvas_width() - 2.0 * PAGE_MARGIN) / 5.0
	var row_pitch: float = board_side + CAPTION_GAP + _line_height() + FRAME_GAP
	for i: int in values.size():
		@warning_ignore("integer_division")
		var row: int = i / 5
		var column: int = i % 5
		var left: float = PAGE_MARGIN + column_pitch * float(column)
		var top: float = y + row_pitch * float(row)
		_add_tile(values[i], Vector2(left + (column_pitch - board_side) * 0.5, top), board_side)
		var tier: int = _skin.tier_for(values[i])
		_caption("2^%d  t%d" % [values[i], tier],
				Vector2(left, top + board_side + CAPTION_GAP), column_pitch)
	y += row_pitch * ceilf(float(values.size()) / 5.0) + SECTION_GAP * 0.5

	# States on a low tier, a high tier and a special tile.
	var states: PackedStringArray = ["Normal", "Chained", "Joinable", "Pressed", "Selected"]
	for column: int in states.size():
		_caption(states[column], Vector2(PAGE_MARGIN + column_pitch * float(column), y), column_pitch)
	y += _line_height() + CAPTION_GAP
	var state_values: Array[int] = [3, _first_value_of_tier(_skin.tier_for(SkinData.RAMP_SIZE) - 1), SkinData.RAMP_SIZE]
	var probe: CommonBoardView = _measure_board(1, 1, column_pitch - FRAME_GAP)
	var state_side: float = probe.size.y
	probe.free()
	for state_value: int in state_values:
		for column: int in states.size():
			var left: float = PAGE_MARGIN + column_pitch * float(column) + FRAME_GAP * 0.5
			var board: CommonBoardView = _make_board(1, 1, Vector2(left, y), column_pitch - FRAME_GAP)
			board.set_board(PackedInt64Array([state_value]))
			_set_state(board, column)
		y += state_side + FRAME_GAP
	y += SECTION_GAP * 0.5

	# Small sizes: the skin chips (72), the menu tiles (112) and the preview.
	_caption("Tile view at 72 px, 112 px and the preview size", Vector2(PAGE_MARGIN, y))
	y += _line_height() + CAPTION_GAP * 2.0
	var sides: PackedFloat32Array = SMALL_SIDES.duplicate()
	sides.append(board_side * _skin.num(&"preview_scale"))
	var small_values: Array[int] = [1, 10, 11, 17, 67]
	for small_side: float in sides:
		var x: float = PAGE_MARGIN
		for small_value: int in small_values:
			_add_tile(small_value, Vector2(x, y), small_side)
			x += small_side + FRAME_GAP * 2.0
		y += small_side + FRAME_GAP * 1.5


func _build_effects_page() -> void:
	var y: float = PAGE_TOP
	_caption("%s: frozen frames of each effect" % _skin.display_name, Vector2(PAGE_MARGIN, y))
	y += _line_height() + CAPTION_GAP * 2.0
	var slot: float = (_canvas_width() - 2.0 * PAGE_MARGIN - FRAME_GAP * float(FRAME_COUNT - 1)) / float(FRAME_COUNT)
	var effects: PackedStringArray = ["merge", "clear", "fall", "spawn"]
	var names: PackedStringArray = ["Merge", "Clear", "Fall", "Fall and spawn together"]
	for e: int in effects.size():
		var effect: String = effects[e]
		var times: PackedFloat32Array = _frame_times(effect)
		_caption("%s, %.2f s in all" % [names[e], _visual_length(effect)], Vector2(PAGE_MARGIN, y))
		y += _line_height() + CAPTION_GAP
		var height: float = 0.0
		for i: int in times.size():
			var left: float = PAGE_MARGIN + (slot + FRAME_GAP) * float(i)
			var board: CommonBoardView = _make_board(2, 3, Vector2(left, y), slot)
			height = board.size.y
			_freeze(board, effect, times[i])
			_caption("%.2f s" % times[i], Vector2(left, y + height + CAPTION_GAP), slot)
		y += height + CAPTION_GAP + _line_height() + SECTION_GAP * 0.6


## Four moments of an effect where its motion visibly moves: where the
## curve passes set values, at a back ease's dip or overshoot, and the tails.
func _frame_times(effect: String) -> PackedFloat32Array:
	var times: PackedFloat32Array = PackedFloat32Array()
	match effect:
		"merge":
			var travel: float = _skin.duration(&"merge_travel")
			var pop: float = _skin.duration(&"merge_pop")
			times.append(travel * _curve_progress(&"merge_travel", 0.35))
			times.append(travel * _curve_progress(&"merge_travel", 0.8))
			times.append(travel + pop * 0.12)
			times.append(travel + pop * 0.5)
		"clear":
			var length: float = _skin.duration(&"clear")
			var burst: float = float(_skin.motion_spec(&"clear").get("burst_fade", 0.0))
			var dip: float = _curve_dip(&"clear")
			times.append(length * (dip if dip >= 0.0 else _curve_progress(&"clear", 0.3)))
			times.append(length * _curve_progress(&"clear", 0.75))
			if burst > 0.0:
				times.append(length + burst * 0.2)
				times.append(length + burst * 0.6)
			elif _skin.motion_spec(&"clear").has("sparks"):
				# Sparks drift out and fade linearly: show them on their way.
				times.clear()
				for share: float in [0.3, 0.5, 0.7, 0.9]:
					times.append(length * share)
			else:
				times.append(length * _curve_progress(&"clear", 0.9))
				times.append(length * 0.97)
		"fall":
			var length: float = _skin.duration(&"fall")
			var peak: float = _curve_peak(&"fall")
			times.append(length * _curve_progress(&"fall", 0.35))
			times.append(length * _curve_progress(&"fall", 0.8))
			times.append(length * (peak if peak >= 0.0 else _curve_progress(&"fall", 0.95)))
			times.append(length * 0.97)
		"spawn":
			# The first frame catches the falling tile just leaving the cell
			# a new tile grows into, behind it.
			var fall: float = _skin.duration(&"fall")
			var total: float = _visual_length(effect)
			times.append(fall * _curve_progress(&"fall", 0.3))
			times.append(fall * _curve_progress(&"fall", 0.75))
			times.append(total * 0.6)
			times.append(total * 0.9)
	return times


## The first linear progress at which a motion's eased value reaches value.
func _curve_progress(motion_name: StringName, value: float) -> float:
	for i: int in CURVE_STEPS + 1:
		var progress: float = float(i) / float(CURVE_STEPS)
		if MotionMath.eased(_skin, motion_name, progress) >= value:
			return progress
	return 1.0


## Progress where a curve dips lowest below 0 (a back ease in), or -1.
func _curve_dip(motion_name: StringName) -> float:
	var best: float = -1.0
	var lowest: float = -CURVE_NOTICE
	for i: int in CURVE_STEPS + 1:
		var progress: float = float(i) / float(CURVE_STEPS)
		var value: float = MotionMath.eased(_skin, motion_name, progress)
		if value < lowest:
			lowest = value
			best = progress
	return best


## Progress where a curve overshoots highest past 1 (a back ease out), or -1.
func _curve_peak(motion_name: StringName) -> float:
	var best: float = -1.0
	var highest: float = 1.0 + CURVE_NOTICE
	for i: int in CURVE_STEPS:
		var progress: float = float(i) / float(CURVE_STEPS)
		var value: float = MotionMath.eased(_skin, motion_name, progress)
		if value > highest:
			highest = value
			best = progress
	return best


# Effects frozen on a 2 by 3 board.

func _freeze(board: CommonBoardView, effect: String, at: float) -> void:
	match effect:
		"merge":
			var chain: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1), Vector2i(0, 1)]
			board.set_board(PackedInt64Array([1, 1, 3, 2, 4, 5]))
			board.set_chain(chain, NO_DRAG)
			board.advance_effects(_skin.duration(&"chain_add"))
			board.play_merge(chain, Vector2i(0, 1), 4)
		"clear":
			board.set_board(PackedInt64Array([1, 2, 6, 1, 7, 1]))
			var cleared: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 2)]
			board.play_clear(cleared)
		"fall":
			board.set_board(PackedInt64Array([4, 5, 0, 6, 0, 0]))
			var from: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0)]
			var to: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2), Vector2i(1, 1)]
			board.play_fall(from, to)
		"spawn":
			# Falls and spawns start together (DESIGN_SYSTEM.md 3.6).
			board.set_board(PackedInt64Array([4, 5, 0, 6, 0, 0]))
			var from: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 1), Vector2i(1, 0)]
			var to: Array[Vector2i] = [Vector2i(0, 2), Vector2i(1, 2), Vector2i(1, 1)]
			board.play_fall(from, to)
			var cells: Array[Vector2i] = [Vector2i(0, 0), Vector2i(0, 1), Vector2i(1, 0)]
			board.play_spawn(cells, PackedInt64Array([1, 2, 3]))
	board.advance_effects(at)


## The whole visible length of an effect on the effects page, tails
## included: the bloom after a Nova merge and the burst after a Gumdrop clear.
func _visual_length(effect: String) -> float:
	match effect:
		"merge":
			return _skin.duration(&"merge_travel") + _skin.duration(&"merge_pop")
		"clear":
			var spec: Dictionary = _skin.motion_spec(&"clear")
			return _skin.duration(&"clear") + float(spec.get("burst_fade", 0.0))
		"fall":
			return _skin.duration(&"fall")
		"spawn":
			var spawn: float = _skin.duration(&"spawn") + float(_skin.motion_spec(&"spawn").get("stagger", 0.0)) * 2.0
			return maxf(_skin.duration(&"fall"), spawn)
	return 0.0


# Helpers.

func _make_board(board_columns: int, board_rows: int, position_px: Vector2, width: float) -> CommonBoardView:
	var board: CommonBoardView = _measure_board(board_columns, board_rows, width)
	add_child(board)
	board.position = position_px
	return board


## A paused board of this size, not yet in the tree.
func _measure_board(board_columns: int, board_rows: int, width: float) -> CommonBoardView:
	var board: CommonBoardView = SkinCatalog.make_board_view(_skin) as CommonBoardView
	board.effects_paused = true
	board.setup(_skin, board_columns, board_rows)
	board.size = Vector2(width, board.preferred_height(width))
	return board


func _add_tile(value: int, top_left: Vector2, side: float) -> void:
	var tile: SkinTileView = SkinCatalog.make_tile_view(_skin)
	add_child(tile)
	tile.position = top_left
	tile.size = Vector2(side, side)
	tile.set_value(value)


func _set_state(board: CommonBoardView, state: int) -> void:
	var cell: Vector2i = Vector2i(0, 0)
	var cells: Array[Vector2i] = [cell]
	match state:
		1:
			board.set_chain(cells, NO_DRAG)
		2:
			board.set_joinable(cells)
		3:
			board.set_targeting(&"hammer")
			board.set_pressed_cell(cell)
		4:
			board.set_targeting(&"swap")
			board.set_swap_selected(cell)
	var settle: float = maxf(maxf(_skin.duration(&"chain_add"), _skin.duration(&"joinable_in")), _skin.duration(&"press"))
	board.advance_effects(maxf(settle, _skin.duration(&"target_pulse") * 0.25))


func _board_cells() -> PackedInt64Array:
	var cells: PackedInt64Array = PackedInt64Array()
	for value: int in BOARD:
		cells.append(value)
	return cells


## The board tile side on the base canvas.
func _reference_tile_side() -> float:
	var board: CommonBoardView = _measure_board(5, 8, _canvas_width() - 2.0 * _skin.num(&"board_margin"))
	var side: float = board.tile_side()
	board.free()
	return side


## The lowest exponent of a tier, for the states row.
func _first_value_of_tier(tier: int) -> int:
	for exponent: int in range(1, SkinData.RAMP_SIZE + 1):
		if _skin.tier_for(exponent) == tier:
			return exponent
	return SkinData.RAMP_SIZE


func _canvas_width() -> float:
	return float(ProjectSettings.get_setting("display/window/size/viewport_width"))



func _line_height() -> float:
	return float(_skin.font_size(TEXT_ROLE))


## A caption with its top left at spot. A width above 0 centers it there.
func _caption(text: String, spot: Vector2, width: float = 0.0) -> void:
	_captions.append(_skin.cased(TEXT_ROLE, text))
	_caption_spots.append(spot)
	_caption_widths.append(width)


func _draw_captions() -> void:
	var font: Font = _skin.font(TEXT_ROLE)
	var font_size: int = _skin.font_size(TEXT_ROLE)
	var color: Color = _skin.color(&"ink_muted")
	for i: int in _captions.size():
		var baseline: Vector2 = _caption_spots[i] + Vector2(0.0, font.get_ascent(font_size))
		var align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER if _caption_widths[i] > 0.0 else HORIZONTAL_ALIGNMENT_LEFT
		_overlay.draw_string(font, baseline, _captions[i], align, _caption_widths[i] if _caption_widths[i] > 0.0 else -1.0, font_size, color)
	if _finger != NO_DRAG:
		_overlay.draw_arc(_finger, FINGER_RADIUS, 0.0, TAU, 48, color, FINGER_STROKE, true)
