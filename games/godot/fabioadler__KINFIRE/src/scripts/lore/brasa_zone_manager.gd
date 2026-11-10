class_name BrasaZoneManager
extends Node

var lore_manager: LoreSystemManager
var current_territory: StringName = &""
var kinfire_zones = [
	&"kinfire_outskirts",
	&"kinfire_heart", 
	&"kinfire_core"
]

func _ready() -> void:
	# Hook into world/territory system - defensive
	if Game and Game.has_meta("world"):
		var world = Game.get_meta("world")
		if world and world.has_signal("territory_changed"):
			world.territory_changed.connect(_on_territory_changed)

func set_lore_manager(manager: LoreSystemManager) -> void:
	lore_manager = manager

func _on_territory_changed(territory_id: StringName) -> void:
	if not lore_manager:
		return
	
	current_territory = territory_id
	
	# Entering Kinfire zone
	if territory_id in kinfire_zones:
		lore_manager.add_brasa(1)
		print("[FIRE] Brasa +1! (Kinfire zone entered)")

func _on_boss_defeated(zone_id: StringName) -> void:
	if not lore_manager:
		return
	
	# Defeated boss in Kinfire zone
	if zone_id == &"kinfire_core":
		lore_manager.brasa_system.clear_brasa()
		print("[FIRE] Brasa cleared! (Maldrach defeated)")

func _on_zone_exit(zone_id: StringName) -> void:
	if not lore_manager:
		return
	
	# Left zone without defeating boss
	if zone_id in kinfire_zones and zone_id != &"kinfire_core":
		lore_manager.remove_brasa(1)
		print("[FIRE] Brasa -1 (zone exited without boss clear)")


func _exit_tree() -> void:
	"""Desconectar signals para evitar memory leak"""
	if Game and Game.has_meta("world"):
		var world = Game.get_meta("world")
		if world and world.territory_changed.is_connected(_on_territory_changed):
			world.territory_changed.disconnect(_on_territory_changed)
