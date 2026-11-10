extends SceneTree
# Механики локаций Арены: лианы, камнепад, шипы, ящики с порохом, батуты,
# катапульты, домик на дереве, корни-ловушки, трясина, газ, тонущие брёвна.
var main
var f := 0
var arena
var p: Player
var cases := [] if OS.get_environment("ONLY") != "" else [
	["forest", 1], ["vine", 11], ["rock", 21], ["spike", 26], ["tnt", 31], ["pad", 36],
	["catapult", 41], ["roots", 51], ["swamp", 56]]
var ci := -1
var t0 := 0
var st := {}
var shots := "/tmp/claude-0/st/"

func _init() -> void:
	if OS.get_environment("ONLY") != "":
		var parts := OS.get_environment("ONLY").split(",")
		cases = [[parts[0], int(parts[1])]]

func _initialize() -> void:
	Save.load_game()
	Save.unlock_all_heroes()
	Save.unlock_all_stages()
	main = load("res://main.tscn").instantiate()
	root.add_child(main)

func find_all(cls) -> Array:
	var res: Array = []
	for n in main.world.get_children():
		if is_instance_of(n, cls):
			res.append(n)
	return res

func _next() -> void:
	ci += 1
	t0 = f
	st = {}
	main.sel = [0, 0]
	main.start_arena(false, cases[ci][1])
	arena = null
	for n in main.world.get_children():
		if n is ArenaMode: arena = n

func shot(n: String) -> void:
	root.get_viewport().get_texture().get_image().save_png(shots + n + ".png")

func put(pos: Vector2) -> void:
	p.global_position = pos
	p.velocity = Vector2.ZERO

func _physics_process(_d: float) -> bool:
	f += 1
	if f == 3:
		_next()
	if arena == null:
		return false
	var lt := f - t0
	if lt < 200 or arena._state != "fight" or arena.players[0].frozen:
		if not st.has("ready"):
			return false                     # подъёмник, начало волны
	if not st.has("ready"):
		st["ready"] = f
	lt = f - st["ready"] + 200
	p = arena.players[0]
	p._protect = 0.0
	# врагов не выпускаем: волна «висит», можно спокойно щупать механики
	arena._queue = ["ghoul"]
	arena._spawn_t = 999.0
	for b in arena._alive.duplicate():
		if is_instance_valid(b) and b.is_alive():
			b.take_damage(99999, p)
	var c: String = cases[ci][0]
	var k := lt - 200
	match c:
		"forest":
			if k == 1:
				var sp: Array = arena.info["spawners"]
				var best = null
				for s in sp:
					if s.mega_chance > 0.0:
						best = s
				st["sp"] = best
				print("forest: highest spawner at ", best.global_position, " mega_chance=", best.mega_chance)
				put(best.global_position + Vector2(0, -60))
			if k == 60:
				print("forest: standing in treehouse? floor=", p.is_on_floor(), " pos=", p.global_position)
				shot("m_forest")
		"vine":
			var vines := find_all(ClimbVine)
			if k == 1:
				print("vine: count=", vines.size())
				var v: ClimbVine = vines[0]
				for vv in vines:
					if vv.length > v.length: v = vv
				st["v"] = v
				put(v.global_position + Vector2(0, v.length * 0.5))
				st["y0"] = p.global_position.y
			if k > 1 and k < 50:
				Input.action_press("p1_jump")
				if k % 8 == 0:
					var v: ClimbVine = st["v"]
					print("   vine dbg k=", k, " pos=", p.global_position, " vel=", p.velocity, " held=", v._held.has(p), " floor=", p.is_on_floor(), " rel=", p.global_position - v.global_position, " frozen=", p.frozen, " forced=", p._forced_time)
			if k == 50:
				Input.action_release("p1_jump")
				print("vine: climbed ", st["y0"] - p.global_position.y, " px up")
				st["y1"] = p.global_position.y
			if k == 80:
				print("vine: after hanging 0.5s dy=", p.global_position.y - st["y1"], " (small = hangs)")
				shot("m_vine")
		"rock":
			if k == 1:
				st["hp"] = p.hp
				put(arena.info["center"])
			for n in main.world.get_children():
				if n is Rockfall.FallingRock:
					if not st.has("seen"): st["seen"] = {}
					st["seen"][n.get_instance_id()] = true
			st["rocks"] = st.get("seen", {}).size()
			if k == 400:
				shot("m_rock")
			if k == 500:
				st["hp2"] = p.hp
				var rf: Rockfall = find_all(Rockfall)[0]
				var space := rf.get_world_2d().direct_space_state
				var fx := 300.0
				for xx in range(200, 2400, 40):
					var hit := space.intersect_ray(PhysicsRayQueryParameters2D.create(Vector2(xx, rf.ceiling + 40.0), Vector2(xx, rf.floor_y + 20.0), Layer.WORLD | Layer.FRAME))
					if not hit.is_empty() and hit["position"].y >= rf.floor_y - 30.0:
						fx = xx
						break
				st["fx"] = fx
				put(Vector2(fx, arena.info["floor"] - p.body_size.y / 2 - 2))
				rf._drop(fx)
			if k > 500 and k < 700:
				p.velocity.x = 0.0
				p.global_position.x = st["fx"]
			if k == 700:
				print("rock: direct drop on hero — hp lost ", st["hp2"] - p.hp, " stunned=", p.is_stunned())
			if k == 900:
				print("rock: hp lost ", st["hp"] - p.hp, ", rock sightings ", st.get("rocks", 0), ", rockfalls=", find_all(Rockfall).size())
		"spike":
			var traps := find_all(SpikeTrap)
			if k == 1:
				print("spike: traps=", traps.size())
				st["hp"] = p.hp
				st["tr"] = traps[0]
			if k >= 1 and k < 400:
				var tr: SpikeTrap = st["tr"]
				if tr._state != "up":
					put(tr.global_position + Vector2(0, -p.body_size.y / 2 - 2))
				else:
					st["vy"] = minf(st.get("vy", 0.0), p.velocity.y)
			if k == 400:
				print("spike: hp lost ", st["hp"] - p.hp, " launch vy=", st.get("vy", 0))
				shot("m_spike")
		"tnt":
			var tnts := find_all(TntCrate)
			if k == 1:
				print("tnt: crates=", tnts.size())
				st["n"] = tnts.size()
				st["hp"] = p.hp
				var t: TntCrate = tnts[0]
				put(t.global_position + Vector2(-110, -10))
				Util.explode(main.world, t.global_position + Vector2(0, -40), 50.0, 5, 40, 0, p, false)
			if k == 15:
				shot("m_tnt")
			if k == 120:
				print("tnt: crates left ", find_all(TntCrate).filter(func(x): return not x._boom).size(), " of ", st["n"], ", hero hp lost ", st["hp"] - p.hp)
		"pad":
			var pads := find_all(BouncePad)
			if k == 1:
				print("pad: pads=", pads.size())
				put(pads[0].global_position + Vector2(0, -14 - p.body_size.y / 2 - 4))
				st["min"] = 99999.0
			if k > 1:
				st["min"] = minf(st["min"], p.global_position.y)
			if k == 40:
				shot("m_pad")
			if k == 30:
				print("pad: hero at ", p.global_position, " floor=", p.is_on_floor(), " pad ", pads[0].global_position, " feet ", p.global_position.y + p.body_size.y / 2)
			if k == 120:
				print("pad: highest point ", pads[0].global_position.y - st["min"] - p.body_size.y / 2, " px above pad (feet)")
		"catapult":
			var cats := find_all(Catapult)
			if k == 1:
				print("catapult: count=", cats.size())
				var ca: Catapult = cats[0]
				st["ca"] = ca
				put(ca.global_position + Vector2(0, -p.body_size.y / 2 - 4))
			if k == 45:
				shot("m_catapult")
			if k == 200:
				var ca: Catapult = st["ca"]
				print("catapult: landed at ", p.global_position, " target ", ca.target, " dist ", p.global_position.distance_to(ca.target))
		"roots":
			var rts := find_all(RootTrap)
			if k == 1:
				print("roots: traps=", rts.size())
				put(rts[0].global_position + Vector2(0, -p.body_size.y / 2 - 2))
			if k == 30:
				print("roots: rooted=", p._root_t > 0.0, " t=", p._root_t)
				shot("m_roots")
		"swamp":
			var puds: Array = []
			var logs: Array = []
			var vents: Array = []
			for n in main.world.get_children():
				if n is SwampBits.MudPuddle: puds.append(n)
				if n is SwampBits.SinkingLog: logs.append(n)
				if n is SwampBits.GasVent: vents.append(n)
			if k == 1:
				print("swamp: puddles=", puds.size(), " logs=", logs.size(), " vents=", vents.size())
				put(puds[0].global_position + Vector2(0, -p.body_size.y / 2 - 6))
			if k > 20 and k < 80:
				Input.action_press("p1_right")
			if k == 40:
				shot("m_swamp_mud")
			if k == 80:
				Input.action_release("p1_right")
				print("swamp: speed in mud ", absf(p.velocity.x), " slow_t=", p._slow_t)
				var lg = logs[0]
				st["lg"] = lg
				st["ly"] = lg.position.y
				put(lg.global_position + Vector2(0, -10 - p.body_size.y / 2 - 2))
			if k == 200:
				print("swamp: log sank ", st["lg"].position.y - st["ly"], " px under rider")
				shot("m_swamp")
				var v = vents[0]
				v._state = "idle"
				v._t = 0.01
				st["hp"] = p.hp
				put(v.global_position + Vector2(0, -p.body_size.y / 2 - 2))
			if k > 200 and k < 300:
				p.velocity.x = 0.0
			if k == 300:
				print("swamp: gas vent hp lost ", st["hp"] - p.hp)
	var limits := {"forest": 80, "vine": 100, "rock": 920, "spike": 420, "tnt": 140, "pad": 140, "catapult": 220, "roots": 50, "swamp": 320}
	if k >= limits[c]:
		if ci + 1 >= cases.size():
			print("DONE")
			return true
		_next()
	return false
