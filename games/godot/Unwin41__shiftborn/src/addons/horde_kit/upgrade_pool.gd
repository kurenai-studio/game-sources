class_name UpgradePool
extends RefCounted
## Tracks upgrade levels and rolls weighted level-up offers.
##
## [codeblock]
## var pool := UpgradePool.new(upgrades)
## var choices := pool.offer(3, rng, ["knight"])
## pool.apply(choices[0].id)
## [/codeblock]

signal upgrade_applied(upgrade: Upgrade, new_level: int)

var _upgrades: Dictionary[StringName, Upgrade] = {}
var _levels: Dictionary[StringName, int] = {}


func _init(upgrades: Array[Upgrade] = []) -> void:
	for upgrade in upgrades:
		add(upgrade)


func add(upgrade: Upgrade) -> void:
	if upgrade == null or upgrade.id == &"":
		push_error("UpgradePool: upgrade needs a non-empty id")
		return
	_upgrades[upgrade.id] = upgrade
	if not _levels.has(upgrade.id):
		_levels[upgrade.id] = 0


func get_upgrade(id: StringName) -> Upgrade:
	return _upgrades.get(id)


func level_of(id: StringName) -> int:
	return _levels.get(id, 0)


func is_maxed(id: StringName) -> bool:
	var upgrade := get_upgrade(id)
	return upgrade != null and level_of(id) >= upgrade.max_level


func is_eligible(upgrade: Upgrade, tag_filter: PackedStringArray = []) -> bool:
	if upgrade.weight <= 0.0 or is_maxed(upgrade.id):
		return false
	for required in upgrade.requires:
		if level_of(required) < 1:
			return false
	for required in upgrade.requires_maxed:
		if not is_maxed(required):
			return false
	if tag_filter.is_empty() or upgrade.tags.is_empty():
		return true
	for tag in upgrade.tags:
		if tag in tag_filter:
			return true
	return false


## Up to [param count] distinct eligible upgrades, picked by weight.
## Pass a seeded [param rng] for reproducible offers.
func offer(count: int, rng: RandomNumberGenerator, tag_filter: PackedStringArray = []) -> Array[Upgrade]:
	var candidates: Array[Upgrade] = []
	for upgrade in _upgrades.values():
		if is_eligible(upgrade, tag_filter):
			candidates.append(upgrade)
	var picked: Array[Upgrade] = []
	while picked.size() < count and not candidates.is_empty():
		var index := _pick_weighted_index(candidates, rng)
		picked.append(candidates[index])
		candidates.remove_at(index)
	return picked


## Raises the upgrade by one level. Returns the new level, or -1 when the
## id is unknown or already at max level.
func apply(id: StringName) -> int:
	var upgrade := get_upgrade(id)
	if upgrade == null:
		push_warning("UpgradePool: unknown upgrade %s" % id)
		return -1
	if is_maxed(id):
		return -1
	var new_level := level_of(id) + 1
	_levels[id] = new_level
	upgrade_applied.emit(upgrade, new_level)
	return new_level


## Upgrades with at least one level, in the order they were added.
func owned() -> Array[Upgrade]:
	var result: Array[Upgrade] = []
	for id in _upgrades:
		if level_of(id) > 0:
			result.append(_upgrades[id])
	return result


func reset() -> void:
	for id in _levels:
		_levels[id] = 0


func _pick_weighted_index(candidates: Array[Upgrade], rng: RandomNumberGenerator) -> int:
	var total := 0.0
	for upgrade in candidates:
		total += upgrade.weight
	var roll := rng.randf() * total
	for i in candidates.size():
		roll -= candidates[i].weight
		if roll < 0.0:
			return i
	return candidates.size() - 1
