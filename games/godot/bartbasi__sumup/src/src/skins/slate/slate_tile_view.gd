extends "res://src/skins/common/common_tile_view.gd"
## One Slate tile on its own: a flat tile with the number top left, as on
## the board (DESIGN_SYSTEM.md 5.7).

const SlateTilePainter: GDScript = preload("res://src/skins/slate/slate_tile_painter.gd")


func _make_painter() -> TilePainter:
	return SlateTilePainter.new() as TilePainter
