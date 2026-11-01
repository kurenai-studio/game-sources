class_name BoardProjection
extends RefCounted
## Maps board points (x east, y south, z up, in cell units) to screen points for the 2.5D board: a
## fixed camera tilted by `pitch` degrees with a little perspective, fitted into a box. Pure, so it
## can be tested. The camera depends on the board size: steeper and flatter as the board grows, so a
## big board stays readable (docs/README_3D_VIEW_PLAN.md, section 2).

const Z_PLATE := -0.4
const Z_FLOOR := 0.12
const Z_GOAL := 0.24
const Z_WALL := 0.62
const Z_AUTOMATON := 0.5
## The highest point of any piece, used to fit the board in its box.
const Z_TOP := 0.72
const PLATE_MARGIN := 0.3
const FIT_MARGIN := 4.0
## How far in front of the board's center the camera stands, in cells.
const CAMERA_DISTANCE := 1.4

var cols: int
var rows: int
var pitch: float
var perspective: float
var cell_scale := 1.0
var _sin_pitch: float
var _cos_pitch: float
var _bounds_center := Vector2.ZERO
var _box := Vector2.ZERO
var _camera := Vector2.ZERO


## The camera for a board of this size: about 62 degrees with perspective up to 6 cells, easing to
## about 80 degrees with almost none by 12 cells.
static func camera_for(board_cols: int, board_rows: int) -> Dictionary:
	var t := clampf((maxi(board_cols, board_rows) - 6) / 6.0, 0.0, 1.0)
	return {"pitch": 62.0 + 18.0 * t, "perspective": 0.06 - 0.04 * t}


func _init(board_cols: int, board_rows: int, box: Vector2) -> void:
	cols = board_cols
	rows = board_rows
	var camera := camera_for(cols, rows)
	pitch = camera["pitch"]
	perspective = camera["perspective"]
	_sin_pitch = sin(deg_to_rad(pitch))
	_cos_pitch = cos(deg_to_rad(pitch))
	_camera = Vector2(0.0, rows * 0.5 + CAMERA_DISTANCE)
	_box = box
	var low := Vector2(INF, INF)
	var high := Vector2(-INF, -INF)
	for corner in [
		Vector2(-PLATE_MARGIN, -PLATE_MARGIN),
		Vector2(cols + PLATE_MARGIN, -PLATE_MARGIN),
		Vector2(-PLATE_MARGIN, rows + PLATE_MARGIN),
		Vector2(cols + PLATE_MARGIN, rows + PLATE_MARGIN),
	]:
		for z in [Z_PLATE - 0.25, Z_TOP]:
			var point := _raw(corner.x, corner.y, z)
			low = low.min(point)
			high = high.max(point)
	var span := high - low
	cell_scale = minf((box.x - 2.0 * FIT_MARGIN) / span.x, (box.y - 2.0 * FIT_MARGIN) / span.y)
	_bounds_center = (low + high) / 2.0


## The box this projection was fitted into.
func box() -> Vector2:
	return _box


## The screen point of a board point.
func project(x: float, y: float, z: float) -> Vector2:
	return _box / 2.0 + (_raw(x, y, z) - _bounds_center) * cell_scale


## Smaller is farther from the camera, so an ascending sort paints far to near.
func depth(x: float, y: float) -> float:
	return -Vector2(x - cols / 2.0, y - rows / 2.0).distance_to(_camera)


## Is the vertical face through (px, py) with outward normal (nx, ny) seen by the camera?
func sees(px: float, py: float, nx: float, ny: float) -> bool:
	return nx * (_camera.x - (px - cols / 2.0)) + ny * (_camera.y - (py - rows / 2.0)) > 0.001


func _raw(x: float, y: float, z: float) -> Vector2:
	var rx := x - cols / 2.0
	var ry := y - rows / 2.0
	var f := 1.0 / (1.0 - perspective * (ry * _sin_pitch + z * _cos_pitch))
	return Vector2(rx * f, (ry * _sin_pitch - z * _cos_pitch) * f)
