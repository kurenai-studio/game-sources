extends SceneTree
# Бестиарий: вкладки «Жуткий лес» и «Болото», новые модели.
var main
var f := 0
var bs
func _initialize() -> void:
	Save.load_game()
	Save.see_all()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("/tmp/claude-0/st/%s.png" % n)
func find(t):
	for n in main.world.get_children():
		if is_instance_of(n, t): return n
	return null
func _physics_process(_d: float) -> bool:
	f += 1
	match f:
		5: main._on_mode_chosen("bestiary")
		10:
			bs = find(BestiaryScreen)
			bs._tab = 6; bs._refresh()
		20: shot("bw_eerie")
		22: bs._tab = 7; bs._refresh()
		32: shot("bw_swamp")
		34: bs._tab = 7; bs._sel = 5; bs._refresh()
		44: shot("bw_boglord")
		46: bs._tab = 6; bs._sel = 4; bs._refresh()
		56: shot("bw_witch")
		58: bs._tab = 6; bs._sel = 2; bs._refresh()
		68:
			shot("bw_deadwood")
			return true
	return false
