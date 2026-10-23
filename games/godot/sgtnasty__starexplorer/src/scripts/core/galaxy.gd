# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name Galaxy
extends RefCounted
## The procedurally generated star map.
##
## Only the seed is saved: stars and systems are regenerated from it, and the
## two pieces of mutable state (mined-out deposits and scan results) are
## stored as small dictionaries layered on top.

const WIDTH := 400.0
const HEIGHT := 240.0
const STAR_COUNT := 60
const MIN_SPACING := 22.0
## Every new star is placed within LINK_MAX of an existing one, so the map is
## always connected for a ship whose jump range >= LINK_MAX.
const LINK_MAX := 56.0
const STARBASE_CHANCE := 0.2
const MARGIN := 10.0

const STAR_CLASS_WEIGHTS := {"M": 30, "K": 25, "G": 20, "F": 12, "A": 8, "B": 5}
const STAR_COLORS := {
	"M": "#ff6b4a", "K": "#ffa34a", "G": "#ffec6e",
	"F": "#fff6d8", "A": "#d8ecff", "B": "#8ab8ff",
}

const NAME_START: Array[String] = [
	"Al", "Bel", "Cor", "Dra", "El", "Fen", "Gal", "Hy", "Ix", "Jor", "Kal",
	"Lyr", "Mor", "Nex", "Or", "Pra", "Qua", "Ras", "Sol", "Tau", "Ul", "Vey",
	"Wex", "Xan", "Yor", "Zeph",
]
const NAME_MID: Array[String] = ["", "", "a", "e", "i", "o", "ar", "en", "or", "ia", "ul"]
const NAME_END: Array[String] = [
	"is", "on", "ar", "ux", "a", "os", "eth", "ion", "ara", "ix", "um", "ae", "or",
]

var galaxy_seed := 0
var start_star := 0
## Each star: {"id", "name", "pos": Vector2, "cls", "starbase": bool, "danger": int}
var stars: Array[Dictionary] = []
## "star:planet:deposit" -> units already extracted
var depleted: Dictionary = {}
## "star:planet" -> science skill the planet was scanned with
var scanned: Dictionary = {}
var _systems: Dictionary = {}


func generate(seed_value: int) -> void:
	galaxy_seed = seed_value
	stars.clear()
	_systems.clear()
	depleted.clear()
	scanned.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var used_names := {}

	_add_star(Vector2(MARGIN + 14.0, HEIGHT * 0.5), rng, used_names)
	var attempts := 0
	while stars.size() < STAR_COUNT and attempts < 20000:
		attempts += 1
		var parent: Dictionary = stars[rng.randi_range(0, stars.size() - 1)]
		var offset := Vector2.from_angle(rng.randf() * TAU) * rng.randf_range(MIN_SPACING + 2.0, LINK_MAX)
		var pos: Vector2 = parent["pos"] + offset
		if pos.x < MARGIN or pos.y < MARGIN or pos.x > WIDTH - MARGIN or pos.y > HEIGHT - MARGIN:
			continue
		if _too_close(pos):
			continue
		_add_star(pos, rng, used_names)

	start_star = 0
	stars[0]["starbase"] = true
	stars[0]["home"] = true
	stars[0]["cls"] = "G"
	var home: Vector2 = stars[0]["pos"]
	for s in stars:
		s["danger"] = clampi(int(home.distance_to(s["pos"]) / 75.0), 0, 4)


func _add_star(pos: Vector2, rng: RandomNumberGenerator, used_names: Dictionary) -> void:
	var star_name := _make_name(rng)
	while used_names.has(star_name):
		star_name = _make_name(rng)
	used_names[star_name] = true
	stars.append({
		"id": stars.size(),
		"name": star_name,
		"pos": pos,
		"cls": StarSystem._weighted_pick(STAR_CLASS_WEIGHTS, rng),
		"starbase": rng.randf() < STARBASE_CHANCE,
		"danger": 0,
	})


func _too_close(pos: Vector2) -> bool:
	for s in stars:
		if pos.distance_to(s["pos"]) < MIN_SPACING:
			return true
	return false


func _make_name(rng: RandomNumberGenerator) -> String:
	return (NAME_START[rng.randi() % NAME_START.size()]
		+ NAME_MID[rng.randi() % NAME_MID.size()]
		+ NAME_END[rng.randi() % NAME_END.size()])


func star(id: int) -> Dictionary:
	return stars[id]


func star_color(id: int) -> Color:
	return Color(STAR_COLORS[stars[id]["cls"]])


func distance(a: int, b: int) -> float:
	return (stars[a]["pos"] as Vector2).distance_to(stars[b]["pos"])


## Stars within `jump_range` of `from`, nearest first.
func reachable_from(from: int, jump_range: float) -> Array[int]:
	var out: Array[int] = []
	for s in stars:
		var id: int = s["id"]
		if id != from and distance(from, id) <= jump_range:
			out.append(id)
	out.sort_custom(func(a: int, b: int) -> bool: return distance(from, a) < distance(from, b))
	return out


func nearest_starbase(from: int) -> int:
	var best := start_star
	var best_d := INF
	for s in stars:
		if s["starbase"] and distance(from, s["id"]) < best_d:
			best_d = distance(from, s["id"])
			best = s["id"]
	return best


func get_system(id: int) -> StarSystem:
	if not _systems.has(id):
		var sys := StarSystem.generate(stars[id], galaxy_seed)
		for p in sys.planets:
			for d in p.deposits.size():
				var key := "%d:%d:%d" % [id, p.index, d]
				if depleted.has(key):
					p.deposits[d]["amount"] = maxi(0, p.deposits[d]["amount"] - int(depleted[key]))
		_systems[id] = sys
	return _systems[id]


## Removes up to `qty` units from a deposit and returns how many came out.
func extract(star_id: int, planet: Planet, deposit_index: int, qty: int) -> int:
	var dep: Dictionary = planet.deposits[deposit_index]
	var taken := mini(qty, dep["amount"])
	dep["amount"] -= taken
	var key := "%d:%d:%d" % [star_id, planet.index, deposit_index]
	depleted[key] = int(depleted.get(key, 0)) + taken
	return taken


func scan_level(star_id: int, planet: Planet) -> int:
	return int(scanned.get("%d:%d" % [star_id, planet.index], -1))


func is_scanned(star_id: int, planet: Planet) -> bool:
	return scan_level(star_id, planet) >= 0


func mark_scanned(star_id: int, planet: Planet, science: int) -> void:
	scanned["%d:%d" % [star_id, planet.index]] = maxi(science, scan_level(star_id, planet))


## A deposit shows up if the planet was scanned with enough science skill.
func deposit_visible(star_id: int, planet: Planet, deposit_index: int) -> bool:
	return planet.deposits[deposit_index]["difficulty"] <= scan_level(star_id, planet)


func to_dict() -> Dictionary:
	return {"seed": galaxy_seed, "depleted": depleted.duplicate(), "scanned": scanned.duplicate()}


func from_dict(d: Dictionary) -> void:
	generate(int(d.get("seed", 1)))
	depleted = d.get("depleted", {})
	scanned = d.get("scanned", {})
