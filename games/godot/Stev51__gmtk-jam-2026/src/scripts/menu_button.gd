@tool
class_name CustomMenuButton extends Control

@export var title: String
@export var description: String
@export var icon: Texture2D
@export var function_name: String

@onready var icon_node = $Icon

var hovered = false

func _process(_delta: float) -> void:
	set_icon()
	if hovered:
		MenuHoverBox.hover(title, get_description())

func set_icon() -> void:
	if icon != null:
		
		icon_node.texture = icon
		
		if not Engine.is_editor_hint():
			if not resource_conditions_met():
				icon_node.modulate = Color(0.267, 0.267, 0.267, 1.0)
			else:
				icon_node.modulate = Color(1,1,1,1) # Reset color

func _on_button_pressed() -> void:
	if resource_conditions_met():
		perform_action()
	
func resource_conditions_met() -> bool:
	return false

func perform_action() -> void:
	pass

func get_description() -> String:
	return "N/A"

func _on_button_mouse_entered() -> void:
	MenuHoverBox.hover(title, get_description())
	hovered = true

func _on_button_mouse_exited() -> void:
	hovered = false
	MenuHoverBox.unhover()
