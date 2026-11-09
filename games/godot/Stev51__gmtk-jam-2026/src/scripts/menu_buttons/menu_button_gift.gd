@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	if Globals.PlayerCountry.money >= Globals.PlayerCountry.gift_cost:
		return true
	else:
		return false

func perform_action() -> void:
	Globals.PlayerCountry.send_gift(Globals.selected_country)

func get_description() -> String:
	var text = "Give money in exchange for influence\n"
	text += "Cost: "
	if Globals.PlayerCountry.money >= Globals.PlayerCountry.gift_cost:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += "$" + str(snapped(Globals.PlayerCountry.gift_cost, 0.01)) + "[/color]\n"
	
	text += "Influence gained: " + str(snapped(Globals.PlayerCountry.gift_influence_gain, 0.01))
	return text
