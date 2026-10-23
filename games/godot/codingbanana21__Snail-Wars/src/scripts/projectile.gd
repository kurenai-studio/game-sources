class_name Projectile
extends CharacterBody2D

@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var detect_box: Area2D = $DetectBox
@onready var gpu_particles_2d: GPUParticles2D = $GPUParticles2D
@onready var explosion_timer: Timer = $ExplosionTimer
@onready var hit_timer: Timer = $HitTimer

#projectile stats
@export var damage: int = 45
@export var size: int = 5
@export var knockback: int = 50
@export var life_steel: int = 0
@export var speed: int = 60
@export var min_speed: int = 80
@export var gravity: int = 450
@export var projectile_hp: int = 1
@export var hit_stun_time: float = 0.0
@export var timer: float = 3.0
@export var bounce: bool = false
@export var spawn_at_mouse: bool = false
@export var players_projectile: bool = true
@export var end_player_turn: bool = true
@export var teleports_player: bool = false
@export var effect_by_wind: bool = true
@export var spawns: Array[String]

var id: int
var parent: Player
var bodys_needed: int = 1


func _enter_tree() -> void:
	set_multiplayer_authority(id)


func _ready() -> void:
	if players_projectile:
		parent = get_parent()
		
		if !Globals.high_fps_mode:
			gpu_particles_2d.show()
	
	if timer > 0:
		explosion_timer.start(timer)
	
	if collision_shape_2d.shape != null:
		bodys_needed = 2
	
	if min_speed > speed:
		speed = min_speed
	
	#spawn type normal or strike
	if spawn_at_mouse:
		global_position.x = Mouse.global_position.x
		global_position.y = -2148.0
		velocity.y += speed
	else:
		global_position += transform.x * 16.0
		velocity += transform.x * speed


func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	if global_position.y >= Globals.water_level:
		explode(true)
		return
	elif len(detect_box.get_overlapping_bodies()) + len(detect_box.get_overlapping_areas()) >= bodys_needed:
		explode()
	
	if !hit_timer.is_stopped(): return
	
	if players_projectile:
		Mouse.global_position = global_position
	
	velocity.y += gravity * delta
	if effect_by_wind:
		velocity.x += Globals.wind * 16 * delta
	
	rotation = velocity.angle()
	
	var temp_velocity: Vector2 = velocity
	move_and_slide()
	
	if bounce:
		if is_on_floor():
			velocity.x = temp_velocity.x * 0.95
			velocity.y = temp_velocity.y * -0.6
		
		if is_on_wall():
			velocity.x = temp_velocity.x * -0.6
			velocity.y = temp_velocity.y * 0.95


func explode(end_explode: bool = false):
	if !is_multiplayer_authority() or !hit_timer.is_stopped(): return
	
	if hit_stun_time > 0:
		hit_timer.start(hit_stun_time)
	
	projectile_hp -= 1
	
	if !Globals.high_fps_mode:
		Mouse.shake.rpc(damage / 3.0)
	
	if len(spawns) > 0:
		parent.multiplayer_spawner.spawn({
			"id": id,
			"global_position": global_position,
			"projectile": "res://projectiles/" + spawns.pick_random() + ".tscn"
		})
	
	if projectile_hp == 0 or end_explode:
		end_explode = true
		queue_free()
		
		#if the projectile is a players end player turn
		if end_player_turn and players_projectile and parent.player_turn_part != 0:
			parent.next_player_timer.start()
			parent.player_turn_part = 3
			Mouse.global_position = parent.global_position
	
	#get map and explode it
	for map in get_tree().get_nodes_in_group("Map"):
		map.explode_tile.rpc(global_position, size)
	
	#hit players
	for player: Player in get_tree().get_nodes_in_group("Player"):
		var dis_to: float = global_position.distance_to(player.global_position)
		if dis_to < (8.0 * size) + 8.0:
			var hit_power: float = clampf(16.0 / dis_to, 0.01, 1.0)
			player.hit.rpc(int(damage * hit_power), (player.global_position - global_position) * hit_power * knockback)
			
			if players_projectile and life_steel > 0:
				parent.heal.rpc(int(life_steel * hit_power))
	
	if players_projectile:
		parent.bomb.play()
		
		if teleports_player:
			parent.global_position = global_position
		
		if !Globals.high_fps_mode:
			var hit_particle: GPUParticles2D = load("res://scenes/hit_particle.tscn").instantiate()
			hit_particle.global_position = global_position
			hit_particle.emitting = true
			hit_particle.amount = clampi(int(damage), 1, 200)
			parent.add_child(hit_particle)


func _on_explosion_timer_timeout() -> void:
	if !is_multiplayer_authority(): return
	explode(true)
