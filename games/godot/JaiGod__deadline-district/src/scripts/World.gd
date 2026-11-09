extends Node2D
## Deadline District gameplay: player, weapons, zombies, waves, defenses and rendering.

class Glow extends Node2D:
	var w
	func _draw() -> void:
		if w:
			w.draw_glow(self)

signal message(text: String, col: Color)
signal ended(won: bool)

const CELL := 40.0
const PR := 14.0
const MAX_ALIVE := 60
const SHADER := """
shader_type canvas_item;
uniform vec2 vsize = vec2(960.0, 540.0);
uniform vec2 ppos;
uniform float ang;
uniform float cone = 0.5;
uniform float range = 430.0;
uniform float ambient = 0.86;
uniform float halo = 95.0;
uniform float flick = 1.0;
uniform float hurt = 0.0;
uniform vec3 lights[16];
uniform float li[16];
uniform int nl = 0;
void fragment() {
	vec2 p = UV * vsize;
	vec2 d = p - ppos;
	float dist = length(d);
	float a = atan(d.y, d.x);
	float da = abs(mod(a - ang + PI, TAU) - PI);
	float c = (1.0 - smoothstep(cone * 0.5, cone, da)) * (1.0 - smoothstep(range * 0.4, range, dist)) * flick;
	float lit = max(c, (1.0 - smoothstep(halo * 0.2, halo, dist)) * 0.8);
	for (int i = 0; i < 16; i++) {
		if (i >= nl) { break; }
		float ld = length(p - lights[i].xy);
		lit = max(lit, (1.0 - smoothstep(lights[i].z * 0.12, lights[i].z, ld)) * li[i]);
	}
	float dark = ambient * (1.0 - clamp(lit, 0.0, 1.0));
	float vig = smoothstep(0.38, 0.85, length(UV - 0.5)) * hurt * 0.8;
	vec3 col = mix(vec3(0.012, 0.018, 0.045), vec3(0.55, 0.0, 0.05), clamp(vig * 2.0, 0.0, 1.0));
	COLOR = vec4(col, max(dark, vig * 0.75));
}
"""

var map_i := 0
var m := {}
var info := {}
var demo := false

# player
var pp := Vector2.ZERO
var pv := Vector2.ZERO
var aim := 0.0
var hp := 100.0
var mhp := 100.0
var cash := 300
var kills := 0
var owned := {"pistol": 0}
var ammo := {"pistol": [12, -1]}
var order := ["pistol"]
var cur := 0
var reload_t := 0.0
var reload_max := 1.0
var fire_cd := 0.0
var spin := 0.0
var dash_t := 0.0
var dash_cd := 0.0
var dash_dir := Vector2.RIGHT
var inv_t := 0.0
var hurt_t := 0.0
var perks := {}
var second_used := false
var alive := true
var walk_t := 0.0
var muzzle_t := 0.0
var score := 0

# input
var in_move := Vector2.ZERO
var in_fire := false
var mouse_aim := true

# waves
var wave := 0
var state := "intermission"
var inter_t := 30.0
var queue: Array = []
var spawn_t := 0.0
var spawn_gap := 1.0
var boss = null
var won := false
var endless := false
var announce := ""
var announce_t := 0.0

var zs: Array = []
var bullets: Array = []
var ebul: Array = []
var parts: Array = []
var splats: Array = []
var texts: Array = []
var lights: Array = []
var rings: Array = []
var arcs: Array = []
var slashes: Array = []
var pickups: Array = []
var bars: Array = []
var turrets: Array = []
var shake := 0.0
var gw := 0
var gh := 0
var blocked := PackedByteArray()
var dist := PackedInt32Array()
var flow_t := 0.0
var next_id := 1
var time := 0.0
var cam: Camera2D
var glow: Glow
var dark: ColorRect
var font: Font
var _prev_cell := -1

func setup(mi: int, is_demo := false) -> void:
	map_i = mi
	demo = is_demo
	m = Data.build_map(mi)
	info = Data.MAP_INFO[mi]
	pp = m.start
	aim = -PI / 2.0
	font = ThemeDB.fallback_font
	_build_grid()
	cam = Camera2D.new()
	add_child(cam)
	cam.position = pp
	cam.make_current()
	var dl = CanvasLayer.new()
	dl.layer = 5
	add_child(dl)
	dark = ColorRect.new()
	dark.set_anchors_preset(Control.PRESET_FULL_RECT)
	dark.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sm = ShaderMaterial.new()
	sm.shader = Shader.new()
	sm.shader.code = SHADER
	dark.material = sm
	dl.add_child(dark)
	var gl = CanvasLayer.new()
	gl.layer = 6
	gl.follow_viewport_enabled = true
	add_child(gl)
	glow = Glow.new()
	glow.w = self
	gl.add_child(glow)
	if demo:
		owned = {"pistol": 1, "smg": 1, "shotgun": 1}
		order = ["pistol", "smg", "shotgun"]
		for id in order:
			ammo[id] = [stat_mag(id), 999]
		cur = 1
		wave = 4
		_start_wave()
	else:
		state = "intermission"
		inter_t = 30.0
		_say("Reach the WEAPON BENCH to gear up. Wave 1 incoming!", Color(1, 0.85, 0.4))

# ------------------------------------------------------------------ grid / flow field
func _build_grid() -> void:
	gw = int(ceil(m.size.x / CELL))
	gh = int(ceil(m.size.y / CELL))
	blocked.resize(gw * gh)
	blocked.fill(0)
	dist.resize(gw * gh)
	for y in gh:
		for x in gw:
			var cr = Rect2(x * CELL + 5, y * CELL + 5, CELL - 10, CELL - 10)
			for wl in m.walls:
				if wl[0].intersects(cr):
					blocked[y * gw + x] = 1
					break

func _cell(p: Vector2) -> int:
	var cx = clampi(int(p.x / CELL), 0, gw - 1)
	var cy = clampi(int(p.y / CELL), 0, gh - 1)
	return cy * gw + cx

func _flow() -> void:
	dist.fill(-1)
	var start = _cell(pp)
	var q = PackedInt32Array([start])
	dist[start] = 0
	var head = 0
	while head < q.size():
		var c = q[head]
		head += 1
		var cx = c % gw
		var cy = c / gw
		var dc = dist[c] + 1
		for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
			var nx = cx + o.x
			var ny = cy + o.y
			if nx < 0 or ny < 0 or nx >= gw or ny >= gh:
				continue
			var n = ny * gw + nx
			if blocked[n] or dist[n] != -1:
				continue
			if o.x != 0 and o.y != 0 and (blocked[cy * gw + nx] or blocked[ny * gw + cx]):
				continue
			dist[n] = dc
			q.append(n)

func _flow_dir(p: Vector2) -> Vector2:
	var c = _cell(p)
	var dc = dist[c]
	if dc <= 1:
		return (pp - p).normalized()
	var cx = c % gw
	var cy = c / gw
	var best = dc
	var bp = pp
	for o in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(1, -1), Vector2i(-1, -1)]:
		var nx = cx + o.x
		var ny = cy + o.y
		if nx < 0 or ny < 0 or nx >= gw or ny >= gh:
			continue
		var n = ny * gw + nx
		var dn = dist[n]
		if dn >= 0 and dn < best:
			if o.x != 0 and o.y != 0 and (blocked[cy * gw + nx] or blocked[ny * gw + cx]):
				continue
			best = dn
			bp = Vector2((nx + 0.5) * CELL, (ny + 0.5) * CELL)
	return (bp - p).normalized()

# ------------------------------------------------------------------ weapon stats
func wdef() -> Dictionary:
	return Data.weapon(order[cur])

func tier(id: String) -> int:
	return int(owned.get(id, 0))

func stat_mag(id: String) -> int:
	var w = Data.weapon(id)
	return int(w.mag * (1.0 + 0.25 * tier(id)))

func stat_res(id: String) -> int:
	var w = Data.weapon(id)
	if w.res < 0:
		return -1
	return int(w.res * (1.0 + 0.25 * tier(id)) * (1.6 if perks.has("pockets") else 1.0))

func stat_dmg(id: String) -> float:
	return Data.weapon(id).dmg * (1.0 + 0.3 * tier(id))

func give_weapon(id: String) -> void:
	if not owned.has(id):
		owned[id] = 0
		order.append(id)
	ammo[id] = [stat_mag(id), stat_res(id)]
	cur = order.find(id)
	reload_t = 0.0

func refill(id: String) -> void:
	ammo[id] = [stat_mag(id), stat_res(id)]

func switch_to(i: int) -> void:
	if i < 0 or i >= order.size() or i == cur:
		return
	cur = i
	reload_t = 0.0
	spin = 0.0
	Sfx.play("click")

func cycle(d: int) -> void:
	switch_to((cur + d + order.size()) % order.size())

func reload() -> void:
	var id = order[cur]
	var w = wdef()
	if w.mag <= 0 or reload_t > 0.0:
		return
	var a = ammo[id]
	if a[0] >= stat_mag(id) or a[1] == 0:
		return
	reload_max = w.reload * (1.0 - 0.12 * tier(id)) * (0.65 if perks.has("hands") else 1.0)
	reload_t = reload_max
	Sfx.play("reload")

func _finish_reload() -> void:
	var id = order[cur]
	var a = ammo[id]
	var need = stat_mag(id) - a[0]
	if a[1] < 0:
		a[0] += need
	else:
		var take = mini(need, a[1])
		a[0] += take
		a[1] -= take

func dash() -> void:
	if dash_cd > 0.0 or not alive:
		return
	dash_dir = in_move.normalized() if in_move.length() > 0.1 else Vector2.from_angle(aim)
	dash_t = 0.2
	dash_cd = 1.3
	Sfx.play("dash")
	for i in 8:
		_part(pp, -dash_dir.rotated(randf_range(-0.6, 0.6)) * randf_range(60, 160), Color(0.6, 0.8, 1.0, 0.8), 0.35, 4.0)

# ------------------------------------------------------------------ main loop
func _process(delta: float) -> void:
	var dt = minf(delta, 0.05)
	time += dt
	if alive:
		_update_player(dt)
	_update_waves(dt)
	flow_t -= dt
	var pc = _cell(pp)
	if flow_t <= 0.0 or pc != _prev_cell:
		_flow()
		flow_t = 0.35
		_prev_cell = pc
	_update_zombies(dt)
	_update_bullets(dt)
	_update_misc(dt)
	_update_camera(dt)
	queue_redraw()
	glow.queue_redraw()

func _update_player(dt: float) -> void:
	if demo:
		_demo_ai(dt)
	elif mouse_aim:
		aim = (get_global_mouse_position() - pp).angle()
	var spd = 215.0 * (1.15 if perks.has("feet") else 1.0)
	var mv = in_move.limit_length(1.0)
	if dash_t > 0.0:
		dash_t -= dt
		pv = dash_dir * 640.0
	else:
		pv = pv.lerp(mv * spd, 1.0 - exp(-14.0 * dt))
	pp += pv * dt
	pp = _collide(pp, PR)
	if pv.length() > 30.0:
		walk_t += dt * pv.length() / 30.0
	dash_cd -= dt
	inv_t -= dt
	hurt_t = maxf(0.0, hurt_t - dt * 1.5)
	muzzle_t -= dt
	fire_cd -= dt
	var w = wdef()
	if reload_t > 0.0:
		reload_t -= dt
		if reload_t <= 0.0:
			_finish_reload()
	if in_fire:
		if w.id == "minigun":
			spin = minf(1.0, spin + dt * 1.7)
		if fire_cd <= 0.0:
			_fire(w)
	else:
		spin = maxf(0.0, spin - dt * 1.2)
	# pickups
	for k in range(pickups.size() - 1, -1, -1):
		var pk = pickups[k]
		var d = pp.distance_to(pk.p)
		if d < 130.0:
			pk.p = pk.p.move_toward(pp, dt * (520.0 - d * 2.5))
		if d < 20.0:
			_collect(pk)
			pickups.remove_at(k)

func _demo_ai(dt: float) -> void:
	hp = mhp
	var tgt = null
	var bd = 520.0
	for z in zs:
		var d = z.p.distance_to(pp)
		if d < bd:
			bd = d
			tgt = z
	if tgt:
		aim = lerp_angle(aim, (tgt.p - pp).angle(), 1.0 - exp(-8.0 * dt))
		in_fire = bd < 420.0
	else:
		aim += dt * 0.8
		in_fire = false
	in_move = Vector2.from_angle(time * 0.4) * 0.35
	if tgt and bd < 110.0:
		in_move = (pp - tgt.p).normalized()
	if pp.distance_to(m.start) > 160.0:
		in_move = (m.start - pp).normalized() * 0.6

func _collect(pk: Dictionary) -> void:
	match pk.t:
		"cash":
			cash += int(pk.v)
			Sfx.play("coin", 1.0, -8.0)
		"med":
			hp = minf(mhp, hp + 30.0)
			_text(pp, "+30 HP", Color(0.5, 1.0, 0.6))
			Sfx.play("buy")
		"ammo":
			for id in order:
				var a = ammo[id]
				if a[1] >= 0:
					a[1] = mini(stat_res(id), a[1] + int(stat_res(id) * 0.35) + 1)
			_text(pp, "AMMO", Color(1.0, 0.85, 0.4))
			Sfx.play("reload")

func _fire(w: Dictionary) -> void:
	var id = w.id
	var a = ammo[id]
	if reload_t > 0.0:
		return
	if w.mag > 0 and a[0] <= 0:
		if a[1] != 0:
			reload()
		else:
			Sfx.play("empty")
			fire_cd = 0.3
			if not demo:
				_say("Out of ammo! Buy more at the bench.", Color(1, 0.5, 0.4))
		return
	var rate = w.rate * (1.0 + 0.1 * tier(id))
	if id == "minigun":
		rate *= 0.2 + 0.8 * spin
	fire_cd = 1.0 / rate
	if w.mag > 0 and not demo:
		a[0] -= 1
	elif w.mag > 0 and demo and a[0] > 1:
		a[0] -= 1
	var dir = Vector2.from_angle(aim)
	var mz = pp + dir * 24.0
	var dmg = stat_dmg(id)
	var spread = w.spread * (0.6 if perks.has("aim") else 1.0)
	match w.kind:
		"bullet", "bolt", "rocket":
			for i in w.pellets:
				var d2 = dir.rotated(randf_range(-spread, spread))
				var sp = w.speed * randf_range(0.92, 1.05)
				bullets.append({"p": mz, "v": d2 * sp, "dmg": dmg, "life": w.range / w.speed, "pierce": w.pierce, "kind": w.kind, "hit": [], "c": w.col, "kb": 140.0 if id == "shotgun" else 60.0})
			if w.kind != "bolt":
				_part(pp + dir.rotated(1.4) * 8, dir.rotated(1.6 + randf_range(-0.3, 0.3)) * 120, Color(0.95, 0.8, 0.35), 0.5, 2.5)
		"flame":
			var d3 = dir.rotated(randf_range(-spread, spread))
			bullets.append({"p": mz, "v": d3 * w.speed * randf_range(0.8, 1.15) + pv * 0.5, "dmg": dmg, "life": w.range / w.speed, "pierce": 99, "kind": "flame", "hit": [], "c": w.col, "kb": 10.0, "age": 0.0})
		"tesla":
			_tesla(dir, dmg, w.range)
		"melee":
			_slash(dir, dmg, w.range)
	muzzle_t = 0.05
	shake = minf(14.0, shake + w.shake * 0.6)
	_light(mz, 170.0 if w.kind != "melee" else 0.0, 0.9, 0.06)
	var snd = {"pistol": "pistol", "smg": "smg", "shotgun": "shotgun", "rifle": "rifle", "minigun": "minigun", "flamer": "flame", "crossbow": "bow", "rocket": "rocket", "tesla": "tesla", "katana": "slash"}
	Sfx.play(snd[id], 1.0, -6.0 if demo else 0.0)
	if w.mag > 0 and a[0] <= 0 and a[1] != 0:
		reload()

func _tesla(dir: Vector2, dmg: float, rng: float) -> void:
	var best = null
	var bd = rng
	for z in zs:
		var to = z.p - pp
		var d = to.length()
		if d < bd and absf(dir.angle_to(to)) < 0.5:
			bd = d
			best = z
	var pts = [pp + dir * 22.0]
	if best == null:
		pts.append(pp + dir * rng * 0.6)
		arcs.append({"pts": pts, "life": 0.12})
		return
	var hitset = []
	var curz = best
	var d = dmg
	for i in 5:
		pts.append(curz.p)
		hitset.append(curz.id)
		_hurt(curz, d, (curz.p - pts[pts.size() - 2]).normalized(), "tesla")
		_light(curz.p, 110.0, 0.8, 0.12)
		d *= 0.8
		var nxt = null
		var nd = 170.0
		for z in zs:
			if hitset.has(z.id) or z.hp <= 0:
				continue
			var dd = z.p.distance_to(curz.p)
			if dd < nd:
				nd = dd
				nxt = z
		if nxt == null:
			break
		curz = nxt
	arcs.append({"pts": pts, "life": 0.14})

func _slash(dir: Vector2, dmg: float, rng: float) -> void:
	slashes.append({"p": pp, "a": dir.angle(), "life": 0.16})
	for z in zs:
		var to = z.p - pp
		if to.length() < rng + z.r and absf(dir.angle_to(to)) < 1.1:
			_hurt(z, dmg, to.normalized(), "melee")
	for k in range(ebul.size() - 1, -1, -1):
		var to = ebul[k].p - pp
		if to.length() < rng + 20.0 and absf(dir.angle_to(to)) < 1.2:
			_burst(ebul[k].p, Color(0.6, 1.0, 0.4), 6, 120.0)
			ebul.remove_at(k)

# ------------------------------------------------------------------ waves
func _update_waves(dt: float) -> void:
	announce_t -= dt
	if state == "intermission":
		inter_t -= dt
		if inter_t <= 0.0:
			_start_wave()
	elif state == "wave":
		spawn_t -= dt
		if spawn_t <= 0.0 and queue.size() > 0 and zs.size() < MAX_ALIVE:
			spawn_t = spawn_gap
			var t = queue.pop_front()
			var sp = _spawn_point()
			if t == "boss":
				_spawn_boss(sp)
			elif t == "crawlers":
				for i in 4:
					_spawn("crawler", sp + Vector2(randf_range(-30, 30), randf_range(-30, 30)))
			else:
				_spawn(t, sp)
		if queue.is_empty() and zs.is_empty():
			if demo:
				_start_wave()
			else:
				_clear_wave()

func ready_up() -> void:
	if state == "intermission":
		inter_t = 0.0

func _start_wave() -> void:
	wave += 1
	state = "wave"
	queue = []
	var is_boss = wave % 5 == 0
	var count = 6 + wave * 4
	if is_boss:
		count = int(count * 0.5)
	var pool = []
	var tot = 0.0
	for k in Data.ZOMBIES:
		var zd = Data.ZOMBIES[k]
		if wave >= zd.from:
			pool.append(k)
			tot += zd.w
	for i in count:
		var r = randf() * tot
		for k in pool:
			r -= Data.ZOMBIES[k].w
			if r <= 0.0:
				queue.append("crawlers" if k == "crawler" else k)
				break
	if is_boss:
		queue.insert(mini(2, queue.size()), "boss")
	spawn_gap = maxf(0.22, 1.05 - wave * 0.05)
	spawn_t = 1.0
	if not demo:
		announce = "BOSS WAVE %d" % wave if is_boss else "WAVE %d" % wave
		announce_t = 2.5
		Sfx.play("boss" if is_boss else "wave")
		Sfx.music("boss" if is_boss else "wave")

func _clear_wave() -> void:
	var bonus = 100 + 25 * wave
	cash += bonus
	score += bonus
	Sfx.play("clear")
	if wave >= Data.WIN_WAVE and not endless:
		won = true
		state = "won"
		Sfx.play("victory")
		Sfx.music("calm")
		ended.emit(true)
		return
	state = "intermission"
	inter_t = 25.0
	announce = "WAVE %d CLEARED  +$%d" % [wave, bonus]
	announce_t = 2.5
	Sfx.music("calm")

func continue_endless() -> void:
	endless = true
	state = "intermission"
	inter_t = 25.0
	won = false

func _spawn_point() -> Vector2:
	var far = []
	for s in m.spawns:
		if s.distance_to(pp) > 380.0:
			far.append(s)
	if far.is_empty():
		far = m.spawns
	return far[randi() % far.size()] + Vector2(randf_range(-20, 20), randf_range(-20, 20))

func _hpm() -> float:
	return (1.0 + 0.13 * (wave - 1)) * info.hp

func _spawn(t: String, p: Vector2) -> Dictionary:
	var zd = Data.ZOMBIES[t]
	var hpv = zd.hp * _hpm()
	var z = {"id": next_id, "t": t, "p": p, "v": Vector2.ZERO, "hp": hpv, "mhp": hpv, "r": zd.r, "spd": zd.spd * minf(1.25, 1.0 + wave * 0.012) * randf_range(0.9, 1.1), "dmg": zd.dmg * (1.0 + 0.04 * wave), "cd": 0.0, "buff": 0.0, "burn": 0.0, "flash": 0.0, "kb": Vector2.ZERO, "ai": randf_range(1.0, 3.0), "st": "", "face": 0.0, "col": zd.col, "boss": false, "ph": randf() * TAU}
	next_id += 1
	zs.append(z)
	return z

func _spawn_boss(p: Vector2) -> void:
	var bi = int((wave / 5 - 1)) % 3
	var bd = Data.BOSSES[bi]
	var cyc = int((wave / 5 - 1) / 3)
	var hpv = bd.hp * (1.0 + 0.6 * cyc) * info.hp
	var z = {"id": next_id, "t": "boss", "bi": bi, "p": p, "v": Vector2.ZERO, "hp": hpv, "mhp": hpv, "r": bd.r, "spd": bd.spd, "dmg": 30.0, "cd": 0.0, "buff": 0.0, "burn": 0.0, "flash": 0.0, "kb": Vector2.ZERO, "ai": 3.0, "st": "", "face": 0.0, "col": bd.col, "boss": true, "mv": 0, "name": bd.name, "ph": 0.0, "sd": Vector2.ZERO, "st_t": 0.0}
	next_id += 1
	zs.append(z)
	boss = z
	_say(bd.name + " has clocked in!", Color(1, 0.4, 0.35))
	shake = 12.0

# ------------------------------------------------------------------ zombies
func _update_zombies(dt: float) -> void:
	var grid = {}
	for z in zs:
		var key = Vector2i(int(z.p.x / 48.0), int(z.p.y / 48.0))
		if not grid.has(key):
			grid[key] = []
		grid[key].append(z)
	for z in zs:
		if z.hp <= 0:
			continue
		z.flash -= dt
		z.cd -= dt
		z.buff -= dt
		z.ph += dt * 6.0
		if z.burn > 0.0:
			z.burn -= dt
			_hurt(z, 12.0 * dt * (1.0 + 0.3 * tier("flamer")), Vector2.ZERO, "burn", false)
			if randf() < dt * 14.0:
				_part(z.p + Vector2(randf_range(-z.r, z.r), randf_range(-z.r, z.r)), Vector2(0, -50), Color(1.0, randf_range(0.4, 0.8), 0.1), 0.4, 3.0)
			if z.hp <= 0:
				continue
		var to = pp - z.p
		var d = to.length()
		var bf = 1.35 if z.buff > 0.0 else 1.0
		var spd = z.spd * bf
		var want = _flow_dir(z.p) if alive else Vector2.from_angle(z.ph * 0.1)
		if demo and d > 380.0:
			want = _flow_dir(z.p)
		match z.t:
			"spitter":
				if d < 360.0 and z.cd <= 0.0 and alive:
					z.cd = 2.4
					ebul.append({"p": z.p, "v": to.normalized() * 300.0, "dmg": z.dmg * bf, "life": 1.7})
					Sfx.play("spit", 1.0, -6.0)
				if d < 240.0:
					want = -to.normalized().rotated(0.6)
			"screamer":
				z.ai -= dt
				if z.ai <= 0.0 and d < 460.0:
					z.ai = 5.0
					rings.append({"p": z.p, "r": 10.0, "mr": 240.0, "life": 0.6, "ml": 0.6, "c": Color(0.9, 0.4, 1.0), "dmg": 0.0})
					Sfx.play("scream", 1.0, -3.0)
					for o in zs:
						if o.p.distance_to(z.p) < 240.0 and o != z:
							o.buff = 6.0
				if d < 220.0:
					want = -to.normalized().rotated(0.8)
			"exploder":
				if d < z.r + PR + 18.0 and alive:
					z.hp = 0
					_kill(z)
					continue
			"boss":
				want = _boss_ai(z, dt, want, d, to)
				spd = z.spd
		if z.st == "charge":
			z.v = z.sd * 520.0
		else:
			z.v = z.v.lerp(want * spd, 1.0 - exp(-7.0 * dt))
		z.p += (z.v + z.kb) * dt
		z.kb = z.kb.lerp(Vector2.ZERO, 1.0 - exp(-8.0 * dt))
		if z.v.length() > 5.0:
			z.face = lerp_angle(z.face, to.angle() if d < 300.0 else z.v.angle(), 1.0 - exp(-8.0 * dt))
		# separation
		var key = Vector2i(int(z.p.x / 48.0), int(z.p.y / 48.0))
		for ox in range(-1, 2):
			for oy in range(-1, 2):
				var cl = grid.get(key + Vector2i(ox, oy))
				if cl == null:
					continue
				for o in cl:
					if o == z:
						continue
					var sep = z.p - o.p
					var sl = sep.length()
					var minr = z.r + o.r
					if sl < minr and sl > 0.01:
						var push = sep / sl * (minr - sl) * (0.15 if z.boss else 0.5)
						z.p += push
		var tp = z.p - pp
		if alive and tp.length() < z.r + PR and tp.length() > 0.01:
			z.p = pp + tp.normalized() * (z.r + PR)
		var before = z.p
		z.p = _collide(z.p, z.r)
		if z.st == "charge" and before.distance_to(z.p) > 1.0:
			z.st = ""
			z.ai = 1.5
			shake = maxf(shake, 9.0)
			Sfx.play("slam", 1.2)
		_defense_contact(z, dt)
		# attack player
		if alive and d < z.r + PR + 4.0 and z.cd <= 0.0 and z.t != "spitter":
			z.cd = 0.9
			_hurt_player(z.dmg * (1.25 if z.buff > 0.0 else 1.0), to.normalized())
		elif alive and z.t == "spitter" and d < z.r + PR + 4.0 and z.cd <= 1.6:
			z.cd = 2.4
			_hurt_player(z.dmg, to.normalized())
	for k in range(zs.size() - 1, -1, -1):
		if zs[k].hp <= 0:
			zs.remove_at(k)
	if randf() < dt * 0.25 and zs.size() > 0:
		Sfx.play("groan", randf_range(0.8, 1.2), -10.0)

func _boss_ai(z: Dictionary, dt: float, want: Vector2, d: float, to: Vector2) -> Vector2:
	z.st_t -= dt
	match z.st:
		"wind":
			if z.st_t <= 0.0:
				z.st = "charge"
				z.st_t = 0.8
				Sfx.play("dash", 0.5)
			return Vector2.ZERO
		"charge":
			if z.st_t <= 0.0:
				z.st = ""
				z.ai = 2.0
			return z.sd
		"slamwind":
			if z.st_t <= 0.0:
				z.st = ""
				z.ai = 2.2
				rings.append({"p": z.p, "r": 20.0, "mr": 400.0, "life": 0.9, "ml": 0.9, "c": Color(1.0, 0.45, 0.3), "dmg": 26.0, "hit": false})
				shake = 14.0
				Sfx.play("slam")
			return Vector2.ZERO
	z.ai -= dt * (1.3 if z.hp < z.mhp * 0.5 else 1.0)
	if z.ai <= 0.0 and alive:
		var moves = Data.BOSSES[z.bi].moves
		var mv = moves[z.mv % moves.size()]
		z.mv += 1
		z.ai = 3.0
		match mv:
			"charge":
				z.st = "wind"
				z.st_t = 0.75
				z.sd = to.normalized()
			"summon":
				rings.append({"p": z.p, "r": 10.0, "mr": 160.0, "life": 0.5, "ml": 0.5, "c": Color(0.5, 1.0, 0.5), "dmg": 0.0})
				Sfx.play("groan", 0.7)
				for i in (5 if zs.size() < MAX_ALIVE else 0):
					_spawn("runner" if i % 2 == 0 else "crawler", z.p + Vector2.from_angle(i * TAU / 5.0) * (z.r + 26.0))
			"volley":
				Sfx.play("spit", 0.7)
				for i in 16:
					ebul.append({"p": z.p, "v": Vector2.from_angle(i * TAU / 16.0 + time) * 230.0, "dmg": 14.0, "life": 2.4})
				for i in 3:
					ebul.append({"p": z.p, "v": to.normalized().rotated((i - 1) * 0.18) * 330.0, "dmg": 14.0, "life": 2.0})
			"slam":
				z.st = "slamwind"
				z.st_t = 0.65
	return want

func _defense_contact(z: Dictionary, dt: float) -> void:
	for b in bars:
		var r = Rect2(b.p - Vector2(18, 18), Vector2(36, 36))
		var cp = Vector2(clampf(z.p.x, r.position.x, r.end.x), clampf(z.p.y, r.position.y, r.end.y))
		var dd = z.p - cp
		if dd.length() < z.r:
			z.p = cp + (dd.normalized() if dd.length() > 0.01 else Vector2.UP) * z.r
			if z.cd <= 0.0:
				z.cd = 0.9
				b.hp -= z.dmg * (3.0 if z.boss else 1.0)
				_burst(cp, Color(0.75, 0.55, 0.3), 3, 80.0)
				Sfx.play("hit", 0.6, -8.0)
	for t in turrets:
		var dd = z.p - t.p
		if dd.length() < z.r + 16.0:
			z.p = t.p + dd.normalized() * (z.r + 16.0)
			if z.cd <= 0.0:
				z.cd = 0.9
				t.hp -= z.dmg * (3.0 if z.boss else 1.0)
				_burst(t.p, Color(0.7, 0.8, 0.9), 3, 80.0)

func _hurt(z: Dictionary, dmg: float, dir: Vector2, kind: String, fx := true) -> void:
	if z.hp <= 0:
		return
	if z.t == "riot" and (kind == "bullet" or kind == "bolt" or kind == "melee"):
		var facing = Vector2.from_angle(z.face)
		if facing.dot(-dir) > 0.35:
			dmg *= 0.3
			if fx:
				_burst(z.p + facing * z.r, Color(0.8, 0.9, 1.0), 4, 160.0)
				Sfx.play("shield", 1.0, -6.0)
	z.hp -= dmg
	if fx:
		z.flash = 0.08
		var kres = 0.12 if (z.t == "brute" or z.boss) else 1.0
		z.kb += dir * 60.0 * kres
		_burst(z.p - dir * z.r * 0.5, z.col.lightened(0.2), 2, 90.0)
		if dmg >= 1.0:
			_text(z.p + Vector2(randf_range(-8, 8), -z.r - 6), str(int(dmg)), Color(1, 1, 1) if dmg < 60 else Color(1, 0.85, 0.3))
	if z.hp <= 0:
		_kill(z)

func _kill(z: Dictionary) -> void:
	z.hp = 0
	kills += 1
	var zd = Data.ZOMBIES.get(z.t, {"cash": 500})
	var val = int(zd.cash * (1.3 if perks.has("bounty") else 1.0))
	if z.boss:
		val = 600 + wave * 40
		boss = null
		announce = z.name + " FIRED!"
		announce_t = 2.5
		Sfx.play("victory")
		Sfx.music("wave")
		for i in 6:
			pickups.append({"p": z.p + Vector2.from_angle(i) * 30, "t": "med" if i == 0 else "ammo" if i == 1 else "cash", "v": 50, "life": 25.0})
	score += val
	if not demo:
		var coins = clampi(val / 15, 1, 8)
		for i in coins:
			pickups.append({"p": z.p + Vector2(randf_range(-12, 12), randf_range(-12, 12)), "t": "cash", "v": max(1, val / coins), "life": 18.0})
		if randf() < 0.035:
			pickups.append({"p": z.p, "t": "med", "v": 0, "life": 18.0})
		elif randf() < 0.05:
			pickups.append({"p": z.p, "t": "ammo", "v": 0, "life": 18.0})
	_splat(z.p, z.r * (1.6 if z.boss else 1.2), z.col.darkened(0.25))
	_burst(z.p, z.col, 10 if not z.boss else 40, 200.0)
	Sfx.play("zdie", randf_range(0.8, 1.2), -4.0)
	shake = maxf(shake, 3.0 if not z.boss else 16.0)
	if z.t == "exploder":
		_explode(z.p, 95.0, z.dmg, false)

func _explode(p: Vector2, rad: float, dmg: float, by_player: bool) -> void:
	Sfx.play("explode")
	shake = maxf(shake, 13.0)
	_light(p, rad * 2.6, 1.0, 0.3)
	rings.append({"p": p, "r": 8.0, "mr": rad, "life": 0.3, "ml": 0.3, "c": Color(1.0, 0.7, 0.3), "dmg": 0.0})
	for i in 26:
		_part(p, Vector2.from_angle(randf() * TAU) * randf_range(60, 320), Color(1.0, randf_range(0.3, 0.85), 0.1), randf_range(0.3, 0.7), randf_range(3, 7))
	for i in 8:
		_part(p, Vector2.from_angle(randf() * TAU) * randf_range(20, 90), Color(0.25, 0.25, 0.28, 0.7), 1.0, 10.0)
	_splat(p, rad * 0.55, Color(0.08, 0.08, 0.1, 0.8))
	for z in zs:
		var d = z.p.distance_to(p)
		if d < rad + z.r and z.hp > 0:
			_hurt(z, dmg * (1.0 - 0.5 * d / (rad + z.r)) * (1.0 if by_player else 1.5), (z.p - p).normalized(), "explode")
			z.kb += (z.p - p).normalized() * 260.0 * (0.2 if z.boss else 1.0)
	var pd = pp.distance_to(p)
	if pd < rad + PR and alive:
		_hurt_player(dmg * (0.3 if by_player else 1.0), (pp - p).normalized())
	if not by_player:
		for b in bars:
			if b.p.distance_to(p) < rad + 18.0:
				b.hp -= dmg * 2.0
		for t in turrets:
			if t.p.distance_to(p) < rad + 16.0:
				t.hp -= dmg * 2.0

func _hurt_player(dmg: float, dir: Vector2) -> void:
	if inv_t > 0.0 or dash_t > 0.0 or not alive or demo:
		return
	hp -= dmg
	inv_t = 0.15
	hurt_t = minf(1.0, hurt_t + 0.5)
	pv += dir * 220.0
	shake = maxf(shake, 7.0)
	Sfx.play("hurt")
	_burst(pp, Color(1.0, 0.5, 0.4), 5, 120.0)
	if hp <= 0.0:
		if perks.has("second") and not second_used:
			second_used = true
			hp = mhp * 0.5
			inv_t = 2.0
			_say("SECOND WIND!", Color(0.5, 1.0, 0.7))
			_explode(pp, 140.0, 120.0, true)
			return
		hp = 0.0
		alive = false
		state = "dead"
		Sfx.play("defeat")
		Sfx.music("")
		_splat(pp, 20.0, Color(0.25, 0.4, 0.9, 0.8))
		ended.emit(false)

# ------------------------------------------------------------------ projectiles
func _update_bullets(dt: float) -> void:
	for k in range(bullets.size() - 1, -1, -1):
		var b = bullets[k]
		var p0 = b.p
		b.p += b.v * dt
		b.life -= dt
		var dead = b.life <= 0.0
		if b.kind == "flame":
			b.age += dt
			b.v *= 1.0 - 1.8 * dt
			if randf() < 0.15:
				_light(b.p, 90.0, 0.55, 0.05)
		if b.kind == "rocket" and randf() < 0.7:
			_part(b.p, -b.v.normalized().rotated(randf_range(-0.4, 0.4)) * 60.0, Color(0.6, 0.6, 0.65, 0.6), 0.5, 5.0)
			_light(b.p, 80.0, 0.6, 0.04)
		if not dead and _in_wall(b.p):
			dead = true
			if b.kind == "rocket":
				_explode(b.p, 115.0, b.dmg, true)
			elif b.kind != "flame":
				_burst(b.p, Color(1, 0.9, 0.6), 3, 110.0)
		if not dead:
			for z in zs:
				if z.hp <= 0 or b.hit.has(z.id):
					continue
				var rr = z.r + (14.0 if b.kind == "flame" else 2.0)
				var cp = Geometry2D.get_closest_point_to_segment(z.p, p0, b.p)
				if cp.distance_to(z.p) < rr:
					if b.kind == "rocket":
						_explode(b.p, 115.0, b.dmg, true)
						dead = true
						break
					b.hit.append(z.id)
					if b.kind == "flame":
						z.burn = 2.0
						_hurt(z, b.dmg, b.v.normalized(), "flame", randf() < 0.3)
					else:
						_hurt(z, b.dmg, b.v.normalized(), b.kind)
						z.kb += b.v.normalized() * b.kb * (0.12 if (z.t == "brute" or z.boss) else 1.0)
					if b.pierce <= 0:
						dead = true
						break
					b.pierce -= 1
		if dead:
			bullets.remove_at(k)
	for k in range(ebul.size() - 1, -1, -1):
		var e = ebul[k]
		e.p += e.v * dt
		e.life -= dt
		var dead = e.life <= 0.0 or _in_wall(e.p)
		if not dead and e.p.distance_to(pp) < PR + 7.0 and alive:
			_hurt_player(e.dmg, e.v.normalized())
			dead = true
		if dead:
			_splat(e.p, 9.0, Color(0.45, 0.8, 0.2, 0.7))
			_burst(e.p, Color(0.6, 1.0, 0.3), 5, 90.0)
			ebul.remove_at(k)
	# turrets
	var dmgm = 1.5 if perks.has("overclock") else 1.0
	for k in range(turrets.size() - 1, -1, -1):
		var t = turrets[k]
		if t.hp <= 0:
			_explode(t.p, 50.0, 0.0, true)
			turrets.remove_at(k)
			_say("A turret was destroyed!", Color(1, 0.5, 0.4))
			continue
		t.cd -= dt
		var best = null
		var bd = 330.0
		for z in zs:
			var d = z.p.distance_to(t.p)
			if d < bd:
				bd = d
				best = z
		if best:
			t.ang = lerp_angle(t.ang, (best.p - t.p).angle(), 1.0 - exp(-12.0 * dt))
			if t.cd <= 0.0:
				t.cd = 1.0 / (3.0 * dmgm)
				var dv = Vector2.from_angle(t.ang)
				bullets.append({"p": t.p + dv * 18.0, "v": dv.rotated(randf_range(-0.05, 0.05)) * 900.0, "dmg": 13.0 * dmgm * (1.0 + 0.05 * wave), "life": 0.45, "pierce": 0, "kind": "bullet", "hit": [], "c": Color(0.5, 1.0, 1.0), "kb": 40.0})
				_light(t.p + dv * 18.0, 90.0, 0.7, 0.05)
				Sfx.play("turret", 1.0, -10.0)
	for k in range(bars.size() - 1, -1, -1):
		if bars[k].hp <= 0:
			_burst(bars[k].p, Color(0.7, 0.5, 0.3), 14, 200.0)
			Sfx.play("build", 0.6)
			bars.remove_at(k)

# ------------------------------------------------------------------ fx
func _part(p: Vector2, v: Vector2, c: Color, life: float, s: float) -> void:
	if parts.size() > 500:
		return
	parts.append({"p": p, "v": v, "c": c, "life": life, "ml": life, "s": s})

func _burst(p: Vector2, c: Color, n: int, spd: float) -> void:
	for i in n:
		_part(p, Vector2.from_angle(randf() * TAU) * randf_range(spd * 0.3, spd), c, randf_range(0.25, 0.55), randf_range(2.0, 4.5))

func _splat(p: Vector2, r: float, c: Color) -> void:
	var blobs = []
	for i in 7:
		blobs.append([Vector2.from_angle(randf() * TAU) * randf_range(0, r), randf_range(r * 0.25, r * 0.6)])
	splats.append({"p": p, "c": c, "b": blobs, "r": r})
	if splats.size() > 260:
		splats.pop_front()

func _text(p: Vector2, s: String, c: Color) -> void:
	if texts.size() > 60:
		return
	texts.append({"p": p, "s": s, "c": c, "life": 0.7})

func _light(p: Vector2, r: float, i: float, life: float) -> void:
	if r <= 0.0:
		return
	lights.append({"p": p, "r": r, "i": i, "life": life, "ml": life})

func _say(t: String, c: Color) -> void:
	message.emit(t, c)

func _update_misc(dt: float) -> void:
	for k in range(parts.size() - 1, -1, -1):
		var q = parts[k]
		q.life -= dt
		q.p += q.v * dt
		q.v *= 1.0 - 3.0 * dt
		if q.life <= 0.0:
			parts.remove_at(k)
	for arr in [texts, lights, arcs, slashes]:
		for k in range(arr.size() - 1, -1, -1):
			arr[k].life -= dt
			if arr[k].life <= 0.0:
				arr.remove_at(k)
	for t in texts:
		t.p.y -= 40.0 * dt
	for k in range(rings.size() - 1, -1, -1):
		var r = rings[k]
		r.life -= dt
		r.r = lerpf(r.mr, 10.0, r.life / r.ml)
		if r.dmg > 0.0 and not r.hit and absf(pp.distance_to(r.p) - r.r) < 22.0:
			r.hit = true
			_hurt_player(r.dmg, (pp - r.p).normalized())
		if r.life <= 0.0:
			rings.remove_at(k)
	for k in range(pickups.size() - 1, -1, -1):
		pickups[k].life -= dt
		if pickups[k].life <= 0.0:
			pickups.remove_at(k)

func _update_camera(dt: float) -> void:
	var vs = get_viewport_rect().size
	var target = pp + Vector2.from_angle(aim) * minf(80.0, vs.x * 0.08)
	var half = vs * 0.5
	target.x = clampf(target.x, half.x, maxf(half.x, m.size.x - half.x)) if m.size.x > vs.x else m.size.x * 0.5
	target.y = clampf(target.y, half.y, maxf(half.y, m.size.y - half.y)) if m.size.y > vs.y else m.size.y * 0.5
	cam.position = cam.position.lerp(target, 1.0 - exp(-7.0 * dt))
	shake = maxf(0.0, shake - dt * 30.0)
	cam.offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * shake
	# lighting uniforms
	var ct = get_viewport().get_canvas_transform()
	var sc = ct.get_scale().x
	var sm: ShaderMaterial = dark.material
	sm.set_shader_parameter("vsize", dark.size)
	sm.set_shader_parameter("ppos", ct * pp)
	sm.set_shader_parameter("ang", aim)
	var big = perks.has("battery")
	sm.set_shader_parameter("cone", 0.62 if big else 0.5)
	sm.set_shader_parameter("range", (560.0 if big else 430.0) * sc)
	sm.set_shader_parameter("halo", 95.0 * sc)
	sm.set_shader_parameter("ambient", 0.0 if not alive and false else (0.8 if map_i == 2 else 0.87))
	sm.set_shader_parameter("flick", 0.93 + 0.07 * sin(time * 23.0) * sin(time * 7.0) if randf() > 0.01 else 0.6)
	sm.set_shader_parameter("hurt", hurt_t)
	var lp = PackedVector3Array()
	var li = PackedFloat32Array()
	var all = [{"p": m.bench, "r": 150.0, "i": 0.75, "life": 1.0, "ml": 1.0}]
	all.append_array(lights)
	for z in zs:
		if z.burn > 0.0 and all.size() < 22:
			all.append({"p": z.p, "r": 70.0, "i": 0.6, "life": 1.0, "ml": 1.0})
	for t in turrets:
		all.append({"p": t.p, "r": 55.0, "i": 0.5, "life": 1.0, "ml": 1.0})
	var n = 0
	for L in all:
		if n >= 16:
			break
		var sp = ct * L.p
		lp.append(Vector3(sp.x, sp.y, L.r * sc))
		li.append(L.i * clampf(L.life / L.ml * 1.5, 0.0, 1.0))
		n += 1
	while lp.size() < 16:
		lp.append(Vector3.ZERO)
		li.append(0.0)
	sm.set_shader_parameter("lights", lp)
	sm.set_shader_parameter("li", li)
	sm.set_shader_parameter("nl", n)

# ------------------------------------------------------------------ collision helpers
func _collide(p: Vector2, r: float) -> Vector2:
	for wl in m.walls:
		var rc: Rect2 = wl[0]
		if p.x < rc.position.x - r or p.x > rc.end.x + r or p.y < rc.position.y - r or p.y > rc.end.y + r:
			continue
		var cp = Vector2(clampf(p.x, rc.position.x, rc.end.x), clampf(p.y, rc.position.y, rc.end.y))
		var d = p - cp
		var l = d.length()
		if l < r:
			if l > 0.01:
				p = cp + d / l * r
			else:
				var c = rc.get_center()
				var ex = (rc.size.x * 0.5 + r) - absf(p.x - c.x)
				var ey = (rc.size.y * 0.5 + r) - absf(p.y - c.y)
				if ex < ey:
					p.x += ex * signf(p.x - c.x + 0.001)
				else:
					p.y += ey * signf(p.y - c.y + 0.001)
	p.x = clampf(p.x, r, m.size.x - r)
	p.y = clampf(p.y, r, m.size.y - r)
	return p

func _in_wall(p: Vector2) -> bool:
	if p.x < 0 or p.y < 0 or p.x > m.size.x or p.y > m.size.y:
		return true
	for wl in m.walls:
		if wl[0].has_point(p):
			return true
	return false

# ------------------------------------------------------------------ building & shop actions
func near_bench() -> bool:
	return pp.distance_to(m.bench) < 95.0

func can_shop() -> bool:
	return near_bench() and state == "intermission"

func build_target() -> Vector2:
	var t = pp + Vector2.from_angle(aim) * 60.0
	if mouse_aim:
		var mp = get_global_mouse_position()
		if mp.distance_to(pp) < 220.0:
			t = mp
	return Vector2((floor(t.x / CELL) + 0.5) * CELL, (floor(t.y / CELL) + 0.5) * CELL)

func build_ok(t: Vector2) -> bool:
	if t.distance_to(pp) < 28.0 or t.distance_to(m.bench) < 50.0:
		return false
	if _in_wall(t) or _collide(t, 18.0) != t:
		return false
	for b in bars:
		if b.p.distance_to(t) < 30.0:
			return false
	for q in turrets:
		if q.p.distance_to(t) < 30.0:
			return false
	return true

func place(kind: String) -> void:
	if not alive or demo:
		return
	var cost = Data.BARRICADE_COST if kind == "bar" else Data.TURRET_COST
	var t = build_target()
	if kind == "bar" and bars.size() >= 24:
		_say("Barricade limit reached (24).", Color(1, 0.6, 0.4))
		Sfx.play("deny")
		return
	if kind == "tur" and turrets.size() >= 6:
		_say("Turret limit reached (6).", Color(1, 0.6, 0.4))
		Sfx.play("deny")
		return
	if cash < cost:
		_say("Need $%d to build that." % cost, Color(1, 0.6, 0.4))
		Sfx.play("deny")
		return
	if not build_ok(t):
		_say("Can't build there.", Color(1, 0.6, 0.4))
		Sfx.play("deny")
		return
	cash -= cost
	if kind == "bar":
		bars.append({"p": t, "hp": 280.0, "mhp": 280.0})
	else:
		turrets.append({"p": t, "hp": 220.0, "mhp": 220.0, "cd": 0.0, "ang": aim})
	_burst(t, Color(0.9, 0.8, 0.5), 10, 140.0)
	Sfx.play("build")
	shake = maxf(shake, 3.0)

func apply_perk(id: String) -> void:
	perks[id] = true
	if id == "tough":
		mhp += 40.0
		hp += 40.0
	if id == "pockets":
		for w in order:
			refill(w)

# ------------------------------------------------------------------ drawing (world layer)
func _view() -> Rect2:
	var vs = get_viewport_rect().size
	return Rect2(cam.get_screen_center_position() - vs * 0.5 - Vector2(60, 60), vs + Vector2(120, 120))

func _h(x: int, y: int) -> float:
	return fposmod(sin(x * 12.9898 + y * 78.233 + map_i * 7.0) * 43758.5453, 1.0)

func _draw() -> void:
	var v = _view()
	var ts: float = m.tile
	var x0 = maxi(0, int(v.position.x / ts))
	var y0 = maxi(0, int(v.position.y / ts))
	var x1 = mini(int(ceil(m.size.x / ts)), int(v.end.x / ts) + 1)
	var y1 = mini(int(ceil(m.size.y / ts)), int(v.end.y / ts) + 1)
	draw_rect(Rect2(Vector2(-400, -400), m.size + Vector2(800, 800)), Color(0.05, 0.05, 0.07))
	for y in range(y0, y1):
		for x in range(x0, x1):
			var c: Color = m.floor[(x + y) % 2]
			c = c.lightened(_h(x, y) * 0.05)
			draw_rect(Rect2(x * ts, y * ts, ts - 1, ts - 1), c)
			if map_i == 1 and _h(y, x) > 0.86:
				draw_circle(Vector2(x * ts + ts * _h(x, x), y * ts + ts * _h(y, y)), 10.0 + 14.0 * _h(x + 1, y), Color(0.1, 0.1, 0.11, 0.6))
	if map_i == 1:
		draw_rect(Rect2(0, 230, m.size.x, 8), Color(0.75, 0.65, 0.25, 0.5))
		draw_rect(Rect2(0, 962, m.size.x, 8), Color(0.75, 0.65, 0.25, 0.5))
	for dcr in m.decor:
		var p: Vector2 = dcr[1]
		match dcr[0]:
			"lane":
				draw_rect(Rect2(p.x, p.y - 3, 70, 6), Color(0.85, 0.85, 0.8, 0.45))
			"plant":
				draw_circle(p, 18, Color(0.2, 0.14, 0.1))
				for i in 6:
					draw_circle(p + Vector2.from_angle(i * 1.05) * 9, 9, Color(0.2, 0.5, 0.25))
	for s in splats:
		if not v.has_point(s.p):
			continue
		for bl in s.b:
			draw_circle(s.p + bl[0], bl[1], s.c)
		draw_circle(s.p, s.r * 0.55, s.c)
	# bench
	var bp: Vector2 = m.bench
	draw_rect(Rect2(bp - Vector2(44, 20) + Vector2(5, 6), Vector2(88, 40)), Color(0, 0, 0, 0.4))
	draw_rect(Rect2(bp - Vector2(44, 20), Vector2(88, 40)), Color(0.45, 0.3, 0.18))
	draw_rect(Rect2(bp - Vector2(40, 16), Vector2(80, 32)), Color(0.55, 0.38, 0.22))
	draw_rect(Rect2(bp + Vector2(-30, -6), Vector2(34, 8)), Color(0.25, 0.27, 0.32))
	draw_circle(bp + Vector2(22, 0), 7, Color(0.9, 0.6, 0.2))
	# walls
	for wl in m.walls:
		var r: Rect2 = wl[0]
		if not v.intersects(r):
			continue
		_draw_wall(r, wl[1])
	for b in bars:
		var r = Rect2(b.p - Vector2(18, 18), Vector2(36, 36))
		draw_rect(Rect2(r.position + Vector2(4, 5), r.size), Color(0, 0, 0, 0.4))
		draw_rect(r, Color(0.42, 0.3, 0.18))
		for i in 3:
			draw_rect(Rect2(r.position.x, r.position.y + 3 + i * 11, 36, 8), Color(0.6, 0.43, 0.25))
		draw_line(r.position + Vector2(3, 3), r.end - Vector2(3, 3), Color(0.35, 0.24, 0.13), 4)
		if b.hp < b.mhp:
			_bar(b.p + Vector2(-18, -26), 36, b.hp / b.mhp, Color(0.9, 0.7, 0.3))
	for t in turrets:
		draw_circle(t.p + Vector2(3, 4), 17, Color(0, 0, 0, 0.4))
		draw_circle(t.p, 16, Color(0.3, 0.34, 0.4))
		draw_circle(t.p, 11, Color(0.45, 0.5, 0.58))
		draw_line(t.p, t.p + Vector2.from_angle(t.ang) * 22, Color(0.2, 0.22, 0.26), 7)
		if t.hp < t.mhp:
			_bar(t.p + Vector2(-18, -26), 36, t.hp / t.mhp, Color(0.5, 0.9, 1.0))
	for pk in pickups:
		match pk.t:
			"cash":
				draw_circle(pk.p, 5, Color(0.95, 0.78, 0.2))
				draw_circle(pk.p - Vector2(1, 1), 2.5, Color(1, 0.95, 0.6))
			"med":
				draw_rect(Rect2(pk.p - Vector2(9, 9), Vector2(18, 18)), Color(0.95, 0.95, 0.95))
				draw_rect(Rect2(pk.p - Vector2(2, 6), Vector2(4, 12)), Color(0.9, 0.2, 0.25))
				draw_rect(Rect2(pk.p - Vector2(6, 2), Vector2(12, 4)), Color(0.9, 0.2, 0.25))
			"ammo":
				draw_rect(Rect2(pk.p - Vector2(10, 7), Vector2(20, 14)), Color(0.35, 0.45, 0.25))
				draw_rect(Rect2(pk.p - Vector2(6, 3), Vector2(12, 6)), Color(0.95, 0.8, 0.3))
	for z in zs:
		if v.has_point(z.p):
			_draw_zombie(z)
	if alive:
		_draw_player()

func _bar(p: Vector2, w: float, f: float, c: Color) -> void:
	draw_rect(Rect2(p, Vector2(w, 4)), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(p, Vector2(w * clampf(f, 0.0, 1.0), 4)), c)

func _draw_wall(r: Rect2, kind: String) -> void:
	var wc: Color = m.wallc
	draw_rect(Rect2(r.position + Vector2(6, 8), r.size), Color(0, 0, 0, 0.45))
	match kind:
		"part":
			draw_rect(r, wc)
			draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), wc.lightened(0.25))
		"desk":
			draw_rect(r, Color(0.42, 0.33, 0.25))
			draw_rect(Rect2(r.position + Vector2(10, 6), Vector2(26, 6)), Color(0.12, 0.13, 0.16))
			draw_rect(Rect2(r.position + Vector2(12, 7), Vector2(22, 4)), Color(0.3, 0.6, 0.9))
			draw_circle(r.position + Vector2(52, 22), 5, Color(0.85, 0.85, 0.8))
		"glass":
			draw_rect(r, Color(0.55, 0.75, 0.85, 0.35))
			draw_rect(Rect2(r.position, Vector2(r.size.x, 3)), Color(0.8, 0.95, 1.0, 0.6))
		"car", "bus":
			var hue = _h(int(r.position.x), int(r.position.y))
			var cc = Color.from_hsv(hue, 0.45, 0.55) if kind == "car" else Color(0.75, 0.6, 0.2)
			draw_rect(r, cc.darkened(0.3))
			draw_rect(r.grow(-4), cc)
			var horiz = r.size.x > r.size.y
			if horiz:
				draw_rect(Rect2(r.position.x + r.size.x * 0.3, r.position.y + 6, r.size.x * 0.4, r.size.y - 12), Color(0.15, 0.2, 0.28))
			else:
				draw_rect(Rect2(r.position.x + 6, r.position.y + r.size.y * 0.3, r.size.x - 12, r.size.y * 0.4), Color(0.15, 0.2, 0.28))
		"jersey":
			draw_rect(r, Color(0.6, 0.6, 0.58))
			for i in int(r.size.x / 28.0):
				draw_rect(Rect2(r.position.x + i * 28 + 4, r.position.y + 4, 14, r.size.y - 8), Color(0.85, 0.4, 0.2, 0.7))
		"store":
			draw_rect(r, Color(0.16, 0.13, 0.18))
			var top = r.position.y < 600
			var sy = r.end.y - 10 if top else r.position.y
			var nc = Color.from_hsv(_h(int(r.position.x), 3), 0.7, 1.0)
			draw_rect(Rect2(r.position.x + 12, sy, r.size.x - 24, 10), nc)
			draw_rect(Rect2(r.position.x + 40, sy - 30 if top else sy + 14, r.size.x - 80, 16), nc.darkened(0.6))
		"kiosk":
			draw_rect(r, Color(0.45, 0.32, 0.4))
			draw_rect(r.grow(-6), Color(0.6, 0.45, 0.55))
		"fountain":
			var c = r.get_center()
			draw_circle(c, 62, Color(0.5, 0.48, 0.52))
			draw_circle(c, 52, Color(0.15, 0.32, 0.5))
			draw_circle(c, 14 + 3 * sin(time * 3.0), Color(0.5, 0.75, 0.95))
		"escal":
			draw_rect(r, Color(0.3, 0.3, 0.34))
			for i in int(r.size.y / 12.0):
				draw_rect(Rect2(r.position.x + 4, r.position.y + i * 12 + fposmod(time * 20.0, 12.0), r.size.x - 8, 3), Color(0.5, 0.5, 0.55))
		_:
			draw_rect(r, wc)

func _draw_zombie(z: Dictionary) -> void:
	var p: Vector2 = z.p
	var r: float = z.r
	var col: Color = z.col
	if z.flash > 0.0:
		col = Color(1, 1, 1)
	elif z.buff > 0.0:
		col = col.lerp(Color(0.9, 0.4, 1.0), 0.35)
	var f = Vector2.from_angle(z.face)
	var sway = sin(z.ph) * 0.25
	draw_circle(p + Vector2(4, 5), r, Color(0, 0, 0, 0.35))
	if z.buff > 0.0:
		draw_arc(p, r + 5, 0, TAU, 20, Color(0.9, 0.4, 1.0, 0.5), 2)
	match z.t:
		"crawler":
			draw_circle(p, r, col.darkened(0.3))
			for i in 4:
				var a = z.face + (i - 1.5) * 0.9 + sway
				draw_line(p, p + Vector2.from_angle(a) * (r + 7), col.darkened(0.4), 3)
			draw_circle(p + f * 3, r * 0.8, col)
			return
		"riot":
			draw_circle(p, r, col.darkened(0.3))
			draw_circle(p, r - 3, col)
			draw_arc(p, r + 5, z.face - 1.0, z.face + 1.0, 10, Color(0.75, 0.85, 0.95), 6)
			draw_circle(p + f * 2, r * 0.55, Color(0.25, 0.3, 0.4))
			return
		"boss":
			_draw_boss(z, p, r, col, f)
			return
	var arm_len = r * (1.1 if z.t != "runner" else 0.9)
	for s in [-1, 1]:
		var base = p + f.rotated(s * 1.1) * r * 0.8
		draw_line(base, base + f.rotated(s * (0.15 + sway * s)) * arm_len, col.darkened(0.35), r * 0.42)
	draw_circle(p, r, col.darkened(0.3))
	draw_circle(p, r - 2.5, col)
	match z.t:
		"brute":
			draw_circle(p + f.rotated(1.6) * r * 0.6, r * 0.45, col.darkened(0.15))
			draw_circle(p + f.rotated(-1.6) * r * 0.6, r * 0.45, col.darkened(0.15))
		"spitter":
			draw_circle(p - f * r * 0.35, r * 0.55, Color(0.65, 0.95, 0.3))
		"exploder":
			var pulse = 1.0 + 0.08 * sin(z.ph * 2.0)
			draw_circle(p, r * 0.75 * pulse, Color(1.0, 0.7, 0.35))
			draw_circle(p, r * 0.4 * pulse, Color(1.0, 0.9, 0.5))
		"screamer":
			draw_circle(p + f * r * 0.4, r * 0.35, Color(0.25, 0.05, 0.2))
		"runner":
			draw_line(p - f * r, p - f * (r + 8), col.darkened(0.4), 3)
	draw_circle(p + f * r * 0.35, r * 0.45, col.lightened(0.12))
	if z.mhp > 150.0 and z.hp < z.mhp:
		_bar(p + Vector2(-r, -r - 9), r * 2.0, z.hp / z.mhp, Color(0.9, 0.35, 0.3))

func _draw_boss(z: Dictionary, p: Vector2, r: float, col: Color, f: Vector2) -> void:
	if z.st == "wind":
		draw_line(p, p + z.sd * 420.0, Color(1, 0.2, 0.2, 0.25), r * 1.6)
	if z.st == "slamwind":
		draw_arc(p, 400.0 * (1.0 - z.st_t / 0.65), 0, TAU, 48, Color(1, 0.3, 0.2, 0.5), 4)
	for s in [-1, 1]:
		var base = p + f.rotated(s * 1.2) * r * 0.8
		draw_circle(base + f * r * 0.5, r * 0.32, col.darkened(0.35))
	draw_circle(p, r, col.darkened(0.35))
	draw_circle(p, r - 4, col)
	match z.bi:
		0:
			draw_line(p + f * r * 0.2, p + f * r * 0.95, Color(0.75, 0.15, 0.2), 9)
			draw_rect(Rect2(p - Vector2(r * 0.6, r * 0.6), Vector2(r * 1.2, r * 1.2)), Color(0.2, 0.22, 0.3, 0.6))
		1:
			var cp = p + f.rotated(0.9) * r * 0.9
			draw_rect(Rect2(cp - Vector2(10, 13), Vector2(20, 26)), Color(0.85, 0.8, 0.65))
			draw_rect(Rect2(cp - Vector2(6, 15), Vector2(12, 5)), Color(0.4, 0.4, 0.45))
		2:
			for i in 8:
				var a = i * TAU / 8.0 + time * 0.5
				draw_line(p + Vector2.from_angle(a) * r * 0.9, p + Vector2.from_angle(a) * (r + 12), Color(0.95, 0.75, 0.5), 5)
	draw_circle(p + f * r * 0.35, r * 0.45, col.lightened(0.15))

func _draw_player() -> void:
	var f = Vector2.from_angle(aim)
	var w = wdef()
	var flick = inv_t > 0.0 and int(time * 30.0) % 2 == 0
	draw_circle(pp + Vector2(4, 5), PR, Color(0, 0, 0, 0.4))
	var glen = {"pistol": 14, "smg": 18, "shotgun": 24, "rifle": 30, "minigun": 28, "flamer": 26, "crossbow": 20, "rocket": 32, "tesla": 22, "katana": 0}
	var gl = float(glen[w.id])
	var gcol = {"flamer": Color(0.7, 0.3, 0.2), "tesla": Color(0.3, 0.5, 0.8), "crossbow": Color(0.45, 0.32, 0.2), "rocket": Color(0.3, 0.38, 0.28)}.get(w.id, Color(0.18, 0.19, 0.24))
	if w.id == "katana":
		var sa = aim + (0.9 if fire_cd > 0.2 else -0.9)
		draw_line(pp + f.rotated(0.8) * 10, pp + f.rotated(0.8) * 10 + Vector2.from_angle(sa) * 36, Color(0.85, 0.9, 0.95), 3)
	else:
		var gw2 = 7.0 if w.id in ["minigun", "rocket", "shotgun", "flamer"] else 5.0
		draw_line(pp + f.rotated(0.35) * 8, pp + f * (12 + gl), gcol, gw2)
		if w.id == "crossbow":
			draw_line(pp + f * (10 + gl) + f.rotated(PI / 2) * 10, pp + f * (10 + gl) - f.rotated(PI / 2) * 10, gcol, 3)
	var bob = sin(walk_t) * 2.0
	draw_circle(pp + f.rotated(1.3) * (10 + bob), 5, Color(0.95, 0.78, 0.6))
	draw_circle(pp + f.rotated(-1.3) * (10 - bob), 5, Color(0.95, 0.78, 0.6))
	var body = Color(1, 1, 1) if flick else Color(0.22, 0.45, 0.85)
	draw_circle(pp, PR, body.darkened(0.3))
	draw_circle(pp, PR - 2.5, body)
	draw_circle(pp + f * 2, 8, Color(0.3, 0.2, 0.15))
	draw_circle(pp + f * 4, 5, Color(0.95, 0.78, 0.6))
	draw_rect(Rect2(pp - f * 9 - Vector2(4, 4), Vector2(8, 8)), Color(0.9, 0.75, 0.2))

# ------------------------------------------------------------------ drawing (glow layer, above darkness)
func draw_glow(g: Node2D) -> void:
	var v = _view()
	if alive:
		var f = Vector2.from_angle(aim)
		var cone = 0.62 if perks.has("battery") else 0.5
		var rng = 560.0 if perks.has("battery") else 430.0
		var pts = PackedVector2Array([pp + f * 10])
		for i in 9:
			pts.append(pp + Vector2.from_angle(aim - cone * 0.8 + cone * 1.6 * i / 8.0) * rng * 0.8)
		g.draw_colored_polygon(pts, Color(1.0, 0.85, 0.5, 0.05))
		if muzzle_t > 0.0 and wdef().kind != "melee":
			g.draw_circle(pp + f * 30, 9, Color(1, 0.9, 0.5, 0.9))
			g.draw_circle(pp + f * 30, 5, Color(1, 1, 0.9))
		g.draw_circle(pp + f * 7, 2.5, Color(1, 1, 0.8, 0.9))
		if dash_t > 0.0:
			g.draw_circle(pp - dash_dir * 16, 10, Color(0.6, 0.8, 1.0, 0.4))
	for s in slashes:
		var a = s.life / 0.16
		g.draw_arc(s.p, 70.0, s.a - 1.1, s.a + 1.1, 16, Color(0.9, 0.95, 1.0, a), 6.0 * a + 1.0)
		g.draw_arc(s.p, 82.0, s.a - 0.9, s.a + 0.9, 16, Color(0.6, 0.8, 1.0, a * 0.6), 3.0)
	for z in zs:
		if not v.has_point(z.p):
			continue
		var f = Vector2.from_angle(z.face)
		var ec = Color(1.0, 0.25, 0.2) if z.buff <= 0.0 else Color(1.0, 0.4, 1.0)
		if z.t == "exploder":
			ec = Color(1.0, 0.7, 0.2)
		var hr = z.r * (0.45 if not z.boss else 0.5)
		var hc = z.p + f * z.r * 0.4
		for s in [-1, 1]:
			g.draw_circle(hc + f * hr * 0.6 + f.rotated(PI / 2) * s * hr * 0.45, 1.8 if not z.boss else 4.0, ec)
		if z.t == "exploder":
			g.draw_circle(z.p, z.r * 0.4, Color(1.0, 0.6, 0.2, 0.25 + 0.2 * sin(z.ph * 2.0)))
	for b in bullets:
		var d = b.v.normalized()
		match b.kind:
			"flame":
				var a = clampf(b.life * 3.0, 0.0, 1.0)
				var s = 6.0 + b.age * 40.0
				g.draw_circle(b.p, s, Color(1.0, 0.35 + 0.4 * a, 0.1, 0.35 * a + 0.1))
				g.draw_circle(b.p, s * 0.5, Color(1.0, 0.85, 0.4, 0.5 * a))
			"rocket":
				g.draw_line(b.p - d * 14, b.p, Color(0.7, 0.75, 0.7), 6)
				g.draw_circle(b.p - d * 16, 5, Color(1, 0.7, 0.3))
			"bolt":
				g.draw_line(b.p - d * 22, b.p, b.c, 3)
			_:
				g.draw_line(b.p - d * 16, b.p, Color(b.c.r, b.c.g, b.c.b, 0.9), 2.5)
	for e in ebul:
		g.draw_circle(e.p, 7, Color(0.5, 0.95, 0.2, 0.7))
		g.draw_circle(e.p, 3.5, Color(0.85, 1.0, 0.6))
	for a in arcs:
		var pts = a.pts
		for i in pts.size() - 1:
			var p0: Vector2 = pts[i]
			var p1: Vector2 = pts[i + 1]
			var prev = p0
			var n = (p1 - p0).orthogonal().normalized()
			for k in range(1, 7):
				var q = p0.lerp(p1, k / 6.0) + (n * randf_range(-10, 10) if k < 6 else Vector2.ZERO)
				g.draw_line(prev, q, Color(0.6, 0.85, 1.0, 0.9), 3)
				g.draw_line(prev, q, Color(1, 1, 1), 1)
				prev = q
	for q in parts:
		var a = q.life / q.ml
		var c: Color = q.c
		g.draw_circle(q.p, q.s * (0.4 + 0.6 * a), Color(c.r, c.g, c.b, c.a * a))
	for r in rings:
		var a = r.life / r.ml
		g.draw_arc(r.p, r.r, 0, TAU, 48, Color(r.c.r, r.c.g, r.c.b, a), 3.0 + 5.0 * a)
	for t in turrets:
		g.draw_circle(t.p, 3, Color(0.4, 1.0, 1.0))
	for pk in pickups:
		if pk.t == "cash":
			g.draw_circle(pk.p, 2.0, Color(1, 0.9, 0.4, 0.8))
		else:
			g.draw_arc(pk.p, 14 + 2 * sin(time * 5.0), 0, TAU, 16, Color(1, 1, 1, 0.5), 2)
	for t in texts:
		var a = clampf(t.life / 0.4, 0.0, 1.0)
		g.draw_string(font, t.p + Vector2(-20, 0), t.s, HORIZONTAL_ALIGNMENT_CENTER, 40, 13, Color(t.c.r, t.c.g, t.c.b, a))
	if not demo:
		var bp: Vector2 = m.bench
		var col = Color(1, 0.8, 0.3) if state == "intermission" else Color(0.6, 0.6, 0.6)
		g.draw_string(font, bp + Vector2(-60, -30), "WEAPON BENCH", HORIZONTAL_ALIGNMENT_CENTER, 120, 12, col)
		if state == "intermission" and near_bench():
			g.draw_string(font, bp + Vector2(-80, 42), "[E] / tap BENCH to shop", HORIZONTAL_ALIGNMENT_CENTER, 160, 12, Color(1, 1, 1))
	if mouse_aim and alive and not demo:
		var c = get_global_mouse_position()
		g.draw_arc(c, 9, 0, TAU, 16, Color(1, 1, 1, 0.85), 2)
		g.draw_line(c - Vector2(14, 0), c - Vector2(5, 0), Color(1, 1, 1, 0.85), 2)
		g.draw_line(c + Vector2(5, 0), c + Vector2(14, 0), Color(1, 1, 1, 0.85), 2)
		if reload_t > 0.0:
			g.draw_arc(c, 13, -PI / 2, -PI / 2 + TAU * (1.0 - reload_t / reload_max), 20, Color(1, 0.85, 0.3), 3)
