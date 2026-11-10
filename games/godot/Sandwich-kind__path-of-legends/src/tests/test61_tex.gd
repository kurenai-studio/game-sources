extends SceneTree
var main
var f := 0
var i := -1
var t0 := 0
const IDS := ["test_field", "two_houses", "mountain", "arena_colosseum", "arena_colosseum_night", "arena_jungle", "arena_caves", "arena_kingdom"]
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_stages()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 5:
		root.get_viewport().get_texture().get_image().save_png("res://tests/shots/t_menu.png")
		i = 0
		main._on_duel_ready(IDS[0], 9, 99, [0, 1], {})
		t0 = f
	if i < 0:
		return false
	if f - t0 == 70:
		root.get_viewport().get_texture().get_image().save_png("res://tests/shots/t_%s.png" % IDS[i])
		i += 1
		if i >= IDS.size():
			return true
		main._on_duel_ready(IDS[i], 9, 99, [0, 1], {})
		t0 = f
	return false
