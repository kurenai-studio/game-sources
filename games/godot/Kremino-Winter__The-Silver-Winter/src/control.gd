extends Node  # Resolution settings

@onready var resolution_list := $control/ResolutionList
@onready var apply_button := $control/ApplyButton
@onready var close_button := $control/CloseButton

# Resolutions
var resolutions := [
	Vector2i(640, 360),
	Vector2i(1280, 720),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440),
	Vector2i(3840, 2160)
]

func _ready():
	# Check nodes
	if not has_node("control/ResolutionList") or not has_node("control/ApplyButton") or not has_node("control/CloseButton"):
		return

	# Resolution dropdown
	resolution_list.clear()
	for res in resolutions:
		resolution_list.add_item("%dx%d" % [res.x, res.y])
	
	# Default resolution
	if resolution_list.get_item_count() > 0:
		resolution_list.select(0)

	# Connect buttons
	if not apply_button.is_connected("pressed", Callable(self, "_on_apply_pressed")):
		apply_button.pressed.connect(_on_apply_pressed)

	if not close_button.is_connected("pressed", Callable(self, "_on_close_pressed")):
		close_button.pressed.connect(_on_close_pressed)


func _on_apply_pressed():
	var selected: int = resolution_list.get_selected()
	if selected < 0 or selected >= resolutions.size():
		return

	var chosen_res: Vector2i = resolutions[selected]

	# Apply window size
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	DisplayServer.window_set_size(chosen_res)

	print("Window size set to:", DisplayServer.window_get_size())


func _on_close_pressed():
	$control.visible = false
