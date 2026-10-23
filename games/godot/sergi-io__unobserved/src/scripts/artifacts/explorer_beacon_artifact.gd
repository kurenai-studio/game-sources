class_name ExplorerBeaconArtifact
extends ShipArtifact

const EXPLORER_BEACON_SCENE: PackedScene = preload("res://scenes/artifacts/explorer_beacon.tscn")
const EXPLORER_BEACON_PLACEMENT_PREVIEW_SCRIPT: Script = preload("res://scripts/artifacts/explorer_beacon_placement_preview.gd")
const DEFAULT_BASE_VISION_RADIUS: float = 900.0

@export_range(100.0, 24000.0, 50.0) var beacon_speed: float = 600.0
@export_range(1.0, 8.0, 0.1) var vision_radius_multiplier: float = 2.0
@export_range(1, 999, 1) var beacon_hit_points: int = 4
@export_range(64.0, 4000.0, 10.0) var direction_preview_radius: float = 525.0

var _next_beacon_network_id: int = 1


func _init() -> void:
	item_kind = &"explorer_beacon"
	cooldown_seconds = 12.0


func get_upgrade_preview() -> Dictionary:
	var safe_cooldown_seconds := get_cooldown_duration()
	return {
		"title": "Explorer Beacon",
		"summary": "Artifact beacon: %sx ship vision\nCooldown: %s" % [
			_format_number(maxf(vision_radius_multiplier, 1.0), 1),
			_format_duration(safe_cooldown_seconds),
		],
		"tooltip": "Unlocks an Artifact Hud button.\nActivating it arms deployment; click the galaxy or minimap to launch a scout beacon in that direction. The beacon never stops and grants %sx ship vision until destroyed or out of bounds.\nCooldown: %s" % [
			_format_number(maxf(vision_radius_multiplier, 1.0), 1),
			_format_duration(safe_cooldown_seconds),
		],
	}


func activate_at(world_position: Vector2) -> bool:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return false

	var deploy_direction := _get_launch_direction()
	var launch_origin := _get_deploy_origin(deploy_direction)
	var launch_direction := (world_position - owner_ship.global_position).normalized()
	if launch_direction == Vector2.ZERO:
		launch_direction = deploy_direction
	if launch_direction == Vector2.ZERO:
		return false

	var effect_vision_radius := _get_beacon_vision_radius()
	var effect_world_radius := _get_world_radius()
	var effect_owner_peer_id := int(owner_ship.get("owner_peer_id"))
	var beacon_network_id := _allocate_beacon_network_id(effect_owner_peer_id)
	if _spawn_explorer_beacon(
		launch_origin,
		launch_direction,
		maxf(beacon_speed, 1.0),
		effect_vision_radius,
		maxi(beacon_hit_points, 1),
		effect_world_radius,
		effect_owner_peer_id,
		beacon_network_id,
		true,
		deploy_direction
	) == null:
		return false

	if owner_ship.has_method("pulse_artifact_activation"):
		owner_ship.call("pulse_artifact_activation")
	if owner_ship.has_method("broadcast_artifact_effect"):
		owner_ship.call("broadcast_artifact_effect", &"explorer_beacon_launched", {
			"owner_peer_id": effect_owner_peer_id,
			"network_id": beacon_network_id,
			"launch_origin": launch_origin,
			"launch_direction": launch_direction,
			"beacon_speed": maxf(beacon_speed, 1.0),
			"vision_radius": effect_vision_radius,
			"hit_points": maxi(beacon_hit_points, 1),
			"world_radius": effect_world_radius,
			"deploy_direction": deploy_direction,
		})
	return true


func play_network(payload: Dictionary) -> void:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return

	_spawn_explorer_beacon(
		payload.get("launch_origin", owner_ship.global_position) as Vector2,
		(payload.get("launch_direction", Vector2.RIGHT) as Vector2).normalized(),
		maxf(float(payload.get("beacon_speed", beacon_speed)), 1.0),
		maxf(float(payload.get("vision_radius", _get_beacon_vision_radius())), 1.0),
		maxi(int(payload.get("hit_points", beacon_hit_points)), 1),
		maxf(float(payload.get("world_radius", _get_world_radius())), 1.0),
		int(payload.get("owner_peer_id", owner_ship.get("owner_peer_id"))),
		int(payload.get("network_id", 0)),
		false,
		(payload.get("deploy_direction", _get_launch_direction()) as Vector2).normalized()
	)


func get_tunables() -> Dictionary:
	var tunables := super.get_tunables()
	tunables["beacon_speed"] = beacon_speed
	tunables["vision_radius_multiplier"] = vision_radius_multiplier
	tunables["beacon_hit_points"] = beacon_hit_points
	tunables["direction_preview_radius"] = direction_preview_radius
	return tunables


func apply_tunables(tunables: Dictionary) -> void:
	super.apply_tunables(tunables)
	if tunables.has("beacon_speed"):
		beacon_speed = maxf(float(tunables.get("beacon_speed", beacon_speed)), 1.0)
	if tunables.has("vision_radius_multiplier"):
		vision_radius_multiplier = maxf(float(tunables.get("vision_radius_multiplier", vision_radius_multiplier)), 1.0)
	if tunables.has("beacon_hit_points"):
		beacon_hit_points = maxi(int(tunables.get("beacon_hit_points", beacon_hit_points)), 1)
	if tunables.has("direction_preview_radius"):
		direction_preview_radius = maxf(float(tunables.get("direction_preview_radius", direction_preview_radius)), 1.0)


func create_placement_preview() -> Node2D:
	var placement_preview := EXPLORER_BEACON_PLACEMENT_PREVIEW_SCRIPT.new() as Node2D
	placement_preview.set("owner_ship", owner_ship)
	placement_preview.set("direction_radius", direction_preview_radius)
	return placement_preview


func _spawn_explorer_beacon(
	launch_origin: Vector2,
	launch_direction: Vector2,
	effect_speed: float,
	effect_vision_radius: float,
	effect_hit_points: int,
	effect_world_radius: float,
	effect_owner_peer_id: int,
	effect_network_id: int,
	should_broadcast_destroy: bool,
	deploy_direction: Vector2 = Vector2.ZERO
) -> ExplorerBeacon:
	var spawn_layer := _get_beacon_spawn_layer()
	if spawn_layer == null:
		return null

	var beacon := EXPLORER_BEACON_SCENE.instantiate() as ExplorerBeacon
	if beacon == null:
		return null

	spawn_layer.add_child(beacon)
	beacon.configure(
		launch_origin,
		launch_direction,
		effect_speed,
		effect_vision_radius,
		effect_hit_points,
		effect_world_radius,
		effect_owner_peer_id,
		effect_network_id,
		should_broadcast_destroy,
		deploy_direction
	)
	if beacon.has_method("set_fog_presentation_alpha"):
		var fog_alpha := 1.0
		if owner_ship.has_method("should_show_artifact_effect"):
			fog_alpha = 1.0 if bool(owner_ship.call("should_show_artifact_effect", launch_origin)) else 0.0
		beacon.call("set_fog_presentation_alpha", fog_alpha)
	return beacon


func _get_launch_direction() -> Vector2:
	if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.has_method("get_artifact_forward_direction"):
		var ship_direction := owner_ship.call("get_artifact_forward_direction") as Vector2
		if ship_direction != Vector2.ZERO:
			return ship_direction.normalized()

	return Vector2.RIGHT


func _get_launch_origin() -> Vector2:
	if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.has_method("get_artifact_launch_origin"):
		return owner_ship.call("get_artifact_launch_origin") as Vector2
	if owner_ship != null and is_instance_valid(owner_ship):
		return owner_ship.global_position + _get_launch_direction() * 48.0

	return Vector2.ZERO


func _get_deploy_origin(deploy_direction: Vector2) -> Vector2:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return Vector2.ZERO

	var safe_direction := deploy_direction.normalized()
	if safe_direction == Vector2.ZERO:
		safe_direction = _get_launch_direction()

	var deploy_distance := 48.0
	if owner_ship.has_method("get_touch_radius"):
		deploy_distance = maxf(float(owner_ship.call("get_touch_radius")) * 0.55, deploy_distance)

	return owner_ship.global_position - safe_direction * deploy_distance


func _get_beacon_spawn_layer() -> Node2D:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return null

	return owner_ship.get_parent() as Node2D


func _get_beacon_vision_radius() -> float:
	var base_radius := _get_base_vision_radius()
	var ship_vision_radius := base_radius
	if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.has_method("get_vision_radius"):
		ship_vision_radius = maxf(float(owner_ship.call("get_vision_radius", base_radius)), 1.0)

	return ship_vision_radius * maxf(vision_radius_multiplier, 1.0)


func _get_base_vision_radius() -> float:
	var scene_root := owner_ship.get_tree().current_scene if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.get_tree() != null else null
	if scene_root != null:
		var fog_of_war := scene_root.find_child("FogOfWar", true, false)
		if fog_of_war != null:
			return maxf(float(fog_of_war.get("visible_radius")), 1.0)

	return DEFAULT_BASE_VISION_RADIUS


func _get_world_radius() -> float:
	var scene_root := owner_ship.get_tree().current_scene if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.get_tree() != null else null
	if scene_root != null and scene_root.has_method("get_world_radius"):
		return maxf(float(scene_root.call("get_world_radius")), 1.0)

	return 100000.0


func _allocate_beacon_network_id(owner_peer_id_value: int) -> int:
	var owner_component := maxi(owner_peer_id_value, 0) * 100000
	var beacon_id := owner_component + _next_beacon_network_id
	_next_beacon_network_id += 1
	return beacon_id
