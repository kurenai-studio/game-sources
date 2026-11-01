# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Load ceilings on a saved battle as a whole (docs/ARCHITECTURE.md 5.6): the crowd of
## creatures with what they can let out, the creatures that summon and that heal over
## the waves on the map at once, and the seal check on every placed gate. The tampered
## saves of the security reviews of 2026-10-25 (L1, L2, and round 2's L5, L6, N7, N8) are
## refused, and real play at its worst moments still loads.

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")
const LIMIT: int = 60000

var game: GameData = null
var store: SaveStore = null


func before_each() -> void:
	Fx.fresh()
	game = Fx.game()
	store = SaveStore.new(Fx.WORK)


func after_each() -> void:
	store = null
	Fx.clean()


## The review's start: r1_l2, one tower, some ticks into wave 1, as a file brings it back.
func _level_save(ticks: int) -> Dictionary:
	var battle: Battle = Fx.battle_mid_wave(game, &"r1_l2", false, ticks)
	assert_eq(battle.phase, Battle.Phase.WAVE)
	return Fx.through_json(Fx.saved(SavedGame.LEVEL, battle).to_data())


func _loads(data: Dictionary) -> bool:
	return SavedGame.from_data(Fx.through_json(data), game) != null


## A release at entrance 1 that starts on the saved tick.
func _release(battle: Dictionary, enemy: String, left: int) -> Dictionary:
	var entrance: Array = DataCheck.cell_data(game.levels[&"r1_l2"].entrances[0])
	return {"enemy": enemy, "wave": battle["running"][0], "left": left, "next": battle["tick"], "gap": 1,
		"from": entrance, "to": entrance.duplicate(), "progress": Sim.UNIT}


## Adds count Grumblesacks, copies of the first creature, with new ids.
func _add_bosses(battle: Dictionary, count: int) -> void:
	_add(battle, "grumblesack", count, 2000, 2000)


## Adds count walkers of a type, copies of the first creature (a Scamp) on its road
## step, with new ids and timers that fit the type.
func _add(battle: Dictionary, type: String, count: int, health: int, max_health: int) -> void:
	var model: Dictionary = battle["enemies"][0]
	var data: EnemyType = game.catalog.enemy(StringName(type))
	for i: int in count:
		var enemy: Dictionary = model.duplicate(true)
		enemy["id"] = int(battle["next_id"])
		battle["next_id"] = int(battle["next_id"]) + 1
		enemy["type"] = type
		enemy["max_health"] = max_health
		enemy["health"] = health
		enemy["summon_at"] = int(battle["tick"]) + 1 if not data.summon.is_empty() else 0
		enemy["heal_at"] = int(battle["tick"]) if data.heal > 0 else 0
		(battle["enemies"] as Array).append(enemy)


## Keeps only the first live creature, so a test can fill the map from scratch.
func _only_first(battle: Dictionary) -> void:
	var model: Dictionary = battle["enemies"][0]
	battle["enemies"] = [model]
	battle["next_id"] = int(model["id"]) + 1


## The live creatures of a save, each with what it can still let out (N7): a Puffball
## as 4, an Old Tusk that has not released as 5.
func _crowd(battle: Dictionary) -> int:
	var total: int = 0
	for enemy: Dictionary in battle["enemies"]:
		var data: EnemyType = game.catalog.enemy(StringName(String(enemy["type"])))
		total += 1 + data.split_count
		if not data.release.is_empty() and not enemy["released"]:
			total += int(data.release["count"])
	return total


# L1: the crowd as a whole.

func test_review_l1_a_thousand_full_releases_are_refused() -> void:
	var data: Dictionary = _level_save(20)
	var battle: Dictionary = data["battle"]
	var list: Array = []
	for i: int in Battle.MAX_RELEASES:
		list.append(_release(battle, "scamp", 200))
	battle["releases"] = list
	battle["lives"] = Battle.MAX_LIVES
	battle["start_lives"] = Battle.MAX_LIVES
	Fx.write_text("game_level.json", JSON.stringify(data))
	assert_true(store.load_games(game).is_empty(), "the tampered save is refused")
	assert_false(Fx.exists("game_level.json"), "and deleted")


func test_live_creatures_and_creatures_to_come_stop_at_max_enemies() -> void:
	var data: Dictionary = _level_save(60)
	var battle: Dictionary = data["battle"]
	var live: int = (battle["enemies"] as Array).size()
	assert_true(live >= 1, "creatures on the map: %d" % live)
	var room: int = Battle.MAX_ENEMIES - live
	var list: Array = []
	while room > 0:
		list.append(_release(battle, "scamp", mini(room, 200)))
		room -= mini(room, 200)
	battle["releases"] = list
	assert_true(_loads(data), "exactly %d in all loads" % Battle.MAX_ENEMIES)
	list.append(_release(battle, "puff", 1))
	assert_false(_loads(data), "one more is refused")


func test_review_l1_a_swarm_of_summoners_is_refused() -> void:
	var data: Dictionary = _level_save(60)
	_add_bosses(data["battle"], 200)
	assert_false(_loads(data), "200 Grumblesacks")


func test_at_most_max_summoners_creatures_summon() -> void:
	var data: Dictionary = _level_save(60)
	var battle: Dictionary = data["battle"]
	_add_bosses(battle, Battle.MAX_SUMMONERS)
	assert_true(_loads(data), "%d Grumblesacks load" % Battle.MAX_SUMMONERS)
	var more: Dictionary = data.duplicate(true)
	_add_bosses(more["battle"], 1)
	assert_false(_loads(more), "one more is refused")
	var released: Dictionary = data.duplicate(true)
	released["battle"]["releases"] = [_release(released["battle"], "grumblesack", 1)]
	assert_false(_loads(released), "a summoner still to come from a release counts too")
	(released["battle"]["enemies"] as Array).pop_back()
	assert_true(_loads(released), "and with one fewer on the map it loads")


# L2: the seal check in a wave.

## The review's L2 save: r1_l2 right after wave 1 starts, two gates given, the gates in
## the given sockets and none in hand.
func _gated_wave(cells: Array[Vector2i]) -> Dictionary:
	var data: Dictionary = _level_save(0)
	var battle: Dictionary = data["battle"]
	assert_true((battle["enemies"] as Array).is_empty(), "no creature has spawned")
	battle["level"]["gates"] = 2
	var list: Array = []
	for cell: Vector2i in cells:
		list.append({"cell": DataCheck.cell_data(cell), "fixed": false, "broken": false})
	battle["gates"] = list
	battle["gates_in_hand"] = 2 - cells.size()
	return data


func test_review_l2_a_wave_save_that_seals_every_road_is_refused() -> void:
	var level: LevelData = game.levels[&"r1_l2"]
	var both: Array[Vector2i] = level.sockets.duplicate()
	assert_eq(both.size(), 2)
	assert_true(RoadMap.new(level).seals(both), "both gates seal r1_l2")
	assert_false(_loads(_gated_wave(both)), "the sealing wave save is refused")
	Fx.write_text("game_level.json", JSON.stringify(_gated_wave(both)))
	assert_true(store.load_games(game).is_empty(), "through the store too")
	assert_false(Fx.exists("game_level.json"))
	assert_true(_loads(_gated_wave([both[0]])), "one gate loads")
	assert_true(_loads(_gated_wave([both[1]])), "the other gate loads")


# L6: the seal check on every placed gate, broken or not, whatever gates_open says.

func test_review_l6_a_broken_gate_still_counts_in_the_seal_check() -> void:
	var both: Array[Vector2i] = game.levels[&"r1_l2"].sockets.duplicate()
	var broken: Dictionary = _gated_wave(both)
	broken["battle"]["gates"][1]["broken"] = true
	assert_false(_loads(broken), "it mends, closed, when the next build phase begins")
	Fx.write_text("game_level.json", JSON.stringify(broken))
	assert_true(store.load_games(game).is_empty(), "through the store too")
	assert_false(Fx.exists("game_level.json"), "and deleted")
	var both_broken: Dictionary = _gated_wave(both)
	both_broken["battle"]["gates"][0]["broken"] = true
	both_broken["battle"]["gates"][1]["broken"] = true
	assert_false(_loads(both_broken), "every gate broken")
	var one: Dictionary = _gated_wave([both[0]])
	one["battle"]["gates"][0]["broken"] = true
	assert_true(_loads(one), "a broken gate that does not seal loads, as in play")


func test_review_l6_gates_open_still_counts_in_the_seal_check() -> void:
	var both: Array[Vector2i] = game.levels[&"r1_l2"].sockets.duplicate()
	# gates_open comes only from a risk card, which a campaign save cannot hold, so
	# these are checked on the battle alone.
	var open: Dictionary = _gated_wave(both)["battle"]
	open["gates_open"] = true
	assert_null(Battle.from_data(Fx.through_json(open), game.catalog), "the gates close again next build phase")
	var one: Dictionary = _gated_wave([both[0]])["battle"]
	one["gates_open"] = true
	assert_not_null(Battle.from_data(Fx.through_json(one), game.catalog), "gates that do not seal load, as in play")


## The review's run steps: Iron Gate picked, so placed gates are fixed, then fixed gates
## on a set of sockets that seals the run map, in a wave, one of them broken; or none
## broken and gates_open, with no Gateless Night among the picks.
func test_review_l6_a_run_wave_save_with_sealing_fixed_gates_is_refused() -> void:
	var session: RunSession = null
	var sealing: Array[Vector2i] = []
	for run_seed: int in range(1, 60):
		session = Fx.run_with(game, run_seed,
			func(_s: RunSession, offers: Array[StringName]) -> StringName: return &"iron_gate" if offers.has(&"iron_gate") else &"",
			func(at: RunSession) -> bool: return at.picks.has(&"iron_gate") and not at.draft_open() and at.battle.phase == Battle.Phase.BUILD)
		if session != null:
			sealing = _sealing_set(session.battle)
			if sealing.size() >= 2:
				break
	assert_true(sealing.size() >= 2, "a run with Iron Gate on a map with a sealing set of 2 or more sockets: %s" % str(sealing))
	if sealing.size() < 2:
		return
	var battle: Battle = session.battle
	assert_eq(session.start_next_wave(), Battle.DONE)
	for i: int in 20:
		battle.step()
	assert_eq(battle.phase, Battle.Phase.WAVE)
	var data: Dictionary = Fx.through_json(Fx.saved_run(session).to_data())
	assert_not_null(SavedGame.from_data(Fx.through_json(data), game), "the run loads before the change")
	var total: int = int(data["battle"]["gates_in_hand"]) + (data["battle"]["gates"] as Array).size()
	var list: Array = []
	for cell: Vector2i in sealing:
		list.append({"cell": DataCheck.cell_data(cell), "fixed": true, "broken": false})
	data["battle"]["gates"] = list
	data["battle"]["gates_in_hand"] = total - list.size()
	list[0]["broken"] = true
	assert_null(SavedGame.from_data(Fx.through_json(data), game), "one of them broken")
	list[0]["broken"] = false
	data["battle"]["gates_open"] = true
	assert_null(SavedGame.from_data(Fx.through_json(data), game), "gates_open")
	list.pop_back()
	data["battle"]["gates_in_hand"] = total - list.size()
	assert_not_null(SavedGame.from_data(Fx.through_json(data), game), "one gate fewer does not seal, and loads")


## The smallest set of sockets, in cell order, that seals the battle's map, using at
## most the battle's gates, placed and in hand. Empty when none does.
func _sealing_set(battle: Battle) -> Array[Vector2i]:
	var sockets: Array[Vector2i] = battle.level.sockets
	for size: int in range(1, mini(battle.gates_in_hand + battle.gates.size(), sockets.size()) + 1):
		for mask: int in 1 << sockets.size():
			var cells: Array[Vector2i] = []
			for i: int in sockets.size():
				if mask & (1 << i) != 0:
					cells.append(sockets[i])
			if cells.size() == size and battle.seals(cells):
				return cells
	return []


# L5: creatures that heal.

func test_review_l5_four_thousand_menders_are_refused() -> void:
	var data: Dictionary = _level_save(1)
	var battle: Dictionary = data["battle"]
	_only_first(battle)
	# Keys that are optional on load since A12 (docs/ARCHITECTURE.md 14.7) are left out, so
	# 4,000 creatures still fit under the file cap and the creature ceiling is what refuses them.
	for key: String in Battle.ENEMY_OPTIONAL:
		(battle["enemies"][0] as Dictionary).erase(key)
	_add(battle, "mender", Battle.MAX_ENEMIES - 1, 1, 1000000000)
	battle["lives"] = Battle.MAX_LIVES
	battle["start_lives"] = Battle.MAX_LIVES
	var text: String = JSON.stringify(data)
	assert_true(text.length() < SaveStore.GAME_CAP, "under the file cap: %d bytes" % text.length())
	Fx.write_text("game_level.json", text)
	assert_true(store.load_games(game).is_empty(), "the tampered save is refused")
	assert_false(Fx.exists("game_level.json"), "and deleted")


func test_review_l5_menders_among_a_crowd_of_scamps_are_refused() -> void:
	var data: Dictionary = _level_save(1)
	var battle: Dictionary = data["battle"]
	_add(battle, "scamp", 3760 - (battle["enemies"] as Array).size(), 1, 1000000000)
	_add(battle, "mender", 240, 1, 1000000000)
	assert_eq((battle["enemies"] as Array).size(), Battle.MAX_ENEMIES)
	assert_false(_loads(data), "240 Menders among 3,760 Scamps")


func test_at_most_max_healers_heal_live_or_still_to_come() -> void:
	var data: Dictionary = _level_save(60)
	var battle: Dictionary = data["battle"]
	_add(battle, "mender", Battle.MAX_HEALERS, 1, 1000)
	assert_true(_loads(data), "%d Menders load" % Battle.MAX_HEALERS)
	var more: Dictionary = data.duplicate(true)
	_add(more["battle"], "mender", 1, 1, 1000)
	assert_false(_loads(more), "one more is refused")
	var released: Dictionary = data.duplicate(true)
	released["battle"]["releases"] = [_release(released["battle"], "mender", 1)]
	assert_false(_loads(released), "a Mender still to come from a release counts too")
	(released["battle"]["enemies"] as Array).pop_back()
	assert_true(_loads(released), "and with one fewer on the map it loads")


## The heal tick at the load ceiling stays cheap: 4,000 creatures, as many Menders as a
## save may hold, every one healing on the same tick, with events on.
func test_a_heal_tick_at_the_load_ceiling_stays_cheap() -> void:
	var data: Dictionary = _level_save(1)
	var battle: Dictionary = data["battle"]
	_add(battle, "scamp", Battle.MAX_ENEMIES - Battle.MAX_HEALERS - (battle["enemies"] as Array).size(), 1, 1000000000)
	_add(battle, "mender", Battle.MAX_HEALERS, 1, 1000000000)
	battle["lives"] = Battle.MAX_LIVES
	battle["start_lives"] = Battle.MAX_LIVES
	var loaded: SavedGame = SavedGame.from_data(Fx.through_json(data), game)
	assert_not_null(loaded, "the ceiling loads")
	var b: Battle = loaded.battle
	var started: int = Time.get_ticks_usec()
	b.step()
	var spent: int = Time.get_ticks_usec() - started
	var heals: Array[Dictionary] = []
	for event: Dictionary in b.take_events():
		if event["kind"] == &"healed":
			heals.append(event)
	assert_eq(heals.size(), Battle.MAX_HEALERS, "every Mender healed on that tick")
	for event: Dictionary in heals:
		assert_eq((event["ids"] as Array).size(), Battle.HEAL_EVENT_IDS, "each event lists at most %d ids" % Battle.HEAL_EVENT_IDS)
	print("    save: a heal tick with %d Menders among %d creatures took %d ms" % [Battle.MAX_HEALERS, Battle.MAX_ENEMIES, spent / 1000])
	assert_true(spent < 2000000, "well under a second even on a busy PC: %d ms" % (spent / 1000))


# N7: what live creatures can still let out.

func test_review_n7_four_thousand_puffballs_are_refused() -> void:
	var data: Dictionary = _level_save(1)
	_only_first(data["battle"])
	_add(data["battle"], "puffball", Battle.MAX_ENEMIES - 1, 1, 60)
	assert_false(_loads(data), "12,000 Puffs would follow")


func test_review_n7_four_thousand_old_tusks_are_refused() -> void:
	var data: Dictionary = _level_save(1)
	_only_first(data["battle"])
	_add(data["battle"], "old_tusk", Battle.MAX_ENEMIES - 1, 1501, 3000)
	assert_false(_loads(data), "16,000 Dusk Moths would follow")


## A Puffball counts as 4, an Old Tusk as 5 until its release begins, then as 1.
func test_the_crowd_counts_what_creatures_can_still_let_out() -> void:
	var data: Dictionary = _level_save(60)
	var battle: Dictionary = data["battle"]
	var before: int = (battle["enemies"] as Array).size()
	_add(battle, "puffball", 300, 1, 60)
	_add(battle, "old_tusk", 300, 3000, 3000)
	assert_eq(_crowd(battle), before + 300 * 4 + 300 * 5)
	var room: int = Battle.MAX_ENEMIES - _crowd(battle)
	var list: Array = []
	while room > 0:
		list.append(_release(battle, "scamp", mini(room, 200)))
		room -= mini(room, 200)
	battle["releases"] = list
	assert_true(_loads(data), "exactly %d in all loads" % Battle.MAX_ENEMIES)
	var over: Dictionary = data.duplicate(true)
	(over["battle"]["releases"] as Array).append(_release(over["battle"], "scamp", 1))
	assert_false(_loads(over), "one more is refused")
	var tusk: Dictionary = (over["battle"]["enemies"] as Array).back()
	assert_eq(tusk["type"], "old_tusk")
	tusk["released"] = true
	tusk["health"] = 1500
	assert_true(_loads(over), "a Tusk whose release has begun counts as 1")
	# Now 3,997: the released Tusk freed 4. Swap the one Scamp to come for a Puffball.
	var puffs: Dictionary = over.duplicate(true)
	(puffs["battle"]["releases"] as Array).pop_back()
	(puffs["battle"]["releases"] as Array).append(_release(puffs["battle"], "puffball", 1))
	assert_true(_loads(puffs), "a Puffball still to come counts as 4: exactly %d" % Battle.MAX_ENEMIES)
	(puffs["battle"]["releases"] as Array).append(_release(puffs["battle"], "scamp", 1))
	assert_false(_loads(puffs), "and one more is refused")


# N8: the saved level's waves.

## The save with the saved level's waves 2 onward each holding one of these groups.
func _with_waves(data: Dictionary, groups: Array) -> Dictionary:
	var out: Dictionary = data.duplicate(true)
	var waves: Array = out["battle"]["level"]["waves"]
	for i: int in groups.size():
		waves[i + 1]["groups"] = [groups[i]]
	return out


func _group(enemy: String, count: int) -> Dictionary:
	return {"enemy": enemy, "count": count, "entrance": 1, "at_ms": 0, "every_ms": 1000}


func test_review_n8_a_saved_level_of_boss_waves_is_refused() -> void:
	var data: Dictionary = _level_save(60)
	var level: Dictionary = data["battle"]["level"]
	var waves: Array = level["waves"]
	while waves.size() > 1:
		waves.pop_back()
	while waves.size() < LevelData.MAX_WAVES:
		waves.append({"strength": 1000, "groups": [_group("grumblesack", 120)]})
	assert_true(LevelData.check(level, game.catalog).is_empty(), "the level passes its own check")
	assert_false(_loads(data), "40 waves of 120 Grumblesacks")
	Fx.write_text("game_level.json", JSON.stringify(data))
	assert_true(store.load_games(game).is_empty(), "through the store too")
	assert_false(Fx.exists("game_level.json"), "and deleted")
	assert_false(_loads(_with_waves(_level_save(60), [_group("mender", 120), _group("mender", 120)])), "240 Menders to come")


func test_the_waves_on_the_map_at_once_stay_within_the_summoner_ceiling() -> void:
	var data: Dictionary = _level_save(60)
	var most: int = Battle.MAX_SUMMONERS
	var half: int = most / 2
	assert_true(_loads(_with_waves(data, [_group("grumblesack", most)])), "%d in a wave to come loads" % most)
	assert_false(_loads(_with_waves(data, [_group("grumblesack", most + 1)])), "one more is refused")
	assert_false(_loads(_with_waves(data, [_group("grumblesack", half), _group("grumblesack", half + 1)])),
		"two waves can be on the map at once")
	assert_true(_loads(_with_waves(data, [_group("grumblesack", half), _group("grumblesack", half), _group("grumblesack", half)])),
		"but never three")
	var live: Dictionary = _with_waves(data, [_group("grumblesack", half + 1)])
	_add_bosses(live["battle"], half)
	assert_false(_loads(live), "the running wave's live summoners and the next wave's add up")


func test_the_waves_on_the_map_at_once_stay_within_the_healer_ceiling() -> void:
	var data: Dictionary = _level_save(60)
	var most: int = Battle.MAX_HEALERS
	var half: int = most / 2
	assert_true(_loads(_with_waves(data, [_group("mender", most)])), "%d in a wave to come loads" % most)
	assert_false(_loads(_with_waves(data, [_group("mender", most + 1)])), "one more is refused")
	assert_false(_loads(_with_waves(data, [_group("mender", half), _group("mender", half + 1)])),
		"two waves can be on the map at once")
	assert_true(_loads(_with_waves(data, [_group("mender", half), _group("mender", half), _group("mender", half)])),
		"but never three")
	var live: Dictionary = _with_waves(data, [_group("mender", half + 1)])
	_add(live["battle"], "mender", half, 1, 1000)
	assert_false(_loads(live), "the running wave's live healers and the next wave's add up")


## A wave of Menders at the ceiling, played: every save while it spawns loads. With one
## Mender more every save is refused. So live and still to spawn never miss one or
## count one twice.
func test_a_running_wave_counts_its_live_creatures_and_those_still_to_spawn() -> void:
	for count: int in [Battle.MAX_HEALERS, Battle.MAX_HEALERS + 1]:
		var raw: Dictionary = game.levels[&"r1_l2"].to_data()
		raw["waves"][0]["groups"] = [{"enemy": "mender", "count": count, "entrance": 1, "at_ms": 100, "every_ms": 250}]
		var level: LevelData = LevelData.from_data(raw, game.catalog)
		assert_not_null(level, "the level with %d Menders" % count)
		var battle: Battle = Battle.create(level, game.catalog, false, [])
		battle.lives = Battle.MAX_LIVES
		battle.start_next_wave()
		var loads: int = 0
		var saves: int = 0
		while battle.phase == Battle.Phase.WAVE and battle.tick < 230:
			if Battle.from_data(Fx.through_json(battle.to_data()), game.catalog) != null:
				loads += 1
			saves += 1
			battle.step()
		assert_eq(saves, 230, "the wave runs on")
		assert_eq(int(battle.to_data()["next_id"]), count, "all %d spawned" % count)
		assert_eq(loads, saves if count == Battle.MAX_HEALERS else 0, "%d Menders: %d of %d saves load" % [count, loads, saves])


# Real play at its worst moments still loads.

## Plays a campaign level with lives that never run out, calling every wave as early as
## it may. defend false builds nothing, so the crowd grows as large as play allows;
## true fills every spot. A save is sent through text and SavedGame.from_data at every
## new peak and every 250 ticks. Returns the peaks.
func _play_worst(level_id: StringName, twist: bool, defend: bool) -> Dictionary:
	var level: LevelData = game.levels[level_id]
	var effects: Array[Dictionary] = level.twist_effects if twist else ([] as Array[Dictionary])
	var battle: Battle = Battle.create(level, game.catalog, false, effects)
	battle.lives = Battle.MAX_LIVES
	var peaks: Dictionary = {"live": 0, "crowd": 0, "summoners": 0, "healers": 0, "releases": 0, "loads": 0, "refused": 0}
	while (battle.phase == Battle.Phase.BUILD or battle.phase == Battle.Phase.WAVE) and battle.tick < LIMIT:
		var check: bool = battle.tick % 250 == 0
		if battle.phase == Battle.Phase.BUILD:
			check = true
			if defend:
				battle.gold = 1000000
				for i: int in level.spots.size():
					battle.place_tower(level.spots[i], level.towers[i % level.towers.size()])
		battle.start_next_wave()
		battle.step()
		var crowd: int = 0
		var summoners: int = 0
		var healers: int = 0
		for enemy: EnemyState in battle.enemies:
			var data: EnemyType = game.catalog.enemy(enemy.type)
			crowd += 1 + data.split_count
			if not data.release.is_empty() and not enemy.released:
				crowd += int(data.release["count"])
			if not data.summon.is_empty():
				summoners += 1
			if data.heal > 0:
				healers += 1
		for release: Battle.Release in battle._releases:
			crowd += release.left
		var now: Dictionary = {"live": battle.enemies.size(), "crowd": crowd, "summoners": summoners,
			"healers": healers, "releases": battle._releases.size()}
		for key: String in now:
			if now[key] > peaks[key]:
				peaks[key] = now[key]
				check = true
		if check and (battle.phase == Battle.Phase.BUILD or battle.phase == Battle.Phase.WAVE):
			var saved: SavedGame = Fx.saved(SavedGame.LEVEL, battle)
			saved.twist = twist
			if SavedGame.from_data(Fx.through_json(saved.to_data()), game) == null:
				peaks["refused"] += 1
			peaks["loads"] += 1
	assert_true(battle.phase == Battle.Phase.WON, "%s twist %s defend %s ends" % [level_id, twist, defend])
	return peaks


## The creatures one wave spawns, counting Puffs, with the Twist when twist is true.
func _wave_size(level: LevelData, w: int, twist: bool) -> int:
	var effects: Array[Dictionary] = level.twist_effects if twist else ([] as Array[Dictionary])
	var total: int = 0
	for group: WaveGroup in level.waves[w].groups:
		var type: EnemyType = game.catalog.enemy(group.enemy)
		total += Modifiers.group_count(effects, group.count, type.flying, w == level.waves.size() - 1) * (1 + type.split_count)
	return total


## The level with the largest wave of the campaign, the level with the most Menders
## (r4_l2), and every boss level with its Twist (Double Trouble brings two bosses), each
## with no defense and with a full one.
func test_real_play_at_its_worst_moments_still_loads() -> void:
	var largest: Array = [&"", false, 0]
	for level_id: StringName in game.levels:
		var level: LevelData = game.levels[level_id]
		for twist: bool in [false, true]:
			for w: int in level.waves.size():
				if _wave_size(level, w, twist) > largest[2]:
					largest = [level_id, twist, _wave_size(level, w, twist)]
	var plays: Array = [[largest[0], largest[1]], [&"r4_l2", false]]
	for level_id: StringName in [&"r1_l6", &"r2_l6", &"r3_l6", &"r4_l6"]:
		plays.append([level_id, true])
	var most: Dictionary = {"live": 0, "crowd": 0, "summoners": 0, "healers": 0, "releases": 0}
	var loads: int = 0
	for play: Array in plays:
		for defend: bool in [false, true]:
			var peaks: Dictionary = _play_worst(play[0], play[1], defend)
			var label: String = "%s twist %s defend %s" % [play[0], play[1], defend]
			assert_eq(peaks["refused"], 0, label + ": refused saves")
			if not defend and (play[0] == &"r1_l6" or play[0] == &"r3_l6"):
				assert_eq(peaks["summoners"], 2, label + ": Double Trouble brings two summoners at once")
			loads += peaks["loads"]
			for key: String in most:
				most[key] = maxi(most[key], peaks[key])
	assert_true(most["crowd"] * 4 <= Battle.MAX_ENEMIES, "play stays far below the crowd ceiling: %d" % most["crowd"])
	assert_true(most["summoners"] * 4 <= Battle.MAX_SUMMONERS, "and the summoner ceiling: %d" % most["summoners"])
	assert_true(most["healers"] * 3 <= Battle.MAX_HEALERS, "and the healer ceiling: %d" % most["healers"])
	print("    save: largest wave %d on %s (twist %s); %d worst moment saves loaded; peaks %s" % [largest[2], largest[0], largest[1], loads, str(most)])


## Play can never bring more summoners than a save may hold: every campaign level with
## and without its Twist, and a run's waves (the largest pack of each band, doubled to
## cover any risk card's count change, plus the cards that add groups).
func test_no_level_pack_or_card_brings_more_summoners_than_a_save_may_hold() -> void:
	for level_id: StringName in game.levels:
		var level: LevelData = game.levels[level_id]
		for effects: Array[Dictionary] in [[] as Array[Dictionary], level.twist_effects]:
			var total: int = 0
			for w: int in level.waves.size():
				for group: WaveGroup in level.waves[w].groups:
					var type: EnemyType = game.catalog.enemy(group.enemy)
					if not type.summon.is_empty():
						total += Modifiers.group_count(effects, group.count, type.flying, w == level.waves.size() - 1)
			assert_true(total <= Battle.MAX_SUMMONERS, "%s: %d summoners" % [level_id, total])
	var run_total: int = 0
	for band: int in range(1, 7):
		var band_most: int = 0
		for pack: Dictionary in game.run.packs_of(band):
			var in_pack: int = 0
			for wave: Dictionary in pack["waves"]:
				for group: Dictionary in wave["groups"]:
					if not game.catalog.enemy(StringName(String(group["enemy"]))).summon.is_empty():
						in_pack += int(group["count"]) * 2
			band_most = maxi(band_most, in_pack)
		run_total += band_most
	for card: Dictionary in game.run.cards:
		for effect: Dictionary in card["effects"]:
			if String(effect["type"]) == "add_group":
				var type: EnemyType = game.catalog.enemy(StringName(String(effect["enemy"])))
				assert_true(type.summon.is_empty(), "card %s adds no summoner" % card["id"])
	assert_true(run_total <= Battle.MAX_SUMMONERS, "a run: at most %d summoners" % run_total)


## [healers, summoners] that a group brings, each with what it can let out.
func _brings(enemy: StringName, count: int) -> Array[int]:
	var data: EnemyType = game.catalog.enemy(enemy)
	var out: Array[int] = [count if data.heal > 0 else 0, count if not data.summon.is_empty() else 0]
	if data.split_into != &"" and game.catalog.enemy(data.split_into).heal > 0:
		out[0] += count * data.split_count
	if not data.release.is_empty() and game.catalog.enemy(data.release["enemy"]).heal > 0:
		out[0] += count * int(data.release["count"])
	return out


## The sum of the max_waves_running largest values.
func _at_once(values: Array[int]) -> int:
	var sorted: Array[int] = values.duplicate()
	sorted.sort()
	var total: int = 0
	for i: int in mini(game.catalog.rules.max_waves_running, sorted.size()):
		total += sorted[sorted.size() - 1 - i]
	return total


## The healers and summoners that can be on the map at once stay far below what a save
## may hold: every campaign level with and without its Twist (at most a third and a
## quarter of the ceilings), and a run (at most half), with each wave of each band at its
## worst pack, that pack doubled or with each risk card, whichever brings more.
func test_real_waves_bring_far_fewer_healers_and_summoners_at_once_than_a_save_may_hold() -> void:
	var most: Array[int] = [0, 0]
	for level_id: StringName in game.levels:
		var level: LevelData = game.levels[level_id]
		for effects: Array[Dictionary] in [[] as Array[Dictionary], level.twist_effects]:
			var healers: Array[int] = []
			var summoners: Array[int] = []
			for w: int in level.waves.size():
				var wave: Array[int] = [0, 0]
				for group: WaveGroup in level.waves[w].groups:
					var count: int = Modifiers.group_count(effects, group.count, game.catalog.enemy(group.enemy).flying, w == level.waves.size() - 1)
					var brings: Array[int] = _brings(group.enemy, count)
					wave[0] += brings[0]
					wave[1] += brings[1]
				healers.append(wave[0])
				summoners.append(wave[1])
			most[0] = maxi(most[0], _at_once(healers))
			most[1] = maxi(most[1], _at_once(summoners))
	assert_true(most[0] * 3 <= Battle.MAX_HEALERS, "a level: %d healers at once" % most[0])
	assert_true(most[1] * 4 <= Battle.MAX_SUMMONERS, "a level: %d summoners at once" % most[1])
	var risks: Array = []
	for card: Dictionary in game.run.cards:
		if String(card["kind"]) == "risk":
			risks.append(Modifiers.normalize_all(card["effects"]))
		for effect: Dictionary in card["effects"]:
			if String(effect["type"]) == "add_group":
				var brings: Array[int] = _brings(StringName(String(effect["enemy"])), 1)
				assert_eq(brings, [0, 0] as Array[int], "card %s adds no healer or summoner" % card["id"])
	assert_true(risks.size() >= 1, "risk cards: %d" % risks.size())
	var healers: Array[int] = []
	var summoners: Array[int] = []
	for band: int in range(1, 7):
		for w: int in 3:
			var worst: Array[int] = [0, 0]
			for pack: Dictionary in game.run.packs_of(band):
				var choices: Array = [[] as Array[Dictionary]]
				choices.append_array(risks)
				for effects: Array[Dictionary] in choices:
					for doubled: bool in ([false, true] if effects.is_empty() else [false]):
						var wave: Array[int] = [0, 0]
						for group: Dictionary in pack["waves"][w]["groups"]:
							var enemy: StringName = StringName(String(group["enemy"]))
							var count: int = Modifiers.group_count(effects, int(group["count"]), game.catalog.enemy(enemy).flying, false)
							var brings: Array[int] = _brings(enemy, count * (2 if doubled else 1))
							wave[0] += brings[0]
							wave[1] += brings[1]
						worst[0] = maxi(worst[0], wave[0])
						worst[1] = maxi(worst[1], wave[1])
			healers.append(worst[0])
			summoners.append(worst[1])
	assert_true(_at_once(healers) * 2 <= Battle.MAX_HEALERS, "a run: %d healers at once" % _at_once(healers))
	assert_true(_at_once(summoners) * 4 <= Battle.MAX_SUMMONERS, "a run: %d summoners at once" % _at_once(summoners))
	print("    save: at once, levels %d healers and %d summoners; runs %d and %d" % [most[0], most[1], _at_once(healers), _at_once(summoners)])


## The per-group count ceiling (5.6) sits far above real play. Every campaign level, with
## and without its Twist, loads at its start, and so does a run battle with each real risk
## card waiting. Every group of every level (with and without its Twist) and of every run
## pack (with no risk card or any real one) stays at most a tenth of MAX_ENEMIES.
func test_no_real_group_comes_near_the_count_ceiling() -> void:
	var most: int = 0
	for level_id: StringName in game.levels:
		var level: LevelData = game.levels[level_id]
		for twist: bool in [false, true]:
			var effects: Array[Dictionary] = level.twist_effects if twist else ([] as Array[Dictionary])
			for w: int in level.waves.size():
				for group: WaveGroup in level.waves[w].groups:
					var flying: bool = game.catalog.enemy(group.enemy).flying
					most = maxi(most, Modifiers.group_count(effects, group.count, flying, w == level.waves.size() - 1))
			var b: Battle = Battle.create(level, game.catalog, false, effects)
			assert_not_null(Battle.from_data(Fx.through_json(b.to_data()), game.catalog), "%s twist %s loads" % [level_id, twist])
	var risks: Array = []
	for card: Dictionary in game.run.cards:
		if String(card["kind"]) == "risk":
			risks.append(Modifiers.normalize_all(card["effects"]))
	assert_true(risks.size() >= 1, "risk cards: %d" % risks.size())
	var choices: Array = [[] as Array[Dictionary]]
	choices.append_array(risks)
	var packs: int = 0
	for band: int in range(1, 7):
		for pack: Dictionary in game.run.packs_of(band):
			packs += 1
			for wave: Dictionary in pack["waves"]:
				for group: Dictionary in wave["groups"]:
					var flying: bool = game.catalog.enemy(StringName(String(group["enemy"]))).flying
					for effects: Array[Dictionary] in choices:
						most = maxi(most, Modifiers.group_count(effects, int(group["count"]), flying, false))
	assert_true(packs >= 6, "run packs: %d" % packs)
	assert_true(most * 10 <= Battle.MAX_ENEMIES, "the largest real group: %d" % most)
	var session: RunSession = Fx.session(game, 1)
	assert_not_null(session, "a run starts")
	for risk: Array[Dictionary] in risks:
		var b: Battle = Battle.from_data(Fx.through_json(session.battle.to_data()), game.catalog)
		assert_eq(b.add_effects(risk, true), Battle.DONE, "a real risk card is taken")
		assert_not_null(Battle.from_data(Fx.through_json(b.to_data()), game.catalog), "a run battle with a real risk card waiting loads")
	print("    save: the largest real group is %d, the ceiling %d" % [most, Battle.MAX_ENEMIES])


## Every campaign level creates with and without its Twist, Normal and Relaxed: create
## refuses a Twist that alone passes a wave ceiling (3.1), and no real one does.
func test_every_real_level_creates_with_its_twist() -> void:
	for level_id: StringName in game.levels:
		var level: LevelData = game.levels[level_id]
		for effects: Array[Dictionary] in [[] as Array[Dictionary], level.twist_effects]:
			for relaxed: bool in [false, true]:
				var b: Battle = Battle.create(level, game.catalog, relaxed, effects)
				assert_not_null(b, "%s with %d Twist effects, relaxed %s" % [level_id, effects.size(), relaxed])


## The speed and max health ceilings (5.6) sit far above real play: every level's Twist
## with any real risk card stays at a quarter of MAX_SPEED_PCT or less, and the catalog's
## largest health at the largest strength data allows (1,000 percent), with any real risk
## card, at a hundredth of BIG or less.
func test_no_real_speed_or_health_comes_near_its_ceiling() -> void:
	var twists: Array = [[] as Array[Dictionary]]
	for level_id: StringName in game.levels:
		twists.append((game.levels[level_id] as LevelData).twist_effects)
	var risks: Array = [[] as Array[Dictionary]]
	for card: Dictionary in game.run.cards:
		if String(card["kind"]) == "risk":
			risks.append(Modifiers.normalize_all(card["effects"]))
	var most_health: int = 1
	for id: StringName in game.catalog.enemy_ids():
		most_health = maxi(most_health, game.catalog.enemy(id).health)
	var speed: int = 0
	var health: int = 0
	for twist: Array[Dictionary] in twists:
		for risk: Array[Dictionary] in risks:
			var effects: Array[Dictionary] = []
			effects.append_array(twist)
			effects.append_array(risk)
			speed = maxi(speed, Modifiers.speed_pct(effects))
			health = maxi(health, Modifiers.scale_all(effects, "health_pct", Sim.pct_half_up(most_health, 1000)))
	assert_true(speed > 100, "some real effect speeds creatures up: %d" % speed)
	assert_true(speed * 4 <= Battle.MAX_SPEED_PCT, "the fastest real speed: %d percent" % speed)
	assert_true(health * 100 <= Battle.BIG, "the most real max health: %d" % health)
	print("    save: real speed at most %d percent (ceiling %d), max health at most %d (ceiling %d)" % [speed, Battle.MAX_SPEED_PCT, health, Battle.BIG])


## The kept card effect ceilings (5.6) sit far above real play. Every real card that is
## not a risk card, stacked as play allows (a once card once, any other card on all 17
## picks), keeps every tower stat at a tenth of MAX_TOWER_STAT or less, and the catalog's
## largest bounty and the last run wave's clear bonus, at the largest strength data allows
## (1,000 percent), at a hundredth of MAX_GAIN or less. A run battle that picked them all
## takes every card and loads.
func test_no_real_card_stack_comes_near_a_ceiling() -> void:
	var stack: Array[Dictionary] = []
	var cards: Array[Dictionary] = []
	for card: Dictionary in game.run.cards:
		if String(card["kind"]) == "risk":
			continue
		for i: int in (1 if bool(card["once"]) else 17):
			cards.append(card)
			for effect: Dictionary in Modifiers.normalize_all(card["effects"]):
				if not Modifiers.INSTANT.has(String(effect["type"])):
					stack.append(effect)
	assert_true(stack.size() <= Modifiers.MAX_KEPT, "the stack fits the kept effects: %d" % stack.size())
	var most_stat: int = 0
	for id: StringName in game.catalog.tower_ids():
		var type: TowerType = game.catalog.tower(id)
		for step: Array in [[1, -1], [2, -1], [3, 0], [3, 1]]:
			var base: TowerStats = type.stats(step[0], step[1])
			if base == null:
				continue
			for first_step: bool in [true, false]:
				var t: TowerStats = Modifiers.tower_stats(base, id, stack, first_step)
				for value: int in [t.cost, t.reach, t.damage, t.reload_ms, t.splash, t.targets, t.boost_pct, t.boost_damage]:
					most_stat = maxi(most_stat, value)
	var most_bounty: int = 1
	for id: StringName in game.catalog.enemy_ids():
		most_bounty = maxi(most_bounty, game.catalog.enemy(id).bounty)
	var rules: GameRules = game.catalog.rules
	var bounty: int = Modifiers.scale_all(stack, "bounty_pct", Sim.pct_half_up(most_bounty, 1000))
	var bonus: int = Modifiers.scale_all(stack, "clear_bonus_pct", Sim.pct_half_up(rules.clear_bonus + rules.clear_bonus_per_wave * 18, 1000))
	assert_true(most_stat * 10 <= Battle.MAX_TOWER_STAT, "the largest real tower stat: %d" % most_stat)
	assert_true(maxi(bounty, bonus) * 100 <= Battle.MAX_GAIN, "the largest real gold gain: bounty %d, clear bonus %d" % [bounty, bonus])
	var session: RunSession = Fx.session(game, 1)
	var b: Battle = Battle.from_data(Fx.through_json(session.battle.to_data()), game.catalog)
	for card: Dictionary in cards:
		assert_eq(b.add_effects(Modifiers.normalize_all(card["effects"]), false), Battle.DONE, "card %s is taken" % card["id"])
	assert_eq(b.card_effects.size(), stack.size(), "every kept effect is kept")
	assert_not_null(Battle.from_data(Fx.through_json(b.to_data()), game.catalog), "the battle with every card loads")
	print("    save: real cards stacked: tower stat at most %d (ceiling %d), gain at most %d (ceiling %d)" % [most_stat, Battle.MAX_TOWER_STAT, maxi(bounty, bonus), Battle.MAX_GAIN])
