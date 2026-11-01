# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Catalog
extends RefCounted
## data/stats/ checked and held: towers, creatures and core rules
## (docs/ARCHITECTURE.md 2.6). src/save/ reads the files and passes the parsed values in.

const FORMAT: int = 1
const TOWER_KINDS: PackedStringArray = ["attack", "slow", "boost", "fright"]
const HITS: PackedStringArray = ["ground", "air", "both"]
const RULE_KEYS: PackedStringArray = [
	"format", "start_lives", "relaxed_lives_pct", "relaxed_gold_pct", "refund_pct",
	"early_bonus_pct", "clear_bonus", "clear_bonus_per_wave", "star2_lives",
	"max_waves_running", "max_gates", "bubble_ms", "region_stars", "run_stars",
]
const ENEMY_REQUIRED: PackedStringArray = ["id", "name", "info", "health", "armor", "speed", "lives", "bounty"]
const ENEMY_OPTIONAL: PackedStringArray = [
	"flying", "boss", "bubble", "heal", "heal_reach", "heal_ms", "split_into", "split_count",
	"split_gap_ms", "break_ms", "summon", "speed_up", "release", "regrow", "regrow_ms", "mist", "dazzle",
	"nap_ms", "dig_first_ms", "dig_every_ms", "dig_ms", "grow_pct", "grow_cap_pct", "yawn_ms", "yawn_reach",
	"doze_ms", "blink_ms", "blink_tiles", "wake_reach",
]

var rules: GameRules = null

var _towers: Dictionary[StringName, TowerType] = {}
var _enemies: Dictionary[StringName, EnemyType] = {}
var _tower_ids: Array[StringName] = []
var _enemy_ids: Array[StringName] = []


## Every problem in the three parsed stat files; empty when valid.
static func check(towers: Variant, enemies: Variant, rules_data: Variant) -> PackedStringArray:
	var built: Array = _build(towers, enemies, rules_data)
	return built[1]


## Null when check() finds anything.
static func from_data(towers: Variant, enemies: Variant, rules_data: Variant) -> Catalog:
	var built: Array = _build(towers, enemies, rules_data)
	var problems: PackedStringArray = built[1]
	if not problems.is_empty():
		return null
	return built[0]


func tower(id: StringName) -> TowerType:
	return _towers.get(id, null)


func enemy(id: StringName) -> EnemyType:
	return _enemies.get(id, null)


func tower_ids() -> Array[StringName]:
	return _tower_ids.duplicate()


func enemy_ids() -> Array[StringName]:
	return _enemy_ids.duplicate()


func has_tower(id: StringName) -> bool:
	return _towers.has(id)


func has_enemy(id: StringName) -> bool:
	return _enemies.has(id)


## [Catalog, PackedStringArray of problems].
static func _build(towers: Variant, enemies: Variant, rules_data: Variant) -> Array:
	var catalog: Catalog = new()
	var problems: PackedStringArray = PackedStringArray()
	var tower_check: DataCheck = DataCheck.new("towers.json")
	catalog._read_towers(towers, tower_check)
	problems.append_array(tower_check.problems)
	var enemy_check: DataCheck = DataCheck.new("enemies.json")
	catalog._read_enemies(enemies, enemy_check)
	problems.append_array(enemy_check.problems)
	var rule_check: DataCheck = DataCheck.new("rules.json")
	catalog._read_rules(rules_data, rule_check)
	problems.append_array(rule_check.problems)
	return [catalog, problems]


func _read_towers(data: Variant, chk: DataCheck) -> void:
	if not chk.object(data, "", ["format", "towers"]):
		return
	var top: Dictionary = data
	chk.integer(top, "format", "", FORMAT, FORMAT)
	var list: Array = chk.array(top, "towers", "", 1, 32)
	var spec_ids: Dictionary = {}
	for i: int in list.size():
		var path: String = "towers[%d]" % i
		if not chk.object(list[i], path, ["id", "name", "plural", "info", "kind", "tiers", "specs"]):
			continue
		var item: Dictionary = list[i]
		var type: TowerType = TowerType.new()
		type.id = chk.ident(item, "id", path)
		type.name = chk.text(item, "name", path, 24)
		type.plural = chk.text(item, "plural", path, 24)
		type.info = chk.text(item, "info", path, 80)
		var kind_value: Variant = item.get("kind", "")
		if not DataCheck.is_string(kind_value) or not TOWER_KINDS.has(String(kind_value)):
			chk.fail(DataCheck.join(path, "kind"), "must be attack, slow, boost or fright")
			continue
		type.kind = StringName(String(kind_value))
		var tiers: Array = chk.array(item, "tiers", path, 2, 2)
		for t: int in tiers.size():
			type._tiers.append(_read_stats(tiers[t], "%s.tiers[%d]" % [path, t], type.kind, false, chk))
		var specs: Array = chk.array(item, "specs", path, 2, 2)
		for s: int in specs.size():
			var spec_path: String = "%s.specs[%d]" % [path, s]
			type._spec_stats.append(_read_stats(specs[s], spec_path, type.kind, true, chk))
			if typeof(specs[s]) != TYPE_DICTIONARY:
				continue
			var spec: Dictionary = specs[s]
			var spec_id: StringName = chk.ident(spec, "id", spec_path)
			if spec_id != &"" and spec_ids.has(spec_id):
				chk.fail(DataCheck.join(spec_path, "id"), "repeats %s" % spec_id)
			spec_ids[spec_id] = true
			type.specs.append(spec_id)
			type._spec_names.append(chk.text(spec, "name", spec_path, 24))
			type._spec_infos.append(chk.text(spec, "info", spec_path, 80))
		_check_attack_way(type, path, chk)
		if type.id == &"":
			continue
		if _towers.has(type.id):
			chk.fail(DataCheck.join(path, "id"), "repeats %s" % type.id)
			continue
		_towers[type.id] = type
		_tower_ids.append(type.id)


func _read_stats(data: Variant, path: String, kind: StringName, is_spec: bool, chk: DataCheck) -> TowerStats:
	var stats: TowerStats = TowerStats.new()
	var required: PackedStringArray = ["cost", "reach"]
	var optional: PackedStringArray = PackedStringArray()
	match kind:
		&"attack":
			required.append_array(["hits", "damage", "reload_ms"])
			optional.append_array(["splash", "targets", "pierce", "slow_pct", "slow_ms", "pulse", "line", "lure_ms"])
		&"slow":
			required.append_array(["hits", "slow_pct", "slow_ms"])
		&"boost":
			required.append("boost_pct")
			optional.append("boost_damage")
		&"fright":
			required.append_array(["hits", "fright_pct", "fright_ms"])
	if is_spec:
		required.append_array(["id", "name", "info"])
	if not chk.object(data, path, required, optional):
		return stats
	var item: Dictionary = data
	stats.cost = chk.integer(item, "cost", path, 10, 100000, 10)
	stats.reach = chk.integer(item, "reach", path, 1, 1000)
	if item.has("hits"):
		var hits: Variant = item["hits"]
		if not DataCheck.is_string(hits) or not HITS.has(String(hits)):
			chk.fail(DataCheck.join(path, "hits"), "must be ground, air or both")
		else:
			stats.hits_ground = String(hits) != "air"
			stats.hits_air = String(hits) != "ground"
	stats.damage = chk.integer(item, "damage", path, 1, 100000)
	stats.reload_ms = chk.integer(item, "reload_ms", path, 50, 60000, 50)
	stats.splash = chk.integer(item, "splash", path, 0, 500)
	stats.targets = chk.integer(item, "targets", path, 1, 3, 1, 1)
	stats.pierce = chk.boolean(item, "pierce", path)
	stats.slow_pct = chk.integer(item, "slow_pct", path, 1, 90)
	stats.slow_ms = chk.integer(item, "slow_ms", path, 50, 60000, 50)
	if item.has("slow_pct") != item.has("slow_ms"):
		chk.fail(path, "slow_pct and slow_ms come together")
	stats.boost_pct = chk.integer(item, "boost_pct", path, 0, 500)
	stats.boost_damage = chk.integer(item, "boost_damage", path, 0, 1000)
	stats.fright_pct = chk.integer(item, "fright_pct", path, 1, 1000)
	stats.fright_ms = chk.integer(item, "fright_ms", path, 50, 60000, 50)
	stats.pulse = chk.boolean(item, "pulse", path)
	stats.line = chk.integer(item, "line", path, 1, 500)
	stats.lure_ms = chk.integer(item, "lure_ms", path, 50, 60000, 50)
	# 14.4: one way of attacking at most, with no splash, and one target for pulses and lines.
	var ways: int = (1 if stats.pulse else 0) + (1 if stats.line > 0 else 0) + (1 if stats.lure_ms > 0 else 0)
	if ways > 1:
		chk.fail(path, "holds at most one of pulse, line and lure_ms")
	if ways > 0 and stats.splash > 0:
		chk.fail(path, "pulse, line and lure_ms come without splash")
	if (stats.pulse or stats.line > 0) and stats.targets > 1:
		chk.fail(path, "pulse and line come with one target")
	if stats.lure_ms > 0 and not (stats.hits_air and not stats.hits_ground):
		chk.fail(path, "lure_ms needs hits air")
	return stats


## 14.4: pulse, line and lure_ms are on every stat block of a tower or on none, so its
## way of attacking never changes with its tier.
static func _check_attack_way(type: TowerType, path: String, chk: DataCheck) -> void:
	var blocks: Array[TowerStats] = []
	blocks.append_array(type._tiers)
	blocks.append_array(type._spec_stats)
	if blocks.is_empty():
		return
	for block: TowerStats in blocks:
		if block.pulse != blocks[0].pulse or (block.line > 0) != (blocks[0].line > 0) \
				or (block.lure_ms > 0) != (blocks[0].lure_ms > 0):
			chk.fail(path, "pulse, line and lure_ms are on every stat block or on none")
			return


func _read_enemies(data: Variant, chk: DataCheck) -> void:
	if not chk.object(data, "", ["format", "enemies"]):
		return
	var top: Dictionary = data
	chk.integer(top, "format", "", FORMAT, FORMAT)
	var list: Array = chk.array(top, "enemies", "", 1, 64)
	var paths: Dictionary[StringName, String] = {}
	for i: int in list.size():
		var path: String = "enemies[%d]" % i
		if not chk.object(list[i], path, ENEMY_REQUIRED, ENEMY_OPTIONAL):
			continue
		var item: Dictionary = list[i]
		var type: EnemyType = EnemyType.new()
		type.id = chk.ident(item, "id", path)
		type.name = chk.text(item, "name", path, 24)
		type.info = chk.text(item, "info", path, 80)
		type.health = chk.integer(item, "health", path, 1, 1000000, 1, 1)
		type.armor = chk.integer(item, "armor", path, 0, 1000)
		type.speed = chk.integer(item, "speed", path, 1, 1000, 1, 1)
		type.lives = chk.integer(item, "lives", path, 1, 1000, 1, 1)
		type.bounty = chk.integer(item, "bounty", path, 1, 100000, 1, 1)
		type.flying = chk.boolean(item, "flying", path)
		type.boss = chk.boolean(item, "boss", path)
		type.bubble = chk.boolean(item, "bubble", path)
		type.heal = chk.integer(item, "heal", path, 1, 10000)
		type.heal_reach = chk.integer(item, "heal_reach", path, 1, 1000)
		type.heal_ms = chk.integer(item, "heal_ms", path, 50, 600000, 50)
		if item.has("heal") != item.has("heal_reach") or item.has("heal") != item.has("heal_ms"):
			chk.fail(path, "heal, heal_reach and heal_ms come together")
		type.split_into = chk.ident(item, "split_into", path)
		type.split_count = chk.integer(item, "split_count", path, 1, 10)
		type.split_gap_ms = chk.integer(item, "split_gap_ms", path, 50, 60000, 50)
		if item.has("split_into") != item.has("split_count") or item.has("split_into") != item.has("split_gap_ms"):
			chk.fail(path, "split_into, split_count and split_gap_ms come together")
		type.break_ms = chk.integer(item, "break_ms", path, 50, 600000, 50)
		_read_rules_of_regions_5_and_6(item, path, type, chk)
		_read_rules_of_regions_7_and_8(item, path, type, chk)
		if item.has("summon"):
			var summon_path: String = DataCheck.join(path, "summon")
			if chk.object(item["summon"], summon_path, ["enemy", "count", "every_ms", "gap_ms"]):
				var summon: Dictionary = item["summon"]
				type.summon = {
					"enemy": chk.ident(summon, "enemy", summon_path),
					"count": chk.integer(summon, "count", summon_path, 1, 20, 1, 1),
					"every_ms": chk.integer(summon, "every_ms", summon_path, 50, 600000, 50, 50),
					"gap_ms": chk.integer(summon, "gap_ms", summon_path, 50, 60000, 50, 50),
				}
		if item.has("speed_up"):
			var up_path: String = DataCheck.join(path, "speed_up")
			if chk.object(item["speed_up"], up_path, ["at_pct", "add"]):
				var up: Dictionary = item["speed_up"]
				var at_list: Array = chk.array(up, "at_pct", up_path, 1, 10)
				var at_pct: Array[int] = []
				for k: int in at_list.size():
					var pct: int = chk.whole(at_list[k], "%s.at_pct[%d]" % [up_path, k], 1, 99, 1, 1)
					if not at_pct.is_empty() and pct >= at_pct.back():
						chk.fail("%s.at_pct[%d]" % [up_path, k], "must be lower than the one before")
					at_pct.append(pct)
				type.speed_up = {"at_pct": at_pct, "add": chk.integer(up, "add", up_path, 1, 1000, 1, 1)}
		if item.has("release"):
			var rel_path: String = DataCheck.join(path, "release")
			if chk.object(item["release"], rel_path, ["at_pct", "enemy", "count", "gap_ms"]):
				var rel: Dictionary = item["release"]
				type.release = {
					"at_pct": chk.integer(rel, "at_pct", rel_path, 1, 99, 1, 1),
					"enemy": chk.ident(rel, "enemy", rel_path),
					"count": chk.integer(rel, "count", rel_path, 1, 20, 1, 1),
					"gap_ms": chk.integer(rel, "gap_ms", rel_path, 50, 60000, 50, 50),
				}
		if type.id == &"":
			continue
		if _enemies.has(type.id):
			chk.fail(DataCheck.join(path, "id"), "repeats %s" % type.id)
			continue
		_enemies[type.id] = type
		_enemy_ids.append(type.id)
		paths[type.id] = path
	# Cross references, once every id is known. A released creature never releases
	# others itself, so releases cannot chain, and a flyer releases only flyers
	# (a walker needs a road step to start from, RULES 6.2). So does a gate breaker: it
	# walks the route with no gates, where a released walker could have no open way on.
	# A summoned creature never heals.
	for id: StringName in _enemy_ids:
		var type: EnemyType = _enemies[id]
		var path: String = paths[id]
		if type.split_into != &"":
			_check_released(type, type.split_into, DataCheck.join(path, "split_into"), chk)
		if not type.summon.is_empty():
			_check_released(type, type.summon["enemy"], DataCheck.join(path, "summon.enemy"), chk)
			# Summons come for as long as the boss lives, so a save could not bound
			# the healers they bring (Battle.MAX_HEALERS).
			var summoned: EnemyType = _enemies.get(type.summon["enemy"], null)
			if summoned != null and summoned.heal > 0:
				chk.fail(DataCheck.join(path, "summon.enemy"), "a summoned creature cannot heal")
			# The same for wakers (Battle.MAX_WAKERS, docs/ARCHITECTURE.md 14.4).
			if summoned != null and summoned.wake_reach > 0:
				chk.fail(DataCheck.join(path, "summon.enemy"), "a summoned creature cannot wake others")
		if not type.release.is_empty():
			_check_released(type, type.release["enemy"], DataCheck.join(path, "release.enemy"), chk)


## docs/ARCHITECTURE.md 14.4: regrow, mist, dazzle, nap and dig (RULES 6.2, 6.3).
static func _read_rules_of_regions_5_and_6(item: Dictionary, path: String, type: EnemyType, chk: DataCheck) -> void:
	type.regrow = chk.integer(item, "regrow", path, 1, 10000)
	type.regrow_ms = chk.integer(item, "regrow_ms", path, 50, 600000, 50)
	if item.has("regrow") != item.has("regrow_ms"):
		chk.fail(path, "regrow and regrow_ms come together")
	type.mist = chk.boolean(item, "mist", path)
	type.dazzle = chk.boolean(item, "dazzle", path)
	type.nap_ms = chk.integer(item, "nap_ms", path, 50, 60000, 50)
	type.dig_first_ms = chk.integer(item, "dig_first_ms", path, 50, 600000, 50)
	type.dig_every_ms = chk.integer(item, "dig_every_ms", path, 50, 600000, 50)
	type.dig_ms = chk.integer(item, "dig_ms", path, 50, 60000, 50)
	var digs: int = (1 if item.has("dig_first_ms") else 0) + (1 if item.has("dig_every_ms") else 0) + (1 if item.has("dig_ms") else 0)
	if digs != 0 and digs != 3:
		chk.fail(path, "dig_first_ms, dig_every_ms and dig_ms come together")
	if type.dig_ms > 0 and type.dig_every_ms > 0 and type.dig_ms >= type.dig_every_ms:
		chk.fail(DataCheck.join(path, "dig_ms"), "must be below dig_every_ms")
	if digs > 0 and type.flying:
		chk.fail(path, "only walkers dig")


## docs/ARCHITECTURE.md 14.4: grow, yawn, blink and wake (RULES 6.2, 6.3).
static func _read_rules_of_regions_7_and_8(item: Dictionary, path: String, type: EnemyType, chk: DataCheck) -> void:
	type.grow_pct = chk.integer(item, "grow_pct", path, 1, 100)
	type.grow_cap_pct = chk.integer(item, "grow_cap_pct", path, 101, 1000)
	if item.has("grow_pct") != item.has("grow_cap_pct"):
		chk.fail(path, "grow_pct and grow_cap_pct come together")
	if item.has("grow_pct") and type.flying:
		chk.fail(path, "only walkers grow")
	type.yawn_ms = chk.integer(item, "yawn_ms", path, 50, 600000, 50)
	type.yawn_reach = chk.integer(item, "yawn_reach", path, 1, 1000)
	type.doze_ms = chk.integer(item, "doze_ms", path, 50, 60000, 50)
	var yawns: int = (1 if item.has("yawn_ms") else 0) + (1 if item.has("yawn_reach") else 0) + (1 if item.has("doze_ms") else 0)
	if yawns != 0 and yawns != 3:
		chk.fail(path, "yawn_ms, yawn_reach and doze_ms come together")
	type.blink_ms = chk.integer(item, "blink_ms", path, 50, 600000, 50)
	type.blink_tiles = chk.integer(item, "blink_tiles", path, 1, 10)
	if item.has("blink_ms") != item.has("blink_tiles"):
		chk.fail(path, "blink_ms and blink_tiles come together")
	if item.has("blink_ms") and type.flying:
		chk.fail(path, "only walkers blink")
	type.wake_reach = chk.integer(item, "wake_reach", path, 1, 1000)
	# A napping creature does nothing (DM, 2026-10-27), so no creature naps and also heals or digs.
	var digs: bool = item.has("dig_ms") or item.has("dig_first_ms") or item.has("dig_every_ms")
	if item.has("nap_ms") and (item.has("heal") or digs):
		chk.fail(path, "a creature that naps cannot heal or dig")


func _check_released(releaser: EnemyType, id: StringName, path: String, chk: DataCheck) -> void:
	if id == &"":
		return
	var released: EnemyType = _enemies.get(id, null)
	if released == null:
		chk.fail(path, "names no creature")
		return
	if released.id == releaser.id:
		chk.fail(path, "cannot release itself")
		return
	if released.split_into != &"" or not released.summon.is_empty() or not released.release.is_empty():
		chk.fail(path, "a released creature cannot release others")
	if released.boss:
		chk.fail(path, "a boss cannot be released")
	if releaser.flying and not released.flying:
		chk.fail(path, "a flyer can release only flyers")
	if releaser.break_ms > 0 and not released.flying:
		chk.fail(path, "a gate breaker can release only flyers")


func _read_rules(data: Variant, chk: DataCheck) -> void:
	if not chk.object(data, "", RULE_KEYS):
		return
	var top: Dictionary = data
	var r: GameRules = GameRules.new()
	chk.integer(top, "format", "", FORMAT, FORMAT)
	r.start_lives = chk.integer(top, "start_lives", "", 1, 1000, 1, 1)
	r.relaxed_lives_pct = chk.integer(top, "relaxed_lives_pct", "", 100, 1000, 1, 100)
	r.relaxed_gold_pct = chk.integer(top, "relaxed_gold_pct", "", 100, 1000, 1, 100)
	r.refund_pct = chk.integer(top, "refund_pct", "", 0, 100)
	r.early_bonus_pct = chk.integer(top, "early_bonus_pct", "", 0, 100)
	r.clear_bonus = chk.integer(top, "clear_bonus", "", 0, 10000)
	r.clear_bonus_per_wave = chk.integer(top, "clear_bonus_per_wave", "", 0, 1000)
	r.star2_lives = chk.integer(top, "star2_lives", "", 1, r.start_lives, 1, 1)
	r.max_waves_running = chk.integer(top, "max_waves_running", "", 1, 10, 1, 1)
	r.max_gates = chk.integer(top, "max_gates", "", 0, 8)
	r.bubble_ms = chk.integer(top, "bubble_ms", "", 50, 60000, 50, 50)
	var stars: Array = chk.array(top, "region_stars", "", 1, 8)
	for i: int in stars.size():
		var count: int = chk.whole(stars[i], "region_stars[%d]" % i, 0, 1000)
		if not r.region_stars.is_empty() and count < r.region_stars.back():
			chk.fail("region_stars[%d]" % i, "must not be lower than the one before")
		r.region_stars.append(count)
	r.run_stars = chk.integer(top, "run_stars", "", 0, 1000)
	rules = r
