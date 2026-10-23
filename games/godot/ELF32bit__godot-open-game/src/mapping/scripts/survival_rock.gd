extends AnimatableBody3D

@export var is_player_selectable: bool = false
@export var is_player_interactable: bool = true
@export var mouse_cursor_override: int = 1

@onready var node: Node3D = get_parent()


func _on_player_interacted(player: Node) -> void:
	node._on_player_interacted(player)
