extends Node2D
## Everything on the field that moves, drawn every frame from the battle's
## state and the screen's selection. Owns only short-lived effects.

const K := UnitTypes.Kind
const S := Regiment.State

## Banner radius in screen pixels.
const BANNER_PX := 10.0
## An enemy closing on one of yours is shown once it is this near.
const THREAT_RANGE := 320.0
const MORALE_GOOD := Color("7bd88f")
const MORALE_SHAKEN := Color("f2c94c")
const MORALE_BAD := Color("ff6b5b")

## The battle screen; untyped to keep the scripts free of a load cycle.
var screen
var _fx: Array[Dictionary] = []
var _font: Font


func _ready() -> void:
	_font = ThemeDB.fallback_font


func add_fx(kind: String, pos: Vector2, life: float, extra := {}) -> void:
	var e := {"kind": kind, "pos": pos, "age": 0.0, "life": life}
	e.merge(extra)
	_fx.append(e)


func _process(delta: float) -> void:
	var live: Array[Dictionary] = []
	for e in _fx:
		e.age += delta
		if e.age < e.life:
			live.append(e)
	_fx = live
	queue_redraw()


## World units per screen pixel.
func px() -> float:
	return 1.0 / maxf(screen.world.scale.x, 0.001)


## The angle that undoes the world's rotation, so marks stand upright.
func upright() -> float:
	return -screen.world.rotation


func screen_up() -> Vector2:
	return Vector2(0, -1).rotated(upright())


func banner_pos(r: Regiment) -> Vector2:
	return r.pos + screen_up() * (BANNER_PX * px() + 4.0)


func _draw() -> void:
	var b: Battle = screen.battle
	if b == null:
		return
	var p := px()
	if b.phase == "deploy":
		_deploy_zones(b.terrain.deploy_depth)
	for f in b.flags:
		_flag_zone(f, p)
	_gate_damage(b, p)
	for id in screen.selected:
		var r := b.get_regiment(id)
		if r != null and r.alive():
			_footprint(r)
	for r in b.regiments:
		if r.alive():
			_soldiers(r)
	_projectiles(b)
	_effects(p)
	var threats := {} if screen.demo else _intents(b, p)
	for i in b.flags.size():
		_flag(b.flags[i], p)
		if i < b.terrain.flag_names.size():
			_flag_name(b.flags[i].pos, b.terrain.flag_names[i], p)
	for r in b.regiments:
		if r.alive():
			_banner(r, p, threats.has(r.id))
	if not screen.demo:
		_orders(b, p)
		_preview(p)


## A grand battle's place names, under each flag, at a fixed size on screen.
func _flag_name(at: Vector2, name: String, p: float) -> void:
	var size := int(13.0 * p)
	var spot := at + Vector2(-90.0 * p, 24.0 * p)
	draw_string_outline(_font, spot, name, HORIZONTAL_ALIGNMENT_CENTER, 180.0 * p, size, int(4.0 * p), Color(0, 0, 0, 0.6))
	draw_string(_font, spot, name, HORIZONTAL_ALIGNMENT_CENTER, 180.0 * p, size, Palette.INK)


## Cracks across a battered gate and a bar of what is left of it.
func _gate_damage(b: Battle, p: float) -> void:
	for i in b.gate_hp.size():
		var g: Dictionary = b.terrain.gates[i]
		var left: float = b.gate_hp[i] / g.hp
		if b.terrain.gate_broken[i] or left >= 1.0:
			continue
		var c: Vector2 = g.c
		var along: Vector2 = g.along
		var out: Vector2 = g.out
		var cracks := int((1.0 - left) * 8.0)
		for k in cracks:
			var x := (float(k * 37 % 11) / 10.0 - 0.5) * Terrain.GATE_HALF * 1.6
			var a := c + along * x - out * 4.0
			draw_line(a, a + out * 8.0 + along * (3.0 if k % 2 == 0 else -3.0), Color(0.1, 0.07, 0.04), 1.6)
		var bar := c + out * 22.0 * p - along * 30.0 * p
		var w := 60.0 * p
		draw_rect(Rect2(bar - Vector2(0, 3.0 * p), Vector2(w, 6.0 * p)), Color(0, 0, 0, 0.55))
		draw_rect(Rect2(bar - Vector2(0, 3.0 * p), Vector2(w * left, 6.0 * p)), Palette.TEAM_LIGHT[b.terrain.holder])


func _deploy_zones(depth: Array) -> void:
	var size: Vector2 = screen.battle.terrain.size
	var e := Terrain.EDGE
	var mine := Rect2(e, size.y - depth[0], size.x - e * 2.0, depth[0] - e * 0.6)
	var theirs := Rect2(e, e * 0.6, size.x - e * 2.0, depth[1] - e * 0.6)
	draw_rect(mine, Color(Palette.TEAM[0], 0.10))
	draw_rect(mine, Color(Palette.TEAM_LIGHT[0], 0.7), false, 2.0)
	draw_rect(theirs, Color(Palette.TEAM[1], 0.07))


func _flag_zone(f: Dictionary, p: float) -> void:
	var c: Vector2 = f.pos
	draw_circle(c, Battle.FLAG_RADIUS, Color(1, 1, 1, 0.06))
	draw_arc(c, Battle.FLAG_RADIUS, 0, TAU, 48, Color(1, 1, 1, 0.35), 1.5 * p)
	var prog: float = f.progress
	if absf(prog) > 0.01:
		var color: Color = Palette.TEAM_LIGHT[0] if prog > 0.0 else Palette.TEAM_LIGHT[1]
		draw_arc(c, Battle.FLAG_RADIUS, -PI * 0.5, -PI * 0.5 + TAU * absf(prog), 48, color, 3.0 * p)


func _flag(f: Dictionary, p: float) -> void:
	var owner: int = f.owner
	var color: Color = Palette.NEUTRAL if owner < 0 else Palette.TEAM[owner]
	draw_set_transform(f.pos, upright())
	var h := 26.0 * p
	draw_line(Vector2(0, 0), Vector2(0, -h), Color(0.2, 0.15, 0.1), 2.0 * p)
	var wave := sin(Time.get_ticks_msec() / 260.0) * 2.0 * p
	draw_colored_polygon(PackedVector2Array([
		Vector2(0, -h), Vector2(16.0 * p, -h + 5.0 * p + wave), Vector2(0, -h + 10.0 * p),
	]), color)
	draw_polyline(PackedVector2Array([
		Vector2(0, -h), Vector2(16.0 * p, -h + 5.0 * p + wave), Vector2(0, -h + 10.0 * p),
	]), Color(0, 0, 0, 0.5), 1.0 * p)
	draw_circle(Vector2.ZERO, 2.5 * p, Color(0.2, 0.15, 0.1))
	draw_set_transform(Vector2.ZERO)


func _footprint(r: Regiment) -> void:
	draw_set_transform(r.pos, r.facing)
	var d := r.depth() + 10.0
	var w := r.width() + 10.0
	draw_rect(Rect2(-d * 0.5, -w * 0.5, d, w), Color(Palette.GOLD, 0.18))
	draw_rect(Rect2(-d * 0.5, -w * 0.5, d, w), Color(Palette.GOLD, 0.8), false, 1.5)
	draw_set_transform(Vector2.ZERO)


func _soldiers(r: Regiment) -> void:
	var team := r.team
	var body: Color = Palette.TEAM[team]
	var dark: Color = Palette.TEAM_DARK[team]
	if r.kind == K.ARCHERS:
		body = body.lerp(Palette.TEAM_LIGHT[team], 0.35)
	if r.state == S.ROUTING:
		body = body.lerp(Color(0.8, 0.8, 0.8), 0.35)
	var fwd := r.forward()
	match r.kind:
		K.CAVALRY, K.GENERAL:
			for s in r.soldiers:
				draw_line(s - fwd * 4.4, s + fwd * 4.4, Palette.HORSE, 4.4)
				draw_rect(Rect2(s - Vector2(2.1, 2.1), Vector2(4.2, 4.2)), body if r.kind == K.CAVALRY else Palette.GOLD)
		K.CANNONS:
			var right := fwd.orthogonal()
			for g in (2 if r.men() >= 5 else 1):
				var base := r.pos + right * (g - 0.5) * 18.0 + fwd * 4.0
				draw_circle(base, 3.4, Palette.HORSE)
				draw_line(base - fwd * 2.0, base + fwd * 9.0, Palette.GUN, 3.4)
			for s in r.soldiers:
				draw_rect(Rect2(s - Vector2(2.2, 2.2), Vector2(4.4, 4.4)), dark)
				draw_rect(Rect2(s - Vector2(1.5, 1.5), Vector2(3.0, 3.0)), body)
		_:
			var pikes := r.kind == K.PIKES and r.state != S.ROUTING
			var muskets := UnitTypes.is_shot(r.kind) and r.state != S.ROUTING
			if r.fighting():
				_front_edge(r, dark)
			var rank := r.formation_cols(r.men())
			for i in r.men():
				var s := r.soldiers[i]
				if pikes and i < rank * 2:
					draw_line(s, s + fwd * 9.0, Color(0.25, 0.2, 0.15, 0.8), 1.2)
				elif muskets and i < rank:
					draw_line(s, s + fwd * 5.5, Palette.GUN, 1.4)
				draw_rect(Rect2(s - Vector2(2.4, 2.4), Vector2(4.8, 4.8)), dark)
				draw_rect(Rect2(s - Vector2(1.6, 1.6), Vector2(3.2, 3.2)), body)


## A line along the front rank, so which way a block faces (and where its
## flanks are) reads at a glance.
func _front_edge(r: Regiment, color: Color) -> void:
	var rank := mini(r.formation_cols(r.men()), r.men())
	if rank < 2:
		return
	var ahead := r.forward() * 3.5
	draw_line(r.soldiers[0] + ahead, r.soldiers[rank - 1] + ahead, Color(color, 0.85), 1.6)


func _banner(r: Regiment, p: float, threatened: bool) -> void:
	var c := banner_pos(r)
	var selected: bool = r.id in screen.selected
	var wavering := r.fighting() and r.morale < r.morale_max * 0.3
	draw_set_transform(c, upright())
	if threatened:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 110.0)
		draw_arc(Vector2.ZERO, (BANNER_PX + 8.0 + 2.0 * pulse) * p, 0, TAU, 24, Color(MORALE_BAD, 0.5 + 0.5 * pulse), 2.5 * p)
	Glyphs.banner(self, r.kind, r.team, Vector2.ZERO, BANNER_PX * p, r.strength(), wavering, r.state == S.ROUTING, selected)
	if r.fighting():
		_morale_bar(r, p)
	for i in r.stars:
		draw_circle(Vector2((i - (r.stars - 1) * 0.5) * 5.0 * p, (BANNER_PX + 12.0) * p), 1.8 * p, Palette.GOLD)
	if r.id in screen.delegated:
		# Under its own command: a gold diamond over the banner.
		var top := -(BANNER_PX + 9.0) * p
		draw_colored_polygon(PackedVector2Array([
			Vector2(0, top - 4.0 * p), Vector2(4.0 * p, top), Vector2(0, top + 4.0 * p), Vector2(-4.0 * p, top),
		]), Palette.GOLD)
	draw_set_transform(Vector2.ZERO)


## Two bars under the banner: nerve (coloured) and, once the regiment has
## started to tire, its stamina (pale) beneath.
func _morale_bar(r: Regiment, p: float) -> void:
	var m := clampf(r.morale / r.morale_max, 0.0, 1.0)
	var color := MORALE_GOOD if m > 0.66 else (MORALE_SHAKEN if m > 0.33 else MORALE_BAD)
	var w := 22.0 * p
	var top := (BANNER_PX + 6.0) * p
	var tired := r.stamina < 0.95
	draw_rect(Rect2(-w * 0.5 - p, top - p, w + 2.0 * p, (8.0 if tired else 5.0) * p), Color(0, 0, 0, 0.55))
	draw_rect(Rect2(-w * 0.5, top, w * m, 3.0 * p), color)
	if tired:
		draw_rect(Rect2(-w * 0.5, top + 4.0 * p, w * r.stamina, 2.0 * p), Color(Palette.NEUTRAL, 0.9))


## Where the enemy is going: a red arrow from each enemy regiment closing
## on one of yours, and from enemy horse on the move. Returns the ids of
## your regiments under threat.
func _intents(b: Battle, p: float) -> Dictionary:
	var threats := {}
	for e in b.regiments:
		if e.team != 1 or not e.fighting() or UnitTypes.is_ranged(e.kind) or not e.contacts.is_empty():
			continue
		var t := Telemetry.closing_on(b, e)
		if t != null:
			var d := e.pos.distance_to(t.pos)
			if d > THREAT_RANGE:
				continue
			threats[t.id] = true
			var via: Vector2 = e.via if not is_nan(e.via.x) else t.pos
			_arrow(e.pos, via, Color(MORALE_BAD, 0.75), p)
			if via != t.pos:
				_arrow(via, t.pos, Color(MORALE_BAD, 0.75), p)
		elif UnitTypes.is_mounted(e.kind) and not e.waypoints.is_empty():
			_arrow(e.pos, e.waypoints[e.waypoints.size() - 1], Color(MORALE_BAD, 0.35), p)
	return threats


func _arrow(a: Vector2, b: Vector2, color: Color, p: float) -> void:
	var dir := (b - a).normalized()
	var tip := b - dir * 10.0 * p
	draw_dashed_line(a, tip, color, 2.0 * p, 7.0 * p)
	var side := dir.orthogonal() * 5.0 * p
	draw_colored_polygon(PackedVector2Array([tip + dir * 8.0 * p, tip + side, tip - side]), color)


func _projectiles(b: Battle) -> void:
	var up := screen_up()
	for pr in b.projectiles:
		var from: Vector2 = pr.from
		var to: Vector2 = pr.to
		var t: float = pr.t
		var dist := from.distance_to(to)
		var dir := (to - from) / maxf(dist, 0.001)
		if pr.kind == "shot":
			var rng := RandomNumberGenerator.new()
			rng.seed = pr.seed
			for i in pr.count:
				var spread := Vector2(rng.randf_range(-16, 16), rng.randf_range(-16, 16))
				var at := from.lerp(to + spread, t)
				draw_line(at - dir * 5.0, at, Color(1.0, 0.9, 0.6, 0.7), 1.0)
		elif pr.kind == "arrows":
			var rng := RandomNumberGenerator.new()
			rng.seed = pr.seed
			var lift := up * sin(PI * t) * dist * 0.14
			var slope := dir + up * cos(PI * t) * 0.6
			for i in pr.count:
				var spread := Vector2(rng.randf_range(-14, 14), rng.randf_range(-14, 14))
				var at := from.lerp(to, clampf(t + rng.randf_range(-0.05, 0.05), 0.0, 1.0)) + spread * t + lift
				draw_line(at - slope.normalized() * 3.0, at + slope.normalized() * 3.0, Color(0.12, 0.1, 0.08, 0.85), 1.0)
		else:
			var at := from.lerp(to, t)
			draw_circle(at, 1.8, Color(0, 0, 0, 0.25))
			draw_circle(at + up * sin(PI * t) * dist * 0.08, 2.3, Palette.GUN)
	for s in b.shells:
		var r: float = 6.0 + s.t * 18.0
		draw_arc(s.pos, r, 0, TAU, 20, Color(1, 0.3, 0.2, 0.7), 1.5)


func _effects(p: float) -> void:
	for e in _fx:
		var k: float = e.age / e.life
		var pos: Vector2 = e.pos
		match e.kind:
			"smoke":
				var drift := screen_up() * k * 10.0 + Vector2(e.get("dx", 0.0), 0) * k
				draw_circle(pos + drift, lerpf(4.0, e.get("size", 18.0), sqrt(k)), Color(Palette.SMOKE, 0.65 * (1.0 - k)))
			"dust":
				draw_circle(pos, lerpf(3.0, e.get("size", 12.0), sqrt(k)), Color(Palette.DUST, 0.55 * (1.0 - k)))
			"flash":
				draw_circle(pos, lerpf(e.get("size", 6.0), 1.0, k), Color(1.0, 0.85, 0.45, 1.0 - k))
			"ring":
				draw_arc(pos, lerpf(12.0, e.get("size", 200.0), k), 0, TAU, 48, Color(Palette.GOLD, 1.0 - k), 3.0 * p)
			"mark":
				draw_arc(pos, lerpf(26.0, 12.0, k), 0, TAU, 24, Color(1, 0.35, 0.25, 1.0 - k), 2.5 * p)
			"text":
				draw_set_transform(pos, upright())
				var color: Color = e.get("color", Color.WHITE)
				color.a = 1.0 - k * k
				var size := int(13.0 * p)
				var lift := -k * 18.0 * p - 22.0 * p
				draw_string_outline(_font, Vector2(-60.0 * p, lift), e.text, HORIZONTAL_ALIGNMENT_CENTER, 120.0 * p, size, int(4.0 * p), Color(0, 0, 0, color.a * 0.7))
				draw_string(_font, Vector2(-60.0 * p, lift), e.text, HORIZONTAL_ALIGNMENT_CENTER, 120.0 * p, size, color)
				draw_set_transform(Vector2.ZERO)


func _orders(b: Battle, p: float) -> void:
	for id in screen.selected:
		var r := b.get_regiment(id)
		if r == null or not r.fighting():
			continue
		if r.target_id >= 0:
			var t := b.get_regiment(r.target_id)
			if t != null and t.alive():
				_dashed(r.pos, t.pos, Color(1, 0.4, 0.3, 0.85), p)
				draw_arc(t.pos, 14.0 * p, 0, TAU, 20, Color(1, 0.4, 0.3, 0.85), 2.0 * p)
		elif not r.waypoints.is_empty():
			var last := r.pos
			for i in r.waypoints.size():
				var w := r.waypoints[i]
				_dashed(last, w, Color(Palette.GOLD, 0.85), p)
				if i < r.waypoints.size() - 1:
					draw_circle(w, 2.5 * p, Color(Palette.GOLD, 0.85))
				last = w
			if not is_nan(r.final_facing):
				var f := Vector2.from_angle(r.final_facing)
				draw_line(last, last + f * 16.0 * p, Palette.GOLD, 2.0 * p)
			_route_end(last, p)


## The end of a selected route, big enough to tap. Tapped, it is pinned:
## a ring with a plus, waiting for the next leg.
func _route_end(at: Vector2, p: float) -> void:
	draw_circle(at, 6.0 * p, Color(0, 0, 0, 0.45))
	if screen.pinned:
		var pulse := 0.5 + 0.5 * sin(Time.get_ticks_msec() / 140.0)
		draw_arc(at, (9.0 + 2.0 * pulse) * p, 0, TAU, 24, Palette.GOLD, 2.0 * p)
		draw_circle(at, 5.0 * p, Palette.GOLD)
		draw_line(at - Vector2(3.0, 0) * p, at + Vector2(3.0, 0) * p, Palette.DESK, 1.6 * p)
		draw_line(at - Vector2(0, 3.0) * p, at + Vector2(0, 3.0) * p, Palette.DESK, 1.6 * p)
	else:
		draw_circle(at, 5.0 * p, Palette.GOLD)


func _dashed(a: Vector2, b: Vector2, color: Color, p: float) -> void:
	draw_dashed_line(a, b, color, 1.6 * p, 6.0 * p)


## The arrow the player is dragging, and the ghost positions it gives.
func _preview(p: float) -> void:
	var slots: Array = screen.preview_slots()
	if slots.is_empty():
		return
	var arrow: PackedVector2Array = screen.preview_arrow()
	var tip := arrow[1]
	var back := (arrow[0] - tip).normalized() * 12.0 * p
	draw_line(arrow[0], tip, Color(Palette.GOLD, 0.8), 2.5 * p)
	draw_colored_polygon(PackedVector2Array([tip, tip + back.rotated(0.45), tip + back.rotated(-0.45)]), Palette.GOLD)
	var b: Battle = screen.battle
	for s in slots:
		var r := b.get_regiment(s[0])
		draw_set_transform(s[1], s[2])
		var d := r.depth() + 4.0
		var w := r.width() + 4.0
		draw_rect(Rect2(-d * 0.5, -w * 0.5, d, w), Color(Palette.GOLD, 0.25))
		draw_rect(Rect2(-d * 0.5, -w * 0.5, d, w), Palette.GOLD, false, 1.5 * p)
		draw_line(Vector2.ZERO, Vector2(d * 0.5 + 8.0 * p, 0), Palette.GOLD, 2.0 * p)
		draw_set_transform(Vector2.ZERO)
