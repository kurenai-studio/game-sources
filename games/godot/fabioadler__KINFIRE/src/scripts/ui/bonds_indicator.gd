class_name BondsIndicator
extends HBoxContainer

var bonds_system: BondsSystem
var label: Label

func _ready() -> void:
	label = Label.new()
	add_child(label)
	label.text = "[CHAIN]️ Laços: 0/7"
	label.add_theme_font_size_override("font_size", 14)
	update_display()

func set_bonds_system(system: BondsSystem) -> void:
	bonds_system = system
	update_display()

func update_display() -> void:
	if not bonds_system:
		return
	var current = bonds_system.get_bond_count()
	label.text = "[CHAIN]️ Laços: {0}/7".format([current])
	
	# Color: gray -> gold when all 7
	if bonds_system.has_all_bonds():
		label.add_theme_color_override("font_color", Color.GOLD)
	else:
		label.add_theme_color_override("font_color", Color.GRAY)
