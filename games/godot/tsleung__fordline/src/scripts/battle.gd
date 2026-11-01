class_name Battle
extends RefCounted
## The battle simulation, and the one writer of battle state.
## Callers hand it orders (apply_orders) and advance it (step); the view
## reads its fields and drains its events (take_events).

const S := Regiment.State
const K := UnitTypes.Kind

const STEP := 1.0 / 30.0

const FLAG_RADIUS := 72.0
const CAPTURE_RATE := 0.3
const FLAG_DRAIN := 0.5
const DUSK_TIME := 240.0
const DUSK_DRAIN := 0.25
const ROUT_COST := 5.0
## Resolve won back when a broken regiment rallies.
const RALLY_REFUND := 3.0
const DESTROYED_COST := 4.0
const GENERAL_COST := 20.0
const BREAK_DELAY := 2.5

const AURA_RADIUS := 170.0
const RALLY_RADIUS := 280.0
const PANIC_RADIUS := 140.0
## Morale a regiment loses when a friend nearby breaks.
const PANIC_SHOCK := 3.0
const ENGAGE_RADIUS := 70.0

## Gates (their strength is the terrain's): what a cannonball or a barrage
## shell landing on one takes off it; what each soldier of the regiment
## pressed closest against it from outside takes off per second (one ram
## at a time); how close counts as pressed.
const GATE_SHOT := 5.0
const GATE_SHELL := 14.0
const RAM_PER_MAN := 0.04
const RAM_REACH := 48.0
## Line infantry standing its ground forms square when enemy horse comes
## this near, and stays in it until none is within SQUARE_STAND. In square:
## horse hits it at SQUARE_VS_HORSE, a charge doesn't land, it has no flank
## or rear, and only one face fires (SQUARE_FIRE of a volley).
const SQUARE_CALL := 240.0
const SQUARE_STAND := 330.0
const SQUARE_VS_HORSE := 0.35
const SQUARE_FIRE := 0.5

## Stamina per second: lost in melee, on the march and in flight; regained
## standing clear of the fight.
const FIGHT_TIRE := 0.018
const MARCH_TIRE := 0.003
const RIDE_TIRE := 0.008
const FLIGHT_TIRE := 0.02
const REST := 0.03

const ABILITY_COOLDOWN := {"rally": 40.0, "barrage": 55.0, "march": 35.0}

var terrain: Terrain
var rng := RandomNumberGenerator.new()
var regiments: Array[Regiment] = []
var phase := "deploy"
var time := 0.0
var winner := -1
var broken_team := -1
var break_timer := 0.0

## {"pos": Vector2, "owner": -1|0|1, "progress": -1..1 (+1 = team 0)}
var flags: Array[Dictionary] = []
var resolve := [100.0, 100.0]
var killed := [0, 0]
## Seconds into the battle at which it ends on the flags, or 0 for no
## deadline: then the player wins holding at least hold_needed flags and
## loses otherwise.
var deadline := 0.0
var hold_needed := 1
## Resolve per second per flag of difference; a siege sets 0, so the
## castle's flags decide at the deadline rather than bleeding the attacker.
var flag_drain := FLAG_DRAIN
## Grand battles: a rout costs this share of ROUT_COST and DESTROYED_COST,
## since there are many more blocks to lose; and when deadline_flags is
## set, the player must hold every one of those flags at the deadline.
var rout_scale := 1.0
## When the late drain starts (INF: never; a grand battle ends at its own
## dusk). pace: a grand battle stretches its fights to fit the day's clock,
## so volleys of arrows and shot do this share of their damage and nerve
## comes back at this share of its rate. A volley's shock is not scaled:
## brigades break long before they are shot to pieces.
var dusk_time := DUSK_TIME
var pace := 1.0
var deadline_flags: Array[int] = []
## Forces still on the road, soonest first. Each: {"at": seconds, "team",
## "formation": name, "road": points from the map edge to where it musters,
## "face": the angle it musters facing, "objectives", "units": [{"kind",
## "name", "stars"?}]}. Each arrives at its time; see _arrive.
var arrivals: Array[Dictionary] = []
## Each gate's strength left (fortress maps).
var gate_hp: Array[float] = []
## Abilities the player (team 0) has, and their cooldowns.
var abilities: Array[String] = []
var cooldowns := {"rally": 0.0, "barrage": 0.0, "march": 0.0}

var projectiles: Array[Dictionary] = []
var shells: Array[Dictionary] = []
var _events: Array[Dictionary] = []
var _by_id := {}
var _next_id := 1
var _looks := 0


func _init(map: Terrain, seed_value: int) -> void:
	terrain = map
	rng.seed = seed_value
	for p in map.flags:
		flags.append({"pos": p, "owner": -1, "progress": 0.0})
	for g in map.gates:
		gate_hp.append(g.hp)


func add_regiment(
	team: int, kind: int, men: int, at: Vector2, face: float, stars: int,
	doctrine: Dictionary, roster_index := -1
) -> Regiment:
	var r := Regiment.create(_next_id, team, kind, men, at, face, stars, doctrine)
	r.roster_index = roster_index
	_next_id += 1
	regiments.append(r)
	_by_id[r.id] = r
	return r


func get_regiment(id: int) -> Regiment:
	return _by_id.get(id)


func team_regiments(team: int) -> Array[Regiment]:
	var out: Array[Regiment] = []
	for r in regiments:
		if r.team == team and r.alive():
			out.append(r)
	return out


func general_of(team: int) -> Regiment:
	for r in regiments:
		if r.team == team and r.kind == K.GENERAL and r.fighting():
			return r
	return null


## Set a flag's owner before the battle begins (a scenario's start).
func claim_flag(index: int, team: int) -> void:
	if phase != "deploy":
		return
	flags[index].owner = team
	flags[index].progress = 1.0 if team == 0 else -1.0


func flags_held(team: int) -> int:
	var n := 0
	for f in flags:
		if f.owner == team:
			n += 1
	return n


func take_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


func begin() -> void:
	phase = "battle"
	_emit({"type": "begin"})


# --- orders ----------------------------------------------------------------

## Orders are dictionaries; see the match arms for each type's fields.
func apply_orders(orders: Array) -> void:
	for o in orders:
		match o.type:
			"place":
				_order_place(o)
			"move":
				_order_move(o)
			"attack":
				_order_attack(o)
			"halt":
				_order_halt(o)
			"rally":
				_ability_rally()
			"barrage":
				_ability_barrage(o.pos)
			"march":
				_ability_march(o.ids)
			"bombard":
				_order_bombard(o)
			"objective":
				_order_objective(o)


func _commandable(id: int) -> Regiment:
	var r := get_regiment(id)
	if r == null or not r.fighting():
		return null
	return r


func _order_place(o: Dictionary) -> void:
	var r := _commandable(o.id)
	if r == null or phase != "deploy":
		return
	var to := terrain.clamp_deploy(r.team, o.to)
	if terrain.is_water(to) or terrain.walled(to, r.team):
		return
	r.pos = to
	if o.has("facing"):
		r.facing = o.facing
	r.final_facing = r.facing
	for i in r.men():
		r.soldiers[i] = r.slot_world(i, r.men())


func _order_move(o: Dictionary) -> void:
	var r := _commandable(o.id)
	if r == null or phase != "battle":
		return
	if o.get("append", false) and r.target_id < 0 and not r.waypoints.is_empty():
		# Another leg after the route it already has.
		r.waypoints.append_array(terrain.path(r.waypoints[r.waypoints.size() - 1], o.to))
	else:
		r.waypoints = terrain.path(r.pos, o.to)
	r.final_facing = o.get("facing", NAN)
	r.target_id = -1
	r.target_gate = -1
	r.via = Vector2(NAN, NAN)
	r.ordered = true
	if r.state == S.IDLE:
		r.state = S.MOVING


func _order_attack(o: Dictionary) -> void:
	var r := _commandable(o.id)
	var t := get_regiment(o.target)
	if r == null or t == null or not t.alive() or t.team == r.team or phase != "battle":
		return
	r.target_id = t.id
	r.target_gate = -1
	r.via = o.get("via", Vector2(NAN, NAN))
	r.waypoints = PackedVector2Array()
	r.repath = 0.0
	r.final_facing = NAN
	r.ordered = true


## Guns only: batter an enemy gate still standing, from within range.
func _order_bombard(o: Dictionary) -> void:
	var r := _commandable(o.id)
	var g: int = o.gate
	if r == null or r.kind != K.CANNONS or phase != "battle" or not _gate_standing(g) or terrain.holder == r.team:
		return
	r.target_gate = g
	r.target_id = -1
	r.waypoints = PackedVector2Array()
	r.repath = 0.0
	r.ordered = true


## A block handed to its division's own command: its objective is now this
## one flag, to take and hold. Whoever commands it (the AI) moves it there.
func _order_objective(o: Dictionary) -> void:
	var r := _commandable(o.id)
	if r == null or phase != "battle":
		return
	r.objectives = PackedVector2Array([o.at])


func _gate_standing(g: int) -> bool:
	return g >= 0 and g < gate_hp.size() and not terrain.gate_broken[g]


func _order_halt(o: Dictionary) -> void:
	var r := _commandable(o.id)
	if r == null:
		return
	r.waypoints = PackedVector2Array()
	r.target_id = -1
	r.target_gate = -1
	r.ordered = true


func _ability_ready(name: String) -> bool:
	return phase == "battle" and name in abilities and cooldowns[name] <= 0.0


func _ability_rally() -> void:
	var g := general_of(0)
	if not _ability_ready("rally") or g == null:
		return
	cooldowns.rally = ABILITY_COOLDOWN.rally
	for r in team_regiments(0):
		if r.pos.distance_to(g.pos) > RALLY_RADIUS:
			continue
		if r.state == S.ROUTING:
			if r.strength() >= 0.2:
				_rally(r)
				r.morale = r.morale_max * 0.6
		else:
			r.morale = minf(r.morale_max, r.morale + 40.0)
	_emit({"type": "horn", "pos": g.pos, "team": 0})


func _ability_barrage(at: Vector2) -> void:
	if not _ability_ready("barrage"):
		return
	cooldowns.barrage = ABILITY_COOLDOWN.barrage
	for i in 6:
		var off := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(0.0, 70.0)
		shells.append({"pos": at + off, "t": 1.2 + 0.25 * i})
	_emit({"type": "barrage", "pos": at, "team": 0})


func _ability_march(ids: Array) -> void:
	if not _ability_ready("march"):
		return
	cooldowns.march = ABILITY_COOLDOWN.march
	for id in ids:
		var r := _commandable(id)
		if r != null and r.team == 0:
			r.march_t = 10.0
	_emit({"type": "march", "team": 0})


# --- the step --------------------------------------------------------------

func step(dt: float) -> void:
	if phase != "battle":
		return
	time += dt
	while not arrivals.is_empty() and time >= arrivals[0].at:
		_arrive(arrivals.pop_front())
	_update_contacts()
	for r in regiments:
		if r.alive():
			_think(r, dt)
	_separate()
	_squares()
	_melee(dt)
	_ram(dt)
	_tire(dt)
	_ranged(dt)
	_fly(dt)
	_shells(dt)
	_morale(dt)
	_flags(dt)
	_drain(dt)
	_place_soldiers(dt)
	for key in cooldowns:
		cooldowns[key] = maxf(0.0, cooldowns[key] - dt)
	_check_end(dt)


## A force reaches the field: its blocks appear in column on the road at
## the map edge and march up it to muster side by side across its end.
func _arrive(a: Dictionary) -> void:
	var road: PackedVector2Array = a.road
	var end := road[road.size() - 1]
	var face: float = a.face
	var across := Vector2.from_angle(face).orthogonal()
	var units: Array = a.units
	var gap := 10.0
	var widths: Array[float] = []
	var regs: Array[Regiment] = []
	var inward := (road[1] - road[0]).normalized()
	for i in units.size():
		var u: Dictionary = units[i]
		var at := terrain.clamp_to_field(road[0] + inward * (30.0 + 55.0 * i))
		var r := add_regiment(a.team, u.kind, UnitTypes.stat(u.kind, "men"), at, inward.angle(), u.get("stars", 0), {})
		r.name = u.name
		r.formation = a.formation
		r.objectives = a.get("objectives", PackedVector2Array())
		regs.append(r)
		widths.append(r.width())
	var total := -gap
	for w in widths:
		total += w + gap
	var cursor := -total * 0.5
	for i in regs.size():
		var r := regs[i]
		var slot := end + across * (cursor + widths[i] * 0.5)
		cursor += widths[i] + gap
		r.waypoints = road.slice(1, road.size() - 1)
		r.waypoints.append(slot)
		r.final_facing = face
		r.ordered = true
		r.state = S.MOVING
	_emit({"type": "arrival", "team": a.team, "formation": a.formation, "from": a.get("from", ""), "pos": end})


func _update_contacts() -> void:
	var pairs: Array = []
	for r in regiments:
		r.contacts.clear()
	var live := _live()
	var at := _live_positions(live)
	var radii := _live_radii(live)
	var fighting := live.map(func(r): return r.fighting())
	for i in live.size():
		var a: Regiment = live[i]
		for j in range(i + 1, live.size()):
			var b: Regiment = live[j]
			if b.team == a.team or not (fighting[i] or fighting[j]):
				continue
			var near := radii[i] + radii[j]
			if at[i].distance_squared_to(at[j]) >= near * near:
				continue
			var d := a.pos.distance_to(b.pos)
			var ang := (b.pos - a.pos).angle()
			if d < a.reach(ang) + b.reach(ang + PI) and not terrain.wall_between(a.pos, b.pos):
				pairs.append([d, a, b])
	pairs.sort_custom(func(x, y): return x[0] < y[0])
	for p in pairs:
		p[1].contacts.append(p[2].id)
		p[2].contacts.append(p[1].id)


func _think(r: Regiment, dt: float) -> void:
	r.charge_t = maxf(0.0, r.charge_t - dt)
	r.march_t = maxf(0.0, r.march_t - dt)
	r.repath -= dt
	if r.state == S.ROUTING:
		_flee(r, dt)
		return
	if not r.contacts.is_empty():
		_hold_contact(r, dt)
		return
	if r.state == S.ENGAGED:
		r.state = S.IDLE
	_pursue(r)
	if r.waypoints.is_empty() and r.target_id < 0 and not UnitTypes.is_ranged(r.kind):
		var e := _nearest_enemy(r, ENGAGE_RADIUS * (1.4 if UnitTypes.is_mounted(r.kind) else 1.0), true)
		if e != null:
			r.target_id = e.id
			r.ordered = false
			_pursue(r)
	if r.waypoints.is_empty():
		r.last_speed = 0.0
		if r.state == S.MOVING:
			r.state = S.IDLE
		if not is_nan(r.final_facing):
			_turn(r, r.final_facing, dt)
		return
	r.state = S.MOVING
	var goal := r.waypoints[0]
	_advance(r, goal, 1.0, dt)
	if r.pos.distance_to(goal) < 4.0:
		r.waypoints.remove_at(0)


## Close on the target, or stop in range of it when shooting.
func _pursue(r: Regiment) -> void:
	if r.target_gate >= 0:
		_pursue_gate(r)
		return
	if r.target_id < 0:
		return
	var t := get_regiment(r.target_id)
	var mounted := UnitTypes.is_mounted(r.kind)
	if t == null or not t.alive() or (t.state == S.ROUTING and not mounted):
		r.target_id = -1
		r.waypoints = PackedVector2Array()
		return
	if UnitTypes.is_ranged(r.kind):
		if r.pos.distance_to(t.pos) <= _range_of(r) * 0.95:
			r.waypoints = PackedVector2Array()
			r.final_facing = (t.pos - r.pos).angle()
			return
	var goal := t.pos
	if not is_nan(r.via.x):
		if r.pos.distance_to(r.via) < 12.0:
			r.via = Vector2(NAN, NAN)
		else:
			goal = r.via
	if r.repath <= 0.0 or r.waypoints.is_empty():
		r.waypoints = terrain.path(r.pos, goal)
		r.repath = 0.5


func _pursue_gate(r: Regiment) -> void:
	if not _gate_standing(r.target_gate):
		r.target_gate = -1
		r.waypoints = PackedVector2Array()
		return
	var g: Vector2 = terrain.gates[r.target_gate].c
	if r.pos.distance_to(g) <= _range_of(r) * 0.9:
		r.waypoints = PackedVector2Array()
		r.final_facing = (g - r.pos).angle()
		return
	if r.repath <= 0.0 or r.waypoints.is_empty():
		r.waypoints = terrain.path(r.pos, g + (r.pos - g).normalized() * _range_of(r) * 0.8)
		r.repath = 1.0


func _hold_contact(r: Regiment, dt: float) -> void:
	var was_engaged := r.state == S.ENGAGED
	r.state = S.ENGAGED
	var primary := get_regiment(r.contacts[0])
	if r.target_id in r.contacts:
		primary = get_regiment(r.target_id)
	if not was_engaged:
		_on_impact(r, primary)
	if r.ordered and not r.waypoints.is_empty() and r.target_id < 0:
		# Ordered away: withdraw at half pace if the way is clear of the enemy.
		var away := true
		var dir := r.waypoints[0] - r.pos
		for id in r.contacts:
			if dir.dot(get_regiment(id).pos - r.pos) > 0.0:
				away = false
		if away:
			_advance(r, r.waypoints[0], 0.5, dt)
			return
	if primary.fighting() or UnitTypes.is_mounted(r.kind):
		_turn(r, (primary.pos - r.pos).angle(), dt)
	r.last_speed = 0.0


func _on_impact(r: Regiment, enemy: Regiment) -> void:
	var z := Combat.zone(enemy.pos, enemy.facing, r.pos)
	if z != Combat.Zone.FRONT and enemy.fighting() and not enemy.square:
		_emit({"type": "flank", "zone": z, "pos": enemy.pos, "team": r.team, "kind": enemy.kind})
	if not UnitTypes.is_mounted(r.kind) or r.last_speed < r.speed * 0.6 or r.stamina < Combat.CHARGE_STAMINA:
		return
	if enemy.square or not Combat.charge_lands(enemy.kind, z):
		_emit({"type": "braced", "pos": enemy.pos})
		return
	r.charge_t = Combat.CHARGE_TIME
	enemy.morale -= Combat.CHARGE_SHOCK * Combat.ZONE_MORALE[z]
	_emit({"type": "charge", "pos": (r.pos + enemy.pos) * 0.5, "team": r.team})


func _flee(r: Regiment, dt: float) -> void:
	if r.waypoints.is_empty():
		r.waypoints = terrain.path(r.pos, _edge_point(r))
	_advance(r, r.waypoints[0], 1.15, dt)
	# A route planned before the crowd pushed it off its line can run into
	# stone; then it was cleared, and the next step plans afresh.
	if not r.waypoints.is_empty() and r.pos.distance_to(r.waypoints[0]) < 6.0:
		r.waypoints.remove_at(0)
	var edge_y := terrain.size.y - 12.0 if r.team == 0 else 12.0
	if (r.team == 0 and r.pos.y >= edge_y) or (r.team == 1 and r.pos.y <= edge_y):
		r.state = S.GONE
		r.fled = true
		_emit({"type": "fled", "pos": r.pos, "team": r.team})


func _edge_point(r: Regiment) -> Vector2:
	return Vector2(r.pos.x, terrain.size.y - 4.0 if r.team == 0 else 4.0)


func _advance(r: Regiment, goal: Vector2, pace: float, dt: float) -> void:
	var to_goal := goal - r.pos
	var dist := to_goal.length()
	if dist < 0.01:
		return
	var mult := terrain.speed_mult(r.pos) * pace * (1.6 if r.march_t > 0.0 else 1.0) * Combat.fatigue_pace(r.stamina)
	var stride := minf(dist, r.speed * mult * dt)
	var dir := to_goal / dist
	var next := r.pos + dir * stride
	if _stopped(r, next):
		var slide_x := r.pos + Vector2(dir.x, 0.0) * stride
		var slide_y := r.pos + Vector2(0.0, dir.y) * stride
		if not _stopped(r, slide_x):
			next = slide_x
		elif not _stopped(r, slide_y):
			next = slide_y
		else:
			r.last_speed = 0.0
			r.waypoints = PackedVector2Array()
			return
	r.last_speed = r.pos.distance_to(next) / dt
	r.pos = terrain.clamp_to_field(next)
	_turn(r, dir.angle(), dt * 1.5)


## Water stops all but the routing; walls and shut gates stop everyone.
func _stopped(r: Regiment, p: Vector2) -> bool:
	return (terrain.is_blocked(p) and r.state != S.ROUTING) or terrain.walled(p, r.team)


func _turn(r: Regiment, angle: float, dt: float) -> void:
	var rate := 2.6 if UnitTypes.is_mounted(r.kind) else 1.5
	var diff := angle_difference(r.facing, angle)
	r.facing += clampf(diff, -rate * dt, rate * dt)


func _separate() -> void:
	var live := _live()
	var at := _live_positions(live)
	var radii := _live_radii(live)
	for i in live.size():
		var a: Regiment = live[i]
		for j in range(i + 1, live.size()):
			var b: Regiment = live[j]
			# No pair farther apart than their widest reaches can overlap;
			# most pairs on a big field are, and are skipped cheaply.
			var near := (radii[i] + radii[j]) * (0.85 if a.team == b.team else 0.7)
			if at[i].distance_squared_to(at[j]) >= near * near:
				continue
			var delta := b.pos - a.pos
			var d := delta.length()
			var ang := delta.angle()
			var want := (a.reach(ang) + b.reach(ang + PI)) * (0.85 if a.team == b.team else 0.7)
			if d >= want or d < 0.001:
				continue
			var push := delta / d * (want - d) * 0.25
			_nudge(a, -push)
			_nudge(b, push)
			at[i] = a.pos
			at[j] = b.pos


## The regiments still on the field, in order, and their positions and
## radius() alongside, for the pair loops' cheap test.
func _live() -> Array[Regiment]:
	var out: Array[Regiment] = []
	for r in regiments:
		if r.alive():
			out.append(r)
	return out


func _live_positions(live: Array[Regiment]) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.resize(live.size())
	for i in live.size():
		out[i] = live[i].pos
	return out


func _live_radii(live: Array[Regiment]) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(live.size())
	for i in live.size():
		out[i] = live[i].radius()
	return out


func _nudge(r: Regiment, by: Vector2) -> void:
	var next := terrain.clamp_to_field(r.pos + by)
	if not terrain.is_water(next) and not terrain.walled(next, r.team):
		r.pos = next


func _melee(dt: float) -> void:
	for r in regiments:
		if not r.fighting() or r.contacts.is_empty():
			continue
		var share := 1.0 / r.contacts.size()
		for id in r.contacts:
			var e := get_regiment(id)
			if not e.alive():
				continue
			var z := Combat.zone(e.pos, e.facing, r.pos)
			if e.state == S.ROUTING:
				z = Combat.Zone.REAR
			elif e.square:
				z = Combat.Zone.FRONT
			var dps := Combat.melee_dps(
				r.kind, r.men(), r.formation_cols(r.men()), r.atk,
				e.kind, e.def + terrain.defence_bonus(e.pos), z, r.charge_t > 0.0
			) * share * Combat.fatigue_hit(r.stamina)
			if e.square and UnitTypes.is_mounted(r.kind):
				dps *= SQUARE_VS_HORSE
			if e.fighting():
				e.morale -= Combat.MELEE_STRAIN * Combat.ZONE_MORALE[z] * share * dt * Combat.fatigue_nerve(e.stamina)
			_wound(e, dps * dt, r.pos, r, Combat.ZONE_MORALE[z])


## Line infantry forms square when enemy horse comes near while it stands,
## unless the horse is already on it; it forms line again once the horse has
## gone, or when it is ordered to march.
func _squares() -> void:
	var horse_by_team := [[], []]
	for e in regiments:
		if e.fighting() and UnitTypes.is_mounted(e.kind):
			horse_by_team[e.team].append(e)
	for r in regiments:
		if r.kind != K.LINE or not r.fighting():
			if r.square:
				r.square = false
			continue
		var horse := _nearest_of(r, horse_by_team[1 - r.team])
		var near := INF if horse == null else horse.pos.distance_to(r.pos)
		if r.square:
			if not r.waypoints.is_empty() or near > SQUARE_STAND:
				r.square = false
		elif r.waypoints.is_empty() and near < SQUARE_CALL and not r.contacts.any(func(id): return UnitTypes.is_mounted(get_regiment(id).kind)):
			r.square = true
			_emit({"type": "square", "pos": r.pos, "team": r.team})


func _nearest_of(r: Regiment, among: Array) -> Regiment:
	var best: Regiment = null
	var best_d := INF
	for e in among:
		var d: float = e.pos.distance_to(r.pos)
		if d < best_d:
			best_d = d
			best = e
	return best


## Foot pressed against an enemy gate from outside batter it down.
func _ram(dt: float) -> void:
	for g in gate_hp.size():
		if terrain.gate_broken[g]:
			continue
		var gate: Dictionary = terrain.gates[g]
		var ram: Regiment = null
		var ram_d := RAM_REACH
		for r in regiments:
			if r.team == terrain.holder or not r.fighting() or UnitTypes.is_ranged(r.kind) or UnitTypes.is_mounted(r.kind):
				continue
			var d := r.pos.distance_to(gate.c)
			if d < ram_d and (r.pos - gate.c).dot(gate.out) > 0.0:
				ram_d = d
				ram = r
		if ram != null:
			var before := gate_hp[g]
			_hit_gate(g, RAM_PER_MAN * ram.men() * dt)
			if int(before / 6.0) != int(gate_hp[g] / 6.0):
				_emit({"type": "ram", "pos": gate.c})


func _hit_gates(at: Vector2, radius: float, dmg: float, by_team: int) -> void:
	if by_team == terrain.holder:
		return
	for g in gate_hp.size():
		if not terrain.gate_broken[g] and at.distance_to(terrain.gates[g].c) < radius:
			_hit_gate(g, dmg)


func _hit_gate(g: int, dmg: float) -> void:
	gate_hp[g] -= dmg
	if gate_hp[g] > 0.0:
		return
	gate_hp[g] = 0.0
	terrain.gate_broken[g] = true
	for r in regiments:
		if r.target_gate == g:
			r.target_gate = -1
	_emit({"type": "gate", "pos": terrain.gates[g].c, "index": g})


func _tire(dt: float) -> void:
	for r in regiments:
		if not r.alive():
			continue
		var change := REST
		if r.state == S.ROUTING:
			change = -FLIGHT_TIRE
		elif not r.contacts.is_empty():
			change = -FIGHT_TIRE
		elif r.last_speed > r.speed * 0.6 and UnitTypes.is_mounted(r.kind):
			change = -RIDE_TIRE
		elif r.last_speed > 1.0:
			change = -MARCH_TIRE
		r.stamina = clampf(r.stamina + change * dt, 0.0, 1.0)


func _range_of(r: Regiment) -> float:
	return r.fire_range * terrain.range_mult(r.pos)


func _ranged(dt: float) -> void:
	for r in regiments:
		if not r.fighting() or not UnitTypes.is_ranged(r.kind):
			continue
		r.reload -= dt
		if r.target_gate >= 0 and _gate_standing(r.target_gate):
			var gate: Vector2 = terrain.gates[r.target_gate].c
			if r.contacts.is_empty() and r.pos.distance_to(gate) <= _range_of(r):
				if r.waypoints.is_empty():
					_turn(r, (gate - r.pos).angle(), dt)
				if r.reload <= 0.0:
					r.reload = r.reload_time
					_fire_guns(r, gate)
			continue
		if not r.contacts.is_empty() or (r.state == S.MOVING and r.target_id < 0):
			continue
		var t := _shot_target(r)
		if t == null:
			continue
		if r.waypoints.is_empty():
			_turn(r, (t.pos - r.pos).angle(), dt)
		if r.reload > 0.0:
			continue
		r.reload = r.reload_time
		match r.kind:
			K.ARCHERS:
				_loose_volley(r, t)
			K.MUSKETS, K.RIFLES, K.LINE:
				_fire_muskets(r, t)
			_:
				_fire_guns(r, t.pos)


func _shot_target(r: Regiment) -> Regiment:
	var reach := _range_of(r)
	var t := get_regiment(r.target_id) if r.target_id >= 0 else null
	if t != null and t.alive() and r.pos.distance_to(t.pos) <= reach:
		return t
	var best: Regiment = null
	var best_d := INF
	for e in regiments:
		if e.team == r.team or not e.alive():
			continue
		var d := r.pos.distance_to(e.pos)
		if d < 40.0 or d > reach:
			continue
		# Fighting regiments first, and those not already locked with ours.
		if not e.fighting():
			d += 400.0
		elif not e.contacts.is_empty():
			d += 120.0
		if d < best_d:
			best_d = d
			best = e
	return best


func _loose_volley(r: Regiment, t: Regiment) -> void:
	var dmg := Combat.volley_damage(r.men(), r.shot, r.accuracy, t.def + terrain.defence_bonus(t.pos))
	dmg *= terrain.cover(t.pos)
	if not t.contacts.is_empty():
		dmg *= 0.6
	var d := r.pos.distance_to(t.pos)
	projectiles.append({
		"kind": "arrows", "from": r.pos, "to": t.pos, "t": 0.0, "dur": 0.5 + d / 420.0,
		"target": t.id, "src": r.id, "team": r.team, "dmg": dmg, "shock": r.shock,
		"count": mini(r.men(), 12), "seed": _look_seed(),
	})
	_emit({"type": "volley", "pos": r.pos, "team": r.team})


## A volley of shot lands at once. It goes through most armour but not
## through trees, and it shakes whoever it hits.
func _fire_muskets(r: Regiment, t: Regiment) -> void:
	var d := r.pos.distance_to(t.pos)
	var armour := Combat.pierced(t.def, r.pierce) + terrain.defence_bonus(t.pos)
	var dmg := Combat.volley_damage(r.men(), r.shot, r.accuracy, armour) * terrain.cover(t.pos)
	if not t.contacts.is_empty():
		dmg *= 0.6
	if r.square:
		dmg *= SQUARE_FIRE
	projectiles.append({
		"kind": "shot", "from": r.pos, "to": t.pos, "t": 0.0, "dur": 0.08 + d / 2000.0,
		"target": t.id, "src": r.id, "team": r.team, "dmg": dmg, "shock": r.shock,
		"count": mini(r.men(), 14), "seed": _look_seed(),
	})
	_emit({"type": "musket", "pos": r.pos, "facing": r.facing, "width": r.width(), "team": r.team})


## A seed for how a flight looks on screen (where its arrows scatter). It is
## counted, not drawn from the battle's random numbers, so what is drawn
## never changes what happens.
func _look_seed() -> int:
	_looks += 1
	return hash(_looks)


func _fire_guns(r: Regiment, at: Vector2) -> void:
	var guns := 2 if r.men() >= 5 else 1
	var d := r.pos.distance_to(at)
	for g in guns:
		var scatter := 8.0 + d * 0.06
		var to := at + Vector2(rng.randf_range(-scatter, scatter), rng.randf_range(-scatter, scatter))
		var from := r.pos + r.forward().orthogonal() * (g - 0.5) * 18.0
		projectiles.append({
			"kind": "ball", "from": from, "to": to, "t": 0.0, "dur": 0.25 + d / 600.0 + g * 0.12,
			"src": r.id, "team": r.team, "dmg": r.shot,
		})
		_emit({"type": "boom", "pos": from, "team": r.team})


func _fly(dt: float) -> void:
	var landed: Array[Dictionary] = []
	for p in projectiles:
		p.t += dt / p.dur
		if p.t >= 1.0:
			landed.append(p)
	for p in landed:
		projectiles.erase(p)
		var src := get_regiment(p.src)
		if p.kind == "arrows" or p.kind == "shot":
			var t := get_regiment(p.target)
			if t != null and t.alive():
				if t.fighting():
					t.morale -= p.shock
				_wound(t, p.dmg * pace, p.from, src, 1.0)
		else:
			_blast(p.to, 1 - p.team, 13.0, 3, 6.0, src)
			_hit_gates(p.to, 40.0, GATE_SHOT, p.team)
			_emit({"type": "impact", "pos": p.to, "big": false})


func _shells(dt: float) -> void:
	var due: Array[Dictionary] = []
	for s in shells:
		s.t -= dt
		if s.t <= 0.0:
			due.append(s)
	for s in due:
		shells.erase(s)
		_blast(s.pos, 1, 20.0, 5, 10.0, null)
		_hit_gates(s.pos, 50.0, GATE_SHELL, 0)
		_emit({"type": "impact", "pos": s.pos, "big": true})


## Kill up to `max_kills` soldiers of `team` within `radius` of `at`, and
## shake every regiment of that team close by.
func _blast(at: Vector2, team: int, radius: float, max_kills: int, shock: float, src: Regiment) -> void:
	var left := max_kills
	for r in regiments:
		if r.team != team or not r.alive():
			continue
		var d := r.pos.distance_to(at)
		if d > 60.0 + r.width():
			continue
		if r.fighting() and d < 50.0:
			r.morale -= shock
		var victims: Array[int] = []
		for i in r.men():
			if left > 0 and r.soldiers[i].distance_to(at) < radius:
				victims.append(i)
				left -= 1
		if not victims.is_empty():
			_kill(r, victims, src, 1.0)


## Apply damage to `e`; whole soldiers die nearest to `from`.
func _wound(e: Regiment, dmg: float, from: Vector2, src: Regiment, morale_mult: float) -> void:
	e.wound += dmg
	var n := mini(int(e.wound / e.hp), e.men())
	if n <= 0:
		return
	e.wound -= n * e.hp
	var order: Array = range(e.men())
	order.sort_custom(func(a, b): return e.soldiers[a].distance_squared_to(from) < e.soldiers[b].distance_squared_to(from))
	_kill(e, order.slice(0, n), src, morale_mult)


func _kill(e: Regiment, indices: Array, src: Regiment, morale_mult: float) -> void:
	indices.sort()
	indices.reverse()
	for i in indices:
		_emit({"type": "death", "pos": e.soldiers[i], "team": e.team, "kind": e.kind})
		e.soldiers.remove_at(i)
	var n := indices.size()
	killed[1 - e.team] += n
	if src != null:
		src.kills += n
	if e.fighting():
		var aura := 0.7 if _in_aura(e) else 1.0
		e.morale -= Combat.loss_morale(n, e.men_max) * morale_mult * aura * Combat.fatigue_nerve(e.stamina)
	if e.men() == 0:
		_destroy(e)


func _destroy(e: Regiment) -> void:
	var was_routed := e.routed_once
	e.state = S.GONE
	resolve[e.team] -= (DESTROYED_COST + (0.0 if was_routed else ROUT_COST)) * rout_scale
	# A general who routed was already mourned (and charged) when he broke.
	if e.kind == K.GENERAL and not was_routed:
		_lose_general(e.team)
	_emit({"type": "destroyed", "pos": e.pos, "team": e.team, "kind": e.kind})


func _lose_general(team: int) -> void:
	resolve[team] -= GENERAL_COST
	for r in team_regiments(team):
		if r.fighting():
			r.morale -= 25.0
	_emit({"type": "general", "team": team})


func _in_aura(r: Regiment) -> bool:
	if r.kind == K.GENERAL:
		return true
	var g := general_of(r.team)
	return g != null and g.pos.distance_to(r.pos) < AURA_RADIUS


func _morale(dt: float) -> void:
	for r in regiments:
		if not r.alive():
			continue
		if r.state == S.ROUTING:
			if _nearest_enemy(r, 130.0, true) == null:
				r.morale += 7.0 * pace * dt
			if r.morale >= r.morale_max * 0.4 and r.strength() >= 0.25:
				_rally(r)
			continue
		var regen := 0.0
		if r.contacts.is_empty():
			regen = 3.5 + (3.0 if _in_aura(r) else 0.0)
		elif _in_aura(r):
			regen = 1.2
		r.morale = minf(r.morale_max, r.morale + regen * pace * dt)
		if r.morale <= 0.0:
			_rout(r)


func _rout(r: Regiment) -> void:
	r.state = S.ROUTING
	r.morale = 0.0
	r.target_id = -1
	r.ordered = false
	r.charge_t = 0.0
	r.waypoints = terrain.path(r.pos, _edge_point(r))
	if not r.routed_once:
		r.routed_once = true
		resolve[r.team] -= ROUT_COST * rout_scale
		if r.kind == K.GENERAL:
			_lose_general(r.team)
	for f in team_regiments(r.team):
		if f != r and f.fighting() and f.pos.distance_to(r.pos) < PANIC_RADIUS:
			f.morale -= PANIC_SHOCK
	_emit({"type": "rout", "pos": r.pos, "team": r.team, "kind": r.kind, "id": r.id})


func _rally(r: Regiment) -> void:
	if r.team == broken_team:
		return
	r.state = S.IDLE
	r.waypoints = PackedVector2Array()
	r.final_facing = PI * 1.5 if r.team == 0 else PI * 0.5
	resolve[r.team] = minf(100.0, resolve[r.team] + RALLY_REFUND)
	_emit({"type": "rally", "pos": r.pos, "team": r.team, "id": r.id})


func _nearest_enemy(r: Regiment, radius: float, fighting_only: bool) -> Regiment:
	var best: Regiment = null
	var best_d := radius
	for e in regiments:
		if e.team == r.team or not e.alive() or (fighting_only and not e.fighting()):
			continue
		var d := r.pos.distance_to(e.pos)
		if d < best_d:
			best_d = d
			best = e
	return best


func _flags(dt: float) -> void:
	for f in flags:
		var present := [0, 0]
		for r in regiments:
			if r.fighting() and r.pos.distance_to(f.pos) < FLAG_RADIUS:
				present[r.team] += 1
		var push := 0.0
		if present[0] > 0 and present[1] == 0:
			push = 1.0
		elif present[1] > 0 and present[0] == 0:
			push = -1.0
		if push == 0.0:
			continue
		f.progress = clampf(f.progress + push * CAPTURE_RATE * dt, -1.0, 1.0)
		var owner: int = f.owner
		if f.progress >= 1.0:
			owner = 0
		elif f.progress <= -1.0:
			owner = 1
		elif (f.owner == 0 and f.progress < 0.0) or (f.owner == 1 and f.progress > 0.0):
			owner = -1
		if owner != f.owner:
			f.owner = owner
			_emit({"type": "flag", "pos": f.pos, "owner": owner, "index": flags.find(f)})


func _drain(dt: float) -> void:
	var diff := flags_held(0) - flags_held(1)
	var dusk := time > dusk_time
	var rate := flag_drain * (2.0 if dusk else 1.0)
	if diff > 0:
		resolve[1] -= rate * diff * dt
	elif diff < 0:
		resolve[0] -= rate * -diff * dt
	if dusk:
		resolve[0] -= DUSK_DRAIN * dt
		resolve[1] -= DUSK_DRAIN * dt
	resolve[0] = maxf(resolve[0], 0.0)
	resolve[1] = maxf(resolve[1], 0.0)


func _check_end(dt: float) -> void:
	if broken_team >= 0:
		break_timer -= dt
		if break_timer <= 0.0:
			phase = "over"
			winner = 1 - broken_team
			_emit({"type": "end", "winner": winner})
		return
	if deadline > 0.0 and time >= deadline:
		_emit({"type": "deadline", "held": flags_held(0)})
		var held := flags_held(0) >= hold_needed
		if not deadline_flags.is_empty():
			held = deadline_flags.all(func(i): return flags[i].owner == 0)
		_break(1 if held else 0)
		return
	for team in 2:
		var standing := false
		for r in team_regiments(team):
			if r.fighting():
				standing = true
		if resolve[team] <= 0.0 or not standing:
			_break(team)
			return


func _break(team: int) -> void:
	broken_team = team
	break_timer = BREAK_DELAY
	resolve[team] = 0.0
	for r in team_regiments(team):
		if r.fighting():
			_rout(r)
	_emit({"type": "broken", "team": team})


func _place_soldiers(dt: float) -> void:
	for r in regiments:
		if not r.alive():
			continue
		var n := r.men()
		var k := minf(1.0, dt * (5.0 if UnitTypes.is_mounted(r.kind) else 3.5))
		var routing := r.state == S.ROUTING
		var fwd := r.forward()
		var front := r.formation_cols(n)
		var slots := r.slots(n)
		for i in n:
			var target := slots[i]
			if routing:
				var h := float(i * 7919 + r.id * 104729)
				target += Vector2(sin(h), cos(h * 1.3)) * 16.0
			elif r.state == S.ENGAGED and i < front:
				target += fwd * (2.0 + 1.5 * sin(time * 9.0 + i * 1.7))
			r.soldiers[i] = r.soldiers[i].lerp(target, k)


func _emit(e: Dictionary) -> void:
	_events.append(e)
