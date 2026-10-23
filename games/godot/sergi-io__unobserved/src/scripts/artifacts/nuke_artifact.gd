class_name NukeArtifact
extends ShipArtifact

const NUKE_BOMB_SCENE: PackedScene = preload("res://scenes/artifacts/nuke_bomb.tscn")
const VORTEX_PLACEMENT_PREVIEW_SCRIPT: Script = preload("res://scripts/artifacts/vortex_placement_preview.gd")

@export_range(64.0, 6000.0, 10.0) var blast_radius: float = 2100.0
@export_range(1, 999, 1) var damage: int = 30
@export_range(100.0, 24000.0, 50.0) var bomb_travel_speed: float = 2600.0
@export_range(0.2, 12.0, 0.05) var explosion_duration_seconds: float = 10.0
@export_group("Damage Timing")
@export_range(0.0, 1.0, 0.01) var blast_growth_duration_ratio: float = 0.36
@export_range(0.0, 1.0, 0.01) var blast_damage_edge_ratio: float = 0.18
@export_range(0.0, 1.0, 0.01) var blast_min_damage_ratio: float = 0.55
@export_range(0.0, 200.0, 0.1) var radiation_damage_per_second: float = 3.0
@export_range(0.05, 5.0, 0.05) var radiation_tick_interval_seconds: float = 1.0
@export_range(0.0, 1.0, 0.01) var radiation_damage_edge_ratio: float = 0.28
@export_range(0.0, 1.0, 0.01) var radiation_min_damage_ratio: float = 0.2


func _init() -> void:
	item_kind = &"nuke"
	cooldown_seconds = 55.0


func get_upgrade_preview() -> Dictionary:
	var safe_blast_radius := maxf(blast_radius, 1.0)
	var safe_cooldown_seconds := get_cooldown_duration()
	return {
		"title": "Nuke",
		"summary": "Artifact nuke: %s px blast\nDamage: %s expanding blast + %s/sec radiation\nCooldown: %s" % [
			_format_number(safe_blast_radius, 0),
			_format_number(float(maxi(damage, 1)), 0),
			_format_number(maxf(radiation_damage_per_second, 0.0), 1),
			_format_duration(safe_cooldown_seconds),
		],
		"tooltip": "Unlocks an Artifact Hud button.\nActivating it arms placement; click the galaxy to launch a nuke from the ship. On impact it blooms into a mushroom-cloud blast that damages ships as the wave reaches them, then burns ships inside the radiation area for %s/sec until the cloud disappears.\nBlast radius: %s px\nCooldown: %s" % [
			_format_number(maxf(radiation_damage_per_second, 0.0), 1),
			_format_number(safe_blast_radius, 0),
			_format_duration(safe_cooldown_seconds),
		],
	}


func activate_at(world_position: Vector2) -> bool:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return false

	var target_position := world_position
	if owner_ship.has_method("clamp_artifact_world_position"):
		target_position = owner_ship.call("clamp_artifact_world_position", world_position) as Vector2

	var launch_direction := _get_launch_direction(target_position)
	var launch_origin := _get_launch_origin(launch_direction)
	if not _spawn_nuke_bomb(
		launch_origin,
		target_position,
		maxf(blast_radius, 1.0),
		maxi(damage, 1),
		maxf(bomb_travel_speed, 1.0),
		maxf(explosion_duration_seconds, 0.1),
		true,
		launch_direction,
		_get_damage_config()
	):
		return false

	if owner_ship.has_method("pulse_artifact_activation"):
		owner_ship.call("pulse_artifact_activation")

	if owner_ship.has_method("broadcast_artifact_effect"):
		owner_ship.call("broadcast_artifact_effect", &"nuke_launched", {
			"owner_peer_id": int(owner_ship.get("owner_peer_id")),
			"launch_origin": launch_origin,
			"launch_direction": launch_direction,
			"target_position": target_position,
			"blast_radius": maxf(blast_radius, 1.0),
			"damage": maxi(damage, 1),
			"bomb_travel_speed": maxf(bomb_travel_speed, 1.0),
			"explosion_duration_seconds": maxf(explosion_duration_seconds, 0.1),
			"damage_config": _get_damage_config(),
		})
	return true


func play_network(payload: Dictionary) -> void:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return

	_spawn_nuke_bomb(
		payload.get("launch_origin", owner_ship.global_position) as Vector2,
		payload.get("target_position", owner_ship.global_position) as Vector2,
		maxf(float(payload.get("blast_radius", blast_radius)), 1.0),
		maxi(int(payload.get("damage", damage)), 1),
		maxf(float(payload.get("bomb_travel_speed", bomb_travel_speed)), 1.0),
		maxf(float(payload.get("explosion_duration_seconds", explosion_duration_seconds)), 0.1),
		false,
		payload.get("launch_direction", Vector2.ZERO) as Vector2,
		payload.get("damage_config", _get_damage_config()) as Dictionary
	)


func get_tunables() -> Dictionary:
	var tunables := super.get_tunables()
	tunables["blast_radius"] = blast_radius
	tunables["damage"] = damage
	tunables["bomb_travel_speed"] = bomb_travel_speed
	tunables["explosion_duration_seconds"] = explosion_duration_seconds
	tunables["blast_growth_duration_ratio"] = blast_growth_duration_ratio
	tunables["blast_damage_edge_ratio"] = blast_damage_edge_ratio
	tunables["blast_min_damage_ratio"] = blast_min_damage_ratio
	tunables["radiation_damage_per_second"] = radiation_damage_per_second
	tunables["radiation_tick_interval_seconds"] = radiation_tick_interval_seconds
	tunables["radiation_damage_edge_ratio"] = radiation_damage_edge_ratio
	tunables["radiation_min_damage_ratio"] = radiation_min_damage_ratio
	return tunables


func apply_tunables(tunables: Dictionary) -> void:
	super.apply_tunables(tunables)
	if tunables.has("blast_radius"):
		blast_radius = maxf(float(tunables.get("blast_radius", blast_radius)), 1.0)
	if tunables.has("damage"):
		damage = maxi(int(tunables.get("damage", damage)), 1)
	if tunables.has("bomb_travel_speed"):
		bomb_travel_speed = maxf(float(tunables.get("bomb_travel_speed", bomb_travel_speed)), 1.0)
	if tunables.has("explosion_duration_seconds"):
		explosion_duration_seconds = maxf(float(tunables.get("explosion_duration_seconds", explosion_duration_seconds)), 0.1)
	if tunables.has("blast_growth_duration_ratio"):
		blast_growth_duration_ratio = clampf(float(tunables.get("blast_growth_duration_ratio", blast_growth_duration_ratio)), 0.0, 1.0)
	if tunables.has("blast_damage_edge_ratio"):
		blast_damage_edge_ratio = clampf(float(tunables.get("blast_damage_edge_ratio", blast_damage_edge_ratio)), 0.0, 1.0)
	if tunables.has("blast_min_damage_ratio"):
		blast_min_damage_ratio = clampf(float(tunables.get("blast_min_damage_ratio", blast_min_damage_ratio)), 0.0, 1.0)
	if tunables.has("radiation_damage_per_second"):
		radiation_damage_per_second = maxf(float(tunables.get("radiation_damage_per_second", radiation_damage_per_second)), 0.0)
	if tunables.has("radiation_tick_interval_seconds"):
		radiation_tick_interval_seconds = maxf(float(tunables.get("radiation_tick_interval_seconds", radiation_tick_interval_seconds)), 0.05)
	if tunables.has("radiation_damage_edge_ratio"):
		radiation_damage_edge_ratio = clampf(float(tunables.get("radiation_damage_edge_ratio", radiation_damage_edge_ratio)), 0.0, 1.0)
	if tunables.has("radiation_min_damage_ratio"):
		radiation_min_damage_ratio = clampf(float(tunables.get("radiation_min_damage_ratio", radiation_min_damage_ratio)), 0.0, 1.0)


func get_preview_radius() -> float:
	return maxf(blast_radius, 1.0)


func create_placement_preview() -> Node2D:
	var placement_preview := VORTEX_PLACEMENT_PREVIEW_SCRIPT.new() as Node2D
	if placement_preview.has_method("configure"):
		placement_preview.call("configure", get_preview_radius())
	return placement_preview


func _spawn_nuke_bomb(
	launch_origin: Vector2,
	target_position: Vector2,
	effect_blast_radius: float,
	effect_damage: int,
	effect_travel_speed: float,
	effect_explosion_duration: float,
	should_deal_damage: bool,
	launch_direction: Vector2,
	damage_config: Dictionary = {}
) -> bool:
	var fx_layer: Node2D = null
	if owner_ship.has_method("get_artifact_effects_layer"):
		fx_layer = owner_ship.call("get_artifact_effects_layer") as Node2D
	if fx_layer == null:
		return false

	var bomb := NUKE_BOMB_SCENE.instantiate() as Node2D
	if bomb == null:
		return false

	fx_layer.add_child(bomb)
	if bomb.has_method("set_damage_config"):
		bomb.call("set_damage_config", damage_config)
	if bomb.has_method("configure"):
		bomb.call(
			"configure",
			launch_origin,
			target_position,
			effect_blast_radius,
			effect_damage,
			effect_travel_speed,
			effect_explosion_duration,
			should_deal_damage,
			int(owner_ship.get("owner_peer_id")),
			launch_direction
		)
	if bomb.has_method("set_fog_presentation_alpha"):
		var fog_alpha := 1.0
		if owner_ship.has_method("should_show_artifact_effect"):
			fog_alpha = 1.0 if bool(owner_ship.call("should_show_artifact_effect", launch_origin)) else 0.0
		bomb.call("set_fog_presentation_alpha", fog_alpha)
	return true


func _get_damage_config() -> Dictionary:
	return {
		"blast_growth_duration_ratio": clampf(blast_growth_duration_ratio, 0.0, 1.0),
		"blast_damage_edge_ratio": clampf(blast_damage_edge_ratio, 0.0, 1.0),
		"blast_min_damage_ratio": clampf(blast_min_damage_ratio, 0.0, 1.0),
		"radiation_damage_per_second": maxf(radiation_damage_per_second, 0.0),
		"radiation_tick_interval_seconds": maxf(radiation_tick_interval_seconds, 0.05),
		"radiation_damage_edge_ratio": clampf(radiation_damage_edge_ratio, 0.0, 1.0),
		"radiation_min_damage_ratio": clampf(radiation_min_damage_ratio, 0.0, 1.0),
	}


func _get_launch_direction(target_position: Vector2) -> Vector2:
	var launch_direction := Vector2.ZERO
	if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.has_method("get_artifact_forward_direction"):
		launch_direction = owner_ship.call("get_artifact_forward_direction") as Vector2
	if launch_direction == Vector2.ZERO and owner_ship != null and is_instance_valid(owner_ship):
		launch_direction = (target_position - owner_ship.global_position).normalized()
	if launch_direction == Vector2.ZERO:
		return Vector2.UP

	return launch_direction.normalized()


func _get_launch_origin(launch_direction: Vector2) -> Vector2:
	if owner_ship != null and is_instance_valid(owner_ship) and owner_ship.has_method("get_artifact_launch_origin"):
		return owner_ship.call("get_artifact_launch_origin") as Vector2
	if owner_ship != null and is_instance_valid(owner_ship):
		return owner_ship.global_position + launch_direction.normalized() * 48.0

	return Vector2.ZERO
