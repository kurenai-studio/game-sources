extends HBoxContainer

@export_node_path("TextureRect") var example_heart: NodePath = "./ExampleHeart"


func _ready():
	get_node(example_heart).visible = false


func _lives_updated(hearts: int):
	# Remove all previous hearts
	for child in get_children():
		if child == get_node(example_heart):
			continue
		child.queue_free()
	
	# Make new hearts based off the example heart
	for _heart in hearts:
		var example_heart_node = get_node(example_heart)
		
		var new_heart = example_heart_node.duplicate()
		new_heart.visible = true
		
		add_child(new_heart)
