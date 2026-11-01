extends RefCounted
## One running board effect. Effects on a cell change that cell's TileFx.
## Ghost effects draw a tile that is no longer in any cell: a chain tile
## travelling into the merge, a tile clearing, a tile leaving in a Shuffle or
## Undo. Decor effects are tails that never block input and outlive
## set_board(): Gumdrop's candy burst and Nova's glow bloom.
##
## Positions are in cell units, (0, 0) at the top left corner of cell
## (0, 0)'s pitch box, so they survive a layout change.

const TileFx: GDScript = preload("res://src/skins/common/tile_fx.gd")

# Effects on a cell's tile.
const SPAWN: int = 0
const POP: int = 1
const FALL: int = 2
const SLIDE: int = 3
## Hides the cell's tile, for example the merge result until it lands.
const HIDE: int = 4
# Ghost tiles.
const TRAVEL: int = 10
## The last chain tile, waiting in place for the others to arrive.
const HOLD: int = 11
const CLEAR: int = 12
const DEPART: int = 13
# Decor tails.
const BLOOM: int = 20
const BURST: int = 21

var kind: int = SPAWN
## Clock time the effect starts, and its length in seconds.
var start: float = 0.0
var length: float = 0.0
## Cell index for effects on a cell, else -1.
var index: int = -1
## The tile value a ghost or decor effect shows.
var value: int = 0
## Ghost and decor: the tile center in cell units.
var origin: Vector2 = Vector2.ZERO
## FALL and SLIDE: where the tile starts, relative to its cell, in cell
## units. Straight TRAVEL: where the ghost ends, in cell units.
var offset: Vector2 = Vector2.ZERO
## TRAVEL along the chain path: start and end distance along it, in cell units.
var path_from: float = 0.0
var path_to: float = 0.0
## Ghosts: how far the chained look shows, 0 to 1.
var chain: float = 0.0
## Ghosts: the animated look.
var fx: TileFx = null


func is_ghost() -> bool:
	return kind >= TRAVEL and kind < BLOOM


func is_decor() -> bool:
	return kind >= BLOOM


func on_cell() -> bool:
	return kind < TRAVEL or kind == BLOOM


## Linear progress at a clock time: below 0 before the start, 1 at the end.
func progress_at(clock: float) -> float:
	if length <= 0.0:
		return 1.0 if clock >= start else -1.0
	return (clock - start) / length
