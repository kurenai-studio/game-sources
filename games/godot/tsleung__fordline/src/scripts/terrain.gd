class_name Terrain
extends RefCounted
## A seeded battlefield and the questions the simulation asks of it.
## The player deploys along the bottom edge, the enemy along the top.

const SIZE := Vector2(1300.0, 820.0)
const DEPLOY_DEPTH := 190.0
const EDGE := 36.0
const RIVER_HALF := 13.0
const BANK_CLEARANCE := 24.0
const ROAD_HALF := 9.0
## Fortress walls: half their thickness; how far pathfinding keeps a
## regiment's centre from them; the wall-walk's depth inside them.
const WALL_HALF := 8.0
const NAV_CLEAR := 12.0
const RAMPART := 40.0
## Share of arrows and shot that get through to a regiment on the wall-walk.
const BATTLEMENTS := 0.3
const NAV_CELL := 16.0
## A creek's half-width: wading it slows a regiment, but anyone may.
const STREAM_HALF := 12.0
## Houses and walls are worth about a hill's crest to the men behind them.
const TOWN_DEFENCE := 0.1
## A gate's half-width along its wall.
const GATE_HALF := 34.0
## The moat's inner and outer distance from the curtain wall.
const MOAT := Vector2(22.0, 50.0)

var kind := ""
## The field's extent. Quick battles and the campaign use SIZE; a grand
## battle's plan sets its own.
var size := SIZE
var has_river := false
## River centre line, sampled left to right.
var river := PackedVector2Array()
## Each crossing: {"x": float, "half": float, "bridge": bool}.
var crossings: Array[Dictionary] = []
## Each forest and hill: {"c": Vector2, "r": float}.
var forests: Array[Dictionary] = []
var hills: Array[Dictionary] = []
## Grand battles: long ridges, each {"line": its crest, "r": how far its
## slopes reach}. Height falls away from the crest as from a hill's top.
var ridges: Array[Dictionary] = []
var roads: Array[PackedVector2Array] = []
var flags := PackedVector2Array()
## How far each side's deployment zone reaches in from its edge. The map is
## generated around DEPLOY_DEPTH; a scenario may push a side forward.
var deploy_depth := [DEPLOY_DEPTH, DEPLOY_DEPTH]

## Fortress maps only. holder: the team whose castle it is (-1: none).
## walls: [a, b] segments; towers: {"c", "r"}; blocks: solid Rect2s;
## gates: {"c", "along", "out", "keep", "hp"}, out pointing away from the
## ward it shuts, hp its strength; gate_broken: written only by Battle. curtain and keep: each
## enclosure's corners as a polyline, for drawing and for inside tests.
## posts: wall-walk stations for the garrison's shooters, best first.
var holder := -1
var walls: Array[PackedVector2Array] = []
var towers: Array[Dictionary] = []
var blocks: Array[Rect2] = []
var gates: Array[Dictionary] = []
var gate_broken: Array[bool] = []
var curtain := PackedVector2Array()
var keep := PackedVector2Array()
var posts := PackedVector2Array()
## The moat's centre line, for drawing.
var moat := PackedVector2Array()
var _nav: AStarGrid2D

## Grand battles only. towns: built-up ground, each a polygon; streams:
## fordable creeks, each a centre line; flag_names: what each flag stands
## for ("Cemetery Hill"), or empty on the arcade maps.
var towns: Array[PackedVector2Array] = []
var streams: Array[PackedVector2Array] = []
var flag_names := PackedStringArray()


static func generate(map_kind: String, seed_value: int) -> Terrain:
	var t := Terrain.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	t.kind = map_kind
	t.has_river = map_kind in ["fords", "bridges", "roads"]
	if map_kind in ["fortress", "fortress_held"]:
		t._make_fortress(rng, 1 if map_kind == "fortress" else 0)
		return t
	if t.has_river:
		t._make_river(rng)
		t._make_crossings(rng)
		for c in t.crossings:
			t.flags.append(Vector2(c.x, t.river_y(c.x)))
	else:
		t._make_open_flags(rng)
	t._make_hills(rng)
	t._make_forests(rng)
	t._make_roads(rng)
	return t


## A field drawn by hand from a plan rather than seeded: a grand battle's
## historical ground. Plan keys: id, size, ridges (each {"line", "r"}: a
## crest line and how far its slopes reach), hills and forests (each {"c",
## "r"}), towns (polygons), streams and roads (lines), and flags (each
## {"name", "at"}).
static func from_plan(plan: Dictionary) -> Terrain:
	var t := Terrain.new()
	t.kind = plan.id
	t.size = plan.size
	for ridge in plan.get("ridges", []):
		t.ridges.append({"line": PackedVector2Array(ridge.line), "r": ridge.r})
	for hill in plan.get("hills", []):
		t.hills.append({"c": hill.c, "r": hill.r})
	for forest in plan.get("forests", []):
		t.forests.append({"c": forest.c, "r": forest.r})
	t.towns.assign(plan.get("towns", []))
	t.streams.assign(plan.get("streams", []))
	t.roads.assign(plan.get("roads", []))
	for f in plan.flags:
		t.flags.append(f.at)
		t.flag_names.append(f.name)
	return t


# --- queries ---------------------------------------------------------------

func river_y(x: float) -> float:
	if river.is_empty():
		return size.y * 0.5
	var step := river[1].x - river[0].x
	var i := clampi(int((x - river[0].x) / step), 0, river.size() - 2)
	var a := river[i]
	var b := river[i + 1]
	return lerpf(a.y, b.y, clampf((x - a.x) / (b.x - a.x), 0.0, 1.0))


## 0 for the player's (south) bank, 1 for the enemy's (north) bank.
func side(p: Vector2) -> int:
	return 1 if p.y < river_y(p.x) else 0


func crossing_at(x: float) -> Dictionary:
	for c in crossings:
		if absf(x - c.x) <= c.half:
			return c
	return {}


func in_river_band(p: Vector2) -> bool:
	return has_river and absf(p.y - river_y(p.x)) < RIVER_HALF


func is_water(p: Vector2) -> bool:
	if holder >= 0:
		return in_moat(p)
	return in_river_band(p) and crossing_at(p.x).is_empty()


func is_blocked(p: Vector2) -> bool:
	return is_water(p) or not in_bounds(p)


func has_walls() -> bool:
	return holder >= 0


## Whether stone stands at `p` for a regiment of `team`: a wall, a tower,
## the great tower, or a gate still shut against that team (a castle's own
## side opens its gates as it pleases).
func walled(p: Vector2, team: int) -> bool:
	if holder < 0:
		return false
	return _stone(p, WALL_HALF + 3.0, 2.0) or (team != holder and _shut_gate(p, WALL_HALF + 3.0))


## Whether a wall or a shut gate stands between `a` and `b`, so they can't
## cross blades. Shot and arrows fly over.
func wall_between(a: Vector2, b: Vector2) -> bool:
	if holder < 0:
		return false
	for w in walls:
		if Geometry2D.segment_intersects_segment(a, b, w[0], w[1]) != null:
			return true
	for i in gates.size():
		if not gate_broken[i]:
			var g: Dictionary = gates[i]
			if Geometry2D.segment_intersects_segment(a, b, g.c - g.along * GATE_HALF, g.c + g.along * GATE_HALF) != null:
				return true
	return false


## Inside the curtain wall: the castle's ground.
func inside(p: Vector2) -> bool:
	return holder >= 0 and Geometry2D.is_point_in_polygon(p, curtain)


func in_keep(p: Vector2) -> bool:
	return holder >= 0 and Geometry2D.is_point_in_polygon(p, keep)


## On the wall-walk: just inside the curtain or the keep's wall.
func on_rampart(p: Vector2) -> bool:
	if not inside(p) or _stone(p, WALL_HALF, 0.0):
		return false
	return _near_line(p, curtain, RAMPART) or (in_keep(p) and _near_line(p, keep, RAMPART))


func in_moat(p: Vector2) -> bool:
	if holder < 0 or inside(p):
		return false
	var d := _dist_to_line(p, curtain)
	if d < MOAT.x or d > MOAT.y:
		return false
	for g in gates:
		if not g.keep and absf((p - g.c).dot(g.along)) < GATE_HALF - 2.0:
			return false
	return true


## Just inside the main gate: where a garrison's foot stand to hold it.
func gate_mouth() -> Vector2:
	return gates[0].c - gates[0].out * 70.0


## The gate within `reach` of `p`, or -1.
func gate_near(p: Vector2, reach: float) -> int:
	for i in gates.size():
		if p.distance_to(gates[i].c) < reach:
			return i
	return -1


func in_bounds(p: Vector2) -> bool:
	return p.x >= 4.0 and p.y >= 4.0 and p.x <= size.x - 4.0 and p.y <= size.y - 4.0


func in_forest(p: Vector2) -> bool:
	for f in forests:
		if p.distance_squared_to(f.c) < f.r * f.r:
			return true
	return false


## 0 off any hill, rising to 1 at a hill's crest; 1 on a wall-walk.
func height(p: Vector2) -> float:
	if holder >= 0 and on_rampart(p):
		return 1.0
	var h := 0.0
	for hill in hills:
		var d: float = p.distance_to(hill.c) / hill.r
		if d < 1.0:
			h = maxf(h, 1.0 - d * d)
	for ridge in ridges:
		var d: float = _dist_to_line(p, ridge.line) / ridge.r
		if d < 1.0:
			h = maxf(h, 1.0 - d * d)
	return h


func on_road(p: Vector2) -> bool:
	for road in roads:
		for i in road.size() - 1:
			var q := Geometry2D.get_closest_point_to_segment(p, road[i], road[i + 1])
			if p.distance_squared_to(q) < ROAD_HALF * ROAD_HALF:
				return true
	return false


func in_town(p: Vector2) -> bool:
	for town in towns:
		if Geometry2D.is_point_in_polygon(p, town):
			return true
	return false


func near_stream(p: Vector2) -> bool:
	return not streams.is_empty() and streams.any(func(line): return _near_line(p, line, STREAM_HALF))


func speed_mult(p: Vector2) -> float:
	if in_river_band(p):
		var c := crossing_at(p.x)
		if not c.is_empty():
			return 0.95 if c.bridge else 0.5
	if in_forest(p):
		return 0.6
	if on_road(p):
		return 1.2
	if near_stream(p):
		return 0.55
	if in_town(p):
		return 0.75
	return 1.0 - 0.15 * height(p)


## Share of arrow and shot damage that gets through at `p`: trees and
## houses stop half, battlements most of it.
func cover(p: Vector2) -> float:
	if in_forest(p) or in_town(p):
		return 0.5
	return BATTLEMENTS if holder >= 0 and on_rampart(p) else 1.0


func range_mult(p: Vector2) -> float:
	return 1.0 + 0.25 * height(p)


func defence_bonus(p: Vector2) -> float:
	return 0.12 * height(p) + (TOWN_DEFENCE if in_town(p) else 0.0)


func in_deploy(team: int, p: Vector2) -> bool:
	if p.x < EDGE or p.x > size.x - EDGE:
		return false
	if team == 0:
		return p.y > size.y - deploy_depth[0] and p.y < size.y - EDGE * 0.6
	return p.y < deploy_depth[1] and p.y > EDGE * 0.6


func clamp_deploy(team: int, p: Vector2) -> Vector2:
	var x := clampf(p.x, EDGE, size.x - EDGE)
	if team == 0:
		return Vector2(x, clampf(p.y, size.y - deploy_depth[0] + 10.0, size.y - EDGE))
	return Vector2(x, clampf(p.y, EDGE, deploy_depth[1] - 10.0))


func clamp_to_field(p: Vector2) -> Vector2:
	return Vector2(clampf(p.x, 8.0, size.x - 8.0), clampf(p.y, 8.0, size.y - 8.0))


## Waypoints from `from` to `to`, through a crossing when the river is
## in between. The last waypoint is always the destination (moved off the
## water if it was on it).
func path(from: Vector2, to: Vector2) -> PackedVector2Array:
	if holder >= 0:
		return _nav_path(from, clamp_to_field(to))
	var dest := _off_water(clamp_to_field(to), side(from))
	if not has_river:
		return PackedVector2Array([dest])
	var bank := side(from)
	if bank == side(dest):
		return _along_bank(from, dest, bank)
	var best: Dictionary = crossings[0]
	var best_cost := INF
	for c in crossings:
		var cost: float = absf(from.x - c.x) + absf(dest.x - c.x)
		if cost < best_cost:
			best_cost = cost
			best = c
	var ry := river_y(best.x)
	var reach := RIVER_HALF + BANK_CLEARANCE
	var near := Vector2(best.x, ry + reach if bank == 0 else ry - reach)
	var far := Vector2(best.x, ry - reach if bank == 0 else ry + reach)
	var way := PackedVector2Array()
	if from.distance_to(near) >= 6.0 and not in_river_band(from):
		way.append_array(_along_bank(from, near, bank))
	way.append(far)
	way.append_array(_along_bank(far, dest, 1 - bank))
	return way


## Waypoints from a to b on one bank: the straight line where it stays
## clear of the water, pushed out to the bank where the river bends into it.
func _along_bank(a: Vector2, b: Vector2, bank: int) -> PackedVector2Array:
	var steps := int(ceil(a.distance_to(b) / 50.0))
	var clear := true
	for i in range(1, steps * 6):
		if is_water(a.lerp(b, float(i) / (steps * 6))):
			clear = false
			break
	if clear:
		return PackedVector2Array([b])
	var reach := RIVER_HALF + BANK_CLEARANCE
	var way := PackedVector2Array()
	for i in range(1, steps):
		var p := a.lerp(b, float(i) / steps)
		var ry := river_y(p.x)
		p.y = maxf(p.y, ry + reach) if bank == 0 else minf(p.y, ry - reach)
		way.append(p)
	way.append(b)
	return way


func _off_water(p: Vector2, prefer_side: int) -> Vector2:
	if not is_water(p):
		return p
	var ry := river_y(p.x)
	var reach := RIVER_HALF + BANK_CLEARANCE * 0.5
	return Vector2(p.x, ry + reach if prefer_side == 0 else ry - reach)


# --- generation ------------------------------------------------------------

func _make_river(rng: RandomNumberGenerator) -> void:
	var a1 := rng.randf_range(35.0, 70.0)
	var a2 := rng.randf_range(10.0, 22.0)
	var p1 := rng.randf_range(0.0, TAU)
	var p2 := rng.randf_range(0.0, TAU)
	var tilt := rng.randf_range(-0.05, 0.05)
	var x := -40.0
	while x <= size.x + 40.0:
		var y := size.y * 0.5 + a1 * sin(x * 0.0042 + p1) + a2 * sin(x * 0.013 + p2)
		y += (x - size.x * 0.5) * tilt
		river.append(Vector2(x, y))
		x += 40.0


func _make_crossings(rng: RandomNumberGenerator) -> void:
	var spots: Array = []
	var bridges: Array = []
	match kind:
		"fords":
			spots = [0.2, 0.5, 0.8]
			bridges = [false, false, false]
		"bridges":
			spots = [0.32, 0.68]
			bridges = [true, true]
		"roads":
			spots = [0.18, 0.5, 0.82]
			bridges = [false, true, false]
	for i in spots.size():
		var x: float = size.x * spots[i] + rng.randf_range(-70.0, 70.0)
		crossings.append({"x": x, "half": 16.0 if bridges[i] else 34.0, "bridge": bridges[i]})
	if kind == "bridges":
		var x := size.x * 0.5 + rng.randf_range(-40.0, 40.0)
		flags.append(Vector2(x, river_y(x) + (60.0 if rng.randf() < 0.5 else -60.0)))


func _make_open_flags(rng: RandomNumberGenerator) -> void:
	var mid := size.y * 0.5
	if kind == "ridge":
		flags.append(Vector2(size.x * 0.5, mid - 20.0))
		flags.append(Vector2(size.x * 0.2 + rng.randf_range(-40, 40), mid + rng.randf_range(-50, 50)))
		flags.append(Vector2(size.x * 0.8 + rng.randf_range(-40, 40), mid + rng.randf_range(-50, 50)))
		return
	for f in [0.22, 0.5, 0.78]:
		flags.append(Vector2(size.x * f + rng.randf_range(-50, 50), mid + rng.randf_range(-70, 70)))


func _make_hills(rng: RandomNumberGenerator) -> void:
	if kind == "ridge":
		hills.append({"c": Vector2(size.x * 0.5, size.y * 0.47), "r": 180.0})
	var count: int = {"fords": 2, "woods": 3, "bridges": 2, "roads": 2, "ridge": 2}.get(kind, 2)
	var tries := 0
	while hills.size() < count + (1 if kind == "ridge" else 0) and tries < 200:
		tries += 1
		var r := rng.randf_range(80.0, 130.0)
		var c := Vector2(rng.randf_range(120, size.x - 120), rng.randf_range(250, size.y - 250))
		if has_river and absf(c.y - river_y(c.x)) < r * 0.9:
			continue
		var clash := false
		for h in hills:
			if c.distance_to(h.c) < r + h.r:
				clash = true
		if not clash:
			hills.append({"c": c, "r": r})


func _make_forests(rng: RandomNumberGenerator) -> void:
	var clusters: int = {"fords": 4, "woods": 9, "bridges": 5, "roads": 3, "ridge": 5}.get(kind, 4)
	var tries := 0
	var made := 0
	while made < clusters and tries < 400:
		tries += 1
		var centre := Vector2(rng.randf_range(60, size.x - 60), rng.randf_range(DEPLOY_DEPTH + 50, size.y - DEPLOY_DEPTH - 50))
		if not _forest_allowed(centre, 70.0):
			continue
		made += 1
		for i in rng.randi_range(4, 9):
			var c := centre + Vector2(rng.randf_range(-55, 55), rng.randf_range(-40, 40))
			if _forest_allowed(c, 30.0):
				forests.append({"c": c, "r": rng.randf_range(18.0, 32.0)})


func _forest_allowed(p: Vector2, clearance: float) -> bool:
	if p.y < DEPLOY_DEPTH + 20.0 or p.y > size.y - DEPLOY_DEPTH - 20.0:
		return false
	for f in flags:
		if p.distance_to(f) < 90.0 + clearance:
			return false
	if has_river:
		if absf(p.y - river_y(p.x)) < RIVER_HALF + clearance:
			return false
		for c in crossings:
			if absf(p.x - c.x) < c.half + 60.0 + clearance:
				return false
	return true


func _make_roads(rng: RandomNumberGenerator) -> void:
	for f in flags:
		var road := PackedVector2Array()
		var bottom_x := clampf(f.x + rng.randf_range(-160, 160), 40, size.x - 40)
		var top_x := clampf(f.x + rng.randf_range(-160, 160), 40, size.x - 40)
		road.append(Vector2(bottom_x, size.y + 10.0))
		road.append(Vector2(lerpf(bottom_x, f.x, 0.6), lerpf(size.y, f.y, 0.55)))
		if has_river:
			var ry := river_y(f.x)
			road.append(Vector2(f.x, ry + 40.0))
			road.append(Vector2(f.x, ry - 40.0))
		else:
			road.append(f)
		road.append(Vector2(lerpf(top_x, f.x, 0.6), lerpf(0.0, f.y, 0.55)))
		road.append(Vector2(top_x, -10.0))
		roads.append(road)


# --- fortress --------------------------------------------------------------
# Laid out for a castle in the north (holder 1) and mirrored top to bottom
# for one in the south. The castle backs onto its own edge of the field:
# its garrison can always flee out of the back, and nobody can walk round.

const CASTLE_FLAGS := [Vector2(360, 330), Vector2(940, 330), Vector2(650, 190)]


func _make_fortress(rng: RandomNumberGenerator, team: int) -> void:
	holder = team
	var m := func(p: Vector2) -> Vector2: return p if team == 1 else Vector2(p.x, size.y - p.y)
	curtain = PackedVector2Array([m.call(Vector2(230, -10)), m.call(Vector2(230, 430)), m.call(Vector2(1070, 430)), m.call(Vector2(1070, -10))])
	keep = PackedVector2Array([m.call(Vector2(520, -10)), m.call(Vector2(520, 260)), m.call(Vector2(780, 260)), m.call(Vector2(780, -10))])
	gates.append({"c": m.call(Vector2(650, 430)), "along": Vector2(1, 0), "out": m.call(Vector2(0, 1)) - m.call(Vector2.ZERO), "keep": false, "hp": 300.0})
	gates.append({"c": m.call(Vector2(520, 150)), "along": Vector2(0, 1), "out": Vector2(-1, 0), "keep": true, "hp": 220.0})
	gate_broken.assign([false, false])
	var mid_moat := (MOAT.x + MOAT.y) * 0.5
	moat = PackedVector2Array([m.call(Vector2(230 - mid_moat, -10)), m.call(Vector2(230 - mid_moat, 430 + mid_moat)),
		m.call(Vector2(1070 + mid_moat, 430 + mid_moat)), m.call(Vector2(1070 + mid_moat, -10))])
	for line in [curtain, keep]:
		for i in line.size() - 1:
			_add_wall(line[i], line[i + 1])
	for t in [[230, 430, 30], [1070, 430, 30], [230, 215, 24], [1070, 215, 24], [440, 430, 22], [860, 430, 22],
			[588, 430, 26], [712, 430, 26], [520, 260, 26], [780, 260, 26], [520, 92, 20], [520, 208, 20]]:
		towers.append({"c": m.call(Vector2(t[0], t[1])), "r": float(t[2])})
	var donjon := Rect2(595, 25, 110, 90)
	if team == 0:
		donjon.position.y = size.y - donjon.end.y
	blocks.append(donjon)
	for f in CASTLE_FLAGS:
		flags.append(m.call(f))
	for p in [[520, 408], [780, 408], [350, 408], [950, 408], [252, 300], [1048, 300], [252, 150], [1048, 150]]:
		posts.append(m.call(Vector2(p[0], p[1])))
	deploy_depth[team] = 415.0
	_make_siege_ground(rng, m)
	_build_nav()


## The outer half: a road up to the gate, a few copses and one low rise
## for the besiegers' guns.
func _make_siege_ground(rng: RandomNumberGenerator, m: Callable) -> void:
	var gate: Vector2 = gates[0].c
	var road := PackedVector2Array([m.call(Vector2(650 + rng.randf_range(-120, 120), size.y + 10.0)), m.call(Vector2(650, 600)), gate])
	roads.append(road)
	var side := 1.0 if rng.randf() < 0.5 else -1.0
	hills.append({"c": m.call(Vector2(650 + side * rng.randf_range(260, 360), rng.randf_range(560, 600))), "r": rng.randf_range(80.0, 105.0)})
	var made := 0
	var tries := 0
	while made < 4 and tries < 200:
		tries += 1
		var c: Vector2 = m.call(Vector2(rng.randf_range(80, size.x - 80), rng.randf_range(510, 620)))
		if absf(c.x - gate.x) < 170.0 or _dist_to_line(c, curtain) < MOAT.y + 60.0:
			continue
		made += 1
		for i in rng.randi_range(3, 7):
			forests.append({"c": c + Vector2(rng.randf_range(-45, 45), rng.randf_range(-30, 30)), "r": rng.randf_range(16.0, 28.0)})


## The wall from a to b, with any gate on it left open as a gap.
func _add_wall(a: Vector2, b: Vector2) -> void:
	var cuts: Array[float] = []
	var length := a.distance_to(b)
	var dir := (b - a) / length
	for g in gates:
		var along: float = (g.c - a).dot(dir)
		if absf((g.c - a).cross(dir)) < 1.0 and along > 0.0 and along < length:
			cuts.append(along)
	cuts.sort()
	var start := 0.0
	for c in cuts:
		walls.append(PackedVector2Array([a + dir * start, a + dir * (c - GATE_HALF)]))
		start = c + GATE_HALF
	walls.append(PackedVector2Array([a + dir * start, b]))


func _stone(p: Vector2, wall_reach: float, tower_reach: float) -> bool:
	for w in walls:
		if p.distance_to(Geometry2D.get_closest_point_to_segment(p, w[0], w[1])) < wall_reach:
			return true
	for t in towers:
		if p.distance_to(t.c) < t.r + tower_reach:
			return true
	for r in blocks:
		if r.grow(tower_reach).has_point(p):
			return true
	return false


func _shut_gate(p: Vector2, reach: float) -> bool:
	for i in gates.size():
		if gate_broken[i]:
			continue
		var g: Dictionary = gates[i]
		var q := Geometry2D.get_closest_point_to_segment(p, g.c - g.along * GATE_HALF, g.c + g.along * GATE_HALF)
		if p.distance_to(q) < reach:
			return true
	return false


func _dist_to_line(p: Vector2, line: PackedVector2Array) -> float:
	var best := INF
	for i in line.size() - 1:
		best = minf(best, p.distance_to(Geometry2D.get_closest_point_to_segment(p, line[i], line[i + 1])))
	return best


func _near_line(p: Vector2, line: PackedVector2Array, within: float) -> bool:
	return _dist_to_line(p, line) < within


## Pathfinding treats gates as open for everyone: a besieger's route runs
## through the gate, and the gate stops it there, which is where it rams.
func _nav_solid(p: Vector2, clear: float) -> bool:
	return not in_bounds(p) or in_moat(p) or _stone(p, WALL_HALF + clear, clear)


func _build_nav() -> void:
	_nav = AStarGrid2D.new()
	_nav.region = Rect2i(0, 0, int(ceil(size.x / NAV_CELL)), int(ceil(size.y / NAV_CELL)))
	_nav.cell_size = Vector2(NAV_CELL, NAV_CELL)
	_nav.offset = Vector2(NAV_CELL, NAV_CELL) * 0.5
	_nav.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_nav.update()
	for x in _nav.region.size.x:
		for y in _nav.region.size.y:
			if _nav_solid(_nav.get_point_position(Vector2i(x, y)), NAV_CLEAR):
				_nav.set_point_solid(Vector2i(x, y))


func _cell(p: Vector2) -> Vector2i:
	var c := Vector2i(int(p.x / NAV_CELL), int(p.y / NAV_CELL))
	return c.clamp(Vector2i.ZERO, _nav.region.size - Vector2i.ONE)


## The open cell nearest `p` that can be walked to in a straight line,
## searching outward ring by ring (never one on the far side of a wall).
func _open_cell(p: Vector2) -> Vector2i:
	var c := _cell(p)
	if not _nav.is_point_solid(c):
		return c
	for ring in range(1, 12):
		var best := Vector2i(-1, -1)
		var best_d := INF
		for dx in range(-ring, ring + 1):
			for dy in range(-ring, ring + 1):
				if maxi(absi(dx), absi(dy)) != ring:
					continue
				var q := c + Vector2i(dx, dy)
				if not _nav.is_in_boundsv(q) or _nav.is_point_solid(q):
					continue
				var at := _nav.get_point_position(q)
				if not _walkable(p, at):
					continue
				var d := p.distance_squared_to(at)
				if d < best_d:
					best_d = d
					best = q
		if best.x >= 0:
			return best
	return c


## Grid route from `from` to `to`, pulled tight: each waypoint is the
## furthest grid point still in plain sight of the last.
func _nav_path(from: Vector2, to: Vector2) -> PackedVector2Array:
	var goal_cell := _open_cell(to)
	var dest := to if not _nav_solid(to, NAV_CLEAR * 0.5) else _nav.get_point_position(goal_cell)
	var grid := _nav.get_point_path(_open_cell(from), goal_cell, true)
	if grid.is_empty():
		return PackedVector2Array([dest])
	grid.append(dest)
	var out := PackedVector2Array()
	var at := from
	var i := 0
	while i < grid.size():
		var j := grid.size() - 1
		while j > i and not _line_clear(at, grid[j]):
			j -= 1
		at = grid[j]
		out.append(at)
		i = j + 1
	return out


## No stone in the way from a to b, at the margin movement itself uses.
func _walkable(a: Vector2, b: Vector2) -> bool:
	var steps := int(ceil(a.distance_to(b) / 6.0))
	for k in range(1, steps + 1):
		if _stone(a.lerp(b, float(k) / steps), WALL_HALF + 3.0, 2.0):
			return false
	return true


func _line_clear(a: Vector2, b: Vector2) -> bool:
	var steps := int(ceil(a.distance_to(b) / 6.0))
	for k in range(1, steps + 1):
		if _nav_solid(a.lerp(b, float(k) / steps), NAV_CLEAR * 0.5):
			return false
	return true
