extends Button

@export var url: String = "https://example.com"

# Connect the button's "pressed" signal to the function
func _ready():
	pressed.connect(_on_button_pressed)

# Function that gets called when the button is pressed
func _on_button_pressed():
	OS.shell_open(url)
