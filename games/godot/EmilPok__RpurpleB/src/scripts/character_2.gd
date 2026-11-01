extends CharacterBody2D

@onready var main = get_tree().current_scene

var SPEED = 100.0

var single_jump = -185.0
var hold_jump = -7.5

var falling_down_velocity_max = 120.0
var speed_falling = 1.5
var max_falling_speed = 400.0

var dash_velocity = 180.0
var dash_vertical_multiplier = 2.0 / 3.0
var during_dash = false
var can_dash = true
var wait_can_dash = false

var acceleration_walk = 1800.0
var acceleration_air = 600.0

var active = false

var can_jump = true
var during_jump = false
var did_coyote = false

var faster_jump = false

var shadow = preload("res://scenes/shadow.tscn")
var shadow_first_frame = 5
var shadow_last_frame = 8
var shadow_frame = 5

var last_velocity_y = 0
var squesh_weight = 16

var scale_fell = Vector2(1.2, 0.8)
var scale_falling = Vector2(1.9, 0.1)
var scale_hold_jump = Vector2(0.5, 1.5)
var scale_single_jump = Vector2(0.7, 1.3)

var was_airbourne := false


func player_2():
	pass

func _physics_process(delta: float) -> void:
	
	if $Icon.animation == "Blink" and not $Icon.is_playing():
		$Icon.play("Idle")
	
	if $Icon.scale.x != 1.0:
		$Icon.scale.x = lerp($Icon.scale.x, 1.0, squesh_weight * delta)
		$Icon.scale.y = lerp($Icon.scale.y, 1.0, squesh_weight * delta)
	
	if is_on_floor():
		if was_airbourne:
			was_airbourne = false
			$Icon.scale = Vector2(1.3, 0.7)
		if last_velocity_y:
			$Icon.scale = scale_fell
		if not can_jump:
			can_jump = true
		if wait_can_dash:
			can_dash = true
			wait_can_dash = false
		if did_coyote:
			did_coyote = false
		if $Icon.animation == "Dash" and not during_dash:
			$Icon.play("Idle")
	
	
	if not is_on_floor() and $Coyote_time.is_stopped() and not did_coyote:
		was_airbourne = true
		did_coyote = true
		$Coyote_time.start()

	if not is_on_floor() and not during_dash:
		was_airbourne = true
		if velocity.y >= falling_down_velocity_max:
			velocity += get_gravity() * delta * speed_falling
			$Icon.scale += scale_falling * delta
		else:
			velocity += get_gravity() * delta
		if velocity.y > max_falling_speed:
			velocity.y = max_falling_speed
	last_velocity_y = velocity.y
	
	if not active:
		if not during_dash:
			_standing(delta)
		move_and_slide()
		return
	
	
	if Input.is_action_just_pressed("jump") and not is_on_floor():
		faster_jump = true
		$Faster_jump.start()
		
	if faster_jump and is_on_floor():
		$Icon.scale = Vector2(0.3, 1.8)
		_jump()
	
	if Input.is_action_just_pressed("jump") and can_jump and not during_dash:
		$Icon.scale = Vector2(0.3, 1.8)
		_jump()
	
	if Input.is_action_pressed("jump") and during_jump and velocity.y <= 0 and not during_dash:
		velocity.y += hold_jump * Engine.time_scale
		$Icon.scale += scale_hold_jump * delta
	else:
		during_jump = false
	
	var direction := Input.get_axis("left", "right")
	
	if Input.is_action_just_pressed("dash") and can_dash:
		var dash_direction = Input.get_vector("left", "right", "up", "down")
		if dash_direction == Vector2.ZERO:
			if $Icon.flip_h:
				dash_direction.x = -1.0
			else:
				dash_direction.x = 1.0
		$Dash_part.direction = dash_direction * -1
		$Dash_part.emitting = true
		
		var temp_dash_velocity = dash_direction * dash_velocity
		temp_dash_velocity.y *= dash_vertical_multiplier
		velocity = temp_dash_velocity
		
		if direction:
			if direction == -1 and $Icon.flip_h == false:
				$Icon.flip_h = true
			elif direction == 1 and $Icon.flip_h == true:
				$Icon.flip_h = false
		
		$Woosh.play()
		shadow_frame = shadow_first_frame
		_on_start_shadows_timeout()
		$Icon.play("Dash")
		
			
			
		$Dash_part.emitting = true
		during_dash = true
		can_dash = false
		$Dash_dur.start()
		$Dash_cooldown.start()
		
	
	elif not during_dash:
	
		if direction:
			if direction == -1 and $Icon.flip_h == false:
				$Icon.flip_h = true
			elif direction == 1 and $Icon.flip_h == true:
				$Icon.flip_h = false
			
			if abs(velocity.x) <= SPEED + (SPEED / 1.5):
				$Icon.play("Walk")
				velocity.x = move_toward(velocity.x, SPEED * direction, acceleration_walk * delta)
			else:
				_standing(delta)
		else:
			_standing(delta)
	
	
	move_and_slide()
	$Icon.scale.x = move_toward($Icon.scale.x, 1, 0.3 * delta)
	$Icon.scale.y = move_toward($Icon.scale.y, 1, 0.3 * delta)


func _jump():
	$Icon.scale = scale_single_jump
	velocity.y = 0.0
	during_jump = true
	velocity.y += single_jump
	can_jump = false

func _standing(delta):
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, acceleration_walk * delta)
	else:
		velocity.x = move_toward(velocity.x, 0, acceleration_air * delta)
	$Icon.play("Idle")


func _knockback(knock_value):
	knock_value *= 2.0
	
	velocity += knock_value


func _on_dash_dur_timeout() -> void:
	during_dash = false
	if is_on_floor():
		$Icon.play("Idle")
	$Dash_part.emitting = false
	velocity.x = SPEED * sign(velocity.x)

func _on_dash_cooldown_timeout() -> void:
	wait_can_dash = true

func _on_coyote_time_timeout() -> void:
	can_jump = false

func _on_faster_jump_timeout() -> void:
	faster_jump = false

func _on_start_shadows_timeout() -> void:
	var new_shadow = shadow.instantiate()
	new_shadow.global_position = global_position
	new_shadow.frame = shadow_frame
	if $Icon.flip_h:
		new_shadow.flip_h = true
	add_sibling(new_shadow)
	
	if shadow_frame != shadow_last_frame:
		$Start_shadows.start()
	shadow_frame += 1
	
	
func _on_blink_timer_timeout() -> void:
	if $Icon.animation == "Idle":
		$Icon.play("Blink")
	$Blink_timer.start(randf_range(2.0, 5.0))
