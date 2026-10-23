## Holds changes per game-hour to needs while a rat is at this location.
## Keeps configured rates within -20..20 and announces changes after storage.
class_name LocationModifiers extends NeedValues

signal stat_changed

const MIN_LOCATION_RATE_PER_GAME_HOUR: float = -20.0
const MAX_LOCATION_RATE_PER_GAME_HOUR: float = 20.0


func _prepare_need_value(value: float) -> float:
	return clampf(
		value,
		MIN_LOCATION_RATE_PER_GAME_HOUR,
		MAX_LOCATION_RATE_PER_GAME_HOUR
	)


func _on_need_value_changed() -> void:
	stat_changed.emit()


func _get_min() -> float:
	return MIN_LOCATION_RATE_PER_GAME_HOUR


func _get_max() -> float:
	return MAX_LOCATION_RATE_PER_GAME_HOUR
