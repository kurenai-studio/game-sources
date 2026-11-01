extends Camera2D

func _ready():
	ResolutionManager.apply_window_settings()
	ResolutionManager.apply_camera($Camera2D)
