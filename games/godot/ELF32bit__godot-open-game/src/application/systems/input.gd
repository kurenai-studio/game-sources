extends Node

enum Mode { Player = 0 }
var mode: Mode = Mode.Player:
	set(value):
		mode = value
		var node := get_current()
		_enable_input(node)


func get_current() -> Node:
	var index := int(mode)
	var node := get_child(index)
	return node


func _enable_input(node: Node) -> void:
	for child in get_children():
		child.set_process_input(false)
		child.set_physics_process(false)
		child.set_process(false)
	if is_instance_valid(node):
		node.set_process_input(true)
		node.set_physics_process(true)
		node.set_process(true)


func _ready() -> void:
	_enable_input(null)
