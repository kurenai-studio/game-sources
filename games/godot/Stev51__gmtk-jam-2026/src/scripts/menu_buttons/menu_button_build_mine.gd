@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	return (Globals.PlayerCountry.money >= Globals.PlayerCountry.build_mine_cost)

func perform_action() -> void:
	Globals.PlayerCountry.build_mine()

func get_description() -> String:
	var text = "Spend money to gain 1 mine\n"
	text += "Cost: "
	if resource_conditions_met():
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += str(snapped(Globals.PlayerCountry.build_mine_cost, 0.01)) + "[/color]\n"
	
	text += "Mines increase: 1"
	return text
