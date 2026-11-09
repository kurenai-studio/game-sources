class_name RepairZone
extends Area2D

@export var npc_id : String = "vrac7"
@export var prompt_text : String = "[E] Repair"

signal repair_requested(npc_id: String)

func interact() -> void:
	if GameState.can_repair(npc_id):
		repair_requested.emit(npc_id)
		_start_repair()

# Dans le script du PNJ, quand les items sont validés
func _start_repair() -> void:
	var minigame: RepairMinigame = preload("res://ui/minigame/repair_minigame.tscn").instantiate() as RepairMinigame
	get_tree().root.add_child(minigame)
	minigame.repair_complete.connect(_on_repair_done)
	minigame.open("vrac7")

func _on_repair_done() -> void:
	GameState.set_flag("vrac7_repaired", true)
	# dialogue_system.start("vrac7_post_repair")
	# → [LOG] "Unité VRAC-7 : réparation complète. Statut : opérationnel."
