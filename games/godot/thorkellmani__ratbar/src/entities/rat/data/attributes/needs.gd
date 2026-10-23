## Holds the rat's current need satisfaction, from -100 to 100.
## Keeps values within bounds and announces changes after storing them.
class_name Needs extends NeedValues

signal stat_changed

const MIN_NEED_VALUE: float = -100.0
const MAX_NEED_VALUE: float = 100.0


func _prepare_need_value(value: float) -> float:
	return clampf(value, MIN_NEED_VALUE, MAX_NEED_VALUE)


func _on_need_value_changed() -> void:
	stat_changed.emit()


func _get_min() -> float:
	return MIN_NEED_VALUE


func _get_max() -> float:
	return MAX_NEED_VALUE
