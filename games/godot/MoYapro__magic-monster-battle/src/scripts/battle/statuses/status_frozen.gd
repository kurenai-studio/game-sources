class_name StatusFrozen extends StatusData


func _init(p_stacks: int = 1) -> void:
	stacks = p_stacks
	display_name = "FROZEN"
	display_color = Color(0.55, 0.80, 0.95)
	icon = "◆"


func get_label() -> String:
	return "FROZEN %d" % stacks


func blocks_action() -> bool:
	return stacks > 0


func on_add_status(target: StatusTarget, incoming: StatusData) -> void:
	if incoming is StatusFrozen:
		stacks += incoming.stacks
		incoming.stacks = 0
	elif incoming is StatusFire:
		incoming.stacks = 0
		target.remove_status(self)


func on_turn_end(target: StatusTarget, _setup: BattleSetup) -> void:
	stacks -= 1
	if stacks <= 0:
		target.remove_status(self)
