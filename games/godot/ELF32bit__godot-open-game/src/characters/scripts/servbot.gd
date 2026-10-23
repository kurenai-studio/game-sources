extends "classes/path_follow.gd"

@onready var animation_player: AnimationPlayer = (
	$AnimatableBody3D/MeshInstance3D/ANIMATIONS)


func _ready() -> void:
	super()
	if path != null:
		animation_player.play("walk")
	else: animation_player.play("idle")

@warning_ignore("unused_parameter")
func _on_player_selected(player: Node) -> void:
	animation_player.play("dance")

@warning_ignore("unused_parameter")
func _on_player_unselected(player: Node) -> void:
	if path != null:
		animation_player.play("walk")
	else: animation_player.play("idle")
