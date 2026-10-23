class_name VortexArtifact
extends ShipArtifact

const VORTEX_SCENE: PackedScene = preload("res://scenes/artifacts/vortex.tscn")
const VORTEX_PLACEMENT_PREVIEW_SCRIPT: Script = preload("res://scripts/artifacts/vortex_placement_preview.gd")
const GAME_SFX: Script = preload("res://scripts/game_sfx.gd")

@export_range(64.0, 5000.0, 10.0) var radius: float = 900.0
@export_range(0.1, 60.0, 0.1) var duration_seconds: float = 30.0
@export_range(0.0, 20000.0, 10.0) var pull_speed: float = 3600.0


func _init() -> void:
	item_kind = &"vortex"
	cooldown_seconds = 60.0


func get_upgrade_preview() -> Dictionary:
	var effect_radius := maxf(radius, 0.0)
	var effect_duration := maxf(duration_seconds, 0.0)
	var safe_cooldown_seconds := get_cooldown_duration()
	return {
		"title": "Vortex",
		"summary": "Artifact vortex: %s px\nDuration: %s\nCooldown: %s" % [
			_format_number(effect_radius, 0),
			_format_duration(effect_duration),
			_format_duration(safe_cooldown_seconds),
		],
		"tooltip": "Unlocks an Artifact Hud button.\nActivating it arms placement; click the galaxy to place a vortex that captures ships and enemies in a %s px radius for %s.\nCooldown: %s" % [
			_format_number(effect_radius, 0),
			_format_duration(effect_duration),
			_format_duration(safe_cooldown_seconds),
		],
	}


func activate_at(world_position: Vector2) -> bool:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return false

	var effect_radius := maxf(radius, 1.0)
	var effect_duration := maxf(duration_seconds, 0.1)
	var effect_pull_speed := maxf(pull_speed, 0.0)
	var target_position := world_position
	if owner_ship.has_method("clamp_artifact_world_position"):
		target_position = owner_ship.call("clamp_artifact_world_position", world_position) as Vector2

	if _is_blocked_by_planet(target_position, effect_radius):
		return false

	if _spawn_vortex_effect(target_position, effect_radius, effect_duration, effect_pull_speed, true) == null:
		return false

	if owner_ship.has_method("broadcast_artifact_effect"):
		owner_ship.call("broadcast_artifact_effect", &"vortex_spawned", {
			"owner_peer_id": int(owner_ship.get("owner_peer_id")),
			"position": target_position,
			"radius": effect_radius,
			"duration_seconds": effect_duration,
			"pull_speed": effect_pull_speed,
		})
	return true


func play_network(payload: Dictionary) -> void:
	if owner_ship == null or not is_instance_valid(owner_ship):
		return

	_spawn_vortex_effect(
		payload.get("position", owner_ship.global_position) as Vector2,
		maxf(float(payload.get("radius", radius)), 1.0),
		maxf(float(payload.get("duration_seconds", duration_seconds)), 0.1),
		maxf(float(payload.get("pull_speed", pull_speed)), 0.0),
		false
	)


func get_tunables() -> Dictionary:
	var tunables := super.get_tunables()
	tunables["radius"] = radius
	tunables["duration_seconds"] = duration_seconds
	tunables["pull_speed"] = pull_speed
	return tunables


func apply_tunables(tunables: Dictionary) -> void:
	super.apply_tunables(tunables)
	if tunables.has("radius"):
		radius = maxf(float(tunables.get("radius", radius)), 1.0)
	if tunables.has("duration_seconds"):
		duration_seconds = maxf(float(tunables.get("duration_seconds", duration_seconds)), 0.1)
	if tunables.has("pull_speed"):
		pull_speed = maxf(float(tunables.get("pull_speed", pull_speed)), 0.0)


func get_preview_radius() -> float:
	return maxf(radius, 1.0)


func create_placement_preview() -> Node2D:
	var placement_preview := VORTEX_PLACEMENT_PREVIEW_SCRIPT.new() as Node2D
	if placement_preview.has_method("configure"):
		placement_preview.call("configure", get_preview_radius())
	return placement_preview


func _is_blocked_by_planet(world_position: Vector2, effect_radius: float) -> bool:
	var tree := owner_ship.get_tree()
	if tree == null:
		return false

	var scene_root := tree.current_scene
	if scene_root == null or not scene_root.has_method("is_vortex_placement_blocked_by_planet"):
		return false

	return bool(scene_root.call("is_vortex_placement_blocked_by_planet", world_position, effect_radius))


func _spawn_vortex_effect(
	world_position: Vector2,
	effect_radius: float,
	effect_duration: float,
	effect_pull_speed: float,
	should_affect_bodies: bool
) -> Node2D:
	var fx_layer: Node2D = null
	if owner_ship.has_method("get_artifact_effects_layer"):
		fx_layer = owner_ship.call("get_artifact_effects_layer") as Node2D
	if fx_layer == null:
		return null

	var vortex := VORTEX_SCENE.instantiate() as Node2D
	if vortex == null:
		return null

	fx_layer.add_child(vortex)
	vortex.global_position = world_position
	if vortex.has_method("configure"):
		vortex.call("configure", effect_radius, effect_duration, effect_pull_speed, should_affect_bodies)
	if vortex.has_method("set_fog_presentation_alpha"):
		var fog_alpha := 1.0
		if owner_ship.has_method("should_show_artifact_effect"):
			fog_alpha = 1.0 if bool(owner_ship.call("should_show_artifact_effect", world_position)) else 0.0
		vortex.call("set_fog_presentation_alpha", fog_alpha)
	GAME_SFX.play(owner_ship, GAME_SFX.CUE_VORTEX, -1.0, randf_range(0.97, 1.03))
	return vortex
