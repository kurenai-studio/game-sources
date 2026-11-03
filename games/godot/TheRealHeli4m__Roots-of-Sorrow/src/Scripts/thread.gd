extends TextureButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.modulate.a = 0.5


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_mouse_entered() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.25)

func _on_mouse_exited() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.5, 0.25)

func _on_pressed() -> void:
	pass # Replace with function body.
