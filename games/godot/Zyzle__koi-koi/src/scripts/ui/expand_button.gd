@tool
extends TextureButton

@onready var label_node: Label = $Label

func _ready():
	label_node.resized.connect(_on_label_resized)

func _on_label_resized():
	if label_node.size.x > self.size.x:
		self.size.x = label_node.size.x