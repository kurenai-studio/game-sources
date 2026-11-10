extends SceneTree
var f := 0
func _initialize() -> void:
	root.add_child(load("res://main.tscn").instantiate())
func _process(_d: float) -> bool:
	f += 1
	if f == 20:
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/menu.png")
		return true
	return false
