@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	return (Globals.PlayerCountry.money >= Globals.PlayerCountry.nuke_cost and Globals.PlayerCountry.uranium > 1 and Globals.PlayerCountry.can_build_nukes == true)

func perform_action() -> void:
	Globals.PlayerCountry.build_nuke()

func get_description() -> String:
	var text = "Spend money to gain 1 nuke. Requires nuclear capabilities.\n"
	
	text += "Cost: "
	if Globals.PlayerCountry.money >= Globals.PlayerCountry.nuke_cost:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += str(snapped(Globals.PlayerCountry.nuke_cost, 0.01)) + "[/color]\n"
	
	text += "Uranium Cost: "
	if Globals.PlayerCountry.uranium > 1:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += "1[/color]\n"
	
	text += "Nukes increase: 1"
	return text
