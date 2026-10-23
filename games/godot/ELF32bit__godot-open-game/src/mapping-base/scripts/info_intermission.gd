extends Node3D

@export_node_path("Camera3D") var _camera: NodePath
@onready var camera: Camera3D = get_node(_camera)

@warning_ignore("unused_parameter")
func _on_generic_signal(parameters: Dictionary) -> void:
	var character: CharacterBody3D = GameState.player.character
	if not character.is_camera_detached():
		var active_camera: Camera3D = character.detach_camera()
		active_camera.global_transform = camera.global_transform
	else: character.attach_camera()
