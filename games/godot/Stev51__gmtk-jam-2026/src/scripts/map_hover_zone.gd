@tool
extends Area2D

@export var outline_image: Texture2D
@export var hover_image: Texture2D
@export var country: Country

@onready var outline_img_node = $OutlineImg
@onready var hover_img_node = $HoverImg
@onready var hover_sound_node = $HoverSound
@onready var click_sound_node = $ClickSound

func update_textures() -> void:
	if outline_image != null:
		outline_img_node.texture = outline_image
	if hover_image != null:
		hover_img_node.texture = hover_image

func _ready() -> void:
	
	update_textures()
	
	if not Engine.is_editor_hint():
		outline_img_node.visible = true
		hover_img_node.visible = false

func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		update_textures()

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if Globals.map_hoverable:
			get_viewport().set_input_as_handled()
			Globals.map_click(country, event.position)
			click_sound_node.play()

func _on_mouse_entered() -> void:
	if Globals.map_hoverable:
		
		hover_sound_node.play()
		hover_img_node.visible = true
		
		Globals.map_hover(country)

func _on_mouse_exited() -> void:
	hover_img_node.visible = false
	Globals.map_unhover()
