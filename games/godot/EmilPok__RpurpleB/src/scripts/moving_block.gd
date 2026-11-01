extends Node2D

@export var end_point_pos : Vector2
@export var flipped = false
@onready var Icon = $Moving_block/Icon

@export var horizontal = false

var active = false

var no_sound = false

func _ready() -> void:
	if flipped or horizontal:
		Icon.flip_v = false
		$Moving_block/Collision.position.y -= 1.0
		
func _moving_platform():
	pass
func _active():
	if not no_sound:
		$Audio.start()
	
	var tween = create_tween()
	
	if not active:
		tween.tween_property($Moving_block, "position", end_point_pos, 0.8).set_trans(Tween.TRANS_CUBIC)
		if not horizontal:
			Icon.flip_v = not Icon.flip_v
			Icon.play("Anim")
	else:
		tween.tween_property($Moving_block, "position", Vector2.ZERO, 0.8).set_trans(Tween.TRANS_CUBIC)
		if not horizontal:
			Icon.flip_v = not Icon.flip_v 
			Icon.play("Anim")
	

	$Stop_anim.start()
	
	if not horizontal:
		if Icon.flip_v == true:
			$Moving_block/Collision.position.y += 1.0
		else:
			$Moving_block/Collision.position.y -= 1.0
	
	active = not active


func _on_stop_anim_timeout() -> void:
	Icon.play("Idle")


func _on_audio_timeout() -> void:
	$Woosh.play()
