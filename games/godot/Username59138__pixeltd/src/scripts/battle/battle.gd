class_name Battle
extends Node2D
## The battlefield: map, paths, waves, towers, enemies, projectiles and effects.
## All gameplay runs in tick(dt) with a fixed step so speed-up and headless simulation behave the same.

const EnemyScript = preload("res://scripts/battle/enemy.gd")
const TowerScript = preload("res://scripts/battle/tower.gd")
const DrawNode = preload("res://scripts/battle/draw_node.gd")

const STEP := 1.0 / 60.0
const TILE := 16
const COLS := 32
const ROWS := 22
const BULLET_SPEED := 320.0
const AURA_RANGE := 48.0   # Holy Champion's damage aura

signal stats_changed
signal ended(win: bool, newly_unlocked: Array)
signal announce(text: String, color: Color)
signal selection_changed

const FX_COLORS := {"slime": Color("63c74d"), "rat": Color("8b9bb4"), "goblin": Color("63c74d"),
	"wolf": Color("5a6988"), "ironclad": Color("c0cbdc"), "imp": Color("e43b44"), "shaman": Color("68386c"),
	"slime_king": Color("0099db"), "ogre": Color("e4a672"), "golem": Color("8b9bb4"), "demon": Color("a22633"),
	"bat": Color("68386c"), "ghost": Color("e8eef8"), "harpy": Color("8a4e3e"), "skeleton": Color("ead4aa"),
	"berserker": Color("647d3c"), "troll": Color("5c8c74"), "wraith": Color("483c6c"), "gargoyle": Color("7c748e"),
	"dark_knight": Color("42405a"), "mammoth": Color("86543c"), "bone_dragon": Color("ead4aa")}

var continued := false
var cheated := false   # a cheat was used: a win is not written to the save (unless --save-fake)
var demo := false
var headless := false
var map_id := ""
var map: Dictionary
var diff_idx := 1
var diff: Dictionary
var paths: Array = []
var blocked := {}
var towers := {}
var enemies: Array = []
var bullets: Array = []
var particles: Array = []
var texts: Array = []
var slashes: Array = []
var grenades: Array = []
var tracers: Array = []
var seen_types := {}
var rng := RandomNumberGenerator.new()
var path_tiles := {}
var lava_tiles: Array = []
var eruption_t := -1.0
var eruption_warn: Array = []   # tiles about to be hit
var eruption_warn_t := 0.0

var cash := 0
var lives := 0
var wave := 0
var total_waves := 0
var endless_mult := 1.0   # waves after Continue start from the strength of the last handmade wave
var spawn_queue: Array = []
var wave_t := 0.0
var spawning := false
var bonus_pending := false
var wave_seed := 1
var speed := 1
var paused := false
var over := false
var auto_start := false
var auto_t := -1.0
var kills := 0
var leaked := 0
var time_total := 0.0

var placing := ""
var hover_tile := Vector2i(-1, -1)
var selected: Node2D = null
var hovered_tower: Node2D = null

var _acc := 0.0
var _spawn_counter := 0
var _demo_t := 0.0
var _demo_boss_t := 25.0

var bg: Sprite2D
var under: Node2D
var ents: Node2D
var over_layer: Node2D

func setup(p_map_id: String, p_diff: int, p_demo := false) -> void:
	demo = p_demo
	map_id = p_map_id
	map = MapsData.MAPS[map_id]
	diff_idx = p_diff
	diff = Defs.DIFFICULTIES[diff_idx]
	cash = int(diff["cash"])
	lives = int(diff["lives"])
	total_waves = Waves.count(diff["id"])
	wave_seed = int(map["seed_idx"]) * 10 + diff_idx + 3   # fixed per map, so adding maps never changes waves
	endless_mult = Waves.endless_factor(diff, wave_seed)
	rng.seed = wave_seed
	for pts in map["paths"]:
		var cum := PackedFloat32Array([0.0])
		var total := 0.0
		for i in range(1, pts.size()):
			total += (pts[i] as Vector2).distance_to(pts[i - 1])
			cum.append(total)
		paths.append({"pts": pts, "cum": cum, "len": total})
		for i in range(1, pts.size()):
			var a := Vector2i(floori(pts[i - 1].x / TILE), floori(pts[i - 1].y / TILE))
			var b := Vector2i(floori(pts[i].x / TILE), floori(pts[i].y / TILE))
			var step := Vector2i(signi(b.x - a.x), signi(b.y - a.y))
			var c := a
			path_tiles[c] = true
			while c != b:
				c += step
				path_tiles[c] = true
	lava_tiles = map.get("lava", [])
	var rows: Array = map["blocked"]
	for y in rows.size():
		var r: String = rows[y]
		for x in r.length():
			if r[x] == "1":
				blocked[Vector2i(x, y)] = true
	if headless:
		return
	bg = Sprite2D.new()
	bg.texture = Game.tex(Game.map_bg(map_id))
	bg.centered = false
	add_child(bg)
	under = DrawNode.new()
	under.draw_fn = _draw_under
	add_child(under)
	ents = Node2D.new()
	ents.y_sort_enabled = true
	add_child(ents)
	over_layer = DrawNode.new()
	over_layer.draw_fn = _draw_over
	over_layer.z_index = 5
	add_child(over_layer)
	if demo:
		_setup_demo()


# ---------------------------------------------------------------- helpers
func cost_of(base: int) -> int:
	return int(roundf(base * float(diff["cost"]) / 5.0) * 5.0)


func tower_cost(t: String) -> int:
	return cost_of(int(Defs.TOWERS[t]["cost"]))


func upgrade_cost(tw: Node2D) -> int:
	var up: Dictionary = tw.next_upgrade()
	if up.is_empty():
		return 0
	return cost_of(int(up["cost"]))


func sell_value(tw: Node2D) -> int:
	return int(tw.spent * float(diff["sell"]))


## HP multiplier of the generated waves (after Continue) and of the menu diorama.
func hp_mult() -> float:
	return float(diff["hp"]) * Defs.enemy_hp_scale(maxi(wave, 1)) * \
		(endless_mult if wave > total_waves else 1.0)


func path_point(pi: int, d: float) -> Array:
	var p: Dictionary = paths[pi]
	var pts: Array = p["pts"]
	var cum: PackedFloat32Array = p["cum"]
	d = clampf(d, 0.0, p["len"])
	for i in range(1, pts.size()):
		if d <= cum[i]:
			var seg: float = cum[i] - cum[i - 1]
			var t := 0.0 if seg <= 0.0 else (d - cum[i - 1]) / seg
			var a: Vector2 = pts[i - 1]
			var b: Vector2 = pts[i]
			return [a.lerp(b, t), (b - a).normalized()]
	return [pts[pts.size() - 1], Vector2.RIGHT]


func tile_center(t: Vector2i) -> Vector2:
	return Vector2(t.x * TILE + 8, t.y * TILE + 8)


func can_place(t: Vector2i, type := "") -> bool:
	if not (t.x >= 0 and t.y >= 0 and t.x < COLS and t.y < ROWS and not blocked.has(t) and not towers.has(t)):
		return false
	if type == "garage":
		return next_to_road(t)
	return true


func next_to_road(t: Vector2i) -> bool:
	for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		if path_tiles.has(t + d):
			return true
	return false


## Closest point of any road to p: [path index, distance along that path]
var _road_cache := {}


func nearest_road(p: Vector2) -> Array:
	var key := Vector2i(p.round())
	if _road_cache.has(key):
		return _road_cache[key]
	var best := []
	var bd := 1e9
	for pi in paths.size():
		var d := 0.0
		while d < paths[pi]["len"]:
			var q: Vector2 = path_point(pi, d)[0]
			var dd := q.distance_squared_to(p)
			if dd < bd:
				bd = dd
				best = [pi, d]
			d += 4.0
	_road_cache[key] = best
	return best


## Every road passing as close to p as the nearest one (roads that merge share their tail):
## [[path index, distance], ...]. Garages send each car down one of them at random.
func nearest_roads(p: Vector2) -> Array:
	var best: Array = nearest_road(p)
	if best.is_empty():
		return []
	var bd: float = path_point(best[0], best[1])[0].distance_to(p)
	var res: Array = [best]
	for pi in paths.size():
		if pi == best[0]:
			continue
		var bq := []
		var bqd := 1e9
		var d := 0.0
		while d < paths[pi]["len"]:
			var dd: float = path_point(pi, d)[0].distance_to(p)
			if dd < bqd:
				bqd = dd
				bq = [pi, d]
			d += 4.0
		if bqd <= bd + 2.0:
			res.append(bq)
	return res


func enemy_at(p: Vector2) -> Node2D:
	var best: Node2D = null
	var bd := 1e9
	for e in enemies:
		if not e.alive:
			continue
		var c: Vector2 = e.position + Vector2(0, -e.radius + 3 - (EnemyScript.FLY_HEIGHT if e.flying else 0.0))
		var d := c.distance_to(p)
		if d <= e.radius + 3 and d < bd:
			bd = d
			best = e
	return best


# ---------------------------------------------------------------- main loop
func _process(delta: float) -> void:
	if headless:
		return
	if not paused and not over:
		_acc += minf(delta, 0.1) * speed
		var n := 0
		while _acc >= STEP and n < 20:
			tick(STEP)
			_acc -= STEP
			n += 1
	elif over:
		_tick_fx(delta)
	_update_hover()
	under.queue_redraw()
	over_layer.queue_redraw()


func tick(dt: float) -> void:
	time_total += dt
	if demo:
		_tick_demo(dt)
	else:
		_tick_waves(dt)
	_tick_enemies(dt)
	for tw in towers.values():
		tw.update(dt, enemies)
	_tick_bullets(dt)
	_tick_grenades(dt)
	_tick_fx(dt)
	# cleanup
	if enemies.any(func(e): return not e.alive):
		var keep: Array = []
		for e in enemies:
			if e.alive:
				keep.append(e)
			else:
				e.queue_free()
		enemies = keep
	if not demo and not over:
		_check_round()


func _tick_waves(dt: float) -> void:
	if spawning:
		wave_t += dt
		while not spawn_queue.is_empty() and spawn_queue[0][0] <= wave_t:
			var s: Array = spawn_queue.pop_front()
			# handmade waves: 1 or BLOATED_HP; generated ones (-1) use hp_mult()
			var e := spawn_enemy(s[1], _spawn_counter % paths.size(), 0.0, s[2], false, {}, s[3])
			if wave == total_waves and Defs.BOSS_TYPES.has(s[1]):
				e.final_boss = true
			_spawn_counter += 1
		if spawn_queue.is_empty():
			spawning = false
	_tick_eruption(dt)
	if auto_t >= 0.0:
		auto_t -= dt
		if auto_t < 0.0 and can_start_wave():
			start_wave()


func _check_round() -> void:
	if not spawning and not has_hostiles() and bonus_pending:
		_award_bonus()
		if wave >= total_waves and not continued:
			_finish(true)
			return
		if auto_start:
			auto_t = 1.0


func _award_bonus() -> void:
	bonus_pending = false
	if not headless and not demo:
		Music.set_boss(false)   # the wave is over, boss or not
	var b := roundi(Defs.wave_bonus(wave) * diff["bonus_multi"])
	cash += b
	add_text(Vector2(256, 40), "+$%d wave bonus" % b, Color("fee761"))
	# farms pay at the end of every wave
	for tw in towers.values():
		var inc := int(tw.stats.get("income", 0))
		if inc > 0:
			cash += inc
			tw.earned += inc
			add_text(tw.position + Vector2(0, -18), "+$%d" % inc, Color("63c74d"))
	stats_changed.emit()


func can_start_wave() -> bool:
	return not over and ((wave < total_waves) or continued) and not spawning and not demo


func start_wave(skip_wave := false) -> void:
	if over or demo or (not skip_wave and not can_start_wave()):
		return
	if skip_wave:
		cheated = true
	if bonus_pending:
		_award_bonus()
	wave += 1
	var w := Waves.build(diff["id"], wave)
	if w.is_empty():   # past the handmade list (Continue): the generator takes over
		w = Defs.build_wave(wave, total_waves, wave_seed)
		for sp in w["spawns"]:
			sp.append_array([-1.0, []])
	if spawning:
		# skipped mid-wave: the rest of the current wave still comes, the new one starts now
		for sp in w["spawns"]:
			spawn_queue.append([sp[0] + wave_t, sp[1], sp[2], sp[3]])
		spawn_queue.sort_custom(func(a, b): return a[0] < b[0])
	else:
		spawn_queue = w["spawns"]
		wave_t = 0.0
	spawning = true
	bonus_pending = true
	auto_t = -1.0
	if not lava_tiles.is_empty() and wave % 2 == 0:
		eruption_t = randf_range(4.0, 9.0)
	# warn about the first invisible / flying enemies of the run, and the first lead ones
	var warn := ""
	for sp in spawn_queue:
		var d: Dictionary = Defs.ENEMIES[sp[1]]
		var tag := "INVISIBLE" if d.get("invisible", false) else ("FLYING" if d.get("flying", false) else "")
		if tag != "" and not seen_types.has(sp[1]):
			warn = "%s: %s!" % [String(d["name"]).to_upper(), tag]
		seen_types[sp[1]] = true
		if (sp[3] as Array).has("lead") and not seen_types.has("*lead"):
			warn = "LEAD ENEMIES!"
			seen_types["*lead"] = true
	if w["boss"]:
		announce.emit("BOSS WAVE %d!" % wave, Color("e43b44"))
		if not headless:
			Music.set_boss(true)
	elif warn != "":
		announce.emit("WAVE %d - %s" % [wave, warn], Color("b25aff"))
	else:
		announce.emit("WAVE %d" % wave, Color("fee761"))
	Sfx.play("wave")
	stats_changed.emit()


## mods: wave modifiers, "bloated" and / or "lead".
func spawn_enemy(t: String, pi: int, at_dist := 0.0, mult := -1.0, is_friendly := false, stats := {},
		mods := []) -> Node2D:
	var e := EnemyScript.new()
	e.is_friendly = is_friendly
	e.stats = stats
	e.bloated = mods.has("bloated")
	e.lead = mods.has("lead")
	if mult < 0.0:
		mult = hp_mult()
		if Defs.BOSS_TYPES.has(t):
			mult = float(diff["hp"])
	e.setup(t, mult, pi, paths[pi]["len"])
	e.dist = at_dist
	var pp := path_point(pi, at_dist)
	e.position = pp[0]
	enemies.append(e)
	if not headless:
		ents.add_child(e)
	return e


func _tick_enemies(dt: float) -> void:
	for e in enemies:
		if not e.alive:
			continue
		if e.is_friendly:
			_tick_friendly(e, dt)
			continue
		e.tick_status(dt)
		if e.burn_t > 0.0:
			e.burn_t -= dt
			var src: Node = e.burn_src if is_instance_valid(e.burn_src) else null
			damage_enemy(e, e.burn_dps * dt, "fire", src, e.burn_pierce, false)
			if not e.alive:
				continue
			if e.burn_t <= 0.0:
				e.burn_dps = 0.0
			elif not headless and randf() < dt * 10.0:
				_spawn_particle(e.position + Vector2(randf_range(-4, 4), -randf_range(2, 10)), Vector2(0, -14),
					0.45, Color("f77622") if randf() < 0.6 else Color("fee761"), 1)
		if e.acid_t > 0.0:
			e.acid_t -= dt
			var asrc: Node = e.acid_src if is_instance_valid(e.acid_src) else null
			damage_enemy(e, e.acid_dps * dt, "acid", asrc, 0.0, false)
			if not e.alive:
				continue
			if e.acid_t <= 0.0:
				e.acid_dps = 0.0
				e.acid_shred = 0.0
			elif not headless and randf() < dt * 9.0:   # green bubbles
				_spawn_particle(e.position + Vector2(randf_range(-4, 4), -randf_range(1, 9)), Vector2(0, -10),
					0.5, Color("63c74d") if randf() < 0.6 else Color("b6f08c"), 2 if randf() < 0.3 else 1)
		# slowed: grey specks dropping off like dead weight
		if not headless and e.slow_t > 0.0 and randf() < dt * 10.0:
			_spawn_particle(e.position + Vector2(randf_range(-4, 4), -randf_range(4, 10)),
				Vector2(0, 14), 0.45, Color("c0cbdc"), 1)
		# enraged berserker: angry red sparks shooting up
		if not headless and e.is_enraged() and randf() < dt * 16.0:
			_spawn_particle(e.position + Vector2(randf_range(-4, 4), -randf_range(8, 14)),
				Vector2(randf_range(-6, 6), -30), 0.35, Color("e43b44") if randf() < 0.7 else Color("fee761"),
				2 if randf() < 0.4 else 1)
		# frost drifting off chilled and frozen enemies
		if not headless and (e.chill > 0.0 or e.frozen_t > 0.0) and randf() < dt * (3.0 + 12.0 * e.chill + (6.0 if e.frozen_t > 0.0 else 0.0)):
			_spawn_particle(e.position + Vector2(randf_range(-5, 5), -randf_range(0, 12)),
				Vector2(randf_range(-4, 4), 6), 0.6, Color("e8f8ff") if randf() < 0.5 else Color("8bd8f0"), 1)
		# troll: grows back, except while fire or acid keeps the wounds open
		if e.def.has("regen") and e.hp < e.max_hp and e.downed_t <= 0.0 and e.burn_t <= 0.0 and e.acid_t <= 0.0:
			e.hp = minf(e.max_hp, e.hp + e.max_hp * float(e.def["regen"]) * dt)
			if not headless and randf() < dt * 4.0:
				_spawn_particle(e.position + Vector2(randf_range(-5, 5), -randf_range(2, 12)), Vector2(0, -12), 0.5,
					Color("63c74d") if randf() < 0.5 else Color("b6f08c"), 1)
		if e.def.has("heal"):
			e.heal_cd -= dt
			if e.heal_cd <= 0.0:
				e.heal_cd = 2.5
				_shaman_heal(e)
		e.dist += e.current_speed() * dt
		if e.dist >= e.path_len:
			_leak(e)
			continue
		var pp := path_point(e.path_i, e.dist)
		e.position = pp[0]
		if not headless:
			e.update_visual(pp[1])


## A green plus floats up from a healed enemy, with a few sparkles.
func _fx_healed(e: Node2D) -> void:
	if headless:
		return
	var p: Vector2 = e.position + Vector2(randf_range(-3, 3), -8)
	var v := Vector2(0, -16)
	for d in [Vector2.ZERO, Vector2(-1, 0), Vector2(1, 0), Vector2(0, -1), Vector2(0, 1)]:
		_spawn_particle(p + d, v, 0.6, Color("63c74d"), 1)
	for i in 3:
		_spawn_particle(e.position + Vector2(randf_range(-5, 5), -randf_range(0, 10)),
			Vector2(randf_range(-4, 4), -randf_range(10, 20)), 0.45, Color("b6f08c"), 1)


# ---------------------------------------------------------------- cheats (pause menu, dev flag --cheats)
## Removes every enemy on the field without paying their bounty.
func cheat_clear_enemies() -> void:
	cheated = true
	for e in enemies:
		if not e.is_friendly:
			e.alive = false
	bullets.clear()
	grenades.clear()


## Drops the current wave and starts wave n right away (enemies get wave n's HP).
func cheat_jump_to_wave(n: int) -> void:
	cheat_clear_enemies()
	spawn_queue = []
	spawning = false
	bonus_pending = false
	auto_t = -1.0
	wave = clampi(n, 1, total_waves) - 1
	start_wave(true)


func cheat_win() -> void:
	cheated = true
	cheat_clear_enemies()
	wave = total_waves
	_finish(true)


func _shaman_heal(s: Node2D) -> void:
	var healed := false
	for o in enemies:
		if o.targetable() and o.hp < o.max_hp and o.heal_lock <= 0.0 and o.position.distance_to(s.position) <= 48.0:
			o.heal_lock = 2.5  # heals from several shamans don't stack
			var amt: float = o.max_hp * (float(s.def["heal"]) if o.cls < 4 else 0.02)
			o.hp = minf(o.max_hp, o.hp + amt)
			_fx_healed(o)
			healed = true
	if healed and not headless:
		for i in 10:
			var a := i * TAU / 10.0
			_spawn_particle(s.position + Vector2(0, -6), Vector2(cos(a), sin(a)) * 40.0, 0.4, Color("63c74d"), 1)
		Sfx.play("heal")


func _leak(e: Node2D) -> void:
	e.alive = false
	if demo:
		return
	var dmg: int = e.hp
	if headless and OS.get_cmdline_user_args().has("--verbose-leaks"):
		print("  LEAK wave %d: %s hp %d/%d" % [wave, e.type, int(e.hp), int(e.max_hp)])
	lives = maxi(0, lives - dmg)
	leaked += 1
	add_text(Vector2(e.position.x, clampf(e.position.y, 20, 340)).clamp(Vector2(20, 20), Vector2(490, 340)),
		"-%d" % dmg, Color("e43b44"))
	Sfx.play("leak")
	stats_changed.emit()
	if lives <= 0:
		_finish(false)


func _finish(win: bool) -> void:
	if over:
		return
	over = true
	placing = ""
	var newly: Array = []
	Game.last_reward = 0
	var record := not headless and (not cheated or Game.save_fake)
	if win and not headless:
		if record:
			newly = Game.record_win(map_id, diff_idx)
		Sfx.play("win")
		Music.play_victory()
	elif not headless:
		# a loss after Continue was already paid as a win
		if record and not continued:
			Game.record_loss(map_id, diff_idx, maxi(0, wave - 1), total_waves)
		Sfx.play("lose")
		Music.fade_out()
	ended.emit(win, newly)


# ---------------------------------------------------------------- damage
func damage_enemy(e: Node2D, amount: float, kind: String, src: Node, pierce := 0.0, flash := true) -> void:
	if not e.alive or amount <= 0.0 or e.downed_t > 0.0:
		return
	if not hurts(e, src, kind):
		if flash and not headless and randf() < 0.15:
			add_text(e.position + Vector2(0, -12), "LEAD", Color("8b9bb4"))
		return
	if src and is_instance_valid(src) and "buff" in src:
		amount *= src.buff
	if e.frozen_t > 0.0 and e.brittle > 0.0:
		amount *= 1.0 + e.brittle
	var dmg := amount   # kind "pure" (car crashes) ignores armor and resistances
	if kind == "physical":
		var arm: float = e.cur_armor() * (1.0 - pierce)
		dmg = maxf(amount - arm, maxf(1.0, amount * 0.15))
	elif kind == "fire":
		var res: float = e.fire_res * (1.0 - pierce)
		dmg = amount * (1.0 - res)
		if dmg <= 0.0:
			if flash and not headless and randf() < 0.08:
				add_text(e.position + Vector2(0, -12), "IMMUNE", Color("8b9bb4"))
			return
	var before: float = e.hp
	e.hp -= dmg
	if flash and e.flash_t < -0.1:   # rapid fire (minigun) would keep it white all the time
		e.flash_t = 0.05
	if src and is_instance_valid(src):
		src.damage_dealt += minf(dmg, before)
	if e.hp <= 0.0:
		if e.revives > 0:
			_fall_apart(e)
		else:
			_kill(e, src)


## Lead enemies only take damage from towers that pierce lead; fire melts it and acid eats through it anyway.
func hurts(e: Node2D, src: Node, kind := "physical") -> bool:
	if not e.lead or kind == "fire" or kind == "acid":
		return true
	return src != null and is_instance_valid(src) and "stats" in src and bool(src.stats.get("lead", false))


## Skeleton: collapses into a pile of bones and gets back up with part of its HP.
func _fall_apart(e: Node2D) -> void:
	e.revives -= 1
	e.hp = e.max_hp * float(e.def["revive"])
	e.downed_t = 1.6
	e.burn_t = 0.0
	e.burn_dps = 0.0
	e.slow_t = 0.0
	e.acid_t = 0.0
	e.acid_dps = 0.0
	e.acid_shred = 0.0
	e.thaw()
	e.incoming = 0.0
	if not headless:
		Sfx.play("rattle")
		add_text(e.position + Vector2(0, -12), "...", Color("ead4aa"))
		for i in 6:
			var a := randf() * TAU
			_spawn_particle(e.position + Vector2(0, -4), Vector2(cos(a), sin(a) - 0.5) * 30.0, 0.3,
				Color("ead4aa"), 1, 120.0)


func _kill(e: Node2D, src: Node) -> void:
	e.alive = false
	kills += 1
	if src and is_instance_valid(src):
		src.kills += 1
	if not demo:
		cash += e.bounty
		stats_changed.emit()
	if not headless:
		var col: Color = FX_COLORS.get(e.type, Color.WHITE)
		var n := 8 if e.cls < 3 else (16 if e.cls == 3 else 40)
		for i in n:
			var a := randf() * TAU
			var sp := randf_range(20, 60) * (1.0 if e.cls < 4 else 1.8)
			_spawn_particle(e.position + Vector2(0, -4), Vector2(cos(a), sin(a) - 0.6) * sp, randf_range(0.25, 0.5),
				col if i % 3 else Color.WHITE, 1 if i % 2 else 2, 120.0)
		if e.cls >= 4:
			Sfx.play("boss_die")
			announce.emit("%s DEFEATED!" % e.display_name().to_upper(), Color("fee761"))
		else:
			Sfx.play("pop", 0.2)
		if not demo:
			add_text(e.position + Vector2(0, -10), "+%d" % e.bounty, Color("feae34"))
	if e.def.has("split"):
		for i in int(e.def["split"]):
			var child := spawn_enemy("slime", e.path_i, maxf(0.0, e.dist - i * 5.0), e.spawn_mult * 2.0, false, {},
				e.mods())
			child.bounty = 1


# ---------------------------------------------------------------- towers
## Holy Champion aura: every tower within AURA_RANGE of one deals that much more damage (auras don't stack).
func recompute_buffs() -> void:
	var holy: Array = towers.values().filter(func(tw): return float(tw.stats.get("aura", 0.0)) > 0.0)
	for tw in towers.values():
		var best := 0.0
		for h in holy:
			if h.position.distance_to(tw.position) <= AURA_RANGE:
				best = maxf(best, float(h.stats["aura"]))
		tw.buff = 1.0 + best


## How many towers of this type stand on the field.
func tower_count(t: String) -> int:
	return towers.values().filter(func(tw): return tw.type == t).size()


func type_limit(t: String) -> int:
	return int(Defs.TOWERS[t].get("limit", Defs.MAX_PER_TYPE))


## Why no more of this tower can be built ("" when it can).
func limit_reason(t: String) -> String:
	if towers.size() >= Defs.MAX_TOWERS:
		return "Max %d towers" % Defs.MAX_TOWERS
	if tower_count(t) >= type_limit(t):
		return "Max %d %ss" % [type_limit(t), Defs.TOWERS[t]["name"]]
	return ""


func place_tower(t: String, tile: Vector2i, free := false) -> Node2D:
	if not can_place(tile, t) or limit_reason(t) != "":
		return null
	var cost := 0 if free else tower_cost(t)
	if cash < cost:
		return null
	cash -= cost
	var tw := TowerScript.new()
	tw.tile = tile
	tw.position = tile_center(tile)
	if not headless:
		ents.add_child(tw)
	tw.setup(t, self, cost)
	towers[tile] = tw
	recompute_buffs()
	if not headless and not demo:
		Sfx.play("place")
		for i in 10:
			var a := randf() * TAU
			_spawn_particle(tw.position + Vector2(0, 4), Vector2(cos(a) * 30, -absf(sin(a)) * 20), 0.35,
				Color("ead4aa"), 1, 60.0)
	stats_changed.emit()
	return tw


func upgrade_tower(tw: Node2D) -> bool:
	var up: Dictionary = tw.next_upgrade()
	if up.is_empty():
		return false
	var c := upgrade_cost(tw)
	if cash < c:
		return false
	cash -= c
	tw.spent += c
	tw.level += 1
	tw.recompute()
	recompute_buffs()
	if not headless:
		Sfx.play("upgrade")
		for i in 14:
			_spawn_particle(tw.position + Vector2(randf_range(-6, 6), 4), Vector2(0, -randf_range(20, 50)), 0.6,
				Color("fee761") if i % 2 else Color("2ce8f5"), 1)
	stats_changed.emit()
	return true


func sell_tower(tw: Node2D) -> void:
	if float(diff["sell"]) <= 0.0:
		return
	cash += sell_value(tw)
	towers.erase(tw.tile)
	recompute_buffs()
	if selected == tw:
		select(null)
	if not headless:
		Sfx.play("sell")
		for i in 10:
			var a := randf() * TAU
			_spawn_particle(tw.position, Vector2(cos(a), sin(a)) * 40, 0.3, Color("feae34"), 1)
	tw.queue_free()
	stats_changed.emit()


func select(tw: Node2D) -> void:
	if selected and is_instance_valid(selected):
		selected.selected = false
	selected = tw
	if tw:
		tw.selected = true
	selection_changed.emit()


func begin_place(t: String) -> void:
	if over:
		return
	if cash < tower_cost(t):
		Sfx.play("error")
		return
	var why := limit_reason(t)
	if why != "":
		Sfx.play("error")
		announce.emit(why.to_upper(), Color("e43b44"))
		return
	select(null)
	placing = t


# ---------------------------------------------------------------- projectiles
## acid: {} or {"dps", "time", "shred", "splash"} put on the enemy hit (and on everyone within "splash" px).
func spawn_bullet(src: Node, from: Vector2, target: Node2D, dmg: float, slow: float, slow_t: float,
		pierce := 0.0, col := Color("fee761"), acid := {}) -> void:
	var expected := maxf(dmg - target.cur_armor() * (1.0 - pierce), maxf(1.0, dmg * 0.15))
	target.incoming += expected
	bullets.append({"pos": from, "target": target, "dmg": dmg, "slow": slow, "slow_t": slow_t, "src": src,
		"dir": (target.position - from).normalized(), "life": 0.6, "exp": expected, "pierce": pierce, "col": col,
		"acid": acid})


func _tick_bullets(dt: float) -> void:
	var keep: Array = []
	for b in bullets:
		var tgt = b["target"]
		if tgt != null and not is_instance_valid(tgt):
			tgt = null
			b["target"] = null
		var hit: Node2D = null
		if tgt and tgt.downed_t > 0.0:
			if b["exp"] > 0.0:
				b["exp"] = 0.0
			tgt = null
			b["target"] = null
		if b["exp"] > 0.0 and tgt and (not tgt.alive or b["life"] - dt <= 0.0):
			tgt.incoming -= b["exp"]
			b["exp"] = 0.0
		if tgt and tgt.alive:
			var aimp: Vector2 = tgt.position + Vector2(0, -3 - (EnemyScript.FLY_HEIGHT if tgt.flying else 0.0))
			var d: Vector2 = aimp - b["pos"]
			if d.length() <= BULLET_SPEED * dt + 3.0:
				hit = tgt
			else:
				b["dir"] = d.normalized()
		else:
			b["target"] = null
			for e in enemies:
				if e.targetable() and (e.position + Vector2(0, -3 - (EnemyScript.FLY_HEIGHT if e.flying else 0.0))).distance_to(b["pos"]) < e.radius:
					hit = e
					break
		if hit:
			if b["exp"] > 0.0 and tgt:
				tgt.incoming -= b["exp"]
			var src = b["src"] if is_instance_valid(b["src"]) else null
			if src == null:
				b["src"] = null
			damage_enemy(hit, b["dmg"], "physical", src, b["pierce"])
			if not hit.alive and src and src.type == "necro":
				raise_dead(src, hit)
			if hit.alive and b["slow"] > 0.0 and hurts(hit, src):
				hit.apply_slow(b["slow"], b["slow_t"])
			if not (b["acid"] as Dictionary).is_empty():
				splash_acid(hit, b["acid"], src)
			if not headless:
				_spawn_particle(b["pos"], -b["dir"] * 30.0, 0.12, b["col"], 1)
			continue
		b["pos"] += b["dir"] * BULLET_SPEED * dt
		b["life"] -= dt
		if b["life"] > 0.0:
			keep.append(b)
	bullets = keep


## Puts acid on the enemy hit and, with "splash", on every enemy around it (flyers too: it's a splash).
func splash_acid(hit: Node2D, acid: Dictionary, src: Node) -> void:
	var r := float(acid.get("splash", 0.0))
	for e in ([hit] if r <= 0.0 else enemies):
		if e.alive and e.targetable() and (e == hit or e.position.distance_to(hit.position) <= r):
			e.apply_acid(float(acid["dps"]), float(acid["time"]), float(acid["shred"]), src)
	if r > 0.0 and not headless:
		for i in 10:
			var a := randf() * TAU
			_spawn_particle(hit.position + Vector2(0, -4), Vector2(cos(a), sin(a)) * r * 2.0, 0.25, Color("63c74d"), 1)


# ---------------------------------------------------------------- grenades
func spawn_grenade(src: Node, from: Vector2, to: Vector2, dmg: float, radius: float) -> void:
	grenades.append({"from": from, "to": to, "t": 0.0, "dur": 0.45, "dmg": dmg, "r": radius, "src": src})


func _tick_grenades(dt: float) -> void:
	var keep: Array = []
	for g in grenades:
		g["t"] += dt
		if g["t"] < g["dur"]:
			keep.append(g)
			continue
		var src = g["src"] if is_instance_valid(g["src"]) else null
		for e in enemies:
			if e.targetable() and not e.flying and e.position.distance_to(g["to"]) <= g["r"] + e.radius * 0.5:
				damage_enemy(e, g["dmg"], "physical", src, 0.5)
		if not headless:
			Sfx.play("boom", 0.1)
			for i in 22:
				var a := randf() * TAU
				var sp := randf_range(10, 70)
				_spawn_particle(g["to"], Vector2(cos(a), sin(a)) * sp, randf_range(0.2, 0.45),
					[Color("fee761"), Color("f77622"), Color("5a6988")][i % 3], 2 if i % 3 == 0 else 1)
	grenades = keep


# ---------------------------------------------------------------- friendly units (garage cars)
## Garage cars are Enemy nodes with is_friendly = true. They enter the road next to the garage,
## drive back towards the start and crash into enemies: both sides lose min(car hp, enemy hp).
func spawn_friendly(src: Node) -> Node2D:
	var st: Dictionary = src.stats
	var r: Array = src.roads[rng.randi() % src.roads.size()] if src.roads.size() > 1 else src.road
	var e := spawn_enemy(st["vehicle"], r[0], r[1], 1.0, true, st)
	e.owner_tower = src
	if not headless:
		Sfx.play("honk", 0.1)
	return e


## Necromancer: an enemy its bolt just killed rises as a friendly undead with part of its max HP,
## at a random spot of road inside the necromancer's range. Undead walk back down the road and crash
## like garage cars. No flyers, no bosses.
func raise_dead(src: Node, e: Node2D) -> void:
	var st: Dictionary = src.stats
	if e.is_friendly or e.flying or Defs.BOSS_TYPES.has(e.type) or e.cls > int(st["raise_class"]):
		return
	var spots := road_in_range(src.position, src.range_px())
	var at: Array = spots[rng.randi() % spots.size()] if not spots.is_empty() else [e.path_i, e.dist]
	var u := spawn_enemy(e.type, at[0], at[1], 1.0, true,
		{"undead": true, "car_hp": roundf(e.max_hp * float(st["raise_hp"])), "car_speed": float(e.def["speed"])},
		e.mods())
	u.owner_tower = src
	if not headless:
		Sfx.play("rattle", 0.1)
		add_text(u.position + Vector2(0, -12), "RISE!", Color("63c74d"))
		for i in 10:
			_spawn_particle(u.position + Vector2(randf_range(-5, 5), 2), Vector2(0, -randf_range(15, 40)), 0.5,
				Color("63c74d") if i % 2 else Color("b25aff"), 1)


## Every point of road (sampled each 4 px) within r of p: [[path index, distance], ...].
func road_in_range(p: Vector2, r: float) -> Array:
	var res: Array = []
	for pi in paths.size():
		var d := 0.0
		while d < paths[pi]["len"]:
			var q: Vector2 = path_point(pi, d)[0]
			if q.distance_to(p) <= r and q.x >= 0.0 and q.y >= 0.0 and q.x < COLS * TILE and q.y < ROWS * TILE:
				res.append([pi, d])
			d += 4.0
	return res


func has_hostiles() -> bool:
	for e in enemies:
		if e.alive and not e.is_friendly:
			return true
	return false


func _tick_friendly(f: Node2D, dt: float) -> void:
	f.anim_t += dt
	if f.flash_t > 0.0:
		f.flash_t -= dt
	f.dist -= f.current_speed() * dt
	if f.dist <= 0.0:
		f.alive = false   # reached the start of the road: just leaves
		return
	var pp := path_point(f.path_i, f.dist)
	f.position = pp[0]
	var src = f.owner_tower if is_instance_valid(f.owner_tower) else null
	# crashes
	for e in enemies:
		if not e.targetable() or e.flying or not hurts(e, src, "pure"):   # undead bounce off lead, cars don't
			continue
		if e.position.distance_to(f.position) > e.radius + f.radius:
			continue
		var dmg: float = minf(f.hp, e.hp)
		damage_enemy(e, dmg, "pure", src)
		f.hp -= dmg
		f.flash_t = 0.06
		if not headless:
			Sfx.play("hit", 0.2)
			for i in 6:
				_spawn_particle(e.position + Vector2(0, -4), Vector2(randf_range(-30, 30), -randf_range(10, 40)),
					0.25, Color("ead4aa"), 1, 80.0)
		if f.hp <= 0.0:
			_destroy_friendly(f)
			return
	# armored car turret
	if float(f.stats.get("gun_dmg", 0)) > 0.0 and src:
		f.gun_cd -= dt
		if f.gun_cd <= 0.0:
			var best: Node2D = null
			var bd := 60.0 * 60.0
			for e in enemies:
				if e.targetable() and not e.invisible and e.hp - e.incoming > 0.0:
					var dd: float = e.position.distance_squared_to(f.position)
					if dd < bd:
						bd = dd
						best = e
			if best:
				f.gun_cd = 1.0 / float(f.stats["gun_rate"])
				spawn_bullet(src, f.position + Vector2(0, -5), best, float(f.stats["gun_dmg"]), 0.0, 0.0)
	if not headless:
		f.update_visual(-pp[1])


func _destroy_friendly(f: Node2D) -> void:
	f.alive = false
	if headless:
		return
	for i in 12:
		var a := randf() * TAU
		_spawn_particle(f.position, Vector2(cos(a), sin(a)) * randf_range(10, 40), 0.4,
			Color("8b9bb4") if i % 2 else Color("fee761"), 1)


# ---------------------------------------------------------------- volcano eruptions
func _tick_eruption(dt: float) -> void:
	if eruption_t >= 0.0:
		eruption_t -= dt
		if eruption_t < 0.0:
			_start_eruption()
	if eruption_warn_t > 0.0:
		eruption_warn_t -= dt
		if eruption_warn_t <= 0.0:
			_erupt()


func _start_eruption() -> void:
	var near := {}
	for lt in lava_tiles:
		for dy in range(-1, 2):
			for dx in range(-1, 2):
				var t: Vector2i = lt + Vector2i(dx, dy)
				if t.x >= 0 and t.y >= 0 and t.x < COLS and t.y < ROWS and not path_tiles.has(t) and not lava_tiles.has(t):
					near[t] = true
	var with_tower: Array = []
	var empty: Array = []
	for t in near:
		if towers.has(t):
			with_tower.append(t)
		elif not blocked.has(t):
			empty.append(t)
	with_tower.shuffle()
	empty.shuffle()
	eruption_warn = with_tower.slice(0, 2) + empty.slice(0, 2)
	if eruption_warn.is_empty():
		return
	eruption_warn_t = 1.6
	announce.emit("ERUPTION!", Color("f77622"))
	if not headless:
		Sfx.play("boom")


func _erupt() -> void:
	for t in eruption_warn:
		if towers.has(t):
			towers[t].disabled_t = 6.0
		if not headless:
			var c := tile_center(t)
			for i in 18:
				var a := randf_range(-PI, 0)
				_spawn_particle(c, Vector2(cos(a), sin(a)) * randf_range(20, 70), randf_range(0.3, 0.7),
					[Color("fee761"), Color("f77622"), Color("e43b44")][i % 3], 2 if i % 2 else 1, 160.0)
	if not headless:
		Sfx.play("boom")
	eruption_warn = []


# ---------------------------------------------------------------- effects
func _spawn_particle(p: Vector2, v: Vector2, life: float, col: Color, size := 1, grav := 0.0) -> void:
	if headless:
		return
	if particles.size() > 900:
		return
	particles.append({"p": p, "v": v, "life": life, "max": life, "c": col, "s": size, "g": grav})


func add_text(p: Vector2, t: String, col: Color) -> void:
	if headless:
		return
	texts.append({"p": p, "t": t, "c": col, "life": 0.9})


func fx_muzzle(p: Vector2) -> void:
	if headless:
		return
	for i in 3:
		_spawn_particle(p + Vector2(randf_range(-1, 1), randf_range(-1, 1)), Vector2.ZERO, 0.06, Color("fee761"), 2)


func fx_slash(p: Vector2, dir: Vector2, r: float, cleave: bool, stun: bool) -> void:
	if headless:
		return
	slashes.append({"p": p, "dir": dir, "r": r * (0.95 if cleave else 0.7), "life": 0.16, "cleave": cleave,
		"stun": stun})


func fx_tracer(a: Vector2, b: Vector2, gold: bool) -> void:
	if headless:
		return
	tracers.append({"a": a, "b": b, "life": 0.12, "gold": gold})
	for i in 4:
		_spawn_particle(b, Vector2(randf_range(-30, 30), randf_range(-30, 10)), 0.2, Color("fee761"), 1)
	fx_muzzle(a)


func fx_flame(p: Vector2, dir: Vector2, r: float, half_cone: float, blue: bool) -> void:
	if headless:
		return
	for i in 5:
		var a := dir.angle() + randf_range(-half_cone, half_cone) * 0.85
		var sp := r / 0.32 * randf_range(0.8, 1.05)
		particles.append({"p": p, "v": Vector2(cos(a), sin(a)) * sp, "life": 0.32, "max": 0.32,
			"c": Color.WHITE, "s": 2, "g": -20.0, "flame": true, "blue": blue})


## Freezer water. Liquid nitrogen (max level) is a white, cold mist instead of blue droplets.
func fx_spray(p: Vector2, dir: Vector2, r: float, half_cone: float, nitrogen: bool) -> void:
	if headless:
		return
	for i in 5:
		var a := dir.angle() + randf_range(-half_cone, half_cone) * 0.85
		var sp := r / 0.32 * randf_range(0.8, 1.05)
		particles.append({"p": p, "v": Vector2(cos(a), sin(a)) * sp, "life": 0.32, "max": 0.32,
			"c": Color.WHITE, "s": 2, "g": -10.0 if nitrogen else 60.0, "flame": true, "water": true,
			"nitro": nitrogen})


## Water met fire (or fire met ice): a puff of steam.
func fx_steam(e: Node2D, txt: String) -> void:
	if headless:
		return
	for i in 6:
		_spawn_particle(e.position + Vector2(randf_range(-4, 4), -randf_range(2, 10)),
			Vector2(randf_range(-8, 8), -randf_range(14, 26)), 0.5, Color("c0cbdc"), 2)
	if randf() < 0.05:
		add_text(e.position + Vector2(0, -12), txt, Color("c0cbdc"))


func fx_freeze(e: Node2D) -> void:
	if headless:
		return
	add_text(e.position + Vector2(0, -14), "FROZEN", Color("8bd8f0"))
	for i in 8:
		var a := randf() * TAU
		_spawn_particle(e.position + Vector2(0, -6), Vector2(cos(a), sin(a)) * 30.0, 0.35, Color("e8f8ff"), 1)


func _tick_fx(dt: float) -> void:
	if headless:
		return
	var keep: Array = []
	for p in particles:
		p["life"] -= dt
		if p["life"] <= 0.0:
			continue
		p["v"].y += p["g"] * dt
		if p.has("flame"):
			p["v"] *= 0.97
		p["p"] += p["v"] * dt
		keep.append(p)
	particles = keep
	var kt: Array = []
	for t in texts:
		t["life"] -= dt
		t["p"].y -= 14.0 * dt
		if t["life"] > 0.0:
			kt.append(t)
	texts = kt
	var ks: Array = []
	for s in slashes:
		s["life"] -= dt
		if s["life"] > 0.0:
			ks.append(s)
	slashes = ks
	var ktr: Array = []
	for tr in tracers:
		tr["life"] -= dt
		if tr["life"] > 0.0:
			ktr.append(tr)
	tracers = ktr


# ---------------------------------------------------------------- input & hover
func _update_hover() -> void:
	var m := get_local_mouse_position()   # map coordinates (zoom aware)
	var on_map := get_viewport().get_mouse_position().x < VIEW_W
	hover_tile = Vector2i(floori(m.x / TILE), floori(m.y / TILE))
	hovered_tower = towers.get(hover_tile) if on_map else null
	if not demo:
		var aim_cursor := on_map and not paused and not over and (placing != "" or enemy_at(m) != null)
		Game.set_cursor(Input.CURSOR_CROSS if aim_cursor else Input.CURSOR_ARROW)


# ---------------------------------------------------------------- camera zoom
const VIEW_W := 512.0   # visible map area on screen (the sidebar covers the rest)
const VIEW_H := 360.0
const MAX_ZOOM := 3
var _panning := false


## Integer zoom steps (1x, 2x, 3x) keep pixel art crisp. The point under the cursor stays in place.
func zoom_at(z: int, screen_pos: Vector2) -> void:
	z = clampi(z, 1, MAX_ZOOM)
	if z == int(scale.x):
		return
	var world := (screen_pos - position) / scale.x
	scale = Vector2(z, z)
	position = screen_pos - world * z
	_clamp_view()


func _clamp_view() -> void:
	var z := scale.x
	position.x = clampf(position.x, VIEW_W - VIEW_W * z, 0.0)
	position.y = clampf(position.y, VIEW_H - VIEW_H * z, 0.0)
	position = position.round()


func _camera_input(event: InputEvent) -> bool:
	if event is InputEventMouseButton:
		var screen: Vector2 = event.position   # where the wheel was turned, in viewport pixels
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			_panning = event.pressed and scale.x > 1.0
			return true
		if event.pressed and screen.x < VIEW_W:
			if event.button_index == MOUSE_BUTTON_WHEEL_UP:
				zoom_at(int(scale.x) + 1, screen)
				return true
			if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
				zoom_at(int(scale.x) - 1, screen)
				return true
	elif event is InputEventMouseMotion and _panning:
		position += event.relative
		_clamp_view()
		return true
	return false


func _unhandled_input(event: InputEvent) -> void:
	if demo:
		return
	if _camera_input(event):
		get_viewport().set_input_as_handled()
		return
	if over or paused:
		return
	if event is InputEventMouseButton and event.pressed:
		if get_viewport().get_mouse_position().x >= VIEW_W:
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			if placing != "":
				if can_place(hover_tile, placing) and cash >= tower_cost(placing):
					var tw := place_tower(placing, hover_tile)
					if not Input.is_key_pressed(KEY_SHIFT) or cash < tower_cost(placing) or limit_reason(placing) != "":
						placing = ""
						select(tw)
				else:
					Sfx.play("error")
					if placing == "garage" and can_place(hover_tile):
						add_text(tile_center(hover_tile) + Vector2(0, -12), "Must touch a road", Color("e43b44"))
			else:
				select(towers.get(hover_tile))
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			placing = ""
			select(null)
			get_viewport().set_input_as_handled()


# ---------------------------------------------------------------- drawing
func _draw_range(n: Node2D, c: Vector2, r: float, ok: bool) -> void:
	var fill := Color(1, 1, 1, 0.12) if ok else Color(0.9, 0.2, 0.25, 0.18)
	var line := Color(1, 1, 1, 0.55) if ok else Color(0.95, 0.3, 0.3, 0.7)
	n.draw_circle(c, r, fill, true, -1.0, false)
	n.draw_arc(c, r, 0, TAU, 64, line, 1.0, false)


func _draw_under(n: Node2D) -> void:
	if demo:
		return
	for t in eruption_warn:
		if int(time_total * 8.0) % 2 == 0:
			n.draw_rect(Rect2(t * TILE, Vector2(TILE, TILE)), Color(1, 0.3, 0.1, 0.45))
		n.draw_rect(Rect2(t * TILE, Vector2(TILE, TILE)), Color("f77622"), false, 1.0)
	if placing != "":
		var ok := can_place(hover_tile, placing)
		if hover_tile.x >= 0 and hover_tile.x < COLS and hover_tile.y >= 0 and hover_tile.y < ROWS:
			var r := float(Defs.TOWERS[placing]["base"]["range"])
			if r > 0:
				_draw_range(n, tile_center(hover_tile), r, ok)
			elif ok and placing == "garage":   # where its cars will drive out
				var rd := nearest_road(tile_center(hover_tile))
				_draw_road_marker(n, path_point(rd[0], rd[1])[0])
			n.draw_rect(Rect2(hover_tile * TILE, Vector2(TILE, TILE)),
				Color(0.4, 1, 0.4, 0.35) if ok else Color(1, 0.3, 0.3, 0.35))
	var show: Node2D = selected if selected and is_instance_valid(selected) else hovered_tower
	if show and is_instance_valid(show):
		if show.range_px() > 0:
			_draw_range(n, show.position, show.range_px(), true)
		elif not show.road.is_empty():
			_draw_road_marker(n, path_point(show.road[0], show.road[1])[0])


func _draw_road_marker(n: Node2D, p: Vector2) -> void:
	var c := Color("fee761")
	n.draw_rect(Rect2(p - Vector2(7, 7), Vector2(14, 14)), Color(1, 0.9, 0.3, 0.2))
	n.draw_rect(Rect2(p - Vector2(7, 7), Vector2(14, 14)), c, false, 1.0)


func _draw_over(n: Node2D) -> void:
	var f := UI.font()
	for g in grenades:
		var k: float = g["t"] / g["dur"]
		var gp: Vector2 = (g["from"] as Vector2).lerp(g["to"], k) + Vector2(0, -sin(k * PI) * 18.0)
		n.draw_rect(Rect2(gp.round() - Vector2(1, 1), Vector2(3, 3)), Color("181425"))
		n.draw_rect(Rect2(gp.round(), Vector2(1, 1)), Color("63c74d"))
	for tr in tracers:
		var k: float = tr["life"] / 0.12
		var col := Color("feae34") if tr["gold"] else Color("fee761")
		n.draw_line((tr["a"] as Vector2).round(), (tr["b"] as Vector2).round(), Color(col, k), 1.0)
		n.draw_line((tr["a"] as Vector2).round(), (tr["b"] as Vector2).round(), Color(1, 1, 1, k * 0.5), 1.0)
	for b in bullets:
		var p: Vector2 = (b["pos"] as Vector2).round()
		var d: Vector2 = b["dir"]
		n.draw_line(p, (p - d * 3.0).round(), b["col"], 1.0)
		n.draw_rect(Rect2(p, Vector2(1, 1)), Color.WHITE)
	for p in particles:
		var t: float = p["life"] / p["max"]
		var c: Color = p["c"]
		var s: int = p["s"]
		if p.has("water"):
			if p["nitro"]:
				c = Color("ffffff") if t > 0.6 else (Color("e8f8ff") if t > 0.3 else Color("c0cbdc"))
				c.a = 1.0 if t > 0.3 else 0.6
			else:
				c = Color("e8f8ff") if t > 0.75 else (Color("8bd8f0") if t > 0.4 else Color("0099db"))
			s = 2 if t > 0.5 else 1
		elif p.has("flame"):
			if p["blue"]:
				c = Color("ffffff") if t > 0.75 else (Color("2ce8f5") if t > 0.5 else (Color("0099db") if t > 0.25 else Color("124e89")))
			else:
				c = Color("fee761") if t > 0.7 else (Color("feae34") if t > 0.45 else (Color("f77622") if t > 0.2 else Color("a22633")))
			s = 2 if t > 0.4 else 1
		else:
			c.a = clampf(t * 2.0, 0.0, 1.0)
		n.draw_rect(Rect2((p["p"] as Vector2).round(), Vector2(s, s)), c)
	for s in slashes:
		var t: float = 1.0 - s["life"] / 0.16
		var dir: Vector2 = s["dir"]
		var base := dir.angle()
		var span := PI * 0.9 if not s["cleave"] else TAU
		var a0 := base - span / 2.0
		var steps := 14 if not s["cleave"] else 28
		var col := Color("fee761") if s["stun"] else Color.WHITE
		for i in steps:
			var k := float(i) / steps
			if k > t + 0.15 or k < t - 0.45:
				continue
			var a := a0 + span * k
			var pp: Vector2 = s["p"] + Vector2(cos(a), sin(a)) * s["r"]
			n.draw_rect(Rect2(pp.round(), Vector2(2, 2)), col)
			var pp2: Vector2 = s["p"] + Vector2(cos(a), sin(a)) * (s["r"] - 3.0)
			n.draw_rect(Rect2(pp2.round(), Vector2(1, 1)), Color(col, 0.6))
	for t in texts:
		var a: float = clampf(t["life"] * 2.0, 0.0, 1.0)
		var p: Vector2 = (t["p"] as Vector2).round()
		var w := f.get_string_size(t["t"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10).x
		var tp := Vector2(roundf(p.x - w / 2.0), p.y)
		n.draw_string(f, tp + Vector2(1, 1), t["t"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.09, 0.08, 0.15, a))
		n.draw_string(f, tp, t["t"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(t["c"], a))
	if placing != "" and not demo:
		var tex := Game.tex("res://assets/sprites/towers/%s.png" % Defs.TOWERS[placing]["sprite"])
		var c := tile_center(hover_tile)
		n.draw_texture(tex, (c - tex.get_size() / 2.0 + Vector2(0, TowerScript.base_offset_y(tex))).round(),
			Color(1, 1, 1, 0.75) if can_place(hover_tile, placing) else Color(1, 0.4, 0.4, 0.6))


# ---------------------------------------------------------------- demo (menu background)
func _setup_demo() -> void:
	# spread decorative towers evenly along the path, one or two tiles beside the road
	var kinds := ["gunner", "knight", "soldier", "garage", "flamer", "gunner", "soldier", "knight", "garage", "freezer"]
	var levels := [1, 0, 1, 2, 1, 0, 2, 3, 3, 1]
	var p: Dictionary = paths[0]
	var n := kinds.size()
	for i in n:
		var d: float = p["len"] * (0.08 + 0.84 * float(i) / float(n - 1))
		var c: Vector2 = path_point(0, d)[0]
		var ct := Vector2i(floori(c.x / TILE), floori(c.y / TILE))
		var best := Vector2i(-1, -1)
		var bd := 1e9
		var want := 1.0 if kinds[i] == "knight" or kinds[i] == "garage" else 1.6
		for dy in range(-3, 4):
			for dx in range(-3, 4):
				var t := ct + Vector2i(dx, dy)
				if t.x < 0 or t.x >= 40 or t.y < 7 or t.y >= 22 or blocked.has(t) or towers.has(t):
					continue
				if kinds[i] == "garage" and not next_to_road(t):
					continue
				var dist := tile_center(t).distance_to(c) / TILE
				var score := absf(dist - want) + (0.3 if (i % 2 == 0) == (dx < 0) else 0.0)
				if score < bd:
					bd = score
					best = t
		if best.x < 0:
			continue
		var tw := TowerScript.new()
		tw.tile = best
		tw.position = tile_center(best)
		ents.add_child(tw)
		tw.setup(kinds[i], self, 0)
		tw.level = levels[i]
		tw.recompute()
		towers[best] = tw


func _tick_demo(dt: float) -> void:
	_demo_t -= dt
	_demo_boss_t -= dt
	if _demo_t <= 0.0:
		_demo_t = randf_range(0.5, 1.1)
		var pool := ["slime", "slime", "rat", "goblin", "goblin", "wolf", "ironclad", "imp", "shaman", "ogre",
			"slime_king"]
		spawn_enemy(pool[randi() % pool.size()], 0, 0.0, 1.6)
	if _demo_boss_t <= 0.0:
		_demo_boss_t = 40.0
		spawn_enemy("golem" if randf() < 0.6 else "demon", 0, 0.0, 0.25)
