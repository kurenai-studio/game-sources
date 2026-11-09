extends Node2D
## Endless cave floor. Only the tiles around the camera are drawn.
## Each cell picks its tile from a hash of its coordinates, so the floor
## looks varied but stays the same when you walk back. Tiles are regions
## of the Ninja Adventure floor tileset (brown earth).

const TILE_SIZE := 16.0
const TILESET := preload("res://assets/ninja/tiles/floor.png")
const PLAIN_TILE := Rect2(192, 240, 16, 16)
## Plain earth with slightly different grain; most cells use one of these.
const VARIANT_TILES: Array[Rect2] = [
	Rect2(272, 240, 16, 16),
	Rect2(320, 256, 16, 16),
	Rect2(336, 256, 16, 16),
	Rect2(320, 272, 16, 16),
	Rect2(336, 272, 16, 16),
]
## Pebbles and cracks, sprinkled rarely.
const DETAIL_TILES: Array[Rect2] = [
	Rect2(256, 256, 16, 16),
	Rect2(272, 256, 16, 16),
]
## Roughly one in this many cells gets a variant, and one in
## DETAIL_ONE_IN a detail.
const VARIANT_ONE_IN := 7
const DETAIL_ONE_IN := 23
## Darkens the floor so characters and enemies stand out.
const FLOOR_TINT := Color(0.62, 0.6, 0.66)


func _process(_delta: float) -> void:
	queue_redraw()


func _draw() -> void:
	var camera := get_viewport().get_camera_2d()
	var center := camera.get_screen_center_position() if camera else Vector2.ZERO
	var half := get_viewport_rect().size * 0.5 + Vector2.ONE * TILE_SIZE
	var first := ((center - half) / TILE_SIZE).floor()
	var last := ((center + half) / TILE_SIZE).ceil()
	for cell_y in range(int(first.y), int(last.y)):
		for cell_x in range(int(first.x), int(last.x)):
			var at := Rect2(Vector2(cell_x, cell_y) * TILE_SIZE, Vector2.ONE * TILE_SIZE)
			draw_texture_rect_region(TILESET, at, _tile_for(cell_x, cell_y), FLOOR_TINT)


## Integer hash with good spread for neighbouring cells.
static func cell_hash(cell_x: int, cell_y: int) -> int:
	var h := (cell_x * 73856093) ^ (cell_y * 19349663)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	return absi(h)


## Region of [constant TILESET] for this cell.
func _tile_for(cell_x: int, cell_y: int) -> Rect2:
	var hash_value := cell_hash(cell_x, cell_y)
	if hash_value % DETAIL_ONE_IN == 0:
		return DETAIL_TILES[(hash_value / DETAIL_ONE_IN) % DETAIL_TILES.size()]
	if hash_value % VARIANT_ONE_IN == 0:
		return VARIANT_TILES[(hash_value / VARIANT_ONE_IN) % VARIANT_TILES.size()]
	return PLAIN_TILE
