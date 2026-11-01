# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends "res://tests/base_test.gd"
## The tier 0 golden test (docs/ARCHITECTURE.md 14.13, RULES 14.9). A tier 0 run is exactly
## the run of regions 1 to 4. tests/run/fixtures/tier0_golden.json was recorded with the
## build before the expansion: the plan and a SHA-256 of the level for run seeds 1 to 200
## and for the daily seeds of 30 days from 2026-10-28, and the card pools. Only a
## deliberate change to tier 0 runs, recorded by the DM, may record it again.

const Golden: GDScript = preload("res://tests/run/fixtures/run_golden.gd")

var _golden: Dictionary = {}
var _now: Dictionary = {}


func before_each() -> void:
	var got: Dictionary = JsonFile.read(Golden.GOLDEN_PATH, 1048576)
	assert_eq(got["status"], JsonFile.OK_STATUS, "the golden file reads")
	if got["status"] == JsonFile.OK_STATUS:
		_golden = got["data"]
	_now = Golden.compute()


func test_the_golden_file_holds_what_the_test_pins() -> void:
	assert_eq((_golden["runs"] as Dictionary).size(), Golden.SEEDS)
	assert_eq((_golden["dailies"] as Dictionary).size(), Golden.DAYS)
	assert_eq((_golden["dailies"] as Dictionary).keys()[0], Golden.FIRST_DAY)
	assert_eq(Golden.days().size(), Golden.DAYS)
	assert_eq(Golden.days()[0], Golden.FIRST_DAY)
	assert_eq(Golden.days()[29], "2026-11-26")
	assert_eq((_golden["card_ids"] as Array).size(), 34)
	assert_eq((_golden["pool_none"] as Array).size(), 22)
	assert_eq(_golden["pool_every"], _golden["card_ids"])


func test_the_pools_at_tier_0_are_unchanged() -> void:
	assert_eq(_now["pool_none"], _golden["pool_none"], "pool with no unlocks")
	assert_eq(_now["pool_every"], _golden["pool_every"], "pool with every unlock")
	assert_eq(_now["card_ids"], _golden["card_ids"], "card_ids")


func test_runs_for_seeds_1_to_200_are_unchanged() -> void:
	var runs: Dictionary = _golden["runs"]
	var now: Dictionary = _now["runs"]
	for key: String in runs.keys():
		var want: Dictionary = runs[key]
		var got: Dictionary = now.get(key, {})
		assert_eq(got.get("plan", {}), want["plan"], "plan of seed %s" % key)
		assert_eq(got.get("hash", ""), want["hash"], "level of seed %s" % key)


func test_the_dailies_of_30_days_are_unchanged() -> void:
	var dailies: Dictionary = _golden["dailies"]
	var now: Dictionary = _now["dailies"]
	for day: String in dailies.keys():
		var want: Dictionary = dailies[day]
		var got: Dictionary = now.get(day, {})
		assert_eq(got.get("seed", -1), want["seed"], "seed of %s" % day)
		assert_eq(got.get("plan", {}), want["plan"], "plan of %s" % day)
		assert_eq(got.get("hash", ""), want["hash"], "level of %s" % day)


func test_a_tier_0_start_gives_the_golden_level_too() -> void:
	# RunSession.start with the default tier builds the same level as the golden file pins.
	var cat: Catalog = Golden.catalog()
	var data: RunData = RunData.from_data(Golden.real_files(), cat)
	assert_not_null(data)
	if data == null:
		return
	for run_seed: int in [1, 77, 200]:
		var s: RunSession = RunSession.start(run_seed, "", false, data.pool({}), data, cat)
		assert_not_null(s, "seed %d" % run_seed)
		if s != null:
			assert_eq(JSON.stringify(s.battle.level.to_data()).sha256_text(), _golden["runs"][str(run_seed)]["hash"])


func test_tier_1_things_added_to_the_real_files_leave_tier_0_unchanged() -> void:
	# The real packs and segments plus a tunnel segment and packs that use tier 1 creatures,
	# put first in their files. The same plans and levels come out (RULES 14.9).
	var files: Dictionary = Golden.with_tier_1(Golden.real_files())
	var cat: Catalog = Golden.catalog()
	var data: RunData = RunData.from_data(files, cat)
	assert_not_null(data, "\n".join(RunData.check(files, cat)))
	if data == null:
		return
	assert_true(data.tiers.size() >= 2, "the real run.json lists at least tiers 1 and 2")
	assert_eq(data.packs_of(2, &"", 1).size(), data.packs_of(2).size() + 1, "the Mossbud pack joins at tier 1")
	assert_true(data.boss_ids(2).has(&"old_hayrick"))
	assert_false(data.boss_ids(0).has(&"old_hayrick"), "and Old Hayrick stays out of tier 0")
	assert_true(data.boss_ids(1).has(&"burrowbelly"))
	var with_tier: Dictionary = Golden.compute(files)
	assert_eq(with_tier["pool_none"], _golden["pool_none"])
	assert_eq(with_tier["card_ids"], _golden["card_ids"])
	var runs: Dictionary = _golden["runs"]
	for key: String in runs.keys():
		var got: Dictionary = with_tier["runs"].get(key, {})
		assert_eq(got.get("plan", {}), runs[key]["plan"], "plan of seed %s" % key)
		assert_eq(got.get("hash", ""), runs[key]["hash"], "level of seed %s" % key)
	var dailies: Dictionary = _golden["dailies"]
	for day: String in dailies.keys():
		var got: Dictionary = with_tier["dailies"].get(day, {})
		assert_eq(got.get("seed", -1), dailies[day]["seed"], "seed of %s" % day)
		assert_eq(got.get("plan", {}), dailies[day]["plan"], "plan of %s" % day)
		assert_eq(got.get("hash", ""), dailies[day]["hash"], "level of %s" % day)


## No creature, pack, segment or card of regions 1 to 4 is above tier 0, and nothing a tier 0
## run can draw holds a tier 1 thing.
func test_nothing_real_of_tier_0_is_above_tier_0() -> void:
	var files: Dictionary = Golden.with_tier_1(Golden.real_files())
	var cat: Catalog = Golden.catalog()
	var data: RunData = RunData.from_data(files, cat)
	assert_not_null(data, "\n".join(RunData.check(files, cat)))
	if data == null:
		return
	var listed: Array[StringName] = []
	for tier: Dictionary in data.tiers:
		for key: String in ["towers", "creatures", "bosses"]:
			listed.append_array(tier[key])
	var old_creatures: Array[StringName] = [
		&"scamp", &"pip", &"skitter", &"flitter", &"shellback", &"bubbler", &"puffball", &"puff",
		&"mender", &"gatecrasher", &"dusk_moth", &"grumblesack", &"ironshell", &"moon_moth", &"old_tusk",
	]
	var old_towers: Array[StringName] = [&"sling_post", &"pumpkin_catapult", &"lullaby_bell", &"longbow_loft", &"firework_tower", &"bakery"]
	for id: StringName in old_creatures + old_towers:
		assert_false(listed.has(id), "%s is in a tier list" % id)
	# Cards: a card is tier 0 unless its tower is listed.
	for id: StringName in data.card_ids(4):
		var card: Dictionary = data.card(id)
		var want_tier: int = 0
		for t: int in data.tiers.size():
			if (data.tiers[t]["towers"] as Array).has(card["tower"]):
				want_tier = t + 1
		assert_eq(card["tier"], want_tier, "tier of card %s" % id)
	# Segments: tier 0 unless a map feature of a tier is in the grid.
	var features: String = ""
	for tier: Dictionary in data.tiers:
		features += String(tier["grid"])
	for id: StringName in data.segment_ids:
		var has_feature: bool = false
		for row: String in data.segment(id)["grid"]:
			for ch: String in features:
				if row.contains(ch):
					has_feature = true
		assert_eq(data.segment(id)["tier"] > 0, has_feature, "tier of segment %s" % id)
	# Packs: tier 0 unless a creature, a boss or something they bring is listed.
	for pack: Dictionary in data.packs:
		var uses_listed: bool = listed.has(pack["boss"])
		for wave: Dictionary in pack["waves"]:
			for group: Dictionary in wave["groups"]:
				var enemy: StringName = StringName(String(group["enemy"]))
				uses_listed = uses_listed or listed.has(enemy)
				var type: EnemyType = cat.enemy(enemy)
				var children: Array[StringName] = [type.split_into]
				for brought: Dictionary in [type.summon, type.release]:
					children.append(StringName(String(brought.get("enemy", ""))))
				for child: StringName in children:
					uses_listed = uses_listed or listed.has(child)
		assert_eq(pack["tier"] > 0, uses_listed, "tier of pack %s" % pack["id"])
	# The golden plans only ever name tier 0 things, and every pack the file held at tier 0 stays.
	var runs: Dictionary = _golden["runs"]
	for key: String in runs.keys():
		var plan: Dictionary = runs[key]["plan"]
		assert_eq(data.segment(StringName(plan["top"]))["tier"], 0)
		assert_eq(data.segment(StringName(plan["middle"]))["tier"], 0)
		assert_eq(data.segment(StringName(plan["bottom"]))["tier"], 0)
		for pack_id: String in plan["packs"]:
			var found: bool = false
			for pack: Dictionary in data.packs:
				if pack["id"] == pack_id:
					found = true
					assert_eq(pack["tier"], 0, pack_id)
			assert_true(found, "%s is still in the packs" % pack_id)
