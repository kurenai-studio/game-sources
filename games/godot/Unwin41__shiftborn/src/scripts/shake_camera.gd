class_name ShakeCamera
extends Camera2D
## Trauma-based screen shake. [method add_trauma] adds 0..1 trauma; the
## shake strength is trauma squared, so small hits barely move the view
## and big ones kick hard. Trauma fades at [constant DECAY] per second.

const DECAY := 1.8
## Largest offset in pixels at full trauma.
const MAX_OFFSET := 5.0
## How fast the noise is sampled; higher feels more jittery.
const NOISE_SPEED := 60.0

var trauma: float = 0.0

var _noise := FastNoiseLite.new()
var _time: float = 0.0


static func shake_strength(amount: float) -> float:
	return amount * amount


func _init() -> void:
	_noise.seed = randi()
	_noise.frequency = 0.5


func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)


func _process(delta: float) -> void:
	step(delta)


## Advances the shake by [param delta] seconds and updates [member offset].
func step(delta: float) -> void:
	trauma = maxf(trauma - DECAY * delta, 0.0)
	if trauma == 0.0:
		offset = Vector2.ZERO
		return
	_time += delta * NOISE_SPEED
	var strength := shake_strength(trauma) * MAX_OFFSET
	offset = Vector2(_noise.get_noise_2d(_time, 0.0), _noise.get_noise_2d(0.0, _time)).clampf(-1.0, 1.0) * strength
