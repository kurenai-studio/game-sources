extends RefCounted
## The animated state of one tile while an effect plays: where it is, how big,
## how bright. Painters read it when they draw. A tile at rest uses the
## defaults set by reset(). One TileFx per cell is made once and reused, so
## effects allocate nothing per frame.
##
## Phase 1 prototype code. Nothing under tools/ ships with the game.

## Draw layers, lowest first. Moving tiles draw over resting ones, and the tile
## a merge lands on draws over the tiles travelling into it.
const LAYER_REST: int = 0
const LAYER_MOVING: int = 1
const LAYER_TOP: int = 2

## Offset from the cell position, in px.
var offset: Vector2 = Vector2.ZERO
## Scale around the pivot.
var scale: Vector2 = Vector2.ONE
## Scale pivot relative to the tile center, as a fraction of the tile side.
## (0, -0.5) is the middle of the top edge.
var pivot: Vector2 = Vector2.ZERO
## Rotation in radians around the tile center.
var rotation: float = 0.0
## Opacity of the whole tile.
var alpha: float = 1.0
## Glow amount, 1 at rest. Only Nova uses it.
var glow: float = 1.0
## Slate merge flash: the tile shows paper with a dark number.
var flash: bool = false
## Hidden tiles are not drawn at all.
var hidden: bool = false
var layer: int = LAYER_REST


func reset() -> void:
	offset = Vector2.ZERO
	scale = Vector2.ONE
	pivot = Vector2.ZERO
	rotation = 0.0
	alpha = 1.0
	glow = 1.0
	flash = false
	hidden = false
	layer = LAYER_REST
