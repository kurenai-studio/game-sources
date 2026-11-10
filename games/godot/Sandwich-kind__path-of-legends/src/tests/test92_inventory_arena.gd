extends SceneTree
# Описание легенды: строки «На Арене» под каждой способностью.
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func find(t):
	for n in main.world.get_children():
		if is_instance_of(n, t): return n
	return null
func _physics_process(_d: float) -> bool:
	f += 1
	match f:
		5: main._on_mode_chosen("inventory")
		10: find(InventoryScreen)._select_hero(0)
		25: root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/inv_hunter.png")
		27: find(InventoryScreen)._select_hero(int(OS.get_environment("HERO")) if OS.get_environment("HERO") != "" else 6)
		42:
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/inv_mortis.png")
			return true
	return false
