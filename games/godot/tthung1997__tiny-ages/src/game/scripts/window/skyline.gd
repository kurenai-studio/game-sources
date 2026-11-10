class_name Skyline
extends RefCounted
## The top edge of everything drawn, one number per column: the highest opaque pixel. The
## click-through region of the desktop strip is built from it (everything at or below the
## skyline is clickable). Works over a world wider than the screen: add each piece at its
## column and read back the slice that is in view.

const ALPHA_CLICKABLE: float = 0.5

## Per-texture column tops, so rebuilding after a building appears does not re-read pixels.
static var _cache: Dictionary = {}

var width: int
var height: int
## For each world column, the y of its highest opaque pixel, or `height` if there is none.
var tops: PackedInt32Array = PackedInt32Array()


func _init(p_width: int, p_height: int) -> void:
	width = p_width
	height = p_height
	tops.resize(width)
	tops.fill(height)


## Adds a texture whose left edge sits at world column `x`, optionally mirrored, and whose top edge
## sits `y` rows down (negative is up: a piece lifted onto a back lane). Columns outside the
## skyline are ignored.
func add(texture: Texture2D, x: int, flipped: bool = false, y: int = 0) -> void:
	if texture == null:
		return
	var columns: PackedInt32Array = column_tops(texture, height)
	var count: int = columns.size()
	for source: int in count:
		var column: int = x + (count - 1 - source if flipped else source)
		if column >= 0 and column < width and columns[source] < height:
			tops[column] = mini(tops[column], clampi(columns[source] + y, 0, height))


## `count` columns starting at `start`, clamped to the skyline's edges.
func slice(start: int, count: int) -> PackedInt32Array:
	var result: PackedInt32Array = PackedInt32Array()
	result.resize(count)
	for index: int in count:
		result[index] = tops[clampi(start + index, 0, width - 1)]
	return result


static func column_tops(texture: Texture2D, height: int) -> PackedInt32Array:
	# Only imported textures (which have a path) are cached; temporary ones are recomputed.
	var key: String = "%s@%d" % [texture.resource_path, height]
	var cacheable: bool = not texture.resource_path.is_empty()
	if cacheable and _cache.has(key):
		return _cache[key]
	var columns: PackedInt32Array = PackedInt32Array()
	var image: Image = texture.get_image()
	if image == null:
		push_warning("Skyline: a texture has no image data; ignoring it.")
		return columns
	columns.resize(image.get_width())
	columns.fill(height)
	var rows: int = mini(image.get_height(), height)
	for x: int in image.get_width():
		for y: int in rows:
			if image.get_pixel(x, y).a > ALPHA_CLICKABLE:
				columns[x] = y
				break
	if cacheable:
		_cache[key] = columns
	return columns
