class_name MetaShop
extends RefCounted
## Persistent between-run upgrades bought with banked coins.

const UPGRADES := {
	&"vitality": {"name": "META_VITALITY", "desc": "META_VITALITY_DESC", "max": 5, "cost": 60, "growth": 1.6, "stat": &"max_hp", "mode": "add", "per": 10.0},
	&"power": {"name": "META_POWER", "desc": "META_POWER_DESC", "max": 5, "cost": 80, "growth": 1.65, "stat": &"damage", "mode": "mult", "per": 0.06},
	&"haste": {"name": "META_HASTE", "desc": "META_HASTE_DESC", "max": 5, "cost": 80, "growth": 1.65, "stat": &"fire_rate", "mode": "mult", "per": 0.05},
	&"swiftness": {"name": "META_SWIFT", "desc": "META_SWIFT_DESC", "max": 4, "cost": 50, "growth": 1.5, "stat": &"move_speed", "mode": "mult", "per": 0.04},
	&"magnet": {"name": "META_MAGNET", "desc": "META_MAGNET_DESC", "max": 3, "cost": 40, "growth": 1.5, "stat": &"pickup_radius", "mode": "mult", "per": 0.2},
	&"greed": {"name": "META_GREED", "desc": "META_GREED_DESC", "max": 5, "cost": 100, "growth": 1.7, "stat": &"coin_gain", "mode": "mult", "per": 0.15},
}


static func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for k: StringName in UPGRADES:
		out.append(k)
	return out


static func cost(id: StringName, current_level: int) -> int:
	var def: Dictionary = UPGRADES[id]
	return int(round(float(def["cost"]) * pow(float(def["growth"]), current_level)))


static func is_maxed(id: StringName, current_level: int) -> bool:
	return current_level >= int(UPGRADES[id]["max"])


## `save` is the SaveSystem (or anything with the same coin/meta API).
static func buy(save: Object, id: StringName) -> bool:
	if not UPGRADES.has(id):
		return false
	var lvl: int = save.get_meta_level(id)
	if is_maxed(id, lvl):
		return false
	if not save.spend_coins(cost(id, lvl)):
		return false
	save.set_meta_level(id, lvl + 1)
	return true


static func apply_to_stats(stats: PlayerStats, levels: Dictionary) -> void:
	for id: StringName in UPGRADES:
		var lvl := int(levels.get(String(id), levels.get(id, 0)))
		if lvl <= 0:
			continue
		var def: Dictionary = UPGRADES[id]
		var amount: float = float(def["per"]) * lvl
		if def["mode"] == "add":
			stats.add_flat(def["stat"], amount)
		else:
			stats.add_mult(def["stat"], amount)
