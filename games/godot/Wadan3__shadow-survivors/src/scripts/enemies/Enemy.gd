extends CharacterBody2D

signal health_changed(current: float, maximum: float)
signal defeated(enemy: Node)

@export_enum("grunt", "runner", "tank", "elite", "boss") var enemy_kind: String = "grunt"
var max_health: float = 45.0
var health: float = 45.0
var speed: float = 105.0
var contact_damage: float = 10.0
var score_value: int = 100
var xp_value: int = 14
var body_radius: float = 18.0
var wave_strength: float = 1.0
var tint := Color("e83b62")
var player: Node2D
var contact_cooldown: float = 0.0
var hit_flash: float = 0.0
var knockback := Vector2.ZERO
var dead := false
var anim_time := 0.0

const BURST := preload("res://scripts/effects/EffectBurst.gd")

func _ready() -> void:
	add_to_group("enemies")
	collision_layer = 4
	collision_mask = 1 | 2
	motion_mode = CharacterBody2D.MOTION_MODE_FLOATING
	_configure()
	max_health *= wave_strength
	health = max_health
	speed *= 1.0 + (wave_strength - 1.0) * 0.22
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = body_radius
	collision.shape = shape
	add_child(collision)
	player = get_tree().get_first_node_in_group("player") as Node2D
	health_changed.emit(health, max_health)

func _configure() -> void:
	match enemy_kind:
		"runner":
			max_health = 27.0; speed = 190.0; contact_damage = 8.0
			score_value = 135; xp_value = 13; body_radius = 13.0; tint = Color("ff3aa7")
		"tank":
			max_health = 165.0; speed = 61.0; contact_damage = 20.0
			score_value = 300; xp_value = 36; body_radius = 29.0; tint = Color("9c3cff")
		"elite":
			max_health = 235.0; speed = 126.0; contact_damage = 24.0
			score_value = 620; xp_value = 70; body_radius = 25.0; tint = Color("ff2f57")
		"boss":
			max_health = 1800.0; speed = 58.0; contact_damage = 34.0
			score_value = 5000; xp_value = 400; body_radius = 55.0; tint = Color("b31bda")
		_:
			max_health = 52.0; speed = 105.0; contact_damage = 11.0
			score_value = 100; xp_value = 16; body_radius = 18.0; tint = Color("ed365a")

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(player):
		return
	anim_time += delta
	contact_cooldown = maxf(0.0, contact_cooldown - delta)
	hit_flash = maxf(0.0, hit_flash - delta)
	var direction := global_position.direction_to(player.global_position)
	velocity = direction * speed + knockback
	knockback = knockback.move_toward(Vector2.ZERO, 760.0 * delta)
	move_and_slide()
	if global_position.distance_to(player.global_position) < body_radius + 22.0 and contact_cooldown <= 0.0:
		player.take_damage(contact_damage)
		contact_cooldown = 0.85
	queue_redraw()

func take_damage(amount: float, from_direction: Vector2 = Vector2.ZERO) -> void:
	if dead:
		return
	health -= amount
	hit_flash = 0.10
	knockback += from_direction * minf(230.0, amount * 5.0)
	health_changed.emit(maxf(0.0, health), max_health)
	AudioManager.play_hit()
	if health <= 0.0:
		die()

func die() -> void:
	if dead:
		return
	dead = true
	collision_layer = 0
	AudioManager.play_enemy_death()
	BURST.spawn(get_tree().current_scene, global_position, tint, 14 if enemy_kind != "boss" else 32, body_radius)
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("enemy_defeated"):
		game.enemy_defeated(self, score_value, xp_value)
	defeated.emit(self)
	queue_free()

func _draw() -> void:
	var pulse := 1.0 + sin(anim_time * 4.0) * 0.045
	var display := Color.WHITE if hit_flash > 0.0 else tint
	draw_circle(Vector2.ZERO, body_radius * 1.45 * pulse, Color(tint, 0.10))
	var points := PackedVector2Array()
	var sides := 5 if enemy_kind == "runner" else (8 if enemy_kind in ["tank", "elite"] else 6)
	for i in sides:
		var r := body_radius * (1.0 if i % 2 == 0 else 0.82)
		points.append(Vector2.from_angle(TAU * i / sides + anim_time * 0.25) * r)
	draw_colored_polygon(points, Color("210b25"))
	draw_polyline(PackedVector2Array(points + PackedVector2Array([points[0]])), display, 3.0, true)
	draw_circle(Vector2.ZERO, body_radius * 0.35, display)
	var to_player := Vector2.RIGHT
	if is_instance_valid(player):
		to_player = global_position.direction_to(player.global_position)
	draw_circle(to_player * body_radius * 0.45, maxf(2.5, body_radius * 0.13), Color.WHITE)
	if health < max_health and enemy_kind != "boss":
		draw_rect(Rect2(-body_radius, -body_radius - 11.0, body_radius * 2.0, 4.0), Color(0.04, 0.02, 0.08, 0.9))
		draw_rect(Rect2(-body_radius, -body_radius - 11.0, body_radius * 2.0 * health / max_health, 4.0), display)
