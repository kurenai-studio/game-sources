extends Sprite2D

var randomStrength = 50.0
var shakeFade = 5.0

var rng = RandomNumberGenerator.new()

var shakeStrength = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if shakeStrength > 0:
		shakeStrength = lerpf(shakeStrength, 0, shakeFade * delta)
		offset = randomOffset()

func apply_shake() -> void:
	shakeStrength = randomStrength

func randomOffset() -> Vector2:
	return Vector2(rng.randf_range(-shakeStrength, shakeStrength), rng.randf_range(-shakeStrength, shakeStrength))
