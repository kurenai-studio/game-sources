extends Node2D

@onready var ball: CharacterBody2D = $ball
@onready var ball_count: Label = $UI/HBoxContainer/ball_count
@onready var score_count: Label = $UI/HBoxContainer/score_count
@onready var best_score: Label = $UI/HBoxContainer/best_score
@onready var last_score_count: Label = $UI/HBoxContainer/last_score_count
@onready var bricks: Node2D = $bricks

@export var brick_scene : PackedScene
@export var count_of_balls = 3
@export var brick_rows = 10
@export var brick_columns = 28
var colors = [
		Color("#ff0000"),
		Color("#ff0000"),
		Color("#ff7f00"),
		Color("#ff7f00"),
		Color("#ffff00"),
		Color("#ffff00"),
		Color("#00ff00"),
		Color("#00ff00"),
		Color("#0000ff"),
		Color("#0000ff"),
		Color("#4b0082"),
		Color("#4b0082"),
		Color("#8f00ff"),
		Color("#8f00ff")  
	]

func _ready() -> void:
	ball_count.text = str(count_of_balls)
	score_count.text = "0"
	best_score.text = "0"
	spawn_bricks( )

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed("start"):
		ball.start_round()
	elif Input.is_action_just_pressed("restart"):
		Game_over()
		return

func Game_over():
	best_score.text = str(max(int(score_count.text), int(best_score.text)))
	ball_count.text = str(count_of_balls)
	last_score_count.text = score_count.text
	score_count.text = "0"
	ball.restart()
	remove_bricks()
	spawn_bricks()

func spawn_bricks():
	for row in brick_rows:
		for col in brick_columns:
			var brick = brick_scene.instantiate()
			brick.position = Vector2(-540 + col * 40, -250 + row * 12)
			brick.modulate = colors[row]
			bricks.add_child(brick)

func remove_bricks():
	for brick in bricks.get_children():
		brick.destroy()

func _on_ball_ball_lost() -> void:
	ball_count.text = str(int(ball_count.text) - 1)
	if int(ball_count.text) <= 0:
		call_deferred("Game_over")
		return
	ball.restart()

func _on_ball_scored() -> void:
	score_count.text = str(int(score_count.text) + 1)
