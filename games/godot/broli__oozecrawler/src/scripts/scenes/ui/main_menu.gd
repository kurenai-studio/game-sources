extends Control

#referencs for controls
@onready var endless_mode_button: Button = $CenterContainer/VBoxContainer/EndlessButton
@onready var dungeon_crawl_button: Button = $CenterContainer/VBoxContainer/DungeonButton
@onready var achievements_button: Button = $CenterContainer/VBoxContainer/AchievementsButton
@onready var journal_button: Button = $CenterContainer/VBoxContainer/JournalButton
@onready var settings_button: Button = $CenterContainer/VBoxContainer/SettingsButton
@onready var quit_button: Button = $CenterContainer/VBoxContainer/QuitButton

func _ready() -> void:
	endless_mode_button.pressed.connect(_on_endless_mode_button_pressed)
	dungeon_crawl_button.pressed.connect(_on_dungeon_crawl_button_pressed)
	achievements_button.pressed.connect(_on_achievements_button_pressed)
	journal_button.pressed.connect(_on_journal_button_pressed)
	settings_button.pressed.connect(_on_settings_button_pressed)
	quit_button.pressed.connect(_on_quit_button_pressed)


func _on_endless_mode_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/Core/main.tscn")

func _on_dungeon_crawl_button_pressed() -> void:
	#TODO implement dungeon crawler
	#get_tree().change_scene_to_file("res://scenes/Core/???")
	pass

func _on_achievements_button_pressed() -> void:
	#TODO implement achivments in general. and then here go to the achivement viwer
	pass
	
func _on_journal_button_pressed() -> void:
	#TODO implement journal in general. and then here go to the journal viewer
	pass
	
func _on_settings_button_pressed() -> void:
	#TODO implement settings in general. and then here go to the settings viewer
	pass
	
func _on_quit_button_pressed() -> void:
	get_tree().quit()
