extends SceneTree
# Арена: допрыгивание до платформ и уступов, шустрик, баффы, МЕГА-способности
var main
var f := 0
var arena: ArenaMode
var p: Player
var held := {}
var mark := {}

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func press(a: String, n: int) -> void:
	Input.action_press(a)
	held[a] = f + n

func count(cls) -> int:
	var c := 0
	for n in main.world.get_children():
		if is_instance_of(n, cls):
			c += 1
	return c

func _physics_process(_d: float) -> bool:
	f += 1
	for a in held.keys():
		if f >= held[a]:
			Input.action_release(a)
			held.erase(a)
	match f:
		3:
			main.sel = [0, 0]
			main.start_arena()
			for n in main.world.get_children():
				if n is ArenaMode: arena = n
			arena._queue.clear()
		10:
			p = arena.player
			arena.wave = 99           # волны не идут, бой не начинается
		# --- лестница: прыжки по башне в центре до алтаря (4 яруса)
		200:
			p.frozen = false
			arena._state = "test"
			p.position = Vector2(1300, 905)
		205: press("p1_jump", 3)
		260: press("p1_jump", 3)
		315: press("p1_jump", 3)
		370: press("p1_jump", 3)
		430:
			print("TEST climb center tower: player y=", int(p.position.y), " (уступ 4-го яруса: ~", int(Colosseum.FLOOR_Y - 480 - 31), ")")
		# --- шустрик: не встаёт на голову, урон умеренный
		440:
			p.position = Vector2(700, 905)
			p.hp = p.max_hp
			var r := Bots.create("runner", 3, Vector2(700, 600), p, Colosseum.W)
			main.world.add_child(r)
			arena._alive.append(r)
			mark["runner"] = r
		740:
			var r: Player = mark["runner"]
			print("TEST runner 5s: runner y=", int(r.position.y), " player y=", int(p.position.y),
					" player hp ", p.hp, "/", p.max_hp)
			r.take_damage(999, p)
		# --- баффы
		750:
			p.hp = p.max_hp
			print("buff rapid first -> mega? ", p.add_buff("rapid"), " second -> mega? ", p.add_buff("rapid"))
			p.facing = 1
			mark["b0"] = count(Bullet)
			press("p1_shoot", 60)
		811:
			print("TEST MEGA rapid: bullets fired in 1s=", count(Bullet) - mark["b0"], " ammo=", p.ammo, "/", p.clip_size)
		820:
			p.buffs.clear()
			p.add_buff("damage")
			var dummy := Bots.create("tank", 1, Vector2(900, 880), p, Colosseum.W)
			dummy.frozen = true
			main.world.add_child(dummy)
			mark["dummy"] = dummy
		825:
			var d: Player = mark["dummy"]
			var h0 := d.hp
			d.take_damage(10, p)
			print("TEST damage buff: 10 -> ", h0 - d.hp, " (ждём 15)")
			p.add_buff("damage")
			h0 = d.hp
			d.take_damage(10, p)
			print("TEST MEGA damage: 10 -> ", h0 - d.hp, " (ждём 25)")
			p.buffs.clear()
			p.add_buff("armor")
			var h1 := p.hp
			p.take_damage(20, d)
			print("TEST armor: 20 -> ", h1 - p.hp, " (ждём 10)")
			p.add_buff("armor")
			h1 = p.hp
			p.take_damage(20, d)
			print("TEST MEGA armor: 20 -> ", h1 - p.hp, " (ждём 0)")
			d.queue_free()
		# --- МЕГА-способности TESTIK_1
		840:
			p.buffs.clear()
			p.add_buff("cooldown")
			p.add_buff("cooldown")
			p._cd = [0.0, 0.0, 0.0]
			p.position = Vector2(1000, 905)
			p.facing = 1
			mark["g0"] = count(Grenade)
			press("p1_a1", 30)
		875:
			print("TEST MEGA grenade: grenades thrown=", count(Grenade) - mark["g0"], " (ждём 3)")
		940:
			print("   minis in air after split=", count(Grenade), " (ждём до 15)")
		1000:
			# МЕГА-рывок сквозь колонну
			p.position = Vector2(700, 905)
			p.facing = 1
			Maps.add_column(main.world, Rect2(820, Colosseum.FLOOR_Y - 300, 40, 300))
			p._cd = [0.0, 0.0, 0.0]
		1005: press("p1_a2", 2)
		1006: press("p1_right", 60)
		1080:
			print("TEST MEGA dash through column: x=", int(p.position.x), " (колонна на 820..860, ждём > 860), protect=", snappedf(p._protect, 0.1), " jump boost=", snappedf(p._jump_boost_t, 0.1))
		1090:
			p._cd = [0.0, 0.0, 0.0]
			mark["s0"] = 0
		1091: press("p1_a3", 2)
		1150:
			print("TEST MEGA leap: hovering=", p._hover_t > 0.0, " y=", int(p.position.y), " shurikens now=", count(Shuriken))
		1250:
			p.ult_charge = p.ult_need
			press("p1_ult", 2)
		1260: press("p1_shoot", 60)
		1320:
			print("TEST MEGA minigun: bullets=", count(Bullet))
		1400:
			print("ALL DONE")
			return true
	return false
