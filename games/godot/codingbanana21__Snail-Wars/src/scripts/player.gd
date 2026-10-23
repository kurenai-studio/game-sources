class_name Player
extends CharacterBody2D

@onready var multiplayer_spawner: MultiplayerSpawner = $MultiplayerSpawner
@onready var snail: Sprite2D = $Snail
@onready var name_label: Label = $NameLabel
@onready var team_label: Label = $TeamLabel
@onready var hp_label: Label = $HpLabel
@onready var shot_bar: TextureProgressBar = $ShotBar
@onready var turn_arrow: Sprite2D = $TurnArrow
@onready var next_player_timer: Timer = $NextPlayerTimer

#sound effects
@onready var ooff: AudioStreamPlayer = $Ooff
@onready var ooff_2: AudioStreamPlayer = $Ooff2
@onready var looser: AudioStreamPlayer = $Looser
@onready var impressive: AudioStreamPlayer = $Impressive
@onready var bomb: AudioStreamPlayer = $Bomb

@export var player_number: int = 0
@export var team_number: int = 0

const SPEED: int = 4
const JUMP: Vector2 = Vector2(120, -300)
const BACK_JUMP: Vector2 = Vector2(-50, -400)
const PLAYER_GRAVITY: int = 30
const NAMES: Array[String] = ["Barry","Bob","Jim","Dave","Rick","Rob","Ray","Nick","Leo"]
const NAMES2: Array[String] = ["Good","Bad","Cool","Best","Dumb","Not","Dead","Same","Super","The","Just","I am"]

var id: int
var rng = RandomNumberGenerator.new()
var projectile_speed: float = 0.0
var hp: int = 100
var weapon: int = 0
var dir: float = 0
var player_turn_part: int = 0
var dead: bool = false
var team_color: Color


func _enter_tree() -> void:
	set_multiplayer_authority(id)
	rng.seed = player_number + (team_number * 10)


func _ready() -> void:
	multiplayer_spawner.spawn_function = shot_projectile
	hp = Globals.player_hp
	hp_label.text = str(hp)
	name_label.text = NAMES2[rng.randi_range(0, NAMES2.size() - 1)] +" "+ NAMES[rng.randi_range(0, NAMES.size() - 1)]
	name_label.modulate = team_color
	team_label.text = "Team "+str(team_number)
	team_label.modulate = team_color
	hp_label.modulate = team_color


func _process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	# skip dead player
	if (dead or global_position.y >= Globals.water_level) and player_turn_part != 0:
		player_turn_part = 0
		hp = 0
		Globals.next_player.rpc(true)
		return
	
	if player_turn_part == 0 or player_turn_part == 4:
		turn_arrow.hide()
		return
	
	turn_arrow.show()
	turn_arrow.position.y = sin(Engine.get_physics_frames() / 5.0) * 3.0 - 16.0
	
	if (global_position > Mouse.global_position and Mouse.moving) or velocity.x < 0:
		snail.flip_h = true
	elif Mouse.moving or velocity.x > 0:
		snail.flip_h = false
	
	if Input.is_action_just_pressed("skip"):
		player_turn_part = 4
		next_player_timer.start(0.1)
	
	if player_turn_part == 1:
		if Input.is_action_pressed("attack") and Globals.teams_weapons[team_number][weapon] != 0:
			shot_bar.rotation = global_position.angle_to_point(Mouse.global_position)
			shot_bar.value = projectile_speed
			projectile_speed += 8.0 * delta
		else:
			if Input.is_action_just_pressed("next_weapon"):
				weapon += 1
			elif Input.is_action_just_pressed("last_weapon"):
				weapon -= 1
				if weapon < 0:
					weapon = 12
			
			weapon %= 13
			Mouse.weapon_amount = Globals.teams_weapons[team_number][weapon]
			Mouse.weapon = weapon
		
		if (Input.is_action_just_released("attack") or projectile_speed >= 10.0) and Globals.teams_weapons[team_number][weapon] != 0:
			multiplayer_spawner.spawn({
				"id": id,
				"global_position": global_position,
				"projectile": "res://projectiles/" + Globals.WEAPONS[weapon] + ".tscn"
			})
			
			Input.action_release("attack")
			Globals.teams_weapons[team_number][weapon] -= 1
			projectile_speed = 0.0
			player_turn_part = 2
			shot_bar.value = 0
			Mouse.hide()
			


func _physics_process(delta: float) -> void:
	if !is_multiplayer_authority(): return
	
	if velocity.y <= 2500.0:
		velocity.y += PLAYER_GRAVITY
	
	if player_turn_part != 0 and player_turn_part != 4 and !Input.is_action_pressed("attack"):
		if is_on_floor():
			dir = Input.get_axis("left", "right")
			velocity.x += dir * SPEED
			
			if Input.is_action_just_pressed("jump"):
				velocity.x += dir * JUMP.x
				velocity.y = JUMP.y
			elif Input.is_action_just_pressed("back_jump"):
				velocity.x += dir * BACK_JUMP.x
				velocity.y = BACK_JUMP.y
		else:
			if Input.is_action_pressed("jump"):
				velocity.x += dir * JUMP.x * delta
			elif Input.is_action_pressed("back_jump"):
				velocity.x += dir * BACK_JUMP.x * delta
	
	var temp_velocity: Vector2 = velocity
	move_and_slide()
	
	if player_turn_part != 0:
		Mouse.global_position += velocity * delta
	
	if is_on_floor():
		if temp_velocity.y >= 750:
			var fall_damage = (temp_velocity.y - 750) / 50.0
			hit(fall_damage)
			
			if !Globals.high_fps_mode:
				Mouse.shake.rpc(fall_damage / 4.0)
		velocity.x *= 0.75
	else:
		velocity.x *= 0.98


func shot_projectile(inputs: Dictionary = {"id":1,
		"global_position":Vector2.ZERO,
		"projectile":"res://projectiles/rocket.tscn"
		}):
	
	var scene: PackedScene = load(inputs["projectile"])
	var new_projectile: Projectile = scene.instantiate()
	
	new_projectile.id = inputs["id"]
	new_projectile.global_position = inputs["global_position"]
	new_projectile.look_at(Mouse.global_position)
	new_projectile.speed *= int(projectile_speed)
	return new_projectile


@rpc("any_peer","reliable","call_local")
func hit(hurt_damage: int, knockback: Vector2 = Vector2.ZERO):
	hp -= hurt_damage
	velocity += knockback
	
	hp_label.text = str(hp)
	var hit_text: Label = load("res://scenes/hit_text.tscn").instantiate()
	hit_text.text = str(hurt_damage)
	add_child(hit_text)
	
	if player_turn_part != 0 and hp < 1:
		impressive.play()
	elif player_turn_part != 0:
		looser.play()
	else:
		if randf() >= 0.35:
			ooff.play()
		else:
			ooff_2.play()
	
	if !is_multiplayer_authority(): return
	
	if player_turn_part != 0:
		Mouse.hide()
		player_turn_part = 4
		next_player_timer.start(1.0)


@rpc("any_peer","reliable","call_local")
func heal(heal_amount: int):
	hp += heal_amount
	
	hp_label.text = str(hp)
	var hit_text: Label = load("res://scenes/hit_text.tscn").instantiate()
	hit_text.text = "+" + str(heal_amount)
	add_child(hit_text)


@rpc("any_peer","call_local","reliable")
func die():
	dead = true
	set_physics_process(false)
	global_position.y = -10000


@rpc("any_peer", "call_local", "reliable")
func next_player(teams_turns, team_turn):
	#remove particles
	for child: Node in get_children():
		if child is GPUParticles2D:
			child.queue_free()
	
	if hp < 1 and !dead and is_multiplayer_authority():
		multiplayer_spawner.spawn({
			"id": id,
			"global_position": global_position,
			"projectile": "res://projectiles/snail.tscn"
		})
		die.rpc()
	
	if teams_turns[team_turn] == player_number and team_number == team_turn:
		player_turn_part = 1
		
		if !dead:
			Mouse.global_position = global_position


func _on_next_player_timer_timeout() -> void:
	if player_turn_part != 0:
		if player_turn_part != 4:
			player_turn_part = 4
			next_player_timer.start(1.0)
		else:
			player_turn_part = 0
			Globals.next_player.rpc()
