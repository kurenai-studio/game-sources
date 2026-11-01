extends Node

var current_speed: float = 200.0 
var speed_multiplier: float = 6.0 
var max_speed: float = 600.0 
var actual_score: float = 0.0 
var game_active: bool = false
var is_restarting: bool = false 
var touch_action_counts := {&"up": 0, &"down": 0}
var touch_action_just_pressed := {&"up": false, &"down": false}
var last_point_milestone: int = 0

signal score_updated(new_score)
@warning_ignore("unused_signal")
signal game_over_triggered

func _physics_process(delta: float) -> void:
	if game_active:
		if current_speed < max_speed:
			current_speed += speed_multiplier * delta
		actual_score += current_speed * delta * 0.05 
		
		@warning_ignore("integer_division")
		var current_milestone = int(actual_score) / 100
		if current_milestone > last_point_milestone:
			last_point_milestone = current_milestone
			AudioManager.play_point()
		
		score_updated.emit(int(actual_score))

func reset_game():
	current_speed = 200.0
	actual_score = 0.0
	last_point_milestone = 0
	game_active = true
	clear_touch_actions()
	get_tree().paused = false
	score_updated.emit(0)

func set_touch_action(action_name: StringName, pressed: bool) -> void:
	if not touch_action_counts.has(action_name):
		return

	if pressed:
		touch_action_counts[action_name] += 1
		if touch_action_counts[action_name] == 1:
			touch_action_just_pressed[action_name] = true
	else:
		touch_action_counts[action_name] = max(0, touch_action_counts[action_name] - 1)
		if touch_action_counts[action_name] == 0:
			touch_action_just_pressed[action_name] = false

func clear_touch_actions() -> void:
	for action_name in touch_action_counts.keys():
		touch_action_counts[action_name] = 0
		touch_action_just_pressed[action_name] = false

func is_action_pressed(action_name: StringName) -> bool:
	return Input.is_action_pressed(action_name) or touch_action_counts.get(action_name, 0) > 0

func is_action_just_pressed(action_name: StringName) -> bool:
	var keyboard_just_pressed := Input.is_action_just_pressed(action_name)
	var touch_just_pressed: bool = touch_action_just_pressed.get(action_name, false)
	touch_action_just_pressed[action_name] = false
	return keyboard_just_pressed or touch_just_pressed
