# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## A saved game at a load ceiling plays on, and the game it then saves loads again
## (docs/ARCHITECTURE.md 5.5, 5.6; security review 2026-10-29, L8). Before the fix, the
## next id, the tick and a tower's spent gold could pass their ceilings in play, so the
## next save was refused and the next launch deleted the game. The crowd of creatures
## and the number of releases are numbers play makes grow as well.

const Fx: GDScript = preload("res://tests/save/fixtures/save_fixtures.gd")
## Creature timers that hold a tick, moved with the tick.
const AT_KEYS: Array = ["summon_at", "heal_at", "regrow_at", "dig_at", "yawn_at", "blink_at"]

var game: GameData = null
var store: SaveStore = null


func before_each() -> void:
	Fx.fresh()
	game = Fx.game()
	store = SaveStore.new(Fx.WORK)


func after_each() -> void:
	store = null
	Fx.clean()


## r1_l2 60 ticks into wave 1, as its file holds it: two Scamps on the map, the next
## due now, then one every 30 ticks. With `towers`, a tower stands on every spot.
func _level_save(towers: bool = true) -> Dictionary:
	var battle: Battle = Battle.create(game.levels[&"r1_l2"], game.catalog, false, [])
	battle.gold = 100000
	for spot: Vector2i in battle.level.spots if towers else []:
		assert_eq(battle.place_tower(spot, battle.level.towers[0]), Battle.DONE)
	assert_eq(battle.start_next_wave(), Battle.DONE)
	for i: int in 60:
		battle.step()
	assert_eq(battle.phase, Battle.Phase.WAVE)
	assert_false(battle.enemies.is_empty(), "creatures on the map")
	return Fx.through_json(Fx.saved(SavedGame.LEVEL, battle).to_data())


## The game a file of `data` brings back, or null when it is refused.
func _from_file(data: Dictionary) -> SavedGame:
	Fx.write_text("game_level.json", JSON.stringify(data))
	var found: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
	return found[0] if found.size() == 1 else null


## Saves the game as the App does, then loads it as the next launch does.
func _saved_and_loaded(saved: SavedGame) -> SavedGame:
	assert_true(store.save_game(saved), "the game saves")
	var found: Array[SavedGame] = SaveStore.new(Fx.WORK).load_games(game)
	assert_eq(found.size(), 1, "the next launch loads it")
	return found[0] if found.size() == 1 else null


## Plays up to n ticks while a wave runs. Returns the events.
func _play(battle: Battle, n: int) -> Array[Dictionary]:
	var events: Array[Dictionary] = []
	for i: int in n:
		if battle.phase != Battle.Phase.WAVE:
			break
		battle.step()
		events.append_array(battle.take_events())
	return events


## Releases of Scamps at the entrance, `total` creatures in all, none due for a minute.
func _fill(battle: Dictionary, total: int, per_release: int = 200) -> void:
	var entrance: Array = DataCheck.cell_data(game.levels[&"r1_l2"].entrances[0])
	var gap: int = 60000 / Sim.MS_PER_TICK
	while total > 0:
		var n: int = mini(total, per_release)
		(battle["releases"] as Array).append({"enemy": "scamp", "wave": battle["running"][0], "left": n,
			"next": int(battle["tick"]) + gap, "gap": gap, "from": entrance, "to": entrance.duplicate(),
			"progress": Sim.UNIT})
		total -= n


func _crowd(battle: Dictionary) -> int:
	var total: int = 0
	for enemy: Dictionary in battle["enemies"]:
		var data: EnemyType = game.catalog.enemy(StringName(String(enemy["type"])))
		total += 1 + data.split_count
		if not data.release.is_empty() and not enemy["released"]:
			total += int(data.release["count"])
	for release: Dictionary in battle["releases"]:
		total += int(release["left"])
	return total


func test_l8_a_game_at_the_id_ceiling_plays_on_and_loads_again() -> void:
	var data: Dictionary = _level_save()
	var battle: Dictionary = data["battle"]
	var enemies: Array = battle["enemies"]
	for i: int in enemies.size():
		enemies[i]["id"] = Battle.ID_CEILING - enemies.size() + i
	battle["next_id"] = Battle.ID_CEILING
	var saved: SavedGame = _from_file(data)
	assert_not_null(saved, "a next id of 2^31 loads")
	var events: Array[Dictionary] = _play(saved.battle, 400)
	assert_eq(_count(events, &"spawned"), 0, "no creature appears")
	var again: SavedGame = _saved_and_loaded(saved)
	assert_eq(again.battle._next_id, Battle.ID_CEILING)
	assert_eq(Fx.battle_text(again.battle), Fx.battle_text(saved.battle), "the same battle")


func test_l8_a_game_at_the_tick_ceiling_plays_to_it_then_is_lost() -> void:
	var data: Dictionary = _level_save()
	var battle: Dictionary = data["battle"]
	var shift: int = Battle.BIG - 20 - int(battle["tick"])
	battle["tick"] = int(battle["tick"]) + shift
	var starts: Array = battle["wave_start"]
	for i: int in starts.size():
		starts[i] = int(starts[i]) + shift
	for enemy: Dictionary in battle["enemies"]:
		for key: String in AT_KEYS:
			if enemy.has(key) and int(enemy[key]) > 0:
				enemy[key] = int(enemy[key]) + shift
	for release: Dictionary in battle["releases"]:
		release["next"] = int(release["next"]) + shift
	var saved: SavedGame = _from_file(data)
	assert_not_null(saved, "20 ticks below the ceiling loads")
	_play(saved.battle, 20)
	assert_eq(saved.battle.tick, Battle.BIG)
	assert_eq(saved.battle.phase, Battle.Phase.WAVE)
	var again: SavedGame = _saved_and_loaded(saved)
	assert_eq(again.battle.tick, Battle.BIG, "a wave at the tick ceiling saves and loads")
	again.battle.step()
	assert_eq(again.battle.phase, Battle.Phase.LOST, "the next tick is lost, never past the ceiling")
	assert_eq(again.battle.tick, Battle.BIG)
	assert_false(again.can_save(), "a game that has ended is not saved")


func test_l8_a_tower_at_the_spent_ceiling_buys_and_loads_again() -> void:
	var data: Dictionary = _level_save()
	var tower: Dictionary = data["battle"]["towers"][0]
	tower["spent_before"] = Battle.BIG
	var saved: SavedGame = _from_file(data)
	assert_not_null(saved, "spent gold at BIG loads")
	var cell: Vector2i = saved.battle.towers[0].cell
	assert_eq(saved.battle.upgrade_tower(cell), Battle.DONE)
	assert_eq(saved.battle.towers[0].spent_before, Battle.BIG, "spent gold stops at BIG")
	_play(saved.battle, 100)
	var again: SavedGame = _saved_and_loaded(saved)
	assert_eq(again.battle.towers[0].spent_before, Battle.BIG)
	assert_eq(again.battle.sell_value(cell), Battle.BIG * game.catalog.rules.refund_pct / 100)


func test_a_game_at_the_crowd_ceiling_plays_on_and_loads_again() -> void:
	var data: Dictionary = _level_save(false)
	var battle: Dictionary = data["battle"]
	_fill(battle, Battle.MAX_ENEMIES - _crowd(battle))
	assert_eq(_crowd(battle), Battle.MAX_ENEMIES)
	var saved: SavedGame = _from_file(data)
	assert_not_null(saved, "exactly MAX_ENEMIES in all loads")
	var events: Array[Dictionary] = _play(saved.battle, 40)
	assert_eq(_count(events, &"spawned"), 0, "two Scamps fell due and neither came")
	var again: SavedGame = _saved_and_loaded(saved)
	# The wave's last Scamp falls due at tick 120 and is left out too. The two on the
	# map get through, so the crowd falls.
	events = _play(again.battle, 400)
	assert_eq(_count(events, &"spawned"), 0)
	assert_eq(_count(events, &"leaked"), 2, "the Scamps on the map got through")
	var last: SavedGame = _saved_and_loaded(again)
	assert_true(_crowd(Fx.through_json(last.battle.to_data())) <= Battle.MAX_ENEMIES)


func test_a_game_at_the_release_ceiling_plays_on_and_loads_again() -> void:
	var data: Dictionary = _level_save()
	var battle: Dictionary = data["battle"]
	# A Puffball with 1 health beside the first creature, where the towers reach.
	var ball: Dictionary = (battle["enemies"][0] as Dictionary).duplicate(true)
	ball["id"] = battle["next_id"]
	battle["next_id"] = int(battle["next_id"]) + 1
	ball["type"] = "puffball"
	ball["health"] = 1
	ball["max_health"] = game.catalog.enemy(&"puffball").health
	(battle["enemies"] as Array).append(ball)
	_fill(battle, Battle.MAX_RELEASES, 1)
	var saved: SavedGame = _from_file(data)
	assert_not_null(saved, "MAX_RELEASES releases load")
	var events: Array[Dictionary] = []
	var popped: bool = false
	for i: int in 100:
		events.append_array(_play(saved.battle, 1))
		for event: Dictionary in events:
			popped = popped or (event["kind"] == &"defeated" and event["enemy"] == &"puffball")
		if popped:
			break
	assert_true(popped, "the Puffball fell")
	assert_eq(_count(events, &"released"), 0, "and with MAX_RELEASES under way its Puffs do not come")
	assert_not_null(_saved_and_loaded(saved), "the game saves and loads")


func _count(events: Array[Dictionary], kind: StringName) -> int:
	var n: int = 0
	for event: Dictionary in events:
		if event["kind"] == kind:
			n += 1
	return n
