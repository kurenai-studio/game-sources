extends Node2D

@export var max_allowed_distance: float = 15.0 #max distance from line for calculating player's score
@export var line_width: float = 4.0 #width of the tattoo line
@export var tattoo_pool: Array[PackedScene] = [] #array with all the tattoo scenes
@export var max_levels: int = 3 #number of levels in da game

@onready var tattoo_container: Node2D = $TattooContainer
# @onready var target_group: Node2D = $TargetGroup
@onready var drawing_canvas: Node2D = $DrawingCanvas
@onready var buzz_sfx: AudioStreamPlayer = $BuzzSFX


@export_file("*.tscn") var game_over_scene: String = "res://scenes/GameOverScreen.tscn"

# @onready var score_label: Label = $UI/ScoreLabel
@onready var level_label: Label = $UI/LevelLabel
@onready var submit_button: Button = $UI/SubmitButton
@onready var score_toast: Control = $UI/ScoreToast
# @onready var next_button: Button = $UI/NextButton

#overall level vars
var current_level: int = 0
var level_scores: Array[float] = []
var active_target_group: Node2D = null

var current_line: Line2D = null
var is_drawing: bool = false

func _ready() -> void:
	tattoo_pool.shuffle()
	# next_button.hide()
	load_level(0)

##### LOAD THE LEVEL #####

func load_level(level_index: int) -> void:
	current_level = level_index
	level_label.text = "Customer: " + str(current_level + 1) + "/" + str(max_levels)
	# score_label.text = "Score: --"
	submit_button.show()
	# next_button.hide()
	clear_drawing_canvas()

	for child in tattoo_container.get_children():
		child.queue_free()

	if level_index < tattoo_pool.size():
		var tattoo_instance = tattoo_pool[level_index].instantiate()
		tattoo_container.add_child(tattoo_instance)
		active_target_group = tattoo_instance.get_node("TargetGroup")


##### DRAWING STUFF #####

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

	# bzzzzzzzzz
	if buzz_sfx and not buzz_sfx.playing:
		buzz_sfx.play()

func add_point_to_stroke(pos: Vector2) -> void:
	if current_line and current_line.get_point_count() > 0:
		if current_line.get_point_position(current_line.get_point_count() - 1).distance_to(pos) > 2.0:
			current_line.add_point(pos)

func stop_stroke() -> void:
	is_drawing = false
	current_line = null

	# stop bzzzzz
	if buzz_sfx and buzz_sfx.playing:
		buzz_sfx.stop()


##### BUTTONS #####

#connect to button
func _on_btn_submit_pressed() -> void:
	# var final_score: float = calculate_score()
	# score_label.text = "Score: " + str(snapped(final_score, 0.1)) + "%"
	var score: float = calculate_score()
	level_scores.append(score)
	# score_label.text = "Level Score: " + str(snapped(score, 0.1)) + "%"
	submit_button.hide()
	# next_button.show()
	print("pressed submit")
	score_toast.show_score(score)

func _on_btn_reset_pressed() -> void:
	# for line in drawing_canvas.get_children():
	# 		line.queue_free()
	# score_label.text = "Score: --"
	clear_drawing_canvas()
	# score_label.text = "Score: --"

func _on_next_button_pressed() -> void:
	if current_level + 1 < max_levels:
		load_level(current_level + 1)
	else:
		show_final_results()

func clear_drawing_canvas() -> void:
	for line in drawing_canvas.get_children():
		line.queue_free()


##### SCORING #####

func calculate_score() -> float:
	if not active_target_group:
		return 0.0

	var target_points: Array[Vector2] = []
	for child in active_target_group.get_children():
		if child is Path2D:
			target_points.append_array(child.curve.get_baked_points())

	var player_points: Array[Vector2] = []
	for line in drawing_canvas.get_children():
		if line is Line2D:
			player_points.append_array(line.points)

	if target_points.is_empty() or player_points.is_empty():
		return 0.0

	var max_dist_sq: float = max_allowed_distance * max_allowed_distance

	# coverage_score: calculate dist btwn target line and player line
	var hits: int = 0
	for tp in target_points:
		var min_dist_sq: float = INF
		for pp in player_points:
			var dist_sq: float = tp.distance_squared_to(pp)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				if min_dist_sq <= max_dist_sq:
					break
		if min_dist_sq <= max_dist_sq:
			hits += 1

	var coverage_score: float = (float(hits) / float(target_points.size())) * 100.0

	# errant_poitns: penalize for errant lines
	var errant_points: int = 0
	for pp in player_points:
		var min_dist_sq: float = INF
		for tp in target_points:
			var dist_sq: float = pp.distance_squared_to(tp)
			if dist_sq < min_dist_sq:
				min_dist_sq = dist_sq
				if min_dist_sq <= max_dist_sq:
					break
		if min_dist_sq > max_dist_sq:
			errant_points += 1

	# mite change that '50' to a variable later to more heavily penalize random lines?
	var penalty: float = (float(errant_points) / float(player_points.size())) * 50.0

	# take the coverage score, subtract any penalties, and 
	# return a score btwn 0-100
	return clamp(coverage_score - penalty, 0.0, 100.0)

func show_final_results() -> void:
	var total: float = 0.0
	for s in level_scores:
		total += s
	# var average: float = total / level_scores.size()
	GameManager.final_score = total / level_scores.size() if not level_scores.is_empty() else 0.0
	get_tree().change_scene_to_file(game_over_scene)
	
	level_label.text = "GAME OVER"
	# score_label.text = "Final Avg Score: " + str(snapped(average, 0.1)) + "%"
	submit_button.hide()
	# next_button.hide()
