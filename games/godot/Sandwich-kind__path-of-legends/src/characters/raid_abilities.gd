class_name RaidAbilities
# ---------- Способности противников Лесной тропы, деревни и Колизея ----------
# Вызываются из Player._bot_try, если способность не нашлась у старых ботов
# и у противников глубин. Возвращает true, если способность применена.

static func brain(p: Player) -> RaidBrain:
	return p.get_node_or_null("RaidBrain") as RaidBrain

static func try(p: Player, ab: String, to: Vector2) -> bool:
	var d := absf(to.x)
	var world := p.get_parent()
	match ab:
		"shuriken_fan":                # три сюрикена веером
			if to.length() < 900.0 and is_instance_valid(p.target):
				p._anim("throw")
				var dir: Vector2 = (p.target.global_position - p.global_position).normalized()
				for k in 3:
					p._after(0.1 + k * 0.05, _shuriken.bind(p, dir.rotated((k - 1) * 0.16)))
				return true
		"smoke_step":                  # дым под ноги — и вдруг уже за спиной
			if is_instance_valid(p.target) and d > 180.0 and d < 750.0 and p.is_on_floor():
				var sc := SmokeCloud.new()
				sc.position = p.global_position
				world.add_child(sc)
				p._anim("throw_smoke")
				p._after(0.45, _blink_behind.bind(p))
				return true
		"lunge":                       # резкий выпад с мечом
			if d > 110.0 and d < 430.0 and absf(to.y) < 80.0 and p.is_on_floor():
				p._anim("windup")
				p._forced_time = 0.28
				p._forced_vx = 0.0
				Fx.star(world, p.global_position + Vector2(p.facing * 30.0, -20.0), 12.0, Color(1.0, 0.9, 0.5), 0.3)
				p._after(0.25, _lunge_go.bind(p))
				return true
		"triple_sling":                # три камня подряд
			if to.length() < 900.0:
				p._anim("throw")
				for k in 3:
					p._after(0.1 + k * 0.16, p._release_spear.bind("stone", (k - 1) * 60.0))
				return true
		"shield_bash":                 # таран щитом: отбрасывает и оглушает
			if d < 380.0 and absf(to.y) < 80.0 and p.is_on_floor():
				p._anim("bash")
				p._forced_time = 0.35
				p._forced_vx = p.facing * 760.0
				var hit := {"done": false}
				for k in 4:
					p._after(0.08 * (k + 1), _bash_check.bind(p, hit))
				return true
		"lion_roar":                   # рык: все рядом замедлены
			if to.length() < 460.0:
				p._anim("roar")
				Fx.ring(world, p.global_position, 300.0, Color(1.0, 0.75, 0.35, 0.8), 0.5, 7.0)
				Fx.ring(world, p.global_position, 200.0, Color(1.0, 0.9, 0.6, 0.6), 0.4, 4.0)
				for n in world.get_children():
					if n is Player and n.team != p.team and n.is_alive() and n.global_position.distance_to(p.global_position) < 300.0:
						n.slow(1.6, 0.5)
						n.take_damage(6, p)
				return true
		"arrow_rain":                  # залп с неба: сначала круг на земле, потом стрелы
			if is_instance_valid(p.target) and to.length() < 1300.0:
				p._anim("cast")
				var tx: float = p.target.global_position.x
				var fy: float = p.target.global_position.y + p.target.body_size.y / 2
				var mark := Fx.rune_circle(world, Vector2(tx, fy), 110.0, Color(1.0, 0.4, 0.3, 0.8), 1.0)
				mark.z_index = 2
				for k in 8:
					p._after(0.8 + k * 0.07, _sky_arrow.bind(p, tx + randf_range(-110.0, 110.0), fy))
				return true
		"whirlwind":                   # вихрь с топором/мечом
			var b := brain(p)
			if b and is_instance_valid(p.target) and d < 650.0 and p.is_on_floor():
				b.start_whirl(2.2)
				return true
		"powder_keg":                  # бочка с порохом катится к герою
			if is_instance_valid(p.target) and d > 90.0 and d < 1400.0 and p.is_on_floor():
				p._anim("throw")
				var k2 := PowderKeg.new()
				k2.dir = signf(to.x) if to.x != 0.0 else float(p.facing)
				k2.team = p.team
				k2.attacker = p
				k2.position = p.global_position + Vector2(k2.dir * (p.body_size.x / 2 + 26.0), p.body_size.y / 2 - PowderKeg.R)
				world.add_child(k2)
				return true
		"shockwave":                   # Колосс бьёт в землю: волна каменных шипов в обе стороны
			if d < 1300.0 and absf(to.y) < 260.0 and p.is_on_floor():
				p._anim("stomp")
				p._forced_time = 0.9
				p._forced_vx = 0.0
				var fy2 := p.global_position.y + p.body_size.y / 2
				p._after(0.45, func():
					if p.is_alive():
						Fx.ring(world, Vector2(p.global_position.x, fy2), 160.0, Color(0.9, 0.7, 0.45, 0.9), 0.4, 8.0, 0.3)
						Fx.cracks(world, Vector2(p.global_position.x, fy2), Color(0.3, 0.24, 0.2), 140.0))
				for side in [-1.0, 1.0]:
					for k in 10:
						p._after(0.5 + k * 0.09, _wave_spike.bind(p, p.global_position.x + side * (p.body_size.x / 2 + 40.0 + k * 105.0), fy2))
				return true
		# ----- Колосс Пробуждённый (вторая фаза) -----
		"fire_dash":                   # огненный рывок через поле
			var br = p.get_node_or_null("RaidBrain")
			if br and is_instance_valid(p.target) and absf(to.y) < 220.0 and d > 220.0 and d < 1500.0 and p.is_on_floor():
				br.start_dash(signf(to.x) if to.x != 0.0 else float(p.facing))
				return true
		"meteor_leap":                 # прыжок за край экрана и падение на героя
			var br2 = p.get_node_or_null("RaidBrain")
			if br2 and is_instance_valid(p.target) and p.is_on_floor() and d < 1600.0:
				br2.start_leap()
				return true
		"core_nova":                   # ядро разгорается — взрыв вокруг
			var br3 = p.get_node_or_null("RaidBrain")
			if br3 and is_instance_valid(p.target) and to.length() < 800.0 and p.is_on_floor():
				br3.start_nova()
				return true
		"lava_volley":                 # три кома лавы по дуге: где упадут — горит земля
			if is_instance_valid(p.target) and d < 1300.0:
				p._anim("throw")
				p._forced_time = 0.5
				p._forced_vx = 0.0
				var side := signf(to.x) if to.x != 0.0 else float(p.facing)
				for k in 3:
					p._after(0.12 + k * 0.14, _lava_ball.bind(p, side, d * (0.75 + k * 0.25)))
				return true
		"chain_pull":                  # цепь с крюком: линия прицела, потом рывок к Колоссу
			if is_instance_valid(p.target) and to.length() > 260.0 and to.length() < 1200.0:
				_chain(p)
				return true
		# ----- Жуткий лес -----
		"fire_orb":                    # огонёк пускает зелёный шар, который доворачивает на цель
			if is_instance_valid(p.target) and to.length() < 900.0:
				var b := Bullet.new()
				b.shooter = p
				b.team = p.team
				b.direction = (p.target.global_position - p.global_position).normalized()
				b.speed = 430.0
				b.damage = maxi(6, p.bullet_damage)
				b.size = 14.0
				b.homing = 260.0
				b.color = Color(0.55, 1.0, 0.7)
				b.style = "soul"
				b.position = p.global_position
				world.add_child(b)
				Fx.sparks(world, p.global_position, Color(0.55, 1.0, 0.7), 5, 120.0, 3.0)
				return true
		"hex":                         # ведьма проклинает землю под героем: круг, потом корни
			if is_instance_valid(p.target) and to.length() < 1300.0:
				p._anim("cast")
				var t: Player = p.target
				var gy := _ground_under(p, t.global_position)
				var rune := Fx.rune_circle(world, Vector2(t.global_position.x, gy), 80.0, Color(0.75, 0.35, 1.0, 0.9), 1.0)
				rune.z_index = 2
				var rs := RootSpike.new()
				rs.team = p.team
				rs.attacker = p
				rs.damage = 14
				rs.warn = 1.0
				rs.half = 75.0
				rs.root_time = 1.1
				rs.position = Vector2(t.global_position.x, gy)
				world.add_child(rs)
				return true
		"flask_volley":                # три склянки с ядом веером
			if is_instance_valid(p.target) and to.length() < 1000.0:
				p._anim("throw")
				for k in 3:
					p._after(0.12 + k * 0.14, p._release_spear.bind("flask", (k - 1) * 120.0))
				return true
		"witch_blink":                 # исчезает в стае воронов и появляется в другом месте
			var bw := brain(p)
			if bw and p.is_on_floor():
				bw.start_blink()
				return true
		# ----- Болото -----
		"tongue":                      # жаболюд выстреливает языком и подтягивает добычу
			if is_instance_valid(p.target) and d > 140.0 and d < 460.0 and absf(to.y) < 120.0:
				p._anim("punch")
				p._forced_time = 0.5
				p._forced_vx = 0.0
				var tgt: Player = p.target
				p._after(0.25, func():
					if not p.is_alive() or not is_instance_valid(tgt) or not tgt.is_alive():
						return
					var mouth: Vector2 = p.global_position + Vector2(p.facing * p.body_size.x * 0.4, -p.body_size.y * 0.15)
					var tl := Line2D.new()
					tl.points = PackedVector2Array([mouth, tgt.global_position])
					tl.width = 6.0
					tl.default_color = Color(0.85, 0.40, 0.45)
					tl.z_index = 5
					world.add_child(tl)
					var tw := tl.create_tween()
					tw.tween_property(tl, "modulate:a", 0.0, 0.3)
					tw.tween_callback(tl.queue_free)
					if absf(tgt.global_position.x - p.global_position.x) < 480.0:
						tgt.take_damage(6, p)
						tgt.velocity = Vector2(signf(p.global_position.x - tgt.global_position.x) * 760.0, -260.0))
				return true
		"anchor_pull":                 # утопленник забрасывает якорь на цепи и тянет к себе
			if is_instance_valid(p.target) and to.length() > 200.0 and to.length() < 800.0:
				_chain(p, false, 800.0)
				return true
		"latch":                       # пиявка присасывается: пьёт кровь и лечится
			if is_instance_valid(p.target) and to.length() < p.body_size.x / 2 + p.target.body_size.x / 2 + 20.0:
				p.target.take_damage(5, p)
				p.target.slow(0.6, 0.6)
				p.heal(5)
				Fx.sparks(world, p.target.global_position, Color(0.8, 0.15, 0.2), 5, 120.0, 3.0)
				return true
		"submerge":                    # Владыка ныряет в трясину и вылезает под героем
			var bs := brain(p)
			if bs and p.is_on_floor() and is_instance_valid(p.target):
				bs.start_submerge()
				return true
		"mud_wave":                    # волна грязи бежит по земле в обе стороны
			if d < 1300.0 and absf(to.y) < 260.0 and p.is_on_floor():
				p._anim("slam")
				p._forced_time = 0.8
				p._forced_vx = 0.0
				var fy3 := p.global_position.y + p.body_size.y / 2
				for side in [-1.0, 1.0]:
					for k in 9:
						p._after(0.45 + k * 0.1, _mud_spike.bind(p, p.global_position.x + side * (p.body_size.x / 2 + 40.0 + k * 110.0), fy3))
				return true
		"gas_burst":                   # пузыри газа вокруг героя — потом вспышки
			if is_instance_valid(p.target) and to.length() < 1300.0:
				p._anim("roar")
				var tgt2: Player = p.target
				for k in 3:
					var at := Vector2(tgt2.global_position.x + (k - 1) * 150.0, _ground_under(p, tgt2.global_position))
					_gas_bubble(world, at, p)
				return true
	return false

static func _shuriken(p: Player, dir: Vector2) -> void:
	if not p.is_alive():
		return
	var b := Bullet.new()
	b.shooter = p
	b.team = p.team
	b.direction = dir
	b.speed = maxf(800.0, p.bullet_speed)
	b.damage = maxi(4, p.bullet_damage)
	b.size = 9.0
	b.style = "shuriken"
	b.position = p.rig.muzzle() if p.rig else p.global_position
	p.get_parent().add_child(b)

static func _blink_behind(p: Player, smoke := true) -> void:
	if not p.is_alive() or not is_instance_valid(p.target):
		return
	var world := p.get_parent()
	var t: Player = p.target
	var side := signf(t.global_position.x - p.global_position.x)
	if side == 0.0:
		side = 1.0
	var from := p.global_position
	var to := Vector2(clampf(t.global_position.x + side * (t.body_size.x / 2 + p.body_size.x / 2 + 14.0), 120.0, p.map_w - 120.0),
			t.global_position.y + t.body_size.y / 2 - p.body_size.y / 2)          # ступни на одном уровне
	p.global_position = to
	p.velocity = Vector2.ZERO
	p.facing = -int(side)
	if smoke:
		var sc := SmokeCloud.new()
		sc.position = to
		world.add_child(sc)
	Fx.sparks(world, from, Color(0.4, 0.4, 0.45), 8, 160.0, 4.0)
	p._anim("swing")
	p._forced_time = 0.4
	p._forced_vx = 0.0
	p._after(0.22, func():
		if p.is_alive() and is_instance_valid(t) and t.is_alive() and absf(p.global_position.x - t.global_position.x) < (p.body_size.x + t.body_size.x) / 2 + 50.0 \
				and absf((p.global_position.y + p.body_size.y / 2) - (t.global_position.y + t.body_size.y / 2)) < 90.0:
			t.take_damage(p.swing_dmg, p)
			Fx.arc(world, t.global_position, 40.0, -0.8, 0.8, Color(1, 1, 1, 0.9), 0.2))

static func _lunge_go(p: Player) -> void:
	if not p.is_alive() or p._stun_t > 0.0:
		return
	p._anim("punch")
	p._forced_time = 0.3
	p._forced_vx = p.facing * 900.0
	var hit := {"done": false}
	for k in 3:
		p._after(0.08 * (k + 1), func():
			if hit["done"] or not p.is_alive() or not is_instance_valid(p.target):
				return
			var dd: Vector2 = p.target.global_position - p.global_position
			if absf(dd.x) < p.body_size.x / 2 + 70.0 and absf(dd.y) < 70.0:
				hit["done"] = true
				p.target.take_damage(p.swing_dmg, p)
				Util.flash(p.get_parent(), p.target.global_position, 26.0, Color(1, 1, 1, 0.7)))

static func _bash_check(p: Player, hit: Dictionary) -> void:
	if hit["done"] or not p.is_alive() or not is_instance_valid(p.target):
		return
	var t: Player = p.target
	var dd: Vector2 = t.global_position - p.global_position
	if signf(dd.x) == p.facing and absf(dd.x) < (p.body_size.x + t.body_size.x) / 2 + 26.0 and absf(dd.y) < 80.0:
		hit["done"] = true
		t.take_damage(12, p)
		t.velocity = Vector2(p.facing * 620.0, -320.0)
		t.stun(0.7)
		p._forced_time = 0.0
		Fx.ring(p.get_parent(), t.global_position, 50.0, Color(1.0, 0.85, 0.5, 0.9), 0.25, 5.0)

static func _sky_arrow(p: Player, x: float, fy: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var s := Spear.new()
	s.shooter = p
	s.team = p.team
	s.payload = ""
	s.damage = maxi(6, p.bullet_damage)
	s.velocity = Vector2(randf_range(-40.0, 40.0), 1100.0)
	s.position = Vector2(x, fy - 900.0)
	p.get_parent().add_child(s)

# Ком лавы летит по дуге так, чтобы упасть примерно на dist пикселей впереди
static func _lava_ball(p: Player, side: float, dist: float) -> void:
	if not is_instance_valid(p) or not p.is_alive():
		return
	var s := Spear.new()
	s.shooter = p
	s.team = p.team
	s.payload = "lava"
	s.damage = 14
	var vy := -620.0
	var g := 1100.0                        # примерно как падает копьё
	var t := 2.0 * -vy / g
	s.velocity = Vector2(side * clampf(dist, 200.0, 1300.0) / t, vy)
	s.position = p.global_position + Vector2(side * p.body_size.x * 0.4, -p.body_size.y * 0.35)
	p.get_parent().add_child(s)
	Fx.sparks(p.get_parent(), s.position, Color(1.0, 0.6, 0.2), 5, 120.0, 3.0)

static func _wave_spike(p: Player, x: float, fy: float) -> void:
	if not is_instance_valid(p) or x < 80.0 or x > p.map_w - 80.0:
		return
	var rs := RootSpike.new()
	rs.team = p.team
	rs.attacker = p
	rs.stone = true
	rs.damage = 16
	rs.half = 42.0
	rs.warn = 0.22
	rs.position = Vector2(x, fy)
	p.get_parent().add_child(rs)

# Цепь Колосса: красная линия прицела 0,7 с, потом крюк летит по ней.
# Кого зацепило — того тянет к Колоссу, и тот бьёт кулаком в землю.
static func _chain(p: Player, slam := true, reach := 1250.0) -> void:
	var world := p.get_parent()
	p._anim("windup")
	p._forced_time = 1.0
	p._forced_vx = 0.0
	var from := p.global_position + Vector2(p.facing * p.body_size.x * 0.35, -p.body_size.y * 0.2)
	var aim := {"dir": (p.target.global_position - from).normalized()}
	var line := LightBeam.aim_line(world, from, from + aim["dir"] * reach, Color(1.0, 0.25, 0.2), 0.7)
	p._after(0.4, func():
		if p.is_alive() and is_instance_valid(p.target):
			aim["dir"] = (p.target.global_position - from).normalized()
			if is_instance_valid(line):
				line.points = PackedVector2Array([from, from + aim["dir"] * reach])
				line.default_color = Color(1.0, 0.1, 0.1, 0.85))
	p._after(0.7, func():
		if not p.is_alive():
			return
		var a := from
		var b: Vector2 = from + (aim["dir"] as Vector2) * reach
		var caught: Player = null
		for n in world.get_children():
			if n is Player and n.team != p.team and n.is_alive():
				var cp := Geometry2D.get_closest_point_to_segment(n.global_position, a, b)
				if cp.distance_to(n.global_position) < n.body_size.x / 2 + 18.0:
					if caught == null or a.distance_to(n.global_position) < a.distance_to(caught.global_position):
						caught = n
		var end := b if caught == null else caught.global_position
		var chain := Line2D.new()
		chain.points = PackedVector2Array([a, end])
		chain.width = 6.0
		chain.default_color = Color(0.55, 0.55, 0.6)
		chain.z_index = 5
		world.add_child(chain)
		var hook := Polygon2D.new()
		hook.polygon = PackedVector2Array([Vector2(-6, -8), Vector2(10, 0), Vector2(-6, 8), Vector2(-2, 0)])
		hook.color = Color(0.75, 0.75, 0.8)
		hook.position = end
		hook.rotation = (aim["dir"] as Vector2).angle()
		chain.add_child(hook)
		hook.position = end
		var t := chain.create_tween()
		t.tween_interval(0.35)
		t.tween_property(chain, "modulate:a", 0.0, 0.25)
		t.tween_callback(chain.queue_free)
		if caught:
			caught.take_damage(8, p)
			var pull: Vector2 = (p.global_position - caught.global_position)
			caught.velocity = Vector2(signf(pull.x) * minf(absf(pull.x) * 2.2, 1300.0), -320.0)
			caught.root(0.15)
			Fx.sparks(world, caught.global_position, Color(0.8, 0.8, 0.85), 8, 200.0, 3.0)
			if not slam:
				return
			p._after(0.55, func():
				if p.is_alive():
					p._bot_cd.erase("slam")
					var tt: Vector2 = caught.global_position - p.global_position if is_instance_valid(caught) else Vector2(9999, 0)
					_colossus_slam(p, tt)))

static func _colossus_slam(p: Player, _to: Vector2) -> void:
	p._anim("slam")
	p._forced_time = 0.55
	p._forced_vx = 0.0
	p._after(0.45, func():
		if p.is_alive():
			var feet := p.global_position + Vector2(p.facing * p.body_size.x * 0.4, p.body_size.y / 2)
			Util.explode(p.get_parent(), feet, 190.0, 24, 40, p.team, p)
			Fx.ring(p.get_parent(), feet, 200.0, Color(0.9, 0.7, 0.45, 0.9), 0.4, 8.0, 0.3)
			Fx.cracks(p.get_parent(), feet, Color(0.3, 0.24, 0.2), 120.0))

# Где земля под точкой
static func _ground_under(p: Player, at: Vector2) -> float:
	var gh := p.get_world_2d().direct_space_state.intersect_ray(PhysicsRayQueryParameters2D.create(
			at + Vector2(0, -10), at + Vector2(0, 900), Layer.WORLD | Layer.FRAME))
	return gh["position"].y if not gh.is_empty() else at.y + 30.0

# Грязевой шип волны Владыки: бьёт и оставляет лужицу трясины
static func _mud_spike(p: Player, x: float, fy: float) -> void:
	if not is_instance_valid(p) or x < 80.0 or x > p.map_w - 80.0:
		return
	var rs := RootSpike.new()
	rs.team = p.team
	rs.attacker = p
	rs.stone = true
	rs.damage = 14
	rs.half = 44.0
	rs.warn = 0.25
	rs.modulate = Color(0.55, 0.62, 0.38)
	rs.position = Vector2(x, fy)
	p.get_parent().add_child(rs)
	if int(x) % 3 == 0:
		var pud := SwampBits.MudPuddle.new()
		pud.width = 80.0
		pud.life = 3.0
		pud.position = Vector2(x, fy)
		p.get_parent().add_child(pud)

# Пузырь болотного газа: 1,2 с растёт (видно, куда не стоит), потом вспышка
static func _gas_bubble(world: Node, at: Vector2, p: Player) -> void:
	var b := Polygon2D.new()
	b.polygon = Util.circle(24.0, 14)
	b.color = Color(0.55, 0.9, 0.35, 0.55)
	b.position = at + Vector2(0, -26)
	b.scale = Vector2(0.2, 0.2)
	b.z_index = 3
	world.add_child(b)
	var t := b.create_tween()
	t.tween_property(b, "scale", Vector2(1.3, 1.3), 1.2)
	t.tween_callback(func():
		if is_instance_valid(world):
			Util.explode(world, b.position, 110.0, 16, 25, p.team if is_instance_valid(p) else 1, p if is_instance_valid(p) else null, true)
			Fx.ring(world, b.position, 120.0, Color(0.6, 1.0, 0.4, 0.9), 0.35, 6.0)
			SwampBits.puff(world, b.position, 0.8)
		b.queue_free())
