class_name Experience
extends RefCounted
## Run XP and level. Kills add XP directly (no pickups). Reaching level
## n + 1 from level n costs [method xp_for_level] of n; leftover XP carries.
## Tuned for roughly 25 level-ups before the boss at 4:30.

signal leveled_up(new_level: int)

## The first level-up needs this much, so the first card comes fast.
const BASE_XP := 3
## Each level costs this much more than the previous one...
const GROWTH := 1.13
## ...plus this much flat XP per level, which slows the early run, where
## the exponential part alone hands out a card every two seconds.
const STEP_XP := 6

var level: int = 1
var xp: int = 0


static func xp_for_level(from_level: int) -> int:
	return roundi(BASE_XP * pow(GROWTH, from_level - 1)) + STEP_XP * (from_level - 1)


func xp_to_next() -> int:
	return xp_for_level(level)


## 0..1 progress toward the next level, for the HUD bar.
func progress() -> float:
	return float(xp) / xp_to_next()


## Adds XP and returns how many levels were gained.
func add(amount: int) -> int:
	if amount <= 0:
		return 0
	xp += amount
	var gained := 0
	while xp >= xp_to_next():
		xp -= xp_to_next()
		level += 1
		gained += 1
		leveled_up.emit(level)
	return gained
