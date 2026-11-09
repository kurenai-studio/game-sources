@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	if Globals.PlayerCountry.money >= Globals.PlayerCountry.spread_counter_propaganda_cost:
		return true
	else:
		return false

func perform_action() -> void:
	Globals.PlayerCountry.spread_counter_propaganda(Globals.selected_country)

func get_description() -> String:
	var text = "Decreases the rate that the target country gains influence over you\n"
	text += "Cost: "
	if Globals.PlayerCountry.money >= Globals.PlayerCountry.spread_counter_propaganda_cost:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += "$" + str(snapped(Globals.PlayerCountry.spread_counter_propaganda_cost, 0.01)) + "[/color]\n"
	
	return text
