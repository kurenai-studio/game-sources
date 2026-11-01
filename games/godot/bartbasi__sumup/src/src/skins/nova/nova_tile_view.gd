extends "res://src/skins/common/common_tile_view.gd"
## One Nova orb on its own, with its glow, as on the board
## (DESIGN_SYSTEM.md 6.7). The orb diameter is min(size.x, size.y); the glow
## reaches outside the rect.

const NovaTilePainter: GDScript = preload("res://src/skins/nova/nova_tile_painter.gd")


func _make_painter() -> TilePainter:
	return NovaTilePainter.new() as TilePainter
