@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	return CountryManager.all_countries_signed_armistice

func perform_action() -> void:
	Globals.PlayerCountry.enforce_armistice()

func get_description() -> String:
	var text = "Select this to achieve victory!\n"
	text += "Requirement: "
	if resource_conditions_met():
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += "All countries have signed the Armistice[/color]\n"
	
	text += "Effect: Global nuclear disarmament"
	return text
