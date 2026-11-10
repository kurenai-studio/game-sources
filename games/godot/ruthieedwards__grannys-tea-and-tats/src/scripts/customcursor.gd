extends Sprite2D

@export var jitter_amount: float = 6.0 #distance in pixels
@export var jitter_speed: float = 25.0 #times per second

var noise: FastNoiseLite = FastNoiseLite.new()
var noise_time: float = 0.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	noise.seed = randi()

func _process(delta: float) -> void:
	noise_time += delta * jitter_speed
	var offset_x = noise.get_noise_2d(noise_time, 0.0) * jitter_amount
	var offset_y = noise.get_noise_2d(0.0, noise_time) * jitter_amount
	global_position = get_global_mouse_position() + Vector2(offset_x, offset_y)

func _exit_tree() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE