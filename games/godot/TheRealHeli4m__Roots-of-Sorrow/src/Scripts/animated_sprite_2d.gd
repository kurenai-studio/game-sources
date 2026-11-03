extends AnimatedSprite2D

@onready var player = $".."
@onready var aTree = $"../AnimationTree"
@onready var jBuffTimer = $"../JumpBufferingTimer"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	aTree["parameters/conditions/is_idle"] = false
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	if not player.canMove:
		aTree["parameters/conditions/is_idle"] = true
		aTree["parameters/conditions/is_running"] = false
		aTree["parameters/conditions/is_landing"] = false
		aTree["parameters/conditions/is_jumping"] = false
		return
	
	if player.velocity == Vector2.ZERO:
		aTree["parameters/conditions/is_idle"] = true
		aTree["parameters/conditions/is_running"] = false
		aTree["parameters/conditions/is_landing"] = false
	
	if Input.is_action_pressed("move_left"):
		aTree["parameters/conditions/is_running"] = true
		aTree["parameters/conditions/is_idle"] = false
		aTree["parameters/conditions/is_landing"] = false
		self.flip_h = true
	elif Input.is_action_pressed("move_right"):
		aTree["parameters/conditions/is_running"] = true
		aTree["parameters/conditions/is_idle"] = false
		aTree["parameters/conditions/is_landing"] = false
		self.flip_h = false
		
	if player.is_on_floor() and not player.was_on_floor:
		aTree["parameters/conditions/is_landing"] = true
		aTree["parameters/conditions/is_jumping"] = false
	if player.is_on_floor():
		aTree["parameters/conditions/is_landing"] = true
		aTree["parameters/conditions/is_jumping"] = false
		
	if not player.is_on_floor() and player.was_on_floor:
		aTree["parameters/conditions/is_jumping"] = true
		aTree["parameters/conditions/is_running"] = false
		aTree["parameters/conditions/is_idle"] = false
		aTree["parameters/conditions/is_landing"] = false

	
