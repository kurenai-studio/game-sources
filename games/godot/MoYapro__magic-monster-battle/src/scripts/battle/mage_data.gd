class_name MageData

var name: String
var max_hp: int
var current_hp: int
var mana_allowance: int
var hp_penalty: int = 0    # subtracted from max_hp at battle start (alchemy backfire)
var mana_debt: int = 0     # pre-spent mana at battle start (alchemy fizzle)


func _init(p_name: String, p_max_hp: int, p_mana_allowance: int = 5) -> void:
	name = p_name
	max_hp = p_max_hp
	current_hp = p_max_hp
	mana_allowance = p_mana_allowance
