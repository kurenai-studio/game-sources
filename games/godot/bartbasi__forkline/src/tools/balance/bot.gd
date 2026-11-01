# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## The balance bot: a strategy (the player's choices), a seeded generator and mutator for
## strategies, and a player that plays one on a Battle through the public API only
## (docs/ARCHITECTURE.md 3.3). Battles have no randomness, so a strategy and a level give one
## result. All the randomness is in making strategies, and every generator is seeded.
##
## A strategy is a Dictionary:
##   "towers": [{"cell": Vector2i, "type": StringName, "depth": 0 to 2, "spec": 0 or 1, "aim": int}]
##   "seq":    [tower index, ...]  the k-th time an index shows up is that tower's k-th purchase:
##             1 build, 2 upgrade to tier 2, 3 upgrade to tier 3 (its spec). Any order of the
##             multiset is a valid strategy, which keeps mutation simple.
##   "gates":  [Vector2i, ...] the sockets that get a gate, none for no gate (placed before wave 1, never
##             moved; a gate the level or Twist cannot give is refused and skipped)
##   "early":  {"on": bool, "from": waves started before calling, "live": call when at most this
##             many creatures are on the map, "max": most calls}
##   "wave_buy": bool, buy in the order of "seq" during waves as gold comes in
## The player buys strictly in the order of "seq", waiting when the next item costs too much.

const NO_CELL: Vector2i = Vector2i(-1, -1)
## 60 minutes of wave time at 1x: far past any level. A run that reaches it is reported as stuck.
const TICK_CAP: int = 72000
const BUILD_SECONDS: int = 15
const STYLES: Array[StringName] = [&"casual", &"typical", &"skilled"]
const LIVE_CHOICES: Array[int] = [0, 3, 8, 15, 40, 999]


## The road tiles that count as "road seen" (RULES 12.6 step 1): every road tile except tunnel tiles.
static func seen_road_cells(level: LevelData) -> Array[Vector2i]:
	var road: Array[Vector2i] = []
	for r: int in level.rows:
		for c: int in Sim.MAP_COLUMNS:
			var cell: Vector2i = Vector2i(c, r)
			if level.is_road(cell) and level.feature_at(cell) != LevelData.Feature.TUNNEL:
				road.append(cell)
	return road


## Road steps a creature has left to the base on `dist`, which is per node (docs/ARCHITECTURE.md 14.3), or -1 off the road.
## A walker on a bridge cell uses the node it is heading to, so it is read on the right road of the deck.
static func steps_left(b: Battle, dist: PackedInt32Array, enemy: EnemyState) -> int:
	var cell: Vector2i = Vector2i(enemy.pos.x / Sim.UNIT, enemy.pos.y / Sim.UNIT)
	var node: int = b.map.node_of(cell)
	if node < 0:
		return -1
	if not enemy.flying:
		var heading: int = b.map.arrival(enemy.from_cell, enemy.to_cell)
		if heading >= 0 and b.map.node_cell(heading) == cell:
			node = heading
	return dist[node]


## True for a tower that takes no aim, a pulse tower (RULES 5.12). Its aim stays First, so two builds that differ only in the
## aim of such a tower are not counted as two builds.
static func no_aim(ctx: Dictionary, type: StringName) -> bool:
	var catalog: Catalog = ctx["catalog"]
	return catalog.tower(type).stats(1, -1).pulse


## Level facts the generator needs, worked out once. With `twist`, the level's Twist is played
## (docs/ARCHITECTURE.md 2.8): its tower bans, gate count and fixed gates are in the facts below.
## "bad" is set when the sim refuses the Twist, which is a bug in the data.
static func context(game: GameData, level_id: StringName, twist: bool = false) -> Dictionary:
	var level: LevelData = game.levels[level_id]
	var effects: Array[Dictionary] = []
	if twist:
		effects.append_array(level.twist_effects)
	var probe: Battle = Battle.create(level, game.catalog, false, effects)
	if probe == null:
		return {"bad": "the sim refuses the Twist of %s" % level_id}
	var map: RoadMap = RoadMap.new(level)
	# Road seen is counted outside tunnels: a walker inside one is out of reach (RULES 12.6 step 1, 3.6).
	var road: Array[Vector2i] = seen_road_cells(level)
	# How many road cells a tier 1 Sling Post at each spot reaches: a rough "good spot" weight.
	# The plain recipe ranks by the same count (RULES 12.6), without the floor of 1.
	var reach: int = game.catalog.tower(&"sling_post").stats(1, -1).reach
	var weights: Array[int] = []
	var seen_road: Array[int] = []
	for spot: Vector2i in level.spots:
		var seen: int = 0
		for cell: Vector2i in road:
			var dx: int = (cell.x - spot.x) * 100
			var dy: int = (cell.y - spot.y) * 100
			if dx * dx + dy * dy <= reach * reach:
				seen += 1
		seen_road.append(seen)
		weights.append(maxi(seen, 1))
	# Gates: what is still in hand after the Twist's fixed gates, and the sockets that can take one.
	var fixed: Array[Vector2i] = probe.closed_cells()
	var gate_options: Array[Vector2i] = []
	for socket: Vector2i in level.sockets:
		if fixed.has(socket):
			continue
		var shut: Array[Vector2i] = fixed.duplicate()
		shut.append(socket)
		if not map.seals(shut):
			gate_options.append(socket)
	var banned: Array[StringName] = []
	for effect: Dictionary in effects:
		if String(effect["type"]) == "ban_tower":
			banned.append(StringName(String(effect["tower"])))
	var offered: Array[StringName] = []
	for id: StringName in level.towers:
		if not banned.has(id):
			offered.append(id)
	var boss: bool = false
	var flyers: bool = false
	for wave: WaveData in level.waves:
		for group: WaveGroup in wave.groups:
			var type: EnemyType = game.catalog.enemy(group.enemy)
			if type.boss:
				boss = true
			if type.flying:
				flyers = true
			# A boss that summons or releases flyers brings flyers too (RULES 12.6).
			for extra: Dictionary in [type.summon, type.release]:
				if not extra.is_empty() and game.catalog.enemy(StringName(extra["enemy"])).flying:
					flyers = true
	var region: int = 1
	var id_text: String = String(level_id)
	if id_text.length() > 3 and id_text[0] == "r" and id_text[1].is_valid_int() and id_text[2] == "_":
		region = int(id_text[1])
	return {"game": game, "level": level, "catalog": game.catalog, "id": level_id,
		"weights": weights, "gate_options": gate_options, "boss": boss,
		"twist": effects, "twist_on": twist, "offered": offered, "gate_count": probe.gates_in_hand,
		"fixed": fixed, "map": map, "road_seen": seen_road, "flyers": flyers, "region": region}


# Generating strategies.

## A random strategy in one of the three styles. `allowed` is the towers it may use.
##   casual:  every spot, no upgrades, a gate or none, no early calls, default targeting.
##   typical: most spots, some upgrades, a gate or none, no early calls.
##   skilled: any number of spots, any upgrades, targeting, early calls.
static func random_strategy(ctx: Dictionary, rng: RandomNumberGenerator, style: StringName, allowed: Array[StringName]) -> Dictionary:
	if style == &"guided":
		return _guided_strategy(ctx, rng, allowed)
	var level: LevelData = ctx["level"]
	var spots: Array[Vector2i] = _spot_order(ctx, rng)
	var count: int = spots.size()
	if style == &"typical":
		count = rng.randi_range(maxi(1, spots.size() * 6 / 10), spots.size())
	elif style == &"skilled":
		count = rng.randi_range(1, spots.size())
	# Per strategy tastes: how much of each tower, how deep to upgrade, which tier 3 path.
	var type_weight: Array[float] = []
	for i: int in allowed.size():
		type_weight.append(rng.randf())
	if rng.randf() < 0.25:
		var only: int = rng.randi_range(0, allowed.size() - 1)
		for i: int in allowed.size():
			type_weight[i] = 1.0 if i == only else 0.0
	var depth_weight: Array[float] = [0.3, 0.5, 0.2]
	if style == &"casual":
		depth_weight = [1.0, 0.0, 0.0]
	elif style == &"skilled":
		depth_weight = [rng.randf(), rng.randf(), rng.randf()]
	var spec_bias: Dictionary = {}
	for type: StringName in allowed:
		spec_bias[type] = rng.randf()
	var towers: Array = []
	var depths: Array[int] = []
	for i: int in count:
		var type: StringName = allowed[_pick(rng, type_weight)]
		var depth: int = _pick(rng, depth_weight)
		var spec: int = 0 if rng.randf() < float(spec_bias[type]) else 1
		var aim: int = TowerState.Aim.FIRST
		if style != &"casual" and rng.randf() < (0.15 if style == &"typical" else 0.4):
			aim = rng.randi_range(0, 2)
		if no_aim(ctx, type):
			aim = TowerState.Aim.FIRST
		towers.append({"cell": spots[i], "type": type, "depth": depth, "spec": spec, "aim": aim})
		depths.append(depth)
	# A random order of the purchases. `breadth` is how likely the next move is a new tower.
	var breadth: float = 1.0 if style == &"casual" else rng.randf()
	var seq: Array = []
	var done: Array[int] = []
	done.resize(count)
	done.fill(0)
	var next_new: int = 0
	while true:
		var open: Array[int] = []
		for i: int in next_new:
			if done[i] <= depths[i]:
				open.append(i)
		var can_new: bool = next_new < count
		if not can_new and open.is_empty():
			break
		if can_new and (open.is_empty() or rng.randf() < breadth):
			seq.append(next_new)
			done[next_new] = 1
			next_new += 1
		else:
			var pick: int = open[rng.randi_range(0, open.size() - 1)]
			seq.append(pick)
			done[pick] += 1
	var gates: Array[Vector2i] = []
	var options: Array[Vector2i] = ctx["gate_options"]
	if int(ctx["gate_count"]) > 0 and not options.is_empty():
		var none_chance: float = 0.7 if style == &"casual" else (0.15 if style == &"typical" else 0.25)
		if rng.randf() >= none_chance:
			gates = _pick_gates(ctx, rng)
	var early: Dictionary = {"on": false, "from": 1, "live": 0, "max": 99}
	if style == &"skilled" and rng.randf() < 0.4:
		early = {"on": true, "from": rng.randi_range(1, 4), "live": LIVE_CHOICES[rng.randi_range(0, LIVE_CHOICES.size() - 1)], "max": 99}
	return {"towers": towers, "seq": seq, "gates": gates, "early": early, "wave_buy": rng.randf() < 0.7}


## The guided style: a player who read the hint. Every spot gets a tower, both kinds are used, every
## tower goes to tier 2, builds come first and upgrades after. Where each kind goes and where the
## gate goes (or none) is random, so this is a floor for a thoughtful player, not a ceiling.
static func _guided_strategy(ctx: Dictionary, rng: RandomNumberGenerator, allowed: Array[StringName]) -> Dictionary:
	var level: LevelData = ctx["level"]
	var spots: Array[Vector2i] = []
	spots.append_array(level.spots)
	for i: int in range(spots.size() - 1, 0, -1):
		var j: int = rng.randi_range(0, i)
		var tmp: Vector2i = spots[i]
		spots[i] = spots[j]
		spots[j] = tmp
	var kinds: Array[int] = []
	for i: int in spots.size():
		kinds.append(rng.randi_range(0, allowed.size() - 1))
	# Both kinds are used at least once, when the level offers two.
	for k: int in allowed.size():
		if not kinds.has(k):
			kinds[rng.randi_range(0, spots.size() - 1)] = k
	var towers: Array = []
	var seq: Array = []
	for i: int in spots.size():
		towers.append({"cell": spots[i], "type": allowed[kinds[i]], "depth": 1, "spec": 0, "aim": TowerState.Aim.FIRST})
		seq.append(i)
	for i: int in spots.size():
		seq.append(i)
	var gates: Array[Vector2i] = []
	var options: Array[Vector2i] = ctx["gate_options"]
	if int(ctx["gate_count"]) > 0 and not options.is_empty() and rng.randf() < 0.5:
		gates = _pick_gates(ctx, rng)
	return {"towers": towers, "seq": seq, "gates": gates, "early": {"on": false, "from": 1, "live": 0, "max": 99}, "wave_buy": false}


## One socket when the level gives one gate (one draw, as before gates came in sets), else 1 to the
## gates in hand, all different.
static func _pick_gates(ctx: Dictionary, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var left: Array[Vector2i] = []
	left.append_array(ctx["gate_options"])
	var count: int = 1
	if int(ctx["gate_count"]) > 1:
		count = rng.randi_range(1, mini(int(ctx["gate_count"]), left.size()))
	var out: Array[Vector2i] = []
	for i: int in count:
		var at: int = rng.randi_range(0, left.size() - 1)
		out.append(left[at])
		left.remove_at(at)
	return out


## Spots in a random order, half the time weighted toward spots that see more road.
static func _spot_order(ctx: Dictionary, rng: RandomNumberGenerator) -> Array[Vector2i]:
	var level: LevelData = ctx["level"]
	var weights: Array[int] = ctx["weights"]
	var weighted: bool = rng.randf() < 0.5
	var keyed: Array = []
	for i: int in level.spots.size():
		var u: float = maxf(rng.randf(), 0.000001)
		var w: float = float(weights[i]) if weighted else 1.0
		keyed.append([-log(u) / w, i])
	keyed.sort_custom(func(a: Array, b: Array) -> bool: return float(a[0]) < float(b[0]))
	var out: Array[Vector2i] = []
	for item: Array in keyed:
		out.append(level.spots[int(item[1])])
	return out


## Index of a random pick by weight. All zero weights give index 0.
static func _pick(rng: RandomNumberGenerator, weights: Array[float]) -> int:
	var total: float = 0.0
	for w: float in weights:
		total += w
	if total <= 0.0:
		return 0
	var roll: float = rng.randf() * total
	for i: int in weights.size():
		roll -= weights[i]
		if roll < 0.0:
			return i
	return weights.size() - 1


# Mutating strategies.

## A changed copy: one to three small edits, all keeping the strategy valid.
static func mutate(ctx: Dictionary, strat: Dictionary, rng: RandomNumberGenerator, allowed: Array[StringName]) -> Dictionary:
	var out: Dictionary = strat.duplicate(true)
	var edits: int = rng.randi_range(1, 3)
	for e: int in edits:
		_edit(ctx, out, rng, allowed)
	return out


static func _edit(ctx: Dictionary, s: Dictionary, rng: RandomNumberGenerator, allowed: Array[StringName]) -> void:
	var level: LevelData = ctx["level"]
	var towers: Array = s["towers"]
	var seq: Array = s["seq"]
	var kind: int = rng.randi_range(0, 13)
	match kind:
		0, 1:                                               # swap two purchases
			if seq.size() >= 2:
				var a: int = rng.randi_range(0, seq.size() - 1)
				var b: int = rng.randi_range(0, seq.size() - 1)
				var tmp: int = seq[a]
				seq[a] = seq[b]
				seq[b] = tmp
		2:                                                  # move one purchase
			if seq.size() >= 2:
				var from: int = rng.randi_range(0, seq.size() - 1)
				var item: int = seq[from]
				seq.remove_at(from)
				seq.insert(rng.randi_range(0, seq.size()), item)
		3:                                                  # change a tower's type
			if not towers.is_empty() and allowed.size() > 1:
				var t: Dictionary = towers[rng.randi_range(0, towers.size() - 1)]
				t["type"] = allowed[rng.randi_range(0, allowed.size() - 1)]
				if no_aim(ctx, t["type"]):
					t["aim"] = TowerState.Aim.FIRST
		4:                                                  # one more upgrade
			if not towers.is_empty():
				var i: int = rng.randi_range(0, towers.size() - 1)
				var t: Dictionary = towers[i]
				if int(t["depth"]) < 2:
					t["depth"] = int(t["depth"]) + 1
					seq.insert(rng.randi_range(_last_index(seq, i) + 1, seq.size()), i)
		5:                                                  # one upgrade fewer
			if not towers.is_empty():
				var i: int = rng.randi_range(0, towers.size() - 1)
				var t: Dictionary = towers[i]
				if int(t["depth"]) > 0:
					t["depth"] = int(t["depth"]) - 1
					seq.remove_at(_last_index(seq, i))
		6:                                                  # add a tower on a free spot
			var free: Array[Vector2i] = []
			for spot: Vector2i in level.spots:
				if _tower_index(towers, spot) < 0:
					free.append(spot)
			if not free.is_empty():
				towers.append({"cell": free[rng.randi_range(0, free.size() - 1)], "type": allowed[rng.randi_range(0, allowed.size() - 1)],
					"depth": 0, "spec": rng.randi_range(0, 1), "aim": TowerState.Aim.FIRST})
				seq.insert(rng.randi_range(0, seq.size()), towers.size() - 1)
		7:                                                  # remove a tower
			if towers.size() > 1:
				var i: int = rng.randi_range(0, towers.size() - 1)
				towers.remove_at(i)
				var kept: Array = []
				for item: int in seq:
					if item == i:
						continue
					kept.append(item - 1 if item > i else item)
				seq.clear()
				seq.append_array(kept)
		8:                                                  # move a tower to another spot
			var free2: Array[Vector2i] = []
			for spot: Vector2i in level.spots:
				if _tower_index(towers, spot) < 0:
					free2.append(spot)
			if not towers.is_empty() and not free2.is_empty():
				var t: Dictionary = towers[rng.randi_range(0, towers.size() - 1)]
				t["cell"] = free2[rng.randi_range(0, free2.size() - 1)]
		9:                                                  # swap the spots of two towers
			if towers.size() >= 2:
				var a: int = rng.randi_range(0, towers.size() - 1)
				var b: int = rng.randi_range(0, towers.size() - 1)
				var cell: Vector2i = towers[a]["cell"]
				towers[a]["cell"] = towers[b]["cell"]
				towers[b]["cell"] = cell
		10:                                                 # flip a tier 3 path
			if not towers.is_empty():
				var t: Dictionary = towers[rng.randi_range(0, towers.size() - 1)]
				t["spec"] = 1 - int(t["spec"])
		11:                                                 # change a targeting mode
			if not towers.is_empty():
				var t: Dictionary = towers[rng.randi_range(0, towers.size() - 1)]
				t["aim"] = rng.randi_range(0, 2) if rng.randf() < 0.5 else TowerState.Aim.FIRST
				if no_aim(ctx, t["type"]):
					t["aim"] = TowerState.Aim.FIRST
		12:                                                 # change the gates
			var options: Array[Vector2i] = ctx["gate_options"]
			if int(ctx["gate_count"]) > 0 and not options.is_empty():
				var none: Array[Vector2i] = []
				s["gates"] = none if rng.randf() < 0.2 else _pick_gates(ctx, rng)
		13:                                                 # change the early call habit or when to buy
			if rng.randf() < 0.3:
				s["wave_buy"] = not bool(s["wave_buy"])
			else:
				var early: Dictionary = s["early"]
				var roll: float = rng.randf()
				if roll < 0.25:
					early["on"] = not bool(early["on"])
				elif roll < 0.5:
					early["from"] = rng.randi_range(1, 6)
				else:
					early["live"] = LIVE_CHOICES[rng.randi_range(0, LIVE_CHOICES.size() - 1)]


static func _last_index(seq: Array, tower: int) -> int:
	var at: int = -1
	for i: int in seq.size():
		if int(seq[i]) == tower:
			at = i
	return at


static func _tower_index(towers: Array, cell: Vector2i) -> int:
	for i: int in towers.size():
		if towers[i]["cell"] == cell:
			return i
	return -1


# Playing a strategy.

## Plays one battle to the end. Returns:
##   won, stars (bits), lives, cleared (waves), ticks, peak (most creatures on the map at once),
##   early (calls made), stuck (hit TICK_CAP), towers, max_tier, kinds (tower ids built),
##   gold_at (gold when each wave started), lives_at (lives when each wave started),
##   spent_at (gold put into towers before each wave started), wave_ticks (ticks each wave was
##   running), boss_hp (the lowest boss health seen, 0 when there is no boss or it was never seen),
##   boss_steps (the fewest road steps the boss had left to the base when last sampled, -1 for no boss).
## With timing, also step_us and step_live: the time of each tick and the creatures on the map.
## With restore_at, the battle is saved and loaded again at that tick (a mid-wave resume).
## With a `watch` Dictionary (empty by default), events stay on and the play fills it with what the report
## asks about (see `_watch_tick`): lives lost by creature type, and how far each flying boss got and with how
## much health. A watched play is the same play: it only reads.
static func play(ctx: Dictionary, strat: Dictionary, relaxed: bool, timing: bool = false, restore_at: int = -1, watch: Dictionary = {}) -> Dictionary:
	var level: LevelData = ctx["level"]
	var b: Battle = Battle.create(level, ctx["catalog"], relaxed, ctx["twist"])
	b.record_events = not watch.is_empty()
	for gate: Vector2i in strat["gates"]:
		b.place_gate(gate)
	var seq: Array = strat["seq"]
	var towers: Array = strat["towers"]
	var steps: Array[int] = []
	steps.resize(towers.size())
	steps.fill(0)
	var cursor: Array[int] = [0]
	var early: Dictionary = strat["early"]
	var early_on: bool = bool(early["on"])
	var early_from: int = int(early["from"])
	var early_live: int = int(early["live"])
	var early_max: int = int(early["max"])
	var wave_buy: bool = bool(strat["wave_buy"])
	var calls: int = 0
	var peak: int = 0
	var gold_at: Array[int] = []
	var lives_at: Array[int] = []
	var spent_at: Array[int] = []
	var wave_ticks: Array[int] = []
	var step_us: PackedInt32Array = PackedInt32Array()
	var step_live: PackedInt32Array = PackedInt32Array()
	var spent: Array[int] = [0]
	var boss_hp: int = 0
	var boss_steps: int = -1
	var boss_level: bool = ctx.get("boss", false)
	var boss_dist: PackedInt32Array = b.map.distances(b.closed_cells())
	var wave_count: int = b.wave_count()
	while b.phase == Battle.Phase.BUILD and b.tick < TICK_CAP:
		_buy(b, seq, towers, steps, cursor, spent)
		gold_at.append(b.gold)
		lives_at.append(b.lives)
		spent_at.append(spent[0])
		var started_at: int = b.tick
		if b.start_next_wave() != Battle.DONE:
			break
		wave_ticks.append(0)
		var wave_index: int = wave_ticks.size() - 1
		var first_tick: int = started_at
		while b.phase == Battle.Phase.WAVE and b.tick < TICK_CAP:
			if wave_buy and cursor[0] < seq.size() and b.tick % 4 == 0:
				_buy(b, seq, towers, steps, cursor, spent)
			if early_on and b.waves_started < wave_count and b.waves_started >= early_from \
					and calls < early_max and b.enemies.size() <= early_live and b.tick % 2 == 0:
				var before_gold: int = b.gold
				if b.start_next_wave() == Battle.DONE:
					calls += 1
					gold_at.append(before_gold)
					lives_at.append(b.lives)
					spent_at.append(spent[0])
					wave_ticks.append(0)
					wave_index = wave_ticks.size() - 1
					wave_ticks[wave_index - 1] = b.tick - first_tick
					first_tick = b.tick
			if b.tick == restore_at:
				# A saved game loaded again: the rest of the battle must play the same.
				var copy: Battle = Battle.from_data(b.to_data(), ctx["catalog"])
				if copy == null:
					return {"restore_failed": true, "won": false, "stars": 0, "lives": 0, "cleared": 0, "ticks": b.tick, "digest": 0, "stuck": true}
				b = copy
				b.record_events = not watch.is_empty()
			if timing:
				var t0: int = Time.get_ticks_usec()
				b.step()
				step_us.append(Time.get_ticks_usec() - t0)
				step_live.append(b.enemies.size())
			else:
				b.step()
			if not watch.is_empty():
				_watch_tick(b, ctx, watch)
			if b.enemies.size() > peak:
				peak = b.enemies.size()
			if boss_level and b.tick % 5 == 0:
				for enemy: EnemyState in b.enemies:
					if ctx["catalog"].enemy(enemy.type).boss:
						boss_hp = enemy.health if boss_hp == 0 else mini(boss_hp, enemy.health)
						var left: int = steps_left(b, boss_dist, enemy)
						boss_steps = left if boss_steps < 0 else mini(boss_steps, left)
		wave_ticks[wave_index] = b.tick - first_tick
	var out: Dictionary = b.result()
	out["lives"] = out["lives_left"]
	out["cleared"] = out["waves_cleared"]
	var kinds: Array[StringName] = []
	var max_tier: int = 0
	# What stands at the end: towers by id, and tier 3 paths by id (not what the strategy planned).
	var built: Dictionary = {}
	for tower: TowerState in b.towers:
		if not kinds.has(tower.type):
			kinds.append(tower.type)
		max_tier = maxi(max_tier, tower.tier)
		var key: String = String(tower.type)
		built[key] = int(built.get(key, 0)) + 1
		if tower.tier == 3:
			var path: String = String(ctx["catalog"].tower(tower.type).specs[tower.spec])
			built[path] = int(built.get(path, 0)) + 1
	out["built"] = built
	out["ticks"] = b.tick
	out["peak"] = peak
	out["early"] = calls
	out["stuck"] = b.phase == Battle.Phase.WAVE or b.phase == Battle.Phase.BUILD
	out["towers"] = b.towers.size()
	out["max_tier"] = max_tier
	out["kinds"] = kinds
	out["gold_at"] = gold_at
	out["lives_at"] = lives_at
	out["spent_at"] = spent_at
	out["wave_ticks"] = wave_ticks
	out["end_gold"] = b.gold
	out["boss_hp"] = boss_hp
	out["boss_steps"] = boss_steps
	out["digest"] = JSON.stringify(b.to_data()).hash()
	out["twist"] = bool(ctx["twist_on"])
	if timing:
		out["step_us"] = step_us
		out["step_live"] = step_live
	return out


## The events of the creature rules of regions 5 to 8 (ARCHITECTURE 14.6). A watched play counts them under `rule_events`.
const RULE_EVENTS: Array[StringName] = [&"napped", &"woke", &"burrowed", &"surfaced", &"blinked", &"yawned"]


## What a watched play records each tick. `watch["leaks"]`: lives lost, by creature type, and
## `watch["leaks_wave"]`: the same by the wave (1 based) the creature came from. `watch["kills"]`: creatures
## defeated, by type. `watch["bosses"]`: for each flying boss, its health when it was a quarter, a half and
## three quarters of the way along its line (-1 before), and where and how it ended. B6 adds `watch["shots"]` and
## `watch["hits"]` (shots fired and creatures hit, by tower id) and `watch["rule_events"]` (how often each creature rule of
## regions 5 to 8 fired: nap, wake, dig, surface, blink, yawn). `replay` reports them only where they say something new.
static func _watch_tick(b: Battle, ctx: Dictionary, watch: Dictionary) -> void:
	if not watch.has("leaks"):
		watch["leaks"] = {}
		watch["leaks_wave"] = {}
		watch["kills"] = {}
		watch["bosses"] = {}
		watch["wave_of"] = {}
		watch["shots"] = {}
		watch["hits"] = {}
		watch["rule_events"] = {}
	var catalog: Catalog = ctx["catalog"]
	var wave_of: Dictionary = watch["wave_of"]
	for enemy: EnemyState in b.enemies:
		if not wave_of.has(enemy.id):
			wave_of[enemy.id] = enemy.wave + 1
		if enemy.flying and catalog.enemy(enemy.type).boss and enemy.fly_length > 0:
			var bosses: Dictionary = watch["bosses"]
			if not bosses.has(enemy.id):
				bosses[enemy.id] = {"type": String(enemy.type), "wave": enemy.wave + 1, "max": enemy.max_health, "q1": -1, "half": -1, "q3": -1,
					"last_permille": 0, "last_health": enemy.health, "fate": "alive"}
			var row: Dictionary = bosses[enemy.id]
			var permille: int = enemy.flown * 1000 / enemy.fly_length
			row["last_permille"] = permille
			row["last_health"] = enemy.health
			if permille >= 250 and int(row["q1"]) < 0:
				row["q1"] = enemy.health
			if permille >= 500 and int(row["half"]) < 0:
				row["half"] = enemy.health
			if permille >= 750 and int(row["q3"]) < 0:
				row["q3"] = enemy.health
	for event: Dictionary in b.take_events():
		var kind: StringName = event["kind"]
		if kind == &"leaked":
			var type_key: String = String(event["enemy"])
			var lost: int = int(event["lives"])
			var leaks: Dictionary = watch["leaks"]
			leaks[type_key] = int(leaks.get(type_key, 0)) + lost
			var wave_key: String = str(int(wave_of.get(event["id"], 0)))
			var by_wave: Dictionary = watch["leaks_wave"]
			if not by_wave.has(wave_key):
				by_wave[wave_key] = {}
			by_wave[wave_key][type_key] = int(by_wave[wave_key].get(type_key, 0)) + lost
			if watch["bosses"].has(event["id"]):
				watch["bosses"][event["id"]]["fate"] = "reached the base"
		elif kind == &"fired":
			var tower_key: String = String(event["tower"])
			watch["shots"][tower_key] = int(watch["shots"].get(tower_key, 0)) + 1
			watch["hits"][tower_key] = int(watch["hits"].get(tower_key, 0)) + (event["targets"] as Array).size()
		elif RULE_EVENTS.has(kind):
			watch["rule_events"][String(kind)] = int(watch["rule_events"].get(String(kind), 0)) + 1
		elif kind == &"defeated":
			var kill_key: String = String(event["enemy"])
			watch["kills"][kill_key] = int(watch["kills"].get(kill_key, 0)) + 1
			if watch["bosses"].has(event["id"]):
				watch["bosses"][event["id"]]["fate"] = "defeated"


## Buys in the order of the strategy while gold lasts. A refusal other than too_poor skips the item.
static func _buy(b: Battle, seq: Array, towers: Array, steps: Array[int], cursor: Array[int], spent: Array[int]) -> void:
	while cursor[0] < seq.size():
		var index: int = seq[cursor[0]]
		var t: Dictionary = towers[index]
		var step: int = steps[index]
		var cell: Vector2i = t["cell"]
		var before: int = b.gold
		var refusal: StringName
		if step == 0:
			refusal = b.place_tower(cell, t["type"])
		elif step == 1:
			refusal = b.upgrade_tower(cell, -1)
		else:
			refusal = b.upgrade_tower(cell, int(t["spec"]))
		if refusal == &"too_poor":
			return
		steps[index] = step + 1
		cursor[0] += 1
		if refusal == Battle.DONE:
			spent[0] += before - b.gold
			if step == 0 and int(t["aim"]) != TowerState.Aim.FIRST:
				b.set_aim(cell, int(t["aim"]) as TowerState.Aim)


# The plain mixed recipe (RULES 12.6).

## The order the recipe takes the attacking towers in, one per spot (RULES 12.6 step 4). The Firework Tower and the Moth Lantern
## are in the turn only on a level whose waves bring flyers.
const ATTACK_ORDER: Array[StringName] = [&"sling_post", &"pumpkin_catapult", &"longbow_loft", &"bramble_cottage", &"snow_fort",
	&"firework_tower", &"moth_lantern"]
## The four towers of regions 5 to 8.
const EXPANSION_TOWERS: Array[StringName] = [&"bramble_cottage", &"scarecrow", &"snow_fort", &"moth_lantern"]
## Towers that can only hit flyers, and so join the turn only on a level with flyers.
const FLYER_ONLY: Array[StringName] = [&"firework_tower", &"moth_lantern"]


## The plain mixed recipe as a strategy with no gates, no early calls and no buying during waves.
## It has no randomness. Steps are RULES 12.6's, numbered as there.
static func plain_recipe(ctx: Dictionary) -> Dictionary:
	var level: LevelData = ctx["level"]
	var catalog: Catalog = ctx["catalog"]
	var offered: Array[StringName] = ctx["offered"]
	var seen: Array[int] = ctx["road_seen"]
	# 1. Spot order: the most road seen first, ties in cell order (the order of level.spots).
	var keyed: Array = []
	for i: int in level.spots.size():
		keyed.append([-seen[i], i])
	keyed.sort()
	var ranked: Array[Vector2i] = []
	for item: Array in keyed:
		ranked.append(level.spots[int(item[1])])
	# 2. The Bakery: the spot with the most other spots among its 8 neighbors, at least 2.
	var bakery_at: int = -1
	if offered.has(&"bakery"):
		var most: int = 1
		for r: int in ranked.size():
			var near: int = 0
			for other: Vector2i in ranked:
				if other != ranked[r] and absi(other.x - ranked[r].x) <= 1 and absi(other.y - ranked[r].y) <= 1:
					near += 1
			if near > most:
				most = near
				bakery_at = r
	# 3. The Lullaby Bell: the third spot, or the fourth when the Bakery has the third.
	var bell_at: int = -1
	if offered.has(&"lullaby_bell"):
		var want: int = 3 if bakery_at == 2 else 2
		if want < ranked.size():
			bell_at = want
	# 3. The Scarecrow: the fifth spot, or the sixth when the Bakery has the fifth.
	var scarecrow_at: int = -1
	if offered.has(&"scarecrow"):
		var scare_want: int = 5 if bakery_at == 4 else 4
		if scare_want < ranked.size():
			scarecrow_at = scare_want
	# 4. The other spots take the attacking towers in turn.
	var attackers: Array[StringName] = []
	for id: StringName in ATTACK_ORDER:
		if offered.has(id) and (not FLYER_ONLY.has(id) or bool(ctx["flyers"])):
			attackers.append(id)
	if attackers.is_empty():
		for id: StringName in offered:
			if catalog.tower(id).kind == &"attack":
				attackers.append(id)
	var towers: Array = []
	var turn: int = 0
	var grown: Array[int] = []                              # indexes of the attacking towers
	for r: int in ranked.size():
		var type: StringName
		var depth: int = 1
		if r == bakery_at:
			type = &"bakery"
		elif r == bell_at:
			type = &"lullaby_bell"
		elif r == scarecrow_at:
			type = &"scarecrow"
		else:
			type = attackers[turn % attackers.size()]
			turn += 1
			# 5. From region 2 on, attackers go on to tier 3, on their first path.
			depth = 2 if int(ctx["region"]) >= 2 else 1
			grown.append(r)
		towers.append({"cell": ranked[r], "type": type, "depth": depth, "spec": 0, "aim": TowerState.Aim.FIRST})
	# 5. Buying: every build, then every tier 2, then the tier 3 steps. The Bakery is last in the first two.
	var seq: Array = []
	for _pass: int in 2:
		for r: int in ranked.size():
			if r != bakery_at:
				seq.append(r)
		if bakery_at >= 0:
			seq.append(bakery_at)
	if int(ctx["region"]) >= 2:
		for r: int in grown:
			seq.append(r)
	var none: Array[Vector2i] = []
	return {"towers": towers, "seq": seq, "gates": none, "early": {"on": false, "from": 1, "live": 0, "max": 99}, "wave_buy": false}


## The strategy with no tower above `top` (1 to 3): the upgrade steps above it are dropped. The plain recipe
## with top 2 is the "tier 2 only" variant of the Dusk Moth question (report, 3-4).
static func cap_tier(strat: Dictionary, top: int) -> Dictionary:
	var out: Dictionary = strat.duplicate(true)
	var steps: Array[int] = []
	steps.resize(out["towers"].size())
	steps.fill(0)
	var seq: Array = []
	for index: int in out["seq"]:
		steps[index] += 1
		if steps[index] <= top:
			seq.append(index)
	out["seq"] = seq
	for t: Dictionary in out["towers"]:
		t["depth"] = mini(int(t["depth"]), top - 1)
	return out


## Every placement of up to the gates in hand that seals no entrance, the empty one first, then by
## size, then in socket order (RULES 12.6 step 7). Each is an Array[Vector2i].
static func placements(ctx: Dictionary) -> Array:
	var options: Array[Vector2i] = ctx["gate_options"]
	var map: RoadMap = ctx["map"]
	var fixed: Array[Vector2i] = ctx["fixed"]
	var none: Array[Vector2i] = []
	var out: Array = [none]
	for size: int in range(1, mini(int(ctx["gate_count"]), options.size()) + 1):
		var picks: Array = []
		_choose_gates(options, size, 0, [], picks)
		for pick: Array in picks:
			var cells: Array[Vector2i] = []
			for at: int in pick:
				cells.append(options[at])
			var shut: Array[Vector2i] = fixed.duplicate()
			shut.append_array(cells)
			if not map.seals(shut):
				out.append(cells)
	return out


static func _choose_gates(options: Array[Vector2i], size: int, from: int, cur: Array, out: Array) -> void:
	if cur.size() == size:
		out.append(cur.duplicate())
		return
	for i: int in range(from, options.size()):
		cur.append(i)
		_choose_gates(options, size, i + 1, cur, out)
		cur.pop_back()


## "none", "3,3" or "3,3+5,6".
static func gates_label(gates: Array) -> String:
	if gates.is_empty():
		return "none"
	var parts: PackedStringArray = PackedStringArray()
	for gate: Vector2i in gates:
		parts.append("%d,%d" % [gate.x, gate.y])
	return "+".join(parts)


## A gate list of one socket, or none for NO_CELL.
static func one_gate(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	if cell != NO_CELL:
		out.append(cell)
	return out


## Creatures in each wave with the Twist and strength applied, a Puffball counted with its Puffs
## (RULES 12.5). Boss summons and releases are not counted: `play` measures the real peak.
static func wave_sizes(ctx: Dictionary) -> Array[int]:
	var b: Battle = Battle.create(ctx["level"], ctx["catalog"], false, ctx["twist"])
	var out: Array[int] = []
	for w: int in b.wave_count():
		var total: int = 0
		for row: Dictionary in b.wave_preview(w):
			var type: EnemyType = ctx["catalog"].enemy(row["enemy"])
			total += int(row["count"]) * (1 + type.split_count)
		out.append(total)
	return out


# Describing and saving strategies.

## The strategy as plain JSON values.
static func to_data(strat: Dictionary) -> Dictionary:
	var towers: Array = []
	for t: Dictionary in strat["towers"]:
		var cell: Vector2i = t["cell"]
		towers.append({"cell": [cell.x, cell.y], "type": String(t["type"]), "depth": t["depth"], "spec": t["spec"], "aim": t["aim"]})
	# "gate" is the first gate, [-1, -1] for none, as in the files before the B1 bots, so the files of
	# a level with one gate keep their old shape. More gates go in "more_gates".
	var gates: Array = strat["gates"]
	var first: Vector2i = NO_CELL if gates.is_empty() else gates[0]
	var out: Dictionary = {"towers": towers, "seq": strat["seq"].duplicate(), "gate": [first.x, first.y],
		"early": strat["early"].duplicate(), "wave_buy": strat["wave_buy"]}
	if gates.size() > 1:
		var more: Array = []
		for i: int in range(1, gates.size()):
			more.append([gates[i].x, gates[i].y])
		out["more_gates"] = more
	return out


static func from_data(data: Dictionary) -> Dictionary:
	var towers: Array = []
	for item: Dictionary in data["towers"]:
		var cell: Array = item["cell"]
		towers.append({"cell": Vector2i(int(cell[0]), int(cell[1])), "type": StringName(item["type"]),
			"depth": int(item["depth"]), "spec": int(item["spec"]), "aim": int(item["aim"])})
	var seq: Array = []
	for item: Variant in data["seq"]:
		seq.append(int(item))
	var gates: Array[Vector2i] = []
	var gate: Array = data["gate"]
	if int(gate[0]) >= 0:
		gates.append(Vector2i(int(gate[0]), int(gate[1])))
	if data.has("more_gates"):
		for item: Array in data["more_gates"]:
			gates.append(Vector2i(int(item[0]), int(item[1])))
	var early_in: Dictionary = data["early"]
	var early: Dictionary = {"on": bool(early_in["on"]), "from": int(early_in["from"]), "live": int(early_in["live"]), "max": int(early_in["max"])}
	return {"towers": towers, "seq": seq, "gates": gates, "early": early, "wave_buy": bool(data["wave_buy"])}


## A key that is the same for two strategies that play the same.
static func signature(strat: Dictionary) -> String:
	return JSON.stringify(to_data(strat))


## What a strategy builds at the end: tower ids and tier 3 paths, counted.
static func inventory(ctx: Dictionary, strat: Dictionary) -> Dictionary:
	var catalog: Catalog = ctx["catalog"]
	var out: Dictionary = {}
	for t: Dictionary in strat["towers"]:
		var key: String = String(t["type"])
		out[key] = int(out.get(key, 0)) + 1
		if int(t["depth"]) == 2:
			var path: String = String(catalog.tower(t["type"]).specs[int(t["spec"])])
			out[path] = int(out.get(path, 0)) + 1
	return out


## True when the level's grid holds a map feature character (T, X, P, Q or a slide arrow).
static func has_features(level: LevelData) -> bool:
	for line: String in level.grid:
		for ch: String in "TX^v<>PQ":
			if line.contains(ch):
				return true
	return false


## The letters that mark the spots in a description, and the mark for a gate. On a map with no feature they are the old ones, A to X
## and X. A map with features uses letters that are no grid character (A, C to F, H to O, R, S, U to W, Y, Z, then a to d), and
## `*` for a gate, because X is a bridge there.
static func spot_letters(level: LevelData) -> String:
	return "ACDEFHIJKLMNORSUVWYZabcd" if has_features(level) else "ABCDEFGHIJKLMNOPQRSTUVWX"


static func gate_mark(level: LevelData) -> String:
	return "*" if has_features(level) else "X"


## Plain text for a report: a map with the spots lettered, then the buying order.
static func describe(ctx: Dictionary, strat: Dictionary) -> String:
	var level: LevelData = ctx["level"]
	var catalog: Catalog = ctx["catalog"]
	var letters: String = spot_letters(level)
	var mark: String = gate_mark(level)
	var lines: PackedStringArray = PackedStringArray()
	var gates: Array = strat["gates"]
	for r: int in level.rows:
		var row: String = ""
		for c: int in Sim.MAP_COLUMNS:
			var cell: Vector2i = Vector2i(c, r)
			var ch: String = level.grid[r][c]
			if level.kind_at(cell) == LevelData.Kind.SPOT:
				ch = letters[level.spots.find(cell)]
			elif gates.has(cell):
				ch = mark
			row += ch
		lines.append(row)
	var text: String = "\n".join(lines) + "\n"
	if gates.is_empty():
		text += "Gate: none\n"
	elif gates.size() == 1:
		text += "Gate: socket (%d,%d) shown as %s\n" % [gates[0].x, gates[0].y, mark]
	else:
		var cells: PackedStringArray = PackedStringArray()
		for gate: Vector2i in gates:
			cells.append("(%d,%d)" % [gate.x, gate.y])
		text += "Gates: sockets %s shown as %s\n" % [", ".join(cells), mark]
	var steps: Array[int] = []
	steps.resize(strat["towers"].size())
	steps.fill(0)
	var n: int = 0
	for index: int in strat["seq"]:
		var t: Dictionary = strat["towers"][index]
		var spot: String = letters[level.spots.find(t["cell"])]
		var type: TowerType = catalog.tower(t["type"])
		var step: int = steps[index]
		steps[index] += 1
		n += 1
		var what: String = "build %s" % type.name
		if step == 1:
			what = "upgrade %s to tier 2" % type.name
		elif step == 2:
			what = "upgrade %s to %s" % [type.name, type.spec_name(int(t["spec"]))]
		var aim: String = ""
		if step == 0 and int(t["aim"]) != TowerState.Aim.FIRST and type.kind == &"attack":
			aim = ", aim %s" % ["first", "last", "strong"][int(t["aim"])]
		text += "%d. spot %s: %s%s\n" % [n, spot, what, aim]
	var early: Dictionary = strat["early"]
	if bool(early["on"]):
		text += "Early calls: from wave %d on, when at most %d creatures are on the map.\n" % [int(early["from"]) + 1, int(early["live"])]
	else:
		text += "Early calls: none.\n"
	text += "Buys %s.\n" % ("during waves as gold comes in, and in build phases" if bool(strat["wave_buy"]) else "only in build phases")
	return text


## Fitness for the search: a win beats everything, then stars, then lives. A loss scores by waves cleared.
static func fitness(res: Dictionary) -> int:
	var stars: int = int(res["stars"])
	if bool(res["won"]) and bool(res.get("twist", false)):
		return 10000 + int(res["lives"])                    # a Twist has no stars
	if bool(res["won"]):
		return 10000 + (1000 if (stars & 2) != 0 else 0) + (3000 if (stars & 4) != 0 else 0) + int(res["lives"])
	return int(res["cleared"]) * 100 + int(res["lives"])
