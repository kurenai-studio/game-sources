## Holds the rat's personality traits, each ranging from -100 to 100.
## Keeps traits within bounds and announces changes after storage.
class_name Personality extends Resource

signal stat_changed

const MIN_TRAIT_VALUE: float = -100.0
const MAX_TRAIT_VALUE: float = 100.0


@export var greed: float:
	set(value):
		greed = _clamp_trait_value(value)
		stat_changed.emit()


@export var temper: float:
	set(value):
		temper = _clamp_trait_value(value)
		stat_changed.emit()


@export var socialness: float:
	set(value):
		socialness = _clamp_trait_value(value)
		stat_changed.emit()


@export var ambition: float:
	set(value):
		ambition = _clamp_trait_value(value)
		stat_changed.emit()


@export var laziness: float:
	set(value):
		laziness = _clamp_trait_value(value)
		stat_changed.emit()


static func get_keys() -> Array[String]:
	return [
		"greed",
		"temper",
		"socialness",
		"ambition",
		"laziness",
	]


func _clamp_trait_value(value: float) -> float:
	return clampf(value, MIN_TRAIT_VALUE, MAX_TRAIT_VALUE)


func _get_min() -> float:
	return MIN_TRAIT_VALUE


func _get_max() -> float:
	return MAX_TRAIT_VALUE
