extends Button

# Export a variable to set the path to the scene you want to load
@export_file var scene_path: String = ""

# Connect the button's "pressed" signal to the function
func _ready():
	pressed.connect(_on_button_pressed)

# Function that gets called when the button is pressed
func _on_button_pressed():
	get_tree().change_scene_to_file(scene_path)
