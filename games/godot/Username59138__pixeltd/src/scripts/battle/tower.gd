extends Node2D
## A placed tower. Battle calls update(dt) every fixed tick.

enum Target { FIRST, LAST, STRONG, CLOSE }
const TARGET_NAMES := ["First", "Last", "Strong", "Close"]

var type := ""
var def: Dictionary
var level := 0
var spent := 0
var stats := {}
var target_mode := Target.FIRST
var cooldown := 0.0
var hit_count := 0
var damage_dealt := 0.0
var earned := 0              # farm: money paid out so far
var kills := 0
var tile := Vector2i.ZERO
var battle: Node
var selected := false
var disabled_t := 0.0   # > 0 while buried by a volcano eruption
var buff := 1.0         # damage multiplier from a Holy Champion's aura (Battle.recompute_buffs)

var sprite: Sprite2D
var anim_t := 0.0
var attack_anim := 0.0
var aim := Vector2.RIGHT
var flame_on := 0.0
var flame_tick := 0.0
var dagger_cd := 0.0
# soldier
var burst_left := 0
var spin := 0.0            # minigun: 0 = cold, 1 = fully spun up
var burst_t := 0.0
var burst_count := 0
# garage
var road: Array = []   # [path index, distance] where cars enter the road
var roads: Array = []  # every road next to the garage, a car picks one at random


func setup(t: String, b: Node, cost_paid: int) -> void:
	type = t
	def = Defs.TOWERS[t]
	battle = b
	spent = cost_paid
	sprite = Sprite2D.new()
	add_child(sprite)
	recompute()
	cooldown = 0.2
	if type == "garage":
		road = battle.nearest_road(position)
		roads = battle.nearest_roads(position)
		cooldown = 1.0


func recompute() -> void:
	stats = (def["base"] as Dictionary).duplicate()
	for i in level:
		var up: Dictionary = def["upgrades"][i]
		for k in up["set"]:
			stats[k] = up["set"][k]
	if battle and battle.headless:
		return
	var elite: bool = level >= def["upgrades"].size()
	var name: String = def["sprite"] + ("_elite" if elite else "")
	sprite.texture = Game.tex("res://assets/sprites/towers/%s.png" % name)
	sprite.offset = Vector2(0, base_offset_y(sprite.texture))
	queue_redraw()


## Keeps a sprite's feet on the same spot whatever its height (old sprites were 18 px tall).
static func base_offset_y(tex: Texture2D) -> float:
	if tex == null:
		return -3.0
	return -3.0 - maxf(0.0, (tex.get_height() - 18) / 2.0)


func max_level() -> int:
	return def["upgrades"].size()


func next_upgrade() -> Dictionary:
	if level >= max_level():
		return {}
	return def["upgrades"][level]


func range_px() -> float:
	return float(stats["range"])


# ---------------------------------------------------------------- targeting
## Flying enemies need "air", invisible ones need "camo" to be aimed at.
func can_target(e) -> bool:
	if not e.targetable():
		return false
	if e.flying and not stats.get("air", false):
		return false
	if e.invisible and not stats.get("camo", false):
		return false
	if e.lead and not stats.get("lead", false):
		return false
	return true


func pick_targets(enemies: Array, count: int, skip_doomed := false) -> Array:
	var r2 := range_px() * range_px()
	var cands: Array = []
	for e in enemies:
		if can_target(e) and e.position.distance_squared_to(position) <= r2:
			if skip_doomed and e.hp - e.incoming <= 0.0:
				continue
			cands.append(e)
	if cands.is_empty():
		return []
	match target_mode:
		Target.FIRST:
			cands.sort_custom(func(a, b): return a.remaining() < b.remaining())
		Target.LAST:
			cands.sort_custom(func(a, b): return a.remaining() > b.remaining())
		Target.STRONG:
			cands.sort_custom(func(a, b): return a.hp > b.hp if a.cls == b.cls else a.cls > b.cls)
		Target.CLOSE:
			cands.sort_custom(func(a, b): return a.position.distance_squared_to(position) < b.position.distance_squared_to(position))
	return cands.slice(0, count)


func update(dt: float, enemies: Array) -> void:
	anim_t += dt
	if disabled_t > 0.0:
		disabled_t -= dt
		burst_left = 0
		_update_visual()
		return
	cooldown -= dt
	if attack_anim > 0.0:
		attack_anim -= dt
	if flame_on > 0.0:
		flame_on -= dt
	match type:
		"gunner":
			_update_gunner(enemies)
		"knight":
			_update_knight(enemies)
		"flamer":
			_update_flamer(dt, enemies)
		"freezer":
			_update_freezer(dt, enemies)
		"toxic":
			_update_toxic(enemies)
		"assassin":
			_update_assassin(dt, enemies)
		"soldier":
			_update_soldier(dt, enemies)
		"garage":
			_update_garage(enemies)
		"sniper":
			_update_sniper(enemies)
		"minigun":
			_update_minigun(dt, enemies)
		"necro":
			_update_necro(enemies)
	_update_visual()


func _face(p: Vector2) -> void:
	var d := p - position
	if d.length() > 0.5:
		aim = d.normalized()


func _muzzle() -> Vector2:
	return position + Vector2(7 * (1.0 if aim.x >= 0 else -1.0), -4)


func _update_gunner(enemies: Array) -> void:
	if cooldown > 0.0:
		return
	var ts := pick_targets(enemies, int(stats["targets"]), true)
	if ts.is_empty():
		return
	cooldown = 1.0 / float(stats["rate"])
	_face(ts[0].position)
	for e in ts:
		battle.spawn_bullet(self, _muzzle(), e, float(stats["damage"]), float(stats["slow"]), float(stats["slow_time"]))
	attack_anim = 0.08
	battle.fx_muzzle(_muzzle() + Vector2(aim.x, 0))
	Sfx.play("shot", 0.1)


## Spins up while it has something to shoot: the fire rate climbs from min_rate to max_rate over spin_time,
## and winds down twice as fast once nothing is in range.
func _update_minigun(dt: float, enemies: Array) -> void:
	var ts := pick_targets(enemies, 1, true)
	if ts.is_empty():
		spin = maxf(0.0, spin - dt * 2.0 / float(stats["spin_time"]))
		cooldown = maxf(cooldown, 0.0)
		return
	spin = minf(1.0, spin + dt / float(stats["spin_time"]))
	_face(ts[0].position)
	var rate := lerpf(float(stats["min_rate"]), float(stats["max_rate"]), spin)
	var shots := 0
	while cooldown <= 0.0 and shots < 4:   # high rates fire several bullets in one tick
		cooldown += 1.0 / rate
		shots += 1
		battle.spawn_bullet(self, _muzzle() + Vector2(0, 2), ts[0], float(stats["damage"]), 0.0, 0.0,
			float(stats["armor_pierce"]), Color("feae34") if level >= max_level() else Color("fee761"))
	if shots > 0:
		attack_anim = 0.05
		if randf() < 0.3:   # visual only: battle.rng stays for the game rules
			battle.fx_muzzle(_muzzle() + Vector2(aim.x, 2))
		Sfx.play("shot", 0.1)


func _update_soldier(dt: float, enemies: Array) -> void:
	if burst_left > 0:
		burst_t -= dt
		if burst_t <= 0.0:
			var ts := pick_targets(enemies, 1, true)
			if ts.is_empty():
				ts = pick_targets(enemies, 1)
			if ts.is_empty():
				burst_left = 0
				return
			burst_t = float(stats["burst_gap"])
			burst_left -= 1
			_face(ts[0].position)
			battle.spawn_bullet(self, _muzzle(), ts[0], float(stats["damage"]), 0.0, 0.0, float(stats["armor_pierce"]))
			attack_anim = 0.05
			battle.fx_muzzle(_muzzle() + Vector2(aim.x, 0))
			Sfx.play("shot", 0.2)
		return
	if cooldown > 0.0:
		return
	var ts := pick_targets(enemies, 1)
	if ts.is_empty():
		return
	cooldown = 1.0 / float(stats["rate"])
	burst_left = int(stats["burst"])
	burst_t = 0.0
	burst_count += 1
	var ge := int(stats["grenade_every"])
	if ge > 0 and burst_count % ge == 0:
		var e = ts[0]
		var lead: Vector2 = battle.path_point(e.path_i, maxf(0.0, e.dist + e.current_speed() * 0.45))[0]
		battle.spawn_grenade(self, position + Vector2(0, -6), lead, float(stats["grenade_dmg"]),
			float(stats["grenade_radius"]))


func _update_knight(enemies: Array) -> void:
	if cooldown > 0.0:
		return
	var ts := pick_targets(enemies, 1)
	if ts.is_empty():
		return
	cooldown = 1.0 / float(stats["rate"])
	_face(ts[0].position)
	hit_count += 1
	var stun_now: bool = int(stats["stun_every"]) > 0 and hit_count % int(stats["stun_every"]) == 0
	var victims: Array = ts
	if stats["cleave"]:
		victims = pick_targets(enemies, 999)
	for e in victims:
		battle.damage_enemy(e, float(stats["damage"]), "physical", self, float(stats["armor_pierce"]))
		if stun_now and e.alive:
			e.apply_stun(float(stats["stun"]))
	attack_anim = 0.18
	battle.fx_slash(position + Vector2(0, -3), aim, range_px(), bool(stats["cleave"]), stun_now)
	Sfx.play("slash", 0.15)


func _update_flamer(dt: float, enemies: Array) -> void:
	flame_tick -= dt
	if flame_tick > 0.0:
		return
	var ts := pick_targets(enemies, 1)
	if ts.is_empty():
		return
	flame_tick = 0.1
	_face(ts[0].position)
	flame_on = 0.15
	var half_cone := deg_to_rad(float(stats["cone"]) * 0.5)
	var r := range_px()
	var origin := position + Vector2(0, -2)
	for e in enemies:
		# the flames can't reach flyers, but they do burn invisible enemies standing in them
		if not e.targetable() or e.flying:
			continue
		var d: Vector2 = e.position - origin
		if d.length() > r + e.radius:
			continue
		if d.length() > 6.0 and absf(aim.angle_to(d)) > half_cone:
			continue
		battle.damage_enemy(e, float(stats["damage"]), "fire", self, float(stats["fire_pierce"]))
		if e.alive:
			e.apply_burn(float(stats["burn"]), float(stats["burn_time"]), float(stats["fire_pierce"]), self)
			if e.thaw():
				battle.fx_steam(e, "MELT")
	battle.fx_flame(position + Vector2(6 * (1.0 if aim.x >= 0 else -1.0), -3), aim, r, half_cone,
		level >= max_level())
	Sfx.play("flame", 0.1)


## Water cone like the flamethrower's: chills (and later hurts) everything in it, puts out burning enemies.
func _update_freezer(dt: float, enemies: Array) -> void:
	flame_tick -= dt
	if flame_tick > 0.0:
		return
	var ts := pick_targets(enemies, 1)
	if ts.is_empty():
		return
	flame_tick = 0.1
	_face(ts[0].position)
	flame_on = 0.15
	var half_cone := deg_to_rad(float(stats["cone"]) * 0.5)
	var r := range_px()
	var origin := position + Vector2(0, -2)
	var dmg := float(stats["damage"])
	for e in enemies:
		# water can't reach flyers or lead, but it does soak invisible enemies standing in it
		if not e.targetable() or e.flying or e.lead:
			continue
		var d: Vector2 = e.position - origin
		if d.length() > r + e.radius:
			continue
		if d.length() > 6.0 and absf(aim.angle_to(d)) > half_cone:
			continue
		if e.burn_t > 0.0:
			e.burn_t = 0.0
			e.burn_dps = 0.0
			battle.fx_steam(e, "FSSS")
		if dmg > 0.0:
			battle.damage_enemy(e, dmg, "cold", self)
			if not e.alive:
				continue
		if e.apply_chill(float(stats["chill"]), 0.1, float(stats["chill_slow"]), float(stats["freeze"]),
				float(stats.get("brittle", 0.0))):
			battle.fx_freeze(e)
	battle.fx_spray(position + Vector2(6 * (1.0 if aim.x >= 0 else -1.0), -3), aim, r, half_cone,
		level >= max_level())
	Sfx.play("spray", 0.1)


func _update_sniper(enemies: Array) -> void:
	if cooldown > 0.0:
		return
	var ts := pick_targets(enemies, 1, true)
	if ts.is_empty():
		return
	var e = ts[0]
	cooldown = 1.0 / float(stats["rate"])
	_face(e.position)
	var from := position + Vector2(10 * (1.0 if aim.x >= 0 else -1.0), -3)
	var to: Vector2 = e.position + Vector2(0, -4 + (e.sprite.position.y if e.sprite else 0.0))
	attack_anim = 0.15
	var hs := float(stats.get("headshot", 0.0))
	if hs > 0.0 and e.cls < 4 and battle.rng.randf() < hs:
		battle.damage_enemy(e, e.hp + 1.0, "pure", self)
		battle.add_text(e.position + Vector2(0, -14), "HEADSHOT", Color("e43b44"))
	else:
		battle.damage_enemy(e, float(stats["damage"]), "physical", self, float(stats["armor_pierce"]))
	battle.fx_tracer(from, to, level >= max_level())
	Sfx.play("snipe", 0.05)


## Dark bolt; an enemy killed by it is raised by Battle as friendly undead.
func _update_necro(enemies: Array) -> void:
	if cooldown > 0.0:
		return
	var ts := pick_targets(enemies, 1, true)
	if ts.is_empty():
		return
	cooldown = 1.0 / float(stats["rate"])
	_face(ts[0].position)
	battle.spawn_bullet(self, position + Vector2(6 * (1.0 if aim.x >= 0 else -1.0), -12), ts[0],
		float(stats["damage"]), 0.0, 0.0, float(stats["armor_pierce"]), Color("b25aff"))
	attack_anim = 0.12
	Sfx.play("shot", 0.1)


func _acid() -> Dictionary:
	return {"dps": float(stats["acid_dps"]), "time": float(stats["acid_time"]), "shred": float(stats["acid_shred"]),
		"splash": float(stats.get("splash", 0.0))}


func _update_toxic(enemies: Array) -> void:
	if cooldown > 0.0:
		return
	var ts := pick_targets(enemies, 1)
	if ts.is_empty():
		return
	cooldown = 1.0 / float(stats["rate"])
	_face(ts[0].position)
	battle.spawn_bullet(self, _muzzle(), ts[0], float(stats["damage"]), 0.0, 0.0, 0.0, Color("63c74d"), _acid())
	attack_anim = 0.08
	Sfx.play("shot", 0.1)


## Fast poisoned melee on the ground; from Throwing Daggers on also daggers at range, which reach flyers.
func _update_assassin(dt: float, enemies: Array) -> void:
	dagger_cd -= dt
	if int(stats["daggers"]) > 0 and dagger_cd <= 0.0:
		var r2 := float(stats["dagger_range"]) * float(stats["dagger_range"])
		var cands: Array = enemies.filter(func(e): return e.targetable() and (stats["camo"] or not e.invisible) \
			and (stats.get("lead", false) or not e.lead) \
			and e.position.distance_squared_to(position) <= r2 and e.hp - e.incoming > 0.0)
		# flyers first: the blades can't reach them
		cands.sort_custom(func(a, b): return a.flying and not b.flying if a.flying != b.flying \
			else a.remaining() < b.remaining())
		if not cands.is_empty():
			dagger_cd = 1.0 / float(stats["dagger_rate"])
			var acid := _acid()
			acid["splash"] = 0.0
			for e in cands.slice(0, int(stats["daggers"])):
				battle.spawn_bullet(self, position + Vector2(0, -8), e, float(stats["dagger_dmg"]), 0.0, 0.0,
					float(stats["armor_pierce"]), Color("c0cbdc"), acid)
			Sfx.play("shot", 0.15)
	if cooldown > 0.0:
		return
	var ts := pick_targets(enemies, 1)
	if ts.is_empty():
		return
	cooldown = 1.0 / float(stats["rate"])
	_face(ts[0].position)
	battle.damage_enemy(ts[0], float(stats["damage"]), "physical", self, float(stats["armor_pierce"]))
	if ts[0].alive:
		var acid := _acid()
		acid["splash"] = 0.0
		battle.splash_acid(ts[0], acid, self)
	attack_anim = 0.1
	battle.fx_slash(position + Vector2(0, -3), aim, range_px() * 0.8, false, false)
	Sfx.play("slash", 0.2)


func _update_garage(enemies: Array) -> void:
	if cooldown > 0.0 or road.is_empty():
		return
	if not battle.has_hostiles():
		return
	cooldown = float(stats["interval"])
	attack_anim = 0.4
	battle.spawn_friendly(self)


func _update_visual() -> void:
	if battle.headless:
		return
	if type not in ["garage", "farm"]:
		sprite.flip_h = aim.x < -0.05
	var off := Vector2(0, base_offset_y(sprite.texture))
	if attack_anim > 0.0:
		match type:
			"gunner", "soldier", "toxic", "minigun":
				off.x -= signf(aim.x) * 1.0
			"sniper":
				off.x -= signf(aim.x) * 2.0
			"necro":
				off.y -= 1.0
			"knight", "assassin":
				off += (aim * 2.0).round()
			"garage":
				off.y += float(int(anim_t * 20.0) % 2)
	if type in ["flamer", "freezer"] and flame_on > 0.0:
		off.y += float(int(anim_t * 30.0) % 2)
	sprite.offset = off
	sprite.modulate = Color(0.55, 0.35, 0.35) if disabled_t > 0.0 else Color.WHITE
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-5, 4, 10, 2), Color(0, 0, 0, 0.3))
	if float(stats.get("aura", 0.0)) > 0.0:   # Holy Champion: faint golden ring where the aura reaches
		draw_arc(Vector2(0, 2), Battle.AURA_RANGE, 0.0, TAU, 48, Color(1.0, 0.85, 0.35, 0.25), 1.0)
	if disabled_t > 0.0:
		var blink := int(anim_t * 6.0) % 2 == 0
		draw_rect(Rect2(-8, -14, 16, 1), Color("f77622") if blink else Color("a22633"))
	if selected:
		var t := int(anim_t * 4.0) % 2
		var c := Color("fee761")
		var s := 8 + t
		for p in [Vector2(-s, -s - 2), Vector2(s - 2, -s - 2), Vector2(-s, s - 2), Vector2(s - 2, s - 2)]:
			draw_rect(Rect2(p, Vector2(2, 2)), c)
