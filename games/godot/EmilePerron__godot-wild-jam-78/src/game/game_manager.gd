extends Node2D
class_name GameManager

signal level_completed
signal player_died(message: String)

static var instance: GameManager

var _game_is_active := true
var _money_at_start_of_level := 0

@export var initial_level := 1
@export var level_completed_overlay: Control
@export var level_failed_overlay: Control
@export var victory_overlay: Control

@onready var _player = $Player
@onready var _current_level = $Level
@onready var _current_level_label = $Camera2D/UI/LevelLabel


func _ready() -> void:
	instance = self
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	level_completed.connect(Callable(self, "_on_level_completed"))
	player_died.connect(Callable(self, "_on_player_died"))
	
	if initial_level != 1:
		load_level(initial_level)


func _on_level_completed() -> void:
	_game_is_active = false
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	
	if has_next_level():
		level_completed_overlay.visible = true
	else:
		victory_overlay.visible = true
	

func _on_player_died(message: String) -> void:
	var label = level_failed_overlay.get_node("CenterContainer/Modal/VBoxContainer/Label")
	label.text = "Uh oh.\n" + message + "\n\n"
	
	_game_is_active = false
	level_failed_overlay.visible = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = true
	

func _notification(notification):
	match notification:
		NOTIFICATION_WM_MOUSE_EXIT:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		NOTIFICATION_WM_MOUSE_ENTER:
			if _game_is_active:
				Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


func _show_loader() -> void:
	pass


func load_next_level() -> void:
	_money_at_start_of_level = Money.get_money()
	load_level(_current_level.level_number + 1)
	

func has_next_level() -> bool:
	var next_level_path = _level_path(_current_level.level_number + 1)
	
	return ResourceLoader.exists(next_level_path, "PackedScene")
		

func _level_path(level: int) -> String:
	if level == 0:
		return "res://levels/level_tutorial.tscn"
		
	var padded_level = ("0" if level < 10 else "") + str(level)
	
	return "res://levels/level_" + padded_level + ".tscn"


func load_level(level: int) -> void:
	_show_loader()
	
	var new_level_path = _level_path(level)
	var new_level_scene = load(new_level_path)
	var previous_level = _current_level
	_current_level = new_level_scene.instantiate()
	previous_level.add_sibling(_current_level)
	previous_level.queue_free()
	
	_current_level_label.text = "Level " + str(level)
	_player.reset_position()
	EraserCounter.refill()
	
	level_completed_overlay.visible = false
	level_failed_overlay.visible = false
	_game_is_active = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	get_tree().paused = false


func restart_current_level() -> void:
	Money.set_money(_money_at_start_of_level)
	load_level(_current_level.level_number)


func go_to_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://main-menu.tscn")
