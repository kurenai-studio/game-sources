class_name StatusBlind extends StatusData


func _init() -> void:
	stacks = 1
	display_name = "BLIND"
	display_color = Color(0.65, 0.60, 0.30)
	icon = "◑"


func get_label() -> String:
	return "BLIND"


func on_add_status(_target: StatusTarget, incoming: StatusData) -> void:
	if incoming is StatusBlind:
		incoming.stacks = 0


func on_turn_end(target: StatusTarget, _setup: BattleSetup) -> void:
	target.remove_status(self)
