extends Node2D

func _ready() -> void:
	push_warning(str(get_tree().get_nodes_in_group("dialogue_box")))
	await get_tree().process_frame
	for zone in get_tree().get_nodes_in_group("repair_zones"):
		if zone is RepairZone:
			zone.repair_requested.connect(_on_repair_requested)


func _on_repair_requested(npc_id: String) -> void:
	# Test de trigger
	GameState.complete_repair(npc_id)
	push_warning("Flux réparation OK pour : " + npc_id)
