extends CharacterBody2D

const SPEED = 500.0
const JUMP_VELOCITY = -550.0
@onready var root = $".."
@onready var was_on_floor = true
@onready var canJump = true
@onready var canMove = true
@onready var animSprite = $AnimatedSprite2D
@onready var coyoteTimer = $CoyoteTimer
@onready var jBuffTimer = $JumpBufferingTimer

@onready var lastOnGroundYPos = 420

@onready var animPlayer = $"../CanvasLayer/AnimationPlayer"
@onready var colRect = $"../CanvasLayer/ColorRect"

@onready var currentScene;
@onready var camera = $"../Camera2D"

func _ready() -> void:
	colRect.modulate.a = 0
	Global.change_room.connect(change_room)
	Global.player = self

func _physics_process(delta: float) -> void:
	if not is_on_floor(): # gravity
		velocity += get_gravity() * delta
		canJump = false
		if was_on_floor:
			lastOnGroundYPos = self.position.y
			coyoteTimer.start()
		
		
	if animSprite.animation == "landing": # stops jumping when landing animation is playing to prevent bug
		canJump = false
	 
	# if pressed jump or jump buffering is still running, and can jump and coyotetimer is still running
	if (Input.is_action_just_pressed("jump") or not jBuffTimer.is_stopped()) and (canJump or not coyoteTimer.is_stopped()):
		velocity.y = JUMP_VELOCITY
	elif Input.is_action_just_pressed("jump") and not canJump:
		jBuffTimer.start()
		
	if Input.is_action_pressed("move_left"):
		velocity.x = -SPEED
	elif Input.is_action_pressed("move_right"):
		velocity.x = SPEED
	else:
		velocity.x = 0
		
	canJump = true # reset canjump at the end of every frame
	was_on_floor = is_on_floor()
	if canMove:
		move_and_slide()
		
func change_room(scene: PackedScene, playerPos: Vector2, cameraPos: Vector2, yMovement: bool, xMovement: bool) -> void:
	self.canMove = false
	camera.isChangingRoom = true
	animPlayer.play("change_room")
	await get_tree().create_timer(0.5).timeout
	
	self.canMove = true
	camera.moveY = true if yMovement else false
	camera.moveX = true if xMovement else false
	
	self.position = playerPos
	camera.position = cameraPos
	currentScene.queue_free()
	var instance = scene.instantiate()
	root.add_child(instance)
	self.move_to_front()
	currentScene = instance
	
	await get_tree().process_frame
	camera.isChangingRoom = false

	
