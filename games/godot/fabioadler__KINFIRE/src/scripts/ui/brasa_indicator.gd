class_name BrasaIndicator
extends HBoxContainer

const MAX_BRASA: int = 7
var brasa_system: BrasaSystem
var label: Label

func _ready() -> void:
	label = Label.new()
	add_child(label)
	label.text = "[FIRE] Brasa: 0/{0}".format([MAX_BRASA])
	label.add_theme_font_size_override("font_size", 14)
	update_display()

func set_brasa_system(system: BrasaSystem) -> void:
	brasa_system = system
	update_display()

func update_display() -> void:
	if not brasa_system:
		return
	var current = brasa_system.get_brasa()
	label.text = "[FIRE] Brasa: {0}/{1}".format([current, MAX_BRASA])
	
	# Color gradient: blue -> red
	var ratio = float(current) / MAX_BRASA
	var color = Color.BLUE.lerp(Color.RED, ratio)
	label.add_theme_color_override("font_color", color)
