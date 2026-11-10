# The "À rendre" tray beside the hand in turn-based play: a small sunken
# slot the player drags tiles into to give them back to the bag when
# their turn ends, and draw others instead (see game_session.gd's
# `set_marked_for_discard`). Dragging a tile back out to the hand (see
# hand_row.gd) changes their mind; dragging it onto the board just plays
# it.
#
# Two (slightly smaller) tiles wide and two rows tall, matching the
# hand's own two rows; past four tiles it scrolls sideways rather than
# growing, so it never takes more room on the phone screen.
#
# Purely visual, like HandView: it only shows the tiles it's given and
# reports drops through `tile_marked` — main.gd asks GameSession to mark
# them.
class_name DiscardTray
extends PanelContainer

# A tile from the hand was dropped into the tray.
signal tile_marked(tile: Tile)

# How big a tile in the tray is, relative to one in the hand — smaller,
# so two rows of them plus the tray's own sideways scrollbar fit in the
# height of the hand's two rows, and two fit side by side without
# squeezing the hand.
const _TILE_SCALE := 0.72

@onready var _scroll: ScrollContainer = $Scroll
@onready var _tiles: GridContainer = $Scroll/Tiles
# "À rendre", shown only while the tray is empty, saying what it's for.
@onready var _hint: Label = $Hint


# Redraws the tray with `tiles` (the marked ones, in the order marked),
# sized from the hand's own tile size `hand_tile_side`.
func refresh(tiles: Array[Tile], hand_tile_side: float) -> void:
	for child in _tiles.get_children():
		child.queue_free()
	var side := roundf(hand_tile_side * _TILE_SCALE)
	# A GridContainer fills row by row: half the tiles per row (rounded
	# up) keeps them on exactly two rows, growing sideways.
	_tiles.columns = maxi(1, ceili(tiles.size() / 2.0))
	for tile in tiles:
		var panel := TilePanel.create(tile, side)
		panel.in_tray = true
		_tiles.add_child(panel)
	# The visible window: two tray tiles wide, and the tray exactly as
	# tall as the hand's two rows (its tiles and its 4 px gap, see
	# hand_view.tscn) — minus the tray's own top/bottom margins — so it
	# never makes the page taller.
	var gap: int = _tiles.get_theme_constant("h_separation")
	var style := get_theme_stylebox("panel")
	var margins := style.content_margin_top + style.content_margin_bottom
	_scroll.custom_minimum_size = Vector2(2 * side + gap, 2 * hand_tile_side + 4 - margins)
	_hint.visible = tiles.is_empty()


# Accepts a tile dragged from the hand — not one from the board (those
# carry "from_row", see board_cell.gd: put it back in the hand first) nor
# one already in the tray (see tile_panel.gd's "from_tray").
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		data is Dictionary
		and data.has("tile")
		and not data.has("from_row")
		and not data.has("from_tray")
	)


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	tile_marked.emit(data["tile"])
