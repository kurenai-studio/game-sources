class_name StatusData extends RefCounted

var stacks: int = -1
var display_name: String = ""
var display_color: Color = Color.WHITE
var icon: String = "●"
var source_enemy_id: String = ""


func get_label() -> String:
	return display_name


func blocks_action() -> bool:
	return false


func on_add_status(_target: StatusTarget, _incoming: StatusData) -> void:
	pass


func on_turn_end(_target: StatusTarget, _setup: BattleSetup) -> void:
	pass


func get_turn_damage() -> int:
	return 0


func on_zap(_target: StatusTarget, _setup: BattleSetup) -> void:
	pass


func on_mana_spent(_target: StatusTarget, _setup: BattleSetup) -> void:
	pass
