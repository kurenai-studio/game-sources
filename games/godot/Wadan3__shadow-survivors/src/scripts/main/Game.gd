extends Node2D

const PLAYER_SCENE := preload("res://scenes/player/Player.tscn")
const HUD_SCENE := preload("res://scenes/ui/HUD.tscn")
const ARENA_SCRIPT := preload("res://scripts/effects/Arena.gd")
const CAMERA_SCRIPT := preload("res://scripts/effects/CameraRig.gd")
const WAVE_SCRIPT := preload("res://scripts/managers/WaveManager.gd")
const PICKUPS := {
	"health": preload("res://scenes/pickups/HealthPickup.tscn"),
	"rapid": preload("res://scenes/pickups/RapidFirePickup.tscn"),
	"damage": preload("res://scenes/pickups/DamageBoostPickup.tscn")
}

var state: String = "playing"
var player: CharacterBody2D
var enemies: Node2D
var hud: CanvasLayer
var wave_manager: Node
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game")
	rng.randomize()
	_build_world()
	GameManager.start_run()

func _build_world() -> void:
	var arena := ARENA_SCRIPT.new()
	arena.z_index = -20
	add_child(arena)
	enemies = Node2D.new()
	enemies.name = "Enemies"
	add_child(enemies)
	hud = HUD_SCENE.instantiate()
	add_child(hud)
	player = PLAYER_SCENE.instantiate()
	player.health_changed.connect(hud.update_health)
	player.xp_changed.connect(hud.update_xp)
	player.dash_changed.connect(hud.update_dash)
	player.level_up_requested.connect(_show_upgrade)
	player.died.connect(_game_over)
	add_child(player)
	var camera := CAMERA_SCRIPT.new()
	camera.limit_left = -1100
	camera.limit_right = 1100
	camera.limit_top = -700
	camera.limit_bottom = 700
	camera.enabled = true
	player.add_child(camera)
	wave_manager = WAVE_SCRIPT.new()
	wave_manager.setup(self)
	wave_manager.wave_started.connect(hud.announce_wave)
	add_child(wave_manager)
	hud.pause_menu.resume_requested.connect(_resume)
	hud.pause_menu.restart_requested.connect(_restart)
	hud.pause_menu.main_menu_requested.connect(_main_menu)
	hud.game_over.restart_requested.connect(_restart)
	hud.game_over.main_menu_requested.connect(_main_menu)
	hud.upgrade_menu.upgrade_selected.connect(_upgrade_selected)
	hud.announce_wave(1, false)

func _process(_delta: float) -> void:
	if state == "playing":
		hud.update_stats()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()
		if state == "playing":
			_pause()
		elif state == "paused":
			_resume()

func enemy_defeated(enemy: Node, points: int, xp_amount: int) -> void:
	GameManager.add_kill(points)
	if is_instance_valid(player):
		player.gain_xp(xp_amount)
	if enemy.enemy_kind == "boss":
		hud.hide_boss()
	if rng.randf() < (0.16 if enemy.enemy_kind in ["tank", "elite", "boss"] else 0.075):
		_spawn_pickup(enemy.global_position)

func _spawn_pickup(at: Vector2) -> void:
	var roll := rng.randf()
	var kind := "health" if roll < 0.46 else ("rapid" if roll < 0.73 else "damage")
	var pickup_scene: PackedScene = PICKUPS[kind]
	var pickup := pickup_scene.instantiate()
	pickup.global_position = at
	call_deferred("add_child", pickup)

func boss_spawned(boss: Node) -> void:
	hud.show_boss(boss.health, boss.max_health)
	boss.health_changed.connect(hud.show_boss)

func _show_upgrade() -> void:
	if state != "playing":
		return
	state = "upgrade"
	get_tree().paused = true
	hud.upgrade_menu.present()

func _upgrade_selected(id: String) -> void:
	player.apply_upgrade(id)
	state = "playing"
	get_tree().paused = false

func _pause() -> void:
	state = "paused"
	get_tree().paused = true
	hud.pause_menu.visible = true

func _resume() -> void:
	hud.pause_menu.visible = false
	state = "playing"
	get_tree().paused = false

func _game_over() -> void:
	if state == "game_over":
		return
	state = "game_over"
	GameManager.finish_run()
	get_tree().paused = true
	hud.game_over.show_results()

func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _main_menu() -> void:
	GameManager.finish_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main/MainMenu.tscn")
