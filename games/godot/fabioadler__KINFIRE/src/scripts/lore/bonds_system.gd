class_name BondsSystem
extends Resource

var active_bonds: Array[StringName] = []
const GUARDIAN_IDS = [
	&"mira_pe_leve", &"ashara_sussurra_magia", &"lorelyn_espelho_agua",
	&"theron_pedra_ressoante", &"kael_abismo", &"khalid_areias_douradas",
	&"pyros_chama_ardente"
]

func add_bond(guardian_id: StringName) -> void:
	if guardian_id not in active_bonds:
		active_bonds.append(guardian_id)

func has_all_bonds() -> bool:
	return active_bonds.size() == GUARDIAN_IDS.size()

func get_bond_count() -> int:
	return active_bonds.size()

func get_active_bonds() -> Array[StringName]:
	return active_bonds.duplicate()

func clear_bonds() -> void:
	active_bonds.clear()
