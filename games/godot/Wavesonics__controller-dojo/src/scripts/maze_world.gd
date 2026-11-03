extends Node2D

signal goal_reached()

const MazeGenerator := preload("res://scripts/maze_generator.gd")
const ConfettiBurst := preload("res://scripts/confetti_burst.gd")
const StarShape := preload("res://scripts/star_shape.gd")
const MazeDangerLayer := preload("res://scripts/maze_danger_layer.gd")

@export var cols: int = 5
@export var rows: int = 3
@export var wall_thickness: float = 22.0
@export var extra_openings: int = 2
@export var max_cell_size: float = 220.0

const REFERENCE_CORRIDOR := 150.0
const WALL_LAYER := 1
const AVATAR_LAYER := 2

const WALL_COLOR := Color(0.26, 0.31, 0.52)
const WALL_EDGE_COLOR := Color(0.38, 0.45, 0.72)
const HARD_WALL_COLOR := Color(0.44, 0.24, 0.36)
const HARD_WALL_EDGE_COLOR := Color(0.78, 0.36, 0.48)
const HIT_WALL_COLOR := Color(1.0, 0.33, 0.38)
const WALL_FLASH_TIME := 0.55
const DANGER_COLOR := Color(1.0, 0.36, 0.30)
const DANGER_SEGMENTS := 28
const FLOOR_COLOR := Color(0.10, 0.12, 0.22)
const START_COLOR := Color(0.42, 0.86, 1.0)
const GOAL_COLOR := Color(1.0, 0.78, 0.28)

@onready var avatar = $Avatar

var hard_mode: bool = false
var bounds: Vector2 = Vector2.ZERO
var corridor: float = 100.0
var cell_size: float = 120.0
var start_cell: Vector2i = Vector2i.ZERO
var goal_cell: Vector2i = Vector2i.ZERO

var _cells: PackedInt32Array
var _rects: Array[Rect2] = []
var _goal_armed: bool = false
var _pulse: float = 0.0
var _hit_index: int = -1
var _hit_flash: float = 0.0
var _walls: StaticBody2D
var _goal_area: Area2D
var _goal_circle: CircleShape2D
var _confetti: CPUParticles2D
var _danger: Node2D


func _ready() -> void:
	_walls = StaticBody2D.new()
	_walls.collision_layer = WALL_LAYER
	_walls.collision_mask = 0
	add_child(_walls)

	_goal_circle = CircleShape2D.new()
	var goal_shape := CollisionShape2D.new()
	goal_shape.shape = _goal_circle
	_goal_area = Area2D.new()
	_goal_area.collision_layer = 0
	_goal_area.collision_mask = AVATAR_LAYER
	_goal_area.add_child(goal_shape)
	_goal_area.body_entered.connect(_on_goal_body_entered)
	add_child(_goal_area)

	_danger = Node2D.new()
	_danger.set_script(MazeDangerLayer)
	_danger.world = self
	add_child(_danger)

	_confetti = ConfettiBurst.build()
	add_child(_confetti)


func _process(delta: float) -> void:
	_pulse += delta
	_hit_flash = maxf(_hit_flash - delta, 0.0)
	_danger.queue_redraw()
	queue_redraw()


## Lays out a fresh maze sized to fit `area`, and parks the avatar at the start.
func build(area: Vector2) -> void:
	_measure(area)
	start_cell = Vector2i(
		0 if randi() % 2 == 0 else cols - 1,
		0 if randi() % 2 == 0 else rows - 1
	)
	_cells = MazeGenerator.generate(cols, rows, extra_openings)
	goal_cell = MazeGenerator.farthest_from(_cells, cols, rows, start_cell)
	_rects = _build_wall_rects()
	_build_wall_bodies()

	_goal_area.position = cell_center(goal_cell)
	_goal_circle.radius = corridor * 0.3

	avatar.configure(clampf(corridor * 0.26, 6.0, 30.0), corridor / REFERENCE_CORRIDOR)
	reset_avatar()
	queue_redraw()


## Parks the avatar back on the start pad without touching the layout.
func reset_avatar() -> void:
	avatar.velocity = Vector2.ZERO
	avatar.position = cell_center(start_cell)
	_hit_flash = 0.0
	_hit_index = -1
	_goal_armed = true


func cell_center(cell: Vector2i) -> Vector2:
	return Vector2(cell) * cell_size + Vector2.ONE * (cell_size + wall_thickness) * 0.5


## Lights up whichever wall segment sits closest to a global contact point.
func flash_wall(global_point: Vector2) -> void:
	var point := to_local(global_point)
	var best := -1
	var best_distance := INF
	for i in _rects.size():
		var rect: Rect2 = _rects[i]
		var closest := Vector2(
			clampf(point.x, rect.position.x, rect.end.x),
			clampf(point.y, rect.position.y, rect.end.y)
		)
		var distance := point.distance_squared_to(closest)
		if distance < best_distance:
			best_distance = distance
			best = i
	_hit_index = best
	_hit_flash = WALL_FLASH_TIME


func burst(at: Vector2, amount: int) -> void:
	_confetti.position = at
	_confetti.amount = amount
	_confetti.restart()


func _measure(area: Vector2) -> void:
	var fit := minf((area.x - wall_thickness) / cols, (area.y - wall_thickness) / rows)
	cell_size = clampf(fit, wall_thickness * 2.5, max_cell_size)
	corridor = cell_size - wall_thickness
	bounds = Vector2(cols * cell_size, rows * cell_size) + Vector2.ONE * wall_thickness


func _build_wall_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	var t := wall_thickness
	for y in rows:
		for x in cols:
			var cell := Vector2i(x, y)
			var corner := Vector2(x, y) * cell_size
			if MazeGenerator.has_wall(_cells, cols, cell, 0):
				rects.append(Rect2(corner, Vector2(cell_size + t, t)))
			if MazeGenerator.has_wall(_cells, cols, cell, 3):
				rects.append(Rect2(corner, Vector2(t, cell_size + t)))
			if y == rows - 1 and MazeGenerator.has_wall(_cells, cols, cell, 2):
				rects.append(Rect2(corner + Vector2(0.0, cell_size), Vector2(cell_size + t, t)))
			if x == cols - 1 and MazeGenerator.has_wall(_cells, cols, cell, 1):
				rects.append(Rect2(corner + Vector2(cell_size, 0.0), Vector2(t, cell_size + t)))
	return rects


func _build_wall_bodies() -> void:
	for child in _walls.get_children():
		child.queue_free()
	for rect in _rects:
		var shape := RectangleShape2D.new()
		shape.size = rect.size
		var collider := CollisionShape2D.new()
		collider.shape = shape
		collider.position = rect.get_center()
		_walls.add_child(collider)


func _on_goal_body_entered(body: Node2D) -> void:
	if body != avatar or not _goal_armed:
		return
	_goal_armed = false
	goal_reached.emit()


func _draw() -> void:
	if _cells.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, bounds), FLOOR_COLOR)
	_draw_start()
	_draw_goal()
	var wall_color := HARD_WALL_COLOR if hard_mode else WALL_COLOR
	var edge_color := HARD_WALL_EDGE_COLOR if hard_mode else WALL_EDGE_COLOR
	var hit_blend := _hit_flash / WALL_FLASH_TIME
	for i in _rects.size():
		var color := wall_color
		if i == _hit_index and _hit_flash > 0.0:
			color = wall_color.lerp(HIT_WALL_COLOR, hit_blend)
		draw_rect(_rects[i], color)
	draw_rect(Rect2(Vector2.ZERO, bounds), edge_color, false, 3.0)


## Paints the slice of wall that has crossed inside the avatar's soft body, so
## she can see a touch coming before the hitbox reaches it.
func draw_danger(canvas: CanvasItem) -> void:
	if not hard_mode or _rects.is_empty():
		return
	var center: Vector2 = avatar.position
	var reach: float = avatar.radius
	var body := _circle_polygon(center, reach)
	for rect in _rects:
		var closest := Vector2(
			clampf(center.x, rect.position.x, rect.end.x),
			clampf(center.y, rect.position.y, rect.end.y)
		)
		var distance := center.distance_to(closest)
		if distance >= reach:
			continue
		var color := DANGER_COLOR
		color.a = lerpf(0.15, 0.9, 1.0 - distance / reach)
		for piece in Geometry2D.intersect_polygons(body, _rect_polygon(rect)):
			canvas.draw_colored_polygon(piece, color)


func _circle_polygon(center: Vector2, radius: float) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in DANGER_SEGMENTS:
		var angle := TAU * i / DANGER_SEGMENTS
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	return points


func _rect_polygon(rect: Rect2) -> PackedVector2Array:
	return PackedVector2Array([
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		rect.end,
		Vector2(rect.position.x, rect.end.y),
	])


func _draw_start() -> void:
	var color := START_COLOR
	color.a = 0.35
	draw_arc(cell_center(start_cell), corridor * 0.34, 0.0, TAU, 40, color, 3.0, true)


func _draw_goal() -> void:
	var center := cell_center(goal_cell)
	var pulse := 0.5 + 0.5 * sin(_pulse * 3.0)
	var glow := GOAL_COLOR
	glow.a = lerpf(0.16, 0.34, pulse)
	draw_circle(center, corridor * lerpf(0.36, 0.46, pulse), glow)
	var star := GOAL_COLOR
	star.a = 0.9
	var outer := corridor * lerpf(0.24, 0.3, pulse)
	draw_colored_polygon(StarShape.points(center, outer, outer * 0.44, _pulse * 0.6), star)
