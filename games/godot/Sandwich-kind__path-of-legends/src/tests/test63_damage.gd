extends SceneTree
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 4:
		main._on_duel_ready("two_houses", 9, 99, [4, 6], {})
	if f == 120:
		for n in main.world.get_children():
			if n is Destructible and not n.background:
				n.hit(n.global_position + Vector2(10, 0), Vector2.RIGHT, 14, 40.0, 5, {"strict": true, "radial": true})
	if f == 130:
		var p: Player = main.duel_players[0]
		Util.explode(main.world, p.global_position + Vector2(260, -40), 120.0, 0, 40, 5, null)
	if f == 140:
		root.get_viewport().get_texture().get_image().save_png("res://tests/shots/dmg1.png")
	if f == 200:
		root.get_viewport().get_texture().get_image().save_png("res://tests/shots/dmg2.png")
		return true
	return false
