# The actual drop target for returning a tile from the board back to
# wherever HandView's tiles came from (see hand_view.gd/board_cell.gd for
# the rest of the drag-and-drop mechanics) — the current player's hand in
# turn-based play, or the free-play palette (see scenes/palette_view.tscn)
# in free play. This lives on the Row container itself, rather than on
# HandView's own root Control, because a Container's rect grows to fit its
# children — exactly the area the tiles are visible in — while HandView's
# root Control has no size of its own to speak of.
#
# `extends Container` rather than a specific box/grid layout: the drop
# logic below cares nothing about HOW the tiles are arranged, only about
# accepting a tile dragged off the board, so the identical script backs
# both an HFlowContainer (the turn-based hand, wrapping onto more rows
# rather than cropping a full hand) and a GridContainer (the free-play
# palette, which needs to wrap 117 tiles across many rows).
class_name HandRow
extends Container

signal tile_returned(from_row: int, from_col: int)
signal tile_unmarked(tile: Tile)
# A tile of this row dropped elsewhere in it, just before `before` (null:
# after the last one) — the player arranging their hand.
signal tile_reordered(tile: Tile, before: Tile)


# Accepts drops that came from a BoardCell (see board_cell.gd's
# `_get_drag_data`, the only source that adds "from_row" to the dragged
# data), or from the discard tray (see tile_panel.gd, which adds
# "from_tray"), or from this row itself (its drag carries nothing but the
# tile, see tile_panel.gd), to move it.
func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return (
		data is Dictionary
		and (data.has("from_row") or data.has("from_tray") or data.keys() == ["tile"])
	)


func _drop_data(at_position: Vector2, data: Variant) -> void:
	if data.has("from_tray"):
		tile_unmarked.emit(data["tile"])
	elif data.has("from_row"):
		tile_returned.emit(data["from_row"], data["from_col"])
	else:
		tile_reordered.emit(data["tile"], _tile_after(at_position))


# The tile a drop at `at_position` lands just before: the first one, in
# reading order, lying on a later row, or on the same row but further
# right than the drop (past its middle) — null if the drop is after them
# all. Each child is a TilePanel (see tile_panel.gd); its `position` is
# where it sits in this row.
func _tile_after(at_position: Vector2) -> Tile:
	for panel: TilePanel in get_children():
		var below := at_position.y < panel.position.y
		var on_row := at_position.y < panel.position.y + panel.size.y
		if below or (on_row and at_position.x < panel.position.x + panel.size.x / 2):
			return panel.tile
	return null
