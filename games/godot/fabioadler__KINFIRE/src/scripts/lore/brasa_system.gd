class_name BrasaSystem
extends Resource

var brasa_level: int = 0
const MAX_BRASA: int = 7

func add_brasa(amount: int = 1) -> void:
	brasa_level = mini(brasa_level + amount, MAX_BRASA)

func remove_brasa(amount: int = 1) -> void:
	brasa_level = maxi(brasa_level - amount, 0)

func get_brasa() -> int:
	return brasa_level

func is_max_brasa() -> bool:
	return brasa_level == MAX_BRASA

func clear_brasa() -> void:
	brasa_level = 0

func get_brasa_bonus(stat_type: String) -> float:
	match stat_type:
		"xp_gain":
			return 0.05 * brasa_level
		"damage":
			return 0.02 * brasa_level
		"damage_reduction":
			return 0.01 * brasa_level
		_:
			return 0.0
