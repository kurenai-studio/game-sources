## Holds the rat's current statuses, each ranging from 0 to 100.
## Keeps values within bounds and announces changes after storage.
class_name Status extends Resource

signal stat_changed

const MIN_STATUS_VALUE: float = 0.0
const MAX_STATUS_VALUE: float = 100.0


@export var stress: float:
	set(value):
		stress = _clamp_status_value(value)
		stat_changed.emit()


@export var health: float:
	set(value):
		health = _clamp_status_value(value)
		stat_changed.emit()


@export var inebriation: float:
	set(value):
		inebriation = _clamp_status_value(value)
		stat_changed.emit()


@export var radicalization: float:
	set(value):
		radicalization = _clamp_status_value(value)
		stat_changed.emit()


@export var extra_stress: float:
	set(value):
		extra_stress = _clamp_status_value(value)
		stat_changed.emit()


static func get_keys() -> Array[String]:
	return [
		"stress",
		"health",
		"inebriation",
		"radicalization",
		"extra_stress",
	]


func _clamp_status_value(value: float) -> float:
	return clampf(value, MIN_STATUS_VALUE, MAX_STATUS_VALUE)


func _get_min() -> float:
	return MIN_STATUS_VALUE


func _get_max() -> float:
	return MAX_STATUS_VALUE
