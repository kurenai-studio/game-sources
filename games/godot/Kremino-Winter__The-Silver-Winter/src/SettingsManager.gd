# SettingsManager.gd
extends Node

const SAVE_PATH = "user://resolution.cfg"
var config = ConfigFile.new()
var current_res: Vector2i = Vector2i(1280, 720)

var zoom_factors = {
	Vector2i(640, 360): Vector2(1, 1),
	Vector2i(1280, 720): Vector2(2, 2),
	Vector2i(1920, 1080): Vector2(3, 3),
	Vector2i(2560, 1440): Vector2(4, 4),
	Vector2i(3840, 2160): Vector2(6, 6)
}

func _ready():
	load_settings()

func load_settings():
	if config.load(SAVE_PATH) == OK:
		current_res = config.get_value("video", "resolution", Vector2i(1280, 720))
	apply_settings()

func save_settings(new_res: Vector2i):
	current_res = new_res
	config.set_value("video", "resolution", new_res)
	config.save(SAVE_PATH)
	apply_settings()

func apply_settings():
	DisplayServer.window_set_size(current_res)
	var center = DisplayServer.screen_get_position() + (DisplayServer.screen_get_size() / 2)
	DisplayServer.window_set_position(center - (current_res / 2))

# Ensure this function is present and correctly named
func get_zoom() -> Vector2:
	return zoom_factors.get(current_res, Vector2(1, 1))
