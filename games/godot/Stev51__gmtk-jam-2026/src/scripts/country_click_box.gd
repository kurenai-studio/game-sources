extends Control

@onready var foreign_interaction_node = $ForeignInteractionContainer
@onready var domestic_interaction_node = $DomesticInteractionContainer

func _ready() -> void:
	
	hide()
	
	Globals.country_click.connect(click)
	Globals.country_unclick.connect(unclick)

func _input(event) -> void:
	if event is InputEventMouseMotion and not Globals.clicked:
		position = event.position

func switch_to_foreign() -> void:
	foreign_interaction_node.show()
	domestic_interaction_node.hide()

func switch_to_domestic() -> void:
	foreign_interaction_node.hide()
	domestic_interaction_node.show()

func click(pos: Vector2) -> void:
	
	position = pos
	
	if Globals.selected_country.index == Globals.PlayerCountry.index:
		switch_to_domestic()
	else:
		switch_to_foreign()
	
	show()

func unclick() -> void:
	hide()
