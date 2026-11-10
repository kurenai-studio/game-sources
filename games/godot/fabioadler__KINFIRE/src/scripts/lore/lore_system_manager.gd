class_name LoreSystemManager
extends Node

var brasa_system: BrasaSystem
var bonds_system: BondsSystem
var character: Hero

signal brasa_changed(new_level: int)
signal bonds_changed(bond_count: int)
signal all_bonds_collected

func _ready() -> void:
	brasa_system = BrasaSystem.new()
	bonds_system = BondsSystem.new()

func initialize(hero: Hero) -> void:
	character = hero
	# Hook into quest completion - defensive
	if not hero or not Game:
		return
	
	var qlog = null
	if Game.has_meta("quest_log"):
		qlog = Game.get_meta("quest_log")
	elif "quest_log" in Game:
		qlog = Game.quest_log
	
	if qlog and qlog.has_signal("quest_completed"):
		qlog.quest_completed.connect(_on_quest_completed)

func _on_quest_completed(quest_id: StringName) -> void:
	if not bonds_system:
		return
	
	# Map quest IDs to Guardians
	var quest_to_guardian = {
		&"misterio_1": &"mira_pe_leve",
		&"misterio_2": &"ashara_sussurra_magia",
		&"misterio_3": &"lorelyn_espelho_agua",
		&"misterio_4": &"theron_pedra_ressoante",
		&"misterio_5": &"kael_abismo",
		&"misterio_6": &"khalid_areias_douradas",
		&"misterio_7": &"pyros_chama_ardente",
	}
	
	if quest_id in quest_to_guardian:
		var guardian_id = quest_to_guardian[quest_id]
		bonds_system.add_bond(guardian_id)
		bonds_changed.emit(bonds_system.get_bond_count())
		
		if bonds_system.has_all_bonds():
			all_bonds_collected.emit()

func add_brasa(amount: int = 1) -> void:
	if brasa_system:
		brasa_system.add_brasa(amount)
		brasa_changed.emit(brasa_system.get_brasa())

func remove_brasa(amount: int = 1) -> void:
	if brasa_system:
		brasa_system.remove_brasa(amount)
		brasa_changed.emit(brasa_system.get_brasa())

func get_brasa() -> int:
	return brasa_system.get_brasa() if brasa_system else 0

func get_bonds() -> int:
	return bonds_system.get_bond_count() if bonds_system else 0

func has_all_bonds() -> bool:
	return bonds_system.has_all_bonds() if bonds_system else false


func _exit_tree() -> void:
	"""Desconectar signals para evitar memory leak"""
	var qlog = null
	if Game and Game.has_meta("quest_log"):
		qlog = Game.get_meta("quest_log")
	elif Game and "quest_log" in Game:
		qlog = Game.quest_log
	if qlog and qlog.quest_completed.is_connected(_on_quest_completed):
		qlog.quest_completed.disconnect(_on_quest_completed)
