extends SceneTree
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		main._on_mode_chosen("settings")
	if f == 25:
		root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/settings.png")
		return true
	return false
