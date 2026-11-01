# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## A small seeded player for tests/run/. It picks cards, builds towers and gates, starts
## waves and, if asked, calls waves early, all from its own generator, so two players with
## the same seed make the same moves. It makes no promise to play well.

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")
## The risk cards of the fixtures.
const RISKY: PackedStringArray = ["crowded_night", "flock", "pip_parade"]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var early_one_in: int = 0
## True: never picks a risk card while another card is offered.
var safe: bool = false
## True: the player has plenty of gold and lives in every build phase, so a fixture run can be won.
var rich: bool = false
var ticks: int = 0
## What happened, for tests: calls the session refused with draft_waiting, early calls made.
var waits: int = 0
var early_calls: int = 0
## Drafts that opened for a wave up to 16 after wave 17 had started, and risk cards offered once wave 17 had started.
var late_drafts: int = 0
var risky_late: int = 0
var refusals: Array[StringName] = []


func _init(seed_value: int = 1, early_chance: int = 0, play_safe: bool = false) -> void:
	rng.seed = seed_value
	early_one_in = early_chance
	safe = play_safe


## A player in the same state: same generator position, same counters.
func fork() -> RefCounted:
	var other: RefCounted = get_script().new(1, early_one_in, safe)
	other.rng.seed = rng.seed
	other.rng.state = rng.state
	other.ticks = ticks
	other.waits = waits
	other.early_calls = early_calls
	other.late_drafts = late_drafts
	other.risky_late = risky_late
	other.rich = rich
	return other


## A session on the fixture data and the real stats: the base cards as the pool, or every
## card, a Normal run or a daily.
static func session(run_seed: int, relaxed: bool = false, day: String = "", every_card: bool = false) -> RunSession:
	var data: RunData = Fx.run_data()
	var pool: Array[StringName] = data.card_ids() if every_card else data.pool({})
	return RunSession.start(run_seed, day, relaxed, pool, data, Fx.catalog())


## One step of play: a whole build phase and the start of the next wave, or one tick of a
## wave (with a small chance of an early call). False once the battle is over.
func advance(s: RunSession) -> bool:
	var b: Battle = s.battle
	if b.phase == Battle.Phase.WON or b.phase == Battle.Phase.LOST:
		return false
	if b.phase == Battle.Phase.BUILD:
		build_phase(s)
		_note(s.start_next_wave())
		return true
	b.step()
	ticks += 1
	if early_one_in > 0 and rng.randi_range(1, early_one_in) == 1:
		var answer: StringName = s.start_next_wave()
		if answer == Battle.DONE:
			early_calls += 1
		else:
			_note(answer)
	return true


## Plays until the battle is over or the tick limit is reached. True when it is over.
func play(s: RunSession, tick_limit: int = 400000) -> bool:
	while advance(s):
		if ticks > tick_limit:
			return false
	return true


## Picks every owed card, places the gates in hand and spends the gold.
func build_phase(s: RunSession) -> void:
	var b: Battle = s.battle
	if rich:
		b.gold = maxi(b.gold, 20000)
		b.lives = maxi(b.lives, 500)
	while s.draft_open():
		var offered: Array[StringName] = s.offers()
		if b.waves_started >= 17:
			if s.picks.size() + 1 <= 16:
				late_drafts += 1
			for id: StringName in offered:
				if RISKY.has(String(id)):
					risky_late += 1
		if safe:
			var calm: Array[StringName] = []
			for id: StringName in offered:
				if not RISKY.has(String(id)):
					calm.append(id)
			if not calm.is_empty():
				offered = calm
		_note(s.pick(offered[rng.randi_range(0, offered.size() - 1)]))
	for cell: Vector2i in b.level.sockets:
		if b.gates_in_hand > 0:
			b.place_gate(cell)
	var spots: Array[Vector2i] = _spots_by_closeness(b.level)
	# New towers first, then upgrades with what is left.
	for cell: Vector2i in spots:
		if b.tower_at(cell) == null:
			var choices: Array[StringName] = []
			for option: Dictionary in b.build_options(cell):
				if option["affordable"]:
					choices.append(option["tower"])
			if not choices.is_empty():
				b.place_tower(cell, choices[rng.randi_range(0, choices.size() - 1)])
	for cell: Vector2i in spots:
		if b.tower_at(cell) != null:
			for option: Dictionary in b.upgrade_options(cell):
				if option["refusal"] == &"":
					b.upgrade_tower(cell, int(option["spec"]))
					break


## Everything that must match after equal play: the battle, the run and the result.
static func fingerprint(s: RunSession) -> String:
	return JSON.stringify(s.battle.to_data(), "", true) + JSON.stringify(s.to_data(), "", true) + str(s.result())


func _note(answer: StringName) -> void:
	if answer == &"draft_waiting":
		waits += 1
	if answer != Battle.DONE:
		refusals.append(answer)


## The build spots, nearest to a road first (then lower on the map first), so towers
## cover the road. Ties keep the map's own order.
func _spots_by_closeness(level: LevelData) -> Array[Vector2i]:
	var roads: Array[Vector2i] = []
	for row: int in level.rows:
		for column: int in Sim.MAP_COLUMNS:
			var kind: LevelData.Kind = level.kind_at(Vector2i(column, row))
			if kind != LevelData.Kind.SCENERY and kind != LevelData.Kind.SPOT:
				roads.append(Vector2i(column, row))
	var keyed: Array[Vector3i] = []
	for i: int in level.spots.size():
		var nearest: int = 1000
		for road: Vector2i in roads:
			nearest = mini(nearest, absi(road.x - level.spots[i].x) + absi(road.y - level.spots[i].y))
		keyed.append(Vector3i(nearest, -level.spots[i].y, i))
	keyed.sort()
	var out: Array[Vector2i] = []
	for key: Vector3i in keyed:
		out.append(level.spots[key.z])
	return out
