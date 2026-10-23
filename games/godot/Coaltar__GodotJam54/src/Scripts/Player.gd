extends KinematicBody2D


export var speed = 420
var velocity = Vector2.ZERO
const GRAVITY = 250.0

export var max_light_radius = 500
export var min_light_radius = 100
var current_light_radius = max_light_radius
const max_time = 15
var time
var score

signal game_over
# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	player_start()
	pass # Replace with function body.

func _process(delta):
	animate_player()
	pass

func get_dir():
	var dir = Vector2.ZERO
	if(Input.is_action_pressed("move_left")):
		dir.x -= 1
	if(Input.is_action_pressed("move_right")):
		dir.x += 1
	if(Input.is_action_pressed("move_up")):
		dir.y -= 1
	if(Input.is_action_pressed("move_down")):
		dir.y += 1
	return dir.normalized()

func animate_player():
	if(velocity.x > 0):
		$AnimatedSprite.flip_h = false
		$AnimatedSprite.animation = "run"
		$AnimatedSprite.play()
	elif(velocity.x < 0):
		$AnimatedSprite.flip_h = true
		$AnimatedSprite.animation = "run"
		$AnimatedSprite.play()
	else :
		$AnimatedSprite.animation = "stand"
		$AnimatedSprite.play()
	
func _physics_process(delta):
	if(Input.is_action_just_pressed("action")):
		print("Fire!")
	
	var dir = get_dir()
	velocity = (dir * speed)
	move_and_slide(velocity, dir)
	#move_and_collide(velocity)
	pass

func player_start():
	$Timer.start(1)
	
	time = max_time
	score = 0
	
	$TimeLabel.text = String(time)
	$ScoreLabel.text = String(score)
	


func _on_Timer_timeout():
	self.time = time - 1
	$TimeLabel.text = String(time)
	
	
	if(time < 0):
		emit_signal("game_over")
	
	pass # Replace with function body.


func _on_GameManager_player_found_goal():
	score += 1
	time += 10
	
	$ScoreLabel.text = String(score)
	pass # Replace with function body.


func _on_GameManager_game_start():
	player_start()
	pass # Replace with function body.
