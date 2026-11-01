extends Control

@onready var resolution_list := $OptionButton
@onready var apply_button := $Button

var resolutions := [
	Vector2i(640, 360),
	Vector2i(800, 600),
	Vector2i(1280, 720),
	Vector2i(1920, 1080)
]

func _ready():
	for res in resolutions:
		resolution_list.add_item("%dx%d" % [res.x, res.y])
	apply_button.pressed.connect(_on_apply_pressed)

func _on_apply_pressed():
	var selected = resolution_list.get_selected()
	var res = resolutions[selected]
	DisplayServer.window_set_size(res)
	print("Resolution set to: ", res)
