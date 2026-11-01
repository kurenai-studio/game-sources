class_name DailyDates
extends RefCounted
## UTC calendar dates as "YYYY-MM-DD" strings, the form the API uses for a daily challenge. A day
## is a UTC day. Pure functions; nothing here reads the clock unless you ask for it.


## The UTC date of a Unix time in seconds.
static func utc(unix_seconds: float) -> String:
	var parts := Time.get_date_dict_from_unix_time(int(floor(unix_seconds)))
	return "%04d-%02d-%02d" % [parts["year"], parts["month"], parts["day"]]


## The UTC date on this device right now.
static func device_today() -> String:
	return utc(Time.get_unix_time_from_system())


## True for a real calendar date written as YYYY-MM-DD.
static func is_valid(date: String) -> bool:
	if date.length() != 10 or date[4] != "-" or date[7] != "-":
		return false
	for i in [0, 1, 2, 3, 5, 6, 8, 9]:
		if not date[i].is_valid_int():
			return false
	var month := int(date.substr(5, 2))
	var day := int(date.substr(8, 2))
	if month < 1 or month > 12 or day < 1:
		return false
	# Checked by hand: converting an impossible date would log an engine error.
	var year := int(date.substr(0, 4))
	var leap := (year % 4 == 0 and year % 100 != 0) or year % 400 == 0
	var lengths := [31, 29 if leap else 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]
	return day <= lengths[month - 1]


## Midnight UTC of a date, in Unix seconds.
static func to_unix(date: String) -> int:
	var parts := date.split("-")
	if parts.size() != 3:
		return 0
	return Time.get_unix_time_from_datetime_dict(
		{
			"year": int(parts[0]),
			"month": int(parts[1]),
			"day": int(parts[2]),
			"hour": 0,
			"minute": 0,
			"second": 0
		}
	)


## The date `days` days after `date` (before it when negative).
static func shift(date: String, days: int) -> String:
	return utc(float(to_unix(date) + days * 86400))
