@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	return (Globals.PlayerCountry.money >= Globals.PlayerCountry.sabotage_mine_cost and Globals.PlayerCountry.influence[Globals.selected_country.index] >= Globals.PlayerCountry.sabotage_mine_influence_cost and Globals.selected_country.mines >= 1)

func perform_action() -> void:
	Globals.PlayerCountry.sabotage_mine(Globals.selected_country)

func get_description() -> String:
	var text = "Spend money and influence to remove 1 mine\n"
	
	text += "Cost: "
	if Globals.PlayerCountry.money >= Globals.PlayerCountry.sabotage_mine_cost:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += str(Globals.PlayerCountry.sabotage_mine_cost) + "[/color]\n"
	
	text += "Influence Cost: "
	if Globals.PlayerCountry.influence[Globals.selected_country.index] >= Globals.PlayerCountry.sabotage_mine_influence_cost:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += str(Globals.PlayerCountry.sabotage_mine_influence_cost) + "[/color]\n"
	
	text += "Mine decrease: 1"
	return text
