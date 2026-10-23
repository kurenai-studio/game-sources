class_name ColonyBeaconTorpedo
extends NukeBomb

const COLONY_BEACON_BREACH_FX_SCRIPT: Script = preload("res://scripts/colony_beacon_breach_fx.gd")

signal landed(world_position: Vector2)

@export_group("Impact")
@export_range(0.0, 1.0, 0.01) var impact_camera_shake_intensity: float = 0.62

var _crash_target_position: Vector2 = Vector2.ZERO
var _crash_surface_normal: Vector2 = Vector2.UP
var _crash_planet: Planet


func configure(
	launch_origin: Vector2,
	target_position: Vector2,
	effect_blast_radius: float,
	effect_damage: int,
	effect_travel_speed: float,
	effect_explosion_duration: float,
	should_deal_damage: bool,
	effect_owner_peer_id: int,
	launch_direction_value: Vector2 = Vector2.ZERO,
	crash_planet: Planet = null
) -> void:
	super.configure(
		launch_origin,
		target_position,
		effect_blast_radius,
		effect_damage,
		effect_travel_speed,
		effect_explosion_duration,
		should_deal_damage,
		effect_owner_peer_id,
		launch_direction_value
	)
	_crash_planet = crash_planet
	_reset_crash_state(launch_origin, target_position)


func _detonate(explosion_position: Vector2) -> void:
	if _detonated:
		return

	_detonated = true
	_set_jet_emitting(false)
	var crash_position := _crash_target_position if _crash_target_position.is_finite() else explosion_position
	_request_impact_camera_shake(crash_position)
	GAME_SFX.play(self, GAME_SFX.CUE_BEACON_COLONY, -1.5, randf_range(0.96, 1.04))
	_spawn_breach_fx(crash_position)
	landed.emit(crash_position)
	queue_free()


func _reset_crash_state(launch_origin: Vector2, target_position: Vector2) -> void:
	_crash_target_position = target_position
	_crash_surface_normal = (launch_origin - target_position).normalized()
	if _crash_surface_normal == Vector2.ZERO:
		_crash_surface_normal = Vector2.UP


func _spawn_breach_fx(world_position: Vector2) -> void:
	var parent_node := get_parent()
	if parent_node == null:
		return

	var breach_fx := COLONY_BEACON_BREACH_FX_SCRIPT.new() as Node2D
	if breach_fx == null:
		return

	breach_fx.name = "ColonyBeaconBreach"
	breach_fx.z_index = z_index - 2
	parent_node.add_child(breach_fx)
	if breach_fx.has_method("configure"):
		breach_fx.call("configure", world_position, _crash_surface_normal, rotation, _crash_planet)


func _request_impact_camera_shake(world_position: Vector2) -> void:
	var scene_root := get_tree().current_scene
	if scene_root != null and scene_root.has_method("request_camera_shake"):
		scene_root.call("request_camera_shake", impact_camera_shake_intensity, world_position)
