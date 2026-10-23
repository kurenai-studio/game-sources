# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name Ship
extends RefCounted
## The player's ship: five upgradable systems, hull, shields, fuel and cargo.
##
## The power plant caps the other systems: the summed levels of thrusters,
## jump drive, weapons and shield may never exceed power_capacity(), so every
## upgrade path eventually runs through the reactor.

const SYSTEMS: Array[String] = ["power", "thrusters", "jump", "weapons", "shield"]
const MAX_LEVEL := 5

const SYSTEM_NAMES := {
	"power": "Power Plant",
	"thrusters": "Thrusters",
	"jump": "Jump Drive",
	"weapons": "Weapons",
	"shield": "Shield",
}

const SYSTEM_DESC := {
	"power": "Powers other systems; boosts shield recharge",
	"thrusters": "Evasion and escape chance",
	"jump": "Jump range and fuel tank",
	"weapons": "Damage per shot",
	"shield": "Shield points absorbing damage",
}

## Resources consumed per upgrade, multiplied by the current level.
const UPGRADE_RESOURCES := {
	"power": {"uranium": 2, "iron": 2},
	"thrusters": {"hydrogen": 3, "iron": 2},
	"jump": {"crystals": 1, "exotic": 1},
	"weapons": {"iron": 3, "crystals": 1},
	"shield": {"crystals": 2, "ice": 2},
}
const UPGRADE_CREDITS_PER_LEVEL := 120

var ship_name := "Wanderer"
var levels := {"power": 1, "thrusters": 1, "jump": 1, "weapons": 1, "shield": 1}
var max_hull := 30
var hull := 30
var shield_points := 0
var fuel := 0
var cargo := CargoHold.new()


func _init() -> void:
	shield_points = max_shield()
	fuel = max_fuel()


func level(system: String) -> int:
	return levels[system]


func power_capacity() -> int:
	return 2 + 3 * level("power")


func power_used() -> int:
	return level("thrusters") + level("jump") + level("weapons") + level("shield")


func max_shield() -> int:
	return 4 * level("shield")


func shield_recharge() -> int:
	return 1 + level("power")


func max_fuel() -> int:
	return 4 + 2 * level("jump")


## Jump range in galaxy map units. Level 1 always reaches a neighbour,
## because Galaxy places every star within LINK_MAX of another.
func jump_range() -> float:
	return 45.0 + 15.0 * level("jump")


func weapon_damage() -> int:
	return 3 * level("weapons")


func upgrade_cost(system: String) -> Dictionary:
	var lvl := level(system)
	var res := {}
	for id in UPGRADE_RESOURCES[system]:
		res[id] = UPGRADE_RESOURCES[system][id] * lvl
	return {"credits": UPGRADE_CREDITS_PER_LEVEL * lvl, "resources": res}


## Returns "" if the system can be upgraded, otherwise the reason it can't.
## Credits are checked by the caller, which owns the wallet.
func upgrade_block_reason(system: String) -> String:
	if level(system) >= MAX_LEVEL:
		return "Max level"
	if system != "power" and power_used() + 1 > power_capacity():
		return "Needs more power"
	if not cargo.has_all(upgrade_cost(system)["resources"]):
		return "Missing resources"
	return ""


## Applies an upgrade, consuming resources. Caller must check
## upgrade_block_reason() and take the credits.
func apply_upgrade(system: String) -> void:
	var needs: Dictionary = upgrade_cost(system)["resources"]
	for id in needs:
		cargo.remove(id, needs[id])
	levels[system] = level(system) + 1
	if system == "shield":
		shield_points = max_shield()


func to_dict() -> Dictionary:
	return {
		"name": ship_name, "levels": levels.duplicate(), "hull": hull,
		"max_hull": max_hull, "fuel": fuel, "cargo": cargo.to_dict(),
	}


func from_dict(d: Dictionary) -> void:
	ship_name = d.get("name", ship_name)
	var saved: Dictionary = d.get("levels", {})
	for s in SYSTEMS:
		levels[s] = clampi(int(saved.get(s, 1)), 1, MAX_LEVEL)
	max_hull = int(d.get("max_hull", 30))
	hull = int(d.get("hull", max_hull))
	fuel = int(d.get("fuel", max_fuel()))
	cargo.from_dict(d.get("cargo", {}))
	shield_points = max_shield()
