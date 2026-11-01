# Forkline. Copyright 2026 Play, Inc.
# Free software under the GNU GPL v3 with additional terms: see LICENSE and NOTICE.
class_name RunSeeds
extends RefCounted
## Seeds and day keys for runs and the daily challenge (docs/ARCHITECTURE.md 3.4).
## Pure functions of their arguments. Nothing here reads the clock: the App reads the
## phone's local date and passes it in.

const YEAR_MIN: int = 2026
const YEAR_MAX: int = 2200
## The highest seed a normal run draws (2^32 - 1).
const SEED_MAX: int = 4294967295
const DAYS_IN_MONTH: Array[int] = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]


## The seed of one random generator: the run seed, a tag and an index mixed into one
## number. Tags and indexes are listed in the contract (3.4).
static func derive(run_seed: int, tag: String, index: int) -> int:
	return ("%d:%s:%d" % [run_seed, tag, index]).hash()


## A Time date dictionary (year, month, day) as "2026-10-23". "" when the dictionary
## has no whole year, month and day. The text may still fail is_day_key().
static func day_key(date: Dictionary) -> String:
	for key: String in ["year", "month", "day"]:
		if not date.has(key) or typeof(date[key]) != TYPE_INT:
			return ""
	var year: int = date["year"]
	var month: int = date["month"]
	var day: int = date["day"]
	if year < 0 or year > 9999 or month < 0 or month > 99 or day < 0 or day > 99:
		return ""
	return "%04d-%02d-%02d" % [year, month, day]


## A real calendar date written YYYY-MM-DD, from 2026-01-01 to 2200-12-31.
static func is_day_key(text: String) -> bool:
	return not _parts(text).is_empty()


## "2026-10-23" as 20261023. -1 when the text is not a day key.
static func daily_seed(day: String) -> int:
	var parts: Array[int] = _parts(day)
	if parts.is_empty():
		return -1
	return parts[0] * 10000 + parts[1] * 100 + parts[2]


## Days since 1970-01-01, so the day after a day is one more. -1 when the text is
## not a day key.
static func day_number(day: String) -> int:
	var parts: Array[int] = _parts(day)
	if parts.is_empty():
		return -1
	var year: int = parts[0] - (1 if parts[1] <= 2 else 0)
	var era: int = year / 400
	var year_of_era: int = year - era * 400
	var month_from_march: int = (parts[1] + 9) % 12
	var day_of_year: int = (153 * month_from_march + 2) / 5 + parts[2] - 1
	var day_of_era: int = year_of_era * 365 + year_of_era / 4 - year_of_era / 100 + day_of_year
	return era * 146097 + day_of_era - 719468


## [year, month, day] of a day key, or [] when it is not one.
static func _parts(text: String) -> Array[int]:
	var none: Array[int] = []
	if text.length() != 10 or text[4] != "-" or text[7] != "-":
		return none
	for i: int in [0, 1, 2, 3, 5, 6, 8, 9]:
		var c: int = text.unicode_at(i)
		if c < 48 or c > 57:
			return none
	var year: int = int(text.substr(0, 4))
	var month: int = int(text.substr(5, 2))
	var day: int = int(text.substr(8, 2))
	if year < YEAR_MIN or year > YEAR_MAX or month < 1 or month > 12 or day < 1:
		return none
	var most: int = DAYS_IN_MONTH[month - 1]
	if month == 2 and year % 4 == 0 and (year % 100 != 0 or year % 400 == 0):
		most = 29
	if day > most:
		return none
	var out: Array[int] = [year, month, day]
	return out
