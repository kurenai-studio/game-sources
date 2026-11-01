extends Camera2D

var trauma: float = 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0
	rng.randomize()

func shake(amount: float = 0.25) -> void:
	trauma = minf(1.0, trauma + amount)

func _process(delta: float) -> void:
	trauma = maxf(0.0, trauma - delta * 1.8)
	var strength := trauma * trauma
	offset = Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0)) * 14.0 * strength
	rotation = rng.randf_range(-0.012, 0.012) * strength

