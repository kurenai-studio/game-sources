class_name CombatantState

var hp: int = 0
var shield: int = 0
var statuses: Array[StatusData] = []


func is_alive() -> bool:
	return hp > 0


func absorb_shield(damage: int) -> int:
	var absorbed := mini(shield, damage)
	shield -= absorbed
	return damage - absorbed


func duplicate() -> CombatantState:
	var s := CombatantState.new()
	s.hp = hp
	s.shield = shield
	s.statuses = statuses.duplicate()
	return s
