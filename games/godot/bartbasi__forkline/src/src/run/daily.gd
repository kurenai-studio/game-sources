# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name Daily
extends RefCounted
## The daily challenge's result and streak rules (docs/design/RULES.md 15, ARCHITECTURE 3.4).
## Pure functions. Days are day keys such as "2026-10-23" (RunSeeds).

## The most a streak can reach. daily.json refuses more (5.5).
const STREAK_MAX: int = 100000


## True when result a beats result b. A result is {"won": bool, "waves": int, "lives": int}.
## A win beats a loss. Between wins, more lives is better. Between losses, more waves
## cleared is better. A tie keeps b. An empty b means no result yet, so any result beats it.
static func is_better(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty():
		return false
	if b.is_empty():
		return true
	var a_won: bool = _won(a)
	var b_won: bool = _won(b)
	if a_won != b_won:
		return a_won
	if a_won:
		return _number(a, "lives") > _number(b, "lives")
	return _number(a, "waves") > _number(b, "waves")


## The streak after a daily belonging to `day` ends. Returns {"streak": int, "day": String},
## where day is the last counted day. The day after last_day adds 1 and moves the day.
## last_day itself, or an earlier day, changes nothing. Anything else, "" included,
## starts again at 1 on day. A `day` that is not a day key changes nothing.
static func streak_after(streak: int, last_day: String, day: String) -> Dictionary:
	var kept: Dictionary = {"streak": clampi(streak, 0, STREAK_MAX), "day": last_day}
	var today: int = RunSeeds.day_number(day)
	if today < 0:
		return kept
	var last: int = RunSeeds.day_number(last_day)
	if last >= 0 and today <= last:
		return kept
	if last >= 0 and today == last + 1:
		return {"streak": mini(clampi(streak, 0, STREAK_MAX) + 1, STREAK_MAX), "day": day}
	return {"streak": 1, "day": day}


## The streak the screen shows: the saved streak while last_day is today or yesterday,
## else 0.
static func shown_streak(streak: int, last_day: String, today: String) -> int:
	var now: int = RunSeeds.day_number(today)
	var last: int = RunSeeds.day_number(last_day)
	if now < 0 or last < 0:
		return 0
	if last == now or last + 1 == now:
		return clampi(streak, 0, STREAK_MAX)
	return 0


static func _won(result: Dictionary) -> bool:
	return typeof(result.get("won", false)) == TYPE_BOOL and result["won"]


static func _number(result: Dictionary, key: String) -> int:
	var value: Variant = result.get(key, 0)
	if typeof(value) == TYPE_INT:
		return value
	return 0
