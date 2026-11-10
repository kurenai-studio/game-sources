extends SceneTree
# Левый стик вверх — прыжок (Арена, один игрок); наискосок слегка — не прыгает.
var main
var f := 0
var p: Player
var arena
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func axis(ax: int, v: float) -> void:
	var ev := InputEventJoypadMotion.new()
	ev.device = 0
	ev.axis = ax as JoyAxis
	ev.axis_value = v
	Input.parse_input_event(ev)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 0]
		main.start_arena(false, 1)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null: return false
	if p == null:
		if arena._state == "fight" and not arena.players[0].frozen:
			p = arena.players[0]
			arena._spawn_t = 999.0
			print("events p1_jump: ", InputMap.action_get_events("p1_jump").map(func(e): return e.as_text()))
			f = 1000
		return false
	p._protect = 2.0
	if f == 1010:
		axis(JOY_AXIS_LEFT_X, -0.6)
		axis(JOY_AXIS_LEFT_Y, -0.4)       # наискосок, чуть вверх — только идёт
	if f == 1030:
		print("diagonal slight: jump=", Input.is_action_pressed("p1_jump"), " left=", Input.is_action_pressed("p1_left"), " vy=", p.velocity.y)
		axis(JOY_AXIS_LEFT_X, 0.0)
		axis(JOY_AXIS_LEFT_Y, 0.0)
	if f == 1060:
		axis(JOY_AXIS_LEFT_Y, -0.9)       # вверх — прыжок
	if f == 1064:
		print("stick up: jump=", Input.is_action_pressed("p1_jump"), " vy=", p.velocity.y, " on_floor=", p.is_on_floor())
		axis(JOY_AXIS_LEFT_Y, 0.0)
		return true
	return false
