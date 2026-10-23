extends Node2D

const SHIP_EXPLOSION_SCENE: PackedScene = preload("res://scenes/ship_explosion_fx.tscn")
const LASER_PROJECTILE_SCRIPT: Script = preload("res://scripts/laser_projectile.gd")
const NUKE_BOMB_SCRIPT: Script = preload("res://scripts/nuke_bomb.gd")
const NUKE_EXPLOSION_SCRIPT: Script = preload("res://scripts/nuke_explosion_effect.gd")
const EXPLORER_BEACON_SCRIPT: Script = preload("res://scripts/artifacts/explorer_beacon.gd")
const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")
const GALAXY_CAMERA_CONTROLLER_SCRIPT = preload("res://scripts/galaxy_camera_controller.gd")
const GALAXY_NETWORK_CONTROLLER_SCRIPT = preload("res://scripts/galaxy_network_controller.gd")
const GALAXY_UI_SCRIPT = preload("res://scripts/ui/galaxy_ui.gd")
const OPTIONS_MODAL_SCRIPT: Script = preload("res://scripts/ui/options_modal.gd")
const SHIP_MOVE_TARGET_FX_SCRIPT: Script = preload("res://scripts/ship_move_target_fx.gd")
const COLONY_BEACON_TORPEDO_SCENE: PackedScene = preload("res://scenes/artifacts/colony_beacon_torpedo.tscn")
const MAIN_MENU_BACKGROUND_MUSIC: AudioStream = preload("res://sfx/bg_music_menu.ogg")
const CUSTOM_MOUSE_CURSOR_PATH: String = "res://textures/ui/pointer.png"
const MAIN_MENU_SCENE_PATH: String = "res://scenes/main_menu.tscn"

@export_group("World")
@export_range(1000.0, 200000.0, 100.0) var world_radius: float = 100.0
@export_range(0.1, 1.0, 0.01) var planet_field_spawn_radius_ratio: float = 0.82
@export_range(0.0, 1.0, 0.01) var planet_field_min_separation_ratio: float = 0.22
@export_range(100.0, 50000.0, 100.0) var planet_colonize_range: float = 4200.0

@export var drag_sensitivity: float = 1.0
@export var click_drag_threshold: float = 8.0
@export_range(100.0, 20000.0, 100.0) var keyboard_pan_speed: float = 2400.0
@export_range(0.05, 2.0, 0.01) var min_zoom: float = 0.25
@export_range(0.05, 8.0, 0.01) var max_zoom: float = 2.5
@export_range(0.05, 8.0, 0.01) var default_zoom: float = 1.0
@export_range(0.01, 1.0, 0.01) var zoom_step: float = 0.01
@export_range(0.001, 1.0, 0.001) var trackpad_zoom_step: float = 0.02

@export_group("Camera Shake")
@export_range(0.0, 1.0, 0.01) var ship_damage_camera_shake_intensity: float = 0.28
@export_range(0.0, 1.0, 0.01) var ship_destroyed_camera_shake_intensity: float = 1.0
@export_range(0.0, 1.0, 0.01) var enemy_destroyed_camera_shake_intensity: float = 0.56
@export_range(0.0, 1.0, 0.01) var homing_missile_camera_shake_intensity: float = 0.42
@export_range(0.0, 12000.0, 100.0) var explosion_camera_shake_falloff_distance: float = 3000.0

@export_group("Explosion FX Budget")
@export_range(0, 64, 1) var max_active_explosion_effects: int = 10

@export_group("Fog of War Performance")
@export_range(0.0, 0.5, 0.005) var fog_update_interval: float = 0.12
@export_range(0.0, 1000.0, 1.0) var fog_update_min_ship_motion: float = 160.0
@export_range(1.0, 2000.0, 1.0) var fog_source_reveal_motion_spacing: float = 180.0

@export_group("Level Up UI")
@export_range(8, 48, 1) var level_up_choice_title_font_size: int = 14
@export_range(6, 32, 1) var level_up_choice_description_font_size: int = 8

@onready var camera: Camera2D = $Camera2D
@onready var starfield: Node2D = $Starfield
@onready var planet_field: Node2D = $PlanetField
@onready var asteroid_field: Node2D = $AsteroidField
@onready var ship: Node2D = $Ship
@onready var enemy_field: EnemyField = $EnemyField
@onready var item_field: ItemField = $ItemField
@onready var fx_layer: Node2D = $FXLayer
@onready var fog_of_war: Node = $FogOfWarLayer/FogOfWar
@onready var background_music: AudioStreamPlayer = $BackgroundMusic

@export_group("Progression")
@export_range(1, 999, 1) var starting_xp_to_next_level: int = 5
@export_range(0.0, 2.0, 0.01) var xp_growth_rate_per_level: float = 0.25

@export_range(0.1, 5.0, 0.1) var income_label_duration: float = 1.2
@export_range(0.0, 200.0, 1.0) var income_label_float_distance: float = 75.0

@export_group("Player Death Drops")
@export_range(1, 64, 1) var player_death_xp_box_count: int = 10
@export_range(1, 99, 1) var player_death_xp_per_box: int = 1
@export_range(0.05, 3.0, 0.01) var player_death_xp_splash_duration: float = 3.0
@export_range(0.0, 4000.0, 10.0) var player_death_xp_splash_min_speed: float = 180.0
@export_range(0.0, 4000.0, 10.0) var player_death_xp_splash_max_speed: float = 320.0
@export_range(0.0, 0.25, 0.001) var player_death_xp_splash_stagger: float = 0.05

@export_group("Debug")
@export_range(0.25, 8.0, 0.25) var debug_min_time_scale: float = 0.25
@export_range(0.25, 8.0, 0.25) var debug_max_time_scale: float = 8.0
@export_range(1.1, 4.0, 0.1) var debug_time_scale_step_factor: float = 2.0

signal planet_action_requested(action_name: String, planet: Planet)

var _planets_invaded_count: int = 0
var _planets_total_count: int = 0
var _conquered_planet_ids: Dictionary = {}
var _has_won: bool = false
var _has_winner_sequence_started: bool = false
var _has_game_over: bool = false
var _ship_current_hp: int = 10
var _ship_max_hp: int = 10
var _ship_current_shield_hp: int = 0
var _ship_max_shield_hp: int = 0
var _ship_shield_level: int = 0
var _ship_level: int = 1
var _ship_xp: int = 0
var _ship_xp_to_next_level: int = 5
var _ship_inventory_levels: Dictionary = {}
var _debug_vacuum_radius_visible: bool = false
var _debug_god_mode_enabled: bool = false
var _debug_no_artifact_cooldowns_enabled: bool = false
var _level_up_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _is_level_up_modal_open: bool = false
var _pending_level_up_options: Array[Dictionary] = []
var _queued_level_up_options: Array = []
var _is_fog_of_war_enabled: bool = true
var _camera_controller: RefCounted = GALAXY_CAMERA_CONTROLLER_SCRIPT.new()
var _network_controller: RefCounted = GALAXY_NETWORK_CONTROLLER_SCRIPT.new()
var _ui: RefCounted = GALAXY_UI_SCRIPT.new()
var _custom_mouse_cursor_texture: Texture2D
var _active_planet: Planet
var _colonizing_planet_ids: Dictionary = {}
var _debug_hud_update_accumulator: float = 0.0
var _pending_artifact_placement_kind: StringName = &""
var _artifact_placement_preview: Node2D
var _pending_enemy_fog_reveal_positions: Array[Vector2] = []
var _enemy_fog_reveal_flush_queued: bool = false
var _fog_update_accumulator: float = 0.0
var _last_fog_update_ship_position: Vector2 = Vector2.ZERO
var _has_fog_update_ship_position: bool = false
var _fog_source_reveal_keys: Dictionary = {}
var _options_modal: OptionsModal

const DEBUG_HUD_UPDATE_INTERVAL: float = 0.25
const ARTIFACT_PLACEMENT_FEEDBACK_DURATION: float = 0.72
const ARTIFACT_PLACEMENT_FEEDBACK_END_SCALE: float = 0.06
const COLONY_BEACON_LANDING_SURFACE_RATIO: float = 0.36
const COLONY_BEACON_TORPEDO_IMPACT_RADIUS: float = 700.0
const COLONY_BEACON_TORPEDO_TRAVEL_SPEED: float = 1500.0
const PLANET_FOG_VISIBILITY_SAMPLE_COUNT: int = 16
const PLANET_FOG_VISIBILITY_EDGE_RATIO: float = 0.96
const EFFECT_FOG_VISIBILITY_SAMPLE_COUNT: int = 32
const EFFECT_FOG_VISIBILITY_EDGE_RATIO: float = 0.96
const ASTEROID_XP_SPLASH_GOLDEN_ANGLE: float = 2.399963229728653

func _ready() -> void:
	_level_up_rng.randomize()
	_configure_mouse_cursor()
	_configure_camera_controller()
	_network_controller.configure(self)
	_configure_ui()
	_ensure_options_modal()
	_camera_controller.setup()
	_connect_enemy_reward_signals()
	_connect_asteroid_reward_signals()
	_connect_enemy_wave_signals()
	_connect_ship_health_signals()
	_apply_debug_vacuum_radius_visibility()
	_apply_debug_god_mode()
	_apply_debug_no_artifact_cooldowns()
	_sync_starfield()
	_configure_fog_of_war()
	_reveal_fog_of_war()
	_ship_level = 1
	_ship_xp = 0
	_ship_xp_to_next_level = max(starting_xp_to_next_level, 1)
	_planets_total_count = _get_total_planet_count()
	_refresh_top_bar()
	_update_debug_hud()
	_update_winner_message()
	queue_redraw()
	_network_controller.setup()


func _configure_mouse_cursor() -> void:
	var cursor_file: FileAccess = FileAccess.open(CUSTOM_MOUSE_CURSOR_PATH, FileAccess.READ)
	if cursor_file == null:
		push_warning("Could not load custom mouse cursor: %s" % CUSTOM_MOUSE_CURSOR_PATH)
		return

	var cursor_image: Image = Image.new()
	var load_error: Error = cursor_image.load_png_from_buffer(cursor_file.get_buffer(cursor_file.get_length()))
	if load_error != OK:
		push_warning("Could not decode custom mouse cursor: %s" % CUSTOM_MOUSE_CURSOR_PATH)
		return

	_custom_mouse_cursor_texture = ImageTexture.create_from_image(cursor_image)
	Input.set_custom_mouse_cursor(_custom_mouse_cursor_texture, Input.CURSOR_ARROW, Vector2.ZERO)


func _configure_ui() -> void:
	_ui.configure(self)
	_ui.set("level_up_choice_title_font_size", level_up_choice_title_font_size)
	_ui.set("level_up_choice_description_font_size", level_up_choice_description_font_size)
	_ui.restart_requested.connect(_on_restart_button_pressed)
	_ui.invade_requested.connect(_on_invade_button_pressed)
	_ui.level_up_choice_requested.connect(_on_level_up_choice_pressed)
	_ui.debug_slow_down_requested.connect(_on_debug_slow_down_pressed)
	_ui.debug_speed_up_requested.connect(_on_debug_speed_up_pressed)
	_ui.debug_stop_requested.connect(_on_debug_stop_pressed)
	_ui.debug_resume_requested.connect(_on_debug_resume_pressed)
	_ui.debug_add_xp_requested.connect(_add_debug_xp)
	_ui.debug_spawn_requested.connect(_spawn_debug_enemies)
	_ui.debug_fog_toggle_requested.connect(_on_debug_toggle_fog_pressed)
	_ui.debug_vacuum_radius_toggled.connect(_on_debug_toggle_vacuum_radius_toggled)
	_ui.debug_god_mode_toggled.connect(_on_debug_god_mode_toggled)
	_ui.debug_no_artifact_cooldowns_toggled.connect(_on_debug_no_artifact_cooldowns_toggled)
	_ui.debug_item_requested.connect(_on_debug_item_button_pressed)
	_ui.debug_force_win_requested.connect(_on_debug_force_win_pressed)
	_ui.artifact_activation_requested.connect(_on_artifact_activation_requested)
	_ui.artifact_placement_cancel_requested.connect(_cancel_artifact_placement)
	_ui.winner_fade_finished.connect(_play_winner_background_music)
	_ui.setup()
	_ui.exit_to_main_menu_requested.connect(_on_exit_to_main_menu_button_pressed)



func _configure_camera_controller() -> void:
	_camera_controller.configure(
		self,
		camera,
		starfield,
		ship,
		Callable(self, "get_world_radius"),
		Callable(self, "_is_game_over_active"),
		Callable(self, "_move_ship_to_world_position")
	)
	_camera_controller.drag_sensitivity = drag_sensitivity
	_camera_controller.click_drag_threshold = click_drag_threshold
	_camera_controller.keyboard_pan_speed = keyboard_pan_speed
	_camera_controller.min_zoom = min_zoom
	_camera_controller.max_zoom = max_zoom
	_camera_controller.default_zoom = default_zoom
	_camera_controller.zoom_step = zoom_step
	_camera_controller.trackpad_zoom_step = trackpad_zoom_step
	_camera_controller.shake_falloff_distance = explosion_camera_shake_falloff_distance


func _is_game_over_active() -> bool:
	return _has_game_over


func _connect_enemy_reward_signals() -> void:
	if enemy_field == null:
		return

	var enemy_destroyed_callable := Callable(self, "_on_enemy_destroyed")
	if enemy_field.has_signal("enemy_destroyed") and not enemy_field.is_connected("enemy_destroyed", enemy_destroyed_callable):
		enemy_field.connect("enemy_destroyed", enemy_destroyed_callable)

	var enemy_damage_taken_callable := Callable(self, "_on_enemy_damage_taken")
	if enemy_field.has_signal("enemy_damage_taken") and not enemy_field.is_connected("enemy_damage_taken", enemy_damage_taken_callable):
		enemy_field.connect("enemy_damage_taken", enemy_damage_taken_callable)


func _connect_asteroid_reward_signals() -> void:
	if asteroid_field == null:
		return

	var asteroid_destroyed_callable := Callable(self, "_on_asteroid_destroyed")
	if asteroid_field.has_signal("asteroid_destroyed") and not asteroid_field.is_connected("asteroid_destroyed", asteroid_destroyed_callable):
		asteroid_field.connect("asteroid_destroyed", asteroid_destroyed_callable)


func _on_asteroid_destroyed(xp_amount: int, world_position: Vector2, asteroid: Node2D) -> void:
	var xp_per_box := maxi(xp_amount, 0)
	var box_count := 1
	if asteroid != null and is_instance_valid(asteroid) and asteroid.has_method("get_xp_box_count"):
		box_count = maxi(int(asteroid.call("get_xp_box_count")), 1)

	_spawn_enemy_explosion(asteroid)
	_spawn_asteroid_xp_boxes(world_position, xp_per_box, box_count)
	_queue_enemy_fog_reveal(world_position)


func _spawn_asteroid_xp_boxes(world_position: Vector2, xp_per_box: int, box_count: int) -> void:
	if xp_per_box <= 0 or box_count <= 0:
		return

	if _network_controller.is_server():
		for index in box_count:
			_network_controller.spawn_xp_box(_get_asteroid_xp_box_position(world_position, index), xp_per_box)
		return

	if _network_controller.is_client():
		return

	if item_field == null or not item_field.has_method("spawn_xp_box"):
		return

	for index in box_count:
		var box_position := _get_asteroid_xp_box_position(world_position, index)
		var direction := (box_position - world_position).normalized()
		if direction == Vector2.ZERO:
			direction = Vector2.RIGHT.rotated(float(index) * ASTEROID_XP_SPLASH_GOLDEN_ANGLE)
		item_field.call(
			"spawn_xp_box",
			box_position,
			xp_per_box,
			world_position,
			direction * randf_range(120.0, 260.0),
			randf_range(0.32, 0.58),
			float(index) * 0.025,
			true
		)


func _get_asteroid_xp_box_position(world_position: Vector2, index: int) -> Vector2:
	var angle := float(index) * ASTEROID_XP_SPLASH_GOLDEN_ANGLE + randf_range(-0.18, 0.18)
	var distance := randf_range(28.0, 82.0) * sqrt(float(index) + 1.0)
	return world_position + Vector2.RIGHT.rotated(angle) * distance


func _connect_enemy_wave_signals() -> void:
	if enemy_field == null:
		return

	var wave_state_callable := Callable(self, "_on_enemy_wave_state_changed")
	if enemy_field.has_signal("wave_state_changed") and not enemy_field.is_connected("wave_state_changed", wave_state_callable):
		enemy_field.connect("wave_state_changed", wave_state_callable)


func _on_enemy_destroyed(xp_amount: int, world_position: Vector2, enemy: Node2D) -> void:
	var total_xp := maxi(xp_amount, 0)
	if _network_controller.is_server():
		_spawn_enemy_explosion(enemy)
		_network_controller.enemy_destroyed(enemy, world_position, total_xp)
		return

	_spawn_enemy_explosion(enemy)
	if item_field != null and item_field.has_method("spawn_xp_box"):
		item_field.call("spawn_xp_box", world_position, total_xp)
	_queue_enemy_fog_reveal(world_position)


func _on_enemy_damage_taken(amount: int, world_position: Vector2, _enemy: Node2D) -> void:
	_spawn_damage_label(world_position, amount)


func _queue_enemy_fog_reveal(world_position: Vector2) -> void:
	if fog_of_war == null:
		return
	if not fog_of_war.has_method("reveal_discs_at_world_positions") and not fog_of_war.has_method("reveal_disc_at_world_position"):
		return

	_pending_enemy_fog_reveal_positions.append(world_position)
	if _enemy_fog_reveal_flush_queued:
		return

	_enemy_fog_reveal_flush_queued = true
	call_deferred("_flush_pending_enemy_fog_reveals")


func _flush_pending_enemy_fog_reveals() -> void:
	_enemy_fog_reveal_flush_queued = false
	if _pending_enemy_fog_reveal_positions.is_empty():
		return

	var reveal_positions := _pending_enemy_fog_reveal_positions.duplicate()
	_pending_enemy_fog_reveal_positions.clear()
	if fog_of_war == null:
		return
	if fog_of_war.has_method("reveal_discs_at_world_positions"):
		fog_of_war.call("reveal_discs_at_world_positions", reveal_positions)
		return
	if fog_of_war.has_method("reveal_disc_at_world_position"):
		for world_position in reveal_positions:
			fog_of_war.call("reveal_disc_at_world_position", world_position)


func _on_enemy_wave_state_changed(time_left: float, next_wave_size: int) -> void:
	_update_enemy_wave_ui(time_left, next_wave_size)


func get_world_radius() -> float:
	return maxf(world_radius, 1.0)


func get_planet_field_spawn_radius() -> float:
	return get_world_radius() * clampf(planet_field_spawn_radius_ratio, 0.0, 1.0)


func get_planet_field_min_separation() -> float:
	return get_world_radius() * maxf(planet_field_min_separation_ratio, 0.0)


func is_fog_of_war_enabled() -> bool:
	return _is_fog_of_war_enabled


func can_place_artifact_at(item_kind: StringName, world_position: Vector2) -> bool:
	if item_kind == ItemPickup.ITEM_VORTEX:
		var preview_radius := _get_artifact_preview_radius(item_kind)
		return not is_vortex_placement_blocked_by_planet(world_position, preview_radius)

	return true


func is_vortex_placement_blocked_by_planet(world_position: Vector2, vortex_radius: float) -> bool:
	if planet_field == null:
		return false

	var safe_vortex_radius := maxf(vortex_radius, 0.0)
	for child in planet_field.get_children():
		var planet := child as Planet
		if planet == null:
			continue

		var planet_radius := maxf(planet.get_touch_radius(), 0.0)
		if planet.global_position.distance_to(world_position) <= safe_vortex_radius + planet_radius:
			return true

	return false


func _process(_delta: float) -> void:
	_update_artifact_placement_preview()
	if _network_controller.is_enabled():
		if _network_controller.is_server():
			_network_controller.process_server(_delta)
		elif _network_controller.is_client():
			_network_controller.process_client(_delta)
		_refresh_artifact_cooldowns_ui()
		return

	_refresh_artifact_cooldowns_ui()
	_camera_controller.set_ship(ship)
	_camera_controller.process(_delta)
	if _has_game_over:
		return

	_process_fog_of_war(_delta)
	_update_planet_action_popover()
	_update_planet_hover_tooltip()
	_process_debug_hud(_delta)


func _unhandled_input(event: InputEvent) -> void:
	if _try_handle_artifact_placement_input(event):
		return

	if _try_handle_options_input(event):
		return

	if _try_handle_artifact_shortcut(event):
		return

	if _camera_controller.handle_unhandled_input(event):
		return


func _try_handle_options_input(event: InputEvent) -> bool:
	if _options_modal != null and _options_modal.visible:
		get_viewport().set_input_as_handled()
		return true

	if _has_game_over or _is_level_up_modal_open or _is_text_input_focused():
		return false
	if not event.is_action_pressed("pause"):
		return false

	_open_options_modal()
	get_viewport().set_input_as_handled()
	return true


func _try_handle_artifact_shortcut(event: InputEvent) -> bool:
	var key_event := event as InputEventKey
	if key_event == null or not key_event.pressed or key_event.echo:
		return false
	if _has_game_over or _is_level_up_modal_open or _is_text_input_focused():
		return false

	var shortcut_index := _get_artifact_shortcut_index(key_event)
	if shortcut_index < 0:
		return false

	var item_kind: StringName = _ui.get_artifact_kind_at_shortcut(shortcut_index)
	if item_kind == &"":
		return false

	_request_artifact_activation(item_kind)
	return true


func _get_artifact_shortcut_index(key_event: InputEventKey) -> int:
	var shortcut_index := _get_artifact_shortcut_index_for_keycode(key_event.keycode)
	if shortcut_index >= 0:
		return shortcut_index

	return _get_artifact_shortcut_index_for_keycode(key_event.physical_keycode)


func _get_artifact_shortcut_index_for_keycode(keycode: int) -> int:
	match keycode:
		KEY_1:
			return 0
		KEY_2:
			return 1
		KEY_3:
			return 2
		KEY_4:
			return 3
		KEY_5:
			return 4
		KEY_6:
			return 5
		KEY_7:
			return 6
		KEY_8:
			return 7
		KEY_9:
			return 8
		_:
			return -1


func _is_text_input_focused() -> bool:
	var focus_owner := get_viewport().gui_get_focus_owner()
	return focus_owner is LineEdit or focus_owner is TextEdit


func _try_handle_artifact_placement_input(event: InputEvent) -> bool:
	if _pending_artifact_placement_kind == &"":
		return false

	var key_event := event as InputEventKey
	if key_event != null and key_event.pressed and not key_event.echo and key_event.keycode == KEY_ESCAPE:
		_cancel_artifact_placement()
		get_viewport().set_input_as_handled()
		return true

	var mouse_event := event as InputEventMouseButton
	if mouse_event == null or not mouse_event.pressed:
		return false

	if mouse_event.button_index == MOUSE_BUTTON_LEFT:
		_place_pending_artifact(get_global_mouse_position())
		get_viewport().set_input_as_handled()
		return true

	if mouse_event.button_index == MOUSE_BUTTON_RIGHT:
		_cancel_artifact_placement()
		get_viewport().set_input_as_handled()
		return true

	return false


func request_ship_move_to_world_position(world_position: Vector2, show_feedback: bool = true) -> void:
	_move_ship_to_world_position(world_position, show_feedback)


func _move_ship_to_world_position(world_position: Vector2, show_feedback: bool = true) -> void:
	if _has_game_over:
		return

	var target_world_position := _clamp_to_galaxy_bounds(world_position)
	if show_feedback:
		_spawn_ship_move_target_feedback(target_world_position)

	if _network_controller.is_client():
		_network_controller.request_move(target_world_position)
		return

	if ship != null and is_instance_valid(ship) and ship.has_method("move_to"):
		ship.call("move_to", target_world_position)


func _spawn_ship_move_target_feedback(world_position: Vector2) -> void:
	var target_parent: Node = fx_layer if fx_layer != null and is_instance_valid(fx_layer) else self
	var use_canvas_overlay := false
	if fog_of_war != null and is_instance_valid(fog_of_war):
		var fog_layer := fog_of_war.get_parent()
		if fog_layer != null and is_instance_valid(fog_layer):
			target_parent = fog_layer
			use_canvas_overlay = true

	var target_fx := SHIP_MOVE_TARGET_FX_SCRIPT.new() as Node2D
	target_parent.add_child(target_fx)
	if use_canvas_overlay and target_fx.has_method("configure_canvas_overlay"):
		target_fx.z_index = 10
		target_fx.call("configure_canvas_overlay", world_position)
	elif target_fx.has_method("configure"):
		target_fx.call("configure", world_position)
	else:
		target_fx.global_position = world_position


func _clamp_to_galaxy_bounds(world_position: Vector2) -> Vector2:
	var radius := get_world_radius()
	return Vector2(
		clampf(world_position.x, -radius, radius),
		clampf(world_position.y, -radius, radius)
	)


func _set_ship_selected(is_selected: bool) -> void:
	_camera_controller.set_ship(ship)
	_camera_controller.set_ship_selected(is_selected)


func _center_camera_on_ship() -> void:
	_camera_controller.set_ship(ship)
	_camera_controller.center_on_ship()

func center_camera_on_world_position(world_position: Vector2) -> void:
	_camera_controller.center_on_world_position(world_position)

func _sync_starfield() -> void:
	_camera_controller.sync_starfield()


func request_camera_shake(intensity: float, source_world_position: Vector2 = Vector2.ZERO) -> void:
	_shake_camera_from_world_position(intensity, source_world_position)


func _shake_camera(intensity: float) -> void:
	if _camera_controller != null and _camera_controller.has_method("shake"):
		_camera_controller.call("shake", intensity)


func _shake_camera_from_world_position(intensity: float, source_world_position: Vector2) -> void:
	if _camera_controller != null and _camera_controller.has_method("shake_from_world_position"):
		_camera_controller.call("shake_from_world_position", intensity, source_world_position)


func _configure_fog_of_war() -> void:
	if fog_of_war == null:
		return

	var fog_half_extent: float = get_world_radius()
	if planet_field != null and planet_field.has_method("get"):
		var planet_field_spawn_radius: float = float(planet_field.get("spawn_radius"))
		var visible_radius: float = float(fog_of_war.get("visible_radius"))
		fog_half_extent = maxf(fog_half_extent, planet_field_spawn_radius + visible_radius * 2.0)

	fog_of_war.call("set_world_half_extent", fog_half_extent)
	_apply_fog_of_war_enabled_state(true)


func _apply_fog_of_war_enabled_state(reset_reveal: bool = false) -> void:
	if fog_of_war == null:
		return

	fog_of_war.set("visible", _is_fog_of_war_enabled)
	if _is_fog_of_war_enabled:
		if reset_reveal:
			_clear_fog_reveal_cache()
			fog_of_war.call("reset_reveal")
		_reset_fog_update_schedule()
		_update_fog_of_war()
	else:
		_update_planet_fog_visibility()
		_update_enemy_fog_visibility()
		_update_item_fog_visibility()
		_update_fx_fog_visibility()


func _process_fog_of_war(delta: float) -> void:
	if fog_of_war == null or ship == null or not _is_fog_of_war_enabled:
		return

	_fog_update_accumulator += maxf(delta, 0.0)
	var update_interval := maxf(fog_update_interval, 0.0)
	var should_update := update_interval <= 0.0 or not _has_fog_update_ship_position
	if not should_update and fog_update_min_ship_motion > 0.0:
		var motion_threshold_squared := fog_update_min_ship_motion * fog_update_min_ship_motion
		should_update = _last_fog_update_ship_position.distance_squared_to(ship.global_position) >= motion_threshold_squared
	if not should_update:
		should_update = _fog_update_accumulator >= update_interval
	if not should_update:
		return

	_reset_fog_update_schedule()
	_reveal_fog_of_war()


func _reset_fog_update_schedule() -> void:
	_fog_update_accumulator = 0.0
	if ship == null:
		_has_fog_update_ship_position = false
		return

	_last_fog_update_ship_position = ship.global_position
	_has_fog_update_ship_position = true


func _reveal_fog_of_war() -> void:
	_update_fog_of_war()


func _reset_fog_of_war_reveal() -> void:
	_clear_fog_reveal_cache()
	_reset_fog_update_schedule()
	if fog_of_war != null and fog_of_war.has_method("reset_reveal"):
		fog_of_war.call("reset_reveal")
	_update_fog_of_war()


func _update_fog_of_war() -> void:
	if fog_of_war == null or ship == null or not _is_fog_of_war_enabled:
		_update_planet_fog_visibility()
		_update_enemy_fog_visibility()
		_update_item_fog_visibility()
		_update_fx_fog_visibility()
		return

	if fog_of_war.has_method("begin_visibility_update"):
		fog_of_war.call("begin_visibility_update")

	var ship_vision_radius := _get_ship_vision_radius()
	if fog_of_war.has_method("reveal_at_world_position"):
		fog_of_war.call("reveal_at_world_position", ship.global_position, ship_vision_radius)
	if fog_of_war.has_method("add_visibility_source"):
		fog_of_war.call("add_visibility_source", ship.global_position, ship_vision_radius)

	_add_conquered_planet_fog_sources()
	_add_explorer_beacon_fog_sources()

	if fog_of_war.has_method("commit_visibility_update"):
		fog_of_war.call("commit_visibility_update")

	_update_planet_fog_visibility()
	_update_enemy_fog_visibility()
	_update_item_fog_visibility()
	_update_fx_fog_visibility()


func _add_conquered_planet_fog_sources() -> void:
	if planet_field == null or fog_of_war == null:
		return

	for child in planet_field.get_children():
		var planet := child as Planet
		if planet == null or not planet.is_conquered():
			continue

		var planet_visibility_radius := planet.get_visibility_radius()
		if (
			fog_of_war.has_method("reveal_disc_at_world_position")
			and _should_reveal_fog_source(planet, planet.global_position, planet_visibility_radius, 0.0)
		):
			fog_of_war.call("reveal_disc_at_world_position", planet.global_position, planet_visibility_radius)
		if fog_of_war.has_method("add_visibility_source"):
			fog_of_war.call("add_visibility_source", planet.global_position, planet_visibility_radius)


func _add_explorer_beacon_fog_sources() -> void:
	if fog_of_war == null or get_tree() == null:
		return

	for beacon_node in get_tree().get_nodes_in_group(&"explorer_beacons"):
		var beacon := beacon_node as Node2D
		if beacon == null or not is_instance_valid(beacon):
			continue
		if not _should_use_beacon_as_local_vision_source(beacon):
			continue

		var beacon_vision_radius := 1800.0
		if beacon.has_method("get_vision_radius"):
			beacon_vision_radius = maxf(float(beacon.call("get_vision_radius")), 1.0)
		if (
			fog_of_war.has_method("reveal_disc_at_world_position")
			and _should_reveal_fog_source(
				beacon,
				beacon.global_position,
				beacon_vision_radius,
				fog_source_reveal_motion_spacing
			)
		):
			fog_of_war.call("reveal_disc_at_world_position", beacon.global_position, beacon_vision_radius)
		if fog_of_war.has_method("add_visibility_source"):
			fog_of_war.call("add_visibility_source", beacon.global_position, beacon_vision_radius)


func _should_reveal_fog_source(source: Node, world_position: Vector2, radius: float, motion_spacing: float) -> bool:
	var source_id := 0
	if source != null:
		source_id = source.get_instance_id()

	var spacing := maxf(motion_spacing, 0.0)
	var position_bucket := Vector2i.ZERO
	if spacing > 0.0:
		position_bucket = Vector2i(
			floori(world_position.x / spacing),
			floori(world_position.y / spacing)
		)
	var radius_bucket := roundi(maxf(radius, 0.0))
	var reveal_key := "%d:%d:%d:%d" % [
		source_id,
		position_bucket.x,
		position_bucket.y,
		radius_bucket,
	]
	if _fog_source_reveal_keys.has(reveal_key):
		return false

	_fog_source_reveal_keys[reveal_key] = true
	return true


func _clear_fog_reveal_cache() -> void:
	_fog_source_reveal_keys.clear()


func _should_use_beacon_as_local_vision_source(beacon: Node2D) -> bool:
	if beacon == null or not is_instance_valid(beacon):
		return false
	if beacon.has_method("is_destroyed") and bool(beacon.call("is_destroyed")):
		return false
	if not _network_controller.is_enabled():
		return true
	if not beacon.has_method("get_owner_peer_id"):
		return false

	return int(beacon.call("get_owner_peer_id")) == _network_controller.get_local_peer_id()


func _update_enemy_fog_visibility() -> void:
	if enemy_field != null:
		for child in enemy_field.get_children():
			var enemy := child as Enemy
			if enemy == null:
				continue

			_set_enemy_fog_presentation(enemy, _get_active_vision_alpha_for_fog(enemy.global_position))

	if asteroid_field != null:
		for child in asteroid_field.get_children():
			var asteroid := child as Node2D
			if asteroid == null:
				continue

			_set_fog_restricted_presentation(asteroid, _get_active_vision_alpha_for_fog(asteroid.global_position))

	_update_other_player_fog_visibility()


func _update_planet_fog_visibility() -> void:
	if planet_field == null:
		return

	for child in planet_field.get_children():
		var planet := child as Planet
		if planet == null:
			continue

		var alpha := _get_planet_explored_alpha_for_fog(planet)
		if planet.has_method("set_fog_presentation_alpha"):
			planet.call("set_fog_presentation_alpha", alpha)
		else:
			_set_canvas_item_fog_alpha(planet, alpha)


func _update_item_fog_visibility() -> void:
	if item_field == null:
		return

	for child in item_field.get_children():
		var item := child as ItemPickup
		if item == null:
			continue

		_set_fog_restricted_presentation(item, _get_active_vision_alpha_for_fog(item.global_position))


func _update_fx_fog_visibility() -> void:
	if fx_layer == null:
		return

	for child in fx_layer.get_children():
		var missile := child as HomingMissile
		if missile != null:
			_set_fog_restricted_presentation(missile, _get_active_vision_alpha_for_fog(missile.global_position))
			continue

		var laser_projectile := child as Node2D
		if laser_projectile != null and laser_projectile.get_script() == LASER_PROJECTILE_SCRIPT:
			_set_fog_restricted_presentation(laser_projectile, _get_active_vision_alpha_for_fog(laser_projectile.global_position))
			continue

		var explosion := child as ShipExplosionFx
		if explosion != null:
			_set_fog_restricted_presentation(explosion, _get_active_vision_alpha_for_fog(explosion.global_position))
			continue

		var vortex := child as VortexEffect
		if vortex != null:
			_set_fog_restricted_presentation(vortex, _get_active_vision_alpha_for_fog(vortex.global_position))
			continue

		var nuke_bomb := child as Node2D
		if nuke_bomb != null and nuke_bomb.get_script() == NUKE_BOMB_SCRIPT:
			_set_fog_restricted_presentation(nuke_bomb, _get_active_vision_alpha_for_fog(nuke_bomb.global_position))
			continue

		var nuke_explosion := child as Node2D
		if nuke_explosion != null and nuke_explosion.get_script() == NUKE_EXPLOSION_SCRIPT:
			_configure_nuke_explosion_fog_mask(nuke_explosion)
			_set_fog_restricted_presentation(nuke_explosion, _get_nuke_explosion_active_vision_alpha(nuke_explosion))
			continue

		var explorer_beacon := child as Node2D
		if explorer_beacon != null and explorer_beacon.get_script() == EXPLORER_BEACON_SCRIPT:
			_set_fog_restricted_presentation(explorer_beacon, _get_active_vision_alpha_for_fog(explorer_beacon.global_position))


func _set_enemy_fog_presentation(enemy: Enemy, alpha: float) -> void:
	if enemy == null:
		return

	_set_fog_restricted_presentation(enemy, alpha)


func _should_show_enemy_for_fog(world_position: Vector2) -> bool:
	if fog_of_war == null or not _is_fog_of_war_enabled:
		return true

	if fog_of_war.has_method("is_world_position_in_active_vision"):
		return bool(fog_of_war.call("is_world_position_in_active_vision", world_position))

	return true


func _get_active_vision_alpha_for_fog(world_position: Vector2) -> float:
	if fog_of_war == null or not _is_fog_of_war_enabled:
		return 1.0

	if fog_of_war.has_method("get_world_position_active_vision_alpha"):
		return float(fog_of_war.call("get_world_position_active_vision_alpha", world_position))

	return 1.0 if _should_show_enemy_for_fog(world_position) else 0.0


func _get_active_vision_alpha_for_fog_radius(world_position: Vector2, radius: float) -> float:
	var alpha := _get_active_vision_alpha_for_fog(world_position)
	var sample_radius := maxf(radius, 0.0) * EFFECT_FOG_VISIBILITY_EDGE_RATIO
	if sample_radius <= 0.0:
		return alpha

	for sample_index in EFFECT_FOG_VISIBILITY_SAMPLE_COUNT:
		var angle := TAU * float(sample_index) / float(EFFECT_FOG_VISIBILITY_SAMPLE_COUNT)
		var sample_position := world_position + Vector2.RIGHT.rotated(angle) * sample_radius
		alpha = maxf(alpha, _get_active_vision_alpha_for_fog(sample_position))
		if alpha >= 1.0:
			return 1.0

	return alpha


func _get_nuke_explosion_active_vision_alpha(nuke_explosion: Node2D) -> float:
	var fog_radius := 0.0
	if nuke_explosion != null and nuke_explosion.has_method("get_fog_presentation_radius"):
		fog_radius = maxf(float(nuke_explosion.call("get_fog_presentation_radius")), 0.0)

	return _get_active_vision_alpha_for_fog_radius(nuke_explosion.global_position, fog_radius)


func _configure_nuke_explosion_fog_mask(nuke_explosion: Node2D) -> void:
	if nuke_explosion == null or not nuke_explosion.has_method("set_fog_visibility_mask"):
		return

	if fog_of_war == null or not _is_fog_of_war_enabled:
		nuke_explosion.call("set_fog_visibility_mask", null, Vector2.ZERO, Vector2.ONE, false)
		_set_nuke_explosion_particle_fog_alpha(nuke_explosion, 1.0)
		return

	if (
		not fog_of_war.has_method("get_visibility_mask_texture")
		or not fog_of_war.has_method("get_world_bounds_min")
		or not fog_of_war.has_method("get_world_bounds_max")
	):
		nuke_explosion.call("set_fog_visibility_mask", null, Vector2.ZERO, Vector2.ONE, false)
		_set_nuke_explosion_particle_fog_alpha(nuke_explosion, _get_active_vision_alpha_for_fog(nuke_explosion.global_position))
		return

	nuke_explosion.call(
		"set_fog_visibility_mask",
		fog_of_war.call("get_visibility_mask_texture") as Texture2D,
		fog_of_war.call("get_world_bounds_min") as Vector2,
		fog_of_war.call("get_world_bounds_max") as Vector2,
		true
	)
	_set_nuke_explosion_particle_fog_alpha(nuke_explosion, _get_active_vision_alpha_for_fog(nuke_explosion.global_position))


func _set_nuke_explosion_particle_fog_alpha(nuke_explosion: Node2D, alpha: float) -> void:
	if nuke_explosion != null and nuke_explosion.has_method("set_particle_fog_presentation_alpha"):
		nuke_explosion.call("set_particle_fog_presentation_alpha", alpha)


func _get_explored_alpha_for_fog(world_position: Vector2) -> float:
	if fog_of_war == null or not _is_fog_of_war_enabled:
		return 1.0

	if fog_of_war.has_method("get_world_position_explored_alpha"):
		return float(fog_of_war.call("get_world_position_explored_alpha", world_position))

	if fog_of_war.has_method("is_world_position_visible"):
		return 1.0 if bool(fog_of_war.call("is_world_position_visible", world_position)) else 0.0

	return 1.0


func _get_ship_vision_radius() -> float:
	var base_radius := 900.0
	if fog_of_war != null:
		base_radius = maxf(float(fog_of_war.get("visible_radius")), 1.0)

	if ship != null and is_instance_valid(ship) and ship.has_method("get_vision_radius"):
		return maxf(float(ship.call("get_vision_radius", base_radius)), 1.0)

	return base_radius


func _set_canvas_item_fog_alpha(node: CanvasItem, alpha: float) -> void:
	if node == null:
		return

	var resolved_alpha := clampf(alpha, 0.0, 1.0)
	node.visible = resolved_alpha > 0.01
	var color := node.modulate
	color.a = resolved_alpha
	node.modulate = color


func _set_fog_restricted_presentation(node: CanvasItem, alpha: float) -> void:
	if node == null:
		return

	var resolved_alpha := clampf(alpha, 0.0, 1.0)
	if node.has_method("set_fog_presentation_alpha"):
		node.call("set_fog_presentation_alpha", resolved_alpha)
		return

	if node.has_method("set_fog_presentation_visible"):
		node.call("set_fog_presentation_visible", resolved_alpha > 0.01)
		return

	_set_canvas_item_fog_alpha(node, resolved_alpha)


func _update_other_player_fog_visibility() -> void:
	var tree := get_tree()
	if tree == null:
		return

	for player_node in tree.get_nodes_in_group(&"player_ships"):
		var player_ship := player_node as Node2D
		if player_ship == null or player_ship == ship:
			continue

		if player_ship.has_method("is_destroyed") and bool(player_ship.call("is_destroyed")):
			_set_other_player_fog_presentation(player_ship, false)
			continue

		_set_other_player_fog_presentation_alpha(player_ship, _get_other_player_ship_fog_alpha(player_ship))


func _set_other_player_fog_presentation(player_ship: Node2D, is_visible: bool) -> void:
	_set_other_player_fog_presentation_alpha(player_ship, 1.0 if is_visible else 0.0)


func _set_other_player_fog_presentation_alpha(player_ship: Node2D, alpha: float) -> void:
	if player_ship == null:
		return

	if player_ship.has_method("set_fog_presentation_alpha"):
		player_ship.call("set_fog_presentation_alpha", alpha, Callable(self, "_should_show_enemy_for_fog"))
		return

	if player_ship.has_method("set_fog_presentation_visible"):
		player_ship.call("set_fog_presentation_visible", alpha > 0.01, Callable(self, "_should_show_enemy_for_fog"))
		return

	_set_canvas_item_fog_alpha(player_ship, alpha)


func _get_other_player_ship_fog_alpha(player_ship: Node2D) -> float:
	if player_ship == null:
		return 0.0

	if bool(player_ship.get("is_local_player")):
		return 1.0

	return _get_active_vision_alpha_for_fog(player_ship.global_position)


func _connect_ship_health_signals() -> void:
	if ship == null:
		return

	if ship.has_signal("hp_changed"):
		var hp_changed_callable: Callable = Callable(self, "_on_ship_hp_changed")
		if not ship.is_connected("hp_changed", hp_changed_callable):
			ship.connect("hp_changed", hp_changed_callable)

	if ship.has_signal("died"):
		var died_callable: Callable = Callable(self, "_on_ship_died")
		if not ship.is_connected("died", died_callable):
			ship.connect("died", died_callable)

	if ship.has_signal("experience_collected"):
		var xp_collected_callable: Callable = Callable(self, "_on_ship_experience_collected")
		if not ship.is_connected("experience_collected", xp_collected_callable):
			ship.connect("experience_collected", xp_collected_callable)

	if ship.has_signal("inventory_changed"):
		var inventory_changed_callable: Callable = Callable(self, "_on_ship_inventory_changed")
		if not ship.is_connected("inventory_changed", inventory_changed_callable):
			ship.connect("inventory_changed", inventory_changed_callable)

	if ship.has_signal("shield_changed"):
		var shield_changed_callable: Callable = Callable(self, "_on_ship_shield_changed")
		if not ship.is_connected("shield_changed", shield_changed_callable):
			ship.connect("shield_changed", shield_changed_callable)

	_sync_ship_hp_from_ship()
	_sync_ship_shield_from_ship()
	_refresh_ship_hp_ui()
	_sync_ship_inventory_from_ship()
	_refresh_inventory_ui()


func _sync_ship_hp_from_ship() -> void:
	if ship == null:
		return

	if ship.has_method("get_hit_points"):
		_ship_current_hp = max(int(ship.call("get_hit_points")), 0)

	if ship.has_method("get_max_hit_points"):
		_ship_max_hp = max(int(ship.call("get_max_hit_points")), 1)


func _refresh_ship_hp_ui() -> void:
	_ui.refresh_ship_hp(_ship_current_hp, _ship_max_hp)
	_ui.refresh_ship_shield(_ship_current_shield_hp, _ship_max_shield_hp, _ship_shield_level)


func _sync_ship_shield_from_ship() -> void:
	if ship == null:
		return

	if ship.has_method("get_shield_hit_points"):
		_ship_current_shield_hp = max(int(ship.call("get_shield_hit_points")), 0)

	if ship.has_method("get_max_shield_hit_points"):
		_ship_max_shield_hp = max(int(ship.call("get_max_shield_hit_points")), 0)

	if ship.has_method("get_shield_level"):
		_ship_shield_level = max(int(ship.call("get_shield_level")), 0)


func _refresh_xp_ui() -> void:
	_ui.refresh_xp(_ship_xp, _ship_xp_to_next_level, _is_level_up_modal_open)


func _sync_ship_inventory_from_ship() -> void:
	if ship == null or not is_instance_valid(ship):
		return

	if ship.has_method("get_inventory_levels"):
		var inventory: Dictionary = ship.call("get_inventory_levels")
		if inventory is Dictionary:
			_ship_inventory_levels = inventory.duplicate(true)


func _refresh_inventory_ui() -> void:
	_ui.refresh_inventory(_ship_inventory_levels)
	_refresh_artifact_cooldowns_ui()


func _refresh_artifact_cooldowns_ui() -> void:
	if ship == null or not is_instance_valid(ship) or not ship.has_method("get_artifact_cooldown_states"):
		_ui.refresh_artifact_cooldowns({})
		return

	var cooldown_states: Dictionary = ship.call("get_artifact_cooldown_states")
	_ui.refresh_artifact_cooldowns(cooldown_states)


func _refresh_enemy_wave_ui() -> void:
	if enemy_field == null or not is_instance_valid(enemy_field) or not enemy_field.has_method("get_wave_time_left"):
		_ui.clear_enemy_wave()
		return

	_update_enemy_wave_ui(
		float(enemy_field.call("get_wave_time_left")),
		int(enemy_field.call("get_next_wave_size"))
	)


func _update_enemy_wave_ui(time_left: float, next_wave_size: int) -> void:
	_ui.refresh_enemy_wave(time_left, next_wave_size, _has_game_over)


func _on_ship_hp_changed(current_hp: int, max_hp: int) -> void:
	var previous_hp := _ship_current_hp
	_ship_current_hp = max(current_hp, 0)
	_ship_max_hp = max(max_hp, 1)
	if _ship_current_hp < previous_hp and previous_hp > 0:
		_shake_camera(ship_damage_camera_shake_intensity)
	_refresh_top_bar()


func _on_ship_shield_changed(current_shield_hp: int, max_shield_hp: int, shield_level: int) -> void:
	_ship_current_shield_hp = max(current_shield_hp, 0)
	_ship_max_shield_hp = max(max_shield_hp, 0)
	_ship_shield_level = max(shield_level, 0)
	_refresh_ship_hp_ui()


func _on_ship_experience_collected(amount: int, world_position: Vector2) -> void:
	add_xp(amount, world_position)


func _on_ship_inventory_changed(inventory: Dictionary) -> void:
	_ship_inventory_levels = inventory.duplicate(true)
	_ship_shield_level = maxi(int(_ship_inventory_levels.get(&"shield", _ship_shield_level)), 0)
	_refresh_inventory_ui()


func _on_ship_died() -> void:
	_shake_camera(ship_destroyed_camera_shake_intensity)
	_release_all_conquered_planets()
	_activate_game_over()


func _activate_game_over() -> void:
	if _has_game_over:
		return

	_has_game_over = true
	_deactivate_winner_sequence(false)
	_close_level_up_modal()
	_set_ship_selected(false)
	_spawn_ship_explosion()
	if ship != null and is_instance_valid(ship) and ship.has_method("hide"):
		ship.hide()
	_refresh_top_bar()
	_update_debug_hud()
	_update_end_messages()


func _deactivate_game_over() -> void:
	if not _has_game_over:
		return

	_has_game_over = false
	_deactivate_winner_sequence(false)
	_close_level_up_modal()
	_update_debug_hud()
	_update_end_messages()


func _activate_winner_sequence() -> void:
	if _has_winner_sequence_started:
		return

	_has_winner_sequence_started = true
	_close_level_up_modal()
	_hide_planet_action_popover()
	_hide_planet_hover_tooltip()
	_cancel_artifact_placement()
	_set_ship_selected(false)
	_set_game_paused(true)
	_ui.play_winner_sequence()


func _deactivate_winner_sequence(should_unpause: bool = true) -> void:
	if not _has_winner_sequence_started:
		return

	_has_winner_sequence_started = false
	_ui.hide_winner_sequence()
	if should_unpause:
		_set_game_paused(false)


func _release_all_conquered_planets() -> void:
	_conquered_planet_ids.clear()
	_planets_invaded_count = 0
	_has_won = false
	_deactivate_winner_sequence(false)

	if planet_field != null:
		for child in planet_field.get_children():
			var planet := child as Planet
			if planet == null or not planet.is_conquered():
				continue

			planet.set_conquered(false)

	_refresh_top_bar()


func _spawn_ship_explosion() -> void:
	if fx_layer == null or ship == null:
		return

	var fog_alpha := _get_active_vision_alpha_for_fog(ship.global_position)
	if fog_alpha <= 0.01:
		return

	request_camera_shake(ship_destroyed_camera_shake_intensity, ship.global_position)
	if not ShipExplosionFx.can_spawn_active_explosion(get_tree(), max_active_explosion_effects):
		return

	var explosion := SHIP_EXPLOSION_SCENE.instantiate() as Node2D
	if explosion == null:
		return

	fx_layer.add_child(explosion)
	if explosion.has_method("configure_from_ship"):
		explosion.call("configure_from_ship", ship)
	_set_fog_restricted_presentation(explosion, fog_alpha)


func _spawn_enemy_explosion(enemy: Node2D) -> void:
	if fx_layer == null or enemy == null or not is_instance_valid(enemy):
		return

	var explosion_scale := 1.0
	if enemy is Enemy:
		explosion_scale = maxf((enemy as Enemy).explosion_size, 0.1)
	else:
		explosion_scale = maxf(_get_optional_float_property(enemy, &"explosion_size", explosion_scale), 0.1)
	var fog_alpha := _get_active_vision_alpha_for_fog(enemy.global_position)
	if fog_alpha <= 0.01:
		return

	request_camera_shake(_get_enemy_explosion_camera_shake_intensity(explosion_scale), enemy.global_position)
	if not ShipExplosionFx.can_spawn_active_explosion(get_tree(), max_active_explosion_effects):
		return

	var explosion := SHIP_EXPLOSION_SCENE.instantiate() as Node2D
	if explosion == null:
		return

	fx_layer.add_child(explosion)
	if explosion.has_method("configure_from_enemy"):
		explosion.call("configure_from_enemy", enemy, explosion_scale)
	_set_fog_restricted_presentation(explosion, fog_alpha)


func _get_enemy_explosion_camera_shake_intensity(explosion_scale: float) -> float:
	return clampf(enemy_destroyed_camera_shake_intensity * sqrt(maxf(explosion_scale, 0.1)), 0.0, 1.0)


func _get_optional_float_property(node: Object, property_name: StringName, fallback: float) -> float:
	if node == null:
		return fallback

	for property in node.get_property_list():
		if StringName(property.get("name", "")) == property_name:
			return float(node.get(property_name))

	return fallback


func network_server_started() -> void:
	_network_controller.network_server_started()


func network_connected_to_server() -> void:
	_network_controller.network_connected_to_server()


func network_peer_connected(_peer_id: int) -> void:
	pass


func network_peer_disconnected(peer_id: int) -> void:
	_network_controller.network_peer_disconnected(peer_id)


func network_server_disconnected() -> void:
	_network_controller.network_server_disconnected()


@rpc("any_peer", "call_remote", "reliable")
func server_request_join(requested_name: String) -> void:
	_network_controller.server_request_join(requested_name, multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "unreliable_ordered", 0)
func server_request_move(world_position: Vector2) -> void:
	_network_controller.server_request_move(world_position, multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func server_request_invade(planet_network_id: int) -> void:
	_network_controller.server_request_invade(planet_network_id, multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func server_request_level_up_choice(option_index: int) -> void:
	_network_controller.server_request_level_up_choice(option_index, multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func server_request_artifact_activation(item_kind_name: String) -> void:
	_network_controller.server_request_artifact_activation(StringName(item_kind_name), multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func server_request_artifact_activation_at(item_kind_name: String, world_position: Vector2) -> void:
	_network_controller.server_request_artifact_activation_at(StringName(item_kind_name), world_position, multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func server_request_debug_item(item_kind_name: String) -> void:
	_network_controller.server_request_debug_item(StringName(item_kind_name), multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func server_request_debug_enemies(spawn_count: int) -> void:
	_network_controller.server_request_debug_enemies(spawn_count, multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func server_request_debug_god_mode(enabled: bool) -> void:
	_network_controller.server_request_debug_god_mode(enabled, multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func server_request_debug_no_artifact_cooldowns(enabled: bool) -> void:
	_network_controller.server_request_debug_no_artifact_cooldowns(enabled, multiplayer.get_remote_sender_id())


@rpc("any_peer", "call_remote", "reliable")
func server_request_restart() -> void:
	_network_controller.server_request_restart(multiplayer.get_remote_sender_id())


@rpc("authority", "call_remote", "reliable")
func client_receive_initial_state(state: Dictionary) -> void:
	_network_controller.client_receive_initial_state(state)


@rpc("authority", "call_remote", "reliable")
func client_player_joined(player_state: Dictionary) -> void:
	_network_controller.client_player_joined(player_state)


@rpc("authority", "call_remote", "reliable")
func client_player_left(peer_id: int) -> void:
	_network_controller.client_player_left(peer_id)


@rpc("authority", "call_remote", "reliable")
func client_player_state(player_state: Dictionary) -> void:
	_network_controller.client_player_state(player_state)


@rpc("authority", "call_remote", "reliable")
func client_item_spawned(item_state: Dictionary) -> void:
	_network_controller.client_item_spawned(item_state)


@rpc("authority", "call_remote", "reliable")
func client_item_removed(item_network_id: int) -> void:
	_network_controller.client_item_removed(item_network_id)


@rpc("authority", "call_remote", "reliable")
func client_level_up_options(options: Array, player_state: Dictionary) -> void:
	_network_controller.client_level_up_options(options, player_state)


@rpc("authority", "call_remote", "reliable")
func client_match_ended(winner_peer_id: int, winner_name: String) -> void:
	_network_controller.client_match_ended(winner_peer_id, winner_name)


@rpc("authority", "call_remote", "unreliable_ordered", 1)
func client_apply_snapshot(snapshot: Dictionary) -> void:
	_network_controller.client_apply_snapshot(snapshot)


@rpc("authority", "call_remote", "reliable")
func client_ship_weapon_fired(peer_id: int, target_world_position: Vector2) -> void:
	_network_controller.client_ship_weapon_fired(peer_id, target_world_position)


@rpc("authority", "call_remote", "reliable")
func client_ship_drone_weapon_fired(peer_id: int, drone_index: int, target_world_position: Vector2) -> void:
	_network_controller.client_ship_drone_weapon_fired(peer_id, drone_index, target_world_position)


@rpc("authority", "call_remote", "reliable")
func client_ship_homing_missile_fired(payload: Dictionary) -> void:
	_network_controller.client_ship_homing_missile_fired(payload)


@rpc("authority", "call_remote", "reliable")
func client_ship_vortex_spawned(payload: Dictionary) -> void:
	_network_controller.client_ship_vortex_spawned(payload)


@rpc("authority", "call_remote", "reliable")
func client_ship_nuke_launched(payload: Dictionary) -> void:
	_network_controller.client_ship_nuke_launched(payload)


@rpc("authority", "call_remote", "reliable")
func client_explorer_beacon_launched(payload: Dictionary) -> void:
	_network_controller.client_explorer_beacon_launched(payload)


@rpc("authority", "call_remote", "reliable")
func client_explorer_beacon_destroyed(network_id: int) -> void:
	_network_controller.client_explorer_beacon_destroyed(network_id)


@rpc("authority", "call_remote", "reliable")
func client_colony_beacon_deployed(peer_id: int, planet_network_id: int, launch_origin: Vector2, launch_direction: Vector2) -> void:
	_network_controller.client_colony_beacon_deployed(peer_id, planet_network_id, launch_origin, launch_direction)


@rpc("authority", "call_remote", "reliable")
func client_ship_destroyed(peer_id: int, world_position: Vector2, world_rotation: float) -> void:
	_network_controller.client_ship_destroyed(peer_id, world_position, world_rotation)


@rpc("authority", "call_remote", "reliable")
func client_enemy_beam_fired(enemy_network_id: int, target_world_position: Vector2) -> void:
	_network_controller.client_enemy_beam_fired(enemy_network_id, target_world_position)


@rpc("authority", "call_remote", "reliable")
func client_enemy_destroyed(enemy_network_id: int, scene_key: StringName, world_position: Vector2, world_rotation: float) -> void:
	_network_controller.client_enemy_destroyed(enemy_network_id, scene_key, world_position, world_rotation)


func _on_restart_button_pressed() -> void:
	if _network_controller.is_enabled():
		_network_controller.request_restart()
		return

	_deactivate_winner_sequence(false)
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_exit_to_main_menu_button_pressed() -> void:
	_deactivate_winner_sequence(false)
	get_tree().paused = false

	var network_session := get_node_or_null("/root/NetworkSession")
	if network_session != null and network_session.has_method("leave_session"):
		network_session.call("leave_session")

	var error := get_tree().change_scene_to_file(MAIN_MENU_SCENE_PATH)
	if error != OK:
		push_error("Could not return to main menu: %s" % MAIN_MENU_SCENE_PATH)


func _ensure_options_modal() -> void:
	if _options_modal != null and is_instance_valid(_options_modal):
		return

	var ui_layer := get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		return

	_options_modal = OPTIONS_MODAL_SCRIPT.new() as OptionsModal
	_options_modal.name = "OptionsModal"
	_options_modal.z_index = 2400
	_options_modal.close_requested.connect(_on_options_modal_close_requested)
	_options_modal.main_menu_requested.connect(_on_options_modal_main_menu_requested)
	_options_modal.exit_game_requested.connect(_on_options_modal_exit_game_requested)
	ui_layer.add_child(_options_modal)
	_options_modal.set_main_menu_button_visible(true)


func _open_options_modal() -> void:
	_ensure_options_modal()
	if _options_modal == null:
		return

	_hide_planet_action_popover()
	_hide_planet_hover_tooltip()
	_set_game_paused(true)
	_keep_background_music_playing()
	_options_modal.open()


func _on_options_modal_close_requested() -> void:
	if _has_winner_sequence_started:
		return
	_set_game_paused(false)


func _on_options_modal_main_menu_requested() -> void:
	if _options_modal != null:
		_options_modal.close()
	_on_exit_to_main_menu_button_pressed()


func _on_options_modal_exit_game_requested() -> void:
	if _options_modal != null:
		_options_modal.close()
	_deactivate_winner_sequence(false)
	get_tree().paused = false
	var network_session := get_node_or_null("/root/NetworkSession")
	if network_session != null and network_session.has_method("leave_session"):
		network_session.call("leave_session")

	get_tree().quit()


func _keep_background_music_playing() -> void:
	if background_music == null:
		return

	background_music.process_mode = Node.PROCESS_MODE_ALWAYS
	background_music.stream_paused = false


func _play_winner_background_music() -> void:
	if background_music == null:
		return

	background_music.process_mode = Node.PROCESS_MODE_ALWAYS
	background_music.bus = "Music"
	background_music.stream_paused = false
	if background_music.stream != MAIN_MENU_BACKGROUND_MUSIC:
		background_music.stream = MAIN_MENU_BACKGROUND_MUSIC
		if AudioSettings != null and AudioSettings.has_method("play_music_when_ready"):
			AudioSettings.play_music_when_ready(background_music)
		else:
			background_music.play()
	elif not background_music.playing:
		if AudioSettings != null and AudioSettings.has_method("play_music_when_ready"):
			AudioSettings.play_music_when_ready(background_music)
		else:
			background_music.play()


func _update_planet_action_popover() -> void:
	var touching_planet := _get_touching_planet()
	if touching_planet == null:
		_hide_planet_action_popover()
		return

	_active_planet = touching_planet
	_ui.show_planet_action_popover(
		touching_planet,
		_world_to_screen_position(touching_planet.global_position),
		get_viewport_rect().size,
		_get_colony_beacon_count() > 0
	)


func _get_hovered_planet() -> Planet:
	if planet_field == null:
		return null

	var hovered_control := get_viewport().gui_get_hovered_control()
	if hovered_control != null:
		return null

	var closest_planet: Planet
	var closest_distance := INF
	var mouse_world_position := get_global_mouse_position()

	for child in planet_field.get_children():
		var planet := child as Planet
		if planet == null:
			continue

		var planet_touch_radius := planet.get_touch_radius()
		if planet_touch_radius <= 0.0:
			continue
		if not _is_planet_visible(planet):
			continue

		var distance_to_mouse := mouse_world_position.distance_to(planet.global_position)
		if distance_to_mouse > planet_touch_radius:
			continue

		if distance_to_mouse < closest_distance:
			closest_distance = distance_to_mouse
			closest_planet = planet

	return closest_planet


func _update_planet_hover_tooltip() -> void:
	var hovered_planet := _get_hovered_planet()
	if hovered_planet == null:
		_hide_planet_hover_tooltip()
		return

	var touching_planet := _get_touching_planet()
	if touching_planet != null and touching_planet == hovered_planet:
		_hide_planet_hover_tooltip()
		return

	_ui.show_planet_hover_tooltip(
		hovered_planet,
		get_viewport().get_mouse_position(),
		get_viewport_rect().size
	)


func _get_touching_planet() -> Planet:
	if planet_field == null or ship == null:
		return null

	var closest_planet: Planet
	var closest_distance := INF

	for child in planet_field.get_children():
		var planet := child as Planet
		if planet == null:
			continue

		var planet_touch_radius := planet.get_touch_radius()
		if planet_touch_radius <= 0.0:
			continue
		if not _is_planet_visible(planet):
			continue

		var distance_to_ship := ship.global_position.distance_to(planet.global_position)
		if not _is_ship_in_planet_colonize_range(planet, distance_to_ship):
			continue

		if distance_to_ship < closest_distance:
			closest_distance = distance_to_ship
			closest_planet = planet

	return closest_planet


func _is_ship_in_planet_colonize_range(planet: Planet, distance_to_ship: float = -1.0) -> bool:
	if planet == null or ship == null or not is_instance_valid(ship):
		return false

	var resolved_distance := distance_to_ship
	if resolved_distance < 0.0:
		resolved_distance = ship.global_position.distance_to(planet.global_position)

	return resolved_distance <= planet.get_touch_radius() + maxf(planet_colonize_range, 0.0)


func _get_touch_radius(node: Node) -> float:
	if node != null and node.has_method("get_touch_radius"):
		return float(node.call("get_touch_radius"))

	return 0.0


func _is_planet_visible(planet: Planet) -> bool:
	if planet == null:
		return false

	if fog_of_war == null or not _is_fog_of_war_enabled:
		return true

	if not fog_of_war.has_method("is_world_position_visible"):
		return true

	if bool(fog_of_war.call("is_world_position_visible", planet.global_position)):
		return true

	var planet_radius := planet.get_touch_radius()
	if planet_radius <= 0.0:
		return false

	var sample_radius := planet_radius * PLANET_FOG_VISIBILITY_EDGE_RATIO
	for sample_index in PLANET_FOG_VISIBILITY_SAMPLE_COUNT:
		var angle := TAU * float(sample_index) / float(PLANET_FOG_VISIBILITY_SAMPLE_COUNT)
		var sample_position := planet.global_position + Vector2.RIGHT.rotated(angle) * sample_radius
		if bool(fog_of_war.call("is_world_position_visible", sample_position)):
			return true

	return false


func _get_planet_explored_alpha_for_fog(planet: Planet) -> float:
	var alpha := _get_explored_alpha_for_fog(planet.global_position)
	var planet_radius := planet.get_touch_radius()
	if planet_radius <= 0.0:
		return alpha

	var sample_radius := planet_radius * PLANET_FOG_VISIBILITY_EDGE_RATIO
	for sample_index in PLANET_FOG_VISIBILITY_SAMPLE_COUNT:
		var angle := TAU * float(sample_index) / float(PLANET_FOG_VISIBILITY_SAMPLE_COUNT)
		var sample_position := planet.global_position + Vector2.RIGHT.rotated(angle) * sample_radius
		alpha = maxf(alpha, _get_explored_alpha_for_fog(sample_position))

	return alpha


func _world_to_screen_position(world_position: Vector2) -> Vector2:
	return _camera_controller.world_to_screen_position(world_position)


func _hide_planet_action_popover() -> void:
	_active_planet = null
	_ui.hide_planet_action_popover()


func _hide_planet_hover_tooltip() -> void:
	_ui.hide_planet_hover_tooltip()


func _on_invade_button_pressed() -> void:
	_handle_planet_action("Invade")


func _handle_planet_action(action_name: String) -> void:
	if _active_planet == null:
		_hide_planet_action_popover()
		return

	if _network_controller.is_client():
		if action_name == "Invade":
			_network_controller.request_invade(_active_planet.network_id)
		planet_action_requested.emit(action_name, _active_planet)
		_hide_planet_action_popover()
		return

	if action_name == "Invade":
		if not _try_invade_planet(_active_planet):
			_hide_planet_action_popover()
			return

	planet_action_requested.emit(action_name, _active_planet)
	_hide_planet_action_popover()


func add_xp(amount: int, source_world_position: Vector2 = Vector2.ZERO) -> void:
	if amount <= 0 or _has_game_over:
		return

	_ship_xp += amount
	_spawn_xp_label(source_world_position, amount)
	_consume_ready_level_ups()
	_refresh_top_bar()


func _queue_level_up_choice(options: Array[Dictionary]) -> void:
	if options.is_empty() or _has_game_over:
		return

	GAME_SFX.play(self, GAME_SFX.CUE_LEVEL_UP)
	if _is_level_up_modal_open or not _pending_level_up_options.is_empty():
		_queued_level_up_options.append(options.duplicate(true))
		return

	_is_level_up_modal_open = true
	_pending_level_up_options = options.duplicate(true)
	_hide_planet_action_popover()
	_hide_planet_hover_tooltip()
	_show_level_up_modal()


func _consume_ready_level_ups() -> void:
	if _has_game_over:
		return

	while _ship_xp >= _ship_xp_to_next_level:
		var level_up_options := _get_level_up_options()
		if level_up_options.is_empty():
			return

		var xp_threshold := _ship_xp_to_next_level
		_ship_xp = maxi(_ship_xp - xp_threshold, 0)
		_ship_level += 1
		_ship_xp_to_next_level = _get_next_xp_threshold(_ship_level)
		_queue_level_up_choice(level_up_options)


func _show_next_queued_level_up_choice() -> void:
	if _is_level_up_modal_open or _queued_level_up_options.is_empty() or _has_game_over:
		return

	var next_options: Array = _queued_level_up_options.pop_front()
	var typed_options: Array[Dictionary] = []
	for option in next_options:
		if option is Dictionary:
			typed_options.append((option as Dictionary).duplicate(true))
	_queue_level_up_choice(typed_options)
	_refresh_top_bar()


func _get_level_up_options() -> Array[Dictionary]:
	if item_field == null:
		return []

	if item_field.has_method("get_random_upgrade_options"):
		return _decorate_level_up_options(item_field.call("get_random_upgrade_options", 3, _level_up_rng))

	return []


func _decorate_level_up_options(options: Array[Dictionary]) -> Array[Dictionary]:
	var decorated_options: Array[Dictionary] = []
	for option in options:
		var decorated_option := option.duplicate(true)
		if ship != null and is_instance_valid(ship) and ship.has_method("get_upgrade_preview"):
			var item_kind: StringName = StringName(decorated_option.get("item_kind", ItemPickup.ITEM_LASER))
			var item_level: int = maxi(int(decorated_option.get("item_level", 1)), 1)
			var repair_amount: int = maxi(int(decorated_option.get("repair_amount", 4)), 0)
			var preview: Dictionary = ship.call("get_upgrade_preview", item_kind, item_level, repair_amount)
			for preview_key in preview.keys():
				decorated_option[preview_key] = preview[preview_key]
		else:
			decorated_option["title"] = str(decorated_option.get("title", "Upgrade"))
			decorated_option["summary"] = str(decorated_option.get("description", ""))
			decorated_option["tooltip"] = str(decorated_option.get("description", ""))
		decorated_options.append(decorated_option)

	return decorated_options


func _show_level_up_modal() -> void:
	_ui.show_level_up_modal(_ship_level, _pending_level_up_options)


func _hide_level_up_modal() -> void:
	_is_level_up_modal_open = false
	_pending_level_up_options.clear()
	_ui.hide_level_up_modal()


func _on_level_up_choice_pressed(option_index: int) -> void:
	_apply_level_up_choice(option_index)


func _apply_level_up_choice(option_index: int) -> void:
	if option_index < 0 or option_index >= _pending_level_up_options.size():
		return

	var option: Dictionary = _pending_level_up_options[option_index]
	var item_kind: StringName = StringName(option.get("item_kind", ItemPickup.ITEM_LASER))

	if _network_controller.is_client():
		_play_level_up_choice_sfx(item_kind)
		_network_controller.request_level_up_choice(option_index)
		_close_level_up_modal()
		return

	if ship != null and is_instance_valid(ship) and ship.has_method("collect_item"):
		var item_level: int = maxi(int(option.get("item_level", 1)), 1)
		var repair_amount: int = maxi(int(option.get("repair_amount", 4)), 0)
		ship.call("collect_item", item_kind, item_level, repair_amount)
		_play_level_up_choice_sfx(item_kind)

	_close_level_up_modal(false)
	_refresh_top_bar()
	_show_next_queued_level_up_choice()


func _play_level_up_choice_sfx(item_kind: StringName) -> void:
	if item_kind == ItemPickup.ITEM_SHIELD:
		GAME_SFX.play(self, GAME_SFX.CUE_SHIELD)


func _close_level_up_modal(clear_queued: bool = true) -> void:
	if clear_queued:
		_queued_level_up_options.clear()
	_hide_level_up_modal()


func _set_game_paused(paused: bool) -> void:
	if _network_controller.is_enabled():
		_update_debug_hud()
		return

	get_tree().paused = paused
	_update_debug_hud()


func _set_debug_time_scale(time_scale: float) -> void:
	var safe_min_time_scale: float = minf(debug_min_time_scale, debug_max_time_scale)
	var safe_max_time_scale: float = maxf(debug_min_time_scale, debug_max_time_scale)
	Engine.time_scale = clampf(time_scale, safe_min_time_scale, safe_max_time_scale)
	_update_debug_hud()


func _on_debug_slow_down_pressed() -> void:
	var current_time_scale: float = maxf(Engine.time_scale, 0.0)
	var next_time_scale: float = current_time_scale / maxf(debug_time_scale_step_factor, 1.01)
	if current_time_scale <= 0.0:
		next_time_scale = debug_min_time_scale
	_set_debug_time_scale(next_time_scale)


func _on_debug_speed_up_pressed() -> void:
	var current_time_scale: float = maxf(Engine.time_scale, 0.0)
	var next_time_scale: float = current_time_scale * maxf(debug_time_scale_step_factor, 1.01)
	if current_time_scale <= 0.0:
		next_time_scale = 1.0
	_set_debug_time_scale(next_time_scale)


func _on_debug_stop_pressed() -> void:
	_set_game_paused(true)


func _on_debug_resume_pressed() -> void:
	_set_debug_time_scale(1.0)
	_set_game_paused(false)


func _on_debug_toggle_fog_pressed(toggled_on: bool) -> void:
	_is_fog_of_war_enabled = toggled_on
	_apply_fog_of_war_enabled_state()
	_update_debug_hud()


func _on_debug_toggle_vacuum_radius_toggled(toggled_on: bool) -> void:
	_debug_vacuum_radius_visible = toggled_on
	_apply_debug_vacuum_radius_visibility()
	_update_debug_hud()


func _on_debug_god_mode_toggled(toggled_on: bool) -> void:
	_debug_god_mode_enabled = toggled_on
	_apply_debug_god_mode()
	if _network_controller.is_enabled():
		_network_controller.request_debug_god_mode(toggled_on)
	_update_debug_hud()


func _on_debug_no_artifact_cooldowns_toggled(toggled_on: bool) -> void:
	_debug_no_artifact_cooldowns_enabled = toggled_on
	_apply_debug_no_artifact_cooldowns()
	if _network_controller.is_enabled():
		_network_controller.request_debug_no_artifact_cooldowns(toggled_on)
	_refresh_artifact_cooldowns_ui()
	_update_debug_hud()


func _on_debug_item_button_pressed(item_kind: StringName) -> void:
	if _network_controller.is_client():
		_network_controller.request_debug_item(item_kind)
		return

	if ship == null or not is_instance_valid(ship) or not ship.has_method("collect_item"):
		return

	ship.call("collect_item", item_kind, 1)


func _on_artifact_activation_requested(item_kind: StringName) -> void:
	_request_artifact_activation(item_kind)


func _request_artifact_activation(item_kind: StringName) -> void:
	if item_kind == &"" or _has_game_over:
		return

	if item_kind == ItemPickup.ITEM_VORTEX or item_kind == ItemPickup.ITEM_NUKE or item_kind == ItemPickup.ITEM_EXPLORER_BEACON:
		_begin_artifact_placement(item_kind)
		return

	if _network_controller.is_client():
		if not _try_activate_artifact_on_ship(item_kind):
			return
		_network_controller.request_artifact_activation(item_kind)
		_refresh_artifact_cooldowns_ui()
		return

	if _network_controller.is_enabled():
		_network_controller.request_artifact_activation(item_kind)
		_refresh_artifact_cooldowns_ui()
		return

	if _try_activate_artifact_on_ship(item_kind):
		_refresh_artifact_cooldowns_ui()


func _try_activate_artifact_on_ship(item_kind: StringName) -> bool:
	if ship == null or not is_instance_valid(ship) or not ship.has_method("activate_artifact"):
		return false

	return bool(ship.call("activate_artifact", item_kind))


func _begin_artifact_placement(item_kind: StringName) -> void:
	if not _can_activate_artifact_on_ship(item_kind):
		return

	_pending_artifact_placement_kind = item_kind
	_ensure_artifact_placement_preview(item_kind)
	_update_artifact_placement_preview()
	_ui.show_artifact_placement_cancel()


func _cancel_artifact_placement() -> void:
	_pending_artifact_placement_kind = &""
	_clear_artifact_placement_preview()
	_ui.hide_artifact_placement_cancel()


func has_pending_artifact_placement() -> bool:
	return _pending_artifact_placement_kind != &""


func try_place_pending_artifact_at_world_position(world_position: Vector2) -> bool:
	if _pending_artifact_placement_kind == &"":
		return false

	_place_pending_artifact(world_position)
	return true


func _place_pending_artifact(world_position: Vector2) -> void:
	var item_kind := _pending_artifact_placement_kind
	if item_kind == &"":
		return

	if not can_place_artifact_at(item_kind, world_position):
		return

	if _network_controller.is_client():
		if not _can_activate_artifact_on_ship(item_kind):
			return
		_play_artifact_placement_feedback(world_position)
		_network_controller.request_artifact_activation_at(item_kind, world_position)
		_start_predicted_artifact_cooldown_on_ship(item_kind)
		_refresh_artifact_cooldowns_ui()
		return

	if _network_controller.is_enabled():
		if not _can_activate_artifact_on_ship(item_kind):
			return
		_play_artifact_placement_feedback(world_position)
		_network_controller.request_artifact_activation_at(item_kind, world_position)
		_refresh_artifact_cooldowns_ui()
		return

	if _try_activate_artifact_at_on_ship(item_kind, world_position):
		_play_artifact_placement_feedback(world_position)
		_refresh_artifact_cooldowns_ui()


func _can_activate_artifact_on_ship(item_kind: StringName) -> bool:
	if ship == null or not is_instance_valid(ship):
		return false
	if ship.has_method("can_activate_artifact"):
		return bool(ship.call("can_activate_artifact", item_kind))
	if ship.has_method("has_artifact") and not bool(ship.call("has_artifact", item_kind)):
		return false

	return true


func _try_activate_artifact_at_on_ship(item_kind: StringName, world_position: Vector2) -> bool:
	if ship == null or not is_instance_valid(ship):
		return false
	if ship.has_method("activate_artifact_at"):
		return bool(ship.call("activate_artifact_at", item_kind, world_position))
	if ship.has_method("activate_artifact"):
		return bool(ship.call("activate_artifact", item_kind))

	return false


func _start_predicted_artifact_cooldown_on_ship(item_kind: StringName) -> void:
	if ship == null or not is_instance_valid(ship):
		return
	if ship.has_method("start_predicted_artifact_cooldown"):
		ship.call("start_predicted_artifact_cooldown", item_kind)


func _ensure_artifact_placement_preview(item_kind: StringName) -> void:
	if _artifact_placement_preview != null and is_instance_valid(_artifact_placement_preview):
		_artifact_placement_preview.queue_free()

	_artifact_placement_preview = Node2D.new()
	_artifact_placement_preview.name = "ArtifactPlacementPreview"
	_artifact_placement_preview.z_index = 480

	var preview_visual := _create_artifact_placement_preview_visual(item_kind)
	if preview_visual != null:
		_artifact_placement_preview.add_child(preview_visual)

	if fx_layer != null and is_instance_valid(fx_layer):
		fx_layer.add_child(_artifact_placement_preview)
	else:
		add_child(_artifact_placement_preview)


func _create_artifact_placement_preview_visual(item_kind: StringName) -> Node2D:
	if ship != null and is_instance_valid(ship):
		if ship.has_method("create_artifact_placement_preview"):
			var artifact_preview := ship.call("create_artifact_placement_preview", item_kind) as Node2D
			if artifact_preview != null:
				return artifact_preview

	var preview_sprite := Sprite2D.new()
	preview_sprite.name = "Sprite2D"
	preview_sprite.texture = _ui.get_item_icon_texture(item_kind)
	preview_sprite.modulate = Color(1.0, 1.0, 1.0, 0.42)
	preview_sprite.scale = _get_artifact_placement_preview_scale(item_kind, preview_sprite.texture)
	return preview_sprite


func _clear_artifact_placement_preview() -> void:
	if _artifact_placement_preview != null and is_instance_valid(_artifact_placement_preview):
		_artifact_placement_preview.queue_free()
	_artifact_placement_preview = null


func _play_artifact_placement_feedback(world_position: Vector2) -> void:
	var feedback_preview := _artifact_placement_preview
	_pending_artifact_placement_kind = &""
	_artifact_placement_preview = null
	_ui.hide_artifact_placement_cancel()

	if feedback_preview == null or not is_instance_valid(feedback_preview):
		return

	_set_artifact_placement_preview_node_valid(feedback_preview, true)
	feedback_preview.global_position = world_position
	feedback_preview.z_index = 481

	var tween := feedback_preview.create_tween()
	tween.set_trans(Tween.TRANS_CUBIC)
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_parallel(true)
	tween.tween_property(
		feedback_preview,
		"scale",
		Vector2.ONE * ARTIFACT_PLACEMENT_FEEDBACK_END_SCALE,
		ARTIFACT_PLACEMENT_FEEDBACK_DURATION
	)
	tween.tween_property(
		feedback_preview,
		"modulate:a",
		0.0,
		ARTIFACT_PLACEMENT_FEEDBACK_DURATION
	)
	tween.chain().tween_callback(Callable(feedback_preview, "queue_free"))


func _update_artifact_placement_preview() -> void:
	if _pending_artifact_placement_kind == &"":
		return
	if _artifact_placement_preview == null or not is_instance_valid(_artifact_placement_preview):
		return

	var preview_position := get_global_mouse_position()
	_artifact_placement_preview.global_position = preview_position
	if _pending_artifact_placement_kind != ItemPickup.ITEM_VORTEX and _pending_artifact_placement_kind != ItemPickup.ITEM_NUKE and _pending_artifact_placement_kind != ItemPickup.ITEM_EXPLORER_BEACON:
		_artifact_placement_preview.rotation -= 2.4 * get_process_delta_time()
	_set_artifact_placement_preview_valid(can_place_artifact_at(_pending_artifact_placement_kind, preview_position))


func _set_artifact_placement_preview_valid(is_valid_placement: bool) -> void:
	if _artifact_placement_preview == null or not is_instance_valid(_artifact_placement_preview):
		return

	_set_artifact_placement_preview_node_valid(_artifact_placement_preview, is_valid_placement)


func _set_artifact_placement_preview_node_valid(preview_node: Node, is_valid_placement: bool) -> void:
	if preview_node.has_method("set_valid_placement"):
		preview_node.call("set_valid_placement", is_valid_placement)

	for child in preview_node.get_children():
		if child.has_method("set_valid_placement"):
			child.call("set_valid_placement", is_valid_placement)


func _get_artifact_placement_preview_scale(item_kind: StringName, texture: Texture2D) -> Vector2:
	if texture == null:
		return Vector2(0.42, 0.42)

	var preview_radius := _get_artifact_preview_radius(item_kind)
	if preview_radius <= 0.0:
		return Vector2(0.42, 0.42)

	var texture_size := texture.get_size()
	var texture_extent := maxf(texture_size.x, texture_size.y)
	if texture_extent <= 0.0:
		return Vector2(0.42, 0.42)

	var scale_factor := (preview_radius * 2.0) / texture_extent
	return Vector2(scale_factor, scale_factor)


func _get_artifact_preview_radius(item_kind: StringName) -> float:
	if ship != null and is_instance_valid(ship):
		if ship.has_method("get_artifact_preview_radius"):
			return maxf(float(ship.call("get_artifact_preview_radius", item_kind)), 0.0)

	return 0.0


func _add_debug_xp(amount: int) -> void:
	var source_world_position := Vector2.ZERO
	if ship != null and is_instance_valid(ship):
		source_world_position = ship.global_position

	add_xp(amount, source_world_position)


func _on_debug_force_win_pressed() -> void:
	if _has_game_over:
		return

	_planets_total_count = _get_total_planet_count()
	_planets_invaded_count = _planets_total_count
	_conquered_planet_ids.clear()

	if planet_field != null:
		for child in planet_field.get_children():
			var planet := child as Planet
			if planet == null:
				continue

			_conquered_planet_ids[planet.get_instance_id()] = true
			planet.set_conquered(true)

	_has_won = true
	_refresh_top_bar()
	_update_end_messages()


func _update_debug_hud() -> void:
	_ui.update_debug_hud(
		get_tree().paused,
		Engine.time_scale,
		_has_game_over,
		_is_fog_of_war_enabled,
		_debug_vacuum_radius_visible,
		_debug_god_mode_enabled,
		_debug_no_artifact_cooldowns_enabled,
		_can_spawn_debug_enemies(),
		Engine.get_frames_per_second(),
		_get_enemy_memory_count(),
		_get_sprite_memory_count(),
		_get_object_memory_count()
	)


func _process_debug_hud(delta: float) -> void:
	_debug_hud_update_accumulator += maxf(delta, 0.0)
	if _debug_hud_update_accumulator < DEBUG_HUD_UPDATE_INTERVAL:
		return

	_debug_hud_update_accumulator = 0.0
	_update_debug_hud()


func _apply_debug_vacuum_radius_visibility() -> void:
	if ship != null and is_instance_valid(ship) and ship.has_method("set_debug_vacuum_radius_visible"):
		ship.call("set_debug_vacuum_radius_visible", _debug_vacuum_radius_visible)


func _apply_debug_god_mode() -> void:
	if ship != null and is_instance_valid(ship) and ship.has_method("set_god_mode_enabled"):
		ship.call("set_god_mode_enabled", _debug_god_mode_enabled)


func _apply_debug_no_artifact_cooldowns() -> void:
	if ship != null and is_instance_valid(ship) and ship.has_method("set_debug_no_artifact_cooldowns"):
		ship.call("set_debug_no_artifact_cooldowns", _debug_no_artifact_cooldowns_enabled)


func _spawn_debug_enemies(spawn_count: int) -> void:
	if spawn_count <= 0:
		return

	if _network_controller.is_client():
		_network_controller.request_debug_enemies(spawn_count)
		return

	_spawn_debug_enemies_local(spawn_count)


func _spawn_debug_enemies_local(spawn_count: int) -> void:
	if enemy_field == null or not is_instance_valid(enemy_field):
		return

	if spawn_count <= 0:
		return

	if enemy_field.has_method("spawn_enemies_near_ship"):
		enemy_field.call("spawn_enemies_near_ship", spawn_count)
	elif enemy_field.has_method("spawn_enemies"):
		enemy_field.call("spawn_enemies", spawn_count)


func _can_spawn_debug_enemies() -> bool:
	if enemy_field == null or not is_instance_valid(enemy_field):
		return false
	if enemy_field.has_method("can_spawn_enemy"):
		return bool(enemy_field.call("can_spawn_enemy"))

	return true


func _get_enemy_memory_count() -> int:
	if get_tree() == null:
		return 0

	return get_tree().get_nodes_in_group("enemies").size()


func _get_sprite_memory_count() -> int:
	return _count_sprite_nodes(get_tree().root if get_tree() != null else null)


func _count_sprite_nodes(node: Node) -> int:
	if node == null:
		return 0

	var sprite_count: int = 1 if node is Sprite2D or node is AnimatedSprite2D else 0
	for child in node.get_children():
		sprite_count += _count_sprite_nodes(child)

	return sprite_count


func _get_object_memory_count() -> int:
	return maxi(int(Performance.get_monitor(Performance.OBJECT_COUNT)), 0)

func _get_next_xp_threshold(level: int) -> int:
	var safe_level: int = maxi(level, 1)
	var base_threshold: int = maxi(starting_xp_to_next_level, 1)
	var level_offset: int = maxi(safe_level - 1, 0)
	var growth_multiplier: float = pow(1.0 + xp_growth_rate_per_level, float(level_offset))
	return maxi(1, int(round(float(base_threshold) * growth_multiplier)))


func _refresh_top_bar() -> void:
	_sync_ship_hp_from_ship()
	_sync_ship_shield_from_ship()
	var total_planets: int = _planets_total_count
	if total_planets <= 0:
		total_planets = _get_total_planet_count()

	_ui.refresh_top_bar_values(_planets_invaded_count, total_planets, _ship_level)
	_refresh_xp_ui()
	_refresh_enemy_wave_ui()
	_refresh_ship_hp_ui()
	_update_end_messages()
	_update_planet_action_popover_details(_active_planet)


func _try_invade_planet(planet: Planet) -> bool:
	if planet == null:
		return false

	if planet.is_conquered():
		return false

	var planet_id := planet.get_instance_id()
	if _conquered_planet_ids.has(planet_id):
		return false
	if _colonizing_planet_ids.has(planet_id):
		return false
	if not _consume_colony_beacon():
		return false

	_colonizing_planet_ids[planet_id] = true
	var target_world_position := _get_colony_beacon_landing_position(planet)
	var launch_direction := _get_colony_beacon_launch_direction(target_world_position)
	var launch_origin := _get_colony_beacon_launch_origin(launch_direction)
	_play_colony_beacon_deployment(
		launch_origin,
		planet,
		Callable(self, "_finish_colony_beacon_deployment").bind(planet_id, planet),
		launch_direction
	)
	_refresh_inventory_ui()
	_refresh_top_bar()
	return true


func _finish_colony_beacon_deployment(planet_id: int, planet: Planet) -> void:
	_colonizing_planet_ids.erase(planet_id)
	if planet == null or not is_instance_valid(planet):
		return
	if _has_game_over or planet.is_conquered() or _conquered_planet_ids.has(planet_id):
		return

	_conquered_planet_ids[planet_id] = true
	planet.set_conquered(true)
	_planets_invaded_count += 1
	_refresh_top_bar()


func _get_colony_beacon_count() -> int:
	if ship != null and is_instance_valid(ship) and ship.has_method("get_item_count"):
		return maxi(int(ship.call("get_item_count", ItemPickup.ITEM_COLONY_BEACON)), 0)

	return maxi(int(_ship_inventory_levels.get(ItemPickup.ITEM_COLONY_BEACON, 0)), 0)


func _consume_colony_beacon() -> bool:
	if ship == null or not is_instance_valid(ship) or not ship.has_method("consume_item"):
		return false

	return bool(ship.call("consume_item", ItemPickup.ITEM_COLONY_BEACON, 1))


func _play_colony_beacon_deployment(
	launch_origin: Vector2,
	planet: Planet,
	landed_callback: Callable = Callable(),
	launch_direction: Vector2 = Vector2.ZERO
) -> void:
	if planet == null or not is_instance_valid(planet):
		if landed_callback.is_valid():
			landed_callback.call()
		return

	if fx_layer == null:
		if landed_callback.is_valid():
			landed_callback.call()
		return

	var torpedo := COLONY_BEACON_TORPEDO_SCENE.instantiate() as Node2D
	if torpedo == null:
		if landed_callback.is_valid():
			landed_callback.call()
		return

	fx_layer.add_child(torpedo)
	torpedo.z_index = 540
	var landed_callable := func(_world_position: Vector2) -> void:
		if landed_callback.is_valid():
			landed_callback.call()
	if torpedo.has_signal("landed"):
		torpedo.connect("landed", landed_callable, CONNECT_ONE_SHOT)
	if torpedo.has_method("configure"):
		torpedo.call(
			"configure",
			launch_origin,
			_get_colony_beacon_landing_position(planet, launch_origin),
			COLONY_BEACON_TORPEDO_IMPACT_RADIUS,
			1,
			COLONY_BEACON_TORPEDO_TRAVEL_SPEED,
			0.1,
			false,
			0,
			launch_direction,
			planet
		)


func _get_colony_beacon_landing_position(planet: Planet, launch_origin: Vector2 = Vector2.INF) -> Vector2:
	if planet == null:
		return Vector2.ZERO

	var origin := launch_origin
	if not origin.is_finite():
		origin = ship.global_position if ship != null and is_instance_valid(ship) else planet.global_position + Vector2.UP
	var direction := planet.global_position - origin
	if direction.length_squared() <= 0.001:
		direction = Vector2.DOWN
	else:
		direction = direction.normalized()

	var planet_radius := maxf(planet.get_touch_radius(), 1.0)
	return planet.global_position - direction * planet_radius * COLONY_BEACON_LANDING_SURFACE_RATIO


func _get_colony_beacon_launch_direction(target_world_position: Vector2) -> Vector2:
	if ship != null and is_instance_valid(ship) and ship.has_method("get_artifact_forward_direction"):
		var ship_direction := ship.call("get_artifact_forward_direction") as Vector2
		if ship_direction != Vector2.ZERO:
			return ship_direction.normalized()
	if ship != null and is_instance_valid(ship):
		var target_direction := (target_world_position - ship.global_position).normalized()
		if target_direction != Vector2.ZERO:
			return target_direction

	return Vector2.UP


func _get_colony_beacon_launch_origin(launch_direction: Vector2) -> Vector2:
	if ship != null and is_instance_valid(ship) and ship.has_method("get_artifact_launch_origin"):
		return ship.call("get_artifact_launch_origin") as Vector2
	if ship != null and is_instance_valid(ship):
		return ship.global_position + launch_direction.normalized() * 48.0

	return Vector2.ZERO


func _update_winner_message() -> void:
	if _network_controller.is_enabled() and _has_game_over and _network_controller.has_match_winner():
		_ui.update_end_messages(_has_game_over, _has_won, "%s WINS!" % _network_controller.get_match_winner_name().to_upper())
		return

	if _has_game_over:
		_ui.update_end_messages(_has_game_over, _has_won)
		return

	var total_planets := _planets_total_count
	if total_planets <= 0:
		total_planets = _get_total_planet_count()

	if not _has_won and total_planets > 0 and _planets_invaded_count >= total_planets:
		_has_won = true

	_ui.update_end_messages(_has_game_over, _has_won)
	if _has_won:
		_activate_winner_sequence()


func _update_end_messages() -> void:
	_update_winner_message()


func _spawn_xp_label(world_position: Vector2, amount: int) -> void:
	_ui.spawn_xp_label(_world_to_screen_position(world_position), amount, income_label_float_distance, income_label_duration)


func _spawn_damage_label(world_position: Vector2, amount: int) -> void:
	_ui.spawn_damage_label(_world_to_screen_position(world_position), amount, income_label_float_distance, income_label_duration)


func _update_planet_action_popover_details(planet: Planet) -> void:
	_ui.update_planet_action_details(planet, _get_colony_beacon_count() > 0)


func _get_total_planet_count() -> int:
	if planet_field == null:
		return 0

	return planet_field.get_child_count()
