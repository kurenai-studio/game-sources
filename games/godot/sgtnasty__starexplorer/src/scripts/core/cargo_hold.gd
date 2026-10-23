# StarExplorer - SPDX-License-Identifier: GPL-3.0-only
class_name CargoHold
extends RefCounted
## A capacity-limited bag of resource units, keyed by ResourceDB id.

var capacity := 30
var items: Dictionary = {}


func total() -> int:
	var sum := 0
	for qty in items.values():
		sum += qty
	return sum


func free_space() -> int:
	return capacity - total()


func count(id: String) -> int:
	return items.get(id, 0)


func is_empty() -> bool:
	return total() == 0


## Adds up to `qty` units and returns how many actually fit.
func add(id: String, qty: int) -> int:
	var added := mini(qty, free_space())
	if added > 0:
		items[id] = count(id) + added
	return added


## Removes up to `qty` units and returns how many were removed.
func remove(id: String, qty: int) -> int:
	var removed := mini(qty, count(id))
	if removed > 0:
		items[id] = count(id) - removed
		if items[id] == 0:
			items.erase(id)
	return removed


func has_all(needs: Dictionary) -> bool:
	for id in needs:
		if count(id) < needs[id]:
			return false
	return true


func to_dict() -> Dictionary:
	return {"capacity": capacity, "items": items.duplicate()}


func from_dict(d: Dictionary) -> void:
	capacity = int(d.get("capacity", 30))
	items.clear()
	var saved: Dictionary = d.get("items", {})
	for id in saved:
		if ResourceDB.DATA.has(id) and int(saved[id]) > 0:
			items[id] = int(saved[id])
