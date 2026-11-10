# One droppable, draggable cell in BoardView's grid (see board_view.gd).
# Knows the Board only well enough to read it — the same read-only
# relationship BoardView itself has with Board, never mutating anything
# directly; `invalid` below is decided elsewhere (GameSession) and just
# handed to this cell by BoardView. Actually placing/moving a tile is main.gd's job: this
# cell just reports what happened via the signals below.
class_name BoardCell
extends Panel

# `signal` declares a named event this node can broadcast — Godot's way of
# saying "something happened" without the emitter needing to know who (if
# anyone) is listening, similar in spirit to a Qt signal if you've seen
# one, or a plain callback list in C++. BoardView connects to all three of
# these once per cell (see board_view.gd) and re-emits its own single
# signals, so main.gd only has to listen in one place instead of 117.
signal tile_dropped(row: int, col: int, tile: Tile)
signal tile_moved(from_row: int, from_col: int, to_row: int, to_col: int)
signal tiles_moved(cells: Array[Vector2i], offset: Vector2i)
signal tile_flipped(row: int, col: int)

# This cell's position in the board grid — set once by BoardView right
# after creating this node.
var row: int
var col: int

# The Board this cell belongs to — kept up to date by BoardView.refresh()
# so `_can_drop_data` below always checks legality against how the board
# looks *right now*, not just at creation time.
var board: Board

# Whether this cell is currently part of why the turn can't end yet — see
# GameSession.invalid_cells/invalid_words. Kept up to date by
# BoardView.refresh(), same as `board` above; free play has no
# such concept and always leaves this false.
var invalid: bool = false

# The tile's face: a Panel filling the hole (see TileView.face_rect),
# holding the letter and corner badge below. Handed over by BoardView at
# creation time like them; this cell itself draws the hole under it (see
# `_draw`).
var face: Panel

# This cell's own Label child, handed over once by BoardView right after
# creating it (see board_view.gd's `_build_grid`) — kept here, not just
# there, so this cell can redraw its own text/color itself (see `refresh`
# below).
var label: Label

# The small top-right badge showing what this tile's OTHER face is (see
# tile_view.gd's `build_corner_badge`/`update_corner_badge`) — also handed
# over by BoardView at creation time, same reasoning as `label` above.
var corner_badge: Panel

# The BoardView that owns this cell, also handed over at creation time —
# needed to read and change its selection (see board_view.gd), and so a
# block drag (see `_get_drag_data` below) can reach and hide every OTHER
# selected cell, not just this one (see board_view.gd's `get_cell`).
var board_view: BoardView

# Remembers where a left-click started, so `_gui_input` below can tell a
# plain click (releasing close to where it was pressed) from a drag that
# happened to end and release back over this same cell.
var _press_position: Vector2 = Vector2.ZERO
# Whether that press landed on a tile (a click flips it) or on an empty
# cell (a drag draws the selection box, see board_view.gd's `begin_box`).
var _pressed_on_tile := false

# The tile this cell showed at its last `refresh`, and whether it showed
# its front: what tells the next refresh a tile just landed here (it
# bounces) from the same tile just flipped (it turns over).
var _shown_tile: Tile
var _shown_front := true
# The face's running animations (see doc/ART_DIRECTION.md's "Motion"):
# its scale (bounce, turn over), and its position (hop, shake) — kept
# apart so a hop can run during a bounce.
var _scale_tween: Tween
var _move_tween: Tween


# A "virtual" function: Godot calls this itself (we never call it
# directly) once per frame while something is being dragged over this
# Control, to ask "would you accept a drop here?" Returning false is what
# shows the player a "no" cursor over illegal cells, and also stops
# `_drop_data` below from ever being called for this drop. `data` is
# whatever the drag started with (see `_get_drag_data` below and
# tile_panel.gd's own version) — a Dictionary shaped one of three ways,
# which is how a drop target tells them apart.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	if not data is Dictionary:
		return false
	if data.has("cells"):
		# The selected tiles, dragged by the one at `grab`: they all move
		# as far as it does, if they fit there (see block_move.gd).
		return BlockMove.can_move(board, data["cells"], Vector2i(col, row) - data["grab"])
	# One tile: anywhere but back where it came from. On another tile, the
	# two swap (see `_drop_data`).
	return not (data.has("from_row") and data["from_row"] == row and data["from_col"] == col)


# Virtual function Godot calls once, only if `_can_drop_data` just returned
# true and the player actually released the mouse here.
func _drop_data(_at_position: Vector2, data: Variant) -> void:
	if data.has("cells"):
		tiles_moved.emit(data["cells"], Vector2i(col, row) - data["grab"])
		return
	# On a tile, the session puts that one in the player's hand (see
	# GameSession.place_tile/move_tile), to play again from there.
	if data.has("from_row"):
		tile_moved.emit(data["from_row"], data["from_col"], row, col)
	else:
		tile_dropped.emit(row, col, data["tile"])


# Virtual function: Godot calls this the moment the player starts dragging
# this Control (see tile_panel.gd's own `_get_drag_data` for the general
# idea). Returning `null` — which happens whenever the cell is empty — is
# how a Control tells Godot "no drag starts here at all".
func _get_drag_data(_at_position: Vector2) -> Variant:
	var tile := board.tile_at(row, col)
	if tile == null:
		return null

	var here := Vector2i(col, row)
	if board_view.selection.size() > 1 and board_view.selection.has(here):
		# One of the selected tiles: they all go. Every selected cell hides
		# its tile while it's dragged (see below), and the preview shows
		# them all, in their places round the one grabbed.
		var cells := board_view.selection.duplicate()
		var tiles: Array[Tile] = []
		var offsets: Array[Vector2i] = []
		for cell in cells:
			tiles.append(board.tile_at(cell.y, cell.x))
			offsets.append(cell - here)
			board_view.get_cell(cell.y, cell.x).hide_tile()
		set_drag_preview(TileView.build_block_drag_preview(tiles, offsets, size))
		return {"cells": cells, "grab": here}

	# A tile on its own: any tile may move during a turn (see
	# GameSession.move_tile). Dragging one outside the selection drops it.
	board_view.selection.clear()
	# Hide this cell's own copy while it's being dragged, so there aren't
	# two of it on screen at once — one here, one following the cursor.
	# `refresh()` puts it back (see `_notification` below) once the drag
	# ends, whether or not it actually moved the tile away.
	hide_tile()
	set_drag_preview(TileView.build_drag_preview(tile, size))
	return {"tile": tile, "from_row": row, "from_col": col}


# Blanks this cell out, regardless of what's actually on the board there —
# used while its tile is off being dragged (see `_get_drag_data` above),
# when the board itself hasn't changed yet so `refresh()` below would just
# redraw the tile right back.
func hide_tile() -> void:
	face.visible = false


# Redraws this single cell from `board`'s current state — used by
# BoardView.refresh() for every cell (see board_view.gd), and by this cell
# itself once a drag that started here ends (see `_notification` below),
# to restore its look if the drag didn't actually carry its tile away. A
# tile that just landed here bounces; one just flipped turns over.
func refresh() -> void:
	var tile := board.tile_at(row, col)
	var landed := tile != null and tile != _shown_tile
	var flipped := tile != null and tile == _shown_tile and tile.is_showing_front() != _shown_front
	_shown_tile = tile
	_shown_front = tile.is_showing_front() if tile != null else true
	face.visible = tile != null
	if tile == null:
		return
	if flipped:
		_turn_over()
		return
	_show_tile()
	if landed:
		_bounce()


# Shows this cell's tile as it is now: its letter, its face, and its other
# face's letter in the corner.
func _show_tile() -> void:
	var tile := board.tile_at(row, col)
	if tile == null:
		return
	label.text = tile.current_letter()
	face.add_theme_stylebox_override("panel", TileView.board_face_style(tile, invalid))
	TileView.update_corner_badge(corner_badge, tile)


# A new scale animation of the face, replacing any still running, the
# face scaling around its centre (`pivot_offset`).
func _new_scale_tween() -> Tween:
	if _scale_tween != null:
		_scale_tween.kill()
	face.pivot_offset = face.size / 2
	_scale_tween = create_tween()
	return _scale_tween


# The "trampoline" bounce of a tile landing: it drops in from above (big,
# as if still held up), squashes a little too small on impact, and springs
# back (TRANS_BACK + EASE_OUT overshoots before settling). About 0.3 s:
# longer than the art direction's 250 ms, so it's seen on a phone.
func _bounce() -> void:
	face.scale = Vector2.ONE * 1.3
	var tween := _new_scale_tween()
	(
		tween
		. tween_property(face, "scale", Vector2.ONE * 0.88, 0.12)
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	tween.tween_property(face, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)


# A flipped tile turning over: it narrows to a sliver, shows its other
# face, and widens again — 120 ms in all.
func _turn_over() -> void:
	var tween := _new_scale_tween()
	tween.tween_property(face, "scale:x", 0.0, 0.06)
	tween.tween_callback(_show_tile)
	tween.tween_property(face, "scale:x", 1.0, 0.06)


# A new position animation of the face, replacing any still running and
# putting the face back in its place first (see TileView.face_rect).
func _new_move_tween() -> Tween:
	if _move_tween != null:
		_move_tween.kill()
	face.position = TileView.face_rect(size.x).position
	_move_tween = create_tween()
	return _move_tween


# The tile hops up and lands back, after `delay` seconds — a scored word's
# letters hop one after another (see board_view.gd's `hop`).
func hop(delay: float) -> void:
	if face.visible:
		var tween := _new_move_tween()
		var y := face.position.y
		tween.tween_interval(delay)
		tween.tween_property(face, "position:y", y - size.y * 0.3, 0.1).set_ease(Tween.EASE_OUT)
		tween.tween_property(face, "position:y", y, 0.12).set_trans(Tween.TRANS_BOUNCE).set_ease(
			Tween.EASE_OUT
		)


# The tile shakes sideways — a turn refused because of it (see
# board_view.gd's `shake_errors`).
func shake() -> void:
	if face.visible:
		var tween := _new_move_tween()
		var x := face.position.x
		for offset in [5.0, -5.0, 3.0, -2.0, 0.0]:
			tween.tween_property(face, "position:x", x + offset, 0.04)


# Godot calls this when this cell needs redrawing (like Qt's paintEvent);
# what it draws sits under the cell's children (the tile's face, which
# covers all but a thin gap of the hole when a tile is in it).
func _draw() -> void:
	TileView.draw_hole(self, Rect2(Vector2.ZERO, size))


# Virtual function: Godot calls this on EVERY Control (not just the one
# being dragged) whenever something relevant happens, `what` saying which
# kind of event. NOTIFICATION_DRAG_END fires once a drag ends, successful
# or not — a successful drop already gets this cell redrawn correctly via
# BoardView.refresh() (see main.gd's `_refresh_views`), so this only ever
# has real work to do when the drag was cancelled or dropped somewhere
# illegal, putting this cell's hidden tile back.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		refresh()


# Virtual function: Godot calls this for mouse/keyboard events over this
# Control that the drag-and-drop system above doesn't already claim.
#   - A plain click on a tile — releasing close to where it was pressed —
#     flips it in place (doc/RULES.md's "trampoline" mechanic).
#   - A press on an empty cell draws the selection box while the pointer
#     moves, and selects the tiles under it on release; a tap there clears
#     the selection (see board_view.gd's `begin_box`). The events are
#     "accepted" (`accept_event`), so the page doesn't scroll meanwhile.
# Godot keeps sending a pressed pointer's events to the Control it was
# pressed on, even once it's moved off it, like a mouse grab.
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_position = event.position
			_pressed_on_tile = board.tile_at(row, col) != null
			if not _pressed_on_tile:
				# `position` is this cell's place in the grid; the event's,
				# the pointer's place in this cell.
				board_view.begin_box(position + event.position)
				accept_event()
		elif not _pressed_on_tile:
			board_view.end_box(board)
			accept_event()
		elif board.tile_at(row, col) != null and event.position.distance_to(_press_position) < 6:
			tile_flipped.emit(row, col)
	elif event is InputEventMouseMotion and not _pressed_on_tile and event.button_mask != 0:
		board_view.drag_box(position + event.position)
		accept_event()
