extends SceneTree
# Насколько опасен Колосс: сколько урона получает герой за 30 с в первой фазе и во второй.
# Герой бегает туда-сюда и иногда прыгает (как неопытный игрок).
var main
var f := 0
var arena
var boss: Player
var p: Player
var t0 := -1
var dmg := {"1": 0, "2": 0, "w": 0}
var phase := "1"
var by := {}

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		main.sel = [0, 0]
		main.start_arena(false, 50)
		for n in main.world.get_children():
			if n is ArenaMode: arena = n
	if arena == null:
		return false
	if t0 < 0:
		if arena._boss and is_instance_valid(arena._boss) and not arena._boss.frozen and not arena._boss.cutscene_shield:
			boss = arena._boss
			p = arena.players[0]
			t0 = f
			p.on_hurt = func(a, who):
				dmg[phase] += a
		return false
	var k := f - t0
	p.hp = p.max_hp
	arena.lives = 3
	if is_instance_valid(boss) and boss.is_alive():
		boss.hp = maxi(boss.hp, boss.max_hp / 2) if k < 1800 + 300 else boss.hp
	# бегает туда-сюда, иногда прыгает
	for a in ["p1_left", "p1_right", "p1_jump"]:
		Input.action_release(a)
	Input.action_press("p1_left" if (k / 150) % 2 == 0 else "p1_right")
	if k % 70 < 8:
		Input.action_press("p1_jump")
	if k == 1800:
		print("phase 1: hero took ", dmg["1"], " dmg in 30 s")
		phase = "w"
		boss.take_damage(99999999, p)
	if k == 2100:
		phase = "2"
	if k == 3900:
		print("phase 2: hero took ", dmg["2"], " dmg in 30 s")
		return true
	return false
