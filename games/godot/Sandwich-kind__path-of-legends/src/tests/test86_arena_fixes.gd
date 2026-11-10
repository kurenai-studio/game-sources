extends SceneTree
# Проверки правок Арены: тотемы Энта (1 → 3 → 4, стоят на месте), отражения Ириды
# (не больше 2), призванные осколки не раскалываются, помощь в прицеливании по мелким.
var main
var f := 0
var arena
var phase := 0
var t0 := 0
var shots := "/tmp/claude-0/st/"
var log_imgs := 0
var tot_y := {}
func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)
func start(w: int, hero: int) -> void:
	t0 = f
	main.sel = [hero, 0]
	main.start_arena(false, w)
	arena = null
	for n in main.world.get_children():
		if n is ArenaMode: arena = n
func totems() -> Array:
	return arena._totems.filter(func(t): return is_instance_valid(t) and t.is_alive())
func shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(shots + n + ".png")
func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		phase = int(OS.get_environment("PHASE")) if OS.get_environment("PHASE") != "" else 0
		start([20, 40, 36][phase], [7, 10, 5][phase])
	if arena == null: return false
	var lt := f - t0
	for p in arena.players:
		p._protect = 5.0
		p.hp = p.max_hp
	var b = arena._boss
	match phase:
		0:   # Энт
			if lt == 60 * 12:
				print("treant: totems=", totems().size(), " inv=", b.invulnerable)
				for t in totems(): tot_y[t] = t.global_position.y
				shot("fix_totem1")
			if lt == 60 * 18:
				for t in totems(): print("  totem dy after 6s = ", t.global_position.y - tot_y[t])
				for t in totems(): t.take_damage(99999)
			if lt == 60 * 19:
				print("after break: inv=", b.invulnerable)
				b.hp = int(b.max_hp * 0.6)
			if lt == 60 * 20:
				print("wave2: totems=", totems().size(), " inv=", b.invulnerable)
				for t in totems(): tot_y[t] = t.global_position.y
				shot("fix_totem3")
			if lt == 60 * 26:
				for t in totems(): print("  totem dy = ", t.global_position.y - tot_y[t], " x=", int(t.global_position.x))
				for t in totems(): t.take_damage(99999)
			if lt == 60 * 27:
				b.hp = int(b.max_hp * 0.3)
			if lt == 60 * 28:
				print("wave3: totems=", totems().size(), " inv=", b.invulnerable, " xs=", totems().map(func(t): return int(t.global_position.x)))
				shot("fix_totem4")
				for t in totems(): t.take_damage(99999)
			if lt == 60 * 29:
				b.hp = int(b.max_hp * 0.1)
			if lt == 60 * 31:
				print("end: totems=", totems().size(), " inv=", b.invulnerable, " wave=", arena._totem_wave)
				phase = 1
				start(40, 10)
		1:   # Ирида
			if b and is_instance_valid(b):
				var imgs := 0
				for n in main.world.get_children():
					if n is Player and n.is_alive() and n.get_meta("kind", "") == "irida_image": imgs += 1
				log_imgs = maxi(log_imgs, imgs)
				if lt % 600 == 0:
					var sh := 0
					for n in main.world.get_children():
						if n is Player and n.is_alive() and String(n.get_meta("kind", "")).begins_with("shardling"): sh += 1
					print("irida t=", lt / 60, " images=", imgs, " max=", log_imgs, " shardlings=", sh, " alive=", arena._alive.size())
			if lt == 60 * 70:
				phase = 2
				start(36, 7)
		2:   # мелкие враги и помощь в прицеливании (Солдат)
			if lt == 60 * 6:
				arena._queue.clear()
				for n in arena._alive.duplicate():
					if is_instance_valid(n): n.take_damage(99999)
				var p: Player = arena.players[0]
				for n in main.world.get_children():
					if n is Destructible and n.global_position.x > 700 and n.global_position.x < 1500:
						n.queue_free()          # убрать всё между героем и целью
				p.global_position = Vector2(900, 880)
				p.facing = 1
				var tiny = arena.spawn_at(OS.get_environment("TINY") if OS.get_environment("TINY") != "" else "shardling_xs", Vector2(1300, 900))
				tiny.set_meta("no_split", true)
				tiny.speed = 0.0
				tiny.bot_abilities = {}
				print("tiny hp=", tiny.hp, " body=", tiny.body_size, " hurt_center_dy=", tiny.hurt_center().y - tiny.global_position.y)
				set_meta("tiny", tiny)
			if lt > 60 * 7 and lt < 60 * 10:
				arena.players[0].facing = 1
				if lt % 40 < 28: Input.action_press("p1_shoot")
				else: Input.action_release("p1_shoot")
			if lt == 60 * 10:
				Input.action_release("p1_shoot")
				var tiny = get_meta("tiny")
				print("tiny after 3s of rifle: alive=", is_instance_valid(tiny) and tiny.is_alive(), " hp=", tiny.hp if is_instance_valid(tiny) else -1)
				shot("fix_tiny")
				return true
	return false
