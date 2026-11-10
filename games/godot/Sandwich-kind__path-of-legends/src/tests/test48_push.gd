extends SceneTree
# Толкание коробок (лёгкая/тяжёлая) и осколок на голове
var main
var f := 0
var light: Destructible
var heavy: Destructible
var frag: Fragment
var me: Player
var x0 := 0.0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func box(x: float, y: float, n: int) -> Destructible:
	var d := Destructible.new()
	d.cols = n; d.rows = n; d.cell = 20; d.color = Color(0.7, 0.5, 0.3)
	d.position = Vector2(x, y)
	main.world.add_child(d)
	return d
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main._on_duel_ready("test_field", 9, 99, [0, 0], {})
	if f == 150:
		me = main.duel_players[0]
		me._protect = 99.0
		me.position.x = 700
		main.duel_players[1].position.x = 3000
		frag = Fragment.new()
		frag.position = me.position + Vector2(0, -80)
		main.world.add_child(frag)
	if f == 175: Input.action_press("p1_jump")
	if f == 178: Input.action_release("p1_jump")
	if f == 186:
		print("JUMP: me.y=", me.position.y, " (на земле 570)")
	if f == 230:
		light = box(me.position.x + 120, me.position.y - 10, 2)
	if f == 260:
		x0 = light.position.x
		Input.action_press("p1_right")
	if f == 320:
		Input.action_release("p1_right")
		print("LIGHT moved ", light.position.x - x0, " in 1s")
		light.queue_free()
		me.position = Vector2(200, 560)
		for n in main.world.get_children():
			if n is Destructible and not n.freeze and absf(n.position.x - 330) < 30:
				heavy = n
	if f == 380: Engine.set_meta("dbg", true)
	if f == 383: Engine.remove_meta("dbg")
	if f == 360:
		x0 = heavy.position.x
		Input.action_press("p1_right")
	if f > 360 and f < 420 and f % 10 == 0:
		print(f, " me=", me.position.round(), " hv=", heavy.position.round(), " hvel=", heavy.linear_velocity.round(), " sleep=", heavy.sleeping)
	if f == 420:
		Input.action_release("p1_right")
		print("HEAVY mass=", heavy.mass, " moved ", heavy.position.x - x0, " in 1s, me.y=", me.position.y)
		return true
	return false
