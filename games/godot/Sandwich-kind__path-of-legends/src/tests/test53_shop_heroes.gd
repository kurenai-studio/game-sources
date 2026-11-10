extends SceneTree
# Новые легенды: все способности и ульты (обычные и МЕГА) в Дуэли.
var main
var f := 0
var heroes := [7, 8]
var hi := 0
var t0 := 0
var held := {}
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n
func _physics_process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	if f == 3 or (hi > 0 and f - t0 == 900):
		if hi > 0:
			var me: Player = main.duel_players[0]
			var foe: Player = main.duel_players[1]
			var minions := 0
			for n in main.world.get_children():
				if n is Player and n.is_minion: minions += 1
			print(Characters.LIST[heroes[hi - 1]]["name"], ": foe hp=", foe.hp, " alive=", foe.is_alive(), " kills=", main.kills,
					" me hp=", me.hp, " minions=", minions, " pos=", me.position.round(), " bones=", foe.bone_shields)
		if hi >= heroes.size():
			return true
		main._on_duel_ready("test_field", 9, 99, [heroes[hi], 0], {})
		hi += 1
		t0 = f
	var d := f - t0
	if hi > 0 and d > 200:
		var me: Player = main.duel_players[0]
		var foe: Player = main.duel_players[1]
		me._protect = 1.0
		foe.position.x = me.position.x + 260 * me.facing if d < 400 else foe.position.x
		match d:
			210: press("p1_shoot", 60)
			280: press("p1_a1", 2)
			330: press("p1_a2", 2)
			380: press("p1_a3", 40)
			440: me.ult_charge = 999; press("p1_ult", 2)
			560:
				me.add_buff("cooldown", true)
				me._cd = [0.0, 0.0, 0.0]
			570: press("p1_a1", 2)
			620: press("p1_a2", 2)
			670: press("p1_a3", 40)
			730: me.ult_charge = 999; press("p1_ult", 2)
			820: press("p1_down", 2)
	return false
