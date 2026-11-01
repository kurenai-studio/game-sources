extends RefCounted
## The animated look of one tile while effects play: where it is, how big,
## how bright. The board turns it into the tile item's transform and
## modulate, and passes flash and glow to the painter. A tile at rest has the
## values reset() sets. The board keeps one per cell and one per ghost tile, made
## once and reused, so effects allocate nothing per frame.
##
## Effects combine: the board resets every TileFx at the start of a frame,
## then each running effect multiplies or adds its part.

## Draw layers, lowest first. Moving tiles draw over resting ones, and the
## tile a merge lands on draws over the tiles travelling into it.
const LAYER_REST: int = 0
const LAYER_MOVING: int = 1
const LAYER_TOP: int = 2

## Offset from the cell center, in px.
var offset: Vector2 = Vector2.ZERO
## Scale around the pivot.
var scale: Vector2 = Vector2.ONE
## Scale pivot relative to the tile center, as a share of the tile side.
## (0, -0.5) is the middle of the top edge.
var pivot: Vector2 = Vector2.ZERO
## Rotation in radians around the pivot.
var rotation: float = 0.0
## Opacity of the whole tile.
var alpha: float = 1.0
## Glow amount, 1 at rest. Only Nova draws a glow.
var glow: float = 1.0
## Slate's merge flash: the tile shows paper with a dark number.
var flash: bool = false
## Hidden tiles are not drawn at all.
var hidden: bool = false
## A new tile still growing in. It draws under every other tile, so it seems
## to appear from behind a tile falling away from its cell.
var spawning: bool = false
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
	spawning = false
	layer = LAYER_REST


## True when the tile is at rest on its cell with its plain look.
func is_rest() -> bool:
	return offset == Vector2.ZERO and scale == Vector2.ONE and rotation == 0.0 \
			and alpha == 1.0 and glow == 1.0 and not flash and not hidden and not spawning and layer == LAYER_REST


## True when a scale this small would make the draw transform singular.
func is_collapsed() -> bool:
	return absf(scale.x) < 0.001 or absf(scale.y) < 0.001


func raise_layer(new_layer: int) -> void:
	layer = maxi(layer, new_layer)
