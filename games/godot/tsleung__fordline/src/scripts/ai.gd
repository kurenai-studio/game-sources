class_name AI
extends RefCounted
## A commander as a pure decision: battle state in, orders out.
## The enemy uses it every think; the headless balance tests use it for
## both sides.

const K := UnitTypes.Kind
const S := Regiment.State

const THINK_EVERY := 0.75

## hold: seconds to hold the near side of the objectives before advancing
## past them.
## flank: whether cavalry looks for rears and soft targets.
## reserve: foot regiments kept behind the line and sent onto the flank of
## whoever a friend is fighting, as soon as that friend is pinned.
## terrain: archers take a hill behind the line when one is in reach.
## garrison: a castle's defenders. Foot fight only what gets inside the
## walls, shooters and guns man the wall-walk; horse may still sally.
const PERSONAS := {
	"garrison": {"hold": INF, "flank": true, "garrison": true},
	"balanced": {"hold": 8.0, "flank": true},
	"aggressive": {"hold": 0.0, "flank": true},
	"dug_in": {"hold": 45.0, "flank": false},
	"flanker": {"hold": 12.0, "flank": true},
	"reserve": {"hold": 8.0, "flank": true, "reserve": 1},
	"hills": {"hold": 8.0, "flank": true, "terrain": true},
}

## A friend in melee below this share of its nerve, or this stamina (about
## five seconds into a fight), calls in the reserve. Waiting until a friend
## is about to break measured worse: the reserve arrives too late.
const RESERVE_CALL_MORALE := 0.75
const RESERVE_CALL_STAMINA := 0.9
const RESERVE_REACH := 450.0
## While holding, foot stand this far short of each flag on their own side
## (inside its capture ring), and guns stand this far back from the flag
## they cover.
const HOLD_SHORT := 50.0
const BATTERY_BACK := 170.0
## Archers step back from foot this close; muskets only from foot about to
## strike, since a musket on the move doesn't fire and its range is short.
const ARCHERS_SHY := 110.0
const MUSKETS_SHY := 60.0
## A division within this of its objective is there, and faces the enemy;
## its blocks stand this far apart, centre to centre.
const DIVISION_THERE := 220.0
const DIVISION_GAP := 120.0
## Horse whose orders start later still rides at an enemy this near.
const HORSE_WAKE := 500.0


## Place orders that set out a team's regiments in its deployment zone:
## foot in front, archers and muskets then cannons behind, horse on the
## wings, the general at the back.
static func deploy_orders(b: Battle, team: int) -> Array:
	var foot: Array[Regiment] = []
	var archers: Array[Regiment] = []
	var guns: Array[Regiment] = []
	var horse: Array[Regiment] = []
	var general: Array[Regiment] = []
	for r in b.team_regiments(team):
		match r.kind:
			K.SWORDS, K.PIKES:
				foot.append(r)
			K.ARCHERS, K.MUSKETS, K.RIFLES, K.LINE:
				archers.append(r)
			K.CANNONS:
				guns.append(r)
			K.CAVALRY:
				horse.append(r)
			K.GENERAL:
				general.append(r)
	foot.sort_custom(func(a, c): return a.kind < c.kind)
	var sign := -1.0 if team == 0 else 1.0
	var depth: float = b.terrain.deploy_depth[team]
	var front_y := b.terrain.size.y - depth + 40.0 if team == 0 else depth - 40.0
	var face := -PI * 0.5 if team == 0 else PI * 0.5
	var cx := b.terrain.size.x * 0.5
	var orders: Array = []
	var rows := [
		[_interleave(foot), 0.0, 112.0],
		[archers, 50.0, 116.0],
		[guns, 88.0, 130.0],
		[general, 118.0, 80.0],
	]
	for row in rows:
		var units: Array = row[0]
		for i in units.size():
			var x: float = cx + (i - (units.size() - 1) * 0.5) * row[2]
			orders.append({"type": "place", "id": units[i].id, "to": Vector2(x, front_y - sign * row[1]), "facing": face})
	var half_front := maxf(foot.size(), 2) * 56.0 + 60.0
	for i in horse.size():
		var wing := -1.0 if i % 2 == 0 else 1.0
		var x := clampf(cx + wing * (half_front + (i / 2) * 95.0), Terrain.EDGE + 40.0, b.terrain.size.x - Terrain.EDGE - 40.0)
		orders.append({"type": "place", "id": horse[i].id, "to": Vector2(x, front_y - sign * 20.0), "facing": face})
	return orders


## Pikes between swords so a cavalry charge always finds a pike nearby.
static func _interleave(foot: Array[Regiment]) -> Array:
	var swords := foot.filter(func(r): return r.kind == K.SWORDS)
	var pikes := foot.filter(func(r): return r.kind == K.PIKES)
	var out: Array = []
	while not swords.is_empty() or not pikes.is_empty():
		if not swords.is_empty():
			out.append(swords.pop_front())
		if not pikes.is_empty():
			out.append(pikes.pop_front())
	return out


## Whichever side holds a castle fights as its garrison, whatever its
## persona otherwise.
static func decide(b: Battle, team: int, persona: Dictionary) -> Array:
	if b.terrain.holder == team:
		persona = persona.merged(PERSONAS.garrison, true)
	var mine := _fighting(b, team)
	var foes := _fighting(b, 1 - team)
	var orders: Array = []
	if mine.is_empty() or foes.is_empty():
		return orders
	var home_y := b.terrain.size.y if team == 0 else 0.0
	## Toward this team's own edge.
	var home := Vector2(0.0, 1.0 if team == 0 else -1.0)
	var advancing: bool = b.time >= persona.hold or _foe_near_line(mine, foes, 260.0)
	var goals := _flags_left_to_right(b)
	var reserve := _reserve(mine, persona.get("reserve", 0))
	var garrison: bool = persona.get("garrison", false)
	# A garrison's line forms across the gateway, not out on the flags.
	if garrison:
		goals = [b.terrain.gate_mouth()] as Array[Vector2]
	# A garrison's foot ignore what is still outside the walls.
	var foot_foes: Array[Regiment] = []
	for f in foes:
		if not garrison or b.terrain.inside(f.pos):
			foot_foes.append(f)
	var shooters := mine.filter(func(r): return UnitTypes.is_ranged(r.kind))
	var line: Array[Regiment] = []
	for r in mine:
		if (r.kind == K.SWORDS or r.kind == K.PIKES or r.kind == K.RIFLES or r.kind == K.LINE) and not r.id in reserve:
			line.append(r)
	line.sort_custom(func(a, c): return a.pos.x < c.pos.x)
	for r in mine:
		var o: Variant = null
		# A block whose orders start later in the day keeps to its ground
		# until then, unless the enemy comes to it; horse held back watches
		# farther, as a reserve of cavalry does.
		var wake := HORSE_WAKE if UnitTypes.is_mounted(r.kind) else maxf(r.fire_range, 150.0) * 1.1
		if b.time < r.holds_until and _nearest(r, foes, wake) == null:
			continue
		match r.kind:
			K.SWORDS, K.PIKES:
				if r.id in reserve:
					o = _reserve_foot(b, r, line, foot_foes, home_y)
				else:
					o = _foot(r, foot_foes, advancing, _spot(b, team, r, line, goals), home)
			K.RIFLES, K.LINE:
				o = _rifle(r, foes, advancing, _spot(b, team, r, line, goals), home)
			K.ARCHERS, K.MUSKETS:
				if garrison:
					o = _man_wall(b, r, foes, shooters.find(r))
				else:
					o = _archer(b, r, mine, foes, home_y, advancing, persona.get("terrain", false))
			K.CANNONS:
				if garrison:
					o = _man_wall(b, r, foes, shooters.find(r))
				else:
					var aims := _flag_goals(b, team)
					var back := home
					if not r.objectives.is_empty():
						# Unlimber short of the objective on the way in.
						aims = [_objective(b, team, r.objectives)] as Array[Vector2]
						back = (r.pos - aims[0]).normalized()
					o = _gun(b, r, foes, aims, back)
			K.CAVALRY:
				o = _horse(b, r, foes, advancing, persona)
			K.GENERAL:
				o = _general(r, mine, foes, home_y)
		if o != null:
			orders.append(o)
	return orders


static func _fighting(b: Battle, team: int) -> Array[Regiment]:
	var out: Array[Regiment] = []
	for r in b.team_regiments(team):
		if r.fighting():
			out.append(r)
	return out


static func _foe_near_line(mine: Array[Regiment], foes: Array[Regiment], radius: float) -> bool:
	for r in mine:
		for f in foes:
			if r.pos.distance_to(f.pos) < radius:
				return true
	return false


## The line's share of the front: left-hand regiments take the left-hand
## goal and so on, side by side within each share.
static func _line_spot(line: Array[Regiment], i: int, goals: Array[Vector2]) -> Vector2:
	var g := mini(i * goals.size() / maxi(line.size(), 1), goals.size() - 1)
	var group: Array[int] = []
	for j in line.size():
		if mini(j * goals.size() / line.size(), goals.size() - 1) == g:
			group.append(j)
	var k := group.find(i)
	return goals[g] + Vector2((k - (group.size() - 1) * 0.5) * 85.0, 0.0)


## Where a line regiment stands: its share of the front. A block with
## objectives of its own (a grand battle's division) has its place in its
## division's line instead.
static func _spot(b: Battle, team: int, r: Regiment, line: Array[Regiment], goals: Array[Vector2]) -> Vector2:
	if r.objectives.is_empty():
		return _line_spot(line, line.find(r), goals)
	var division: Array[Regiment] = []
	for o in line:
		if o.formation == r.formation:
			division.append(o)
	return _division_spot(b, team, r, division, _objective(b, team, r.objectives))


## A division forms side by side across its objective, square to the way
## it is going; once there, square to the nearest enemy. Each block keeps
## its place from left to right, so their routes don't cross.
static func _division_spot(b: Battle, team: int, r: Regiment, division: Array[Regiment], objective: Vector2) -> Vector2:
	var centre := Vector2.ZERO
	for o in division:
		centre += o.pos
	centre /= division.size()
	var ahead := objective - centre
	if ahead.length() < DIVISION_THERE:
		var nearest := INF
		for f in _fighting(b, 1 - team):
			var d := f.pos.distance_to(objective)
			if d < nearest:
				nearest = d
				ahead = f.pos - objective
	var across := ahead.normalized().orthogonal() if ahead.length() > 1.0 else Vector2.RIGHT
	var order := division.duplicate()
	order.sort_custom(func(x, y): return x.pos.dot(across) < y.pos.dot(across))
	var k := order.find(r)
	return objective + across * (k - (order.size() - 1) * 0.5) * DIVISION_GAP


## A division's objectives are flags to take in order: the first it
## doesn't hold. Once it holds them all it stays on the last.
static func _objective(b: Battle, team: int, objectives: PackedVector2Array) -> Vector2:
	for p in objectives:
		for f in b.flags:
			if f.pos.distance_to(p) < Battle.FLAG_RADIUS and f.owner != team:
				return p
	return objectives[objectives.size() - 1]


static func _flags_left_to_right(b: Battle) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for f in b.flags:
		out.append(f.pos)
	out.sort_custom(func(a, c): return a.x < c.x)
	return out


## Flags this team should take, most wanted first: not ours, then nearest
## to our side of the field.
static func _flag_goals(b: Battle, team: int) -> Array[Vector2]:
	var fl := b.flags.duplicate()
	var home_y := b.terrain.size.y if team == 0 else 0.0
	fl.sort_custom(func(a, c):
		var a_ours: bool = a.owner == team
		var c_ours: bool = c.owner == team
		if a_ours != c_ours:
			return c_ours
		return absf(a.pos.y - home_y) < absf(c.pos.y - home_y))
	var out: Array[Vector2] = []
	for f in fl:
		out.append(f.pos)
	return out


## Fight what comes within reach; otherwise take the goal, or while
## holding, stand just short of it on our own side.
static func _foot(r: Regiment, foes: Array[Regiment], advancing: bool, goal: Vector2, home: Vector2) -> Variant:
	var reach := 220.0 if r.kind == K.PIKES else 170.0
	var best: Regiment = null
	var best_score := INF
	for f in foes:
		var d := r.pos.distance_to(f.pos)
		if d > reach:
			continue
		var score := d - 60.0 * (Combat.type_mult(r.kind, f.kind) - 1.0)
		score -= 50.0 if not f.contacts.is_empty() else 0.0
		if r.kind == K.PIKES and UnitTypes.is_mounted(f.kind):
			score -= 120.0
		if score < best_score:
			best_score = score
			best = f
	if best != null:
		return _attack(r, best)
	if not advancing:
		return _move(r, goal + home * HOLD_SHORT)
	return _move(r, goal)


## The foot held back: the last `count` by id, always leaving two in line.
static func _reserve(mine: Array[Regiment], count: int) -> Array[int]:
	var foot: Array[int] = []
	for r in mine:
		if r.kind == K.SWORDS or r.kind == K.PIKES:
			foot.append(r.id)
	foot.sort()
	var keep := mini(count, foot.size() - 2)
	return foot.slice(foot.size() - keep) if keep > 0 else ([] as Array[int])


## A reserve waits behind the middle of the line. When a friend in melee is
## pinned it goes in on the flank of whoever that friend is fighting, and
## when that fight is done it falls back to wait again.
static func _reserve_foot(b: Battle, r: Regiment, line: Array[Regiment], foes: Array[Regiment], home_y: float) -> Variant:
	if not r.contacts.is_empty() or r.target_id >= 0:
		return null
	var best: Regiment = null
	var best_d := RESERVE_REACH
	for f in line:
		if f.contacts.is_empty():
			continue
		if f.morale > f.morale_max * RESERVE_CALL_MORALE and f.stamina > RESERVE_CALL_STAMINA:
			continue
		var enemy := b.get_regiment(f.contacts[0])
		var d := r.pos.distance_to(enemy.pos)
		if enemy.fighting() and d < best_d:
			best_d = d
			best = enemy
	if best != null:
		var side := best.forward().orthogonal()
		if side.dot(r.pos - best.pos) < 0.0:
			side = -side
		var via := b.terrain.clamp_to_field(best.pos + side * 80.0)
		return {"type": "attack", "id": r.id, "target": best.id, "via": via}
	var near := _nearest(r, foes, 120.0)
	if near != null:
		return _attack(r, near)
	if line.is_empty():
		return null
	var centre := Vector2.ZERO
	for f in line:
		centre += f.pos
	centre /= line.size()
	var back := 1.0 if home_y > 0.0 else -1.0
	return _move(r, centre + Vector2(0.0, 110.0 * back))


## Archers and muskets: step back from foot closing on them, else shoot
## at the nearest in reach, else keep behind the line.
static func _archer(b: Battle, r: Regiment, mine: Array[Regiment], foes: Array[Regiment], home_y: float, advancing: bool, use_hills: bool) -> Variant:
	var shy := ARCHERS_SHY if r.kind == K.ARCHERS else MUSKETS_SHY
	for f in foes:
		if UnitTypes.is_ranged(f.kind) or not f.contacts.is_empty():
			continue
		if r.pos.distance_to(f.pos) < shy:
			var away := (r.pos - f.pos).normalized() * 100.0
			away.y += 40.0 if home_y > 0.0 else -40.0
			return _move(r, r.pos + away)
	var reach := r.fire_range * b.terrain.range_mult(r.pos)
	var target := _nearest(r, foes, reach)
	if target != null:
		return _attack(r, target)
	if not advancing:
		return null
	var anchor := _nearest_kind(r, mine, [K.SWORDS, K.PIKES])
	if anchor == null:
		return null
	var back := 1.0 if home_y > 0.0 else -1.0
	var spot := anchor.pos + Vector2(0.0, 75.0 * back)
	if use_hills:
		spot = _hill_near(b.terrain, spot, anchor.pos)
	return _move(r, spot)


## The closest hilltop to `spot` from which archers still reach past
## `front`; `spot` itself when there is none.
static func _hill_near(t: Terrain, spot: Vector2, front: Vector2) -> Vector2:
	var best := spot
	var best_d := 200.0
	for h in t.hills:
		var top: Vector2 = h.c + (front - h.c).limit_length(h.r * 0.4)
		if top.distance_to(front) > 170.0 or t.is_water(top):
			continue
		var d := top.distance_to(spot)
		if d < best_d:
			best_d = d
			best = top
	return best


## A garrison's shooter takes its station on the wall-walk (the best
## stations first, in id order) and from there shoots back at the enemy's
## shooters first, then at the nearest in reach.
static func _man_wall(b: Battle, r: Regiment, foes: Array[Regiment], index: int) -> Variant:
	var posts := b.terrain.posts
	if posts.is_empty():
		return null
	var post := posts[index % posts.size()]
	if r.pos.distance_to(post) > 24.0:
		return _move(r, post)
	var reach := r.fire_range * b.terrain.range_mult(r.pos)
	var shooters: Array[Regiment] = []
	for f in foes:
		if UnitTypes.is_ranged(f.kind):
			shooters.append(f)
	var target := _nearest(r, shooters, reach)
	if target == null:
		target = _nearest(r, foes, reach)
	return _attack(r, target) if target != null else null


## Before a castle, guns batter the nearest gate still shut against them.
## Otherwise they keep firing at whatever is in range, or stand behind the
## most wanted flag, close enough to cover it.
static func _gun(b: Battle, r: Regiment, foes: Array[Regiment], goals: Array[Vector2], home: Vector2) -> Variant:
	if b.terrain.has_walls() and b.terrain.holder != r.team:
		for g in b.terrain.gates.size():
			if not b.terrain.gate_broken[g]:
				if r.target_gate == g:
					return null
				return {"type": "bombard", "id": r.id, "gate": g}
	var reach := r.fire_range * b.terrain.range_mult(r.pos)
	if _nearest(r, foes, reach) != null:
		# A battery on its way to an objective unlimbers where it is.
		if not r.objectives.is_empty() and not r.waypoints.is_empty():
			return {"type": "halt", "id": r.id}
		return null
	return _move(r, b.terrain.clamp_to_field(goals[0] + home * BATTERY_BACK))


static func _horse(b: Battle, r: Regiment, foes: Array[Regiment], advancing: bool, persona: Dictionary) -> Variant:
	if not r.contacts.is_empty():
		for id in r.contacts:
			var e := b.get_regiment(id)
			if e.kind == K.PIKES and Combat.zone(e.pos, e.facing, r.pos) == Combat.Zone.FRONT:
				var back := (r.pos - e.pos).normalized() * 140.0
				return {"type": "move", "id": r.id, "to": r.pos + back}
		return null
	if not advancing:
		var close := _nearest(r, foes, 150.0)
		return _attack(r, close) if close != null else null
	var pikes := foes.filter(func(f): return f.kind == K.PIKES)
	var prey: Regiment = null
	var prey_d := INF
	for f in foes:
		if not (UnitTypes.is_ranged(f.kind) or (persona.flank and not f.contacts.is_empty() and f.kind != K.PIKES)):
			continue
		var guarded := false
		for p in pikes:
			if p.pos.distance_to(f.pos) < 120.0 and p.contacts.is_empty():
				guarded = true
		if guarded:
			continue
		var d := r.pos.distance_to(f.pos)
		if d < prey_d:
			prey_d = d
			prey = f
	if prey != null:
		if not prey.contacts.is_empty() and r.target_id != prey.id:
			var rear := prey.pos - prey.forward() * 90.0
			return {"type": "attack", "id": r.id, "target": prey.id, "via": b.terrain.clamp_to_field(rear)}
		return _attack(r, prey)
	var near := _nearest(r, foes, 130.0)
	if near != null and near.kind != K.PIKES:
		return _attack(r, near)
	return null


static func _general(r: Regiment, mine: Array[Regiment], foes: Array[Regiment], home_y: float) -> Variant:
	var centre := Vector2.ZERO
	var n := 0
	for m in mine:
		if m.kind == K.SWORDS or m.kind == K.PIKES:
			centre += m.pos
			n += 1
	if n == 0:
		return null
	centre /= n
	var back := 1.0 if home_y > 0.0 else -1.0
	var spot := centre + Vector2(0.0, 150.0 * back)
	var threat := _nearest(r, foes, 120.0)
	if threat != null:
		spot = r.pos + (r.pos - threat.pos).normalized() * 120.0
	return _move(r, spot)


static func _nearest(r: Regiment, among: Array[Regiment], radius: float) -> Regiment:
	var best: Regiment = null
	var best_d := radius
	for f in among:
		var d := r.pos.distance_to(f.pos)
		if d < best_d:
			best_d = d
			best = f
	return best


static func _nearest_kind(r: Regiment, among: Array[Regiment], kinds: Array) -> Regiment:
	var best: Regiment = null
	var best_d := INF
	for f in among:
		if f.kind in kinds:
			var d := r.pos.distance_to(f.pos)
			if d < best_d:
				best_d = d
				best = f
	return best


static func _attack(r: Regiment, t: Regiment) -> Variant:
	if r.target_id == t.id:
		return null
	return {"type": "attack", "id": r.id, "target": t.id}


## Rifles are the line: they take their place in it, and anything that
## comes within range they stand and shoot at.
static func _rifle(r: Regiment, foes: Array[Regiment], advancing: bool, goal: Vector2, home: Vector2) -> Variant:
	if r.kind == K.LINE and _horse_near(r, foes, Battle.SQUARE_STAND):
		# Horse about: stand, so the square forms and holds.
		return {"type": "halt", "id": r.id} if not r.waypoints.is_empty() else null
	var best: Regiment = null
	var best_d := r.fire_range * 1.1
	for f in foes:
		var d := r.pos.distance_to(f.pos)
		if d < best_d:
			best_d = d
			best = f
	if best != null:
		return _attack(r, best)
	if not advancing:
		return _move(r, goal + home * HOLD_SHORT)
	return _move(r, goal)


static func _horse_near(r: Regiment, foes: Array[Regiment], radius: float) -> bool:
	return foes.any(func(f): return UnitTypes.is_mounted(f.kind) and f.pos.distance_to(r.pos) < radius)


## Move only when it changes where the regiment is going.
static func _move(r: Regiment, to: Vector2) -> Variant:
	var heading_to := r.waypoints[r.waypoints.size() - 1] if not r.waypoints.is_empty() else r.pos
	if heading_to.distance_to(to) < 30.0 and r.target_id < 0:
		return null
	return {"type": "move", "id": r.id, "to": to}
