extends SceneTree
# Урон легенд по боссу за 8 секунд (стрельба + способности + ульта), чтобы сравнить баланс Арены.
var main
var f := 0
var heroes := [0, 1, 4, 5, 6, 7, 8, 9, 10]
var hi := -1
var t0 := 0
var boss: Player
var mode_name := "arena"
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	mode_name = OS.get_environment("BAL") if OS.get_environment("BAL") != "" else "arena"
	if OS.get_environment("HEROES") != "":
		heroes = Array(OS.get_environment("HEROES").split(",")).map(func(x): return int(x))
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func _next() -> void:
	hi += 1
	if hi >= heroes.size():
		return
	main._on_duel_ready("test_field", 9, 99, [heroes[hi], 0], {})
	t0 = f
func _process(_d: float) -> bool:
	f += 1
	if f == 3:
		_next()
	if hi >= heroes.size():
		return true
	var d := f - t0
	if main.duel_players.size() < 2 or not is_instance_valid(main.duel_players[0]):
		return false
	var me: Player = main.duel_players[0]
	var p2: Player = main.duel_players[1]
	if d == 199:
		for n in main.world.get_children():
			if n is Destructible: n.queue_free()          # ровное поле без ящиков и колонн
	if d == 200:
		if mode_name == "arena":
			var ch: Dictionary = Characters.LIST[heroes[hi]]
			me.ability_cds = (ch["cds"] as Array).duplicate()       # снять поправки Дуэли
			me.ult_need = float(ch.get("ult_need", 300.0))
			Balance.apply(me, "arena")
		p2.position = Vector2(1100, 100)
		p2.frozen = true
		p2._protect = 999.0
		boss = Bots.create("gladiator", 1, Vector2(700, 540), me, 1152.0)
		boss.max_hp = 99999
		boss.hp = 99999
		boss.frozen = true
		boss.speed = 0.0
		if mode_name == "arena":
			boss.stagger_max = 750 * 0.10
		main.world.add_child(boss)
		me.position = Vector2(620 if Characters.LIST[heroes[hi]]["kit"] in ["smith", "samurai", "champion"] else 400, 560)
		me.facing = 1
		me.ult_charge = 0.0
	if d > 205 and d < 205 + 480:
		me._protect = 1.0
		# лук натягивается, пока кнопка зажата, — отпускаем после полного натяжения
		if Characters.LIST[heroes[hi]]["kit"] == "hunter" and d % 52 >= 50:
			Input.action_release("p1_shoot")
		else:
			Input.action_press("p1_shoot")
		if d % 40 == 0 and OS.get_environment("ABIL") != "0":
			for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult"]:
				Input.action_press(a)
		elif d % 40 == 3:
			for a in ["p1_a1", "p1_a2", "p1_a3", "p1_ult"]:
				Input.action_release(a)
		me.facing = 1
	if false:
		var nb := 0
		for n in main.world.get_children():
			if n is Bullet: nb += 1
		print("d=", d, " me=", me.position.round(), " boss=", boss.position.round(), " hp=", boss.hp, " bullets=", nb, " frozen=", me.frozen, " ammo=", me.ammo)
	if d == 205 + 480:
		Input.action_release("p1_shoot")
		print(Characters.LIST[heroes[hi]]["name"], ": урон по боссу за 8 с = ", 99999 - boss.hp, "  (", mode_name, ")")
		boss.queue_free()
		_next()
	return false
