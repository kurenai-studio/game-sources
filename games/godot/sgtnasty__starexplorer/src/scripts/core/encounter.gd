# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name Encounter
extends RefCounted
## A random meeting with another ship (or creature) and its combat stats.
##
## Kinds: "pirate", "trader", "patrol", "monster". Stats scale with the
## danger level of the system (0 near home .. 4 at the far rim).

const KINDS: Array[String] = ["pirate", "trader", "patrol", "monster"]

const PIRATE_NAMES: Array[String] = ["Rust Fang", "Black Comet", "Grinning Skull", "Red Maw", "Void Jackal", "Iron Widow"]
const TRADER_NAMES: Array[String] = ["Lucky Margin", "Slow Fortune", "Bountiful", "Cargo Queen", "Fair Deal", "Long Haul"]
const PATROL_NAMES: Array[String] = ["SPV Vigilant", "SPV Resolute", "SPV Lawgiver", "SPV Sentinel", "SPV Aegis"]
const MONSTER_NAMES: Array[String] = ["Void Leech", "Star Kraken", "Nebula Wyrm", "Hull Eater", "Leviathan"]

var kind := "pirate"
var title := ""
var description := ""
var sprite := ""
var danger := 0
var hull := 10
var max_hull := 10
var shield := 0
var max_shield := 0
var shield_regen := 0
var weapons := 1
var evasion := 10
var speed := 1
var hands := 4
var boardable := true
var loot_credits := 0
var loot_cargo: Dictionary = {}


static func create(p_kind: String, p_danger: int, rng: RandomNumberGenerator) -> Encounter:
	var e := Encounter.new()
	e.kind = p_kind
	e.danger = p_danger
	var d := p_danger
	match p_kind:
		"pirate":
			e.title = "Pirate raider '%s'" % _pick(PIRATE_NAMES, rng)
			e.description = "A scarred raider drops out of the dark, guns hot. They demand your cargo."
			e.sprite = "res://assets/sprites/ship_pirate.png"
			e._set_stats(10 + 5 * d, 2 + 2 * d, 1 + d, 10 + 3 * d, 1 + int(d / 2.0), 4 + 2 * d)
			e.loot_credits = rng.randi_range(60, 120) * (d + 1)
			e._random_cargo(rng, 2, 2 + d)
		"trader":
			e.title = "Free trader '%s'" % _pick(TRADER_NAMES, rng)
			e.description = "A fat-bellied merchant hails you, offering to buy and sell."
			e.sprite = "res://assets/sprites/ship_trader.png"
			e._set_stats(14 + 4 * d, 4 + 2 * d, 1, 5, 0, 4 + d)
			e.loot_credits = rng.randi_range(100, 200) * (d + 1)
			e._random_cargo(rng, 3, 4 + d)
		"patrol":
			e.title = "Star Patrol cutter %s" % _pick(PATROL_NAMES, rng)
			e.description = "A Star Patrol cutter signals you to hold position for inspection."
			e.sprite = "res://assets/sprites/ship_patrol.png"
			e._set_stats(18 + 6 * d, 8 + 3 * d, 2 + d, 15, 3, 8 + 2 * d)
			e.shield_regen = 1
			e.loot_credits = rng.randi_range(50, 100) * (d + 1)
		"monster":
			e.title = "Space monster: %s" % _pick(MONSTER_NAMES, rng)
			e.description = "Something vast and hungry uncoils from the void and turns toward your hull."
			e.sprite = "res://assets/sprites/monster.png"
			e._set_stats(20 + 8 * d, 0, 2 + d, 5, 1, 0)
			e.boardable = false
			e.loot_cargo = {"organics": rng.randi_range(3, 6)}
			if rng.randf() < 0.3 + 0.15 * d:
				e.loot_cargo["exotic"] = rng.randi_range(1, 2)
	return e


## Rolls for a random encounter. `context` is "arrival" or "mining".
## Returns null when nothing happens.
static func roll(star: Dictionary, context: String, notoriety: int, rng: RandomNumberGenerator) -> Encounter:
	var d: int = star["danger"]
	var base := 0.30 + 0.06 * d if context == "arrival" else 0.08 + 0.03 * d
	if rng.randf() >= minf(base, 0.6):
		return null
	var starbase: bool = star["starbase"]
	var weights := {
		"pirate": 30 + 10 * d - (15 if starbase else 0),
		"trader": 25 + (15 if starbase else 0),
		"patrol": maxi(2, 15 + (25 if starbase else 0) - 3 * d + 10 * notoriety),
		"monster": (5 + 8 * d) * (2 if context == "mining" else 1),
	}
	return create(StarSystem._weighted_pick(weights, rng), d, rng)


func _set_stats(p_hull: int, p_shield: int, p_weapons: int, p_evasion: int, p_speed: int, p_hands: int) -> void:
	max_hull = p_hull
	hull = p_hull
	max_shield = p_shield
	shield = p_shield
	weapons = p_weapons
	evasion = p_evasion
	speed = p_speed
	hands = p_hands


func _random_cargo(rng: RandomNumberGenerator, kinds: int, max_qty: int) -> void:
	for i in kinds:
		var id: String = ResourceDB.ORDER[rng.randi_range(0, ResourceDB.ORDER.size() - 1)]
		loot_cargo[id] = int(loot_cargo.get(id, 0)) + rng.randi_range(1, max_qty)


## Price a trader pays per unit (slightly under starbase rates).
func trader_buy_price(id: String, captain: int) -> int:
	return maxi(1, int(ResourceDB.base_price(id) * (0.8 + 0.05 * captain)))


static func _pick(list: Array[String], rng: RandomNumberGenerator) -> String:
	return list[rng.randi_range(0, list.size() - 1)]
