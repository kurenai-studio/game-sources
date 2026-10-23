class_name Game
extends Node

@export var asteroid: CharacterBody2D
@export var player_a: CharacterBody2D
@export var player_b: CharacterBody2D
@export var scores: CanvasLayer

var camera
var screen_size

var score_a: int = 0
var score_b: int = 0

@export var start: bool = false

func _ready() -> void:
	camera = get_viewport().get_camera_2d()
	screen_size = get_viewport().get_visible_rect().size / camera.zoom
	scores.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("start_game"):
		start_game()
	
	if event.is_action_pressed("back_to_main_menu"):
		exit_game()

func start_game() -> void:
	player_a.position = Vector2(20, screen_size.y / 2)
	player_b.position = Vector2(screen_size.x - 20, screen_size.y / 2)
	asteroid.position = camera.get_screen_center_position()
	scores.show()
	start = true
	
func restart_game() -> void:
	asteroid.position = camera.get_screen_center_position()
	asteroid.launch()
	
func exit_game() -> void:
	get_tree().reload_current_scene()
	
func scored(player_id: int) -> void:
	if player_id == 0:
		score_a += 1
		scores.increment_score(player_id, score_a)
	else:
		score_b += 1
		scores.increment_score(player_id, score_b)

func _on_left_body_entered(body: Node2D) -> void:
	if body.is_in_group("asteroid") and start:
		scored(1)
		restart_game()

func _on_rigtht_body_entered(body: Node2D) -> void:
	if body.is_in_group("asteroid") and start:
		scored(0)
		restart_game()

func _on_bottom_body_entered(body: Node2D) -> void:
	if body.is_in_group("asteroid"):
		asteroid.direction.y *= -1

func _on_top_body_entered(body: Node2D) -> void:
	if body.is_in_group("asteroid"):
		asteroid.direction.y *= -1
