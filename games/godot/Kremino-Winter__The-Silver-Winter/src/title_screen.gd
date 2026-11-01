extends Node

func _on_new_game() -> void:
		$new_game_sound.play()
		get_tree().change_scene_to_file("res://main.tscn")

@onready var resolution_list := $control/ResolutionList
@onready var apply_button := $control/ApplyButton
@onready var close_button := $control/CloseButton
@onready var camera := $Camera2D 

var resolutions := [
	Vector2i(640, 360),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

var zoom_factors = {
	Vector2i(640, 360): Vector2(1, 1),
	Vector2i(1280, 720): Vector2(2, 2),
	Vector2i(1920, 1080): Vector2(3, 3),
	Vector2i(2560, 1440): Vector2(4, 4),
	Vector2i(3840, 2160): Vector2(6, 6)
}

func _ready():
	if not has_node("control/ResolutionList") or not has_node("control/ApplyButton") or not has_node("control/CloseButton"):
		return

	resolution_list.clear()

	for res in resolutions:
		resolution_list.add_item("%dx%d" % [res.x, res.y])
	
	if resolution_list.get_item_count() > 0:
		resolution_list.select(0)

	if not apply_button.is_connected("pressed", Callable(self, "_on_apply_pressed")):
		apply_button.pressed.connect(_on_apply_pressed)

	if not close_button.is_connected("pressed", Callable(self, "_on_close_pressed")):
		close_button.pressed.connect(_on_close_pressed)


func _on_apply_pressed():
	$apply_sound.play()
	var selected = resolution_list.get_selected()
	
	if DisplayServer.WINDOW_MODE_FULLSCREEN:
		var chosen_res = resolutions[selected]
		
		if camera:
			camera.zoom = zoom_factors.get(chosen_res, Vector2(1, 1))
	
	
	elif selected >= 0 and selected < resolutions.size():
		var chosen_res = resolutions[selected]
		
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(chosen_res)
		DisplayServer.window_set_position(DisplayServer.window_get_position())

		if camera:
			camera.zoom = zoom_factors.get(chosen_res, Vector2(1, 1))


func _on_close_pressed():
	$control.visible = false
