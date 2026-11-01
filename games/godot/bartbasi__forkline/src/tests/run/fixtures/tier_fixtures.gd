# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## Fixtures for the content tiers (docs/ARCHITECTURE.md 14.8). These build their own tiers on
## the stats of regions 1 to 4 only (Fx.REGIONS_1_TO_4): clones of real towers and creatures
## under the ids the real tiers use, run.json tiers that list them, cards, segments with the
## map features T, X, the slide arrows and the stumps P and Q, and packs that use them. A real region added later
## never reaches these, so they stay as they are. Every fixture here is valid. A test copies
## one with duplicate(true) and breaks one thing.
##
## Tier 1: tower bramble_cottage, creatures mossbud and mistwisp, boss burrowbelly, feature T.
## Tier 2: tower scarecrow, creature gleamer, boss old_hayrick, feature X.
## Tier 3: tower snow_fort, creatures snowroller and yawner, boss snowsnore, features ^v<>.
## Tier 4: tower moth_lantern, creatures blinker and hootling, boss glimmertoad, features PQ.

const Fx: GDScript = preload("res://tests/run/fixtures/run_fixtures.gd")

const TIER_1_TOWER: String = "bramble_cottage"
const TIER_2_TOWER: String = "scarecrow"
const TIER_3_TOWER: String = "snow_fort"
const TIER_4_TOWER: String = "moth_lantern"


static func _clone(item: Dictionary, id: String, name: String) -> Dictionary:
	var out: Dictionary = item.duplicate(true)
	out["id"] = id
	out["name"] = name
	return out


## The real stats plus the stand-in towers and creatures. mutate (optional) takes
## {"towers": Dictionary, "enemies": Dictionary, "rules": Dictionary} as plain values and may change them.
static func catalog(mutate: Callable = Callable()) -> Catalog:
	var towers: Dictionary = Fx.read(Fx.STATS_DIR + "towers.json")
	var enemies: Dictionary = Fx.read(Fx.STATS_DIR + "enemies.json")
	var rules: Dictionary = Fx.read(Fx.STATS_DIR + "rules.json")
	# Only regions 1 to 4 are kept. The stand-ins below take the ids the real tiers use.
	var kept: Array[String] = Fx.REGIONS_1_TO_4
	towers["towers"] = (towers["towers"] as Array).filter(func(item: Dictionary) -> bool: return kept.has(item["id"]))
	enemies["enemies"] = (enemies["enemies"] as Array).filter(func(item: Dictionary) -> bool: return kept.has(item["id"]))
	var sling: Dictionary = {}
	for item: Dictionary in towers["towers"]:
		if item["id"] == "sling_post":
			sling = item
	for pair: Array in [[TIER_1_TOWER, "Bramble Cottage", "bc"], [TIER_2_TOWER, "Scarecrow", "sc"], [TIER_3_TOWER, "Snow Fort", "sf"], [TIER_4_TOWER, "Moth Lantern", "ml"]]:
		var copy: Dictionary = _clone(sling, pair[0], pair[1])
		copy["plural"] = pair[1] + "s"
		for i: int in 2:
			copy["specs"][i]["id"] = "%s_path_%d" % [pair[2], i]
		towers["towers"].append(copy)
	var by_id: Dictionary = {}
	for item: Dictionary in enemies["enemies"]:
		by_id[item["id"]] = item
	var extra: Array = [
		_clone(by_id["scamp"], "mossbud", "Mossbud"),
		_clone(by_id["flitter"], "mistwisp", "Mistwisp"),
		_clone(by_id["pip"], "gleamer", "Gleamer"),
		_clone(by_id["grumblesack"], "burrowbelly", "Burrowbelly"),
		_clone(by_id["ironshell"], "old_hayrick", "Old Hayrick"),
		_clone(by_id["scamp"], "snowroller", "Snowroller"),
		_clone(by_id["pip"], "yawner", "Yawner"),
		_clone(by_id["ironshell"], "snowsnore", "Snowsnore"),
		_clone(by_id["scamp"], "blinker", "Blinker"),
		_clone(by_id["pip"], "hootling", "Hootling"),
		_clone(by_id["ironshell"], "glimmertoad", "Glimmertoad"),
	]
	extra[3]["summon"]["enemy"] = "mistwisp"
	for item: Dictionary in extra:
		enemies["enemies"].append(item)
	var all: Dictionary = {"towers": towers, "enemies": enemies, "rules": rules}
	if mutate.is_valid():
		mutate.call(all)
	var parsed_towers: Variant = JSON.parse_string(JSON.stringify(all["towers"]))
	var parsed_enemies: Variant = JSON.parse_string(JSON.stringify(all["enemies"]))
	var parsed_rules: Variant = JSON.parse_string(JSON.stringify(all["rules"]))
	return Catalog.from_data(parsed_towers, parsed_enemies, parsed_rules)


static func tiers() -> Array:
	return [
		{"level": "r5_l6", "towers": [TIER_1_TOWER], "creatures": ["mossbud", "mistwisp"], "bosses": ["burrowbelly"], "grid": "T"},
		{"level": "r6_l6", "towers": [TIER_2_TOWER], "creatures": ["gleamer"], "bosses": ["old_hayrick"], "grid": "X"},
		{"level": "r7_l6", "towers": [TIER_3_TOWER], "creatures": ["snowroller", "yawner"], "bosses": ["snowsnore"], "grid": "^v<>"},
		{"level": "r8_l6", "towers": [TIER_4_TOWER], "creatures": ["blinker", "hootling"], "bosses": ["glimmertoad"], "grid": "PQ"},
	]


static func run_plan() -> Dictionary:
	var plan: Dictionary = Fx.run_plan()
	plan["tiers"] = tiers()
	return plan


static func _replace_cell(rows: Array, row: int, col: int, ch: String) -> Array:
	var out: Array = rows.duplicate()
	var line: String = out[row]
	out[row] = line.substr(0, col) + ch + line.substr(col + 1)
	return out


## Extra segments, in the file shape: a tier 1 middle with a tunnel, a tier 2 middle with a
## bridge, a tier 3 middle with an ice slide and a tier 4 middle with a pair of stumps. All are
## mid_split with road cells changed, so their ports are its ports, every top and bottom that
## fits it fits them, and the road still leads from entrance to base. The stumps are a pair in
## the middle rows, never neighbors (a stump segment holds one pair).
static func segments() -> Dictionary:
	var split: Array = Fx.SEGMENTS["mid_split"][1]
	return {
		"mid_tunnel": ["middle", _replace_cell(split, 4, 3, "T")],
		"mid_bridge": ["middle", _replace_cell(split, 0, 3, "X")],
		"mid_slide": ["middle", _replace_cell(split, 4, 3, "v")],
		"mid_stumps": ["middle", _replace_cell(_replace_cell(split, 1, 1, "P"), 1, 3, "P")],
	}


## The fixture index order with the four tier segments in the middle of it.
static func index_order() -> Array:
	var out: Array = Fx.INDEX_ORDER.duplicate()
	out.insert(out.find("mid_split") + 1, "mid_tunnel")
	out.insert(out.find("mid_bend") + 1, "mid_bridge")
	out.insert(out.find("mid_side") + 1, "mid_slide")
	out.insert(out.find("mid_merge") + 1, "mid_stumps")
	return out


static func _pack(files: Dictionary, id: String) -> Dictionary:
	for item: Variant in files["segments/packs.json"]["packs"]:
		if (item as Dictionary)["id"] == id:
			return item
	return {}


## Packs that use the stand-ins, put first in the file: a tier 1 pack for band 2, a tier 2 pack
## and a Snowroller pack for band 3, a Yawner pack for band 4, a Blinker pack for bands 3 and 4, a
## Hootling pack for band 5, and a band 6 pack for each new boss.
static func packs() -> Dictionary:
	var base: Dictionary = Fx.packs()
	var files: Dictionary = {"segments/packs.json": base}
	var made: Array = []
	var one: Dictionary = (_pack(files, "band2_pack0")).duplicate(true)
	one["id"] = "band2_mossbud"
	one["waves"][1]["groups"][0]["enemy"] = "mossbud"
	made.append(one)
	var two: Dictionary = (_pack(files, "band3_pack0")).duplicate(true)
	two["id"] = "band3_gleamer"
	two["waves"][1]["groups"][0]["enemy"] = "gleamer"
	made.append(two)
	var burrow: Dictionary = (_pack(files, "band6_pack0")).duplicate(true)
	burrow["id"] = "band6_burrowbelly"
	burrow["boss"] = "burrowbelly"
	burrow["waves"][2]["groups"][0]["enemy"] = "burrowbelly"
	made.append(burrow)
	var hayrick: Dictionary = (_pack(files, "band6_pack1")).duplicate(true)
	hayrick["id"] = "band6_hayrick"
	hayrick["boss"] = "old_hayrick"
	hayrick["waves"][2]["groups"][0]["enemy"] = "old_hayrick"
	made.append(hayrick)
	var roller: Dictionary = (_pack(files, "band3_pack1")).duplicate(true)
	roller["id"] = "band3_snowroller"
	roller["waves"][1]["groups"][0]["enemy"] = "snowroller"
	made.append(roller)
	var yawner: Dictionary = (_pack(files, "band4_pack0")).duplicate(true)
	yawner["id"] = "band4_yawner"
	yawner["waves"][1]["groups"][0]["enemy"] = "yawner"
	made.append(yawner)
	var snore: Dictionary = (_pack(files, "band6_pack2")).duplicate(true)
	snore["id"] = "band6_snowsnore"
	snore["boss"] = "snowsnore"
	snore["waves"][2]["groups"][0]["enemy"] = "snowsnore"
	made.append(snore)
	var blink3: Dictionary = (_pack(files, "band3_pack2")).duplicate(true)
	blink3["id"] = "band3_blinker"
	blink3["waves"][1]["groups"][0]["enemy"] = "blinker"
	made.append(blink3)
	var blink4: Dictionary = (_pack(files, "band4_pack1")).duplicate(true)
	blink4["id"] = "band4_blinker"
	blink4["waves"][1]["groups"][0]["enemy"] = "blinker"
	made.append(blink4)
	var hoot: Dictionary = (_pack(files, "band5_pack0")).duplicate(true)
	hoot["id"] = "band5_hootling"
	hoot["waves"][1]["groups"][0]["enemy"] = "hootling"
	made.append(hoot)
	var glimmer: Dictionary = (_pack(files, "band6_pack3")).duplicate(true)
	glimmer["id"] = "band6_glimmertoad"
	glimmer["boss"] = "glimmertoad"
	glimmer["waves"][2]["groups"][0]["enemy"] = "glimmertoad"
	made.append(glimmer)
	var all: Array = made.duplicate()
	all.append_array(base["packs"])
	return {"format": 1, "packs": all}


static func cards() -> Dictionary:
	var out: Dictionary = Fx.cards()
	var list: Array = out["cards"]
	# Between the fixture's own cards, so file order is tested too.
	list.insert(1, Fx.tower_card(TIER_1_TOWER, "Bramble Cottage"))
	list.insert(3, Fx.tower_card(TIER_2_TOWER, "Scarecrow"))
	list.insert(7, {"id": "thorn_tips", "kind": "perk", "tower": TIER_1_TOWER, "name": "Thorn Tips",
		"text": "Bramble Cottages deal 2 more damage.", "once": true, "unlock": {},
		"effects": [{"type": "tower_add", "tower": TIER_1_TOWER, "stat": "damage", "amount": 2}]})
	list.insert(8, {"id": "straw_hats", "kind": "perk", "tower": TIER_2_TOWER, "name": "Straw Hats",
		"text": "Scarecrows reach further.", "once": true, "unlock": {"counter": "stars", "at": 10},
		"effects": [{"type": "tower_add", "tower": TIER_2_TOWER, "stat": "reach", "amount": 50},
			{"type": "tower_add", "tower": TIER_2_TOWER, "stat": "damage", "amount": -1}]})
	list.insert(5, Fx.tower_card(TIER_3_TOWER, "Snow Fort"))
	list.insert(12, {"id": "packed_snow", "kind": "perk", "tower": TIER_3_TOWER, "name": "Packed Snow",
		"text": "Snow Forts deal 4 more damage.", "once": true, "unlock": {},
		"effects": [{"type": "tower_add", "tower": TIER_3_TOWER, "stat": "damage", "amount": 4}]})
	list.insert(7, Fx.tower_card(TIER_4_TOWER, "Moth Lantern"))
	list.insert(15, {"id": "bright_wick", "kind": "perk", "tower": TIER_4_TOWER, "name": "Bright Wick",
		"text": "Moth Lanterns reach 1 tile further.", "once": true, "unlock": {},
		"effects": [{"type": "tower_add", "tower": TIER_4_TOWER, "stat": "reach", "amount": 100}]})
	return out


## All parsed files after a trip through the JSON parser, with the tiers.
static func files() -> Dictionary:
	var out: Dictionary = {
		"runs/run.json": run_plan(), "cards/cards.json": cards(),
		"segments/index.json": {"format": 1, "segments": index_order()},
		"segments/packs.json": packs(),
	}
	var extra: Dictionary = segments()
	for id: String in index_order():
		if extra.has(id):
			var item: Array = extra[id]
			out["segments/%s.json" % id] = {"format": 1, "id": id, "kind": item[0], "grid": (item[1] as Array).duplicate()}
		else:
			out["segments/%s.json" % id] = Fx.segment(id)
	var parsed: Dictionary = {}
	for key: String in out.keys():
		parsed[key] = JSON.parse_string(JSON.stringify(out[key]))
	return parsed


static func run_data() -> RunData:
	return RunData.from_data(files(), catalog())
