extends Control

@onready var background_node = $Background
@onready var title_node = $TitleTextBox
@onready var description_node = $DescriptionTextBox

func _ready() -> void:
	hide()

func _input(event) -> void:
	
	if event is InputEventMouseMotion:
		
		position = event.position
		
		var buffer = background_node.size.x + 20
		if 1920 - position.x < buffer:
			position.x = 1920 - buffer

func hover(title: String, desc: String) -> void:
	set_text(title, desc)
	set_boundaries.call_deferred()
	show()

func unhover() -> void:
	hide()

func set_text(title: String, desc: String) -> void:
	title_node.text = title
	description_node.text = desc

func set_boundaries() -> void:
	
	background_node.size.x = max(title_node.size.x, description_node.size.x) + 20
	
	var size_y = title_node.size.y + 10
	if description_node.text != "":
		size_y += description_node.size.y 
	background_node.size.y = size_y
