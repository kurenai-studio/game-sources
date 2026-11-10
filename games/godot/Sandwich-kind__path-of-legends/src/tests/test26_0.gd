extends SceneTree
# Точный счёт выстрелов и МЕГА-способности UBER_TESTIK_2
var main
var f := 0
var arena: ArenaMode
var p: Player
var held := {}
var spawned := {}
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n
func _on_child(n: Node) -> void:
	var k := n.get_class()
	if n is Bullet: k = "Bullet"
	elif n is Grenade: k = "Grenade"
	elif n is Mortar: k = "Mortar"
	elif n is Shell: k = "Shell"
	elif n is Eruptor: k = "Eruptor"
	elif n is Destructible and n.shield_team == 0: k = "Shield"
	spawned[k] = spawned.get(k, 0) + 1
	if n is Shell: spawned["shell_size"] = n.size if n.is_node_ready() else -1
func _physics_process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	match f:
		3:
			main.sel = [0, 0]
			main.start_arena()
			for n in main.world.get_children():
				if n is ArenaMode: arena = n
			arena._queue.clear()
			main.world.child_entered_tree.connect(_on_child)
		200:
			p = arena.player
			p.frozen = false
			arena.wave = 20
			arena._state = "test"
			p.position = Vector2(400, 905)
			p.facing = 1
			p.add_buff("rapid"); p.add_buff("rapid")
			spawned.clear()
		201: press("p1_shoot", 60)
		262:
			print("0 ", 0, " MEGA rapid bullets/s=", spawned.get("Bullet", 0))
			p.buffs.clear()
			p.add_buff("cooldown"); p.add_buff("cooldown")
			p._cd = [0.0, 0.0, 0.0]
			spawned.clear()
		263: press("p1_a1", 30)
		400:
			print("   after a1: ", spawned)
			spawned.clear()
			p._cd = [0.0, 0.0, 0.0]
		401: press("p1_a2", 2)
		420:
			print("   after a2: ", spawned)
			if 0 == 1:
				for n in main.world.get_children():
					if n is Destructible and n.shield_team == 0:
						print("   shield cols=", n.cols, " rows=", n.rows, " cell_hp=", n.cell_hp)
			spawned.clear()
			p._cd = [0.0, 0.0, 0.0]
			p.position = Vector2(400, 905)
			var tgt := Bots.create("tank", 1, Vector2(1200, 880), p, Colosseum.W)
			tgt.frozen = true
			main.world.add_child(tgt)
		421: press("p1_a3", 2)
		600:
			print("   after a3: ", spawned)
			spawned.clear()
			p.ult_charge = p.ult_need
		601: press("p1_ult", 2)
		640:
			print("   after ult: ", spawned)
			return true
	return false
