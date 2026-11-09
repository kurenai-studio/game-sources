@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	return (Globals.PlayerCountry.money >= Globals.PlayerCountry.spy_on_technology_cost)

func perform_action() -> void:
	Globals.PlayerCountry.spy_on_technology(Globals.selected_country)

func get_description() -> String:
	var text = "Spend money to steal research progress. More effective with a bigger gap.\n"
	text += "Cost: "
	if resource_conditions_met():
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += '$' + str(snapped(Globals.PlayerCountry.spy_on_technology_cost, 0.01)) + "[/color]\n"
	
	text += "Research gained: " + str(snapped(maxf(5, (Globals.selected_country.research_progress - Globals.PlayerCountry.research_progress) / 2), 0.01))
	return text
