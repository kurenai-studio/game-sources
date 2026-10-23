## Holds baseline changes per game-hour for each need.
## Keeps configured rates within -10..10 and announces changes after storage.
class_name NeedDecayRate extends NeedValues

signal stat_changed

const MIN_DECAY_RATE_PER_GAME_HOUR: float = -10.0
const MAX_DECAY_RATE_PER_GAME_HOUR: float = 10.0


func _prepare_need_value(value: float) -> float:
	return clampf(
		value,
		MIN_DECAY_RATE_PER_GAME_HOUR,
		MAX_DECAY_RATE_PER_GAME_HOUR
	)


func _on_need_value_changed() -> void:
	stat_changed.emit()


func _get_min() -> float:
	return MIN_DECAY_RATE_PER_GAME_HOUR


func _get_max() -> float:
	return MAX_DECAY_RATE_PER_GAME_HOUR
