class_name BoardGeometry extends RefCounted
## Hit test math for the board (docs/ARCHITECTURE.md section 8, GDD D-07,
## test hook TH19). Pure functions, no allocation, so the drag path can call
## them on every pointer event.
##
## A cell is Vector2i(column, row). grid_origin is the top left corner of
## cell (0, 0)'s pitch box, and pitch is the distance between neighboring
## cell centers, both in the same pixels as the point.

const NO_CELL: Vector2i = Vector2i(-1, -1)
const HALF_CELL: Vector2 = Vector2(0.5, 0.5)


## TH19, D-07. The cell whose center is within join_radius * min(pitch.x,
## pitch.y) of point, else (-1, -1). The edge of the circle counts as inside.
## When the radius is large enough for two circles to overlap, the nearest
## center wins.
static func cell_at(point: Vector2, grid_origin: Vector2, pitch: Vector2, columns: int, rows: int, join_radius: float) -> Vector2i:
	if columns < 1 or rows < 1 or not (pitch.x > 0.0 and pitch.y > 0.0) or not (join_radius > 0.0):
		return NO_CELL
	if not point.is_finite() or not grid_origin.is_finite() or not pitch.is_finite():
		return NO_CELL
	var local: Vector2 = (point - grid_origin) / pitch
	# The nearest center on each axis is the pitch box the point falls in,
	# held to the board, because centers sit at whole cells plus a half.
	var column: int = clampi(floori(local.x), 0, columns - 1)
	var row: int = clampi(floori(local.y), 0, rows - 1)
	var cell: Vector2i = Vector2i(column, row)
	var radius: float = join_radius * minf(pitch.x, pitch.y)
	if point.distance_squared_to(cell_center(cell, grid_origin, pitch)) <= radius * radius:
		return cell
	return NO_CELL


## The center of a cell in the same pixels as grid_origin.
static func cell_center(cell: Vector2i, grid_origin: Vector2, pitch: Vector2) -> Vector2:
	return grid_origin + (Vector2(cell) + HALF_CELL) * pitch
