extends ProgressBar
class_name EraserCounter


var player_max: int = 3

static var _instance: EraserCounter


func _ready() -> void:
	_instance = self
	
	# TODO: Add the user's powerups here if we get to implementing those
	max_value = player_max
	value = player_max


static func refill() -> void:
	_instance.value = _instance.player_max


static func decrement(value:= 1) -> void:
	_instance.value -= value


static func increment(value:= 1) -> void:
	_instance.value += value


static func can_erase() -> bool:
	return _instance.value > 0
