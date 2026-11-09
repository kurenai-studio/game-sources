@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	return (Globals.PlayerCountry.money >= Globals.PlayerCountry.spread_propaganda_cost)

func perform_action() -> void:
	Globals.PlayerCountry.spread_propaganda()

func get_description() -> String:
	var text = "Spend money to increase self-influence gain over time\n"
	text += "Cost: "
	if resource_conditions_met():
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += str(snapped(Globals.PlayerCountry.spread_propaganda_cost, 0.01)) + "[/color]\n"
	
	text += "Influence gain: " + str(snapped(Globals.PlayerCountry.spread_progaganda_delta_influence_gain * CountryManager.DELTA_MOD, 0.001)) + "/s"
	return text
