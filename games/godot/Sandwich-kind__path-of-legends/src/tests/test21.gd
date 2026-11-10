extends SceneTree
var main
var f := 0
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 30:
		print("window=", DisplayServer.window_get_size(), " mode=", DisplayServer.window_get_mode(), " game area=", root.get_visible_rect().size)
		root.get_viewport().get_texture().get_image().save_png("res://tests/shots/big_menu.png")
		main.sel = [0, 1]
		main._on_map_chosen("two_houses", 3, 5)
		main._start_game()
	if f == 90:
		root.get_viewport().get_texture().get_image().save_png("res://tests/shots/big_game.png")
		return true
	return false
