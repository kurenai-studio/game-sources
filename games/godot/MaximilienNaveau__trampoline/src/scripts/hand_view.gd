# Visualizes a collection of colored tiles, using the same yellow/green/
# blank coloring as BoardView (via TileView). Each tile is a TilePanel (see
# tile_panel.gd), draggable onto a BoardView cell — this view itself
# doesn't need to know that's possible, it just builds them. The row
# itself (see hand_row.gd) accepts a tile dragged back FROM the board,
# re-broadcast here as `tile_returned` the same way BoardView re-broadcasts
# its own cells' signals.
#
# Instanced twice: as one player's turn-based hand (hand_view.tscn, an
# HFlowContainer that wraps onto more rows rather than ever cropping a
# full hand), and as the free-play palette of every currently-unplaced
# tile (scenes/palette_view.tscn, a GridContainer whose own column count
# `_update_palette_columns` below keeps refitted to the page's full width,
# tall enough that main.tscn's own page-level scrolling is what reveals
# the rest, rather than a second, nested scrollbar of its own) — this
# script itself doesn't care which, since `refresh()` only ever deals in a
# plain list of tiles (see hand_row.gd's own comment for why the SAME
# `Row` script backs both container shapes).
#
# Unlike BoardView's grid (13x9, always the same 117 cells), the tiles
# shown here change turn to turn — tiles leave when placed, more arrive on
# a draw (or, in free play, whenever anything moves on/off the board) — so
# there's no fixed pool of nodes to reuse here. `refresh()` just throws
# away the previous tile nodes and builds fresh ones matching whatever's
# passed in; even the free-play palette's worst case (117 tiles) is cheap
# enough to rebuild from scratch every refresh, so this needs no pooling.
class_name HandView
extends Control

signal tile_returned(from_row: int, from_col: int)
# A tile dragged back out of the discard tray into this hand (see
# discard_tray.gd): the player no longer wants to give it back.
signal tile_unmarked(tile: Tile)
# A hand tile dropped elsewhere in the hand (see hand_row.gd).
signal tile_reordered(tile: Tile, before: Tile)

# The palette's tiles a line, set by play_area.gd beside the board so they
# fill its mat (0, stacked: as many as fit across the page).
# A property with a `set` function, called on every assignment (like a
# Python @property setter): it re-fits the palette straight away.
var fixed_columns := 0:
	set(value):
		fixed_columns = value
		if _tile_side > 0.0 and "columns" in _row:
			_update_palette_columns(_tile_side)
# The tile size of the last `refresh`, for re-fitting when `fixed_columns`
# changes.
var _tile_side := 0.0

# `$Row` looks up the child node named "Row" declared in hand_view.tscn,
# same `@onready`/`$Name` pattern as BoardView's `_grid`.
@onready var _row: HandRow = $Row


func _ready() -> void:
	_row.tile_returned.connect(_on_row_tile_returned)
	# A signal can be connected straight to another signal's `emit`,
	# re-broadcasting it unchanged.
	_row.tile_unmarked.connect(tile_unmarked.emit)
	_row.tile_reordered.connect(tile_reordered.emit)


func _on_row_tile_returned(from_row: int, from_col: int) -> void:
	tile_returned.emit(from_row, from_col)


# Redraws the whole row from `hand`'s current tiles, left to right, each
# `tile_side` pixels square — matching BoardView's own current cell size
# (see board_view.gd's `cell_side()`) rather than a fixed guess, so a tile
# looks the same size whether it's in a hand/palette or already on the
# board.
func refresh(hand: Array[Tile], tile_side: float) -> void:
	# `queue_free()` marks a node for deletion at the end of this frame,
	# rather than destroying it immediately (Godot's usual way to remove a
	# node safely) — `free()` would work too here since none of these
	# panels are still being interacted with mid-signal, but queue_free is
	# the standard habit throughout Godot code.
	for child in _row.get_children():
		child.queue_free()

	# Only the free-play palette's Row is a GridContainer (see this file's
	# own header comment) — the turn-based hand's HFlowContainer already
	# wraps automatically at whatever width it's given, no column count to
	# manage. `_row` is statically typed as HandRow (its script), which
	# GDScript's compiler won't let an `as GridContainer` cast target —
	# HandRow and GridContainer are unrelated branches from its point of
	# view, even though the actual node underneath genuinely is one in the
	# palette's case — so this checks/sets `columns` dynamically instead.
	_tile_side = tile_side
	if "columns" in _row:
		_update_palette_columns(tile_side)

	for tile in hand:
		_row.add_child(TilePanel.create(tile, tile_side))


# Fits as many `tile_side`-wide tiles as possible across the palette's own
# available width, instead of a fixed 4 columns that leaves the rest of a
# wide screen empty — mirrors board_view.gd's own `_update_cell_sizes`
# math, reusing its `PAGE_MARGIN` constant rather than a second copy of the
# same page margin that could quietly drift out of sync with it. In
# landscape, the palette sits beside the board rather than below it (see
# main.gd's `PlayArea.vertical`), so it only gets whatever width the board
# ISN'T claiming — the complement of `BoardView.LANDSCAPE_BOARD_WIDTH_
# FRACTION`, not the full viewport width.
func _update_palette_columns(tile_side: float) -> void:
	var separation: int = _row.get_theme_constant("h_separation")
	var viewport_size := get_viewport_rect().size
	var content_width := viewport_size.x - BoardView.PAGE_MARGIN
	if viewport_size.x > viewport_size.y:
		content_width *= 1.0 - BoardView.LANDSCAPE_BOARD_WIDTH_FRACTION
	var columns := int(floor((content_width + separation) / (tile_side + separation)))
	if fixed_columns > 0:
		columns = fixed_columns
	# `.set()` — a plain Object method, valid on any type — reaches
	# `columns` dynamically, the same reasoning as the `in` check above.
	_row.set("columns", max(1, columns))
