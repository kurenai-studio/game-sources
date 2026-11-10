class_name LaneLayout
extends RefCounted
## Where each piece stands once `LanePlacer` has placed them: a piece's key to the first space it
## takes. Read-only for the view, the villagers and the tests; hover, the click region and the
## sites all take a piece's position from here, so there is one projection.

## Piece key -> first space index (`LanePieces.key_of`). A shown piece with no entry is hidden.
var starts: Dictionary = {}


func is_placed(key: StringName) -> bool:
	return starts.has(key)


## Whether the view draws a piece: backdrop always (the world decides), the rest only in a space.
func is_drawn(id: StringName) -> bool:
	return not LanePieces.has(id) or starts.has(LanePieces.key_of(id))


## The camp x of the left edge of a piece's spaces.
func span_left(key: StringName) -> float:
	return float(LaneSpaces.left(LanePieces.lane_of(key), int(starts[key])))


func span_width(key: StringName) -> float:
	return float(LaneSpaces.span_px(LanePieces.spaces_of(key)))


## The camp x of the middle of a piece's spaces, or `fallback` if it is not in any.
func center_x(key: StringName, fallback: float = NAN) -> float:
	if not starts.has(key):
		return fallback
	return span_left(key) + span_width(key) / 2.0


## The x to give a sprite so that its art (`art`, the drawn pixels inside the sprite) stands in the
## middle of the piece's spaces, on whole pixels; a piece that is joined to the shore
## (`LanePieces.is_anchored`) has its landward end at the left edge of its spaces instead, so it
## still touches the bank.
func sprite_x(key: StringName, art: Rect2i) -> float:
	var left: float = span_left(key)
	if not LanePieces.is_anchored(key):
		left += floorf((span_width(key) - float(art.size.x)) / 2.0)
	return left - float(art.position.x)


## How far a piece's art has moved from where `home` (the x its sprite would stand at with no
## spaces) put it: what to add to a spot or a light that was written down for the home position.
func shift(key: StringName, art: Rect2i, home: float) -> float:
	return sprite_x(key, art) - home
