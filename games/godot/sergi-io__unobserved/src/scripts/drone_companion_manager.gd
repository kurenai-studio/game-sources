extends Node
class_name DroneCompanionManager

const DRONE_COMPANION_SCENE: PackedScene = preload("res://scenes/drone_companion.tscn")

var _ship: Node2D
var _drone_companions: Array[Node2D] = []
var _owner_peer_id: int = 0
var _is_network_presentation: bool = false
var _is_server_authority: bool = false
var _attack_range: float = 1600.0
var _damage_per_shot: int = 1
var _is_fog_presentation_visible: bool = true
var _owner_invisibility_alpha: float = 1.0


func set_owner_ship(ship: Node2D) -> void:
	_ship = ship


func _exit_tree() -> void:
	clear()


func sync_companions(
	drone_count: int,
	attack_range: float,
	damage_per_shot: int,
	owner_peer_id: int,
	is_network_presentation: bool,
	is_server_authority: bool,
	is_fog_presentation_visible: bool,
	owner_invisibility_alpha: float
) -> void:
	_owner_peer_id = owner_peer_id
	_is_network_presentation = is_network_presentation
	_is_server_authority = is_server_authority
	_attack_range = maxf(attack_range, 1.0)
	_damage_per_shot = maxi(damage_per_shot, 1)
	_is_fog_presentation_visible = is_fog_presentation_visible
	_owner_invisibility_alpha = clampf(owner_invisibility_alpha, 0.0, 1.0)

	var safe_drone_count := maxi(drone_count, 0)
	if _ship == null or not is_instance_valid(_ship) or safe_drone_count <= 0:
		clear()
		return

	var owner_parent := _ship.get_parent()
	if owner_parent == null:
		return

	_prune_invalid_companions()
	while _drone_companions.size() > safe_drone_count:
		var extra_drone := _drone_companions.pop_back() as Node2D
		if extra_drone != null and is_instance_valid(extra_drone):
			extra_drone.queue_free()

	for index in range(_drone_companions.size()):
		var existing_drone := _drone_companions[index]
		if existing_drone == null or not is_instance_valid(existing_drone):
			continue

		_configure_companion(existing_drone, index, safe_drone_count, false)

	for index in range(_drone_companions.size(), safe_drone_count):
		var drone := DRONE_COMPANION_SCENE.instantiate() as Node2D
		if drone == null:
			continue

		owner_parent.add_child(drone)
		_drone_companions.append(drone)
		_configure_companion(drone, index, safe_drone_count, true)
		_apply_companion_presentation(drone)

	apply_presentation(is_fog_presentation_visible, owner_invisibility_alpha)


func apply_presentation(is_fog_visible: bool, owner_invisibility_alpha: float) -> void:
	_is_fog_presentation_visible = is_fog_visible
	_owner_invisibility_alpha = clampf(owner_invisibility_alpha, 0.0, 1.0)
	for drone in _drone_companions:
		if drone == null or not is_instance_valid(drone):
			continue
		_apply_companion_presentation(drone)


func play_network_beam(drone_index: int, target_world_position: Vector2) -> void:
	if drone_index < 0 or drone_index >= _drone_companions.size():
		return

	var drone := _drone_companions[drone_index]
	if drone != null and is_instance_valid(drone) and drone.has_method("play_network_beam"):
		drone.call("play_network_beam", target_world_position)


func clear() -> void:
	for drone in _drone_companions:
		if drone != null and is_instance_valid(drone):
			drone.queue_free()

	_drone_companions.clear()


func _configure_companion(drone: Node2D, drone_index: int, drone_count: int, should_snap: bool) -> void:
	if _ship == null or not is_instance_valid(_ship):
		return

	drone.name = "DroneCompanion%d_%d" % [_owner_peer_id, drone_index + 1]
	drone.set("attack_range", _attack_range)
	drone.set("damage_per_shot", _damage_per_shot)
	drone.set("ship_path", drone.get_path_to(_ship))
	if _is_network_presentation and drone.has_method("set_network_identity"):
		drone.call("set_network_identity", _owner_peer_id, drone_index, _is_server_authority)
	if drone.has_method("set_formation_slot"):
		drone.call("set_formation_slot", drone_index, drone_count)
	if not should_snap:
		return

	if drone.has_method("snap_to_formation"):
		drone.call("snap_to_formation")
	else:
		drone.global_position = _ship.global_position
		drone.rotation = _ship.rotation


func _apply_companion_presentation(drone: Node) -> void:
	if drone == null or not is_instance_valid(drone):
		return

	if drone.has_method("set_owner_invisibility_alpha"):
		drone.call("set_owner_invisibility_alpha", _owner_invisibility_alpha)
	elif drone is CanvasItem:
		var canvas_item := drone as CanvasItem
		var entity_modulate := canvas_item.modulate
		entity_modulate.a = _owner_invisibility_alpha
		canvas_item.modulate = entity_modulate

	if drone.has_method("set_fog_presentation_visible"):
		drone.call("set_fog_presentation_visible", _is_fog_presentation_visible)
	elif drone is CanvasItem:
		(drone as CanvasItem).visible = _is_fog_presentation_visible


func _prune_invalid_companions() -> void:
	var index := _drone_companions.size() - 1
	while index >= 0:
		var drone := _drone_companions[index]
		if drone == null or not is_instance_valid(drone):
			_drone_companions.remove_at(index)
		index -= 1
