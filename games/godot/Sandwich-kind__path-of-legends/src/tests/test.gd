extends SceneTree

var main
var f := 0
var held := {}

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func press(a: String, frames: int) -> void:
	Input.action_press(a)
	held[a] = f + frames

func players() -> Array:
	var r := []
	for n in main.world.get_children():
		if n.has_method("take_damage"):
			r.append(n)
	return r

func count(kind: String) -> int:
	var c := 0
	for n in main.world.get_children():
		if n.get_class() == "RigidBody2D" and n.get_script() and n.has_method("vanish") and kind == "frag":
			c += 1
		if n.has_method("hit") and kind == "destr":
			c += 1
	return c

func _physics_process(_delta: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)

	match f:
		5:
			main.show_select("duel")
			main.world.get_child(1).sel[1] = 1; main.world.get_child(1)._refresh()
			print("select ok, sel=", main.sel)
		10:
			main.start_duel()
			print("duel started, players=", players().size())
		20:
			press("p1_shoot", 120)
			press("p2_shoot", 60)
		40:
			press("p1_a1", 50)        # граната, зажать ~0.8 с
		150:
			press("p1_a1", 150)       # зажать 2.5 с — отмена
		160:
			press("p2_a1", 2)         # массивный снаряд
		200:
			press("p2_a2", 2)         # щит
		230:
			press("p1_a3", 2)         # прыжок с сюрикенами
		300:
			press("p1_a2", 2)         # рывок
			var ps := players()
			print("before dash cd p1=", ps[0]._cd)
		302:
			print("after dash cd p1=", players()[0]._cd, " ammo=", players()[0].ammo)
		330:
			press("p2_a3", 2)         # залп
		420:
			var ps := players()
			ps[0].ult_charge = ps[0].ult_need
			ps[1].ult_charge = ps[1].ult_need
			press("p1_ult", 2)
			press("p2_ult", 2)
		425:
			press("p1_shoot", 200)
		700:
			print("duel f700: frags=", main.get_node(".").world.get_child_count(),
					" debris_all=", players()[0].get_script() != null)
			var fr := 0
			for n in main.world.get_children():
				if n.has_method("vanish"):
					fr += 1
			print("fragments alive=", fr, " destructibles=", count("destr"),
					" score=", main.score)
			print("p1 hp=", players()[0].hp, " p2 hp=", players()[1].hp)
		710:
			# стресс: разнести всё, чтобы проверить лимит 200 обломков
			for k in 6:
				for n in main.world.get_children():
					if n.has_method("hit"):
						n.hit(n.global_position, Vector2.RIGHT, 999, 200.0, 0, {"radial": true})
		800:
			var fr := 0
			for n in main.world.get_children():
				if n.has_method("vanish"):
					fr += 1
			print("after stress: fragments=", fr, " destructibles=", count("destr"))
			print("phys time ms=", Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS) * 1000.0)
		810:
			main.show_select("solo")
		815:
			main.start_solo()
			print("solo started, players=", players().size())
		820:
			press("p1_right", 200)
			press("p1_shoot", 300)
		900:
			press("p1_a2", 2)
		1300:
			print("solo f1300 score=", main.score, " p1 pos=", players()[0].position)
			var ps := players()
			ps[0].ult_charge = ps[0].ult_need
			press("p1_ult", 2)
		1500:
			main.show_menu()
			print("menu ok")
		1510:
			print("DONE")
			return true
	return false
