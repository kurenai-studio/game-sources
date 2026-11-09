class_name UnlockZone
extends Area2D

@export var flag_to_set: String = ""
@export var node_to_reveal: NodePath = NodePath("") 

var _triggered: bool = false

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if _triggered:
		return
	if not body.is_in_group("pushable"):
		return

	_triggered = true

	if flag_to_set != "":
		GameState.set_flag(flag_to_set, true)

	if not node_to_reveal.is_empty():
		var node: CanvasItem = get_node_or_null(node_to_reveal) as CanvasItem
		if node:
			node.show()
