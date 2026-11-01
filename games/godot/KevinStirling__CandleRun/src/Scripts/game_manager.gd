extends Node2D

@export var levels : Array[PackedScene]

@onready var resume = $Control/VBoxContainer/Resume
@onready var quit = $Control/VBoxContainer/Quit

var current_level : int = 0
var current_level_instance : Level

func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		if current_level_instance.get_tree().paused == false:
			current_level_instance.get_node("CanvasGroup").visible = false
			$TileMap.visible = true
			$Control.visible = true
			current_level_instance.get_tree().paused = true
		else:
			current_level_instance.get_node("CanvasGroup").visible = true
			$TileMap.visible = false
			$Control.visible = false
			current_level_instance.get_tree().paused = false

# Called when the node enters the scene tree for the first time.
func _ready():
	resume.pressed.connect(func():
		current_level_instance.get_node("CanvasGroup").visible = true
		$TileMap.visible = false
		$Control.visible = false
		current_level_instance.get_tree().paused = false
	)
	quit.pressed.connect(func():
		get_tree().quit()
	)
	next_level()

func next_level():
	if levels.size() != 0:
		var level = levels.pop_front().instantiate()
		if current_level_instance != null:
			current_level_instance.queue_free()
		current_level_instance = level
		add_child(current_level_instance)
		current_level_instance.won.connect(func():
			await get_tree().create_timer(1.5).timeout
			current_level += 1
			next_level()
		)
		

func _notification(what):
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		get_tree().quit()
