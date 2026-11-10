extends SceneTree
var main
var f := 0
func _initialize() -> void:
	Save.load_game()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func add(n: Node, pos: Vector2) -> void:
	n.position = pos
	main.world.add_child(n)
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 4:
		main._on_duel_ready("test_field", 9, 99, [0, 1], {})
	if f == 200:
		var y := 200.0
		var x := 300.0
		for st in ["soul", "tracer", "shock"]:
			var b := Bullet.new(); b.style = st; b.speed = 1.0; b.size = 14.0 if st == "soul" else 7.0; b.team = 9
			add(b, Vector2(x, y)); x += 80
		for pl in ["javelin", "beam", "thorn", "thorn_big", "flask", "net"]:
			var s := Spear.new(); s.payload = pl; s.velocity = Vector2(1, -0.01); s.team = 9
			add(s, Vector2(x, y)); x += 80
		x = 300.0; y = 300.0
		var sh := Shuriken.new(); sh.detailed = true; sh.speed = 1.0; sh.team = 9; add(sh, Vector2(x, y)); x += 80
		var g := Grenade.new(); g.style = "frag"; g.team = 9; g.gravity_scale = 0.0; add(g, Vector2(x, y)); x += 80
		for m in ["", "pierce", "blast", "knife", "knife_bomb"]:
			var a := Arrow.new(); a.mode = m; a.velocity = Vector2(1, 0); a.gravity = 0.0; a.team = 9
			add(a, Vector2(x, y)); x += 80
		var h := ThrownHammer.new(); h.owner_p = main.duel_players[0]; h.team = 9; h.set_physics_process(false); add(h, Vector2(x, y))
	if f == 203:
		var im := root.get_viewport().get_texture().get_image()
		im.crop(1600, 720)
		var c := im.get_region(Rect2i(240, 160, 900, 200))
		c.resize(1800, 400, Image.INTERPOLATE_NEAREST)
		c.save_png("res://tests/shots/proj.png")
		return true
	return false
