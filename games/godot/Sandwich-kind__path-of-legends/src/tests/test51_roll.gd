extends SceneTree
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main._on_duel_ready("test_field", 9, 99, [0, 1], {})
	if f < 200: return false
	var me: Player = main.duel_players[0]
	me._protect = 1.0
	if f == 200:
		me.position = Vector2(300, 570); me.facing = 1
		main.duel_players[1].position = Vector2(760, 570)
	if f == 210:
		Input.action_press("p1_a1")
	if f == 212:
		Input.action_release("p1_a1")
	if f >= 208 and f < 240:
		print(f, " pos=", me.position.round(), " v=", me.velocity.round(), " forced=", me._forced_time)
	return f > 240
