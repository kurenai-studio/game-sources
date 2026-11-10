extends SceneTree
var f := 0
func _process(_d: float) -> bool:
	f += 1
	if f == 3:
		print("viewport rect=", root.get_visible_rect().size, " window=", root.size)
		return true
	return false
