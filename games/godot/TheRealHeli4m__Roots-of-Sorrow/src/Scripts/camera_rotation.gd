extends Camera3D

@onready var cameraAcc = 0.001
@onready var cameraXVel = 0
@onready var cameraYVel = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta: float) -> void:
	var mousePos = get_viewport().get_mouse_position()
	var centerPos = get_viewport().size / 2
	self.global_rotation.y += cameraXVel
	self.global_rotation.x += cameraYVel
	
	var diff_x = centerPos.x - mousePos.x
	var angle_y = diff_x * 0.0003
	self.global_rotation.y = angle_y - 0.40
	
	var diff_y = centerPos.y - mousePos.y
	var angle_x = diff_y * 0.0003
	self.global_rotation.x = angle_x
