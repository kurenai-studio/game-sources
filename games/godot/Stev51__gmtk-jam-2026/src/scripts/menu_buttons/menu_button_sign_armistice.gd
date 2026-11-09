@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	return (Globals.PlayerCountry.influence[Globals.selected_country.index] >= Globals.PlayerCountry.convince_to_sign_influence_cost and Globals.selected_country.willingness_to_fire_nukes <= 10 and Globals.selected_country.signed_armistice == false)

func perform_action() -> void:
	Globals.PlayerCountry.convince_to_sign_armistice(Globals.selected_country)

func get_description() -> String:
	var text = "Use influence to convince them to sign the Armistice. Required for victory.\nMust have at most 10 willingness to fire nukes.\n"
	text += "Influence Cost: "
	if Globals.PlayerCountry.influence[Globals.selected_country.index] >= Globals.PlayerCountry.convince_to_sign_influence_cost:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += str(snapped(Globals.PlayerCountry.convince_to_sign_influence_cost, 0.01)) + "[/color]\n"
	
	text += "Effect: Country signs the Armistice"
	return text
