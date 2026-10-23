## Holds changes per game-hour to needs while a rat performs this job.
## Keeps configured rates within -20..20 and announces changes after storage.
class_name JobModifiers extends NeedValues

signal stat_changed

const MIN_JOB_RATE_PER_GAME_HOUR: float = -20.0
const MAX_JOB_RATE_PER_GAME_HOUR: float = 20.0


func _prepare_need_value(value: float) -> float:
	return clampf(
		value,
		MIN_JOB_RATE_PER_GAME_HOUR,
		MAX_JOB_RATE_PER_GAME_HOUR
	)


func _on_need_value_changed() -> void:
	stat_changed.emit()


func _get_min() -> float:
	return MIN_JOB_RATE_PER_GAME_HOUR


func _get_max() -> float:
	return MAX_JOB_RATE_PER_GAME_HOUR
