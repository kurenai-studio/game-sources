# Visualizes a Board's current state as a 13x9 grid of colored cells, and
# accepts tiles dropped onto it from a HandView (see board_cell.gd/
# tile_panel.gd for the actual drag-and-drop mechanics). BoardView's own
# root IS the painted frame around the grid (see `frame_style`) — a
# `PanelContainer` instead of a plain `Control` so it reports the grid's
# real size to whatever contains it (see main.tscn's container-based
# layout), not just a zero-size point. Like the start screen's box (the
# board IS that box, lid off), it's drawn in "2.5D" (see oblique.gd): its
# front and right sides show below and to the right of the frame, and
# each cell is a hole, the tiles sunk flush into them.
#
# Deliberately knows nothing about GameSession, TurnManager, scoring, or
# any other game rule: it only ever reads a `Board` (see board.gd), draws
# whatever's there, and asks BlockMove (a stateless rule-checker, not a
# mutator) whether a block of tiles would fit where it's dropped. It never
# places/moves a tile itself — that's main.gd's job, listening for the
# signals below. It also never watches the board for changes on its own —
# whoever owns this node calls `refresh(board, …)` after the board changes
# (placing/removing/flipping/moving a tile).
#
# What it does keep is the player's selection: dragging across empty
# cells draws a dotted box, and the tiles under it are selected (see
# `begin_box`); dragging any of them then moves them all (see
# board_cell.gd's `_get_drag_data`).
class_name BoardView
extends PanelContainer

# Re-broadcasts whichever cell just received a dropped/moved tile — see
# board_cell.gd's own same-named signals for what a "signal" is, and for
# why one carries "from"/"to" positions while the other doesn't. Having
# these here, instead of main.gd connecting to all 117 cells individually,
# keeps BoardView's grid an implementation detail its owner doesn't need to
# know about.
signal tile_dropped(row: int, col: int, tile: Tile)
signal tile_moved(from_row: int, from_col: int, to_row: int, to_col: int)
signal tiles_moved(cells: Array[Vector2i], offset: Vector2i)
signal tile_flipped(row: int, col: int)

# Fires whenever `_update_cell_sizes` below recomputes `_cell_side` — lets
# main.gd keep the free-play palette's own tiles the same size as the
# board's (see hand_view.gd's `refresh`), without HandView needing to know
# anything about BoardView's own sizing math.
signal cell_size_changed(side: float)

# Mirrors the fixed border main.tscn's own `Margin` node keeps around the
# whole page — used by `_update_cell_sizes` below, which has no direct
# way to ask that node for its own margin, so this just needs to be kept
# in sync with it by hand if it ever changes. Public (not `_`-prefixed)
# since hand_view.gd's own palette-width math reuses this same value
# rather than risking a second, separately-drifting copy of it.
const PAGE_MARGIN := 8.0

# How much of the page's available width the board claims once the window
# is wide enough to show the board and the hand/palette side by side,
# rather than stacked (see main.gd's own matching check on
# `PlayArea.vertical`) — a FIXED fraction of the available width, not a
# measurement of BoardView's own current size, for the same "no ratchet"
# reason `_update_cell_sizes` below reads the viewport instead of
# `_grid.size.x` (see that function's own comment). Public since
# hand_view.gd's own sidebar-width math uses the complement of this exact
# constant, rather than a second, separately-drifting fraction.
const LANDSCAPE_BOARD_WIDTH_FRACTION := 0.62

# The biggest a cell is ever allowed to get, in pixels. Without a cap, an
# ultrawide/large monitor would blow the board — and its lettering — up to
# a genuinely silly size; this keeps it comfortably bigger than a phone's
# own tiles without going past what other tile/word games consider a
# normal size.
const _MAX_CELL_SIDE := 64.0

# Spacing, in pixels, assumed around each row of `reserved_bottom_rows`
# below — the hand's own 4px gap between rows (see hand_view.tscn) plus a
# share of PlayArea's 10px gap between board and hand (see main.tscn).
const _BOTTOM_ROW_GAP := 8.0

# How far the board's bottom edge sticks out from under its frame: x is
# how wide its right side looks, y how tall its front looks. Kept inside
# BoardView's own size (see `_ready`), so the layout makes room for it.
const _DEPTH := Vector2(10, 20)
# Same tints and shadow as the box's sides (see box_lid.gd): the light
# comes from the back-left, so the front is a bit darker, the right more.
const _FRONT_TINT := Color(0.72, 0.72, 0.72)
const _RIGHT_TINT := Color(0.52, 0.52, 0.52)
const _SHADOW := Color(0, 0, 0, 0.4)
# The selection box: dotted, in the letters' ink (see tile_view.gd).
const _BOX_COLOR := TileView.LETTER_COLOR
const _BOX_LINE_WIDTH := 2.0
const _BOX_DASH := 6.0
# Red frames round what stops the turn from ending: words that aren't
# words, and emptied cells (see `refresh`) — doc/ART_DIRECTION.md's
# `error` red.
const _ERROR_COLOR := Color("c8463c")
const _ERROR_LINE_WIDTH := 3.0
# How far (px) a press must move before it draws a box rather than being a
# tap (which clears the selection instead).
const _BOX_THRESHOLD := 6.0

# The painted frame's look: the same paint as the box's lid, as a
# StyleBoxTexture (an image stretched to fit a rectangle while keeping
# its `texture_margin_*` borders unstretched — a "nine-patch"). `@export`
# makes a variable settable from the editor/.tscn file, like a public
# serialized field in Unity: its value is set in board_view.tscn.
@export var frame_style: StyleBoxTexture

# Height, in pixels, of everything on the page that ISN'T the board or
# what's below it — the header row, the scoreboard, and the page's own
# margins/separators — subtracted from the viewport's height in
# `_update_cell_sizes` below so all 13 rows fit without scrolling. 120 is
# a rough default; main.gd keeps it set to the real, measured value (see
# its `_update_board_height_budget`), since the scoreboard wraps onto a
# second line with 3-4 players. Re-fits the cells on change, same as
# `reserved_right_width` below.
var vertical_overhead: float = 120.0:
	set(value):
		if value == vertical_overhead:
			return
		vertical_overhead = value
		_update_cell_sizes()

# How many rows of board-sized tiles to keep room for BELOW the board
# (the turn-based hand, in portrait — see main.gd), so the board shrinks
# just enough for the hand to fit on screen too, rather than leaving it
# to be scrolled to. 0 means the board alone gets the whole height.
var reserved_bottom_rows: int = 0:
	set(value):
		if value == reserved_bottom_rows:
			return
		reserved_bottom_rows = value
		_update_cell_sizes()

# Extra width, in pixels, kept free inside the frame right of the grid —
# room for an overlay to draw beside the rows (crossword mode's "?"
# column, see ClueMarkersView.LANE_WIDTH). 0 means the grid fills the
# frame, as usual. The `set(value):` block below is a GDScript property
# setter (like a Python @property setter): it runs on every
# `reserved_right_width = ...`, so the cells re-fit straight away.
var reserved_right_width: float = 0.0:
	set(value):
		if value == reserved_right_width:
			return
		reserved_right_width = value
		_update_cell_sizes()

# The selected tiles' cells, `Vector2i(col, row)` (see this file's header
# comment). Read by the cells, to drag them all together.
var selection: Array[Vector2i] = []

# One cell per board square, indexed [row][col] — built once in _ready()
# and reused by refresh(), rather than destroying and recreating 117 nodes
# every time the board changes.
var _cell_panels: Array = []

# The side length `_update_cell_sizes` below last gave every cell, in
# pixels — kept as a field (not just a local variable there) so
# `cell_side()` can hand it to whoever asks, e.g. the free-play palette
# matching its own tiles to the board's.
var _cell_side: float = 0.0

# The box being drawn, in `_overlay`'s coordinates: where the press
# started and where it is now. `_boxing` while the press lasts.
var _box_from := Vector2.ZERO
var _box_to := Vector2.ZERO
var _boxing := false
# What to frame in red (see `refresh`): each invalid word's cells, and the
# emptied cells, as lists of `Vector2i(col, row)` per frame.
var _error_frames: Array = []
# A plain Control laid over the grid, for the box and the frames to be
# drawn over the tiles (`_draw` itself paints under them).
var _overlay: Control

# `@onready` runs this line once this node's children actually exist
# (right before `_ready()` — a plain `var _grid := $Grid` at the top of
# the class would run too early, before the scene tree below this node
# has been built). `$Grid` is shorthand for "find my child node named
# Grid", declared in board_view.tscn.
@onready var _grid: GridContainer = $Grid


func _ready() -> void:
	# The PanelContainer's own background ("panel" style) only reserves
	# room around the grid, drawing nothing (StyleBoxEmpty): the frame's
	# margins, plus the sides' room on the right and bottom. `_draw` below
	# paints the frame and sides into that room.
	var room := StyleBoxEmpty.new()
	room.content_margin_left = frame_style.content_margin_left
	room.content_margin_top = frame_style.content_margin_top
	room.content_margin_right = frame_style.content_margin_right + _DEPTH.x
	room.content_margin_bottom = frame_style.content_margin_bottom + _DEPTH.y
	add_theme_stylebox_override("panel", room)
	_build_grid()
	# A PanelContainer stretches every child over the same area, so the
	# overlay lies exactly over the grid. It lets every click through, and
	# its `draw` signal lets this script paint on it, like a callback.
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)
	_overlay.draw.connect(_draw_overlay)
	# The viewport's own `size_changed` signal fires whenever the actual
	# window/screen size changes — e.g. the player resizing the window,
	# or an Android device simply having a different screen size than
	# this one. Keeping cells sized off that, rather than a fixed 32px,
	# is what makes the board fill the available width instead of always
	# drawing the same small fixed-size grid regardless of screen size.
	# (Listening on `_grid.resized` instead, as an earlier version of
	# this did, doesn't work: once cells claim some size, nothing ever
	# asks for less than that again, so GridContainer itself would only
	# ever grow, never actually shrink back down to even NOTICE a
	# smaller window — see `_update_cell_sizes`'s own comment.)
	get_viewport().size_changed.connect(_update_cell_sizes)
	_update_cell_sizes()


# Godot calls this when this node needs redrawing (like Qt's paintEvent);
# it sits under the children (the tray and the grid of holes). A Control
# redraws by itself when resized, so this follows the board's size.
func _draw() -> void:
	# The frame's top face: everything but the room kept for the sides.
	var top := Rect2(Vector2.ZERO, size - _DEPTH)
	# A soft shadow on the felt, cast down-right like the sides.
	draw_rect(Rect2(_DEPTH + Vector2(4, 4), top.size), _SHADOW)
	Oblique.draw_sides(self, top, _DEPTH, _FRONT_TINT, _RIGHT_TINT, frame_style.texture)
	draw_style_box(frame_style, top)


# Creates all 117 cell nodes once, empty. GridContainer lays out its
# children left-to-right then wraps after `columns` of them (set to 9 in
# board_view.tscn), so simply adding them row by row, column by column,
# naturally produces the right grid shape with no manual positioning. Each
# cell's actual size is set separately, once real space is available (see
# `_update_cell_sizes`) — not here, since nothing has been laid out yet.
func _build_grid() -> void:
	for row in range(Board.ROWS):
		var panel_row: Array = []
		for col in range(Board.COLUMNS):
			var panel := BoardCell.new()
			panel.row = row
			panel.col = col
			panel.board_view = self
			# The cell draws its hole itself (see board_cell.gd's `_draw`),
			# so its own Panel background is switched off: StyleBoxEmpty
			# draws nothing.
			panel.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
			# Connects this cell's own signals to methods on BoardView (see
			# `_on_cell_tile_dropped`/`_on_cell_tile_moved` below) — the
			# standard Godot way of reacting to a signal, same idea as a Qt
			# slot or a C callback registered against a function pointer.
			panel.tile_dropped.connect(_on_cell_tile_dropped)
			panel.tile_moved.connect(_on_cell_tile_moved)
			panel.tiles_moved.connect(_on_cell_tiles_moved)
			panel.tile_flipped.connect(_on_cell_tile_flipped)

			# The tile's face, raised above the cell; sized and placed in
			# `_update_cell_sizes` once the cell's own size is known. It
			# lets clicks through to the cell, which handles them.
			var face := Panel.new()
			face.mouse_filter = Control.MOUSE_FILTER_IGNORE
			panel.add_child(face)
			panel.face = face

			var label := TileView.build_letter_label()
			face.add_child(label)
			# Handed to the cell itself (not just kept here) so it can
			# redraw its own text/color — needed both by `refresh()` below
			# and by the cell itself once a drag that started there ends
			# (see board_cell.gd's `refresh()`/`_notification`).
			panel.label = label

			# Same idea for the small "other face" hint badge (see
			# tile_view.gd's build_corner_badge/update_corner_badge).
			var corner_badge := TileView.build_corner_badge()
			face.add_child(corner_badge)
			panel.corner_badge = corner_badge

			_grid.add_child(panel)
			panel_row.append(panel)
		_cell_panels.append(panel_row)


# Resizes every cell to be as big as it can while (a) staying square, (b)
# fitting exactly `Board.COLUMNS` of them across the viewport's current
# width, AND (c) fitting all `Board.ROWS` of them within its current
# height too (see `vertical_overhead` above) — instead of a fixed pixel
# size that would leave empty space around the board on a big screen, run
# off the right edge on a narrow one, or spill past the bottom needing a
# scroll to see the rest of it. Deliberately reads the VIEWPORT's own size
# rather than `_grid.size` (GridContainer's own current size) — a cell's
# own `custom_minimum_size` is exactly what feeds into how big GridContainer
# (and everything containing it, up to BoardView itself) reports NEEDING to
# be, so measuring that directly has a feedback problem: once cells have
# claimed some size, nothing ever asks a *container* for less than that
# claim again, even once the window shrinks and there's genuinely less
# room. That was a real, one-way-ratchet bug this used to have. The
# viewport's own size is the one number in this whole chain that's never
# influenced by how big the cells last were.
func _update_cell_sizes() -> void:
	# The frame's own content margin (plus the sides' room, see `_ready`)
	# already eats into how much of BoardView's own size the grid actually
	# gets — read directly off the stylebox rather than hardcoding it a
	# second time here.
	var room: StyleBox = get_theme_stylebox("panel")
	var frame_margin_h: float = room.content_margin_left + room.content_margin_right
	var frame_margin_v: float = room.content_margin_top + room.content_margin_bottom
	var h_separation: int = _grid.get_theme_constant("h_separation")
	var v_separation: int = _grid.get_theme_constant("v_separation")
	var viewport_size := get_viewport_rect().size

	var content_width := viewport_size.x - PAGE_MARGIN
	# In landscape, the board only gets its own fixed share of the page —
	# the rest goes to the hand/palette sitting beside it instead of below
	# it (see `_is_landscape`/`LANDSCAPE_BOARD_WIDTH_FRACTION` above).
	if _is_landscape():
		content_width *= LANDSCAPE_BOARD_WIDTH_FRACTION
	var available_width := (
		content_width - frame_margin_h - reserved_right_width - h_separation * (Board.COLUMNS - 1)
	)

	# However wide a cell could be isn't the whole story — a tall, narrow
	# board would still spill past the bottom of the screen on an ordinary
	# desktop window. Capping by whichever of width/height is tighter is
	# what actually keeps all 13 rows visible without scrolling on a big
	# screen (see `vertical_overhead` above). The rows kept free below the
	# board (see `reserved_bottom_rows`) are the same size as a cell, so
	# they share the height with the board's own 13 rows.
	var available_height := (
		viewport_size.y
		- vertical_overhead
		- frame_margin_v
		- v_separation * (Board.ROWS - 1)
		- _BOTTOM_ROW_GAP * reserved_bottom_rows
	)

	if available_width <= 0 or available_height <= 0:
		return
	_cell_side = min(
		floor(available_width / Board.COLUMNS),
		floor(available_height / (Board.ROWS + reserved_bottom_rows)),
		_MAX_CELL_SIDE
	)
	# The letter and corner square scale with the cell itself, rather than
	# staying fixed — a fixed size would look tiny on a wide screen's
	# huge cells, or overflow a narrow screen's small ones.
	var face := TileView.face_rect(_cell_side)
	for panel_row in _cell_panels:
		for panel: BoardCell in panel_row:
			panel.custom_minimum_size = Vector2(_cell_side, _cell_side)
			# The face isn't in a container, so its position and size are
			# set directly; it then stays put until the next resize.
			panel.face.position = face.position
			panel.face.size = face.size
			TileView.fit_to_side(panel.label, panel.corner_badge, face.size.x)
	cell_size_changed.emit(_cell_side)


# Whether the window is wider than it is tall — see `PlayArea.vertical` in
# main.gd, toggled by this exact same comparison, for what actually
# arranges the board and hand/palette side by side instead of stacked.
func _is_landscape() -> bool:
	var size := get_viewport_rect().size
	return size.x > size.y


# The side length (in pixels) `_update_cell_sizes` above last gave every
# board cell — 0 before the first layout pass has actually run. Lets
# whoever's drawing tiles elsewhere (currently: the free-play palette, see
# hand_view.gd) match the board's own size instead of a fixed guess.
func cell_side() -> float:
	return _cell_side


# The rectangle board row `row` occupies, in Grid's own coordinates —
# which are also the coordinates of any overlay node added as another
# child of BoardView (see ClueMarkers in main.tscn), since a
# PanelContainer stretches every one of its children over the exact same
# area inside the frame. Computed from `_cell_side` rather than read off
# the cells' own `position`s, which only catch up once Godot's container
# layout runs again a frame later.
func row_rect(row: int) -> Rect2:
	var h_separation: int = _grid.get_theme_constant("h_separation")
	var v_separation: int = _grid.get_theme_constant("v_separation")
	var width := Board.COLUMNS * _cell_side + (Board.COLUMNS - 1) * h_separation
	return Rect2(0, row * (_cell_side + v_separation), width, _cell_side)


# Redraws every cell from `board`'s current state, and frames in red what
# stops the turn from ending (see GameSession): `invalid_cells`, the
# `{row, col}` tiles breaking the turn's shape (red-bordered themselves,
# see GameSession.invalid_cells); `invalid_words`, the `{row, col, word}`
# words that aren't words (see GameSession.invalid_words); and
# `emptied_cells`, the `Vector2i(col, row)` cells that must be filled
# again (see GameSession.emptied_cells). Free play has none of these, so
# all default to empty.
func refresh(
	board: Board, invalid_cells: Array = [], invalid_words: Array = [], emptied_cells: Array = []
) -> void:
	# A quick "is (row, col) in the list" lookup built once per refresh,
	# rather than re-scanning `invalid_cells` for every one of the 117
	# cells below.
	var invalid_lookup := {}
	for cell in invalid_cells:
		invalid_lookup["%d_%d" % [cell["row"], cell["col"]]] = true

	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			var panel: BoardCell = _cell_panels[row][col]
			# Kept current every refresh, not just at creation, in case a
			# future save/load ever swaps in a whole new Board instance.
			panel.board = board
			panel.invalid = invalid_lookup.has("%d_%d" % [row, col])
			panel.refresh()

	_error_frames.clear()
	for word in invalid_words:
		var columns := board.word_columns_at(word["row"], word["col"])
		var cells: Array[Vector2i] = []
		for col in columns:
			cells.append(Vector2i(col, word["row"]))
		_error_frames.append(cells)
	for cell in emptied_cells:
		_error_frames.append([cell])
	# A selected tile that has left its cell (taken back, moved alone) is
	# no longer selected. `filter` keeps the items its function returns
	# true for, like Python's filter(); `func(cell): …` is a lambda;
	# `assign` copies the result into the typed array.
	selection.assign(selection.filter(func(cell): return not board.is_empty(cell.y, cell.x)))
	_overlay.queue_redraw()


# Each of `cells`' tiles hops, one after another, `stagger` seconds apart
# — a scored word's letters left to right, or the whole board row by row
# (see board_cell.gd's `hop`).
func hop(cells: Array[Vector2i], stagger: float) -> void:
	for i in range(cells.size()):
		get_cell(cells[i].y, cells[i].x).hop(i * stagger)


# Every tile framed in red (see `refresh`) shakes: why the turn can't end.
func shake_errors() -> void:
	for row in range(Board.ROWS):
		for col in range(Board.COLUMNS):
			if get_cell(row, col).invalid:
				get_cell(row, col).shake()
	for cells in _error_frames:
		for cell: Vector2i in cells:
			get_cell(cell.y, cell.x).shake()


# Starts the dotted box at `at`, in the grid's coordinates (which are
# `_overlay`'s too): called by the empty cell just pressed (see
# board_cell.gd's `_gui_input`).
func begin_box(at: Vector2) -> void:
	_box_from = at
	_box_to = at
	_boxing = true


# Stretches the box to `at`, while the press lasts.
func drag_box(at: Vector2) -> void:
	_box_to = at
	_overlay.queue_redraw()


# Ends the box: the tiles under it become the selection. A tap (the
# pointer barely moved) clears the selection instead.
func end_box(board: Board) -> void:
	_boxing = false
	selection.clear()
	# `abs()` turns a box drawn up or leftwards into one with a positive
	# size, which `intersects` needs.
	var box := Rect2(_box_from, _box_to - _box_from).abs()
	if _box_from.distance_to(_box_to) >= _BOX_THRESHOLD:
		for row in range(Board.ROWS):
			for col in range(Board.COLUMNS):
				if not board.is_empty(row, col) and box.intersects(_cell_rect(col, row, 1)):
					selection.append(Vector2i(col, row))
	_overlay.queue_redraw()


# Draws on `_overlay`: the red frames (see `refresh`), then the box being
# drawn, or the one round the selection.
func _draw_overlay() -> void:
	for cells in _error_frames:
		_frame(cells, _ERROR_COLOR, _ERROR_LINE_WIDTH)
	if _boxing:
		_dotted_rect(Rect2(_box_from, _box_to - _box_from).abs())
	elif not selection.is_empty():
		# The smallest box round every selected cell.
		var box := _cell_rect(selection[0].x, selection[0].y, 1)
		for cell in selection:
			box = box.merge(_cell_rect(cell.x, cell.y, 1))
		_dotted_rect(box.grow(_BOX_LINE_WIDTH))


# A frame round `cells` (side by side on one row), inside their edges.
# `draw_rect` with `filled` false draws only the border, centred on the
# rectangle's edge: shrunk by half the width to sit inside it.
func _frame(cells: Array, color: Color, width: float) -> void:
	var rect := _cell_rect(cells[0].x, cells[0].y, cells.size())
	_overlay.draw_rect(rect.grow(-width / 2.0), color, false, width)


# `rect`'s outline in dashes.
func _dotted_rect(rect: Rect2) -> void:
	var corners := [rect.position, Vector2(rect.end.x, rect.position.y), rect.end]
	corners.append(Vector2(rect.position.x, rect.end.y))
	for i in range(4):
		var to: Vector2 = corners[(i + 1) % 4]
		_overlay.draw_dashed_line(corners[i], to, _BOX_COLOR, _BOX_LINE_WIDTH, _BOX_DASH)


# The rectangle of `count` cells side by side from `(col, row)`, in the
# grid's (and `_overlay`'s) coordinates — see `row_rect`.
func _cell_rect(col: int, row: int, count: int) -> Rect2:
	var h_separation: int = _grid.get_theme_constant("h_separation")
	var rect := row_rect(row)
	rect.position.x = col * (_cell_side + h_separation)
	rect.size.x = count * _cell_side + (count - 1) * h_separation
	return rect


# Looks up the single cell at (row, col) — used by BoardCell itself (see
# board_cell.gd's `_get_drag_data`) to reach and hide the other selected
# cells being dragged, not just the one actually grabbed.
func get_cell(row: int, col: int) -> BoardCell:
	return _cell_panels[row][col]


# Forwards one cell's drop straight to this view's own single signal (see
# the header comment above `tile_dropped`'s declaration).
func _on_cell_tile_dropped(row: int, col: int, tile: Tile) -> void:
	tile_dropped.emit(row, col, tile)


# Same idea, for a tile moved from one board cell to another.
func _on_cell_tile_moved(from_row: int, from_col: int, to_row: int, to_col: int) -> void:
	tile_moved.emit(from_row, from_col, to_row, to_col)


# Same idea, for the selected tiles dragged together. The selection
# follows them, so the block can be nudged again.
func _on_cell_tiles_moved(cells: Array[Vector2i], offset: Vector2i) -> void:
	tiles_moved.emit(cells, offset)
	selection.clear()
	for cell in cells:
		selection.append(cell + offset)
	_overlay.queue_redraw()


# Same idea, for a cell clicked (not dragged) to flip its tile in place.
func _on_cell_tile_flipped(row: int, col: int) -> void:
	tile_flipped.emit(row, col)
