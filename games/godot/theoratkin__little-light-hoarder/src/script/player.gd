extends KinematicBody2D

var can_move = false

var snap = false

var run_speed = 50
var jump_speed = 160
var gravity = 400

const JUMP_BUFFER = 0.3
const JUMP_CYOTE = 0.1

var idle_name = "idle"

var velocity = Vector2()

var _jump_buffer = 0.0

var _air_time = 0.0
var _jump_in_progress = false
var ignore_teleport = false

onready var sprite = get_node("sprite")
onready var eyes = get_node("eyes")

func _ready():
	align_position_to_pixels()


func set_active(state):
	can_move = state
	visible = state


func align_position_to_pixels():
	position = Vector2(round(position.x), position.y)


func flip(state):
	transform.x = Vector2(-1 if state else 1, 0)


func get_input(delta):
	if not can_move:
		velocity.x = 0
		sprite.play(idle_name)
		eyes.play("idle")
		align_position_to_pixels()
		return
	velocity.x = 0
	var right = Input.is_action_pressed('right')
	var left = Input.is_action_pressed('left')
	var jump = Input.is_action_just_pressed('jump')
	
	if is_on_floor():
		_air_time = 0
		_jump_in_progress = false
	else:
		_air_time += delta
		if jump:
			_jump_buffer = JUMP_BUFFER
	
	var can_jump = _air_time < JUMP_CYOTE and not _jump_in_progress
	var want_to_jump = jump or _jump_buffer > 0
	
	if (want_to_jump and can_jump):
		velocity.y = -jump_speed
		_jump_buffer = 0
		_jump_in_progress = true
	
	if right:
		flip(false)
		velocity.x += run_speed
	if left:
		flip(true)
		velocity.x -= run_speed
	if !right and !left:
		if is_on_floor():
			sprite.play("idle")
			eyes.play("idle")
		#flip(false)
		align_position_to_pixels()
	
	if !is_on_floor():
		if !right and !left:
			sprite.play("jump")
			eyes.play("jump")
	
	if Input.is_action_just_pressed("down") and is_on_floor():
		position = Vector2(position.x, position.y + 3)


func _physics_process(delta):
	ignore_teleport = false
	velocity.y += gravity * delta
	get_input(delta)
	if not snap:
		velocity = move_and_slide(velocity, Vector2(0, -1))
	else:
		velocity = move_and_slide_with_snap(velocity, Vector2(0, 8), Vector2(0, -1))
	if _jump_buffer > 0:
		_jump_buffer -= delta
