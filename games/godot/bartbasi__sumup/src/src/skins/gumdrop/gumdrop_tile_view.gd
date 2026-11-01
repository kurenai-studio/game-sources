extends "res://src/skins/common/common_tile_view.gd"
## One Gumdrop tile on its own: a squircle candy tile with its lip, shine and
## candy rim as on the board (DESIGN_SYSTEM.md 4.7).

const GumdropTilePainter: GDScript = preload("res://src/skins/gumdrop/gumdrop_tile_painter.gd")


func _make_painter() -> TilePainter:
	return GumdropTilePainter.new() as TilePainter
