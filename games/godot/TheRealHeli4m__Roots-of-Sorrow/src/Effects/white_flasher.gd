extends ColorRect

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.color.a = 1
	var tween = get_tree().create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.75)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
		
	
