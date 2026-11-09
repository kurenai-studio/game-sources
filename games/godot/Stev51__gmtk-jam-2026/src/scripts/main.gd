extends Node2D

var win_screen_scene = preload("res://scenes/win_screen.tscn")
var lose_screen_scene = preload("res://scenes/lose_screen.tscn")

func _ready() -> void:
	
	DoomsdayClock.infinite_hour.connect(win_game)
	DoomsdayClock.zero_hour.connect(lose_game)
	
	Globals.PlayerCountry.signed_armistice = true

func _input(event):
		
	if event.is_action_pressed("pause"):
		
		if Globals.game_speed == Globals.GameSpeed.PAUSED:
			Globals.game_speed = Globals.GameSpeed.NORMAL
		else:
			Globals.game_speed = Globals.GameSpeed.PAUSED
		
	elif event.is_action_pressed("x1_speed"):
		
		Globals.game_speed = Globals.GameSpeed.NORMAL
		
	elif event.is_action_pressed("x2_speed"):
		
		Globals.game_speed = Globals.GameSpeed.FAST

func win_game() -> void:
	add_child(win_screen_scene.instantiate())

func lose_game() -> void:
	add_child(lose_screen_scene.instantiate())
