class_name StatusWet extends StatusData


func _init(p_stacks: int) -> void:
	stacks = p_stacks
	display_name = "WET"
	display_color = Color(0.25, 0.55, 0.90)
	icon = "▼"


func get_label() -> String:
	return "WET %d" % stacks


func on_add_status(target: StatusTarget, incoming: StatusData) -> void:
	if incoming is StatusWet:
		stacks += incoming.stacks
		incoming.stacks = 0
	elif incoming is StatusFrozen:
		incoming.stacks = (stacks / 10) + incoming.stacks
		target.remove_status(self)
	elif incoming is StatusFire:
		var absorbed := mini(stacks, incoming.stacks)
		stacks -= absorbed
		incoming.stacks -= absorbed
		if stacks <= 0:
			target.remove_status(self)


func on_turn_end(target: StatusTarget, _setup: BattleSetup) -> void:
	stacks -= 1
	if stacks <= 0:
		target.remove_status(self)
