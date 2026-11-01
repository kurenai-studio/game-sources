extends Node

@onready var resolution_list := $ResolutionList
@onready var apply_button := $ApplyButton

var resolutions := [
	Vector2i(640, 360),
	Vector2i(800, 600),
	Vector2i(1280, 720),
	Vector2i(1920, 1080)
]

# Runs at the start of the game
func _ready():
	print("Hi!")
	print("Listing children of this node:")
	for child in get_children():
		print("- ", child.name, " (", child, ")")
		
	# OptionButton resolutions
	for res in resolutions:
		resolution_list.add_item("%dx%d" % [res.x, res.y])

	# Connect button press
	apply_button.pressed.connect(_on_apply_pressed)

# Runs when input is detected
func _input(event):
	if event.is_action_pressed("Fullscreen"):
		$Camera2D.zoom = Vector2(3, 3)

# Main game loop
func _process(_delta):
	pass

# Apply resolution when button pressed
func _on_apply_pressed():
	var selected = resolution_list.get_selected()
	if selected >= 0 and selected < resolutions.size():
		var chosen_res = resolutions[selected]
		DisplayServer.window_set_size(chosen_res)
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		print("Resolution set to:", chosen_res)
	else:
		print("No resolution selected!")
