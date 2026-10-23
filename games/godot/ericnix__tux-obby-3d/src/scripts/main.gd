extends Node3D
## Controla o estado da partida: menu, timer, mortes, checkpoints, pausa e vitória.

enum State { MENU, PLAYING, PAUSED, WON }

const SAVE_PATH := "user://tux_obby.cfg"

@onready var player: TuxPlayer = $Player
@onready var level: Level = $Level
@onready var hud: Hud = $HUD

var state := State.MENU
var spawn := Vector3.ZERO
var elapsed := 0.0
var deaths := 0
var fish := 0
var current_checkpoint := 0
var respawning := false
var best_time := 0.0
var auto_pause_enabled := true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("game")
	_load_best()

	spawn = level.start_spawn
	player.global_position = spawn
	player.camera_rig.reset_view(0.0)
	player.set_camera_enabled(false)
	player.set_frozen(true)
	player.died.connect(_on_player_died)

	hud.set_time(0.0)
	hud.set_deaths(0)
	hud.set_fish(0, level.total_fish)
	hud.set_checkpoint(0, level.checkpoint_spawns.size() - 1)
	hud.set_best(best_time)
	hud.show_start(best_time)

	hud.play_pressed.connect(start_game)
	hud.resume_pressed.connect(resume_game)
	hud.restart_pressed.connect(restart_level)
	hud.quit_pressed.connect(quit_game)

	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	Sfx.start_music()


func _process(delta: float) -> void:
	if state != State.PLAYING or respawning:
		return
	elapsed += delta
	hud.set_time(elapsed)
	if not player.dead and player.global_position.y < level.kill_y:
		player.kill()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if state == State.PLAYING:
			pause_game()
		elif state == State.PAUSED:
			resume_game()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("quit") and (state == State.PAUSED or state == State.WON):
		quit_game()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("respawn"):
		if state == State.PLAYING:
			manual_respawn()
		elif state == State.PAUSED or state == State.WON:
			restart_level()
		get_viewport().set_input_as_handled()
		return

	if event.is_action_pressed("ui_accept"):
		if state == State.MENU:
			start_game()
		elif state == State.WON:
			restart_level()
		get_viewport().set_input_as_handled()
		return

	if state == State.PLAYING and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		if event is InputEventMouseButton and event.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if auto_pause_enabled and state == State.PLAYING and not respawning:
			pause_game()


# --------------------------------------------------------------------------
# Fluxo de jogo
# --------------------------------------------------------------------------

func start_game() -> void:
	if state != State.MENU:
		return
	state = State.PLAYING
	respawning = false
	hud.hide_start()
	hud.hide_pause()
	hud.hide_win()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.set_camera_enabled(true)
	player.unfreeze()
	Sfx.play("click", -12.0)
	Sfx.unduck_music()


func pause_game() -> void:
	if state != State.PLAYING or respawning:
		return
	state = State.PAUSED
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	player.set_camera_enabled(false)
	hud.show_pause()
	Sfx.play("click", -12.0)
	Sfx.duck_music()


func resume_game() -> void:
	if state != State.PAUSED:
		return
	get_tree().paused = false
	state = State.PLAYING
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	player.set_camera_enabled(true)
	hud.hide_pause()
	Sfx.play("click", -12.0)
	Sfx.unduck_music()


func restart_level() -> void:
	get_tree().paused = false
	Sfx.play("click", -10.0)
	get_tree().reload_current_scene()


func quit_game() -> void:
	get_tree().quit()


func reach_checkpoint(index: int, position: Vector3) -> void:
	if state != State.PLAYING or player.dead or respawning:
		return
	if index <= current_checkpoint:
		return
	current_checkpoint = index
	spawn = position
	hud.set_checkpoint(index, level.checkpoint_spawns.size() - 1)


func collect_fish() -> void:
	if state != State.PLAYING:
		return
	fish += 1
	hud.set_fish(fish, level.total_fish)
	if fish == level.total_fish:
		hud.notify(Loc.t("notify_all_fish"), Color("ffb03a"))


func finish() -> void:
	if state != State.PLAYING or respawning:
		return
	state = State.WON
	player.set_frozen(true)
	player.set_camera_enabled(false)
	player.model.double_jump_spin()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var new_record := best_time <= 0.0 or elapsed < best_time
	if new_record:
		best_time = elapsed
		_save_best()
	hud.set_best(best_time)
	hud.show_win(elapsed, deaths, fish, level.total_fish, new_record, best_time)
	hud.fade_black(0.4, 0.0)
	Sfx.play("win", -3.0)
	Sfx.fade_out_music(1.5)
	_confetti()


func _on_player_died() -> void:
	if state != State.PLAYING or respawning:
		return
	respawning = true
	deaths += 1
	hud.set_deaths(deaths)
	hud.flash_death()
	hud.notify(Loc.t("notify_fall"), Color("ff6262"))
	await get_tree().create_timer(0.6).timeout
	if state != State.PLAYING:
		return
	hud.fade_black(0.2, 0.9)
	await get_tree().create_timer(0.24).timeout
	player.respawn(spawn, 0.0)
	hud.fade_black(0.35, 0.0)
	await get_tree().create_timer(0.18).timeout
	if state == State.PLAYING:
		player.unfreeze()
	respawning = false


func manual_respawn() -> void:
	if state != State.PLAYING or respawning or player.dead:
		return
	respawning = true
	Sfx.play("click", -12.0)
	hud.fade_black(0.18, 1.0)
	await get_tree().create_timer(0.2).timeout
	player.respawn(spawn, 0.0)
	hud.fade_black(0.3, 0.0)
	await get_tree().create_timer(0.15).timeout
	if state == State.PLAYING:
		player.unfreeze()
	respawning = false


# --------------------------------------------------------------------------
# Recordes e efeitos
# --------------------------------------------------------------------------

func _load_best() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		best_time = float(config.get_value("records", "best_time", 0.0))


func _save_best() -> void:
	var config := ConfigFile.new()
	config.set_value("records", "best_time", best_time)
	config.set_value("records", "fish_total", fish)
	config.save(SAVE_PATH)


func _confetti() -> void:
	var colors := [Color("5cf0cc"), Color("ffb03a"), Color("ff7f6e"), Color("b8ef63")]
	for i in colors.size():
		var particles := CPUParticles3D.new()
		particles.one_shot = true
		particles.emitting = false
		particles.amount = 48
		particles.lifetime = 2.6
		particles.explosiveness = 1.0
		particles.direction = Vector3(0, 1, 0)
		particles.spread = 70.0
		particles.initial_velocity_min = 6.0
		particles.initial_velocity_max = 13.0
		particles.gravity = Vector3(0, -11.0, 0)
		particles.scale_amount_min = 0.6
		particles.scale_amount_max = 1.4
		particles.angular_velocity_min = -220.0
		particles.angular_velocity_max = 220.0
		var mesh := BoxMesh.new()
		mesh.size = Vector3(0.12, 0.16, 0.02)
		particles.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = colors[i]
		mat.emission_enabled = true
		mat.emission = colors[i]
		mat.emission_energy_multiplier = 1.4
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		particles.material_override = mat
		particles.position = Vector3(2.0 + (i - 1.5) * 0.9, 18.2, -168.4)
		add_child(particles)
		particles.emitting = true
		get_tree().create_timer(4.0).timeout.connect(particles.queue_free)
