@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	return (Globals.PlayerCountry.influence[Globals.PlayerCountry.index] >= Globals.PlayerCountry.war_taxes_influence_cost)

func perform_action() -> void:
	Globals.PlayerCountry.raise_war_taxes()

func get_description() -> String:
	var text = "Spend self-influence to increase money gain over time\n"
	text += "Influence Cost: "
	if resource_conditions_met():
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += str(snapped(Globals.PlayerCountry.war_taxes_influence_cost, 0.01)) + "[/color]\n"
	
	text += "Money gain: " + str(snapped(Globals.PlayerCountry.war_taxes_delta_money_gain * CountryManager.DELTA_MOD, 0.001)) + "/s"
	return text
