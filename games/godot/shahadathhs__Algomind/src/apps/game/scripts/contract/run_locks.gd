class_name RunLocks
extends RefCounted
## Keys and doors during a run. Mirrors the keyAt, doorAt and held parts of simulate.ts. A lock is
## its index in the level's `locks`; a key is held once its cell has been entered.


## The run state for a level's locks: cell to lock index, for keys and for doors.
static func tables(level: Dictionary) -> Dictionary:
	var keys := {}
	var doors := {}
	var locks: Array = level.get("locks", [])
	for i in locks.size():
		var key: Array = locks[i]["key"]
		var door: Array = locks[i]["door"]
		keys[Vector2i(int(key[0]), int(key[1]))] = i
		doors[Vector2i(int(door[0]), int(door[1]))] = i
	return {"keys": keys, "doors": doors}


## True when a door stands on the cell and its key is not held.
static func closed_door(run: Dictionary, cell: Vector2i) -> bool:
	var doors: Dictionary = run["doors"]
	return doors.has(cell) and not (run["held"] as Dictionary).has(doors[cell])


## Picks up the key on the cell, if there is one not yet held. Returns true when one was taken.
static func take_key(run: Dictionary, cell: Vector2i) -> bool:
	var keys: Dictionary = run["keys"]
	if not keys.has(cell) or (run["held"] as Dictionary).has(keys[cell]):
		return false
	(run["held"] as Dictionary)[keys[cell]] = true
	return true
