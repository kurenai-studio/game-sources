extends Control

@onready var money_node = $GridContainer/Money
@onready var uranium_node = $GridContainer/Uranium
@onready var nukes_node = $GridContainer/Nukes
@onready var research_node = $GridContainer/Research
@onready var labs_node = $GridContainer/Labs
@onready var mines_node = $GridContainer/Mines
@onready var influence_node = $GridContainer/Influence

@onready var influence_delta_node = $GridContainer/Influence/DeltaLabel
@onready var money_delta_node = $GridContainer/Money/DeltaLabel

func _process(_delta: float) -> void:
	
		money_node.set_text("$" + str(snapped(Globals.PlayerCountry.money, 0.01)))
		uranium_node.set_text(str(snapped(Globals.PlayerCountry.uranium, 0.01)))
		nukes_node.set_text(str(int(Globals.PlayerCountry.nukes)))
		research_node.set_text(str(snapped(Globals.PlayerCountry.research_progress, 0.01)))
		labs_node.set_text(str(int(Globals.PlayerCountry.labs)))
		mines_node.set_text(str(int(Globals.PlayerCountry.mines)))
		influence_node.set_text(str(snapped(Globals.PlayerCountry.influence[Globals.PlayerCountry.index], 0.01)))
		
		influence_delta_node.text = "[i]+ " + str(snapped(Globals.PlayerCountry.delta_influence[Globals.PlayerCountry.index] * CountryManager.DELTA_MOD, 0.001)) + " / s"
		money_delta_node.text = "[i]+ " + str(snapped(Globals.PlayerCountry.delta_money * CountryManager.DELTA_MOD, 0.001)) + " / s"
