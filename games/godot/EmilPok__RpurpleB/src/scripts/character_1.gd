extends CharacterBody2D

@onready var main = get_tree().current_scene

var SPEED = 90.0

var single_jump = -180.0
var hold_jump = -7.5

var falling_down_velocity_max = 120.0
var speed_falling = 1.5
var max_falling_speed = 400.0

var acceleration_walk = 1200.0
var acceleration_air = 600.0

var shoot_self_knock = 400

var can_jump = true
var during_jump = false
var did_coyote = false

var faster_jump = false

var active = true

var gun_out = false
var taking_gun = false

@onready var Gun = $Rotation_point
@onready var Gun_sprite = $Rotation_point/Gun
@onready var Gun_pivot = $Rotation_point/Pivot
@onready var icon = $Icon

@export var GUI : CanvasLayer

var Camera : Camera2D
var Camera_orginal_pos = Vector2.ZERO
var shake_power = 4
var camera_lerp_power = 1

var bullet = preload("res://scenes/bullet.tscn")

var can_shoot = true

var last_velocity_y = 0
var squesh_weight = 16

var scale_fell = Vector2(1.2, 0.8)
var scale_falling = Vector2(1.9, 0.1)
var scale_hold_jump = Vector2(0.5, 1.5)
var scale_single_jump = Vector2(0.7, 1.3)

var was_airbourne := false

func _physics_process(delta: float) -> void:
	if $Icon.animation == "LookAround" and not $Icon.is_playing():
		if $Icon.frame == 0:
			$Icon.play("Idle")
		else:
			$Icon.play_backwards("LookAround")
	
	if $Icon.scale.x != 1.0:
		$Icon.scale.x = lerp($Icon.scale.x, 1.0, squesh_weight * delta)
		$Icon.scale.y = lerp($Icon.scale.y, 1.0, squesh_weight * delta)
	
	if Camera:
		if Camera.global_position != Camera_orginal_pos:
			Camera.global_position.x = lerp(Camera.global_position.x, Camera_orginal_pos.x, camera_lerp_power * delta)
			Camera.global_position.y = lerp(Camera.global_position.y, Camera_orginal_pos.y, camera_lerp_power * delta)
	
	if not is_on_floor() and $Coyote_time.is_stopped() and not did_coyote:
		was_airbourne = true
		did_coyote = true
		$Coyote_time.start()
	
	if is_on_floor():
		if was_airbourne:
			was_airbourne = false
			$Icon.scale = Vector2(1.3, 0.7)
		if last_velocity_y:
			$Icon.scale = scale_fell
		if not can_jump:
			can_jump = true
		if did_coyote:
			did_coyote = false

	if not is_on_floor():
		was_airbourne = true
		if velocity.y >= falling_down_velocity_max:
			$Icon.scale += scale_falling * delta
			velocity += get_gravity() * delta * speed_falling
		else:
			velocity += get_gravity() * delta
		if velocity.y > max_falling_speed:
			velocity.y = max_falling_speed
		
		
	
	if not active:
		_standing(delta)
		move_and_slide()
		return
	
	if Input.is_action_just_pressed("aim") and not gun_out and not taking_gun:
		taking_gun = true
		$Icon.play("TakeAGun")
		
	if taking_gun and $Icon.animation == "TakeAGun" and not $Icon.is_playing():
		taking_gun = false
		gun_out = true
		Gun_sprite.visible = true
		Engine.time_scale = 0.1
		main.get_node("Music").pitch_scale = 0.5
		_slow_motion_effect(true)
	if gun_out:
		Gun.look_at(get_global_mouse_position())
		var mouse_left := get_global_mouse_position().x < global_position.x
		icon.flip_h = mouse_left 
		Gun_sprite.flip_v = mouse_left
	
	var direction := Input.get_axis("left", "right") if not gun_out and not taking_gun else 0.0
	
	if direction:
		if not gun_out:
			$Icon.flip_h = direction < 0 
	
	if Input.is_action_just_pressed("shoot") and can_shoot and gun_out:
		$Pop.play()
		GUI.red_cursor._shoot()
		gun_out = false
		Gun_sprite.visible = false
		$Rotation_point/Gun_dis.emitting = true
		Engine.time_scale = 1.0
		main.get_node("Music").pitch_scale = 1.0
		Engine.time_scale = 1.0
		main.get_node("Music").pitch_scale = 1.0
		_slow_motion_effect(false)
		$Icon.play("Idle")
		
		can_shoot = false
		$Shoot_cooldown.start()
		
		var new_bullet = bullet.instantiate()
		new_bullet.rotation_offset = Gun.rotation
		new_bullet.global_position = Gun_pivot.global_position
		add_sibling(new_bullet)
		
		main.shot_bullets.append(new_bullet)
		
		velocity = Vector2.RIGHT.rotated(new_bullet.rotation_offset + deg_to_rad(180)) * new_bullet.SPEED * 0.3

		velocity.y = 0.0
		did_coyote = true
		can_jump = false
		
		var camera_shake = Vector2(shake_power, 0.0)
		camera_shake = camera_shake.rotated(Gun.rotation + deg_to_rad(180))
		Camera.global_position += camera_shake
		

	if Input.is_action_just_pressed("jump") and not is_on_floor():
		faster_jump = true
		$Faster_jump.start()
	
	if faster_jump and is_on_floor():
		_jump()
	
	if Input.is_action_just_pressed("jump") and can_jump:
		_jump()
	
	if Input.is_action_pressed("jump") and during_jump and velocity.y <= 0:
		velocity.y += hold_jump * Engine.time_scale
		$Icon.scale += scale_hold_jump * delta
	else:
		during_jump = false

	if direction:
		if abs(velocity.x) <= SPEED + (SPEED / 1.5):
			velocity.x = move_toward(velocity.x, SPEED * direction, acceleration_walk * delta)
			$Icon.play("Walk")
		else:
			_standing(delta)
	else:
		_standing(delta)
	
	
	
	move_and_slide()
	


func _standing(delta):
	if $Icon.animation == "Walk":
		$Icon.play("Idle")
	
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, acceleration_walk * delta)
	else:
		if abs(velocity.x) <= SPEED + (SPEED / 1.5):
			velocity.x = move_toward(velocity.x, 0, acceleration_walk * delta)
		else:
			velocity.x = move_toward(velocity.x, 0, acceleration_air * delta)

func _jump():
	$Icon.scale = scale_single_jump
	velocity.y = 0
	during_jump = true
	velocity.y += single_jump
	can_jump = false

func _on_shoot_cooldown_timeout() -> void:
	can_shoot = true
	

func _on_coyote_time_timeout() -> void:
	can_jump = false


func _on_faster_jump_timeout() -> void:
	faster_jump = false

func _reset():
	Engine.time_scale = 1.0
	main.get_node("Music").pitch_scale = 1.0
	_slow_motion_effect(false)
	gun_out = false
	Gun_sprite.visible = false
	taking_gun = false
	$Icon.play("Idle")

func _slow_motion_effect(on: bool) -> void:
	var mat = GUI.get_node("ColorRect").material
	mat.set_shader_parameter("aberration_x", 0.02 if on else 0.0)
	mat.set_shader_parameter("aberration_y", 0.02 if on else 0.0)
	GUI.get_node("ColorRect2").modulate.a = 0.2 if on else 0.0

func _on_look_around_timeout() -> void:
	if $Icon.animation == "Idle":
		$Icon.play("LookAround")
	$Look_around.start(randf_range(4.0, 9.0))
