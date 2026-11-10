extends Node2D

@export var max_allowed_distance: float = 15.0 #max distance from line for calculating player's score
@export var line_width: float = 4.0 #width of the tattoo line

@onready var target_group: Node2D = $TargetGroup
@onready var drawing_canvas: Node2D = $DrawingCanvas
@onready var score_label: Label = $UI/ScoreLabel

var current_line: Line2D = null
var is_drawing: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			start_stroke(event.position)
		else:
			stop_stroke()
	elif event is InputEventMouseMotion and is_drawing:
		add_point_to_stroke(event.position)

func start_stroke(pos: Vector2) -> void:
	is_drawing = true
	current_line = Line2D.new()
	current_line.width = line_width
	current_line.default_color = Color.BLACK
	drawing_canvas.add_child(current_line)
	current_line.add_point(pos)

func add_point_to_stroke(pos: Vector2) -> void:
	if current_line and current_line.get_point_count() > 0:
		if current_line.get_point_position(current_line.get_point_count() - 1).distance_to(pos) > 2.0:
			current_line.add_point(pos)

func stop_stroke() -> void:
	is_drawing = false
	current_line = null

#connect to button
func _on_btn_submit_pressed() -> void:
	var final_score: float = calculate_score()
	score_label.text = "Score: " + str(snapped(final_score, 0.1)) + "%"

func _on_btn_reset_pressed() -> void:
	for line in drawing_canvas.get_children():
			line.queue_free()
	score_label.text = "Score: --"

func calculate_score() -> float:
	var target_points: Array[Vector2] = []
	for child in target_group.get_children():
		if child is Path2D:
			target_points.append_array(child.curve.get_baked_points())

	var player_points: Array[Vector2] = []
	for line in drawing_canvas.get_children():
		if line is Line2D:
			for i in range(line.get_point_count()):
				player_points.append(line.get_point_position(i))

	if target_points.is_empty() or player_points.is_empty():
		return 0.0

	# coverage_score: calculate dist btwn target line and player line
	var hits: int = 0
	for tp in target_points:
		var closest_dist: float = INF
		for pp in player_points:
			var dist: float = tp.distance_to(pp)
			if dist < closest_dist:
				closest_dist = dist
		if closest_dist <= max_allowed_distance:
			hits += 1

	var coverage_score: float = (float(hits) / float(target_points.size())) * 100.0

	# errant_poitns: penalize for errant lines
	var errant_points: int = 0
	for pp in player_points:
		var closest_dist: float = INF
		for tp in target_points:
			var dist: float = pp.distance_to(tp)
			if dist < closest_dist:
				closest_dist = dist
		if closest_dist > max_allowed_distance:
			errant_points += 1

	# mite change that '50' to a variable later to more heavily penalize random lines?
	var penalty: float = (float(errant_points) / float(player_points.size())) * 50.0

	# take the coverage score, subtract any penalties, and 
	# return a score btwn 0-100
	return clamp(coverage_score - penalty, 0.0, 100.0)
