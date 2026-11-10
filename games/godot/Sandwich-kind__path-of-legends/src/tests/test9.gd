extends SceneTree
# Скриншоты новых вещей
var main
var f := 0
var held := {}
var tag := ""
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n
func ps() -> Array:
	var r := []
	for n in main.world.get_children():
		if n is Player:
			r.append(n)
	return r
func shot(name: String) -> void:
	root.get_viewport().get_texture().get_image().save_png("res://tests/shots/" + tag + "_" + name + ".png")
	print("shot ", name)
func _process(_d: float) -> bool:
	f += 1
	if f == 2:
		tag = str(int(root.get_visible_rect().size.x))
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	match f:
		5: main._on_mode_chosen("duel")
		10: shot("a_mapselect")
		12: main._on_map_chosen("two_houses", 3, 5)
		16: shot("b_select")
		18:
			main.sel = [0, 1]
			main._start_game()
		30: shot("c_houses_far")
		32:
			ps()[0].position = Vector2(1850, 1215)
			ps()[1].position = Vector2(2150, 1215)
		150: shot("d_houses_near")
		155:
			press("p1_a1", 40)
			ps()[1].position = Vector2(2000, 1215)
		185: shot("e_grenade_aim")
		200: press("p2_a2", 2)
		205: press("p2_a3", 2)
		232: shot("f_barrage_rise")
		262: shot("g_barrage_dive")
		300: press("p1_a3", 2)
		322: shot("h_leap_phase")
		330:
			ps()[0].ult_charge = 999
		331: press("p1_ult", 2)
		332: press("p1_shoot", 250)
		420: shot("i_minigun_grenades")
		500:
			main.map_id = "test_field"
			main.start_duel()
		520: shot("j_testfield")
		530: main.start_solo()
		560: shot("k_solo")
		565: return true
	return false
