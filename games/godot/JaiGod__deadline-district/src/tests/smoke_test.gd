extends Node
## Headless smoke test: boots the game, plays every map through several waves (incl. a boss), uses every weapon.
var main
func _ready() -> void:
	_run.call_deferred()
func _f(n: int) -> void:
	for i in n: await get_tree().process_frame
func _run() -> void:
	main = load("res://scenes/Main.tscn").instantiate()
	add_child(main)
	await _f(30)
	for screen in ["how", "maps", "title"]:
		main.show_screen(screen); await _f(5)
	for mi in 3:
		main.start_game(mi)
		var w = main.world
		w.cash = 99999
		for wd in Data.WEAPONS:
			w.give_weapon(wd.id)
		for p in Data.PERKS:
			w.apply_perk(p.id)
		w.place("bar"); w.place("tur")
		main.open_shop(); await _f(3)
		for t in ["weapons", "defense", "perks"]:
			main.shop_tab = t; main.show_screen("shop"); await _f(2)
		main.show_screen("play")
		w.wave = 4
		w.ready_up()
		var frames = 0
		while w.wave <= 6 and frames < 9000 and w.alive:
			w.hp = w.mhp
			main.mouse_held = true; w.mouse_aim = false
			w.cur = (frames / 90) % w.order.size()
			var tgt = null
			for z in w.zs:
				tgt = z; break
			if tgt: w.aim = (tgt.p - w.pp).angle()
			if w.state == "intermission": w.ready_up()
			frames += 1
			await get_tree().process_frame
		print("[smoke] map %d reached wave %d kills %d frames %d zs %d" % [mi, w.wave, w.kills, frames, w.zs.size()])
	main.show_screen("pause"); await _f(3)
	main.show_screen("over"); await _f(3)
	main.show_screen("won"); await _f(3)
	print("[smoke] OK")
	get_tree().quit()
