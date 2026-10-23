## Holds how appealing this location is for each need.
## Appeal influences location choice; it does not change the rat's needs.
class_name LocationPull extends NeedValues

signal stat_changed

const MIN_LOCATION_PULL: float = 0.0
const MAX_LOCATION_PULL: float = 7.0


func _prepare_need_value(value: float) -> float:
	return clampf(value, MIN_LOCATION_PULL, MAX_LOCATION_PULL)


func _on_need_value_changed() -> void:
	stat_changed.emit()


## Converts a need's location appeal from 0..7 to 0..1 for scoring.
func get_normalized_value(need: String) -> float:
	assert(need in NeedValues.get_keys(), "Unknown need: " + need)
	return (
		(get(need) - MIN_LOCATION_PULL)
		/ (MAX_LOCATION_PULL - MIN_LOCATION_PULL)
	)


func _get_min() -> float:
	return MIN_LOCATION_PULL


func _get_max() -> float:
	return MAX_LOCATION_PULL
