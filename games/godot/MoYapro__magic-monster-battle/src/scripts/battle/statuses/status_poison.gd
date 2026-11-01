class_name StatusPoison extends StatusData


func _init(p_stacks: int) -> void:
	stacks = p_stacks
	display_name = "POISON"
	display_color = Color(0.50, 0.20, 0.65)
	icon = "▼"


func get_label() -> String:
	return "POISON %d" % stacks


func on_add_status(_target: StatusTarget, incoming: StatusData) -> void:
	if incoming is StatusPoison:
		stacks += incoming.stacks
		incoming.stacks = 0


func on_turn_end(target: StatusTarget, setup: BattleSetup) -> void:
	if not target.is_alive():
		return
	target.set_hp(max(0, target.get_hp() - 1))
	stacks -= 1
	if stacks <= 0:
		target.remove_status(self)
	if target.get_hp() <= 0:
		target.kill(setup)


func get_turn_damage() -> int:
	return 1
