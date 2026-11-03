extends Node2D


var started:bool=false
var can_restart:bool=false
signal game_started()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var t=create_tween()
	t.tween_property($StartLayer/V/Title,"offset_transform_position:x",0.0,1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property($StartLayer/V/Start,"offset_transform_scale",Vector2.ONE,0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property($StartLayer/V/Quit,"offset_transform_scale",Vector2.ONE,0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	GameManager.camera_inst=$PhantomCamera2D
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _input(event: InputEvent) -> void:
	if can_restart:
		if event is InputEventMouseButton:
			if (event as InputEventMouseButton).button_index==MouseButton.MOUSE_BUTTON_LEFT:
				GameManager.reset()
				GameManager.change_scene("res://Scene/game.tscn")
		

func _on_player_died() -> void:
	can_restart=true
	pass # Replace with function body.


func _on_start_pressed() -> void:
	var t=create_tween()
	t.tween_property($StartLayer/V/Title,"offset_transform_position:x",-200.0,1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property($StartLayer/V/Start,"offset_transform_scale",Vector2.ZERO,0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_property($StartLayer/V/Quit,"offset_transform_scale",Vector2.ZERO,0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	t.tween_callback(game_started.emit)
	t.tween_property(self,"started",true,0.0)


func _on_quit_pressed() -> void:
	get_tree().quit()
	pass # Replace with function body.
