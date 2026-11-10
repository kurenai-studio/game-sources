extends SceneTree
# Лавка: карточка Пивозавра; Книга легенд: Пивозавр и Рассвет.
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	Save.add_gold(5000)
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func find(t):
	for n in main.world.get_children():
		if is_instance_of(n, t): return n
	return null
func _physics_process(_d: float) -> bool:
	f += 1
	match f:
		5: main._on_mode_chosen("shop")
		20:
			var s = find(ShopScreen)
			s._fill_shelves(0, false)
			var j := -1
			for i in s._offers.size():
				var o: Dictionary = s._offers[i]
				if o.get("kind", "") == "hero" and Characters.LIST[o["idx"]]["name"] == "ПИВОЗАВР":
					j = i
			print("pivo offer slot=", j)
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/shop_shelf.png")
			if j >= 0:
				s._open_offer(j)
		40: root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/shop_pivo.png")
		45:
			Save.unlock_all_heroes()
			main._on_mode_chosen("inventory")
		50: find(InventoryScreen)._select_hero(14)
		65: root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/inv_pivo.png")
		66: find(InventoryScreen)._select_hero(13)
		80:
			root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/inv_rassvet.png")
			return true
	return false
