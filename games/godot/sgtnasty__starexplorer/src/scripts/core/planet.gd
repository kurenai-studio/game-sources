# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name Planet
extends RefCounted
## One planet in a star system and its resource deposits.

## Resource weights per planet type: higher weight = more likely and richer.
const TYPES := {
	"barren": {"name": "Barren", "res": {"iron": 3, "uranium": 1}},
	"rocky": {"name": "Rocky", "res": {"iron": 4, "uranium": 2, "crystals": 1}},
	"ice": {"name": "Ice World", "res": {"ice": 5, "hydrogen": 1, "exotic": 1}},
	"gas_giant": {"name": "Gas Giant", "res": {"hydrogen": 6, "exotic": 1}},
	"ocean": {"name": "Ocean World", "res": {"ice": 2, "organics": 4}},
	"jungle": {"name": "Jungle World", "res": {"organics": 6, "crystals": 1}},
	"volcanic": {"name": "Volcanic", "res": {"uranium": 4, "iron": 2, "crystals": 2}},
	"crystal": {"name": "Crystalline", "res": {"crystals": 5, "exotic": 1}},
}
const TYPE_WEIGHTS := {
	"barren": 18, "rocky": 18, "ice": 12, "gas_giant": 14,
	"ocean": 8, "jungle": 8, "volcanic": 12, "crystal": 6,
}

var index := 0
var planet_name := ""
var type := "barren"
## Each deposit: {"res": String, "amount": int, "difficulty": int}
var deposits: Array[Dictionary] = []


func type_name() -> String:
	return TYPES[type]["name"]


func texture() -> Texture2D:
	return load("res://assets/sprites/planet_%s.png" % type)


func remaining_units() -> int:
	var sum := 0
	for dep in deposits:
		sum += dep["amount"]
	return sum
