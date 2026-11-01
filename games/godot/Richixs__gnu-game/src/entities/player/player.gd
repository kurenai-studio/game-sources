extends CharacterBody2D

@export var skin: SkinData
@export var fast_fall_multiplier: float = 4.0 

@export var min_jump_velocity: float = -400.0
@export var max_jump_velocity: float = -450.0
@export var standing_hitbox_inset: Vector2 = Vector2(3, 2)
@export var ducking_hitbox_inset: Vector2 = Vector2(6, 2)

@onready var sprite = $Sprite
@onready var collision_shape = $CollisionShape2D

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var is_ducking: bool = false

func _ready():
	_apply_skin()

func _apply_skin():
	if skin and sprite:
		sprite.sprite_frames = skin.animations
		_set_collision_state(false)
		sprite.play("run")

func _physics_process(delta):
	if not is_on_floor():
		if Global.is_action_pressed(&"down"):
			velocity.y += (gravity * fast_fall_multiplier) * delta
		else:
			velocity.y += gravity * delta
		
		if not is_ducking:
			sprite.play("idle")


	if Global.is_action_just_pressed(&"up") and is_on_floor() and not is_ducking:
		velocity.y = randf_range(max_jump_velocity, min_jump_velocity)
		AudioManager.play_jump()

	if is_on_floor():
		if Global.is_action_pressed(&"down"):
			if not is_ducking:
				_set_collision_state(true)
		elif is_ducking:
			_set_collision_state(false)
		else:
			sprite.play("run")

	move_and_slide()

func _set_collision_state(duck: bool):
	is_ducking = duck
	
	if not skin or not collision_shape.shape is RectangleShape2D:
		return

	var target_size: Vector2
	var target_offset: Vector2
	var hitbox_inset: Vector2

	if is_ducking:
		target_size = skin.ducking_size
		target_offset = skin.ducking_offset
		hitbox_inset = ducking_hitbox_inset
		sprite.position = skin.ducking_offset
		sprite.play("duck")
	else:
		target_size = skin.standing_size
		target_offset = skin.standing_offset
		hitbox_inset = standing_hitbox_inset
		sprite.position = skin.standing_offset
		sprite.play("run")

	var new_size := Vector2(
		max(2.0, target_size.x - hitbox_inset.x * 2.0),
		max(2.0, target_size.y - hitbox_inset.y * 2.0)
	)

	collision_shape.shape.size = new_size
	collision_shape.position = target_offset + Vector2(0, hitbox_inset.y)
