@tool
extends CustomMenuButton

func resource_conditions_met() -> bool:
	return (Globals.PlayerCountry.research_progress > 99.9 and not Globals.PlayerCountry.can_build_nukes)

func perform_action() -> void:
	Globals.PlayerCountry.establish_nuclear_capabilities()

func get_description() -> String:
	var text = "Use research progress to unlock nukes\n"
	text += "Research Requirement: "
	if Globals.PlayerCountry.research_progress > 99.9:
		text += "[color=green]"
	else:
		text += "[color=red]"
	text += "100.0[/color]\n"
	
	text += "Effect: Unlocks building nuclear warheads"
	return text
