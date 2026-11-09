@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	return (Globals.PlayerCountry.money >= Globals.PlayerCountry.steal_uranium_cost and Globals.PlayerCountry.influence[Globals.selected_country.index] >= Globals.PlayerCountry.steal_uranium_influence_cost and Globals.selected_country.uranium >= Globals.PlayerCountry.steal_uranium_uranium_gain)

func perform_action() -> void:
	Globals.PlayerCountry.steal_uranium(Globals.selected_country)

func get_description() -> String:
	var text = "Spend money and influence to steal uranium\n"
	
	text += "Cost: "
	if Globals.PlayerCountry.money >= Globals.PlayerCountry.steal_uranium_cost:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += str(Globals.PlayerCountry.steal_uranium_cost) + "[/color]\n"
	
	text += "Influence Cost: "
	if Globals.PlayerCountry.influence[Globals.selected_country.index] >= Globals.PlayerCountry.steal_uranium_influence_cost:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += str(Globals.PlayerCountry.steal_uranium_influence_cost) + "[/color]\n"
	
	text += "Uranium increase: " + str(Globals.PlayerCountry.steal_uranium_uranium_gain, 0.01)
	return text
