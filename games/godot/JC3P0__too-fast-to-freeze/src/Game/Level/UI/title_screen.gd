extends Node3D

@onready var level_loader = $".."
@onready var options_panel: Control = $Title_Options/AudioSettings
@onready var title_panel: Control = $Title_Options/Title
@onready var menu_panel: Control = $Title_Options/Menu
@onready var credit_panel: Control = $Title_Options/CreditPanel
@onready var how_to_play_panel: Control = $Title_Options/HowToPlayPanel

func _ready() -> void:
	if level_loader.get_child(0).name == "TitleScreen":
		$Title_Options/Menu/VBoxContainer/start_button.grab_focus()
 
func _on_start_button_pressed() -> void:
	level_loader.change_level("main_level")
	#print("testing start_button_pressed")

func _on_options_button_pressed() -> void:
	options_panel.visible = true
	menu_panel.visible = false
	credit_panel.visible = false
	how_to_play_panel.visible = false
	options_panel.get_node("HBoxContainer/PanelContainer/VBoxContainer/back").grab_focus()
	#print("testing options_button_pressed")

func _on_credits_button_pressed() -> void:
	credit_panel.visible = true
	how_to_play_panel.visible = false
	#print("testing credits_button_pressed")

func _on_how_to_play_pressed() -> void:
	how_to_play_panel.visible = true
	credit_panel.visible = false
	#print("testing how_to_play_pressed")
