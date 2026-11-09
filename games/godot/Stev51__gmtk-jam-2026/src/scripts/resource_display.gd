@tool
extends Control

@export var title: String = ""
@export var description: String = ""
@export var icon: Texture2D

@onready var count_node = $ResourceCount
@onready var sprite_node = $ResourceSprite

func _ready() -> void:
	set_icon()

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		set_icon()

func set_icon() -> void:
	if icon != null:
		sprite_node.texture = icon

func set_text(text: String) -> void:
	count_node.text = text

func _on_area_2d_mouse_entered() -> void:
	if self.title != "":
		MenuHoverBox.hover(title, description)

func _on_area_2d_mouse_exited() -> void:
	if self.title != "":
		MenuHoverBox.unhover()
