class_name ShipArtifact
extends Node

@export var item_kind: StringName = &""
@export_range(0.0, 120.0, 0.1) var cooldown_seconds: float = 0.0

const MAX_STACK_COUNT: int = 4

var owner_ship: Node2D
var _level: int = 0
var _unit_cooldown_time_left: Array[float] = []


func configure(ship: Node2D) -> void:
	owner_ship = ship


func unlock(item_level: int = 1) -> bool:
	var previous_level := _level
	set_level(mini(_level + maxi(item_level, 1), MAX_STACK_COUNT))
	return _level != previous_level


func set_level(item_level: int) -> void:
	_level = clampi(item_level, 0, MAX_STACK_COUNT)
	_resize_unit_cooldowns()


func get_level() -> int:
	return _level


func is_owned() -> bool:
	return _level > 0


func can_activate() -> bool:
	return is_owned() and _get_ready_unit_index() >= 0


func start_cooldown() -> bool:
	if not is_owned():
		return false

	var unit_index := _get_ready_unit_index()
	if unit_index < 0:
		return false

	var duration := get_cooldown_duration()
	if duration <= 0.0:
		_unit_cooldown_time_left[unit_index] = 0.0
		return true

	_unit_cooldown_time_left[unit_index] = duration
	return true


func clear_cooldown() -> void:
	_resize_unit_cooldowns()
	for index in range(_unit_cooldown_time_left.size()):
		_unit_cooldown_time_left[index] = 0.0


func is_on_cooldown() -> bool:
	return is_owned() and _get_ready_unit_index() < 0


func process_cooldown(delta: float) -> void:
	_resize_unit_cooldowns()
	var safe_delta := maxf(delta, 0.0)
	if is_zero_approx(safe_delta):
		return

	for index in range(_unit_cooldown_time_left.size()):
		var time_left := _unit_cooldown_time_left[index]
		if time_left <= 0.0:
			continue

		_unit_cooldown_time_left[index] = maxf(time_left - safe_delta, 0.0)


func get_cooldown_duration() -> float:
	return maxf(cooldown_seconds, 0.0)


func get_cooldown_state() -> Dictionary:
	_resize_unit_cooldowns()
	var duration := get_cooldown_duration()
	var unit_states: Array[Dictionary] = []
	var ready_count := 0
	var next_ready_time := 0.0
	for index in range(_level):
		var time_left := maxf(_unit_cooldown_time_left[index], 0.0)
		if duration <= 0.0:
			time_left = 0.0
		var is_ready := time_left <= 0.01
		if is_ready:
			ready_count += 1
		elif next_ready_time <= 0.0 or time_left < next_ready_time:
			next_ready_time = time_left

		unit_states.append({
			"time_left": time_left,
			"duration": duration,
			"ready": is_ready,
			"fill_ratio": 1.0 if duration <= 0.0 else 1.0 - clampf(time_left / duration, 0.0, 1.0),
		})

	return {
		"time_left": next_ready_time if ready_count <= 0 else 0.0,
		"duration": duration,
		"stack_count": _level,
		"ready_count": ready_count,
		"units": unit_states,
	}


func get_upgrade_preview() -> Dictionary:
	return {
		"title": "Artifact",
		"summary": "Unlocks an Artifact Hud button.",
		"tooltip": "Unlocks an Artifact Hud button.",
	}


func activate() -> bool:
	return false


func activate_at(_world_position: Vector2) -> bool:
	return activate()


func get_tunables() -> Dictionary:
	return {
		"cooldown_seconds": cooldown_seconds,
	}


func apply_tunables(tunables: Dictionary) -> void:
	if tunables.has("cooldown_seconds"):
		cooldown_seconds = maxf(float(tunables.get("cooldown_seconds", cooldown_seconds)), 0.0)


func get_preview_radius() -> float:
	return 0.0


func create_placement_preview() -> Node2D:
	return null


func _resize_unit_cooldowns() -> void:
	while _unit_cooldown_time_left.size() < _level:
		_unit_cooldown_time_left.append(0.0)
	while _unit_cooldown_time_left.size() > _level:
		_unit_cooldown_time_left.pop_back()


func _get_ready_unit_index() -> int:
	_resize_unit_cooldowns()
	for index in range(_unit_cooldown_time_left.size()):
		if _unit_cooldown_time_left[index] <= 0.01:
			return index

	return -1


func _format_number(value: float, decimals: int = 1) -> String:
	if decimals <= 0 or is_equal_approx(value, round(value)):
		return str(int(round(value)))

	var step := pow(10.0, -float(decimals))
	var rounded_value := snappedf(value, step)
	var format_string := "%0." + str(decimals) + "f"
	return format_string % rounded_value


func _format_duration(seconds: float) -> String:
	var safe_seconds := maxi(int(ceil(maxf(seconds, 0.0))), 0)
	var minutes := int(safe_seconds / 60)
	var remaining_seconds := safe_seconds % 60
	if minutes > 0:
		return "%d:%02d" % [minutes, remaining_seconds]

	return "%ds" % remaining_seconds
