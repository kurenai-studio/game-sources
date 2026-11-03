class_name GameCamera
extends Camera2D
## Smooth-follow camera with trauma-based screen shake (respects the settings toggle).

const MAX_OFFSET := 22.0
const MAX_ROLL := 0.035

var trauma: float = 0.0
var target: Node2D
var _noise := FastNoiseLite.new()
var _t: float = 0.0


func _ready() -> void:
	_noise.seed = 7
	_noise.frequency = 2.0
	position_smoothing_enabled = true
	position_smoothing_speed = 7.0
	ignore_rotation = false


func add_trauma(amount: float) -> void:
	if not bool(Settings.get_value("screen_shake")):
		return
	trauma = clampf(trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	if target and is_instance_valid(target):
		global_position = target.global_position
	_t += delta * 30.0
	trauma = maxf(0.0, trauma - delta * 1.6)
	var s := trauma * trauma
	offset = Vector2(_noise.get_noise_2d(_t, 0.0), _noise.get_noise_2d(0.0, _t)) * MAX_OFFSET * s
	rotation = _noise.get_noise_2d(_t, _t) * MAX_ROLL * s
