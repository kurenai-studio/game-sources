extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal xp_changed(current: int, needed: int, level: int)
signal dash_changed(ratio: float)
signal died
signal level_up_requested

@export var max_health: float = 100.0
@export var move_speed: float = 290.0
@export var acceleration: float = 1800.0
@export var fire_interval: float = 0.19
@export var bullet_damage: float = 22.0
@export var bullet_speed: float = 920.0

var health: float
var level: int = 1
var xp: int = 0
var xp_needed: int = 55
var projectile_count: int = 1
var dash_cooldown: float = 2.2
var dash_time: float = 0.0
var dash_remaining: float = 0.0
var fire_remaining: float = 0.0
var invulnerability: float = 0.0
var damage_boost: float = 0.0
var rapid_fire: float = 0.0
var aim_direction := Vector2.RIGHT
var dead := false
var flash := 0.0
var recoil := 0.0

const BULLET_SCENE := preload("res://scenes/projectiles/Bullet.tscn")
const BURST := preload("res://scripts/effects/EffectBurst.gd")

func _ready() -> void:
	add_to_group("player")
	collision_layer = 2
	collision_mask = 1 | 4
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = 19.0
	collision.shape = shape
	add_child(collision)
	health = max_health
	health_changed.emit(health, max_health)
	xp_changed.emit(xp, xp_needed, level)
	queue_redraw()

func _physics_process(delta: float) -> void:
	if dead:
		return
	aim_direction = global_position.direction_to(get_global_mouse_position())
	if aim_direction.length_squared() < 0.01:
		aim_direction = Vector2.RIGHT
	fire_remaining = maxf(0.0, fire_remaining - delta)
	dash_remaining = maxf(0.0, dash_remaining - delta)
	dash_time = maxf(0.0, dash_time - delta)
	invulnerability = maxf(0.0, invulnerability - delta)
	damage_boost = maxf(0.0, damage_boost - delta)
	rapid_fire = maxf(0.0, rapid_fire - delta)
	flash = maxf(0.0, flash - delta)
	recoil = move_toward(recoil, 0.0, delta * 42.0)

	var input_vector := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if Input.is_action_just_pressed("dash") and dash_remaining <= 0.0:
		_start_dash(input_vector)
	var target := input_vector * move_speed
	if dash_time > 0.0:
		target = (input_vector if input_vector != Vector2.ZERO else aim_direction) * move_speed * 3.25
		velocity = target
	else:
		velocity = velocity.move_toward(target, acceleration * delta)
	move_and_slide()

	if Input.is_action_pressed("shoot") and fire_remaining <= 0.0:
		shoot()
	dash_changed.emit(1.0 - dash_remaining / dash_cooldown)
	queue_redraw()

func _start_dash(direction: Vector2) -> void:
	dash_remaining = dash_cooldown
	dash_time = 0.16
	invulnerability = maxf(invulnerability, 0.22)
	AudioManager.play_tone("dash", 230.0, 0.11, 0.25, -11.0)
	BURST.spawn(get_parent(), global_position, Color("38e8ff"), 10, 12.0)
	if direction == Vector2.ZERO:
		velocity = aim_direction * move_speed * 3.25

func shoot() -> void:
	var effective_interval := fire_interval * (0.52 if rapid_fire > 0.0 else 1.0)
	fire_remaining = effective_interval
	recoil = 5.0
	var spread_step := 0.12
	for i in projectile_count:
		var offset := (float(i) - float(projectile_count - 1) * 0.5) * spread_step
		var bullet := BULLET_SCENE.instantiate()
		bullet.direction = aim_direction.rotated(offset)
		bullet.speed = bullet_speed
		bullet.damage = bullet_damage * (1.5 if damage_boost > 0.0 else 1.0)
		bullet.global_position = global_position + bullet.direction * 30.0
		get_tree().current_scene.add_child(bullet)
	AudioManager.play_shoot()
	BURST.spawn(get_tree().current_scene, global_position + aim_direction * 28.0, Color("52f7ff"), 4, 5.0)
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(0.045)

func take_damage(amount: float) -> void:
	if dead or invulnerability > 0.0 or dash_time > 0.0:
		return
	health = maxf(0.0, health - amount)
	invulnerability = 0.72
	flash = 0.18
	health_changed.emit(health, max_health)
	AudioManager.play_player_damage()
	BURST.spawn(get_tree().current_scene, global_position, Color("ff3d72"), 12, 16.0)
	var camera := get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(0.5)
	if health <= 0.0:
		dead = true
		velocity = Vector2.ZERO
		died.emit()

func heal(amount: float) -> void:
	health = minf(max_health, health + amount)
	health_changed.emit(health, max_health)

func gain_xp(amount: int) -> void:
	xp += amount
	if xp >= xp_needed:
		xp -= xp_needed
		level += 1
		xp_needed = int(xp_needed * 1.28 + 12)
		level_up_requested.emit()
		AudioManager.play_level_up()
	xp_changed.emit(xp, xp_needed, level)

func apply_upgrade(id: String) -> void:
	match id:
		"damage": bullet_damage *= 1.2
		"speed": move_speed *= 1.15
		"fire_rate": fire_interval *= 0.8
		"projectile": projectile_count = mini(5, projectile_count + 1)
		"health":
			max_health += 20.0
			health = minf(max_health, health + 20.0)
			health_changed.emit(health, max_health)
		"bullet_speed": bullet_speed *= 1.2
		"dash": dash_cooldown = maxf(0.75, dash_cooldown * 0.8)

func apply_pickup(kind: String) -> void:
	match kind:
		"health": heal(35.0)
		"rapid": rapid_fire = 9.0
		"damage": damage_boost = 9.0

func _draw() -> void:
	var pulse := 1.0 + sin(Time.get_ticks_msec() * 0.008) * 0.05
	var body_color := Color("ffffff") if flash > 0.0 else Color("39dff5")
	if invulnerability > 0.0 and int(invulnerability * 20.0) % 2 == 0:
		body_color.a = 0.4
	draw_circle(Vector2.ZERO, 27.0 * pulse, Color(0.1, 0.9, 1.0, 0.1))
	draw_circle(Vector2.ZERO, 19.0, Color("071b32"))
	draw_arc(Vector2.ZERO, 18.0, 0.0, TAU, 24, body_color, 3.5)
	draw_circle(Vector2.ZERO, 7.0, body_color)
	var weapon_start := aim_direction * (11.0 - recoil)
	draw_line(weapon_start, aim_direction * (31.0 - recoil), Color("d9fbff"), 7.0, true)
	draw_circle(aim_direction * (31.0 - recoil), 4.0, Color("64f6ff"))
	if dash_time > 0.0:
		draw_arc(Vector2.ZERO, 31.0, 0.0, TAU, 28, Color("67f5ff"), 4.0)
