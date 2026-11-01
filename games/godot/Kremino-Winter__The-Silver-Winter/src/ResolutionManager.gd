extends Node

# Variables for resolution and zoom
var current_resolution: Vector2i = Vector2i(640, 360)
var current_zoom: Vector2 = Vector2(1, 1)

# Apply window resolution
func apply_window_settings():
	if current_resolution:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(current_resolution)

# Apply zoom to Camera2D
func apply_camera(camera: Camera2D) -> void:
	if camera:
		camera.zoom = current_zoom
