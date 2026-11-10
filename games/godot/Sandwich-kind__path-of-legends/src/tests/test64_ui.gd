extends SceneTree
var main
var f := 0
var i := 0
const PAIRS := [[0, 1], [4, 5], [6, 7], [8, 2]]
func _initialize() -> void:
	Config.SHOW_TOUCH_ON_PC = true
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 10:
		root.get_viewport().get_texture().get_image().save_png("res://tests/shots/ui_menu.png")
	if f == 12 + i * 60 and i < PAIRS.size():
		main._on_duel_ready("test_field", 9, 99, PAIRS[i], {})
	if f == 12 + i * 60 + 50:
		root.get_viewport().get_texture().get_image().save_png("res://tests/shots/ui_duel_%d.png" % i)
		i += 1
		if i >= PAIRS.size():
			return true
	return false
