extends SceneTree
# Стена Кузнеца падает прямо на противника: его отодвигает вбок, а не наверх стены или под карту.
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _process(_d: float) -> bool:
	f += 1
	if f == 3:
		main._on_duel_ready("test_field", 9, 99, [1, 0], {})
	if f == 200:
		var me: Player = main.duel_players[0]
		var foe: Player = main.duel_players[1]
		me.position = Vector2(300, 560)
		me.facing = 1
		foe.position = Vector2(400, 560)
		me._protect = 0.0
	if f == 210:
		print("before: foe=", main.duel_players[1].position.round())
		Input.action_press("p1_a2")
	if f == 212:
		Input.action_release("p1_a2")
	if f in [230, 260, 320]:
		var foe2: Player = main.duel_players[1]
		var walls := []
		for n in main.world.get_children():
			if n is Destructible and n.lifetime > 0.0: walls.append(n.global_position.round())
		print(f, ": foe=", foe2.position.round(), " hp=", foe2.hp, " wall=", walls)
	return f > 320
