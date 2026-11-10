extends Control



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if Global.score > Global.high_score:
		Global.high_score = Global.score
	$Score.text = $Score.text % [Global.score, Global.crashed, Global.high_score]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_play_again_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
