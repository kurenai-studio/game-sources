# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## Every real level played on the real sim by the plain mixed recipe of RULES 12.6: the stand-in
## for a thoughtful first try. It is played once for every gate placement the level allows, and
## its best placement must win on Normal, last 5 to 10 minutes at 1x (RULES 12.5) and be
## repeatable. It proves each level plays through with no script errors. It does not judge
## balance beyond that: the balance bots in tools/balance/ do that.
## Each level prints one line: the best placement, lives left and the length.

const Files: GDScript = preload("res://tests/levels/fixtures/level_files.gd")

## Far more than any level needs: 20 minutes of wave time at 1x.
const TICK_CAP: int = 20 * 60 * Sim.TICKS_PER_SECOND
## RULES 12.5 counts 15 s for each build phase when it measures a level's length.
const BUILD_SECONDS: int = 15
## RULES 12.5: a level lasts 5 to 10 minutes at 1x.
const LENGTH_MINUTES: Array[float] = [5.0, 10.0]
## RULES 12.6 step 4: the attacking towers in turn. The Firework Tower and the Moth Lantern join the turn
## only on a level whose waves bring flyers.
const TURN: Array[StringName] = [&"sling_post", &"pumpkin_catapult", &"longbow_loft", &"bramble_cottage", &"snow_fort", &"firework_tower", &"moth_lantern"]
const FLYER_TOWERS: Array[StringName] = [&"firework_tower", &"moth_lantern"]
## RULES 12.6 step 1: road seen within 2.5 tiles.
const SEEN_REACH: int = 250

var catalog: Catalog = null


func before_each() -> void:
	catalog = Files.catalog()


## RULES 12.6 steps 1 to 5: [{"cell", "type", "top"}] in build order, where top is the highest
## tier the recipe buys. In region 1 it stops at tier 2. Bells and Scarecrows stay at tier 2.
func _recipe(level: LevelData, first_region: bool) -> Array[Dictionary]:
	var ranked: Array[Vector2i] = _spot_order(level)
	var bakery_cell: Vector2i = Vector2i(-1, -1)
	if level.towers.has(&"bakery"):
		var best: int = 1
		for spot: Vector2i in ranked:
			var near: int = 0
			for other: Vector2i in level.spots:
				if other != spot and absi(other.x - spot.x) <= 1 and absi(other.y - spot.y) <= 1:
					near += 1
			if near > best:
				best = near
				bakery_cell = spot
	var attackers: Array[StringName] = []
	for type: StringName in TURN:
		if level.towers.has(type) and (not FLYER_TOWERS.has(type) or _brings_flyers(level)):
			attackers.append(type)
	var out: Array[Dictionary] = []
	var bell_done: bool = not level.towers.has(&"lullaby_bell")
	var scarecrow_done: bool = not level.towers.has(&"scarecrow")
	var turn: int = 0
	for i: int in ranked.size():
		var cell: Vector2i = ranked[i]
		if cell == bakery_cell:
			continue
		var bell_index: int = 3 if bakery_cell == ranked[mini(2, ranked.size() - 1)] else 2
		if not bell_done and i == bell_index:
			out.append({"cell": cell, "type": &"lullaby_bell", "top": 2})
			bell_done = true
			continue
		# RULES 12.6 step 3: one Scarecrow on the fifth spot, or the sixth when the Bakery has the fifth.
		var scarecrow_index: int = 5 if bakery_cell == ranked[mini(4, ranked.size() - 1)] else 4
		if not scarecrow_done and i == scarecrow_index:
			out.append({"cell": cell, "type": &"scarecrow", "top": 2})
			scarecrow_done = true
			continue
		out.append({"cell": cell, "type": attackers[turn % attackers.size()], "top": 2 if first_region else 3})
		turn += 1
	if bakery_cell != Vector2i(-1, -1):
		out.append({"cell": bakery_cell, "type": &"bakery", "top": 2})
	return out


## Spots by road seen, most first; ties keep cell order (RULES 3.4, 12.6 step 1). Tunnel tiles are not
## counted: a walker inside one is out of reach (RULES 3.6).
func _spot_order(level: LevelData) -> Array[Vector2i]:
	var keyed: Array = []
	for i: int in level.spots.size():
		var spot: Vector2i = level.spots[i]
		var seen: int = 0
		for r: int in level.rows:
			for c: int in Sim.MAP_COLUMNS:
				var dx: int = (c - spot.x) * 100
				var dy: int = (r - spot.y) * 100
				var cell: Vector2i = Vector2i(c, r)
				if level.is_road(cell) and level.feature_at(cell) != LevelData.Feature.TUNNEL and dx * dx + dy * dy <= SEEN_REACH * SEEN_REACH:
					seen += 1
		keyed.append([-seen, i])
	keyed.sort()
	var out: Array[Vector2i] = []
	for item: Array in keyed:
		out.append(level.spots[int(item[1])])
	return out


func _brings_flyers(level: LevelData) -> bool:
	for wave: WaveData in level.waves:
		for group: WaveGroup in wave.groups:
			var enemy: EnemyType = catalog.enemy(group.enemy)
			if enemy == null:
				continue
			if enemy.flying:
				return true
			var released: Array = [enemy.summon.get("enemy", ""), enemy.release.get("enemy", "")]
			for other: Variant in released:
				var type: EnemyType = catalog.enemy(StringName(str(other)))
				if type != null and type.flying:
					return true
	return false


## Every placement of up to the level's gates that seals nothing, the empty one first.
func _placements(level: LevelData) -> Array[Array]:
	var out: Array[Array] = []
	_collect(level, RoadMap.new(level), 0, [], out)
	return out


func _collect(level: LevelData, map: RoadMap, start: int, current: Array, out: Array[Array]) -> void:
	var closed: Array[Vector2i] = []
	closed.assign(current)
	if map.seals(closed):
		return
	out.append(current.duplicate())
	if current.size() >= level.gates:
		return
	for i: int in range(start, level.sockets.size()):
		var next: Array = current.duplicate()
		next.append(level.sockets[i])
		_collect(level, map, i + 1, next, out)


## RULES 12.6 step 6: buy strictly in order, only in build phases, waiting when too poor.
func _buy(battle: Battle, plan: Array[Dictionary], cursor: Array[int]) -> void:
	while cursor[0] < plan.size() * 3:
		var step: int = cursor[0] / plan.size()
		var item: Dictionary = plan[cursor[0] % plan.size()]
		if step + 1 > int(item["top"]):
			cursor[0] += 1
			continue
		var cell: Vector2i = item["cell"]
		var done: StringName
		if step == 0:
			done = battle.place_tower(cell, item["type"])
		elif step == 1:
			done = battle.upgrade_tower(cell)
		else:
			done = battle.upgrade_tower(cell, 0)
		if done == &"too_poor":
			return
		cursor[0] += 1


## One play: {"won", "lives", "cleared", "ticks", "waves", "wave1_lives", "digest"}.
func _play(level: LevelData, plan: Array[Dictionary], gates: Array) -> Dictionary:
	var battle: Battle = Battle.create(level, catalog, false, [])
	if battle == null:
		return {}
	battle.record_events = false
	for cell: Vector2i in gates:
		battle.place_gate(cell)
	var cursor: Array[int] = [0]
	var wave1_lives: int = -1
	while battle.phase == Battle.Phase.BUILD and battle.tick < TICK_CAP:
		_buy(battle, plan, cursor)
		if battle.start_next_wave() != Battle.DONE:
			break
		while battle.phase == Battle.Phase.WAVE and battle.tick < TICK_CAP:
			battle.step()
		if wave1_lives < 0:
			wave1_lives = battle.lives
	var result: Dictionary = battle.result()
	return {"won": battle.phase == Battle.Phase.WON, "lost": battle.phase == Battle.Phase.LOST,
		"lives": int(result["lives_left"]), "cleared": int(result["waves_cleared"]), "ticks": battle.tick,
		"waves": battle.wave_count(), "wave1_lives": wave1_lives, "digest": JSON.stringify(battle.to_data()).hash()}


func _better(a: Dictionary, b: Dictionary) -> bool:
	if b.is_empty():
		return true
	if bool(a["won"]) != bool(b["won"]):
		return bool(a["won"])
	if bool(a["won"]):
		return int(a["lives"]) > int(b["lives"])
	return int(a["cleared"]) > int(b["cleared"])


func test_the_plain_mixed_recipe_wins_every_level_in_5_to_10_minutes() -> void:
	var regions: Dictionary = Files.region_of()
	var first_region: String = str(regions.get("r1_l1", ""))
	for id: String in Files.campaign_order():
		var level: LevelData = Files.level(id, catalog)
		assert_not_null(level, "%s loads" % id)
		if level == null:
			continue
		var plan: Array[Dictionary] = _recipe(level, str(regions.get(id, "")) == first_region)
		var best: Dictionary = {}
		var best_gates: Array = []
		for gates: Array in _placements(level):
			var out: Dictionary = _play(level, plan, gates)
			assert_false(out.is_empty(), "%s: Battle.create gives a battle" % id)
			if out.is_empty():
				continue
			assert_true(bool(out["won"]) or bool(out["lost"]), "%s with gates %s: the battle ends within %d ticks" % [id, gates, TICK_CAP])
			if _better(out, best):
				best = out
				best_gates = gates
		if best.is_empty():
			continue
		var minutes: float = (float(best["ticks"]) / Sim.TICKS_PER_SECOND + BUILD_SECONDS * int(best["waves"])) / 60.0
		assert_true(bool(best["won"]), "%s: the plain mixed recipe wins on Normal at its best gates (RULES 12.6)" % id)
		assert_true(int(best["wave1_lives"]) > 0, "%s: the recipe survives wave 1" % id)
		if bool(best["won"]):
			assert_eq(int(best["cleared"]), int(best["waves"]), "%s: a win clears every wave" % id)
			assert_true(minutes >= LENGTH_MINUTES[0] and minutes <= LENGTH_MINUTES[1], "%s: the recipe's win lasts %.1f min at 1x, RULES 12.5 asks 5 to 10" % [id, minutes])
		var again: Dictionary = _play(level, plan, best_gates)
		assert_eq(again.get("digest", 0), best["digest"], "%s: the same play gives the same battle" % id)
		print("    %s: %s with gates %s, %d lives left, %d of %d waves cleared, %.1f min at 1x with %d s per build phase" % [
			id, "won" if bool(best["won"]) else "lost", best_gates, int(best["lives"]), int(best["cleared"]),
			int(best["waves"]), minutes, BUILD_SECONDS])
