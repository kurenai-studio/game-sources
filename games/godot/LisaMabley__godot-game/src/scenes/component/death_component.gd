extends Node2D

@export var health_component: Node
@export var sprite: Sprite2D


func _ready() -> void:
	health_component.died.connect(_on_died)


func _on_died():
	if owner == null || not owner is Node2D:
		return
		
	var spawn_position = owner.global_position
	
	var tree = get_tree()
	var entities_layer = tree.get_first_node_in_group("entities_layer")
	get_parent().remove_child(self)
	entities_layer.add_child(self)
	
	global_position = spawn_position	
