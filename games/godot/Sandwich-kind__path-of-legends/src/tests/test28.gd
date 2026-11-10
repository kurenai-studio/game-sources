extends SceneTree
var main
var f := 0
var arena: ArenaMode
var p: Player
var held := {}
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n
func shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("res://tests/shots/" + name + ".png")
	print("shot ", name)
func _process(_d: float) -> bool:
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
		200:
			p = arena.player
			p.frozen = false
			arena.wave = 20
			arena._state = "test"
			for sp in arena.info["spawners"]:
				sp._t = 0.0          # сразу выдать шарики
			p.position = Vector2(1300, 905)
		230:
			p.add_buff("armor"); p.add_buff("speed"); p.add_buff("speed"); p.add_buff("cooldown"); p.add_buff("cooldown")
			p.ult_charge = 200
		260: shot("u1_arena_buffs")
		270:
			p.facing = -1
			p._cd = [0.0, 0.0, 0.0]
			press("p1_a1", 35)
		345: shot("u2_mega_grenades")
		360:
			p._cd = [0.0, 0.0, 0.0]
			press("p1_a3", 2)
		420: shot("u3_mega_leap")
		430:
			arena._rebuild(3)
		500:
			main.sel = [1, 0]
			main.start_arena()
			for n in main.world.get_children():
				if n is ArenaMode: arena = n
			arena._queue.clear()
		700:
			p = arena.player
			p.frozen = false
			arena.wave = 20
			arena._state = "test"
			arena._rebuild(3)
		760:
			p.position = Vector2(700, 905)
			p.facing = 1
			for k in 3:
				var b := Bots.create(["grunt", "tank", "soldier"][k], 5, Vector2(1300 + k * 150, 880), p, Colosseum.W)
				b.frozen = true
				main.world.add_child(b)
				arena._alive.append(b)
			p.add_buff("cooldown"); p.add_buff("cooldown")
			p._cd = [0.0, 0.0, 0.0]
		765: press("p1_a3", 2)
		820: shot("u4_mega_barrage_night")
		830:
			p._cd = [0.0, 0.0, 0.0]
			press("p1_a2", 2)
		840:
			p.ult_charge = p.ult_need
			press("p1_ult", 2)
		880: shot("u5_mega_quake_shield")
		890: return true
	return false
