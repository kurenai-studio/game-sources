extends Control

@onready var pause_menu_panel: Control = $"../PauseScreen"

func _ready():
	$HBoxContainer/PanelContainer/VBoxContainer/back.pressed.connect(_on_back_button_pressed)

func _on_back_button_pressed():
	visible = false
	pause_menu_panel.visible = true
	pause_menu_panel.get_node("PauseMenu/VBoxContainer/ContinueButton").grab_focus()
	#print("testing back_button_pressed")
