extends Node

@export var health_component: Node

var drop_percent: float = 0
var weighted_table = WeightedTable.new()


func _ready() -> void:
	(health_component as HealthComponent).died.connect(_on_died)


func set_loot(new_drop_percent: float, loot: Array) -> void:
	drop_percent = new_drop_percent
	weighted_table = WeightedTable.new()

	for entry in loot:
		var drop_id = entry[0]
		var weight = entry[1]
		if not Balance.DROP_SCENES.has(drop_id) or weight <= 0:
			push_error("LootDropComponent has an invalid loot entry: %s." % [entry])
			continue

		weighted_table.add_item(Balance.DROP_SCENES[drop_id], weight, drop_id)


func _on_died():
	if randf() > drop_percent:
		return

	_spawn_drop(weighted_table.pick_item())


func _spawn_drop(drop_scene: PackedScene):
	if drop_scene == null:
		push_error("LootDropComponent has no drop scene assigned.")
		return

	if not owner is Node2D:
		return

	var spawn_position = (owner as Node2D).global_position
	var entities_layer = get_tree().get_first_node_in_group("entities_layer")
	var drop = drop_scene.instantiate() as Node2D
	entities_layer.add_child(drop)
	drop.global_position = spawn_position
