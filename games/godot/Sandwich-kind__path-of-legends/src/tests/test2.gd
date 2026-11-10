extends SceneTree

var main
var f := 0
var p1
var p2
var shield
var hp_before := 0
var cells_before := 0

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func destr_cells() -> int:
	var c := 0
	for n in main.world.get_children():
		if n.has_method("hit"):
			c += n.cells.size()
	return c

func ps() -> Array:
	var r := []
	for n in main.world.get_children():
		if n.has_method("take_damage"):
			r.append(n)
	return r

func clear_level() -> void:
	for n in main.world.get_children():
		if n.has_method("hit") or n.has_method("vanish"):
			n.queue_free()

func _physics_process(_delta: float) -> bool:
	f += 1
	match f:
		3:
			main.sel = [0, 1]
			main.start_duel()
		5:
			clear_level()
			var a := ps()
			p1 = a[0]
			p2 = a[1]
			p1.position = Vector2(300, 570)
			p2.position = Vector2(700, 570)
			p1.facing = 1
			p2.facing = -1
			p2._update_eye()
		10:
			# щит игрока 2 между ними
			p2._place_shield()
			shield = p2._shield
			print("shield pos=", shield.position, " team=", shield.shield_team, " color=", shield.color)
		15:
			# игрок 2 стреляет сквозь свой щит
			hp_before = p1.hp
			cells_before = shield.cells.size()
			p2._shoot_bullet(900.0, 10, 0.0, 8.0, 0.0)
		60:
			print("TEST own bullet through shield: p1 hp ", hp_before, " -> ", p1.hp,
					" | shield cells ", cells_before, " -> ", shield.cells.size())
		65:
			hp_before = p2.hp
			p1._shoot_bullet(900.0, 30, 0.0, 8.0, 0.0)
		110:
			var sc = shield.cells.size() if is_instance_valid(shield) else -1
			print("TEST enemy bullet vs shield: p2 hp ", hp_before, " -> ", p2.hp, " | shield cells -> ", sc)
		115:
			# массивный снаряд сквозь 8 ящиков
			if is_instance_valid(shield):
				shield.queue_free()
			p2.position = Vector2(1100, 300)
			for k in 8:
				Maps.add_crate(main.world, Vector2(380 + k * 70, 569))
		125:
			print("crates=", _count_destr())
			p1._fire_shell()
		260:
			print("TEST shell vs 8 crates: crates still with cells > 12: ", _count_full())
			clear_level()
		265:
			for k in 4:
				Maps.add_column(main.world, Rect2(420 + k * 120, 440, 40, 160))
		275:
			p1._fire_shell()
		420:
			var dmg_cols := 0
			var untouched := 0
			for n in main.world.get_children():
				if n.has_method("hit") and n.anchored:
					if n.cells.size() < 16:
						dmg_cols += 1
					else:
						untouched += 1
			print("TEST shell vs 4 columns: damaged=", dmg_cols, " untouched=", untouched)
			clear_level()
		430:
			# сюрикены сквозь ящики
			for k in 4:
				Maps.add_crate(main.world, Vector2(400 + k * 62, 569))
			p1.position = Vector2(330, 470)
		440:
			p1._throw_shurikens()
		520:
			var cnt := 0
			for n in main.world.get_children():
				if n.has_method("hit"):
					cnt += 1
			print("TEST shurikens: destructible pieces=", cnt, " cells left=", destr_cells(), " of 64")
			clear_level()
		530:
			# залп: проходит сквозь платформу над головой в фазе призрака
			Maps.add_platform(main.world, Rect2(200, 420, 260, 20))
			p2.position = Vector2(330, 570)
			p2.facing = 1
			p1.position = Vector2(1000, 570)
			hp_before = p1.hp
		540:
			cells_before = destr_cells()
			p2._barrage()
		700:
			print("TEST barrage: platform cells overhead ", cells_before, " -> ", destr_cells(),
					" (should stay ~13), mortars exploded somewhere right")
			clear_level()
		710:
			# ульта: взрывы из-под земли
			p2.position = Vector2(150, 570)
			p2.facing = 1
			p1.position = Vector2(700, 570)
			p1.hp = 100
			for k in 6:
				Maps.add_crate(main.world, Vector2(250 + k * 150, 569))
			hp_before = p1.hp
		720:
			cells_before = destr_cells()
			p2.ult_charge = p2.ult_need
			p2._start_ult()
		900:
			print("TEST quake: p1 hp ", hp_before, " -> ", p1.hp, " | crate cells ", cells_before,
					" -> ", destr_cells())
		905:
			print("Fragment.all size=", Fragment.all.size())
			print("ALL DONE")
			return true
	return false

func _count_destr() -> int:
	var c := 0
	for n in main.world.get_children():
		if n.has_method("hit"):
			c += 1
	return c

func _count_full() -> int:
	var c := 0
	for n in main.world.get_children():
		if n.has_method("hit") and n.cells.size() > 12:
			c += 1
	return c
