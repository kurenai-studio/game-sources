## Holds a number for each need.
## Subclasses decide whether changes need constraints or notifications.
class_name NeedValues extends Resource


@export var nutrition: float:
	set(value):
		nutrition = _prepare_need_value(value)
		_on_need_value_changed()


@export var energy: float:
	set(value):
		energy = _prepare_need_value(value)
		_on_need_value_changed()


@export var stimulation: float:
	set(value):
		stimulation = _prepare_need_value(value)
		_on_need_value_changed()


@export var social: float:
	set(value):
		social = _prepare_need_value(value)
		_on_need_value_changed()


@export var vice_satisfaction: float:
	set(value):
		vice_satisfaction = _prepare_need_value(value)
		_on_need_value_changed()


static func get_keys() -> Array[String]:
	return [
		"nutrition",
		"energy",
		"stimulation",
		"social",
		"vice_satisfaction",
	]


## Accepts the number unchanged. Subclasses can constrain it before storage.
func _prepare_need_value(value: float) -> float:
	return value


## Runs after storage. Subclasses can notify observers here.
func _on_need_value_changed() -> void:
	pass
