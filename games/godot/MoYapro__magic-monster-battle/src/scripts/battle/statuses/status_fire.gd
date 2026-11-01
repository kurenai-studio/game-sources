class_name StatusFire extends StatusData


func _init(p_stacks: int) -> void:
	stacks = p_stacks
	display_name = "FIRE"
	display_color = Color(0.95, 0.42, 0.05)
	icon = "▲"


func get_label() -> String:
	return "FIRE %d" % stacks


func on_add_status(target: StatusTarget, incoming: StatusData) -> void:
	if incoming is StatusFire:
		stacks += incoming.stacks
		incoming.stacks = 0
	elif incoming is StatusWet:
		var absorbed := mini(stacks, incoming.stacks)
		stacks -= absorbed
		incoming.stacks -= absorbed
		if stacks <= 0:
			target.remove_status(self)
	elif incoming is StatusFrozen:
		incoming.stacks = 0
		target.remove_status(self)
		target.add_status(StatusWet.new(2))


func on_turn_end(target: StatusTarget, setup: BattleSetup) -> void:
	if not target.is_alive():
		return
	target.set_hp(max(0, target.get_hp() - stacks))
	stacks /= 2
	if stacks <= 0:
		target.remove_status(self)
	if target.get_hp() <= 0:
		target.kill(setup)


func get_turn_damage() -> int:
	return stacks
