# One draggable tile in a HandView row (see hand_view.gd), or in the
# discard tray beside it (see discard_tray.gd). Knows nothing about
# GameSession/turns/scoring — it only carries a reference to the `Tile` it
# displays, and implements Godot's drag-and-drop hook so a player can pick
# it up and drop it onto a BoardCell (see board_cell.gd), the tray, or
# back into the hand.
class_name TilePanel
extends Panel

# The tile this panel represents — set once by `create()` below.
var tile: Tile

# Whether this panel sits in the discard tray rather than the hand. Only
# changes what a drag carries along (see `_get_drag_data`), so the hand
# can tell a tile coming back out of the tray from anything else.
var in_tray := false

# This panel's own main Label and corner badge, set once by `create()`
# (see tile_view.gd's `build_corner_badge`/`update_corner_badge`) — kept
# here so `refresh()` below can redraw them in place after a flip, without
# rebuilding this whole panel from scratch.
var label: Label
var corner_badge: Panel

# Remembers where a left-click started, so `_gui_input` below can tell a
# plain click (releasing close to where it was pressed) from a drag that
# happened to end and release back over this same tile.
var _press_position: Vector2 = Vector2.ZERO


# Builds a ready-to-show panel for `tile`, `side` pixels square — shared
# by HandView and DiscardTray so a tile looks the same in both. A
# `static func` is called on the class itself (`TilePanel.create(...)`),
# like a C++ static factory function.
static func create(a_tile: Tile, side: float) -> TilePanel:
	var panel := TilePanel.new()
	panel.tile = a_tile
	# Every Control can pick its own mouse cursor shape for whenever the
	# pointer is hovering over it — a hint that this tile can be picked
	# up, shown before the player even starts dragging. CURSOR_DRAG would
	# be the conceptually closest match, but on this system (X11) Godot
	# maps it to the 4-way "move" cross, not a hand; the actual
	# hand-shaped cursor Godot ships is CURSOR_POINTING_HAND.
	panel.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	# A Control's default MOUSE_FILTER_STOP means it swallows mouse events
	# entirely, including a drag-and-drop drop — since a TilePanel doesn't
	# handle drops itself, an unhandled drop landing on one (rather than
	# the gap between tiles) would otherwise never reach the container
	# behind it, the actual drop target (see hand_row.gd/discard_tray.gd).
	# PASS lets a TilePanel still handle its OWN events (starting a drag
	# out of it still works) while letting anything it doesn't handle
	# continue on to its parent.
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.custom_minimum_size = Vector2(side, side)
	panel.add_theme_stylebox_override("panel", TileView.style_for_tile(a_tile))

	var a_label := TileView.build_letter_label()
	a_label.text = a_tile.current_letter()
	panel.add_child(a_label)
	panel.label = a_label

	# The small "other face" hint badge (see tile_view.gd's
	# build_corner_badge/update_corner_badge) — lets a player see what
	# flipping this tile would reveal before they commit to it.
	var badge := TileView.build_corner_badge()
	TileView.update_corner_badge(badge, a_tile)
	panel.add_child(badge)
	panel.corner_badge = badge
	# Same letter/corner proportions as on the board, at this size.
	TileView.fit_to_side(a_label, badge, side)
	# Off the board, a tile shows its cork base (see tile_view.gd).
	TileView.add_cork(panel, side)
	return panel


# Virtual function: Godot calls this itself the moment the player starts
# dragging this Control with the mouse (see board_cell.gd's header comment
# for what "virtual function" means here). Its return value becomes the
# payload every drop target receives in `_can_drop_data`/`_drop_data` — a
# plain Dictionary is the simplest way to carry the dragged Tile along.
func _get_drag_data(_at_position: Vector2) -> Variant:
	# Shows a copy of this tile following the cursor while it's dragged, so
	# the player can see what they're holding. Godot destroys this preview
	# automatically once the drag ends — we never free it ourselves. See
	# TileView.build_drag_preview for why it needs its own wrapper Control
	# to stay centered on the cursor (BoardCell's own drag source, for
	# moving a tile already on the board, reuses the exact same helper).
	set_drag_preview(TileView.build_drag_preview(tile, size))

	# Fades this panel out while it's being dragged, so it doesn't look
	# like there are two of this tile at once (one here, one following the
	# cursor). `modulate` tints/fades a Control without resizing it (unlike
	# `visible = false`, which would also pull it out of HBoxContainer's
	# layout and make the rest of the hand jump sideways to fill the gap).
	# `_notification` below fades it back in once the drag ends — if it
	# actually got placed, HandView.refresh() will have already queued this
	# whole panel for deletion anyway, making this a harmless no-op.
	modulate = Color(1, 1, 1, 0)

	if in_tray:
		return {"tile": tile, "from_tray": true}
	return {"tile": tile}


# See board_cell.gd's own `_notification` for what NOTIFICATION_DRAG_END
# means and why every Control receives it once a drag ends, successful or
# not.
func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END:
		modulate = Color(1, 1, 1, 1)


# Redraws this tile's own text/color and other-face hint from `tile`'s
# current state — needed after a flip (see `_gui_input` below). Unlike a
# board tile, flipping a tile still in hand has no game-rule consequence
# at all (see game_session.gd's `flip_tile`, which only ever touches board
# tiles) — it's just choosing which face to place, so this panel handles
# it entirely on its own, no signal to main.gd needed.
func refresh() -> void:
	label.text = tile.current_letter()
	add_theme_stylebox_override("panel", TileView.style_for_tile(tile))
	TileView.update_corner_badge(corner_badge, tile)


# Virtual function: Godot calls this for mouse/keyboard events over this
# Control that the drag-and-drop system above doesn't already claim (see
# board_cell.gd's own version for the fuller explanation of the click-vs-
# drag distinction this makes).
func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_press_position = event.position
		elif event.position.distance_to(_press_position) < 6:
			tile.flip()
			refresh()
