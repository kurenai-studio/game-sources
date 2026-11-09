class_name UpgradeEffects
extends RefCounted
## Applies one level of an [UpgradeCatalog] upgrade to a [Player].
## Keep the steps in sync with the catalog descriptions.

## Damage upgrades multiply, so each level is felt (5 levels = x3.05).
const DAMAGE_FACTOR := 1.25
const KNIGHT_REACH_FACTOR := 1.15
const KNIGHT_HASTE_FACTOR := 0.88
const LIFESTEAL_STEP := 0.25
## Initial push speed in px/s; enemies slide about speed / 10 pixels.
const KNOCKBACK_STEP := 120.0
const MAGE_HASTE_FACTOR := 0.85
const MAGE_RANGE_FACTOR := 1.2
## Max HP grows by this factor and the gain is healed.
const VITALITY_FACTOR := 1.25
const SWIFTNESS_FACTOR := 1.1
const REGEN_STEP := 0.3
const SHIFT_BURST_DAMAGE_STEP := 4.0
## Added crit chance per level.
const PRECISION_STEP := 0.08
## Momentum damage bonus per level.
const MOMENTUM_STEP := 0.2

const KNOWN_IDS: Array[StringName] = [
	&"knight_damage", &"knight_reach", &"knight_haste", &"knight_lifesteal",
	&"knight_twin_blade", &"knight_knockback",
	&"mage_damage", &"mage_haste", &"mage_range", &"mage_pierce",
	&"mage_multishot", &"mage_chain",
	&"vitality", &"swiftness", &"regen", &"shift_burst", &"precision",
	&"momentum",
	&"evo_arcane_orbit", &"evo_storm_cleaver", &"evo_blood_pact", &"evo_twin_soul",
]


## Returns false for an unknown id.
static func apply(player: Player, id: StringName) -> bool:
	match id:
		&"knight_damage": player.knight_damage *= DAMAGE_FACTOR
		&"knight_reach": player.knight_radius *= KNIGHT_REACH_FACTOR
		&"knight_haste": player.knight_interval *= KNIGHT_HASTE_FACTOR
		&"knight_lifesteal": player.lifesteal += LIFESTEAL_STEP
		&"knight_twin_blade": player.blade_count += 1
		&"knight_knockback": player.knockback += KNOCKBACK_STEP
		&"mage_damage": player.mage_damage *= DAMAGE_FACTOR
		&"mage_haste": player.mage_interval *= MAGE_HASTE_FACTOR
		&"mage_range": player.mage_range *= MAGE_RANGE_FACTOR
		&"mage_pierce": player.bolt_pierce += 1
		&"mage_multishot": player.bolt_count += 1
		&"mage_chain": player.bolt_chain += 1
		&"vitality":
			var gained := player.max_health * (VITALITY_FACTOR - 1.0)
			player.max_health += gained
			player.heal(gained)
		&"swiftness": player.move_speed *= SWIFTNESS_FACTOR
		&"regen": player.regen_per_second += REGEN_STEP
		&"shift_burst": player.shift_burst_damage += SHIFT_BURST_DAMAGE_STEP
		&"precision": player.crit_chance += PRECISION_STEP
		&"momentum": player.momentum_bonus += MOMENTUM_STEP
		&"evo_arcane_orbit", &"evo_storm_cleaver", &"evo_blood_pact", &"evo_twin_soul":
			player.add_evolution(id)
		_:
			push_warning("UpgradeEffects: unknown upgrade %s" % id)
			return false
	player.refresh_stats()
	return true
