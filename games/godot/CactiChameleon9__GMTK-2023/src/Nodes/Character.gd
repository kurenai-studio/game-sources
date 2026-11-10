extends CharacterBody2D

signal live_changed(lives: int)
signal dashed()
signal death()

@export var lives: int = 5

@export var normal_sprite: Texture
@export var hurt_sprite: Texture
@export var dead_sprite: Texture

@onready var _character_sprite = $Apple
var _character_bounce_length: float = 45

@onready var _shadow_sprite = $Shadow
var _shadow_size_change: float = 0.2

@onready var _dash_audio = $DashAudioPlayer

var _walking: bool = false
var _bouncing: bool = false
var _tweener: Tween

var _acceleration: float = 4500
var _max_speed: float = 400
var _resistance: float = 3000
var _dash_speed: float = 1200

var _can_dash: bool = true
var _dashing: bool = false
var _can_take_damage: bool = true

func _ready():
	live_changed.emit(lives)
	_character_sprite.texture = normal_sprite


func _physics_process(delta):
	# Get the move direction
	_do_movement(delta)
	_do_bouncing()
	_do_dash_checks()


func _do_movement(delta):
	
	var move_direction := Vector2(Input.get_action_strength("ui_right")
								- Input.get_action_strength("ui_left"),
								Input.get_action_strength("ui_down")
								- Input.get_action_strength("ui_up"))
	move_direction = move_direction.limit_length()
	
	if _dashing:
		move_direction = Vector2.ZERO
	
	# Move in direction (or resist if no movement input given)
	if move_direction.is_zero_approx():
		_walking = false
		velocity -= velocity.normalized() * delta * _resistance
		if velocity.length() < _resistance * delta:
			velocity = Vector2.ZERO
	else:
		_walking = true
		velocity += move_direction * delta * _acceleration
		
		# Limit the velocity to max
		velocity = velocity.limit_length(_max_speed)
	
	# Actually move
	move_and_slide()


func _do_bouncing():
	# Create the tween if not existing
	if is_instance_valid(_tweener):
		_bouncing = _tweener.is_running()
	
	# Exit if already tweening/stationary
	if _bouncing or not _walking:
		return
	
	# Bounce Up
	_tweener = create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel(true)
	_tweener.set_ease(Tween.EASE_OUT)
	
	_tweener.tween_property(_character_sprite, "position:y",
							-_character_bounce_length, 0.25).as_relative()
	_tweener.tween_property(_character_sprite, "scale:y",
							-_shadow_size_change/6, 0.25).as_relative()
	_tweener.tween_property(_shadow_sprite, "scale", Vector2.ONE *
							-_shadow_size_change, 0.25).as_relative()
	
	# Bounce Down
	await _tweener.finished
	_tweener = create_tween().set_trans(Tween.TRANS_CUBIC).set_parallel(true)
	_tweener.set_ease(Tween.EASE_IN)
	
	_tweener.tween_property(_character_sprite, "position:y",
							_character_bounce_length, 0.25).as_relative()
	_tweener.tween_property(_character_sprite, "scale:y",
							_shadow_size_change/6, 0.25).as_relative()
	_tweener.tween_property(_shadow_sprite, "scale", Vector2.ONE *
							_shadow_size_change, 0.25).as_relative()


func _do_dash_checks():
	if Input.is_action_just_pressed("ui_accept") and _can_dash:
		# Set the dashed/dashing infos
		dashed.emit()
		_dashing = true
		_can_dash = false
		
		# Disable collisions
		_can_take_damage = false
		
		# Tween transparency
		var tween := create_tween() \
					.set_ease(Tween.EASE_OUT) \
					.set_trans(Tween.TRANS_QUART)
		tween.tween_property(_character_sprite, "modulate", Color(0.8, 0.8, 0.8, 0.8), 0.25)
		
		# Set the velocity to the dash speed (in the right direction)
		velocity = velocity.normalized() * _dash_speed
		
		_dash_audio.play()
	
	# Dashed finished
	if _dashing and velocity.length() <= _max_speed:
		# Set the dashed/dashing infos
		_dashing = false
		_damage_immunity()


func _damage_immunity(hurt: bool = false):
	# Disable collisions
	_can_take_damage = false
	
	if hurt: _character_sprite.texture = hurt_sprite
	
	# Tween transparency
	var tween := create_tween() \
				.set_ease(Tween.EASE_IN_OUT) \
				.set_trans(Tween.TRANS_SINE)
	tween.tween_property(_character_sprite, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.tween_property(_character_sprite, "modulate", Color(.9, .9, .9, .8), 0.3)
	tween.tween_property(_character_sprite, "modulate", Color(1, 1, 1, 1), 0.2)
	tween.tween_property(_character_sprite, "modulate", Color(.9, .9, .9, .8), 0.3)
	tween.tween_property(_character_sprite, "modulate", Color(1, 1, 1, 1), 0.2)
	
	await tween.finished
	
	if hurt: _character_sprite.texture = normal_sprite
	
	# Enable collisions
	_can_take_damage = true


func _enable_dash():
	_can_dash = true


func die():
	# Return if cannot take damage
	if not _can_take_damage:
		return
	
	# Reduce lives and emit lives changed signal
	lives -= 1
	live_changed.emit(lives)
	
	# Emit death signal and change texture if dead
	if lives <= 0:
		death.emit()
		_character_sprite.texture = dead_sprite
		set_process(false)
		set_physics_process(false)
	# Otherwise grant immunity
	else:
		_damage_immunity(true)
