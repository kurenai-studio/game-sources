class_name HeroKit
extends Node
# Способности новых легенд. Набор прикрепляется к герою (Player.kit) и сам
# решает, как он стреляет, что делают способности 1–3 и ульта.
#   champion  — ЧЕМПИОН (за Колосса): пилумы/удар копьём, таран щитом, сеть, рёв толпы,
#               ульта «Копья света».
#   ternovnik — ТЕРНОВНИК (за Энта): семена-шипы, хватка корней, тотем жизни,
#               лиана со склянкой яда, ульта «Пробуждение леса» (форма Энта).
#   mortis    — МОРТИС (за Короля скелетов): сгустки душ, призыв скелетов,
#               кости-обереги, призрачный шаг, ульта «Меч Короля».

var hero := ""
var p: Player
var duel := false              # в Дуэли у тотемов есть заряды

# Чемпион
var _bash_t := 0.0
var _bash_hit := {}
var _bash_mega := false
var _roar_t := 0.0
var _roar_mega := false
# Терновник
var totem_charges := 3
var _aiming := -1              # какая способность сейчас целится (лиана)
var _aim_t := 0.0
var _arrow: Polygon2D
var _vine: Line2D
var _pull_t := 0.0
var _pull_mega := false
var _anchor := Vector2.ZERO
var _ent_t := 0.0
var _smash_t := 0.0
var _totems: Array = []
# Мортис
var _ghost_t := 0.0
var _ghost_mega := false
var _minions: Array = []

const TOTEM_CHARGES := 3

# ---------- Стрельба ----------
func weapon(delta: float, shoot: bool) -> void:
	var rapid := p.has_buff("rapid")
	if p._reloading > 0.0:
		p._reloading -= delta
		if p._reloading <= 0.0:
			p._reloading = 0.0
			p.ammo = p.clip_size
	elif not p.is_bot and Input.is_action_just_pressed(p.prefix + "_reload") and p.ammo < p.clip_size:
		p._reloading = p.reload_time
	if rapid:
		p._reloading = 0.0
		p.ammo = p.clip_size
	if not shoot or p._cooldown_left > 0.0 or p._reloading > 0.0:
		return
	var cd := p.fire_cooldown * (0.5 if rapid else 1.0)
	match hero:
		"champion":
			if _enemy_close(170.0):
				_thrust()                  # вблизи — удар копьём вперёд, патроны не тратит
				p._cooldown_left = 0.45 * (0.6 if rapid else 1.0)
				return
			_throw("javelin", _lob(Vector2(p.facing * 950.0, -260.0) + p.velocity * 0.25, 900.0), p.bullet_damage)
			p._anim("throw")
		"ternovnik":
			var ent := _ent_t > 0.0
			_throw("thorn_big" if ent else "thorn", _lob(Vector2(p.facing * 720.0, -280.0), 700.0), 15 if ent else p.bullet_damage)
			p._anim("throw" if not ent else "shoot")
		"mortis":
			var b := p._shoot_bullet(p.bullet_speed, p.bullet_damage, 0.0, p.bullet_size, 0.0)
			b.color = Color(0.75, 0.45, 1.0)
			b.lifesteal = 0.2
			b.restyle("soul")
			b.homing = 220.0
			if rapid and p.is_mega("rapid"):
				b.pierce = 3
	p._cooldown_left = cd
	if not rapid:
		p.ammo -= 1
		if p.ammo <= 0:
			p._reloading = p.reload_time

func _throw(kind: String, vel: Vector2, dmg: int) -> Spear:
	var s := Spear.new()
	s.shooter = p
	s.team = p.team
	s.payload = kind
	s.damage = dmg
	s.velocity = vel
	s.position = (p.rig.muzzle() if p.rig else p.global_position) + Vector2(0, -6)
	p.get_parent().add_child(s)
	return s

# Помощь в прицеливании для бросков по дуге (только на Арене, по ботам):
# если враг впереди в пределах броска, дуга подбирается так, чтобы попасть в него
func _lob(vel: Vector2, speed: float) -> Vector2:
	if p.is_bot or not Balance.arena(p):
		return vel
	var from: Vector2 = (p.rig.muzzle() if p.rig else p.global_position) + Vector2(0, -6)
	var best: Player = null
	var bd := 1050.0
	for e in _enemies():
		if not e.is_bot or e.cutscene_shield:
			continue
		var to: Vector2 = e.hurt_center() - from
		if to.x * p.facing <= 20.0 or absf(to.y) > 380.0:
			continue
		if to.length() < bd:
			bd = to.length()
			best = e
	if best == null:
		return vel
	var t := clampf(bd / speed, 0.3, 1.2)
	return Spear.aim(from, best.hurt_center() + best.velocity * t * 0.5, t)

func _enemies() -> Array:
	var res := []
	for n in p.get_parent().get_children():
		if n is Player and n.team != p.team and n.is_alive():
			res.append(n)
	return res

func _nearest_enemy(max_d := 1400.0) -> Player:
	var best: Player = null
	var bd := max_d
	for e in _enemies():
		var d: float = p.global_position.distance_to(e.global_position)
		if d < bd:
			bd = d
			best = e
	return best

func _enemy_close(reach: float) -> bool:
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		if signf(to.x) == p.facing and absf(to.x) < reach + e.body_size.x / 2 and absf(to.y) < 60.0:
			return true
	return false

# Чемпион: удар копьём вперёд — ранит всех на пути и пробивает ящики
func _thrust() -> void:
	p._anim("punch")
	var reach := 180.0
	for e in _enemies():
		var to: Vector2 = e.global_position - p.global_position
		if signf(to.x) == p.facing and absf(to.x) < reach + e.body_size.x / 2 and absf(to.y) < 60.0:
			e.take_damage(18, p)
	for n in p.get_parent().get_children():
		if n is Destructible and n.shield_team != p.team and n.global_position.distance_to(p.global_position) < 400.0:
			n.hit(p.global_position + Vector2(p.facing * 100.0, -4), Vector2(p.facing, 0), 25, 20.0, p.team,
					{"strict": true, "attacker": p})
	var line := Line2D.new()
	line.points = PackedVector2Array([p.global_position + Vector2(p.facing * 30, -4), p.global_position + Vector2(p.facing * reach, -4)])
	line.width = 6.0
	line.default_color = Color(1, 1, 0.9, 0.7)
	p.get_parent().add_child(line)
	var t := line.create_tween()
	t.tween_property(line, "modulate:a", 0.0, 0.18)
	t.tween_callback(line.queue_free)

# ---------- Способности ----------
func handle_ability(i: int, ab: String, action: String, delta: float) -> void:
	p._cd[i] = maxf(0.0, p._cd[i] - delta * p._cd_speed())
	if ab == "vine":
		_handle_vine(i, action, delta)
		return
	if not Input.is_action_just_pressed(action) or p._cd[i] > 0.0:
		return
	if ab == "totem" and duel and totem_charges <= 0:
		Util.flash(p.get_parent(), p.global_position, 20.0, Color(1, 0.3, 0.3, 0.6))
		return
	use(ab)
	p._cd[i] = p.ability_cds[i]
	if ab == "totem" and not duel:
		p._cd[i] = 25.0                       # на Арене зарядов нет, но откат долгий

func use(ab: String) -> void:
	var mega := p._mega_ab()
	match ab:
		"bash":
			_bash_t = 0.7 if mega else 0.35
			_bash_mega = mega
			_bash_hit.clear()
			p._forced_time = _bash_t
			p._forced_vx = p.facing * 1100.0
			p._forced_no_gravity = false
			p._anim("bash")
			if mega:
				p.set_visual_scale(1.4, 0.15)    # МЕГА: Чемпион становится больше
		"net":
			# Арена: три сети веером
			var angs := [-0.18, 0.0, 0.16] if Balance.arena(p) else [0.0]
			for a in angs:
				_throw("net_poison" if mega else "net", Vector2(p.facing * 800.0, -220.0).rotated(a * p.facing), 0)
			p._anim("throw")
		"roar":
			var arena := Balance.arena(p)
			_roar_t = 8.0 if arena else 6.0
			_roar_mega = mega
			p.boost(1.3, _roar_t)
			if arena:
				# Арена: рёв ещё и лечит, а враги рядом цепенеют от страха (замедлены)
				p.heal(int(p.max_hp * 0.2))
				for e in _enemies():
					if e.global_position.distance_to(p.global_position) < 280.0:
						e.slow(2.0, 0.45)
			p._anim("roar")
			p.set_visual_scale(1.15)
			if mega:
				p.armor_mult = 0.5               # «мраморный» Чемпион
				p.set_tint(Color(1.35, 1.35, 1.45))
			Fx.ring(p.get_parent(), p.global_position, 140.0, Color(1.0, 0.8, 0.3, 0.8), 0.5, 6.0)
			Fx.sparks(p.get_parent(), p.global_position + Vector2(0, -30), Color(1.0, 0.85, 0.4), 12, 220.0, 4.0, true)
		"roots":
			_roots(mega)
			Fx.sparks(p.get_parent(), p.global_position + Vector2(0, p.body_size.y / 2), Color(0.5, 0.9, 0.3), 8, 120.0, 4.0, true)
		"totem":
			_place_totem(mega)
		"summon":
			_summon(mega)
		"bones":
			p._anim("cast")
			Fx.ring(p.get_parent(), p.global_position, 120.0, Color(0.95, 0.92, 0.85, 0.8), 0.45, 5.0)
			var arena := Balance.arena(p)
			for n in p.get_parent().get_children():
				if n is Player and n.team == p.team and n.is_alive():
					n.add_bones((4 if mega else 2) if arena else (3 if mega else 1))
					if arena:
						n.heal(10)                   # Арена: обереги ещё и лечат
		"ghost":
			_ghost_t = 3.0 if mega else 4.0
			_ghost_mega = mega
			p.fly_free = true
			p.armor_mult = 0.5
			p.set_tint(Color(0.8, 0.75, 1.0, 0.55))
			Fx.sparks(p.get_parent(), p.global_position, Color(0.7, 0.5, 1.0), 14, 180.0, 4.0)
			if mega:
				# МЕГА: сквозь стены и блоки, за спиной — облако тьмы
				p.collision_mask = Player.PHASE_MASK
				var sc := SmokeCloud.new()
				sc.position = p.global_position
				sc.modulate = Color(0.35, 0.25, 0.45)
				p.get_parent().add_child(sc)

# ---------- Ульта ----------
# У каждой легенды ульта — маленькое представление: замах, эффекты, удар.
func ult() -> void:
	var mega := p._mega_ab()
	var world := p.get_parent()
	match hero:
		"champion":
			# «Копья света»: Чемпион поднимает копьё к небу — с неба падает луч
			# на острие, под ногами вспыхивает золотой круг; потом веер копий
			# летит вперёд, и через 1,5 с в каждое бьёт луч света.
			p._forced_time = 0.75
			p._forced_vx = 0.0
			p._anim("invoke")
			Fx.rune_circle(world, p.global_position + Vector2(0, p.body_size.y / 2), 80.0, Color(1.0, 0.82, 0.3, 0.9), 1.1)
			Fx.glow(world, p.global_position + Vector2(0, -20), 90.0, Color(1.0, 0.92, 0.55, 0.25), 0.9)
			_after(0.25, func():
				var tip: Vector2 = p.rig.muzzle() if p.rig else p.global_position
				Fx.star(world, tip, 34.0, Color(1.0, 0.95, 0.6, 0.95), 0.5)
				Fx.sparks(world, tip, Color(1.0, 0.85, 0.35), 14, 240.0, 5.0)
				var ray := Polygon2D.new()          # луч с неба на острие
				ray.polygon = PackedVector2Array([Vector2(-10, -900), Vector2(10, -900), Vector2(3, 0), Vector2(-3, 0)])
				ray.color = Color(1.0, 0.95, 0.7, 0.55)
				ray.position = tip
				ray.z_index = 8
				world.add_child(ray)
				var rt := ray.create_tween()
				rt.tween_property(ray, "modulate:a", 0.0, 0.45)
				rt.tween_callback(ray.queue_free))
			_after(0.7, func():
				if not p.is_alive():
					return
				p._anim("volley")
				var n := 8 if mega else 5
				if Balance.arena(p):
					n = 12 if mega else 8             # Арена: больше копий света
				for k in n:
					var s := _throw("beam", Vector2(p.facing * (260.0 + k * (110.0 if mega else 140.0)), -430.0), 12)
					s.big = mega
				Fx.sparks(world, p.global_position + Vector2(p.facing * 30, -20), Color(1.0, 0.85, 0.35), 10, 300.0, 5.0, true))
		"ternovnik":
			# «Пробуждение леса»: вихрь листьев, герой сжимается — и вырастает в Энта
			p._forced_time = 0.95
			p._forced_vx = 0.0
			p._anim("transform")
			Fx.leaf_swirl(world, p, 110.0, 0.9, 22)
			Fx.rune_circle(world, p.global_position + Vector2(0, p.body_size.y / 2), 90.0, Color(0.45, 0.95, 0.35, 0.9), 1.2)
			Fx.glow(world, p.global_position, 80.0, Color(0.4, 1.0, 0.35, 0.3), 1.0)
			_after(0.55, func():
				if not p.is_alive():
					return
				_ent_t = 12.0 if mega else 10.0
				if Balance.arena(p):
					_ent_t += 4.0                    # Арена: форма Энта дольше
				p.set_rig("mini_ent")
				if p._rig_root:
					p._rig_root.scale = Vector2(0.8, 0.8)
					var gt := p._rig_root.create_tween()
					gt.tween_property(p._rig_root, "scale", Vector2(1.5, 1.5), 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
				p.move_mult = 0.6
				p.armor_mult = 0.6
				totem_charges = mini(TOTEM_CHARGES, totem_charges + 1)
				Fx.leaf_burst(world, p.global_position, 30)
				Fx.ring(world, p.global_position + Vector2(0, p.body_size.y / 2), 160.0, Color(0.5, 1.0, 0.4, 0.9), 0.5, 8.0, 0.35)
				Fx.cracks(world, p.global_position + Vector2(0, p.body_size.y / 2), Color(0.3, 0.22, 0.12), 110.0)
				var saplings := 2 if mega else 0
				if Balance.arena(p):
					saplings = 4 if mega else 2          # Арена: деревца и без МЕГА
				for k in saplings:
					_spawn_minion("sapling", p.global_position + Vector2((k % 2 * 2 - 1) * (70.0 + k / 2 * 60.0), 0), 20.0))
			_after(1.0, func():
				if p.is_alive() and _ent_t > 0.0:
					p._anim("roar"))
		"mortis":
			# «Меч Короля»: Мортис поднимает косу, над ним вспыхивает призрачная
			# корона, под ногами — фиолетовый круг; над врагом из тумана
			# появляется огромный меч и вонзается в землю.
			p._forced_time = 0.6
			p._forced_vx = 0.0
			p._anim("invoke")
			Fx.rune_circle(world, p.global_position + Vector2(0, p.body_size.y / 2), 75.0, Color(0.75, 0.45, 1.0, 0.9), 1.0)
			_ghost_crown(world)
			Fx.sparks(world, p.global_position, Color(0.75, 0.5, 1.0), 12, 200.0, 4.0, true)
			_after(0.45, func():
				if not p.is_alive():
					return
				# Арена: мечи падают на трёх ближайших врагов
				var targets: Array = []
				if Balance.arena(p):
					var es := _enemies().filter(func(e): return e.global_position.distance_to(p.global_position) < 1400.0)
					es.sort_custom(func(a, b): return a.global_position.distance_to(p.global_position) < b.global_position.distance_to(p.global_position))
					targets = es.slice(1, 3)
				for extra in targets:
					_king_sword(world, extra, mega)
				var t := _nearest_enemy()
				var at: Vector2 = t.global_position if t else p.global_position + Vector2(p.facing * 300.0, 0)
				var gs := GhostSword.new()
				gs.team = p.team
				gs.attacker = p
				gs.target = t
				gs.mega = mega
				gs.position = at + Vector2(0, -380.0)
				# точно в землю у врага: на том уровне, где он стоит, даже если над ним платформа
				var gh := p.get_world_2d().direct_space_state.intersect_ray(
						PhysicsRayQueryParameters2D.create(at + Vector2(0, -10), at + Vector2(0, 1500), Layer.WORLD | Layer.FRAME))
				gs.ground_y = gh["position"].y if not gh.is_empty() else at.y + 40.0
				world.add_child(gs))

func _after(time: float, fn: Callable) -> void:
	get_tree().create_timer(time).timeout.connect(fn)

func _king_sword(world: Node, t: Player, mega: bool) -> void:
	var at: Vector2 = t.global_position
	var gs := GhostSword.new()
	gs.team = p.team
	gs.attacker = p
	gs.target = t
	gs.mega = mega
	gs.position = at + Vector2(0, -380.0)
	var gh := p.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(at + Vector2(0, -10), at + Vector2(0, 1500), Layer.WORLD | Layer.FRAME))
	gs.ground_y = gh["position"].y if not gh.is_empty() else at.y + 40.0
	world.add_child(gs)

# Призрачная корона над головой Мортиса
func _ghost_crown(world: Node) -> void:
	var c := Polygon2D.new()
	c.polygon = PackedVector2Array([Vector2(-22, 0), Vector2(-22, -18), Vector2(-11, -8), Vector2(0, -26),
			Vector2(11, -8), Vector2(22, -18), Vector2(22, 0)])
	c.color = Color(0.85, 0.65, 1.0, 0.0)
	c.z_index = 9
	c.position = p.global_position + Vector2(0, -p.body_size.y / 2 - 40)
	world.add_child(c)
	var t := c.create_tween()
	t.tween_property(c, "color:a", 0.85, 0.2)
	t.parallel().tween_property(c, "position:y", c.position.y - 30.0, 0.8)
	t.tween_property(c, "color:a", 0.0, 0.3)
	t.tween_callback(c.queue_free)

# ---------- Каждый кадр ----------
func _physics_process(delta: float) -> void:
	if p == null or not p.is_alive():
		return
	if _bash_t > 0.0:
		_bash_t -= delta
		_update_bash()
		if _bash_t <= 0.0 and Balance.arena(p):
			_bash_wave()                         # Арена: таран заканчивается ударной волной
		if _bash_t <= 0.0 and _bash_mega:
			p.set_visual_scale(1.15 if _roar_t > 0.0 else 1.0, 0.2)
	if _roar_t > 0.0:
		_roar_t -= delta
		if _roar_t <= 0.0:
			p.set_visual_scale(1.0)
			if _roar_mega:
				p.armor_mult = 1.0
				p.set_tint(Color.WHITE)
	if _pull_t > 0.0:
		_pull_t -= delta
		if _vine and is_instance_valid(_vine):
			_vine.points = PackedVector2Array([p.global_position, _anchor])
		if _pull_t <= 0.0:
			_end_pull()
	if _ent_t > 0.0:
		_ent_t -= delta
		_smash_t -= delta
		if _smash_t <= 0.0:
			_smash_t = 0.1
			_ent_smash()
		if _ent_t <= 0.0:
			# форма Энта рассыпается листьями
			Fx.leaf_burst(p.get_parent(), p.global_position, 20)
			p.set_rig("ternovnik")
			if p._rig_root:
				p._rig_root.scale = Vector2(1.5, 1.5)
			p.set_visual_scale(1.0, 0.35)
			p.move_mult = 1.0
			p.armor_mult = 1.0
	if _ghost_t > 0.0:
		_ghost_t -= delta
		if Balance.arena(p):
			_ghost_drain(delta)                  # Арена: призрак вытягивает жизнь из врагов рядом
		if _ghost_t <= 0.0:
			_end_ghost()
	_tick_totems(delta)

func on_dealt(amount: int, _victim: Node) -> void:
	if hero == "champion" and _roar_t > 0.0:
		p.heal(3)                                # рёв толпы: лечение за попадания

func on_mega() -> void:
	if hero == "ternovnik" and duel:
		totem_charges = mini(TOTEM_CHARGES, totem_charges + 1)   # МЕГА-бафф возвращает заряд тотема

func on_death() -> void:
	_bash_t = 0.0
	_roar_t = 0.0
	_pull_t = 0.0
	_aiming = -1
	if _arrow:
		_arrow.visible = false
	if _vine and is_instance_valid(_vine):
		_vine.queue_free()
	if _ent_t > 0.0:
		_ent_t = 0.0
		p.set_rig("ternovnik")
	if _ghost_t > 0.0:
		_ghost_t = 0.0
		p.collision_mask = Player.NORMAL_MASK
	p.set_visual_scale(1.0, 0.01)
	p.set_tint(Color.WHITE)
	p.move_mult = 1.0
	p.armor_mult = 1.0
	p.fly_free = false

# ---------- Чемпион ----------
# Арена: в конце тарана щит бьёт о землю — волна перед Чемпионом
func _bash_wave() -> void:
	if not p.is_alive():
		return
	var world := p.get_parent()
	var at := p.global_position + Vector2(p.facing * 70.0, p.body_size.y / 2 - 4.0)
	var r := 190.0 if _bash_mega else 150.0
	for e in _enemies():
		var to: Vector2 = e.global_position - at
		if absf(to.x) < r and absf(to.y) < 120.0 and signf(to.x) != -p.facing:
			e.take_damage(14 if not _bash_mega else 20, p)
			e.velocity = Vector2(p.facing * 480.0, -320.0)
	Fx.ring(world, at, r, Color(1.0, 0.85, 0.45, 0.9), 0.35, 6.0, 0.3)
	Fx.sparks(world, at, Color(1.0, 0.85, 0.5), 12, 260.0, 4.0, true)
	Fx.cracks(world, at, Color(0.35, 0.28, 0.2), 70.0)

func _update_bash() -> void:
	var reach := p.body_size.x * (0.9 if _bash_mega else 0.6) + 20.0
	var front := p.global_position + Vector2(p.facing * reach, 0)
	for e in _enemies():
		if _bash_hit.has(e):
			continue
		if e.global_position.distance_to(front) < 50.0 + e.body_size.x * 0.5 + (30.0 if _bash_mega else 0.0):
			_bash_hit[e] = true
			e.take_damage(15 if not _bash_mega else 24, p)
			e._forced_time = 0.25
			e._forced_vx = p.facing * 900.0
			e._forced_no_gravity = false
			e.velocity.y = -300.0
			var stun_t := 1.8 if _bash_mega else 1.0
			var victim: Player = e
			get_tree().create_timer(0.18).timeout.connect(func():
				if is_instance_valid(victim) and victim.is_alive() and victim.is_on_wall():
					victim.stun(stun_t))             # отбросило в стену — оглушён
	# разрушает блоки на пути (МЕГА — выше и сильнее)
	var hgt := p.body_size.y * (1.4 if _bash_mega else 1.0)
	for n in p.get_parent().get_children():
		if n is Destructible and n.shield_team != p.team and not n.background \
				and n.global_position.distance_to(p.global_position) < 500.0:
			var k := 0.0
			while k < hgt:
				n.hit(front + Vector2(0, p.body_size.y / 2 - 12.0 - k), Vector2(p.facing, 0), 90 if _bash_mega else 40,
						12.0, p.team, {"strict": true, "attacker": p})
				k += 18.0

# ---------- Терновник ----------
func _roots(mega: bool) -> void:
	p._anim("cast")
	if Balance.arena(p):
		# Арена: корни прорастают под тремя ближайшими врагами
		var es := _enemies().filter(func(e): return e.global_position.distance_to(p.global_position) < 900.0)
		es.sort_custom(func(a, b): return a.global_position.distance_to(p.global_position) < b.global_position.distance_to(p.global_position))
		for e in es.slice(0, 3):
			_root_at(e.global_position.x, e.global_position.y - 20.0, mega)
		if not es.is_empty():
			return
	var t := _nearest_enemy(800.0)
	var x: float = t.global_position.x if t else p.global_position.x + p.facing * 300.0
	var from_y: float = (t.global_position.y if t else p.global_position.y) - 20.0
	var hit := p.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, from_y + 900.0), Layer.WORLD))
	if hit.is_empty():
		return
	_spawn_root_spike(hit["position"], mega)

func _root_at(x: float, from_y: float, mega: bool) -> void:
	var hit := p.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(Vector2(x, from_y), Vector2(x, from_y + 900.0), Layer.WORLD))
	if not hit.is_empty():
		_spawn_root_spike(hit["position"], mega)

func _spawn_root_spike(at: Vector2, mega: bool) -> void:
	var r := RootSpike.new()
	r.team = p.team
	r.attacker = p
	r.damage = 8
	r.warn = 0.7
	r.half = 120.0 if mega else 55.0
	r.root_time = 2.4 if mega else 1.2
	r.position = at
	p.get_parent().add_child(r)

func _place_totem(mega: bool) -> void:
	p._anim("summon")
	if duel:
		totem_charges -= 1
	var pos := p.global_position + Vector2(p.facing * 50.0, p.body_size.y / 2 - 40.0)
	var arena := Balance.arena(p)
	var tot := _spawn_minion("totem", pos, (22.0 if mega else 15.0) if arena else (18.0 if mega else 10.0))
	tot.set_meta("shooter", arena)           # Арена: тотем ещё и стреляет семенами-колючками
	tot.max_hp = 120 if mega else 70
	tot.hp = tot.max_hp
	tot.set_meta("tall", mega)
	if mega:
		tot.scale = Vector2(1.0, 1.0)
		tot.set_visual_scale(1.6)
	_totems.append(tot)

func _tick_totems(delta: float) -> void:
	_totems = _totems.filter(func(t): return is_instance_valid(t) and t.is_alive())
	for t in _totems:
		if t.get_meta("shooter", false):
			var st: float = t.get_meta("shot_t", 0.0) - delta
			if st <= 0.0:
				st = 1.6
				_totem_shot(t)
			t.set_meta("shot_t", st)
		var tall: bool = t.get_meta("tall", false)
		var acc: float = t.get_meta("acc", 0.0) + delta
		if acc < 1.0:
			t.set_meta("acc", acc)
			continue
		t.set_meta("acc", 0.0)
		for n in p.get_parent().get_children():
			if n is Player and n.team == p.team and n.is_alive() and not n.is_minion \
					and n.global_position.distance_to(t.global_position) < (300.0 if tall else 220.0):
				n.heal(5 if tall else 3)
				if tall:
					n.boost(1.25, 1.2)            # высокий тотем усиливает урон
				Util.flash(p.get_parent(), n.global_position, 16.0, Color(0.4, 1.0, 0.4, 0.6))

func _totem_shot(t: Player) -> void:
	var from := t.global_position + Vector2(0, -t.body_size.y * 0.35)
	var best: Player = null
	var bd := 750.0
	for e in _enemies():
		var d: float = e.global_position.distance_to(from)
		if d < bd:
			bd = d
			best = e
	if best == null:
		return
	var s := Spear.new()
	s.shooter = p
	s.team = p.team
	s.payload = "thorn"
	s.damage = 8
	s.velocity = Spear.aim(from, best.hurt_center(), clampf(bd / 700.0, 0.3, 1.0))
	s.position = from
	p.get_parent().add_child(s)
	Fx.sparks(p.get_parent(), from, Color(0.5, 1.0, 0.4), 4, 120.0, 3.0)

# Лиана: зажми — над героем качается стрелка; отпусти — лиана летит туда
func _handle_vine(i: int, action: String, delta: float) -> void:
	if _arrow == null:
		_arrow = Polygon2D.new()
		_arrow.polygon = PackedVector2Array([Vector2(0, -5), Vector2(60, -5), Vector2(60, -13), Vector2(84, 0),
				Vector2(60, 13), Vector2(60, 5), Vector2(0, 5)])
		_arrow.color = Color(0.5, 1.0, 0.35, 0.85)
		_arrow.position = Vector2(0, -p.body_size.y / 2 - 6)
		_arrow.visible = false
		p.add_child(_arrow)
	if Input.is_action_just_pressed(action) and p._cd[i] <= 0.0 and _pull_t <= 0.0:
		_aiming = i
		_aim_t = 0.0
	if _aiming != i:
		return
	_aim_t += delta
	var angle := -PI / 2 + sin(_aim_t * 2.6) * 1.45
	_arrow.rotation = angle
	_arrow.visible = true
	if not Input.is_action_pressed(action):
		_aiming = -1
		_arrow.visible = false
		_shoot_vine(Vector2.from_angle(angle), p._mega_ab())
		p._cd[i] = p.ability_cds[i]

func _shoot_vine(dir: Vector2, mega: bool) -> void:
	p._anim("throw")
	var from := p.global_position + Vector2(0, -p.body_size.y / 2)
	var hit := p.get_world_2d().direct_space_state.intersect_ray(
			PhysicsRayQueryParameters2D.create(from, from + dir * 520.0, Layer.WORLD | Layer.FRAME, [p.get_rid()]))
	_anchor = hit["position"] if not hit.is_empty() else from + dir * 520.0   # не нашла блок — цепляется за воздух
	_vine = Line2D.new()
	_vine.width = 5.0
	_vine.default_color = Color(0.3, 0.6, 0.2)
	p.get_parent().add_child(_vine)
	var to := _anchor - p.global_position
	var v := to.normalized() * clampf(to.length() * 3.2, 600.0, 1250.0)
	v.y -= 260.0                       # импульс: взлетает выше точки зацепа
	p._forced_time = 0.3
	p._forced_vx = v.x
	p._forced_no_gravity = false
	p.velocity.y = v.y
	_pull_t = 0.3
	_pull_mega = mega

func _end_pull() -> void:
	if _vine and is_instance_valid(_vine):
		var vn := _vine
		var t := vn.create_tween()
		t.tween_property(vn, "modulate:a", 0.0, 0.2)
		t.tween_callback(vn.queue_free)
	# после подтягивания — склянка яда (МЕГА: несколько во все стороны вниз)
	if _pull_mega or Balance.arena(p):
		var angs := [20.0, 55.0, 90.0, 125.0, 160.0]
		if Balance.arena(p):                     # Арена: 3 склянки (МЕГА — 7)
			angs = [10.0, 35.0, 62.0, 90.0, 118.0, 145.0, 170.0] if _pull_mega else [55.0, 90.0, 125.0]
		for a in angs:
			var d := Vector2.from_angle(deg_to_rad(a))
			_throw("flask", Vector2(d.x * 420.0, d.y * 300.0 - 120.0), 0)
	else:
		_throw("flask", Vector2(p.facing * 430.0, -200.0), 0)

# Форма Энта: крушит всё, к чему притронется сбоку (платформы под ногами целы)
func _ent_smash() -> void:
	var front_x := p.global_position.x + p.facing * (p.body_size.x * 0.75 + 16.0)
	for n in p.get_parent().get_children():
		if n is Destructible and n.shield_team != p.team and not n.background \
				and n.global_position.distance_to(p.global_position) < 500.0:
			var y := -p.body_size.y * 1.1
			while y < p.body_size.y * 0.32:
				n.hit(Vector2(front_x, p.global_position.y + y), Vector2(p.facing, 0), 70, 10.0, p.team,
						{"strict": true, "attacker": p})
				y += 18.0

# ---------- Мортис ----------
func _summon(mega: bool) -> void:
	p._anim("summon")
	Fx.rune_circle(p.get_parent(), p.global_position + Vector2(p.facing * 50.0, p.body_size.y / 2), 50.0, Color(0.7, 0.45, 1.0, 0.85), 0.8)
	_minions = _minions.filter(func(m): return is_instance_valid(m) and m.is_alive())
	# всего не больше 5 призванных скелетов (и в МЕГА-форме тоже)
	var alive := _minions.size()
	var cap := 6 if Balance.arena(p) else 5
	if alive >= cap:
		Util.flash(p.get_parent(), p.global_position, 20.0, Color(1, 0.3, 0.3, 0.6))
		return
	if mega:
		_spawn_minion("skel_sword", p.global_position + Vector2(p.facing * 60.0, 0), 25.0)
		if alive + 1 < cap:
			_spawn_minion("skel_archer", p.global_position + Vector2(-p.facing * 40.0, 0), 25.0)
		if Balance.arena(p) and alive + 2 < cap:      # Арена: ещё один мечник
			_spawn_minion("skel_sword", p.global_position + Vector2(p.facing * 110.0, 0), 25.0)
		return
	var throwers := _minions.filter(func(m): return m.get_meta("kind") == "skel_thrower").size()
	if throwers >= cap:
		Util.flash(p.get_parent(), p.global_position, 20.0, Color(1, 0.3, 0.3, 0.6))
		return
	var count := 2 if Balance.arena(p) and alive + 1 < cap else 1   # Арена: два метателя разом
	for k in count:
		var m := _spawn_minion("skel_thrower", p.global_position + Vector2(p.facing * (50.0 + k * 50.0), 0), 0.0)
		m.max_hp = 25                            # слабый: мало здоровья, умеет только метать кости
		m.hp = 25

func _spawn_minion(kind: String, pos: Vector2, life: float) -> Player:
	var size: Vector2 = Bots.TYPES[kind]["size"]
	var target := _nearest_enemy()
	var b := Bots.create(kind, 1, Vector2(pos.x, pos.y - 30.0), target if target else p, p.map_w)
	b.team = p.team
	b.index = p.index
	b.is_minion = true
	b.minion_owner = p
	b.lifetime = life
	b.team_color = p.team_color
	b.target = target
	b.position = Vector2(pos.x, pos.y + p.body_size.y / 2 - size.y / 2 - 2.0)
	b.add_to_group("allies")
	Balance.inherit(b, p)                 # бьёт с теми же поправками режима, что и хозяин
	p.get_parent().add_child(b)
	Util.flash(p.get_parent(), b.position, size.y * 0.7, Color(0.7, 0.5, 1.0, 0.7) if hero == "mortis" else Color(0.4, 0.9, 0.3, 0.7))
	_minions.append(b)
	return b

var _drain_t := 0.0
func _ghost_drain(delta: float) -> void:
	_drain_t -= delta
	if _drain_t > 0.0:
		return
	_drain_t = 0.3
	for e in _enemies():
		if e.global_position.distance_to(p.global_position) < 120.0 + e.body_size.x * 0.5:
			e.take_damage(6, p)
			p.heal(3)
			var l := Line2D.new()
			l.points = PackedVector2Array([e.global_position, p.global_position])
			l.width = 3.0
			l.default_color = Color(0.75, 0.45, 1.0, 0.7)
			p.get_parent().add_child(l)
			var t := l.create_tween()
			t.tween_property(l, "modulate:a", 0.0, 0.25)
			t.tween_callback(l.queue_free)

func _end_ghost() -> void:
	p.fly_free = false
	p.armor_mult = 1.0
	p.set_tint(Color.WHITE)
	if _ghost_mega:
		p.collision_mask = Player.NORMAL_MASK
		_push_out()

# Если призрак застрял в блоке — выталкиваем наверх (или вбок)
func _push_out() -> void:
	if not p._inside_block():
		return
	var start := p.global_position
	for k in 60:
		for off in [Vector2(0, -20.0 * k), Vector2(20.0 * k, 0), Vector2(-20.0 * k, 0)]:
			p.global_position = start + off
			if not p._inside_block():
				return
	p.global_position = start + Vector2(0, -1200)
