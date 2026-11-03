class_name Progression
extends RefCounted
## XP and level curve for a single run.

signal leveled_up(level: int)
signal xp_changed(xp: int, needed: int, level: int)

var level: int = 1
var xp: int = 0


static func xp_to_next(lvl: int) -> int:
	var n := lvl - 1
	return 8 + n * 7 + n * n


## Adds XP and returns how many levels were gained.
func add_xp(amount: int) -> int:
	if amount <= 0:
		return 0
	xp += amount
	var gained := 0
	while xp >= xp_to_next(level):
		xp -= xp_to_next(level)
		level += 1
		gained += 1
		leveled_up.emit(level)
	xp_changed.emit(xp, xp_to_next(level), level)
	return gained


func progress_ratio() -> float:
	return float(xp) / float(xp_to_next(level))
