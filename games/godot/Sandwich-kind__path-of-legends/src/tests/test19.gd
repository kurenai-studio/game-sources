extends SceneTree
# Скриншоты: настройки матча, отсчёт, деревья, парашют, огонь, экран победы
var main
var f := 0
var tag := ""
func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
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
	match f:
		5: main.show_map_select()
		8: shot("m1_map_settings")
		10:
			main.sel = [0, 1]
			main._on_map_chosen("two_houses", 3, 5)
			main._start_game()
		25: shot("m2_countdown")
		200:
			ps()[0].position = Vector2(700, 1215)
			ps()[1].position = Vector2(1250, 1215)
		260: shot("m3_trees")
		262:
			var g := Grenade.new()
			g.team = 0
			g.attacker = ps()[0]
			g.position = Vector2(820, 1180)
			main.world.add_child(g)
		360: shot("m4_tree_burning")
		420: shot("m5_tree_falling")
		430:
			var p: Player = ps()[1]
			p.position = Vector2(1500, 300)
			p.velocity = Vector2.ZERO
			p._para = 1
			ps()[0].position = Vector2(1150, 1215)
		485: shot("m6_parachute")
		700: shot("m7_landed")
		710:
			main.round_wins = [2, 1]
			main.kills = [4, 2]
			ps()[1].take_damage(999, ps()[0])
		740: shot("m8_match_point")
		840: shot("m9_match_end")
		850: return true
	return false
