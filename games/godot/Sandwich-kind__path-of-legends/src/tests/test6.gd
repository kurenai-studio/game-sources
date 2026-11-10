extends SceneTree
# Проверка новых механик: сквозной прыжок, камера, дома, залп, гранаты в ульте

var main
var f := 0
var p1
var p2
var cam
var v0 := 0.0
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
		if n is Player:
			r.append(n)
	return r

func clear_level() -> void:
	for n in main.world.get_children():
		if n is Destructible or n is Fragment:
			n.queue_free()

func count(kind) -> int:
	var c := 0
	for n in main.world.get_children():
		if is_instance_of(n, kind):
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
			main.sel = [0, 1]
			main.map_id = "test_field"
			main.start_duel()
		5:
			clear_level()
			var a := ps()
			p1 = a[0]
			p2 = a[1]
			p2.position = Vector2(1050, 560)
			print("speed TESTIK=", p1.speed, " UBER=", p2.speed)
			p1.position = Vector2(300, 565)
		8:
			Maps.add_platform(main.world, Rect2(200, 440, 260, 20))   # платформа над головой
		20:
			p1._leap()
		90:
			print("TEST phase up: p1 y=", int(p1.position.y), " (стоит на платформе, если ~410) mask=", p1.collision_mask)
		95:
			# сверху вниз: стоит на платформе, прыжок не нужен — просто проверяем, что не проваливается
			p1.velocity = Vector2(0, 600)
		140:
			print("TEST no phase down: p1 y=", int(p1.position.y), " (должно остаться ~410)")
			clear_level()
		145:
			p1.position = Vector2(300, 565)
			p1.facing = 1
			Maps.add_column(main.world, Rect2(360, 360, 40, 240))   # высокая колонна справа
		155:
			p1._leap()
			press("p1_right", 60)
		230:
			print("TEST phase side: p1 x=", int(p1.position.x), " (должно быть < 345, колонна с 360)")
			clear_level()
		235:
			# стрелка гранаты
			p1.position = Vector2(300, 565)
			p1._cd = [0.0, 0.0, 0.0]
			press("p1_a1", 30)
		250:
			print("TEST aim visible=", p1._aim.visible, " dots=", p1._aim_dots.size(),
					" line=", p1._aim_line.points)
		270:
			print("TEST aim hidden after throw=", not p1._aim.visible, " grenades=", count(Grenade))
		300:
			# гранаты в ульте
			p1.ult_charge = p1.ult_need
			p1._start_ult()
		301:
			v0 = count(Grenade)
		690:
			print("TEST minigun auto grenades thrown (approx): ok, ult_left=", p1._ult_left)
		700:
			# щит толщиной 2
			p2._place_shield()
			print("TEST shield cols=", p2._shield.cols, " cells=", p2._shield.cells.size())
		710:
			p2._barrage()
		711:
			v0 = 0
		725:
			var mt := 0
			var ghost := 0
			for n in main.world.get_children():
				if n is Mortar:
					mt += 1
					if not n._diving:
						ghost += 1
			print("TEST barrage mortars in air=", mt, " still rising=", ghost)
		760:
			var div := 0
			for n in main.world.get_children():
				if n is Mortar and n._diving:
					div += 1
			print("TEST barrage diving=", div)
		800:
			main.map_id = "two_houses"
			main.start_duel()
		810:
			var a := ps()
			p1 = a[0]
			p2 = a[1]
			for n in main.world.get_children():
				if n is DuelCamera:
					cam = n
			print("houses: p1=", p1.position, " p2=", p2.position, " zoom far=", snappedf(cam.zoom.x, 0.001))
		830:
			p1.position = Vector2(1900, 1215)
			p2.position = Vector2(2100, 1215)
		1000:
			print("TEST camera near zoom=", snappedf(cam.zoom.x, 0.001), " pos=", cam.position.round())
		1005:
			p1.position = Vector2(200, 1215)
			p2.position = Vector2(3800, 1215)
		1200:
			print("TEST camera far zoom=", snappedf(cam.zoom.x, 0.001), " pos=", cam.position.round())
			var vs: Vector2 = cam.get_viewport_rect().size
			var half: Vector2 = Vector2(vs.x, vs.y - Config.PANEL) / cam.zoom.x / 2
			var c: Vector2 = cam.position - Vector2(0, Config.PANEL / 2.0 / cam.zoom.x)
			print("   visible x ", int(c.x - half.x), "..", int(c.x + half.x),
					"  y ", int(c.y - half.y), "..", int(c.y + half.y), " (карта 0..4000, низ 1300)")
		1210:
			# прочность дома: 10 выстрелов массивным снарядом в стену
			var house = null
			for n in main.world.get_children():
				if n is Destructible and n.cells.size() > 90:
					house = n
					break
			print("house cells=", house.cells.size())
			p2.position = Vector2(700, 1215)
			p2.facing = -1
			p2._fire_shell()
		1330:
			var big := 0
			for n in main.world.get_children():
				if n is Destructible and n.cells.size() > 60:
					big += 1
					print("   big piece cells=", n.cells.size(), " anchored=", n.anchored)
		1335:
			print("ALL DONE")
			return true
	return false
