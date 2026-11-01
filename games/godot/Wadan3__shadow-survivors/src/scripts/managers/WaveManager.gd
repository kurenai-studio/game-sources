extends Node

signal wave_started(number: int, boss_wave: bool)

const GRUNT := preload("res://scenes/enemies/EnemyGrunt.tscn")
const RUNNER := preload("res://scenes/enemies/EnemyRunner.tscn")
const TANK := preload("res://scenes/enemies/EnemyTank.tscn")
const ELITE := preload("res://scenes/enemies/EliteEnemy.tscn")
const BOSS := preload("res://scenes/enemies/Boss.tscn")

var game: Node
var wave: int = 1
var wave_time: float = 0.0
var wave_duration: float = 22.0
var spawn_time: float = 0.7
var boss_spawned_this_wave := false
var rng := RandomNumberGenerator.new()

func setup(game_node: Node) -> void:
	game = game_node

func _ready() -> void:
	rng.randomize()
	wave = 1
	GameManager.wave = wave
	wave_started.emit(wave, false)

func _process(delta: float) -> void:
	if not is_instance_valid(game) or game.get("state") != "playing":
		return
	wave_time += delta
	spawn_time -= delta
	if wave_time >= wave_duration:
		wave += 1
		wave_time = 0.0
		boss_spawned_this_wave = false
		GameManager.wave = wave
		wave_started.emit(wave, wave % 5 == 0)
	if wave % 5 == 0 and not boss_spawned_this_wave:
		boss_spawned_this_wave = true
		_spawn(BOSS)
	if spawn_time <= 0.0 and get_tree().get_nodes_in_group("enemies").size() < mini(58, 18 + wave * 3):
		spawn_time = maxf(0.36, 1.62 - wave * 0.075) * rng.randf_range(0.82, 1.16)
		_spawn(_choose_enemy())

func _choose_enemy() -> PackedScene:
	var roll := rng.randf()
	if wave >= 8 and roll < 0.07 + wave * 0.004:
		return ELITE
	if wave >= 5 and roll < 0.22:
		return TANK
	if wave >= 3 and roll < 0.53:
		return RUNNER
	return GRUNT

func _spawn(scene: PackedScene) -> void:
	if not is_instance_valid(game.player):
		return
	var enemy := scene.instantiate()
	enemy.wave_strength = 1.0 + (wave - 1) * 0.105
	var angle := rng.randf_range(0.0, TAU)
	var distance := rng.randf_range(720.0, 900.0)
	var desired: Vector2 = game.player.global_position + Vector2.from_angle(angle) * distance
	desired.x = clampf(desired.x, -1050.0, 1050.0)
	desired.y = clampf(desired.y, -650.0, 650.0)
	enemy.global_position = desired
	game.enemies.add_child(enemy)

