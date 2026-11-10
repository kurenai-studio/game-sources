extends SceneTree
# Виртуальный стик: касание в зоне стика → ходьба, вверх → прыжок, отпустил → стоп.
var main
var f := 0
var x0 := 0.0
func _initialize() -> void:
	Config.SHOW_TOUCH_ON_PC = true
	StorySettings.set_value("touch_move", "stick")
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
# события подаём прямо стику: в тестовом окне без экрана координаты касаний пересчитываются иначе
func stick() -> VirtualStick:
	return root.find_children("*", "VirtualStick", true, false)[0]
func touch(pos: Vector2, on: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = 0
	e.position = pos
	e.pressed = on
	stick()._input(e)
func drag(pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = 0
	e.position = pos
	stick()._input(e)
func _process(_d: float) -> bool:
	f += 1
	var vs := root.get_viewport().get_visible_rect().size
	var c := Vector2(110, vs.y - 80)
	match f:
		3: main.start_story(2, StorySave.new_game("T", StoryLook.default_look()))
		20:
			for n in main.world.get_children():
				if n is StoryMode: x0 = n.hero.position.x
			touch(c, true)
			var st := root.find_children("*", "VirtualStick", true, false)
			print("sticks=", st.size(), " area=", st[0].area if st.size() > 0 else null, " c=", c)
		21: drag(c + Vector2(55, 0))
		50:
			var sm: StoryMode
			for n in main.world.get_children():
				if n is StoryMode: sm = n
			print("right held=", Input.is_action_pressed("p1_right"), " strength=", snappedf(Input.get_action_strength("p1_right"), 0.01), " moved=", int(sm.hero.position.x - x0))
			drag(c + Vector2(10, -60))
		52: print("jump held=", Input.is_action_pressed("p1_jump"), " right=", Input.is_action_pressed("p1_right"))
		55: touch(c + Vector2(10, -60), false)
		57:
			print("released: right=", Input.is_action_pressed("p1_right"), " jump=", Input.is_action_pressed("p1_jump"))
			StorySave.delete_slot(2)
			return true
	return false
