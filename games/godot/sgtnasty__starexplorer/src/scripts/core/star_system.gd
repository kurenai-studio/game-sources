# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name StarSystem
extends RefCounted
## A star system's planets, generated deterministically from the galaxy
## seed and the star's id, so a revisited system is always the same.

const ROMAN: Array[String] = ["I", "II", "III", "IV", "V", "VI"]

var id := 0
var system_name := ""
var star_class := "G"
var has_starbase := false
var danger := 0
var planets: Array[Planet] = []


static func generate(star: Dictionary, galaxy_seed: int) -> StarSystem:
	var sys := StarSystem.new()
	sys.id = star["id"]
	sys.system_name = star["name"]
	sys.star_class = star["cls"]
	sys.has_starbase = star["starbase"]
	sys.danger = star["danger"]

	var rng := RandomNumberGenerator.new()
	rng.seed = hash([galaxy_seed, sys.id, "system"])
	var count := rng.randi_range(2, 5)
	for i in count:
		var p := Planet.new()
		p.index = i
		p.planet_name = "%s %s" % [sys.system_name, ROMAN[i]]
		p.type = _weighted_pick(Planet.TYPE_WEIGHTS, rng)
		var weights: Dictionary = Planet.TYPES[p.type]["res"]
		for res in weights:
			var w: int = weights[res]
			if rng.randf() > 0.25 + 0.12 * w:
				continue
			var diff := ResourceDB.difficulty(res) + rng.randi_range(0, 1)
			var amount := int(rng.randi_range(6, 10 + 3 * w) * (1.0 - 0.15 * diff))
			p.deposits.append({"res": res, "amount": maxi(amount, 3), "difficulty": diff})
		sys.planets.append(p)
	if star.get("home", false):
		_seed_home(sys)
	return sys


## The home system always offers iron and hydrogen a new captain can see,
## so the first mining run never comes up empty.
static func _seed_home(sys: StarSystem) -> void:
	var rocky := sys.planets[0]
	rocky.type = "rocky"
	rocky.deposits = [{"res": "iron", "amount": 18, "difficulty": 0}, {"res": "uranium", "amount": 8, "difficulty": 2}]
	var giant := sys.planets[1]
	giant.type = "gas_giant"
	giant.deposits = [{"res": "hydrogen", "amount": 20, "difficulty": 0}, {"res": "exotic", "amount": 3, "difficulty": 4}]


static func _weighted_pick(weights: Dictionary, rng: RandomNumberGenerator) -> String:
	var total := 0
	for k in weights:
		total += weights[k]
	var roll := rng.randi_range(1, total)
	for k in weights:
		roll -= weights[k]
		if roll <= 0:
			return k
	return weights.keys()[0]
