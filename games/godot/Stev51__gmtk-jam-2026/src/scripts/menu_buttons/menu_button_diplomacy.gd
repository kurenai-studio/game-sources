@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	if Globals.PlayerCountry.influence[Globals.PlayerCountry.index] >= Globals.PlayerCountry.send_diplomat_influence_cost:
		return true
	else:
		return false

func perform_action() -> void:
	Globals.PlayerCountry.send_diplomat(Globals.selected_country)

func get_description() -> String:
	var text = "Increases rate of influence gain in country\n"
	text += "Self-Influence Cost: "
	if Globals.PlayerCountry.influence[Globals.PlayerCountry.index] >= Globals.PlayerCountry.send_diplomat_influence_cost:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += str(snapped(Globals.PlayerCountry.send_diplomat_influence_cost, 0.01)) + "[/color]\n"
	text += "Influence gain: " + str(snapped(Globals.PlayerCountry.send_diplomat_delta_influence_gain, 0.01)) + " per second"
	
	return text
