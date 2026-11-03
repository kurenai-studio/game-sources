extends TextureButton

@onready var isFollowing = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if isFollowing:
		self.position = get_viewport().get_mouse_position() - Vector2(300, 150)

func _on_button_down() -> void:
	isFollowing = false if isFollowing else true
