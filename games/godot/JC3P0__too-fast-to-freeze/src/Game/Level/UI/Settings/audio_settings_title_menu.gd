extends Control

@onready var menu_panel: Control = $"../Menu"

func _ready():
	$HBoxContainer/PanelContainer/VBoxContainer/back.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed():
	visible = false
	menu_panel.visible = true
	menu_panel.get_node("VBoxContainer/start_button").grab_focus()
	#print("testing back_button_pressed")
