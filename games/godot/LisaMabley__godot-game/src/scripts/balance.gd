class_name Balance
## All gameplay tuning numbers in one place. Edit values here; the game reads
## them at startup.


# Per-enemy stats. "loot" is a list of [drop id, weight]; drop ids are keys of
# DROP_SCENES. "drop_percent" is the chance (0-1) that anything drops at all.
const ENEMIES = {
	"bug": {
		"max_health": 5,
		"max_speed": 16,
		"acceleration": 5,
		"drop_percent": 0.4,
		"loot": [["gem", 1]],
	},
	"slug": {
		"max_health": 10,
		"max_speed": 10,
		"acceleration": 2,
		"drop_percent": 0.7,
		"loot": [["gem", 9], ["health", 1]],
	},
		"rat": {
		"max_health": 16,
		"max_speed": 20,
		"acceleration": 5,
		"drop_percent": 0.95,
		"loot": [["gem", 7], ["health", 3]],
	},
}

const DROP_SCENES = {
	"gem": preload("res://scenes/game_object/drops/experience_gem/experience_gem.tscn"),
	"health": preload("res://scenes/game_object/drops/health_drop/health_drop.tscn"),
}

# Seconds between enemy spawns. Each difficulty level (every 5s of arena time)
# shortens it, down to SPAWN_BASE_TIME - SPAWN_MAX_TIME_REDUCTION.
const SPAWN_BASE_TIME = 1.0
const SPAWN_TIME_REDUCTION_PER_LEVEL = 0.1 / 12
const SPAWN_MAX_TIME_REDUCTION = 0.7

# [difficulty, enemy id, weight]. At that difficulty the enemy is added to the
# spawn pool with that weight, or reweighted if it is already in the pool.
const SPAWN_STEPS = [
	[0, "bug", 10],
	[3, "slug", 2],
	[6, "slug", 15],
	[6, "rat", 2],
	[9, "bug", 5],
	[9, "rat", 15],
]

# Base damage per hit and seconds between attacks, before upgrades.
const WEAPONS = {
	"sword": { "damage": 5, "cooldown": 1.5 },
	"axe": { "damage": 8, "cooldown": 3.5 },
}

# Level-up upgrades, keyed by id (ability controllers match on these ids).
#   name, description: shown on the upgrade card. "{percent}" in the
#       description is replaced with the "percent" value, so they always match.
#   max_quantity: times it can be picked before it leaves the pool.
#   weight: how likely it is to be offered, relative to the others.
#   percent: effect per level (e.g. 15 = +15% each time it's picked).
#   unlocked_by: only offered after this upgrade has been picked.
#   ability_controller_scene: makes this a new ability rather than an upgrade.
const UPGRADES = {
	"axe": {
		"name": "Axe",
		"description": "Periodically sends out a spinning axe",
		"max_quantity": 1,
		"weight": 5,
		"ability_controller_scene": "res://scenes/ability/axe_ability_controller/axe_ability_controller.tscn",
	},
	"axe_damage": {
		"name": "Axe Damage",
		"description": "Increases axe damage by {percent}%",
		"max_quantity": 15,
		"weight": 10,
		"percent": 10,
		"unlocked_by": "axe",
	},
	"sword_damage": {
		"name": "Sword Damage",
		"description": "Increases sword damage by {percent}%",
		"max_quantity": 15,
		"weight": 10,
		"percent": 15,
	},
	"sword_attack_rate": {
		"name": "Sword Attack Rate",
		"description": "Increases sword attack rate by {percent}%",
		"max_quantity": 5,
		"weight": 10,
		"percent": 10,
	},
}


static func apply_enemy_stats(enemy: Node, enemy_id: String) -> void:
	assert(ENEMIES.has(enemy_id), "No Balance.ENEMIES entry for '%s'." % enemy_id)
	var stats = ENEMIES[enemy_id]

	(enemy.get_node("HealthComponent") as HealthComponent).set_max_health(stats["max_health"])

	var velocity_component = enemy.get_node("VelocityComponent")
	velocity_component.max_speed = stats["max_speed"]
	velocity_component.acceleration = stats["acceleration"]

	enemy.get_node("LootDropComponent").set_loot(stats["drop_percent"], stats["loot"])
