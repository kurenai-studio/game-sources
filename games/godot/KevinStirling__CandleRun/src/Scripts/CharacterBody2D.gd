extends CharacterBody2D
class_name CandleMan

signal died
var is_dead = false

# DEBUG SHIT
# @onready var size_1 = $"../CanvasLayer/Size1"
# @onready var size_2 = $"../CanvasLayer/Size2"
# @onready var size_3 = $"../CanvasLayer/Size3"
#@onready var label = $"../CanvasLayer/Label"
#@onready var hitbox1 = $Size1/Hitbox
#@onready var hitbox2 = $Size2/Hitbox
#@onready var hitbox3 = $Size3/Hitbox
#@onready var hitbox1coll = $Size1/Hitbox/CollisionShape2D
#@onready var hitbox2coll = $Size2/Hitbox/CollisionShape2D
#@onready var hitbox3coll = $Size3/Hitbox/CollisionShape2D
@onready var hitbox_test = $Hitbox
@onready var hitboxcoll_test = $Hitbox/CollisionShape2D

@onready var animation_size_1 = $Size1
@onready var animation_size_2 = $Size2
@onready var animation_size_3 = $Size3
@onready var dead = $Dead
@onready var light_animation: AnimationPlayer = %LightAnimationPlayer

@onready var collision_shape_size_1 = $CollisionShapeSize1
@onready var collision_shape_size_2 = $CollisionShapeSize2
@onready var collision_shape_size_3 = $CollisionShapeSize3

@onready var current_animation : AnimatedSprite2D

@onready var footsteps : AudioStreamPlayer = $Footsteps
@onready var step_speed : Timer = $Footsteps/StepSpeed
@onready var downsize_sfx : AudioStreamPlayer = $DownsizeSFX
@onready var upsize_sfx : AudioStreamPlayer = $UpsizeSFX
@onready var dead_sfx : AudioStreamPlayer = $DeadSFX

@export var SPEED = 100.0
@export var slide_speed = 100.0
@export var turn_speed = 100.0
#const JUMP_VELOCITY = -250.0

@export var jump_height : float
@export var jump_time_to_peak: float
@export var jump_time_to_descent : float

@onready var jump_velocity : float = ((2.0 * jump_height) / jump_time_to_peak) * -1.0
@onready var jump_gravity : float = ((-2.0 * jump_height) / (jump_time_to_peak * jump_time_to_peak)) * -1.0
@onready var fall_gravity : float = ((-2.0 * jump_height) / (jump_time_to_descent * jump_time_to_descent)) * -1.0

@onready var coyote_timer = $CoyoteTimer
@onready var downsize_timer = $DownsizeTimer
@onready var damage_cool_down_timer = $DamageCoolDown

var previous_vel
var disable_shrink : bool
var invincible : bool = false
var in_damage_area = false

var current_anim_size : int
func increase_anim_size():
	if current_anim_size < 3 && current_anim_size > 0:
		upsize_sfx.play()
		set_anim_size(current_anim_size + 1)
		
func decrease_anim_size():

	if current_anim_size <= 3 && current_anim_size > 1:
		downsize_sfx.play()
		set_anim_size(current_anim_size - 1)
	else:
		dead_sfx.play()
		light_animation.play("dead")
		# process_mode = Node.PROCESS_MODE_DISABLED
		is_dead = true
		animation_size_1.visible = false
		dead.visible = true
		died.emit()


func set_anim_size(size):
	dead.visible = false
	is_dead = false
	light_animation.play("flicker")
	match size :
		1 :
			# current_distance_left = distance_between_sizes
			animation_size_1.visible = true
			animation_size_2.visible = false
			animation_size_3.visible = false
			animation_size_1.process_mode = Node.PROCESS_MODE_INHERIT
			animation_size_2.process_mode = Node.PROCESS_MODE_DISABLED
			animation_size_3.process_mode = Node.PROCESS_MODE_DISABLED
			collision_shape_size_1.disabled = false
			collision_shape_size_2.disabled = true
			collision_shape_size_3.disabled = true
			collision_shape_size_1.set_deferred("disabled", false)
			collision_shape_size_2.set_deferred("disabled", true)
			collision_shape_size_3.set_deferred("disabled", true)
			current_animation = animation_size_1
			current_anim_size = 1
			hitboxcoll_test.shape.size = Vector2(7, 12.5)
			hitboxcoll_test.position = Vector2(0, 1.25)

		2 :
			# current_distance_left = distance_between_sizes
			animation_size_1.visible = false
			animation_size_2.visible = true
			animation_size_3.visible = false
			animation_size_1.process_mode = Node.PROCESS_MODE_DISABLED
			animation_size_2.process_mode = Node.PROCESS_MODE_INHERIT
			animation_size_3.process_mode = Node.PROCESS_MODE_DISABLED
			collision_shape_size_1.set_deferred("disabled", true)
			collision_shape_size_2.set_deferred("disabled", false)
			collision_shape_size_3.set_deferred("disabled", true)
			current_animation = animation_size_2
			current_anim_size = 2
			hitboxcoll_test.shape.size = Vector2(7, 30.5)
			hitboxcoll_test.position = Vector2(0, -7.75)

		3 :
			# current_distance_left = distance_between_sizes
			animation_size_1.visible = false
			animation_size_2.visible = false
			animation_size_3.visible = true
			animation_size_1.process_mode = Node.PROCESS_MODE_DISABLED
			animation_size_2.process_mode = Node.PROCESS_MODE_DISABLED
			animation_size_3.process_mode = Node.PROCESS_MODE_INHERIT
			collision_shape_size_1.set_deferred("disabled", true)
			collision_shape_size_2.set_deferred("disabled", true)
			collision_shape_size_3.set_deferred("disabled", false)
			current_animation = animation_size_3
			current_anim_size = 3
			hitboxcoll_test.shape.size = Vector2(7, 45)
			hitboxcoll_test.position = Vector2(0, -15)
			
func _ready():
#	MOVE ALL THIS SHIT INTO SOME STATE MANAGEMENT? eh maybe later...
	hitbox_test.body_entered.connect(func(body):
		if body is TileMap:
			in_damage_area = true
	)
	hitbox_test.body_exited.connect(func(body):
		if body is TileMap:
			in_damage_area = false 
	)
	downsize_timer.timeout.connect(decrease_anim_size)
	damage_cool_down_timer.timeout.connect(func():
		invincible = false
	)
	step_speed.timeout.connect(func():
		footsteps.play()
	)	
	set_anim_size(3)
	# size_1.pressed.connect(func():
	# 	set_anim_size(1))
	# size_2.pressed.connect(func():
	# 	set_anim_size(2))
	# size_3.pressed.connect(func():
	# 	set_anim_size(3))

func respawn(anim_size : int):
	set_anim_size(anim_size)
	in_damage_area = false

func get_gravity() -> float:
	return jump_gravity if velocity.y < 0.0 else fall_gravity

var last_dir_before_jump : float
var direction : float

func take_damage():
	if not invincible && not is_dead: 
		decrease_anim_size()
		invincible = true
		damage_cool_down_timer.start()

func _physics_process(delta):

	if in_damage_area:
		take_damage()

	if not is_dead:
		if not is_on_floor():
			velocity.y += get_gravity() * delta

		# Handle size down
		if Input.is_action_pressed("size_down"):
			# await get_tree().create_timer(1.5).timeout
			if not disable_shrink :
				if downsize_timer.is_stopped():
					downsize_timer.start()
					current_animation.play("shrink")
					light_animation.play("blaze")
				# else:
					# slow down player if on ground
					# if is_on_floor():
				velocity.x = move_toward(previous_vel.x, velocity.x, 10)

		if Input.is_action_just_released("size_down"):
			print("timer stopped")
			downsize_timer.stop()
			light_animation.play("flicker")

		# Handle jump.
		if Input.is_action_just_pressed("jump") and (is_on_floor() || !coyote_timer.is_stopped()):
			last_dir_before_jump = direction
			velocity.y = jump_velocity
			step_speed.stop()

		# Get the input direction and handle the movement/deceleration.
		direction = Input.get_axis("ui_left", "ui_right")
		previous_vel = velocity
		if direction && downsize_timer.is_stopped():
			if is_on_floor() && step_speed.is_stopped():
				step_speed.start()
			# previous_vel = velocity
			if not is_on_floor() && direction == -(last_dir_before_jump):
				if previous_vel.x == 0:
					velocity.x = (direction * SPEED) / 2
				else:
					velocity.x = (direction * SPEED) / (2 + delta)
			else:
				velocity.x = direction * SPEED

			if velocity.x > 0 :
				rotation_degrees = lerp(rotation_degrees, -5.0, .1)
				current_animation.flip_h = false
				if previous_vel.x < 0 :
					velocity.x = move_toward(previous_vel.x, velocity.x, slide_speed)

			else:
				rotation_degrees = lerp(rotation_degrees, 5.0, .1)
				current_animation.flip_h = true
				if previous_vel.x > 0 :
					velocity.x = move_toward(previous_vel.x, velocity.x, slide_speed)
			current_animation.play("run")
			# current_distance_left = current_distance_left - delta
		else:
			rotation_degrees = lerp(rotation_degrees, 0.0, .1)
			velocity.x = move_toward(velocity.x, 0, slide_speed)
			if downsize_timer.is_stopped():
				current_animation.play("idle")

		var was_on_floor = is_on_floor()

		if (Input.is_action_just_released("ui_left") || Input.is_action_just_released("ui_right")) && not is_on_floor():
			# velocity.x = move_toward(previous_vel.x, 0, .004)
			velocity.x = move_toward(previous_vel.x, velocity.x / .6, slide_speed)

		
		move_and_slide()

		if was_on_floor && !is_on_floor():
			coyote_timer.start()
		
