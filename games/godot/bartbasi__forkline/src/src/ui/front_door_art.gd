# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name FrontDoorArt
extends Control
## The small live picture on the front door: a short road with night creatures
## walking to the village hearth, two watch posts beside it, a flyer crossing
## the sky. It is decoration only and never takes a touch. It stops when hidden.

const GRID: PackedStringArray = [
	".......",
	".o...o.",
	"1##G##B",
	"..o.o..",
]
const COLUMNS: int = 7
const ROW_ROAD: int = 2
## Walkers: creature id, start offset in cells, speed in cells per second.
const WALKERS: Array[Array] = [
	[&"scamp", 0.0, 0.55],
	[&"pip", 2.6, 0.55],
	[&"shellback", 4.4, 0.40],
]

var _ground: Control
var _actors: Control
var _time: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = false
	_ground = Control.new()
	_ground.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ground.set_anchors_preset(Control.PRESET_FULL_RECT)
	_ground.draw.connect(_draw_ground)
	add_child(_ground)
	_actors = Control.new()
	_actors.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_actors.set_anchors_preset(Control.PRESET_FULL_RECT)
	_actors.draw.connect(_draw_actors)
	add_child(_actors)


## The picture is 7 cells wide and 4 tall. Give it the width it may use.
func fit_width(width: float) -> void:
	custom_minimum_size = Vector2(width, width * float(GRID.size()) / float(COLUMNS))


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_ground.queue_redraw()
		_actors.queue_redraw()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	_actors.queue_redraw()


func _cell() -> float:
	return size.x / float(COLUMNS)


func _draw_ground() -> void:
	var cell: float = _cell()
	if cell <= 0.0:
		return
	MapArt.draw_ground(_ground, GRID, cell, UiTheme.font(UiTheme.WEIGHT_BOLD))
	MapArt.draw_gate(_ground, GRID, Vector2i(3, ROW_ROAD), cell, MapArt.Gate.SOCKET)


func _draw_actors() -> void:
	var cell: float = _cell()
	if cell <= 0.0:
		return
	var frame: int = int(_time * 8.0) % 4
	Silhouettes.draw_tower(_actors, &"sling_post", 2, -1, _center(1, 1, cell), cell)
	Silhouettes.draw_tower(_actors, &"pumpkin_catapult", 1, -1, _center(5, 1, cell), cell)
	Silhouettes.draw_tower(_actors, &"lullaby_bell", 1, -1, _center(2, 3, cell), cell)
	# Walkers loop from the entrance to the village and start again.
	var span: float = float(COLUMNS - 1)
	for walker: Array in WALKERS:
		var id: StringName = walker[0]
		var x: float = fposmod(float(walker[1]) + _time * float(walker[2]), span + 0.6) - 0.3
		var at: Vector2 = Vector2((x + 0.5) * cell, (float(ROW_ROAD) + 0.5) * cell)
		Silhouettes.draw_enemy(_actors, id, at, Silhouettes.enemy_size(id, cell), frame)
	# A flyer crosses straight from the entrance to the village.
	var t: float = fposmod(_time * 0.12, 1.0)
	var from: Vector2 = _center(0, ROW_ROAD, cell)
	var to: Vector2 = _center(COLUMNS - 1, ROW_ROAD, cell)
	var fly_at: Vector2 = from.lerp(to, t) + Vector2(0.0, -cell * (0.9 + 0.12 * sin(_time * 3.0)))
	Silhouettes.draw_enemy(_actors, &"flitter", fly_at, Silhouettes.enemy_size(&"flitter", cell), frame)


func _center(column: int, row: int, cell: float) -> Vector2:
	return Vector2((float(column) + 0.5) * cell, (float(row) + 0.5) * cell)
