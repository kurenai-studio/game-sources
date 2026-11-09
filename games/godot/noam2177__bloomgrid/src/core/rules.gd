class_name Rules
extends RefCounted
## נוסחאות במקום אחד, כדי שהמעטפת לא "תנחש" ניקוד.
## קומבו עולה רק על ניקוי ברצף. בלי ניקוי — מתאפס.

const SCORE_MAX := 9999999


static func clamp_score(n: int) -> int:
	if n < 0:
		return 0
	return mini(n, SCORE_MAX)


static func score_place(cells: int, lines: int, combo: int = 1, cross: bool = false) -> int:
	# בסיס: 10 לתא. ניקוי: 100 * lines² * combo. סופרנובה: +250.
	var base := cells * 10
	if lines <= 0:
		return base
	var c := maxi(combo, 1)
	var total := base + 100 * lines * lines * c
	if cross:
		total += 250
	return total


## דרגת קושי לפי כמה מגשים חולקו — בהתחלה קל (שימור D1).
static func difficulty_tier(trays_dealt: int) -> int:
	return mini(trays_dealt / 4, 4)


static func race_start_time() -> float:
	return 48.0


static func race_time_cap() -> float:
	return 90.0


## בונוס שניות על כל הצלחה. ניקוי קו / סופרנובה = יותר.
static func race_time_bonus(cells: int, lines: int, combo: int = 1, cross: bool = false) -> float:
	var t := 1.6 + 0.05 * float(cells)
	if lines > 0:
		t += 3.2 * float(lines) + 0.45 * float(maxi(combo, 1))
	if cross:
		t += 4.0
	return t


static func rotate_charges() -> int:
	return 2
