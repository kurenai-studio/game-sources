class_name GalaxyNetworkController
extends RefCounted

const SHIP_SCENE: PackedScene = preload("res://scenes/ship.tscn")
const SERVER_PEER_ID: int = 1
const NETWORK_SNAPSHOT_INTERVAL: float = 1.0 / 30.0
const NETWORK_ITEM_PICKUP_PADDING: float = 12.0
const PLAYER_DEATH_XP_SPLASH_GOLDEN_ANGLE: float = 2.399963229728653
const COLONY_BEACON_LANDING_SURFACE_RATIO: float = 0.36
const NETWORK_SHIP_TUNABLE_PROPERTIES: Array[StringName] = [
	&"move_speed",
	&"target_tolerance",
	&"acceleration",
	&"deceleration",
	&"turn_speed",
	&"sprite_forward_rotation_offset",
	&"minimum_turn_speed_factor",
	&"jet_length_scale_min",
	&"jet_length_scale_max",
	&"jet_turn_power_boost",
	&"invisibility_duration_per_pickup",
	&"invisibility_visual_alpha",
	&"invisibility_distortion_bonus",
	&"remote_invisibility_visual_alpha",
	&"remote_invisibility_tint_color",
	&"remote_invisibility_refraction_strength",
	&"remote_invisibility_wave_frequency",
	&"remote_invisibility_wave_speed",
	&"remote_invisibility_mirror_mix",
	&"remote_invisibility_edge_strength",
	&"remote_invisibility_shimmer_strength",
]
const NETWORK_SHIP_ARTIFACT_TUNABLES_KEY: StringName = &"_artifact_tunables"

var _galaxy
var _network_session: Node
var _enabled: bool = false
var _is_server: bool = false
var _is_client: bool = false
var _players_node: Node2D
var _players_by_peer_id: Dictionary = {}
var _player_states: Dictionary = {}
var _player_names: Dictionary = {}
var _local_peer_id: int = 0
var _snapshot_accumulator: float = 0.0
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _next_item_network_id: int = 1
var _client_enemy_nodes: Dictionary = {}
var _destroyed_enemy_ids: Dictionary = {}
var _client_item_nodes: Dictionary = {}
var _status_label: Label
var _match_winner_peer_id: int = 0
var _match_winner_name: String = ""
var _network_ship_tunables: Dictionary = {}
var _suppress_inventory_broadcast: bool = false


func configure(galaxy) -> void:
	_galaxy = galaxy


func setup() -> void:
	_network_session = _galaxy.get_node_or_null("/root/NetworkSession")
	if _network_session == null:
		return

	_enabled = bool(_network_session.call("is_multiplayer_enabled"))
	if not _enabled:
		return

	_is_server = bool(_network_session.call("is_server"))
	_is_client = bool(_network_session.call("is_client"))
	_local_peer_id = int(_network_session.call("get_local_peer_id"))
	_rng.randomize()
	_ensure_players_node()
	_assign_planet_network_ids()
	_assign_existing_item_network_ids()
	_create_status_label()
	_disable_static_ship_for_network()

	if _is_client:
		if _galaxy.enemy_field != null:
			_galaxy.enemy_field.set_process(false)
		if _galaxy.item_field != null:
			_galaxy.item_field.set_process(false)
		set_status("Connecting to server...")
	elif _is_server:
		set_status("Server listening on UDP %d" % int(_network_session.get("port")))

	_network_session.call("register_galaxy", _galaxy)


func is_enabled() -> bool:
	return _enabled


func is_server() -> bool:
	return _is_server


func is_client() -> bool:
	return _is_client


func get_local_peer_id() -> int:
	return _local_peer_id


func has_match_winner() -> bool:
	return _match_winner_peer_id > 0


func get_match_winner_name() -> String:
	return _match_winner_name


func process_server(delta: float) -> void:
	if _galaxy.get("_has_game_over"):
		_send_network_snapshot()
		return

	_process_item_pickups(delta)
	_snapshot_accumulator += delta
	if _snapshot_accumulator >= NETWORK_SNAPSHOT_INTERVAL:
		_snapshot_accumulator = 0.0
		_send_network_snapshot()


func process_client(delta: float) -> void:
	if _galaxy.ship == null or _galaxy.get("_has_game_over"):
		_galaxy.call("_update_debug_hud")
		return

	_galaxy.get("_camera_controller").set_ship(_galaxy.ship)
	_galaxy.get("_camera_controller").process(delta)
	_galaxy.call("_reveal_fog_of_war")
	_galaxy.call("_update_planet_action_popover")
	_galaxy.call("_update_planet_hover_tooltip")
	_galaxy.call("_update_debug_hud")


func request_move(world_position: Vector2) -> void:
	var local_ship := _players_by_peer_id.get(_local_peer_id, _galaxy.ship) as Node2D
	if local_ship != null and is_instance_valid(local_ship) and local_ship.has_method("move_to"):
		local_ship.call("move_to", world_position)
	_galaxy.rpc_id(SERVER_PEER_ID, "server_request_move", world_position)


func request_invade(planet_network_id: int) -> void:
	_galaxy.rpc_id(SERVER_PEER_ID, "server_request_invade", planet_network_id)


func request_level_up_choice(option_index: int) -> void:
	_galaxy.rpc_id(SERVER_PEER_ID, "server_request_level_up_choice", option_index)


func request_artifact_activation(item_kind: StringName) -> void:
	if _is_server:
		server_request_artifact_activation(item_kind, _local_peer_id)
		return
	if _is_client:
		_galaxy.rpc_id(SERVER_PEER_ID, "server_request_artifact_activation", String(item_kind))


func request_artifact_activation_at(item_kind: StringName, world_position: Vector2) -> void:
	if _is_server:
		server_request_artifact_activation_at(item_kind, world_position, _local_peer_id)
		return
	if _is_client:
		_galaxy.rpc_id(SERVER_PEER_ID, "server_request_artifact_activation_at", String(item_kind), world_position)


func request_debug_item(item_kind: StringName) -> void:
	_galaxy.rpc_id(SERVER_PEER_ID, "server_request_debug_item", String(item_kind))


func request_debug_enemies(spawn_count: int) -> void:
	_galaxy.rpc_id(SERVER_PEER_ID, "server_request_debug_enemies", spawn_count)


func request_debug_god_mode(enabled: bool) -> void:
	if _is_server:
		server_request_debug_god_mode(enabled, _local_peer_id)
		return
	if _is_client:
		_galaxy.rpc_id(SERVER_PEER_ID, "server_request_debug_god_mode", enabled)


func request_debug_no_artifact_cooldowns(enabled: bool) -> void:
	if _is_server:
		server_request_debug_no_artifact_cooldowns(enabled, _local_peer_id)
		return
	if _is_client:
		_galaxy.rpc_id(SERVER_PEER_ID, "server_request_debug_no_artifact_cooldowns", enabled)


func request_restart() -> void:
	if _is_server:
		_server_restart_player(_local_peer_id)
		return
	if _is_client:
		_galaxy.rpc_id(SERVER_PEER_ID, "server_request_restart")


func spawn_xp_box(world_position: Vector2, xp_amount: int) -> void:
	_server_spawn_xp_box(world_position, xp_amount)


func enemy_destroyed(enemy: Node2D, world_position: Vector2, xp_amount: int) -> void:
	var destroyed_enemy := enemy as Enemy
	if destroyed_enemy != null and destroyed_enemy.network_id > 0:
		_galaxy.rpc(
			"client_enemy_destroyed",
			destroyed_enemy.network_id,
			destroyed_enemy.network_scene_key,
			world_position,
			destroyed_enemy.rotation
		)
	_server_spawn_xp_box(world_position, xp_amount)


func network_server_started() -> void:
	set_status("Server listening on UDP %d" % int(_network_session.get("port")))


func network_connected_to_server() -> void:
	if not _is_client:
		return

	var requested_name := str(_network_session.get("display_name"))
	_galaxy.rpc_id(SERVER_PEER_ID, "server_request_join", requested_name)
	set_status("Connected. Joining galaxy...")


func network_peer_disconnected(peer_id: int) -> void:
	if _is_server:
		_server_remove_player(peer_id)


func network_server_disconnected() -> void:
	set_status("Disconnected from server.")


func server_request_restart(sender_peer_id: int) -> void:
	if not _is_server or _galaxy.get("_has_game_over"):
		return

	_server_restart_player(sender_peer_id)


func server_request_join(requested_name: String, sender_peer_id: int) -> void:
	if not _is_server:
		return

	var peer_id := sender_peer_id
	if peer_id <= 0:
		return

	if _player_states.has(peer_id):
		_send_initial_state(peer_id)
		return

	var display_name := requested_name.strip_edges()
	if display_name.is_empty():
		display_name = "Player%d" % peer_id
	display_name = display_name.substr(0, 24)
	_server_add_player(peer_id, display_name)


func server_request_move(world_position: Vector2, sender_peer_id: int) -> void:
	if not _is_server or _galaxy.get("_has_game_over"):
		return

	var peer_id := sender_peer_id
	var state: Dictionary = _player_states.get(peer_id, {})
	if state.is_empty():
		return

	var player_ship := state.get("ship", null) as Node2D
	if player_ship == null or not is_instance_valid(player_ship):
		return
	if player_ship.has_method("is_destroyed") and bool(player_ship.call("is_destroyed")):
		return
	if player_ship.has_method("move_to"):
		player_ship.call("move_to", world_position)


func server_request_invade(planet_network_id: int, sender_peer_id: int) -> void:
	if not _is_server or _galaxy.get("_has_game_over"):
		return

	var peer_id := sender_peer_id
	if _server_try_invade_planet(peer_id, planet_network_id):
		_send_player_state(peer_id)


func server_request_level_up_choice(option_index: int, sender_peer_id: int) -> void:
	if not _is_server or _galaxy.get("_has_game_over"):
		return

	var peer_id := sender_peer_id
	var state: Dictionary = _player_states.get(peer_id, {})
	if state.is_empty() or not bool(state.get("awaiting_level_up", false)):
		return

	var options: Array = state.get("level_up_options", [])
	if option_index < 0 or option_index >= options.size():
		return

	var option: Dictionary = options[option_index]
	if not _server_collect_item_for_player(
		peer_id,
		StringName(option.get("item_kind", ItemPickup.ITEM_LASER)),
		maxi(int(option.get("item_level", 1)), 1),
		maxi(int(option.get("repair_amount", 4)), 0),
		Vector2.ZERO,
		false
	):
		return

	state = _player_states.get(peer_id, {})
	if state.is_empty():
		return
	state["awaiting_level_up"] = false
	state["level_up_options"] = []
	state = _show_next_queued_level_up_choice(state)
	_player_states[peer_id] = state
	_broadcast_player_state(peer_id)
	if bool(state.get("awaiting_level_up", false)):
		_galaxy.rpc_id(peer_id, "client_level_up_options", state.get("level_up_options", []), _build_player_payload(peer_id))


func server_request_artifact_activation(item_kind: StringName, sender_peer_id: int) -> void:
	if not _is_server or _galaxy.get("_has_game_over"):
		return

	var state: Dictionary = _player_states.get(sender_peer_id, {})
	if state.is_empty() or not bool(state.get("alive", true)):
		return

	var player_ship := state.get("ship", null) as Node2D
	if player_ship == null or not is_instance_valid(player_ship) or not player_ship.has_method("activate_artifact"):
		return

	player_ship.call("activate_artifact", item_kind)


func server_request_artifact_activation_at(item_kind: StringName, world_position: Vector2, sender_peer_id: int) -> void:
	if not _is_server or _galaxy.get("_has_game_over"):
		return

	var state: Dictionary = _player_states.get(sender_peer_id, {})
	if state.is_empty() or not bool(state.get("alive", true)):
		return

	var player_ship := state.get("ship", null) as Node2D
	if player_ship == null or not is_instance_valid(player_ship) or not player_ship.has_method("activate_artifact_at"):
		return

	player_ship.call("activate_artifact_at", item_kind, world_position)


func server_request_debug_item(item_kind: StringName, sender_peer_id: int) -> void:
	if not _is_server or _galaxy.get("_has_game_over"):
		return

	_server_collect_item_for_player(sender_peer_id, item_kind, 1, 4)


func server_request_debug_enemies(spawn_count: int, _sender_peer_id: int) -> void:
	if not _is_server or _galaxy.get("_has_game_over"):
		return

	if spawn_count <= 0:
		return

	_galaxy.call("_spawn_debug_enemies_local", spawn_count)


func server_request_debug_god_mode(enabled: bool, sender_peer_id: int) -> void:
	if not _is_server or _galaxy.get("_has_game_over"):
		return

	var state: Dictionary = _player_states.get(sender_peer_id, {})
	if state.is_empty() or not bool(state.get("alive", true)):
		return

	var player_ship := state.get("ship", null) as Node
	if player_ship != null and is_instance_valid(player_ship) and player_ship.has_method("set_god_mode_enabled"):
		player_ship.call("set_god_mode_enabled", enabled)

	state["god_mode"] = enabled
	_player_states[sender_peer_id] = state
	_send_player_state(sender_peer_id)


func server_request_debug_no_artifact_cooldowns(enabled: bool, sender_peer_id: int) -> void:
	if not _is_server or _galaxy.get("_has_game_over"):
		return

	var state: Dictionary = _player_states.get(sender_peer_id, {})
	if state.is_empty() or not bool(state.get("alive", true)):
		return

	var player_ship := state.get("ship", null) as Node
	if player_ship != null and is_instance_valid(player_ship) and player_ship.has_method("set_debug_no_artifact_cooldowns"):
		player_ship.call("set_debug_no_artifact_cooldowns", enabled)

	state["no_artifact_cooldowns"] = enabled
	_player_states[sender_peer_id] = state
	_send_player_state(sender_peer_id)


func client_receive_initial_state(state: Dictionary) -> void:
	if not _is_client:
		return

	_local_peer_id = int(state.get("local_peer_id", _local_peer_id))
	_destroyed_enemy_ids.clear()
	_apply_planet_states(state.get("planets", []))
	_apply_item_states(state.get("items", []))
	for player_state in state.get("players", []):
		_apply_player_state(player_state)
	_apply_enemy_states(state.get("enemies", []))
	set_status("Connected as %s" % str(state.get("display_name", "Player")))
	_galaxy.call("_refresh_top_bar")


func client_player_joined(player_state: Dictionary) -> void:
	if _is_client:
		_apply_player_state(player_state)


func client_player_left(peer_id: int) -> void:
	if not _is_client:
		return

	var player_ship := _players_by_peer_id.get(peer_id, null) as Node
	if player_ship != null and is_instance_valid(player_ship):
		player_ship.queue_free()
	_players_by_peer_id.erase(peer_id)
	_player_states.erase(peer_id)
	if peer_id == _local_peer_id:
		_galaxy.ship = null
		_galaxy.get("_camera_controller").set_ship(null)


func client_player_state(player_state: Dictionary) -> void:
	if _is_client:
		_apply_player_state(player_state)


func client_item_spawned(item_state: Dictionary) -> void:
	if _is_client:
		_spawn_client_item(item_state)


func client_item_removed(item_network_id: int) -> void:
	if not _is_client:
		return

	var item := _client_item_nodes.get(item_network_id, null) as Node
	if item != null and is_instance_valid(item):
		item.queue_free()
	_client_item_nodes.erase(item_network_id)


func client_level_up_options(options: Array, player_state: Dictionary) -> void:
	if not _is_client:
		return

	_apply_player_state(player_state)
	_galaxy.set("_pending_level_up_options", [])
	for option in options:
		if option is Dictionary:
			_galaxy.get("_pending_level_up_options").append((option as Dictionary).duplicate(true))
	if _galaxy.get("_pending_level_up_options").is_empty():
		return

	_galaxy.set("_is_level_up_modal_open", true)
	_galaxy.call("_hide_planet_action_popover")
	_galaxy.call("_hide_planet_hover_tooltip")
	_galaxy.call("_show_level_up_modal")
	_galaxy.call("_refresh_top_bar")


func client_match_ended(winner_peer_id: int, winner_name: String) -> void:
	_match_winner_peer_id = winner_peer_id
	_match_winner_name = winner_name
	_galaxy.set("_has_game_over", true)
	_galaxy.call("_close_level_up_modal")
	_galaxy.call("_update_end_messages")
	set_status("%s conquered the galaxy." % winner_name)


func client_apply_snapshot(snapshot: Dictionary) -> void:
	if not _is_client:
		return

	for player_state in snapshot.get("players", []):
		if player_state is Array:
			_apply_player_snapshot_row(player_state as Array)
		elif player_state is Dictionary:
			_apply_player_snapshot(player_state)
	_apply_item_snapshot_rows(snapshot.get("items", []))
	_apply_enemy_snapshot_rows(snapshot.get("enemies", []))
	_galaxy.call("_update_enemy_wave_ui", float(snapshot.get("wave_time_left", 0.0)), int(snapshot.get("next_wave_size", 0)))


func client_ship_weapon_fired(peer_id: int, target_world_position: Vector2) -> void:
	if not _is_client:
		return

	var player_ship := _players_by_peer_id.get(peer_id, null) as Node
	if player_ship != null and is_instance_valid(player_ship) and player_ship.has_method("play_network_weapon_projectile"):
		player_ship.call("play_network_weapon_projectile", target_world_position)


func client_ship_drone_weapon_fired(peer_id: int, drone_index: int, target_world_position: Vector2) -> void:
	if not _is_client:
		return

	var player_ship := _players_by_peer_id.get(peer_id, null) as Node
	if player_ship != null and is_instance_valid(player_ship) and player_ship.has_method("play_network_drone_beam"):
		player_ship.call("play_network_drone_beam", drone_index, target_world_position)


func client_ship_homing_missile_fired(payload: Dictionary) -> void:
	if not _is_client:
		return

	var owner_peer_id := int(payload.get("owner_peer_id", 0))
	if owner_peer_id <= 0:
		return

	var player_ship := _players_by_peer_id.get(owner_peer_id, null) as Node
	if player_ship == null or not is_instance_valid(player_ship) or not player_ship.has_method("play_network_homing_missile"):
		return

	player_ship.call("play_network_homing_missile", payload, _resolve_weapon_target(payload.get("target", {}) as Dictionary))


func client_ship_vortex_spawned(payload: Dictionary) -> void:
	if not _is_client:
		return

	var owner_peer_id := int(payload.get("owner_peer_id", 0))
	if owner_peer_id <= 0:
		return

	var player_ship := _players_by_peer_id.get(owner_peer_id, null) as Node
	if player_ship == null or not is_instance_valid(player_ship) or not player_ship.has_method("play_network_vortex"):
		return

	player_ship.call("play_network_vortex", payload)


func client_ship_nuke_launched(payload: Dictionary) -> void:
	if not _is_client:
		return

	var owner_peer_id := int(payload.get("owner_peer_id", 0))
	if owner_peer_id <= 0:
		return

	var player_ship := _players_by_peer_id.get(owner_peer_id, null) as Node
	if player_ship == null or not is_instance_valid(player_ship) or not player_ship.has_method("play_network_nuke"):
		return

	player_ship.call("play_network_nuke", payload)


func client_explorer_beacon_launched(payload: Dictionary) -> void:
	if not _is_client:
		return

	var owner_peer_id := int(payload.get("owner_peer_id", 0))
	if owner_peer_id <= 0:
		return

	var player_ship := _players_by_peer_id.get(owner_peer_id, null) as Node
	if player_ship == null or not is_instance_valid(player_ship) or not player_ship.has_method("play_network_explorer_beacon"):
		return

	player_ship.call("play_network_explorer_beacon", payload)


func client_explorer_beacon_destroyed(network_id: int) -> void:
	if not _is_client:
		return

	var beacon := _get_explorer_beacon_by_network_id(network_id)
	if beacon != null and is_instance_valid(beacon):
		beacon.queue_free()


func client_colony_beacon_deployed(_peer_id: int, planet_network_id: int, launch_origin: Vector2, launch_direction: Vector2) -> void:
	if not _is_client:
		return

	var planet := _get_planet_by_network_id(planet_network_id)
	if planet == null:
		return

	_galaxy.call("_play_colony_beacon_deployment", launch_origin, planet, Callable(), launch_direction)


func client_ship_destroyed(peer_id: int, world_position: Vector2, world_rotation: float) -> void:
	if not _is_client:
		return

	if peer_id == _local_peer_id:
		_galaxy.call("_activate_game_over")
		return

	var player_ship := _players_by_peer_id.get(peer_id, null) as Node2D
	if player_ship == null or not is_instance_valid(player_ship):
		return

	player_ship.global_position = world_position
	player_ship.rotation = world_rotation
	if player_ship.has_method("play_destruction_fx"):
		player_ship.call("play_destruction_fx")
	player_ship.hide()


func client_enemy_beam_fired(enemy_network_id: int, target_world_position: Vector2) -> void:
	if not _is_client:
		return

	var enemy := _client_enemy_nodes.get(enemy_network_id, null) as Node
	if enemy != null and is_instance_valid(enemy) and enemy.has_method("play_network_beam"):
		enemy.call("play_network_beam", target_world_position)


func client_enemy_destroyed(enemy_network_id: int, scene_key: StringName, world_position: Vector2, world_rotation: float) -> void:
	if not _is_client:
		return

	_explode_and_remove_client_enemy(enemy_network_id, scene_key, world_position, world_rotation)


func set_status(text: String) -> void:
	if _status_label != null:
		_status_label.text = text
	if _is_server:
		print(text)


func _ensure_players_node() -> void:
	_players_node = _galaxy.get_node_or_null("Players") as Node2D
	if _players_node != null:
		return

	_players_node = Node2D.new()
	_players_node.name = "Players"
	_galaxy.add_child(_players_node)


func _disable_static_ship_for_network() -> void:
	if _galaxy.ship == null:
		return

	_cache_network_ship_tunables(_galaxy.ship)
	if _galaxy.enemy_field != null:
		_galaxy.enemy_field.set("ship_path", NodePath(""))
		_galaxy.enemy_field.set("_ship", null)
	_galaxy.ship.remove_from_group("player_ships")
	_galaxy.ship.hide()
	_galaxy.ship.set_process(false)
	_galaxy.ship.set_physics_process(false)
	_galaxy.ship = null
	_galaxy.get("_camera_controller").set_ship(null)


func _create_status_label() -> void:
	if _status_label != null:
		return

	var ui_layer := _galaxy.get_node_or_null("UI") as CanvasLayer
	if ui_layer == null:
		return

	_status_label = Label.new()
	_status_label.name = "NetworkStatusLabel"
	_status_label.position = Vector2(16.0, 132.0)
	_status_label.add_theme_font_size_override("font_size", 16)
	ui_layer.add_child(_status_label)


func _server_add_player(peer_id: int, display_name: String) -> void:
	var spawn_position := _pick_player_spawn_position()
	var player_ship := _spawn_player_ship(peer_id, spawn_position, false, true)
	var state := _create_server_player_state(peer_id, display_name, spawn_position, player_ship)
	_player_states[peer_id] = state
	_player_names[peer_id] = display_name
	_connect_network_ship_signals(peer_id, player_ship)
	_send_initial_state(peer_id)

	var payload := _build_player_payload(peer_id)
	for existing_peer_id in _player_states.keys():
		if int(existing_peer_id) == peer_id:
			continue
		_galaxy.rpc_id(int(existing_peer_id), "client_player_joined", payload)
	set_status("%s joined as peer %d." % [display_name, peer_id])


func _server_remove_player(peer_id: int) -> void:
	var state: Dictionary = _player_states.get(peer_id, {})
	if not state.is_empty():
		var player_ship := state.get("ship", null) as Node
		if player_ship != null and is_instance_valid(player_ship):
			player_ship.queue_free()

	_player_states.erase(peer_id)
	_players_by_peer_id.erase(peer_id)
	_player_names.erase(peer_id)
	_galaxy.rpc("client_player_left", peer_id)


func _server_restart_player(peer_id: int) -> void:
	if peer_id <= 0 or not _player_states.has(peer_id):
		return

	var previous_state: Dictionary = _player_states.get(peer_id, {})
	if previous_state.is_empty() or bool(previous_state.get("alive", true)):
		return

	var display_name := str(previous_state.get("display_name", _player_names.get(peer_id, "Player%d" % peer_id)))
	var previous_ship := previous_state.get("ship", null) as Node
	if previous_ship != null and is_instance_valid(previous_ship):
		previous_ship.queue_free()

	_players_by_peer_id.erase(peer_id)
	var spawn_position := _pick_player_spawn_position()
	var player_ship := _spawn_player_ship(peer_id, spawn_position, peer_id == _local_peer_id, true)
	var restarted_state := _create_server_player_state(peer_id, display_name, spawn_position, player_ship)
	_player_states[peer_id] = restarted_state
	_player_names[peer_id] = display_name
	_connect_network_ship_signals(peer_id, player_ship)
	_galaxy.rpc("client_player_left", peer_id)
	_galaxy.rpc("client_player_joined", _build_player_payload(peer_id))
	set_status("%s restarted with a new ship." % display_name)


func _spawn_player_ship(peer_id: int, spawn_position: Vector2, local_player: bool, server_authority: bool) -> Node2D:
	_ensure_players_node()
	var existing_ship := _players_by_peer_id.get(peer_id, null) as Node2D
	if existing_ship != null and is_instance_valid(existing_ship):
		if server_authority or not existing_ship.has_method("set_network_snapshot"):
			existing_ship.global_position = spawn_position
		_apply_network_ship_tunables(existing_ship)
		if existing_ship.has_method("set_network_identity"):
			existing_ship.call("set_network_identity", peer_id, local_player, server_authority)
		_configure_network_ship_processing(existing_ship, local_player, server_authority)
		if local_player:
			_galaxy.ship = existing_ship
			_update_minimap_ship_path(existing_ship)
		return existing_ship

	var player_ship := SHIP_SCENE.instantiate() as Node2D
	if player_ship == null:
		return null

	_players_node.add_child(player_ship)
	_apply_network_ship_tunables(player_ship)
	player_ship.global_position = spawn_position
	if player_ship.has_method("set_network_identity"):
		player_ship.call("set_network_identity", peer_id, local_player, server_authority)
	_configure_network_ship_processing(player_ship, local_player, server_authority)
	_players_by_peer_id[peer_id] = player_ship
	if local_player:
		_galaxy.ship = player_ship
		_galaxy.call("_center_camera_on_ship")
		_update_minimap_ship_path(player_ship)
	return player_ship


func _configure_network_ship_processing(player_ship: Node2D, local_player: bool, server_authority: bool) -> void:
	player_ship.set_process(true)
	player_ship.set_physics_process(server_authority or local_player)


func _cache_network_ship_tunables(source_ship: Node) -> void:
	_network_ship_tunables.clear()
	for property_name in NETWORK_SHIP_TUNABLE_PROPERTIES:
		_network_ship_tunables[property_name] = source_ship.get(property_name)
	if source_ship.has_method("get_artifact_tunables"):
		_network_ship_tunables[NETWORK_SHIP_ARTIFACT_TUNABLES_KEY] = source_ship.call("get_artifact_tunables")


func _apply_network_ship_tunables(player_ship: Node) -> void:
	for property_name in _network_ship_tunables.keys():
		if property_name == NETWORK_SHIP_ARTIFACT_TUNABLES_KEY:
			continue

		player_ship.set(property_name, _network_ship_tunables[property_name])
	if player_ship.has_method("apply_artifact_tunables"):
		player_ship.call(
			"apply_artifact_tunables",
			_network_ship_tunables.get(NETWORK_SHIP_ARTIFACT_TUNABLES_KEY, {})
		)


func _create_server_player_state(peer_id: int, display_name: String, spawn_position: Vector2, player_ship: Node2D) -> Dictionary:
	return {
		"peer_id": peer_id,
		"display_name": display_name,
		"ship": player_ship,
		"hp": 10,
		"max_hp": 10,
		"shield_hp": 0,
		"max_shield_hp": 0,
		"shield_level": 0,
		"xp": 0,
		"level": 1,
		"xp_to_next": max(_galaxy.starting_xp_to_next_level, 1),
		"inventory": {&"laser": 1},
		"conquered_planet_ids": {},
		"colonizing_planet_ids": {},
		"alive": true,
		"god_mode": false,
		"no_artifact_cooldowns": false,
		"awaiting_level_up": false,
		"level_up_options": [],
		"queued_level_up_options": [],
		"spawn_position": spawn_position,
	}


func _connect_network_ship_signals(peer_id: int, player_ship: Node2D) -> void:
	if player_ship == null:
		return
	if player_ship.has_signal("hp_changed"):
		player_ship.connect("hp_changed", Callable(self, "_on_network_ship_hp_changed").bind(peer_id))
	if player_ship.has_signal("died"):
		player_ship.connect("died", Callable(self, "_on_network_ship_died").bind(peer_id))
	if player_ship.has_signal("experience_collected"):
		player_ship.connect("experience_collected", Callable(self, "_on_network_ship_experience_collected").bind(peer_id))
	if player_ship.has_signal("inventory_changed"):
		player_ship.connect("inventory_changed", Callable(self, "_on_network_ship_inventory_changed").bind(peer_id))
	if player_ship.has_signal("shield_changed"):
		player_ship.connect("shield_changed", Callable(self, "_on_network_ship_shield_changed").bind(peer_id))


func _on_network_ship_hp_changed(current_hp: int, max_hp: int, peer_id: int) -> void:
	var state: Dictionary = _player_states.get(peer_id, {})
	if state.is_empty():
		return
	state["hp"] = max(current_hp, 0)
	state["max_hp"] = max(max_hp, 1)
	state["alive"] = current_hp > 0
	_player_states[peer_id] = state
	_send_player_state(peer_id)


func _on_network_ship_shield_changed(current_shield_hp: int, max_shield_hp: int, shield_level: int, peer_id: int) -> void:
	var state: Dictionary = _player_states.get(peer_id, {})
	if state.is_empty():
		return
	state["shield_hp"] = max(current_shield_hp, 0)
	state["max_shield_hp"] = max(max_shield_hp, 0)
	state["shield_level"] = max(shield_level, 0)
	_player_states[peer_id] = state
	_send_player_state(peer_id)


func _on_network_ship_died(peer_id: int) -> void:
	var state: Dictionary = _player_states.get(peer_id, {})
	if state.is_empty():
		return

	if _is_server:
		var player_ship := state.get("ship", null) as Node2D
		var death_position := Vector2.ZERO
		var death_rotation := 0.0
		if player_ship != null and is_instance_valid(player_ship):
			death_position = player_ship.global_position
			death_rotation = player_ship.rotation
			if peer_id == _local_peer_id:
				_galaxy.call("_activate_game_over")
			else:
				if player_ship.has_method("play_destruction_fx"):
					player_ship.call("play_destruction_fx")
				player_ship.hide()
			_spawn_player_death_xp_boxes(death_position)
			_galaxy.rpc("client_ship_destroyed", peer_id, death_position, death_rotation)

	state["alive"] = false
	state["conquered_planet_ids"] = {}
	state["colonizing_planet_ids"] = {}
	state["awaiting_level_up"] = false
	state["level_up_options"] = []
	state["queued_level_up_options"] = []
	_player_states[peer_id] = state
	_send_player_state(peer_id)


func _on_network_ship_experience_collected(amount: int, world_position: Vector2, peer_id: int) -> void:
	_server_add_xp(peer_id, amount, world_position)


func _on_network_ship_inventory_changed(inventory: Dictionary, peer_id: int) -> void:
	var state: Dictionary = _player_states.get(peer_id, {})
	if state.is_empty():
		return
	state["inventory"] = inventory.duplicate(true)
	_player_states[peer_id] = state
	if _suppress_inventory_broadcast:
		return
	_broadcast_player_state(peer_id)


func _server_add_xp(peer_id: int, amount: int, _world_position: Vector2 = Vector2.ZERO) -> void:
	if amount <= 0:
		return

	var state: Dictionary = _player_states.get(peer_id, {})
	if state.is_empty():
		return

	var was_awaiting_level_up := bool(state.get("awaiting_level_up", false))
	state["xp"] = int(state.get("xp", 0)) + amount
	state = _consume_ready_level_ups(state)
	_player_states[peer_id] = state
	_send_player_state(peer_id)
	if not was_awaiting_level_up and bool(state.get("awaiting_level_up", false)):
		_galaxy.rpc_id(peer_id, "client_level_up_options", state.get("level_up_options", []), _build_player_payload(peer_id))


func _consume_ready_level_ups(state: Dictionary) -> Dictionary:
	if state.is_empty():
		return state

	while int(state.get("xp", 0)) >= max(int(state.get("xp_to_next", _galaxy.starting_xp_to_next_level)), 1):
		var level_up_options := _build_level_up_options(state)
		if level_up_options.is_empty():
			return state

		var xp_to_next: int = max(int(state.get("xp_to_next", _galaxy.starting_xp_to_next_level)), 1)
		state["xp"] = maxi(int(state.get("xp", 0)) - xp_to_next, 0)
		state["level"] = maxi(int(state.get("level", 1)) + 1, 1)
		state["xp_to_next"] = maxi(int(_galaxy.call("_get_next_xp_threshold", int(state["level"]))), 1)
		state = _queue_level_up_choice(state, level_up_options)

	return state


func _queue_level_up_choice(state: Dictionary, level_up_options: Array) -> Dictionary:
	if state.is_empty() or level_up_options.is_empty():
		return state

	if bool(state.get("awaiting_level_up", false)):
		var queued_options: Array = state.get("queued_level_up_options", [])
		queued_options.append(level_up_options.duplicate(true))
		state["queued_level_up_options"] = queued_options
		return state

	state["awaiting_level_up"] = true
	state["level_up_options"] = level_up_options.duplicate(true)
	return state


func _show_next_queued_level_up_choice(state: Dictionary) -> Dictionary:
	if state.is_empty() or bool(state.get("awaiting_level_up", false)):
		return state

	var queued_options: Array = state.get("queued_level_up_options", [])
	if queued_options.is_empty():
		state["queued_level_up_options"] = queued_options
		return state

	var next_options: Array = queued_options.pop_front()
	state["queued_level_up_options"] = queued_options
	state["awaiting_level_up"] = true
	state["level_up_options"] = next_options.duplicate(true)
	return state


func _build_level_up_options(state: Dictionary) -> Array:
	var player_ship := state.get("ship", null) as Node2D
	if _galaxy.item_field == null or not _galaxy.item_field.has_method("get_random_upgrade_options"):
		return []

	var raw_options: Array = _galaxy.item_field.call("get_random_upgrade_options", 3, _rng)
	var options: Array = []
	for raw_option in raw_options:
		if not (raw_option is Dictionary):
			continue
		var option := (raw_option as Dictionary).duplicate(true)
		option.erase("scene")
		option.erase("icon_texture")
		if player_ship != null and is_instance_valid(player_ship) and player_ship.has_method("get_upgrade_preview"):
			var preview: Dictionary = player_ship.call(
				"get_upgrade_preview",
				StringName(option.get("item_kind", ItemPickup.ITEM_LASER)),
				maxi(int(option.get("item_level", 1)), 1),
				maxi(int(option.get("repair_amount", 4)), 0)
			)
			for key in preview.keys():
				if key != "icon_texture":
					option[key] = preview[key]
		options.append(option)
	return options


func _server_collect_item_for_player(
	peer_id: int,
	item_kind: StringName,
	item_level: int = 1,
	repair_amount: int = 4,
	source_world_position: Vector2 = Vector2.ZERO,
	broadcast: bool = true
) -> bool:
	var state: Dictionary = _player_states.get(peer_id, {})
	if state.is_empty() or not bool(state.get("alive", true)):
		return false

	var player_ship := state.get("ship", null) as Node2D
	if player_ship == null or not is_instance_valid(player_ship) or not player_ship.has_method("collect_item"):
		return false

	_suppress_inventory_broadcast = true
	player_ship.call(
		"collect_item",
		item_kind,
		maxi(item_level, 1),
		maxi(repair_amount, 0),
		source_world_position
	)
	_suppress_inventory_broadcast = false

	state = _player_states.get(peer_id, state)
	if player_ship.has_method("get_inventory_levels"):
		state["inventory"] = (player_ship.call("get_inventory_levels") as Dictionary).duplicate(true)
	if player_ship.has_method("get_shield_hit_points"):
		state["shield_hp"] = max(int(player_ship.call("get_shield_hit_points")), 0)
	if player_ship.has_method("get_max_shield_hit_points"):
		state["max_shield_hp"] = max(int(player_ship.call("get_max_shield_hit_points")), 0)
	if player_ship.has_method("get_shield_level"):
		state["shield_level"] = max(int(player_ship.call("get_shield_level")), 0)
	_player_states[peer_id] = state
	if broadcast:
		_broadcast_player_state(peer_id)
	return true


func _process_item_pickups(delta: float) -> void:
	if _galaxy.item_field == null:
		return

	for item_node in _galaxy.item_field.get_children():
		var item := item_node as ItemPickup
		if item == null or not is_instance_valid(item):
			continue

		var closest_pickup_peer_id := 0
		var closest_pickup_distance := INF
		var closest_attraction_peer_id := 0
		var closest_attraction_distance := INF
		var closest_attraction_radius := 0.0
		for peer_id_variant in _player_states.keys():
			var peer_id := int(peer_id_variant)
			var state: Dictionary = _player_states.get(peer_id, {})
			if not bool(state.get("alive", true)):
				continue
			var player_ship := state.get("ship", null) as Node2D
			if player_ship == null or not is_instance_valid(player_ship):
				continue

			var ship_distance := player_ship.global_position.distance_to(item.global_position)
			var pickup_distance := _get_touch_radius(player_ship) + _get_touch_radius(item) + NETWORK_ITEM_PICKUP_PADDING
			if pickup_distance > 0.0 and ship_distance <= pickup_distance and ship_distance < closest_pickup_distance:
				closest_pickup_peer_id = peer_id
				closest_pickup_distance = ship_distance

			var attraction_radius := _get_pickup_attraction_radius(player_ship)
			if attraction_radius > 0.0 and ship_distance <= attraction_radius and ship_distance < closest_attraction_distance:
				closest_attraction_peer_id = peer_id
				closest_attraction_distance = ship_distance
				closest_attraction_radius = attraction_radius

		if closest_pickup_peer_id > 0:
			if not _server_collect_item_for_player(closest_pickup_peer_id, item.item_kind, item.item_level, item.repair_amount, item.global_position):
				continue
			var item_id := item.network_id
			item.queue_free()
			_galaxy.rpc("client_item_removed", item_id)
			continue

		if closest_attraction_peer_id <= 0:
			item.reset_attraction()
			continue

		var attraction_state: Dictionary = _player_states.get(closest_attraction_peer_id, {})
		var attraction_ship := attraction_state.get("ship", null) as Node2D
		if attraction_ship == null or not is_instance_valid(attraction_ship):
			item.reset_attraction()
			continue

		item.attract_toward_world_position(attraction_ship.global_position, delta, closest_attraction_radius)

		var final_pickup_distance := _get_touch_radius(attraction_ship) + _get_touch_radius(item) + NETWORK_ITEM_PICKUP_PADDING
		if final_pickup_distance <= 0.0:
			continue
		if attraction_ship.global_position.distance_to(item.global_position) > final_pickup_distance:
			continue
		if not _server_collect_item_for_player(closest_attraction_peer_id, item.item_kind, item.item_level, item.repair_amount, item.global_position):
			continue

		var attracted_item_id := item.network_id
		item.queue_free()
		_galaxy.rpc("client_item_removed", attracted_item_id)


func _server_try_invade_planet(peer_id: int, planet_network_id: int) -> bool:
	var state: Dictionary = _player_states.get(peer_id, {})
	if state.is_empty() or not bool(state.get("alive", true)):
		return false

	var planet := _get_planet_by_network_id(planet_network_id)
	var player_ship := state.get("ship", null) as Node2D
	if planet == null or player_ship == null or not is_instance_valid(player_ship):
		return false

	var conquered: Dictionary = state.get("conquered_planet_ids", {})
	if conquered.has(planet_network_id):
		return false
	var colonizing: Dictionary = state.get("colonizing_planet_ids", {})
	if colonizing.has(planet_network_id):
		return false

	var colonize_distance := maxf(float(_galaxy.get("planet_colonize_range")), 0.0) + planet.get_touch_radius()
	if player_ship.global_position.distance_to(planet.global_position) > colonize_distance:
		return false
	if not player_ship.has_method("consume_item"):
		return false
	if not bool(player_ship.call("consume_item", ItemPickup.ITEM_COLONY_BEACON, 1)):
		return false

	colonizing[planet_network_id] = true
	state["colonizing_planet_ids"] = colonizing
	if player_ship.has_method("get_inventory_levels"):
		state["inventory"] = (player_ship.call("get_inventory_levels") as Dictionary).duplicate(true)
	_player_states[peer_id] = state

	var target_position := _get_colony_beacon_landing_position_for_ship(player_ship, planet)
	var launch_direction := _get_colony_beacon_launch_direction_for_ship(player_ship, target_position)
	var launch_origin := _get_colony_beacon_launch_origin_for_ship(player_ship, launch_direction)
	_galaxy.call(
		"_play_colony_beacon_deployment",
		launch_origin,
		planet,
		Callable(self, "_server_finish_colony_beacon_deployment").bind(peer_id, planet_network_id),
		launch_direction
	)
	_galaxy.rpc("client_colony_beacon_deployed", peer_id, planet_network_id, launch_origin, launch_direction)
	return true


func _server_finish_colony_beacon_deployment(peer_id: int, planet_network_id: int) -> void:
	var state: Dictionary = _player_states.get(peer_id, {})
	if state.is_empty() or not bool(state.get("alive", true)):
		return

	var colonizing: Dictionary = state.get("colonizing_planet_ids", {})
	if not colonizing.has(planet_network_id):
		return

	colonizing.erase(planet_network_id)
	var conquered: Dictionary = state.get("conquered_planet_ids", {})
	conquered[planet_network_id] = true
	state["colonizing_planet_ids"] = colonizing
	state["conquered_planet_ids"] = conquered
	_player_states[peer_id] = state
	_send_player_state(peer_id)
	_check_network_winner(peer_id)


func _get_colony_beacon_landing_position_for_ship(player_ship: Node2D, planet: Planet) -> Vector2:
	var origin := player_ship.global_position if player_ship != null and is_instance_valid(player_ship) else planet.global_position + Vector2.UP
	var direction := planet.global_position - origin
	if direction.length_squared() <= 0.001:
		direction = Vector2.DOWN
	else:
		direction = direction.normalized()

	var planet_radius := maxf(planet.get_touch_radius(), 1.0)
	return planet.global_position - direction * planet_radius * COLONY_BEACON_LANDING_SURFACE_RATIO


func _get_colony_beacon_launch_direction_for_ship(player_ship: Node2D, target_world_position: Vector2) -> Vector2:
	if player_ship != null and is_instance_valid(player_ship) and player_ship.has_method("get_artifact_forward_direction"):
		var ship_direction := player_ship.call("get_artifact_forward_direction") as Vector2
		if ship_direction != Vector2.ZERO:
			return ship_direction.normalized()
	if player_ship != null and is_instance_valid(player_ship):
		var target_direction := (target_world_position - player_ship.global_position).normalized()
		if target_direction != Vector2.ZERO:
			return target_direction

	return Vector2.UP


func _get_colony_beacon_launch_origin_for_ship(player_ship: Node2D, launch_direction: Vector2) -> Vector2:
	if player_ship != null and is_instance_valid(player_ship) and player_ship.has_method("get_artifact_launch_origin"):
		return player_ship.call("get_artifact_launch_origin") as Vector2
	if player_ship != null and is_instance_valid(player_ship):
		return player_ship.global_position + launch_direction.normalized() * 48.0

	return Vector2.ZERO


func _check_network_winner(peer_id: int) -> void:
	var state: Dictionary = _player_states.get(peer_id, {})
	var conquered: Dictionary = state.get("conquered_planet_ids", {})
	if _get_planets().size() <= 0 or conquered.size() < _get_planets().size():
		return

	_galaxy.set("_has_game_over", true)
	_match_winner_peer_id = peer_id
	_match_winner_name = str(state.get("display_name", "Player%d" % peer_id))
	_galaxy.rpc("client_match_ended", _match_winner_peer_id, _match_winner_name)
	set_status("%s conquered the galaxy." % _match_winner_name)


func _send_initial_state(peer_id: int) -> void:
	_galaxy.rpc_id(peer_id, "client_receive_initial_state", {
		"local_peer_id": peer_id,
		"display_name": str(_player_names.get(peer_id, "Player%d" % peer_id)),
		"players": _build_all_player_payloads(),
		"planets": _build_planet_states(),
		"items": _build_item_states(),
		"enemies": _build_enemy_states(),
	})


func _send_player_state(peer_id: int) -> void:
	if not _player_states.has(peer_id):
		return
	_galaxy.rpc_id(peer_id, "client_player_state", _build_player_payload(peer_id))


func _broadcast_player_state(peer_id: int) -> void:
	if not _player_states.has(peer_id):
		return
	_galaxy.rpc("client_player_state", _build_player_payload(peer_id))


func _send_network_snapshot() -> void:
	if _player_states.is_empty():
		return

	_galaxy.rpc("client_apply_snapshot", {
		"players": _build_all_player_snapshot_rows(),
		"items": _build_item_snapshot_rows(),
		"enemies": _build_enemy_snapshot_rows(),
		"wave_time_left": float(_galaxy.enemy_field.call("get_wave_time_left")) if _galaxy.enemy_field != null and _galaxy.enemy_field.has_method("get_wave_time_left") else 0.0,
		"next_wave_size": int(_galaxy.enemy_field.call("get_next_wave_size")) if _galaxy.enemy_field != null and _galaxy.enemy_field.has_method("get_next_wave_size") else 0,
	})


func _build_all_player_payloads() -> Array:
	var payloads: Array = []
	for peer_id_variant in _player_states.keys():
		payloads.append(_build_player_payload(int(peer_id_variant)))
	return payloads


func _build_all_player_snapshot_rows() -> Array:
	var snapshots: Array = []
	for peer_id_variant in _player_states.keys():
		var peer_id := int(peer_id_variant)
		var state: Dictionary = _player_states.get(peer_id, {})
		var player_ship := state.get("ship", null) as Node2D
		snapshots.append([
			peer_id,
			player_ship.global_position if player_ship != null and is_instance_valid(player_ship) else Vector2.ZERO,
			player_ship.rotation if player_ship != null and is_instance_valid(player_ship) else 0.0,
			bool(state.get("alive", true)),
		])
	return snapshots


func _build_item_snapshot_rows() -> Array:
	var snapshots: Array = []
	if _galaxy.item_field == null:
		return snapshots

	for child in _galaxy.item_field.get_children():
		var item := child as ItemPickup
		if item == null or not is_instance_valid(item):
			continue
		snapshots.append([
			item.network_id,
			item.position,
		])

	return snapshots


func _build_player_payload(peer_id: int) -> Dictionary:
	var state: Dictionary = _player_states.get(peer_id, {})
	var player_ship := state.get("ship", null) as Node2D
	var conquered: Dictionary = state.get("conquered_planet_ids", {})
	var conquered_ids: Array[int] = []
	for planet_id_variant in conquered.keys():
		conquered_ids.append(int(planet_id_variant))

	return {
		"peer_id": peer_id,
		"display_name": str(state.get("display_name", "Player%d" % peer_id)),
		"position": player_ship.global_position if player_ship != null and is_instance_valid(player_ship) else Vector2.ZERO,
		"rotation": player_ship.rotation if player_ship != null and is_instance_valid(player_ship) else 0.0,
		"hp": int(state.get("hp", 0)),
		"max_hp": int(state.get("max_hp", 1)),
		"shield_hp": int(state.get("shield_hp", 0)),
		"max_shield_hp": int(state.get("max_shield_hp", 0)),
		"shield_level": int(state.get("shield_level", 0)),
		"xp": int(state.get("xp", 0)),
		"level": int(state.get("level", 1)),
		"xp_to_next": int(state.get("xp_to_next", _galaxy.starting_xp_to_next_level)),
		"inventory": (state.get("inventory", {}) as Dictionary).duplicate(true),
		"conquered_planet_ids": conquered_ids,
		"alive": bool(state.get("alive", true)),
		"god_mode": bool(state.get("god_mode", false)),
		"no_artifact_cooldowns": bool(state.get("no_artifact_cooldowns", false)),
		"awaiting_level_up": bool(state.get("awaiting_level_up", false)),
	}


func _build_planet_states() -> Array:
	var states: Array = []
	for planet in _get_planets():
		states.append(planet.to_network_state())
	return states


func _build_item_states() -> Array:
	var states: Array = []
	if _galaxy.item_field == null:
		return states
	for child in _galaxy.item_field.get_children():
		var item := child as ItemPickup
		if item == null:
			continue
		states.append(_build_item_state(item))
	return states


func _build_item_state(item: ItemPickup) -> Dictionary:
	return {
		"network_id": item.network_id,
		"item_kind": item.item_kind,
		"item_level": item.item_level,
		"repair_amount": item.repair_amount,
		"position": item.position,
		"z_index": item.z_index,
	}


func _build_enemy_states() -> Array:
	var states: Array = []
	if _galaxy.enemy_field == null:
		return states
	for child in _galaxy.enemy_field.get_children():
		var enemy := child as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		states.append({
			"network_id": enemy.network_id,
			"scene_key": enemy.network_scene_key,
			"position": enemy.position,
			"rotation": enemy.rotation,
		})
	return states


func _build_enemy_snapshot_rows() -> Array:
	var states: Array = []
	if _galaxy.enemy_field == null:
		return states
	for child in _galaxy.enemy_field.get_children():
		var enemy := child as Enemy
		if enemy == null or not is_instance_valid(enemy):
			continue
		states.append([
			enemy.network_id,
			enemy.network_scene_key,
			enemy.position,
			enemy.rotation,
		])
	return states


func _apply_planet_states(states: Array) -> void:
	var planets := _get_planets()
	for index in range(mini(planets.size(), states.size())):
		var planet_state := states[index] as Dictionary
		if planet_state == null:
			continue
		planets[index].apply_network_state(planet_state)


func _apply_item_states(states: Array) -> void:
	if _galaxy.item_field == null:
		return

	for child in _galaxy.item_field.get_children():
		child.queue_free()
	_client_item_nodes.clear()
	for state in states:
		if state is Dictionary:
			_spawn_client_item(state as Dictionary)


func _spawn_client_item(state: Dictionary) -> void:
	if _galaxy.item_field == null or not _galaxy.item_field.has_method("create_item_for_network"):
		return

	var item_id := int(state.get("network_id", 0))
	if item_id <= 0:
		return
	var existing_item := _client_item_nodes.get(item_id, null) as Node
	if existing_item != null and is_instance_valid(existing_item):
		return

	var item := _galaxy.item_field.call("create_item_for_network", state) as ItemPickup
	if item == null:
		return
	item.set_process(false)
	_client_item_nodes[item_id] = item


func _apply_player_state(player_state: Dictionary) -> void:
	var peer_id := int(player_state.get("peer_id", 0))
	if peer_id <= 0:
		return

	var is_local := peer_id == _local_peer_id
	var existing_ship := _players_by_peer_id.get(peer_id, null) as Node2D
	var is_new_local_ship := is_local and (existing_ship == null or not is_instance_valid(existing_ship))
	var player_ship := _spawn_player_ship(peer_id, player_state.get("position", Vector2.ZERO) as Vector2, is_local, false)
	if player_ship != null and player_ship.has_method("apply_network_status"):
		player_ship.call(
			"apply_network_status",
			int(player_state.get("hp", 0)),
			int(player_state.get("max_hp", 1))
		)
	if player_ship != null and player_ship.has_method("set_network_snapshot"):
		player_ship.call(
			"set_network_snapshot",
			player_state.get("position", Vector2.ZERO) as Vector2,
			float(player_state.get("rotation", 0.0)),
			not bool(player_state.get("alive", true))
		)
	if player_ship != null and player_ship.has_method("apply_network_inventory"):
		player_ship.call("apply_network_inventory", player_state.get("inventory", {}) as Dictionary)
	if player_ship != null and player_ship.has_method("apply_network_shield"):
		player_ship.call(
			"apply_network_shield",
			int(player_state.get("shield_hp", 0)),
			int(player_state.get("max_shield_hp", 0)),
			int(player_state.get("shield_level", 0))
		)
	if player_ship != null and player_ship.has_method("set_god_mode_enabled"):
		player_ship.call("set_god_mode_enabled", bool(player_state.get("god_mode", false)))
	if player_ship != null and player_ship.has_method("set_debug_no_artifact_cooldowns"):
		player_ship.call("set_debug_no_artifact_cooldowns", bool(player_state.get("no_artifact_cooldowns", false)))
	_player_states[peer_id] = player_state.duplicate(true)
	_player_names[peer_id] = str(player_state.get("display_name", "Player%d" % peer_id))

	if is_local:
		_apply_local_player_state(player_state)
		if is_new_local_ship:
			_galaxy.call("_reset_fog_of_war_reveal")


func _apply_player_snapshot(player_state: Dictionary) -> void:
	var peer_id := int(player_state.get("peer_id", 0))
	if peer_id <= 0:
		return

	if not _players_by_peer_id.has(peer_id):
		_apply_player_state(player_state)
		return

	var player_ship := _players_by_peer_id.get(peer_id, null) as Node2D
	if player_ship != null and is_instance_valid(player_ship) and player_ship.has_method("set_network_snapshot"):
		player_ship.call(
			"set_network_snapshot",
			player_state.get("position", Vector2.ZERO) as Vector2,
			float(player_state.get("rotation", 0.0)),
			not bool(player_state.get("alive", true))
		)
	if peer_id == _local_peer_id:
		_update_local_game_over_state(bool(player_state.get("alive", true)))
		_apply_local_player_state(player_state)


func _apply_player_snapshot_row(row: Array) -> void:
	if row.size() < 4:
		return

	var peer_id := int(row[0])
	if peer_id <= 0:
		return
	var snapshot_state := {
		"peer_id": peer_id,
		"display_name": str(_player_names.get(peer_id, "Player%d" % peer_id)),
		"position": row[1] as Vector2,
		"rotation": float(row[2]),
		"alive": bool(row[3]),
	}
	if not _players_by_peer_id.has(peer_id):
		_apply_player_state(snapshot_state)
		return

	var player_ship := _players_by_peer_id.get(peer_id, null) as Node2D
	if player_ship != null and is_instance_valid(player_ship) and player_ship.has_method("set_network_snapshot"):
		player_ship.call("set_network_snapshot", row[1] as Vector2, float(row[2]), not bool(row[3]))
	if peer_id == _local_peer_id:
		_update_local_game_over_state(bool(row[3]))


func _apply_item_snapshot_rows(rows: Array) -> void:
	if _galaxy.item_field == null:
		return

	for row_variant in rows:
		if not (row_variant is Array):
			continue
		var row := row_variant as Array
		if row.size() < 2:
			continue

		var item_id := int(row[0])
		if item_id <= 0:
			continue

		var item := _client_item_nodes.get(item_id, null) as ItemPickup
		if item == null or not is_instance_valid(item):
			continue
		if item.has_method("is_spawn_animating") and bool(item.call("is_spawn_animating")):
			continue

		item.position = row[1] as Vector2


func _apply_local_player_state(player_state: Dictionary) -> void:
	_update_local_game_over_state(bool(player_state.get("alive", true)))
	_galaxy.set("_ship_current_hp", max(int(player_state.get("hp", _galaxy.get("_ship_current_hp"))), 0))
	_galaxy.set("_ship_max_hp", max(int(player_state.get("max_hp", _galaxy.get("_ship_max_hp"))), 1))
	_galaxy.set("_ship_current_shield_hp", max(int(player_state.get("shield_hp", _galaxy.get("_ship_current_shield_hp"))), 0))
	_galaxy.set("_ship_max_shield_hp", max(int(player_state.get("max_shield_hp", _galaxy.get("_ship_max_shield_hp"))), 0))
	_galaxy.set("_ship_shield_level", max(int(player_state.get("shield_level", _galaxy.get("_ship_shield_level"))), 0))
	_galaxy.set("_ship_level", max(int(player_state.get("level", _galaxy.get("_ship_level"))), 1))
	_galaxy.set("_ship_xp", max(int(player_state.get("xp", _galaxy.get("_ship_xp"))), 0))
	_galaxy.set("_ship_xp_to_next_level", max(int(player_state.get("xp_to_next", _galaxy.get("_ship_xp_to_next_level"))), 1))
	_galaxy.set("_ship_inventory_levels", (player_state.get("inventory", {}) as Dictionary).duplicate(true))
	_galaxy.set("_debug_god_mode_enabled", bool(player_state.get("god_mode", _galaxy.get("_debug_god_mode_enabled"))))
	_galaxy.set(
		"_debug_no_artifact_cooldowns_enabled",
		bool(player_state.get("no_artifact_cooldowns", _galaxy.get("_debug_no_artifact_cooldowns_enabled")))
	)
	var conquered_ids: Array = player_state.get("conquered_planet_ids", [])
	var conquered_lookup := {}
	for planet_id_variant in conquered_ids:
		conquered_lookup[int(planet_id_variant)] = true
	_galaxy.set("_conquered_planet_ids", conquered_lookup)
	_galaxy.set("_planets_invaded_count", conquered_ids.size())
	_galaxy.set("_planets_total_count", _galaxy.call("_get_total_planet_count"))
	_apply_local_conquered_planets(conquered_ids)
	_galaxy.call("_refresh_inventory_ui")
	_galaxy.call("_refresh_top_bar")


func _update_local_game_over_state(is_alive: bool) -> void:
	if is_alive:
		if bool(_galaxy.get("_has_game_over")):
			_galaxy.call("_deactivate_game_over")
		return
	if bool(_galaxy.get("_has_game_over")):
		return
	_galaxy.call("_activate_game_over")


func _apply_local_conquered_planets(conquered_ids: Array) -> void:
	var conquered_lookup := {}
	for planet_id_variant in conquered_ids:
		conquered_lookup[int(planet_id_variant)] = true
	for planet in _get_planets():
		planet.set_conquered(conquered_lookup.has(planet.network_id))


func _apply_enemy_states(states: Array) -> void:
	if _galaxy.enemy_field == null:
		return

	var seen_ids := {}
	for state_variant in states:
		if not (state_variant is Dictionary):
			continue
		var state := state_variant as Dictionary
		var enemy_id := int(state.get("network_id", 0))
		if enemy_id <= 0:
			continue
		if _destroyed_enemy_ids.has(enemy_id):
			continue
		seen_ids[enemy_id] = true
		var enemy := _client_enemy_nodes.get(enemy_id, null) as Enemy
		if enemy == null or not is_instance_valid(enemy):
			enemy = _galaxy.enemy_field.call("create_enemy_for_network", StringName(state.get("scene_key", &"enemy")), enemy_id) as Enemy
			if enemy == null:
				continue
			_client_enemy_nodes[enemy_id] = enemy
		enemy.position = state.get("position", Vector2.ZERO) as Vector2
		enemy.rotation = float(state.get("rotation", 0.0))

	for enemy_id_variant in _client_enemy_nodes.keys():
		var enemy_id := int(enemy_id_variant)
		if seen_ids.has(enemy_id):
			continue
		var stale_enemy := _client_enemy_nodes.get(enemy_id, null) as Node
		var stale_scene_key := &"enemy"
		var stale_position := Vector2.ZERO
		var stale_rotation := 0.0
		if stale_enemy is Enemy:
			stale_scene_key = (stale_enemy as Enemy).network_scene_key
		if stale_enemy is Node2D:
			stale_position = (stale_enemy as Node2D).global_position
			stale_rotation = (stale_enemy as Node2D).rotation
		_explode_and_remove_client_enemy(enemy_id, stale_scene_key, stale_position, stale_rotation)


func _apply_enemy_snapshot_rows(rows: Array) -> void:
	if _galaxy.enemy_field == null:
		return

	var seen_ids := {}
	for row_variant in rows:
		if not (row_variant is Array):
			continue
		var row := row_variant as Array
		if row.size() < 4:
			continue
		var enemy_id := int(row[0])
		if enemy_id <= 0:
			continue
		if _destroyed_enemy_ids.has(enemy_id):
			continue
		seen_ids[enemy_id] = true
		var enemy := _client_enemy_nodes.get(enemy_id, null) as Enemy
		if enemy == null or not is_instance_valid(enemy):
			enemy = _galaxy.enemy_field.call("create_enemy_for_network", StringName(row[1]), enemy_id) as Enemy
			if enemy == null:
				continue
			_client_enemy_nodes[enemy_id] = enemy
		enemy.position = row[2] as Vector2
		enemy.rotation = float(row[3])

	for enemy_id_variant in _client_enemy_nodes.keys():
		var enemy_id := int(enemy_id_variant)
		if seen_ids.has(enemy_id):
			continue
		var stale_enemy := _client_enemy_nodes.get(enemy_id, null) as Node
		var stale_scene_key := &"enemy"
		var stale_position := Vector2.ZERO
		var stale_rotation := 0.0
		if stale_enemy is Enemy:
			stale_scene_key = (stale_enemy as Enemy).network_scene_key
		if stale_enemy is Node2D:
			stale_position = (stale_enemy as Node2D).global_position
			stale_rotation = (stale_enemy as Node2D).rotation
		_explode_and_remove_client_enemy(enemy_id, stale_scene_key, stale_position, stale_rotation)


func _explode_and_remove_client_enemy(enemy_network_id: int, scene_key: StringName, world_position: Vector2, world_rotation: float) -> void:
	if enemy_network_id <= 0 or _galaxy.enemy_field == null:
		return

	var enemy := _client_enemy_nodes.get(enemy_network_id, null) as Enemy
	if enemy == null or not is_instance_valid(enemy):
		if _destroyed_enemy_ids.has(enemy_network_id):
			return
		if not _galaxy.enemy_field.has_method("create_enemy_for_network"):
			_destroyed_enemy_ids[enemy_network_id] = true
			return
		enemy = _galaxy.enemy_field.call("create_enemy_for_network", scene_key, enemy_network_id) as Enemy
		if enemy == null:
			_destroyed_enemy_ids[enemy_network_id] = true
			return
		enemy.global_position = world_position
		enemy.rotation = world_rotation

	_client_enemy_nodes.erase(enemy_network_id)
	if _destroyed_enemy_ids.has(enemy_network_id):
		enemy.queue_free()
		return

	_destroyed_enemy_ids[enemy_network_id] = true
	if _galaxy.has_method("_spawn_enemy_explosion"):
		_galaxy.call("_spawn_enemy_explosion", enemy)
	enemy.queue_free()


func _assign_planet_network_ids() -> void:
	var next_id := 1
	for planet in _get_planets():
		planet.network_id = next_id
		next_id += 1


func _assign_existing_item_network_ids() -> void:
	if _galaxy.item_field == null:
		return
	for child in _galaxy.item_field.get_children():
		var item := child as ItemPickup
		if item == null:
			continue
		if item.network_id <= 0:
			item.network_id = _next_item_network_id
			_next_item_network_id += 1


func _get_planets() -> Array[Planet]:
	var planets: Array[Planet] = []
	if _galaxy.planet_field == null:
		return planets
	for child in _galaxy.planet_field.get_children():
		var planet := child as Planet
		if planet != null:
			planets.append(planet)
	return planets


func _get_planet_by_network_id(planet_network_id: int) -> Planet:
	for planet in _get_planets():
		if planet.network_id == planet_network_id:
			return planet
	return null


func _resolve_weapon_target(target_state: Dictionary) -> Node2D:
	var target_kind := str(target_state.get("kind", ""))
	var target_id := int(target_state.get("id", 0))
	if target_id <= 0:
		return null

	if target_kind == "enemy":
		return _client_enemy_nodes.get(target_id, null) as Node2D
	if target_kind == "player":
		return _players_by_peer_id.get(target_id, null) as Node2D
	if target_kind == "explorer_beacon":
		return _get_explorer_beacon_by_network_id(target_id)

	return null


func _get_explorer_beacon_by_network_id(network_id: int) -> Node2D:
	if network_id <= 0 or _galaxy == null or _galaxy.get_tree() == null:
		return null

	for beacon_node in _galaxy.get_tree().get_nodes_in_group(&"explorer_beacons"):
		var beacon := beacon_node as Node2D
		if beacon == null or not is_instance_valid(beacon):
			continue
		if int(beacon.get("network_id")) != network_id:
			continue

		return beacon

	return null


func _pick_player_spawn_position() -> Vector2:
	var safe_radius := maxf(float(_galaxy.call("get_world_radius")) * 0.85, 1.0)
	for _attempt in range(32):
		var candidate := Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) * _rng.randf_range(0.0, safe_radius)
		var is_clear := true
		for other_ship_variant in _players_by_peer_id.values():
			var other_ship := other_ship_variant as Node2D
			if other_ship != null and is_instance_valid(other_ship) and other_ship.global_position.distance_to(candidate) < 800.0:
				is_clear = false
				break
		if is_clear:
			return candidate
	return Vector2.RIGHT.rotated(_rng.randf_range(0.0, TAU)) * _rng.randf_range(0.0, safe_radius)


func _update_minimap_ship_path(player_ship: Node2D) -> void:
	var minimap: Node = _galaxy.get_node_or_null("UI/Minimap")
	if minimap == null or player_ship == null:
		return
	minimap.set("ship_path", _galaxy.get_path_to(player_ship))


func _server_spawn_xp_box(
	world_position: Vector2,
	xp_amount: int,
	spawn_origin: Vector2 = Vector2.ZERO,
	spawn_initial_velocity: Vector2 = Vector2.ZERO,
	spawn_duration: float = 0.0,
	spawn_delay: float = 0.0,
	animate_spawn: bool = false
) -> void:
	if _galaxy.item_field == null or xp_amount <= 0:
		return
	var state := {
		"network_id": _next_item_network_id,
		"item_kind": ItemPickup.ITEM_XP_BOX,
		"item_level": xp_amount,
		"repair_amount": 0,
		"position": world_position,
		"z_index": -10,
	}
	if animate_spawn:
		state["spawn_origin"] = spawn_origin
		state["spawn_initial_velocity"] = spawn_initial_velocity
		state["spawn_duration"] = maxf(spawn_duration, 0.01)
		state["spawn_delay"] = maxf(spawn_delay, 0.0)
	_next_item_network_id += 1
	var item := _galaxy.item_field.call("create_item_for_network", state) as ItemPickup
	if item != null:
		item.set_process(false)
	_galaxy.rpc("client_item_spawned", state)


func _spawn_player_death_xp_boxes(world_position: Vector2) -> void:
	var drop_count := maxi(int(_galaxy.get("player_death_xp_box_count")), 1)
	var xp_per_box := maxi(int(_galaxy.get("player_death_xp_per_box")), 1)
	var splash_duration := maxf(float(_galaxy.get("player_death_xp_splash_duration")), 0.01)
	var splash_min_speed := maxf(float(_galaxy.get("player_death_xp_splash_min_speed")), 0.0)
	var splash_max_speed := maxf(float(_galaxy.get("player_death_xp_splash_max_speed")), splash_min_speed)
	var splash_stagger := maxf(float(_galaxy.get("player_death_xp_splash_stagger")), 0.0)
	var base_angle := _rng.randf_range(0.0, TAU)
	for index in range(drop_count):
		var progress := float(index) / maxf(float(drop_count - 1), 1.0)
		var splash_speed := lerpf(splash_min_speed, splash_max_speed, progress)
		var splash_angle := base_angle + float(index) * PLAYER_DEATH_XP_SPLASH_GOLDEN_ANGLE
		var splash_velocity := Vector2.RIGHT.rotated(splash_angle) * splash_speed
		var rest_position := world_position + splash_velocity * (splash_duration * 0.5)
		_server_spawn_xp_box(
			rest_position,
			xp_per_box,
			world_position,
			splash_velocity,
			splash_duration,
			float(index) * splash_stagger,
			true
		)


func _get_touch_radius(node: Node) -> float:
	if node != null and node.has_method("get_touch_radius"):
		return float(node.call("get_touch_radius"))

	return 0.0


func _get_pickup_attraction_radius(node: Node) -> float:
	if node != null and node.has_method("get_pickup_attraction_radius"):
		return float(node.call("get_pickup_attraction_radius"))

	return 0.0
