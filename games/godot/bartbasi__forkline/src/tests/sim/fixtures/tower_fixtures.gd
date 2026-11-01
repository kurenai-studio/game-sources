# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
extends RefCounted
## The four expansion towers as test data, with the numbers of RULES 5.12 to 5.15, added
## to the real stat files. data/stats/ gets them in E5.1 (game designer); until then the
## rules are proven on this test-only catalog (docs/ARCHITECTURE.md 14.4).

const Fx: GDScript = preload("res://tests/sim/fixtures/sim_fixtures.gd")

const ALL: Array = [
	"sling_post", "pumpkin_catapult", "lullaby_bell", "longbow_loft", "firework_tower", "bakery",
	"bramble_cottage", "scarecrow", "snow_fort", "moth_lantern",
]


static func _block(cost: int, reach: int, extra: Dictionary) -> Dictionary:
	var out: Dictionary = {"cost": cost, "reach": reach}
	out.merge(extra)
	return out


static func _spec(id: String, name: String, block: Dictionary) -> Dictionary:
	var out: Dictionary = {"id": id, "name": name, "info": "A test path."}
	out.merge(block)
	return out


## RULES 5.12 to 5.15, in the file's units.
static func towers() -> Array:
	var bramble: Callable = func(damage: int) -> Dictionary:
		return {"hits": "ground", "damage": damage, "reload_ms": 1000, "pulse": true}
	var fright: Callable = func(pct: int, hits: String) -> Dictionary:
		return {"hits": hits, "fright_pct": pct, "fright_ms": 1000}
	var snow: Callable = func(damage: int, reload: int, line: int) -> Dictionary:
		return {"hits": "ground", "damage": damage, "reload_ms": reload, "line": line}
	var lantern: Callable = func(damage: int, lure: int) -> Dictionary:
		return {"hits": "air", "damage": damage, "reload_ms": 1000, "lure_ms": lure}
	var holly: Dictionary = bramble.call(12)
	holly["pierce"] = true
	var garland: Dictionary = lantern.call(6, 3000)
	garland["targets"] = 3
	return [
		{"id": "bramble_cottage", "name": "Bramble Cottage", "plural": "Bramble Cottages", "info": "Thorns.", "kind": "attack",
			"tiers": [_block(120, 150, bramble.call(4)), _block(130, 150, bramble.call(7))],
			"specs": [_spec("wild_bramble", "Wild Bramble", _block(230, 200, bramble.call(10))),
				_spec("holly_crown", "Holly Crown", _block(230, 150, holly))]},
		{"id": "scarecrow", "name": "Scarecrow", "plural": "Scarecrows", "info": "Frights.", "kind": "fright",
			"tiers": [_block(100, 200, fright.call(15, "ground")), _block(100, 250, fright.call(25, "ground"))],
			"specs": [_spec("tall_scarecrow", "Tall Scarecrow", _block(190, 250, fright.call(40, "ground"))),
				_spec("crow_keeper", "Crow Keeper", _block(190, 300, fright.call(25, "both")))]},
		{"id": "snow_fort", "name": "Snow Fort", "plural": "Snow Forts", "info": "Snowballs.", "kind": "attack",
			"tiers": [_block(140, 300, snow.call(16, 3000, 80)), _block(150, 350, snow.call(28, 3000, 80))],
			"specs": [_spec("big_snowball", "Big Snowball", _block(260, 400, snow.call(64, 3500, 100))),
				_spec("flurry", "Flurry", _block(260, 350, snow.call(24, 1500, 80)))]},
		{"id": "moth_lantern", "name": "Moth Lantern", "plural": "Moth Lanterns", "info": "Lures.", "kind": "attack",
			"tiers": [_block(110, 300, lantern.call(4, 2000)), _block(110, 350, lantern.call(6, 3000))],
			"specs": [_spec("beacon_lantern", "Beacon Lantern", _block(200, 450, lantern.call(8, 4000))),
				_spec("lantern_garland", "Lantern Garland", _block(200, 350, garland))]},
	]


## The real stat files with the four towers added. A tower the real files already hold
## (from E5.1 on) gives way to this file's copy, so these tests keep their own numbers.
static func stats_files() -> Array:
	var files: Array = Fx.stats_files()
	files[0]["towers"] = replaced(files[0]["towers"], towers())
	return files


## `list` without the items whose ids `mine` holds, then `mine`.
static func replaced(list: Array, mine: Array) -> Array:
	var ids: Array = []
	for item: Dictionary in mine:
		ids.append(item["id"])
	var out: Array = []
	for item: Variant in list:
		if not (item is Dictionary and ids.has((item as Dictionary).get("id", ""))):
			out.append(item)
	out.append_array(mine)
	return out


static func catalog() -> Catalog:
	var files: Array = stats_files()
	return Catalog.from_data(files[0], files[1], files[2])


## A catalog with one new tower's stat block changed: tiers 0 and 1, then specs 0 and 1,
## as index 0 to 3.
static func catalog_with(id: String, index: int, changes: Dictionary) -> Catalog:
	var files: Array = stats_files()
	for item: Dictionary in files[0]["towers"]:
		if item["id"] == id:
			var block: Dictionary = item["tiers"][index] if index < 2 else item["specs"][index - 2]
			block.merge(changes, true)
	return Catalog.from_data(files[0], files[1], files[2])


## A battle offering every tower, old and new.
static func battle(grid: Array, waves: Array, changes: Dictionary = {}, stats: Catalog = null) -> Battle:
	var all: Dictionary = {"towers": ALL, "start_gold": 100000}
	all.merge(changes, true)
	return Fx.battle(grid, waves, all, stats if stats != null else catalog())


## Places a tower and takes it to `tier` (spec at tier 3). Returns the tower.
static func build(b: Battle, cell: Vector2i, type: StringName, tier: int = 1, spec: int = -1) -> TowerState:
	if b.place_tower(cell, type) != Battle.DONE:
		return null
	if tier >= 2:
		b.upgrade_tower(cell)
	if tier >= 3:
		b.upgrade_tower(cell, spec)
	return b.tower_at(cell)
