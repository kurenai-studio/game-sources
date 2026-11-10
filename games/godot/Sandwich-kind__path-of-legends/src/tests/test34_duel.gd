extends SceneTree
var main
var f := 0
var maps := ["test_field", "two_houses", "mountain"]
var mi := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3 or (f > 3 and f % 400 == 3):
		if mi >= maps.size():
			print("duel maps ok")
			return true
		main._on_duel_ready(maps[mi], 1, 2, [0, 1])
		mi += 1
	if f % 400 == 200 and main.duel_players.size() == 2:
		var a = main.duel_players[0]
		var b = main.duel_players[1]
		b.take_damage(999, a)
		print(maps[mi - 1], " kills ", main.kills)
	Input.action_press("p1_shoot") if f % 2 == 0 else Input.action_release("p1_shoot")
	return false
