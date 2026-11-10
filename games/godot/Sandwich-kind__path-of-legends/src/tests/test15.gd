extends SceneTree
# Раунды, возрождение, парашют, деревья, задние стены
var main
var f := 0
var t0 := 0
var spawns: Array = []
var sky_count := 0

func _initialize() -> void:
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func ps() -> Array:
	var r := []
	for n in main.world.get_children():
		if n is Player:
			r.append(n)
	return r

func trees() -> Array:
	var r := []
	for n in main.world.get_children():
		if n is Destructible and n.background and not n.ghost:
			r.append(n)
	return r

func backwalls() -> Array:
	var r := []
	for n in main.world.get_children():
		if n is Destructible and n.ghost:
			r.append(n)
	return r

func _physics_process(_d: float) -> bool:
	f += 1
	match f:
		3:
			main.sel = [0, 1]
			main._on_map_chosen("two_houses", 2, 2)
			main._start_game()
		10:
			print("round=", main.round_num, " frozen=", ps()[0].frozen, " round_over=", main.round_over,
					" trees=", trees().size(), " backwalls=", backwalls().size())
		200:
			print("after countdown: frozen=", ps()[0].frozen, " round_over=", main.round_over)
		# --- убийство 1
		205:
			ps()[1].take_damage(999, ps()[0])
		206:
			print("kills=", main.kills, " text ok")
		# --- статистика возрождений игрока 2
		330:
			var p: Player = ps()[1]
			print("respawned p2 at ", p.position.round(), " para=", p._para, " kind=", p.last_spawn_kind)
		# --- 40 возрождений подряд: где появляется
		340:
			var p: Player = ps()[1]
			for k in 40:
				var r: Dictionary = main._pick_spawn(p)
				spawns.append(r["pos"])
				if r["parachute"]:
					sky_count += 1
			var left := 0
			var xs := []
			for s in spawns:
				if s.x < 2000:
					left += 1
				xs.append(int(s.x))
			xs.sort()
			print("40 spawns of p2: on wrong half=", left, " sky=", sky_count, " x range ", xs[0], "..", xs[-1])
			var ys := {}
			for s in spawns:
				ys[int(s.y / 100) * 100] = true
			print("   heights used (y/100): ", ys.keys())
		# --- парашют: принудительно в небо
		350:
			var p: Player = ps()[0]
			p.position = map_sky(0)
			p.velocity = Vector2.ZERO
			p._para = 1
			t0 = f
		351, 400, 440, 480, 520, 560:
			var p: Player = ps()[0]
			print("  para f", f - t0, " y=", int(p.position.y), " vy=", int(p.velocity.y), " state=", p._para)
		900:
			var lying2 := 0
			for n in main.world.get_children():
				if n is Node2D and not (n is CollisionObject2D) and n.z_index == -1 and n.get_child_count() >= 2 and n.modulate.a > 0.9:
					lying2 += 1
			print("canopy still lying 5 s later=", lying2)
		600:
			var lying := 0
			for n in main.world.get_children():
				if n is Node2D and not (n is CollisionObject2D) and n.z_index == -1 and n.get_child_count() >= 2 and n.modulate.a > 0.9:
					lying += 1
			print("parachute after landing: state=", ps()[0]._para, " canopy lying on ground=", lying)
		# --- гранатa поджигает дерево
		610:
			var tr: Destructible = trees()[0]
			print("tree at ", tr.global_position.round(), " cells=", tr.cells.size())
			var g := Grenade.new()
			g.team = 0
			g.attacker = ps()[0]
			g.position = tr.global_position + Vector2(0, 170)
			main.world.add_child(g)
		611:
			for n in main.world.get_children():
				if n is Grenade:
					n.linear_velocity = Vector2.ZERO
		900:
			var tr: Destructible = trees()[0]
			var pieces := 0
			for n in main.world.get_children():
				if n is Destructible and not n.background and n.flammable:
					pieces += 1
			print("TEST tree after grenade+fire: anchored tree cells=", tr.cells.size(),
					" burning=", tr._burning.size(), " fallen tangible pieces=", pieces)
		# --- тяжёлый снаряд сквозь задние стены и деревья
		910:
			var p: Player = ps()[1]
			p.position = Vector2(3950 - 300, 1215)
			p.facing = -1
			var bw: Destructible = backwalls()[1]
			print("backwall2 cells before=", bw.cells.size())
			p._fire_shell()
		1050:
			var bw: Destructible = backwalls()[1]
			print("TEST shell vs back wall: cells after=", bw.cells.size())
		# --- раунд 1 до 2 убийств
		1060:
			ps()[1].take_damage(999, ps()[0])
		1065:
			print("after 2nd kill: round_wins=", main.round_wins, " round_over=", main.round_over)
		1250:
			print("new round=", main.round_num, " kills=", main.kills, " trees=", trees().size())
		1420:
			ps()[1].take_damage(999, ps()[0])
		1600:
			ps()[1].take_damage(999, ps()[0])
		1720:
			var ended := false
			for n in main.world.get_children():
				if n is MatchEnd:
					ended = true
			print("match end screen=", ended, " round_wins=", main.round_wins)
			print("ALL DONE")
			return true
	return false

func map_sky(team: int) -> Vector2:
	return main.map_info["sky"][team]
