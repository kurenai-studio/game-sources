extends SceneTree
# Воплощение Тьмы само по себе 40 с: какие атаки идут, сколько урона получает герой.
var main
var f := 0
var arena
var stage := "wait"
var t0 := 0
var av: DarkAvatar
var acts := {}
var hstates := {}
var lost := 0
var last_hp := -1

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 0]
		main.start_arena(false, 80)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null:
		return false
	var hero: Player = arena.players[0]
	var b: Player = arena._boss
	match stage:
		"wait":
			hero._protect = 1.0
			if b and not b.frozen and not b.cutscene_shield and arena._cut_cam == null:
				b.hp = 1
				b.take_damage(50, hero)
				stage = "p2"
		"p2":
			hero._protect = 1.0
			if b and not b.frozen and not b.cutscene_shield and arena._cut_cam == null and b.has_meta("title"):
				b.hp = 1
				b.take_damage(50, hero)
				stage = "p3wait"
		"p3wait":
			hero._protect = 1.0
			for n in main.world.get_children():
				if n is DarkAvatar: av = n
			if av and av._state == "fight" and arena._cut_cam == null:
				stage = "soak"
				t0 = f
				last_hp = hero.hp
		"soak":
			var k := f - t0
			if av._head_act != "":
				acts[av._head_act] = acts.get(av._head_act, 0) + 1
			for h in av.hands:
				hstates[h.state] = hstates.get(h.state, 0) + 1
			if hero.hp < last_hp:
				lost += last_hp - hero.hp
			hero.hp = hero.max_hp
			last_hp = hero.hp
			# герой бегает туда-сюда по полу
			hero.global_position.x = 1300.0 + sin(k * 0.01) * 600.0
			if k % 600 == 0 and k > 0:
				print("t=", k / 60, "s  lost=", lost, " (", snappedf(lost / (k / 60.0), 0.1), "/s)")
			if k == 2400:
				print("head acts (frames): ", acts)
				print("hand states (frames): ", hstates)
				print("hero max_hp=", hero.max_hp, " total lost=", lost)
				quit()
	return false
