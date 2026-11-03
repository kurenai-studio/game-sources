extends CanvasLayer

func _ready():
	get_tree().paused = true
	$%RestartButton.pressed.connect(_on_restart_pressed)
	$%QuitButton.pressed.connect(_on_quit_pressed)


func set_defeat():
	$%TitleLabel.text = "Defeat"
	$%DescriptionLabel.text = "You lost."


func _on_restart_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file('res://scenes/main/main.tscn')


func _on_quit_pressed():
	get_tree().quit()
