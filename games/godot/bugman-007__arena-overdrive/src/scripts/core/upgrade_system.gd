class_name UpgradeSystem
extends RefCounted
## Rolls weighted "pick 1 of 3" upgrade cards and tracks stacks.

const RARITY_WEIGHTS := {
	UpgradeData.Rarity.COMMON: 60.0,
	UpgradeData.Rarity.RARE: 28.0,
	UpgradeData.Rarity.EPIC: 12.0,
}

var pool: Array[UpgradeData] = []
var stacks: Dictionary = {}


func _init(upgrade_pool: Array[UpgradeData] = []) -> void:
	pool = upgrade_pool


func stack_count(id: StringName) -> int:
	return int(stacks.get(id, 0))


func available() -> Array[UpgradeData]:
	var out: Array[UpgradeData] = []
	for u in pool:
		if stack_count(u.id) < u.max_stacks:
			out.append(u)
	return out


static func weight_of(u: UpgradeData) -> float:
	return float(RARITY_WEIGHTS.get(u.rarity, 1.0))


## Weighted sampling without replacement.
func roll_choices(rng: RandomNumberGenerator, count: int = 3) -> Array[UpgradeData]:
	var candidates := available()
	var picks: Array[UpgradeData] = []
	while picks.size() < count and not candidates.is_empty():
		var total := 0.0
		for u in candidates:
			total += weight_of(u)
		var roll := rng.randf() * total
		var chosen: UpgradeData = candidates[candidates.size() - 1]
		for u in candidates:
			roll -= weight_of(u)
			if roll <= 0.0:
				chosen = u
				break
		picks.append(chosen)
		candidates.erase(chosen)
	return picks


func take(u: UpgradeData) -> int:
	stacks[u.id] = stack_count(u.id) + 1
	return stacks[u.id]
