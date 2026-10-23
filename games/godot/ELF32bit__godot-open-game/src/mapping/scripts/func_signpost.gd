extends AnimatableBody3D

@export var hover_text: String = ""
@export var mouse_cursor_override: int = 1

@export_node_path("Node3D") var _gui_label: NodePath
@onready var gui_label: Node3D = get_node(_gui_label)

@warning_ignore("unused_parameter")
func _on_player_highlighted(player: Node) -> void:
	gui_label.text = hover_text
	gui_label.visible = true

@warning_ignore("unused_parameter")
func _on_player_unhighlighted(player: Node) -> void:
	gui_label.text = ""
	gui_label.visible = false
