extends SceneTree
var main
var f := 0
var held := {}
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n
func ps() -> Array:
	var r := []
	for n in main.world.get_children():
		if n.has_method("take_damage"):
			r.append(n)
	return r
func shot(name: String) -> void:
	var img := root.get_viewport().get_texture().get_image()
	img.save_png("res://tests/shots/" + name + ".png")
	print("shot ", name)
func _process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	match f:
		5: main.show_select("duel")
		6: main.world.get_child(1).sel[1] = 1; main.world.get_child(1)._refresh()
		12: shot("01_select")
		15:
			main.start_duel()
		25:
			press("p2_a2", 2)
			press("p1_a1", 40)
		40: shot("02_grenade_charge")
		110: shot("03_fire_shield")
		120:
			press("p1_a3", 2)
		135: shot("04_shurikens")
		160: press("p2_a1", 2)
		185: shot("05_shell")
		220: press("p2_a3", 2)
		275: shot("06_barrage")
		330:
			var a := ps()
			a[1].ult_charge = a[1].ult_need
			a[0].ult_charge = a[0].ult_need
		331:
			press("p2_ult", 2)
		360: shot("07_quake")
		420: shot("08_quake_later")
		430:
			press("p1_ult", 2)
		435: press("p1_shoot", 120)
		470: shot("09_minigun")
		600: shot("10_debris")
		610: main.start_solo()
		640: shot("11_solo")
		650: press("p1_right", 60)
		651: press("p1_jump", 3)
		720: shot("12_solo_move")
		725: return true
	return false
