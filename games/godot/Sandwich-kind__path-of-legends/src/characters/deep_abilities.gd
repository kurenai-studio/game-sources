class_name DeepAbilities
# ---------- Способности противников Драгоценных и Кристальных пещер ----------
# Вызываются из Player._bot_try для способностей, которых нет у старых ботов.
# Возвращает true, если способность применена (тогда начинается перезарядка).

static func brain(p: Player) -> DeepBrain:
	return p.get_node_or_null("DeepBrain") as DeepBrain

static func try(p: Player, ab: String, to: Vector2) -> bool:
	var d := absf(to.x)
	var world := p.get_parent()
	match ab:
		"roll":                    # самоцветный жук сворачивается и катится
			var b := brain(p)
			if b and d < 650.0 and p.is_on_floor():
				b.start_roll()
				return true
		"gem_shield":              # Гранильщик покрывает своих самоцветной коркой
			if not p.allies.is_valid():
				return false
			var any := false
			for a in p.allies.call():
				if is_instance_valid(a) and a.is_alive() and a.crust <= 0.0 \
						and a.global_position.distance_to(p.global_position) < 460.0:
					a.give_crust(30.0, 9.0)
					Fx.sparks(world, a.global_position, Color(0.4, 1.0, 0.6), 8, 140.0, 3.0)
					any = true
			if any:
				p._anim("cast")
				Fx.ring(world, p.global_position, 120.0, Color(0.4, 1.0, 0.6, 0.8), 0.45, 5.0)
			return any
		"beam":                    # призматик: линия прицела, потом луч
			if to.length() < 1300.0:
				_beam(p, 0.85, 16, Color(1.0, 0.95, 0.75), 1, 0.0)
				return true
		"resonate":                # резонатор гудит: ломает кристаллы, оглушает рядом
			if to.length() < 420.0:
				p._anim("cast")
				var rg = p.rig
				if rg is DeepRig:
					rg.buzzing = 1.0
				Fx.ring(world, p.global_position, 150.0, Color(0.75, 0.6, 1.0, 0.5), 0.5, 3.0)
				p._after(0.55, _resonate.bind(p))
				return true
		"dust":                    # хрустальная моль сыплет пыльцу
			if to.length() < 500.0:
				var dc := DustCloud.new()
				dc.team = p.team
				dc.position = p.global_position + Vector2(0, 30)
				world.add_child(dc)
				return true
		"dynamite_bundle":         # Барон бросает связку динамита
			if to.length() < 1000.0:
				p._anim("throw")
				for k in 3:
					p._after(0.12 + k * 0.18, p._release_spear.bind("dynamite", (k - 1) * 130.0))
				return true
		"cart_call":               # Барон свистит — с обеих сторон несутся вагонетки
			p._anim("roar")
			var fy := p.global_position.y + p.body_size.y / 2
			for side in [-1.0, 1.0]:
				var rc := RunawayCart.new()
				rc.dir = -side
				rc.team = p.team
				rc.attacker = p
				rc.floor_y = fy
				rc.position = Vector2(Colosseum.W / 2 + side * (Colosseum.W / 2 - 110.0), 0)
				p._after(0.6, func():
					if is_instance_valid(world):
						world.add_child(rc))
			return true
		"burrow":
			var b2 := brain(p)
			if b2 and p.is_on_floor() and is_instance_valid(p.target):
				b2.start_burrow()
				return true
		"rainbow_beam":            # Ирида: три радужных луча
			if to.length() < 1500.0:
				var real: bool = p.get_meta("kind", "") == "irida"
				_beam(p, 1.0, 22 if real else 9, Color(1.0, 0.6, 0.9), 3 if real else 1, 3.0 if real else 0.0)
				return true
		"spike_trail":             # дорожка кристальных шипов ползёт к герою
			if is_instance_valid(p.target) and d < 1400.0:
				p._anim("cast")
				var fy2 := p.global_position.y + p.body_size.y / 2
				var trail := {"x": p.global_position.x + p.facing * 120.0}
				for k in 7:
					p._after(0.3 + k * 0.22, func():
						if not p.is_alive() or not is_instance_valid(p.target):
							return
						trail["x"] = move_toward(trail["x"], p.target.global_position.x, 130.0)
						var x: float = trail["x"]
						var rs := RootSpike.new()
						rs.team = p.team
						rs.attacker = p
						rs.crystal = true
						rs.damage = 16
						rs.half = 46.0
						rs.warn = 0.5
						rs.position = Vector2(x, fy2)
						world.add_child(rs))
				return true
		"mirror_images":           # Ирида создаёт два своих отражения
			var am := p.get_tree().get_first_node_in_group("arena_mode")
			var alive_images := 0
			for n in world.get_children():
				if n is Player and n.is_alive() and n.get_meta("kind", "") == "irida_image":
					alive_images += 1
			if am and alive_images == 0:            # новые отражения — только когда старых не осталось
				p._anim("summon")
				for side in [-1.0, 1.0]:
					var x2 := clampf(p.global_position.x + side * 380.0, 200.0, Colosseum.W - 200.0)
					am.spawn_at("irida_image", Vector2(x2, p.global_position.y))
				Fx.ring(world, p.global_position, 200.0, Color(0.85, 0.8, 1.0, 0.8), 0.5, 6.0)
				return true
		"shatter":
			var b3 := brain(p)
			if b3:
				b3.start_shatter()
				return true
	return false

# Луч с линией прицела. n — сколько лучей веером (Ирида — три), stun_self —
# на сколько оглушить стрелка, если отражённый луч попадёт в него самого.
static func _beam(p: Player, windup: float, dmg: int, c: Color, n: int, stun_self: float) -> void:
	var world := p.get_parent()
	p._anim("cast")
	p._forced_time = windup + 0.2
	p._forced_vx = 0.0
	var aim := {"dir": (p.target.global_position - p.rig.muzzle()).normalized() if p.rig else Vector2(p.facing, 0)}
	var line := LightBeam.aim_line(world, p.rig.muzzle(), p.rig.muzzle() + aim["dir"] * 1400.0, Color(1.0, 0.3, 0.35), windup)
	# первую половину подготовки прицел следит за героем, потом замирает — можно увернуться
	p._after(windup * 0.55, func():
		if p.is_alive() and is_instance_valid(p.target) and p.rig:
			aim["dir"] = (p.target.global_position - p.rig.muzzle()).normalized()
			if is_instance_valid(line):
				line.points = PackedVector2Array([p.rig.muzzle(), p.rig.muzzle() + aim["dir"] * 1400.0])
				line.default_color = Color(1.0, 0.15, 0.2, 0.8))
	p._after(windup, func():
		if not p.is_alive() or p.rig == null:
			return
		var cols := [Color(1.0, 0.35, 0.4), Color(0.45, 1.0, 0.55), Color(0.45, 0.6, 1.0)]
		for i in n:
			var a := 0.0 if n == 1 else (i - (n - 1) / 2.0) * 0.17
			LightBeam.fire(world, p.rig.muzzle(), (aim["dir"] as Vector2).rotated(a),
					{"team": p.team, "attacker": p, "damage": dmg, "color": c if n == 1 else cols[i % 3],
					"width": 7.0 if n > 1 else 5.0, "bounces": 2, "cell_damage": 25, "stun_self": stun_self}))

static func _resonate(p: Player) -> void:
	if not p.is_alive():
		return
	var world := p.get_parent()
	var at := p.global_position
	Fx.ring(world, at, 240.0, Color(0.8, 0.65, 1.0, 0.9), 0.5, 7.0)
	Fx.ring(world, at, 160.0, Color(1.0, 1.0, 1.0, 0.7), 0.35, 4.0, 0.15)
	for n in world.get_children():
		if n is Destructible and not n.background and n.global_position.distance_to(at) < 400.0:
			n.hit(at, Vector2.UP, 40, 230.0, p.team, {"radial": true, "origin": at, "attacker": p})
		elif n is Player and n.team != p.team and n.is_alive():
			var dist: float = n.global_position.distance_to(at)
			if dist < 240.0:
				n.take_damage(10, p)
				if dist < 160.0:
					n.stun(0.8)
	var rg = p.rig
	if rg is DeepRig:
		rg.buzzing = 0.0
