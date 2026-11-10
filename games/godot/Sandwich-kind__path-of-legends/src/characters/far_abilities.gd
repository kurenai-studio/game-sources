class_name FarAbilities
# ---------- Способности противников дальних земель (волны 61–80) ----------
# Вызываются из Player._bot_try, если способность не нашлась у других наборов.
# Возвращает true, если способность применена.
#   Ледяная тропа:   howl, frost_volley, ice_shard, frost_slam, frost_breath, icicle_rain,
#                    ice_armor, glacier_wave
#   Храм шторма:     chain_spark, feathers, overload, call_lightning, chain_lightning,
#                    storm_call, tornado, wind_blast, overload_storm
#   Лава:            fire_breath, meteor, triple_fire, howl_imps, lava_charge, bite
#   Тронный зал:     shadow_orbs, stone_skin, dark_wave, shadow_dash, dark_orbs, eclipse,
#                    hellfire, black_hole, wing_dash

static func brain(p: Player) -> FarBrain:
	return p.get_node_or_null("FarBrain") as FarBrain

static func _foes(p: Player) -> Array:
	var res: Array = []
	for n in p.get_parent().get_children():
		if n is Player and n.team != p.team and n.is_alive() and not n.cutscene_shield:
			res.append(n)
	return res

static func _ground(p: Player, at: Vector2) -> float:
	return RaidAbilities._ground_under(p, at)

static func try(p: Player, ab: String, to: Vector2) -> bool:
	var d := absf(to.x)
	var world := p.get_parent()
	var has_t := is_instance_valid(p.target)
	match ab:
		# ======================= Ледяная тропа =======================
		"howl":                        # волк воет — стая бежит быстрее
			if to.length() < 900.0:
				p._anim("roar")
				Fx.ring(world, p.global_position, 260.0, Color(0.8, 0.9, 1.0, 0.8), 0.5, 6.0)
				for n in world.get_children():
					if n is Player and n.team == p.team and n.is_alive() and String(n.get_meta("kind", "")) == "snow_wolf" \
							and n.global_position.distance_to(p.global_position) < 700.0:
						n.add_buff("speed", false, false)
				return true
		"frost_volley":                # три ледяные стрелы веером
			if has_t and to.length() < 1100.0:
				p._anim("throw")
				for k in 3:
					p._after(0.1 + k * 0.09, p._release_spear.bind("ice_arrow", (k - 1) * 110.0))
				return true
		"ice_shard":                   # ледяной осколок с доводкой: обдаёт инеем
			if has_t and to.length() < 900.0:
				var b := Bullet.new()
				b.shooter = p
				b.team = p.team
				b.direction = (p.target.global_position - p.global_position).normalized()
				b.speed = 470.0
				b.damage = maxi(6, p.bullet_damage)
				b.size = 12.0
				b.homing = 240.0
				b.style = "ice"
				b.chill = 1.3
				b.color = Color(0.7, 0.9, 1.0)
				b.position = p.global_position
				world.add_child(b)
				Fx.sparks(world, p.global_position, Color(0.8, 0.95, 1.0), 5, 120.0, 3.0)
				return true
		"frost_slam":                  # удар о землю: иней на всех рядом
			if d < 240.0 and absf(to.y) < 100.0 and p.is_on_floor():
				p._anim("slam")
				p._forced_time = 0.6
				p._forced_vx = 0.0
				p._after(0.45, func():
					if not p.is_alive():
						return
					var feet := p.global_position + Vector2(p.facing * 30.0, p.body_size.y / 2)
					Util.explode(world, feet, 170.0, 16, 20, p.team, p)
					Fx.ring(world, feet, 180.0, Color(0.75, 0.92, 1.0, 0.9), 0.4, 7.0, 0.3)
					Fx.sparks(world, feet + Vector2(0, -6), Color(0.85, 0.96, 1.0), 14, 260.0, 4.0, true)
					for n in _foes(p):
						if n.global_position.distance_to(feet) < 190.0:
							n.chill(2.0))
				return true
		"frost_breath":                # Ётун: морозное дыхание (конус)
			var bb := brain(p)
			if bb and has_t and d < 520.0 and absf(to.y) < 220.0 and p.is_on_floor():
				bb.start_breath()
				return true
		"icicle_rain":                 # ливень сосулек: тени на земле, потом падают
			if has_t:
				p._anim("roar")
				var tx: float = p.target.global_position.x
				for k in 6:
					var x := clampf(tx + (k - 2.5) * 120.0 + randf_range(-30, 30), 120.0, p.map_w - 120.0)
					var gy := _ground(p, Vector2(x, p.target.global_position.y - 40.0))
					FarBits.drop_icicle(world, x, gy, 0.9 + k * 0.08, 16)
				return true
		"ice_armor":                   # ледяная броня: принимает урон на себя
			if p.crust <= 0.0:
				p._anim("cast")
				p.give_crust(p.max_hp * 0.10, 8.0)
				Fx.sparks(world, p.global_position, Color(0.75, 0.92, 1.0), 18, 260.0, 4.0)
				Fx.ring(world, p.global_position, p.body_size.y * 0.7, Color(0.8, 0.95, 1.0, 0.9), 0.4, 6.0)
				p._float_label("Ледяная броня!", Color(0.7, 0.92, 1.0))
				return true
		"glacier_wave":                # ледяные шипы бегут по земле в обе стороны
			if d < 1300.0 and absf(to.y) < 260.0 and p.is_on_floor():
				p._anim("stomp")
				p._forced_time = 0.9
				p._forced_vx = 0.0
				var fy := p.global_position.y + p.body_size.y / 2
				for side in [-1.0, 1.0]:
					for k in 9:
						p._after(0.5 + k * 0.09, _ice_spike.bind(p, p.global_position.x + side * (p.body_size.x / 2 + 40.0 + k * 105.0), fy))
				return true
		# ======================= Храм шторма =======================
		"chain_spark":                 # разряд перескакивает с цели на соседа
			if has_t and to.length() < 800.0:
				p._anim("cast")
				p._after(0.25, _chain.bind(p, 9, 6, 1))
				return true
		"feathers":                    # гарпия: веер острых перьев
			if has_t and to.length() < 800.0:
				var dir: Vector2 = (p.target.global_position - p.global_position).normalized()
				for k in 3:
					var b := Bullet.new()
					b.shooter = p
					b.team = p.team
					b.direction = dir.rotated((k - 1) * 0.2)
					b.speed = 720.0
					b.damage = 6
					b.size = 8.0
					b.style = "arrow"
					b.color = Color(0.5, 0.56, 0.68)
					b.position = p.global_position
					world.add_child(b)
				return true
		"overload":                    # шаровая молния: подлетела вплотную — взрыв
			if has_t and to.length() < 110.0:
				var at := p.global_position
				Util.explode(world, at, 120.0, 20, 15, p.team, p)
				Util.flash(world, at, 130.0, Color(0.85, 0.92, 1.0, 0.95))
				for k in 4:
					Fx.bolt(world, at, at + Vector2.from_angle(randf() * TAU) * 120.0, Color(0.8, 0.9, 1.0))
				p.take_damage(99999)
				return true
		"call_lightning":              # жрец: метка — и в неё бьёт молния
			if has_t and to.length() < 1300.0:
				p._anim("cast")
				_strike_at(p, p.target.global_position.x, 1.1, 18)
				return true
		"chain_lightning":             # Владыка: цепная молния
			if has_t and to.length() < 1100.0:
				p._anim("cast")
				p._forced_time = 0.5
				p._forced_vx = 0.0
				p._after(0.3, _chain.bind(p, 14, 9, 2))
				return true
		"storm_call":                  # Владыка: гроза — пять меток вокруг героя
			if has_t:
				p._anim("roar")
				var tx2: float = p.target.global_position.x
				for k in 5:
					var x := clampf(tx2 + (k - 2) * 160.0 + randf_range(-40, 40), 100.0, p.map_w - 100.0)
					_strike_at(p, x, 1.0 + k * 0.18, 16)
				return true
		"tornado":                     # Владыка: смерч идёт через поле
			if has_t and p.is_on_floor():
				p._anim("cast")
				var tn := Tornado.new()
				tn.team = p.team
				tn.attacker = p
				tn.dir = signf(to.x) if to.x != 0.0 else float(p.facing)
				tn.map_w = p.map_w
				tn.position = Vector2(p.global_position.x + tn.dir * 90.0, p.global_position.y + p.body_size.y / 2)
				world.add_child(tn)
				return true
		"wind_blast":                  # Владыка: порыв отбрасывает героев
			if has_t and to.length() < 650.0:
				p._anim("cast")
				p._forced_time = 0.5
				p._forced_vx = 0.0
				p._after(0.3, func():
					if not p.is_alive():
						return
					for n in _foes(p):
						var dd: Vector2 = n.global_position - p.global_position
						if dd.length() < 700.0:
							n.velocity = Vector2(signf(dd.x + 0.01) * 950.0, -340.0)
							n.take_damage(8, p)
					for k in 10:
						var l := Line2D.new()
						var y := p.global_position.y + randf_range(-120, 60)
						var x0 := p.global_position.x + p.facing * randf_range(20, 80)
						l.points = PackedVector2Array([Vector2(x0, y), Vector2(x0 + p.facing * randf_range(160, 320), y + randf_range(-10, 10))])
						l.width = 3.0
						l.default_color = Color(0.85, 0.9, 1.0, 0.7)
						l.z_index = 8
						world.add_child(l)
						var tw := l.create_tween()
						tw.tween_property(l, "position:x", p.facing * 260.0, 0.35)
						tw.parallel().tween_property(l, "modulate:a", 0.0, 0.35)
						tw.tween_callback(l.queue_free))
				return true
		"overload_storm":              # Владыка: Перегрузка (громоотводы)
			var bo := brain(p)
			if bo and bo.can_overload():
				bo.start_overload()
				return true
		# ======================= Лавовые просторы =======================
		"fire_breath":                 # саламандра: короткий язык пламени
			if d < 300.0 and absf(to.y) < 100.0:
				p._anim("breath")
				p._forced_time = 0.9
				p._forced_vx = 0.0
				for k in 5:
					p._after(0.3 + k * 0.1, _flame_puff.bind(p, k))
				return true
		"meteor":                      # культист: метеор в огненный круг
			if has_t and to.length() < 1300.0:
				p._anim("cast")
				var x2: float = p.target.global_position.x
				var gy2 := _ground(p, Vector2(x2, p.target.global_position.y - 40.0))
				var mark := Fx.rune_circle(world, Vector2(x2, gy2), 75.0, Color(1.0, 0.45, 0.15, 0.9), 1.5)
				mark.z_index = 3
				var lb := FarBits.LavaBomb.new()
				lb.team = p.team
				lb.attacker = p
				lb.damage = 18
				lb.position = Vector2(x2 + randf_range(-200, 200), -160.0)
				lb.goal = Vector2(x2, gy2)
				lb.delay = 0.7
				world.add_child(lb)
				return true
		"triple_fire":                 # Цербер: три огненных шара из трёх пастей
			if has_t and to.length() < 1000.0:
				p._anim("breath")
				p._forced_time = 0.5
				p._forced_vx = 0.0
				var mouths: Array = p.rig.head_points() if p.rig and p.rig.has_method("head_points") else [p.global_position]
				for k in mouths.size():
					p._after(0.15 + k * 0.12, _fireball.bind(p, k, mouths.size()))
				return true
		"howl_imps":                   # Цербер: вой — из лавы выпрыгивают бесы
			if p.summon.is_valid():
				p._anim("roar")
				Fx.ring(world, p.global_position, 300.0, Color(1.0, 0.5, 0.2, 0.8), 0.6, 7.0)
				p.summon.call("fire_imp", 2, p.global_position)
				return true
		"lava_charge":                 # Цербер: огненный рывок, за ним горит земля
			var bc := brain(p)
			if bc and has_t and d > 200.0 and d < 1500.0 and absf(to.y) < 160.0 and p.is_on_floor():
				bc.start_lava_charge(signf(to.x))
				return true
		"bite":                        # Цербер: укус средней головой
			if has_t and d < p.body_size.x / 2 + 90.0 and absf(to.y) < 110.0:
				p._anim("punch")
				p._after(0.18, func():
					if not p.is_alive() or not is_instance_valid(p.target):
						return
					var dd: Vector2 = p.target.global_position - p.global_position
					if absf(dd.x) < p.body_size.x / 2 + 100.0 and absf(dd.y) < 120.0:
						p.target.take_damage(18, p)
						p.target.velocity = Vector2(signf(dd.x) * 420.0, -260.0)
						Fx.arc(world, p.target.global_position, 36.0, -0.9, 0.9, Color(1.0, 0.6, 0.3, 0.9), 0.2))
				return true
		# ======================= Тронный зал =======================
		"shadow_orbs":                 # чернокнижник: три сгустка тьмы с доводкой
			if has_t and to.length() < 1000.0:
				p._anim("cast")
				for k in 3:
					p._after(0.15 + k * 0.15, _dark_orb.bind(p, (k - 1) * 0.35, 380.0, maxi(7, p.bullet_damage)))
				return true
		"stone_skin":                  # горгулья каменеет: падает и неуязвима
			if not p.has_meta("stone"):
				p.set_meta("stone", true)
				p.invulnerable = true
				p.frozen = true
				p.set_tint(Color(0.55, 0.55, 0.6))
				Fx.sparks(world, p.global_position, Color(0.55, 0.55, 0.6), 10, 160.0, 4.0)
				p._after(2.2, func():
					if is_instance_valid(p):
						p.remove_meta("stone")
						p.invulnerable = false
						p.frozen = false
						p.set_tint(Color.WHITE))
				return true
		"dark_wave":                   # Лорд: волна тьмы по земле — перепрыгни
			if has_t and d < 1100.0 and absf(to.y) < 160.0 and p.is_on_floor():
				p._anim("swing")
				p._forced_time = 0.55
				p._forced_vx = 0.0
				p._after(0.35, func():
					if not p.is_alive():
						return
					var sw := SlashWave.new()
					sw.team = p.team
					sw.attacker = p
					sw.dir = p.facing
					sw.damage = 20
					sw.speed = 1000.0
					sw.range_px = 1000.0
					sw.color = Color(0.40, 0.05, 0.18, 0.9)
					sw.position = p.global_position + Vector2(p.facing * (p.body_size.x / 2 + 20.0), p.body_size.y * 0.32)
					world.add_child(sw)
					Fx.sparks(world, sw.position, Color(0.6, 0.1, 0.3), 8, 200.0, 4.0))
				return true
		"shadow_dash":                 # Лорд: исчезает в чёрном дыму — и уже за спиной
			if has_t and d > 160.0 and d < 900.0 and p.is_on_floor():
				_dark_smoke(world, p.global_position, p.body_size)
				p._anim("cast")
				p._forced_time = 0.4
				p._forced_vx = 0.0
				p._after(0.35, func():
					if is_instance_valid(p) and p.is_alive():
						RaidAbilities._blink_behind(p, false)
						_dark_smoke(world, p.global_position, p.body_size))
				return true
		"shade_step":                  # Тень: растворяется в тёмной дымке — и уже за спиной
			if has_t and d > 160.0 and d < 750.0 and p.is_on_floor():
				_dark_smoke(world, p.global_position, p.body_size)
				p._anim("throw_smoke")
				p._after(0.4, func():
					if is_instance_valid(p) and p.is_alive():
						_dark_smoke(world, p.global_position, p.body_size)
						RaidAbilities._blink_behind(p, false)
						_dark_smoke(world, p.global_position, p.body_size * 0.7))
				return true
		"dark_orbs":                   # Лорд: кольцо из пяти сгустков тьмы
			if has_t and to.length() < 1200.0:
				p._anim("roar")
				for k in 5:
					p._after(0.2 + k * 0.1, _dark_orb.bind(p, (k - 2) * 0.3, 360.0, 10))
				return true
		"eclipse":                     # Лорд: Затмение
			var be := brain(p)
			if be and has_t:
				be.start_eclipse()
				return true
		"hellfire":                    # Лорд Пробуждённый: столбы адского пламени к герою
			if has_t and d < 1400.0 and p.is_on_floor():
				p._anim("slam")
				p._forced_time = 0.7
				p._forced_vx = 0.0
				var fy2 := p.global_position.y + p.body_size.y / 2
				var dirx := signf(to.x) if to.x != 0.0 else float(p.facing)
				for k in 8:
					p._after(0.4 + k * 0.12, _pillar.bind(p, p.global_position.x + dirx * (p.body_size.x / 2 + 50.0 + k * 120.0), fy2))
				return true
		"black_hole":                  # Лорд Пробуждённый: чёрная дыра
			var bh := brain(p)
			if bh and has_t and p.is_on_floor():
				bh.start_black_hole()
				return true
		"wing_dash":                   # Лорд Пробуждённый: рывок на огненных крыльях
			var bw := brain(p)
			if bw and has_t and d > 200.0 and d < 1600.0 and absf(to.y) < 220.0 and p.is_on_floor():
				bw.start_wing_dash(signf(to.x))
				return true
	return false

# ---------- помощники ----------
static func _ice_spike(p: Player, x: float, fy: float) -> void:
	if not is_instance_valid(p) or x < 80.0 or x > p.map_w - 80.0:
		return
	var rs := RootSpike.new()
	rs.team = p.team
	rs.attacker = p
	rs.crystal = true
	rs.damage = 16
	rs.half = 42.0
	rs.warn = 0.25
	rs.modulate = Color(0.8, 0.95, 1.1)
	rs.position = Vector2(x, fy)
	p.get_parent().add_child(rs)

# Цепная молния: от стрелка к цели, потом к ближайшим соседям цели
static func _chain(p: Player, dmg: int, dmg2: int, jumps: int) -> void:
	if not is_instance_valid(p) or not p.is_alive() or not is_instance_valid(p.target) or not p.target.is_alive():
		return
	var world := p.get_parent()
	var from: Vector2 = p.rig.muzzle() if p.rig else p.global_position
	var cur: Player = p.target
	var hit := {}
	Fx.bolt(world, from, cur.global_position, Color(0.85, 0.92, 1.0))
	Fx.bolt(world, from, cur.global_position, Color(0.6, 0.75, 1.0))
	cur.take_damage(dmg, p)
	Fx.zap(world, cur.global_position, Color(0.8, 0.9, 1.0), 30.0)
	hit[cur] = true
	for j in jumps:
		var best: Player = null
		var bd := 360.0
		for n in world.get_children():
			if n is Player and n.team != p.team and n.is_alive() and not hit.has(n):
				var dd: float = n.global_position.distance_to(cur.global_position)
				if dd < bd:
					bd = dd
					best = n
		if best == null:
			return
		Fx.bolt(world, cur.global_position, best.global_position, Color(0.8, 0.9, 1.0))
		best.take_damage(dmg2, p)
		hit[best] = true
		cur = best

# Метка на земле, через delay — удар молнии с неба
static func _strike_at(p: Player, x: float, delay: float, dmg: int) -> void:
	var world := p.get_parent()
	var y_ref: float = p.target.global_position.y - 40.0 if is_instance_valid(p.target) else p.global_position.y
	var gy := _ground(p, Vector2(x, y_ref))
	var mark := Fx.rune_circle(world, Vector2(x, gy), 70.0, Color(0.6, 0.8, 1.0, 0.9), delay + 0.2)
	mark.z_index = 3
	var team := p.team
	var t := mark.create_tween()
	t.tween_interval(delay)
	t.tween_callback(func():
		var w2 := mark.get_parent()
		if w2 == null:
			return
		var at := Vector2(x, gy)
		Fx.bolt(w2, at + Vector2(randf_range(-80, 80), -950.0), at, Color(0.9, 0.95, 1.0))
		Fx.bolt(w2, at + Vector2(randf_range(-80, 80), -950.0), at, Color(0.6, 0.75, 1.0))
		Util.flash(w2, at + Vector2(0, -20), 80.0, Color(0.85, 0.92, 1.0, 0.95))
		Fx.zap(w2, at, Color(0.85, 0.92, 1.0), 40.0)
		for n in w2.get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
				if absf(n.global_position.x - x) < 70.0 and absf(n.global_position.y + n.body_size.y / 2 - gy) < 160.0:
					n.take_damage(dmg, p if is_instance_valid(p) else null))

static func _flame_puff(p: Player, k: int) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var world := p.get_parent()
	var mouth: Vector2 = p.rig.muzzle() if p.rig else p.global_position
	var reach := 240.0
	for i in 4:
		var f := Polygon2D.new()
		f.polygon = Util.circle(randf_range(10, 18), 10)
		f.color = Color(1.0, 0.5 + randf() * 0.3, 0.15, 0.85)
		f.position = mouth
		f.z_index = 6
		world.add_child(f)
		var end := mouth + Vector2(p.facing * reach * randf_range(0.6, 1.0), randf_range(-30, 30))
		var tw := f.create_tween()
		tw.tween_property(f, "position", end, 0.3)
		tw.parallel().tween_property(f, "scale", Vector2(1.8, 1.8), 0.3)
		tw.parallel().tween_property(f, "modulate:a", 0.0, 0.3)
		tw.tween_callback(f.queue_free)
	if k % 2 == 0:
		for n in _foes(p):
			var dd: Vector2 = n.global_position - mouth
			if signf(dd.x) == float(p.facing) and absf(dd.x) < reach + 20.0 and absf(dd.y) < 60.0 + absf(dd.x) * 0.2:
				n.take_damage(8, p)
				if not n.has_meta("fireproof"):
					n.burn(2.0, 6.0, p)

static func _fireball(p: Player, k: int, n_heads: int) -> void:
	if not is_instance_valid(p) or not p.is_alive() or not is_instance_valid(p.target):
		return
	var mouths: Array = p.rig.head_points() if p.rig and p.rig.has_method("head_points") else [p.global_position]
	var from: Vector2 = mouths[mini(k, mouths.size() - 1)]
	var b := Bullet.new()
	b.shooter = p
	b.team = p.team
	b.direction = (p.target.global_position - from).normalized().rotated((k - (n_heads - 1) / 2.0) * 0.16)
	b.speed = 620.0
	b.damage = 12
	b.size = 16.0
	b.style = "ember"
	b.burn_t = 2.0
	b.color = Color(1.0, 0.6, 0.2)
	b.position = from
	p.get_parent().add_child(b)
	Fx.sparks(p.get_parent(), from, Color(1.0, 0.6, 0.2), 5, 140.0, 3.0)

static func _dark_orb(p: Player, spread: float, speed: float, dmg: int) -> void:
	if not is_instance_valid(p) or not p.is_alive() or not is_instance_valid(p.target):
		return
	var from: Vector2 = p.rig.muzzle() if p.rig else p.global_position
	var b := Bullet.new()
	b.shooter = p
	b.team = p.team
	b.direction = (p.target.global_position - from).normalized().rotated(spread)
	b.speed = speed
	b.damage = dmg
	b.size = 14.0
	b.homing = 280.0
	b.style = "dark"
	b.color = Color(0.5, 0.15, 0.6)
	b.position = from
	p.get_parent().add_child(b)

static func _dark_smoke(world: Node, at: Vector2, bs: Vector2) -> void:
	for k in 8:
		var s := Polygon2D.new()
		s.polygon = Util.circle(randf_range(14, 26), 10)
		s.color = Color(0.08, 0.04, 0.10, 0.8)
		s.position = at + Vector2(randf_range(-bs.x * 0.5, bs.x * 0.5), randf_range(-bs.y * 0.4, bs.y * 0.4))
		s.z_index = 6
		world.add_child(s)
		var t := s.create_tween()
		t.set_parallel(true)
		t.tween_property(s, "scale", Vector2(1.8, 1.8), 0.8)
		t.tween_property(s, "position:y", s.position.y - 50.0, 0.8)
		t.tween_property(s, "modulate:a", 0.0, 0.8)
		t.chain().tween_callback(s.queue_free)

# Столб адского пламени: короткое свечение на земле, потом столб огня
static func _pillar(p: Player, x: float, fy: float) -> void:
	if not is_instance_valid(p) or x < 80.0 or x > p.map_w - 80.0:
		return
	var fp := FirePillar.new()
	fp.team = p.team
	fp.attacker = p
	fp.position = Vector2(x, fy)
	p.get_parent().add_child(fp)

class FirePillar extends Node2D:
	var team := 1
	var attacker: Node
	var damage := 16
	var harmless := false              # только для красоты (кат-сцена)
	var _t := 0.0
	var _hit := {}
	var _warn: Polygon2D
	var _fire: Node2D

	func _ready() -> void:
		z_index = 5
		_warn = Polygon2D.new()
		_warn.polygon = PackedVector2Array([Vector2(-40, -3), Vector2(40, -3), Vector2(40, 3), Vector2(-40, 3)])
		_warn.color = Color(0.85, 0.2, 0.9, 0.7)
		add_child(_warn)
		_fire = Node2D.new()
		_fire.visible = false
		add_child(_fire)
		for i in 5:
			var f := Polygon2D.new()
			f.polygon = PackedVector2Array([Vector2(-14, 0), Vector2(-6, -150), Vector2(0, -240), Vector2(6, -140), Vector2(14, 0)])
			f.color = Color(0.85, 0.25, 0.1, 0.85) if i % 2 == 0 else Color(0.25, 0.04, 0.22, 0.85)
			f.position = Vector2(-30 + i * 15, 0)
			_fire.add_child(f)

	func _physics_process(delta: float) -> void:
		_t += delta
		if _t < 0.45:
			_warn.modulate.a = 0.5 + 0.5 * absf(sin(_t * 20.0))
			return
		if not _fire.visible:
			_fire.visible = true
			_warn.visible = false
			Fx.sparks(get_parent(), global_position + Vector2(0, -10), Color(1.0, 0.4, 0.2), 10, 260.0, 4.0, true)
		for f in _fire.get_children():
			f.scale = Vector2(1.0 + randf_range(-0.12, 0.12), 0.85 + randf() * 0.3)
		for n in get_parent().get_children():
			if harmless:
				break
			if n is Player and n.team != team and n.is_alive() and not _hit.has(n) and not n.cutscene_shield:
				var feet: float = n.global_position.y + n.body_size.y / 2
				if absf(n.global_position.x - global_position.x) < 44.0 + n.body_size.x * 0.3 and feet > global_position.y - 250.0 and feet < global_position.y + 12.0:
					_hit[n] = true
					n.take_damage(damage, attacker if is_instance_valid(attacker) else null)
					n.velocity.y = -520.0
		if _t > 1.1:
			modulate.a -= delta * 4.0
			if modulate.a <= 0.0:
				queue_free()

# Смерч Владыки Бури: идёт по земле, подхватывает героев и кружит
class Tornado extends Node2D:
	var team := 1
	var attacker: Node
	var dir := 1.0
	var map_w := 2600.0
	var speed := 250.0
	var life := 5.5
	var _rings: Array = []
	var _t := 0.0
	var _tick := {}

	func _ready() -> void:
		z_index = 6
		for k in 8:
			var r := Line2D.new()
			var pts := Util.circle(1.0, 18)
			pts.append(pts[0])
			var rw := 26.0 + k * 9.0
			for i in pts.size():
				pts[i] = pts[i] * Vector2(rw, rw * 0.25)
			r.points = pts
			r.width = 4.0
			r.default_color = Color(0.70, 0.76, 0.86, 0.75 - k * 0.04)
			r.position = Vector2(0, -12.0 - k * 26.0)
			add_child(r)
			_rings.append(r)
		scale = Vector2(0.2, 0.2)
		create_tween().tween_property(self, "scale", Vector2.ONE, 0.4)

	func _physics_process(delta: float) -> void:
		_t += delta
		life -= delta
		position.x += dir * speed * delta
		for k in _rings.size():
			var r: Line2D = _rings[k]
			r.position.x = sin(_t * 6.0 + k * 0.6) * (4.0 + k * 2.0)
			r.rotation = sin(_t * 9.0 + k) * 0.08
		if randf() < 0.5:
			Fx.sparks(get_parent(), global_position + Vector2(randf_range(-40, 40), -randf_range(0, 200)), Color(0.75, 0.8, 0.9), 1, 140.0, 3.0)
		for n in get_parent().get_children():
			if n is Player and n.team != team and n.is_alive() and not n.cutscene_shield:
				var feet: float = n.global_position.y + n.body_size.y / 2
				if absf(n.global_position.x - global_position.x) < 60.0 and feet > global_position.y - 240.0 and feet < global_position.y + 20.0:
					n.velocity.y = minf(n.velocity.y, -360.0)          # подхватило и крутит
					n.push_wind(dir * 160.0)
					var nt: float = _tick.get(n, 0.0)
					if _t >= nt:
						_tick[n] = _t + 0.5
						n.take_damage(6, attacker if is_instance_valid(attacker) else null)
		if life <= 0.0 or global_position.x < 120.0 or global_position.x > map_w - 120.0:
			modulate.a -= delta * 3.0
			if modulate.a <= 0.0:
				queue_free()
