class_name Measures
extends RefCounted
## Measures of play, read from a fought battle's trace: what DESIGN.md's
## "Play over time" asks of each time horizon. Pure functions of a run.

## A side is behind when the lead is this far against it.
const BEHIND := 0.15
## How far after an order its effect is first read, for persistence.
const SOON := 20.0


## Seconds into the battle of the first clash, or -1 if none came.
static func first_clash(run: BattleRun) -> float:
	for s in run.trace.samples:
		if s.engaged[0] + s.engaged[1] > 0:
			return s.t
	return -1.0


## The longest stretch after the first clash with no block engaged and
## nothing fired, in seconds.
static func quiet_max(run: BattleRun) -> float:
	var start := first_clash(run)
	if start < 0.0:
		return 0.0
	var longest := 0.0
	var since := -1.0
	for s in run.trace.samples:
		if s.t < start:
			continue
		var fire := 0
		for type in ["volley", "musket", "boom", "charge"]:
			fire += s.counts[type][0] + s.counts[type][1]
		var quiet: bool = s.engaged[0] + s.engaged[1] == 0 and fire == 0
		if quiet and since < 0.0:
			since = s.t
		elif not quiet and since >= 0.0:
			longest = maxf(longest, s.t - since)
			since = -1.0
	if since >= 0.0:
		longest = maxf(longest, run.trace.samples.back().t - since)
	return longest


## Whether the winner was behind by BEHIND at some point after the first
## clash.
static func comeback(run: BattleRun) -> bool:
	var w := run.battle.winner
	var start := first_clash(run)
	if w < 0 or start < 0.0:
		return false
	for s in run.trace.samples:
		if s.t >= start and (s.lead < -BEHIND if w == 0 else s.lead > BEHIND):
			return true
	return false


## The warning the side `team` had before each blow it took: the median of
## the announced ones, and the share that came unannounced.
static func warning(run: BattleRun, team: int) -> Dictionary:
	var blows: Array = run.trace.blows[team]
	var announced := blows.filter(func(w): return w >= 0.0)
	announced.sort()
	return {
		"median": announced[announced.size() / 2] if not announced.is_empty() else -1.0,
		"unannounced": 0.0 if blows.is_empty() else 1.0 - float(announced.size()) / blows.size(),
		"blows": blows.size(),
	}


static func orders_per_minute(run: BattleRun, team: int) -> float:
	var n := 0
	for s in run.trace.samples:
		n += s.orders[team]
	return n * 60.0 / maxf(run.battle.time, 1.0)


static func margin(b: Battle) -> float:
	return b.resolve[0] - b.resolve[1]


## The lead at battle time `t` (the last sample at or before it).
static func lead_at(run: BattleRun, t: float) -> float:
	var value := 0.0
	for s in run.trace.samples:
		if s.t > t:
			break
		value = s.lead
	return value


## Sensitivity: take `count` of the player's orders out of a logged run
## one at a time, fight each battle again with every other order as it was,
## and compare. The later orders were made for the battle as it went, so
## this measures how far one small change carries (a game whose outcome
## flips on any small change plays like dice), not what a better decision
## is worth; that takes comparing plans. For each: the
## change in the final margin, whether the winner changed, and the change
## in the lead SOON seconds after the order and at the end. `make` builds
## the battle as it was before its first order; `make_seats` its seats.
static func impact(played: BattleRun, make: Callable, make_seats: Callable, count: int, seed_value: int) -> Array:
	var picks: Array = []
	for j in played.log.size():
		for k in played.log[j].orders.size():
			picks.append([j, k])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out: Array = []
	for n in mini(count, picks.size()):
		var pick: Array = picks.pop_at(rng.randi() % picks.size())
		var changed := played.log.duplicate(true)
		var entry: Dictionary = changed[pick[0]]
		var removed: Dictionary = entry.orders.pop_at(pick[1])
		var at: float = entry.tick * Battle.STEP
		var again := BattleRun.replay(make, make_seats, changed, Fights.length(played.battle))
		var end := played.battle.time
		out.append({
			"type": removed.type, "at": snappedf(at, 0.1),
			"margin": margin(again.battle) - margin(played.battle),
			"flip": again.battle.winner != played.battle.winner,
			"soon": lead_at(again, at + SOON) - lead_at(played, at + SOON),
			"end": lead_at(again, end) - lead_at(played, end),
		})
	return out
