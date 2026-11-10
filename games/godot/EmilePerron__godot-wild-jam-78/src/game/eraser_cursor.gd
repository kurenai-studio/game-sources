extends Node2D

var hovered_erasable = null

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position = get_global_mouse_position()


func _on_cursor_left_node(node: Node2D) -> void:
	if not hovered_erasable:
		return
		
	if hovered_erasable == _get_erasable_from_node(node):
		hovered_erasable = null
	
	
func _on_cursor_entered_node(node: Node2D) -> void:
	var erasable = _get_erasable_from_node(node)
	
	if erasable:
		hovered_erasable = erasable
	

func _get_erasable_from_node(node: Node2D) -> Node2D:
	var erasable = node
	
	while not erasable.get_meta('erasable', false):
		erasable = erasable.get_parent()
		
		if erasable == null:
			return null
		
	return erasable
	

func _on_eraser_area_2d_input_event(viewport: Node, event: InputEvent, shape_idx: int) -> void:
	if hovered_erasable == null or event is not InputEventMouseButton or not event.is_pressed():
		return
		
	if not EraserCounter.can_erase():
		# TODO: Show some kind of error indicator
		return
	
	Eraser.erase(hovered_erasable)
	EraserCounter.decrement()
	hovered_erasable.queue_free()
	hovered_erasable = null
