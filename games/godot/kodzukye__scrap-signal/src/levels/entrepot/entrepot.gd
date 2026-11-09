extends Node2D

func _ready() -> void:
	AudioManager.play_ambiance("entrepot")
	if OS.get_name() == "Web":
		JavaScriptBridge.eval("document.querySelector('canvas').focus()")
	await get_tree().process_frame
	for zone in get_tree().get_nodes_in_group("repair_zones"):
		if zone is RepairZone:
			zone.repair_requested.connect(_on_repair_requested)

func _on_repair_requested(npc_id: String) -> void:
	GameState.complete_repair(npc_id)
