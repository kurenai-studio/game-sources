extends "res://scripts/enemies/Enemy.gd"

var attack_timer: float = 2.2
var charge_timer: float = 6.0
var charge_time: float = 0.0
var charge_direction := Vector2.ZERO
var attack_cycle: int = 0

const ENEMY_BULLET := preload("res://scenes/projectiles/EnemyProjectile.tscn")

func _ready() -> void:
	enemy_kind = "boss"
	super._ready()
	var game := get_tree().get_first_node_in_group("game")
	if game and game.has_method("boss_spawned"):
		game.boss_spawned(self)

func _physics_process(delta: float) -> void:
	if dead or not is_instance_valid(player):
		return
	attack_timer -= delta
	charge_timer -= delta
	charge_time = maxf(0.0, charge_time - delta)
	if charge_timer <= 0.0:
		charge_timer = 7.0
		charge_time = 0.65
		charge_direction = global_position.direction_to(player.global_position)
		AudioManager.play_tone("boss_charge", 85.0, 0.28, 0.32, -7.0)
	if attack_timer <= 0.0:
		attack_timer = 1.55
		_fire_pattern()
	if charge_time > 0.0:
		var original_speed := speed
		speed = 440.0
		velocity = charge_direction * speed
		move_and_slide()
		speed = original_speed
		anim_time += delta * 3.0
		if global_position.distance_to(player.global_position) < body_radius + 24.0 and contact_cooldown <= 0.0:
			player.take_damage(contact_damage)
			contact_cooldown = 0.7
		contact_cooldown = maxf(0.0, contact_cooldown - delta)
		queue_redraw()
	else:
		super._physics_process(delta)

func _fire_pattern() -> void:
	attack_cycle += 1
	if attack_cycle % 3 == 0:
		for i in 12:
			_spawn_bullet(Vector2.from_angle(TAU * i / 12.0), 285.0, 14.0)
	else:
		var target := global_position.direction_to(player.global_position)
		for offset in [-0.22, 0.0, 0.22]:
			_spawn_bullet(target.rotated(offset), 390.0, 17.0)
	BURST.spawn(get_tree().current_scene, global_position, Color("ff3dc8"), 12, 28.0)

func _spawn_bullet(dir: Vector2, projectile_speed: float, projectile_damage: float) -> void:
	var bullet := ENEMY_BULLET.instantiate()
	bullet.direction = dir
	bullet.speed = projectile_speed
	bullet.damage = projectile_damage
	bullet.radius = 10.0
	bullet.global_position = global_position + dir * (body_radius + 8.0)
	get_tree().current_scene.add_child(bullet)

func _draw() -> void:
	super._draw()
	var ring_color := Color("ff4dd2") if charge_time <= 0.0 else Color.WHITE
	draw_arc(Vector2.ZERO, body_radius + 13.0 + sin(anim_time * 3.0) * 4.0, anim_time, anim_time + PI * 1.55, 32, ring_color, 5.0)
	draw_arc(Vector2.ZERO, body_radius + 23.0, -anim_time * 0.7, -anim_time * 0.7 + PI, 28, Color(0.7, 0.2, 1.0, 0.65), 3.0)
