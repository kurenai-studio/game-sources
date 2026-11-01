class_name DailyStore
extends RefCounted
## The daily challenges kept on the device so they play offline: the schedule of today and the
## next three days (`GET /daily`) and the content of each day's level (`GET /levels/<slug>`).
##
## The schedule lives in one small file written atomically; the levels live in a ContentStore of
## their own, so a daily-pool level never mixes with the campaign. Every level goes through the
## validator before it is stored, and a failed download changes nothing.
##
## "Today" is the server's date while the last refresh succeeded (this run), otherwise the UTC
## date of the device. A day is a UTC day.

const VERSION := 1
## How many days before today are kept (the last one still matters around midnight).
const KEEP_PAST_DAYS := 1

var path: String
var content: ContentStore
## { date: day } as SocialParse.day_info makes them.
var days: Dictionary = {}
## The server's date from the last successful refresh in this run, "" when there was none.
var online_date := ""


func _init(
	file_path: String = "user://daily.json", content_root: String = "user://daily_content"
) -> void:
	path = file_path
	content = ContentStore.new(content_root)


func load_data() -> void:
	days = {}
	var parsed: Variant = AtomicFile.read_json(path)
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != VERSION:
		return
	if typeof(parsed.get("days")) != TYPE_DICTIONARY:
		return
	for date: String in parsed["days"]:
		var day := SocialParse.day_info(parsed["days"][date])
		if not day.is_empty() and day["date"] == date:
			days[date] = day


func save() -> bool:
	return AtomicFile.write_json(path, {"version": VERSION, "days": days})


## The date to treat as today. `device_unix` is injectable for tests.
func today(device_unix: float = -1.0) -> String:
	if not online_date.is_empty():
		return online_date
	return DailyDates.utc(Time.get_unix_time_from_system() if device_unix < 0.0 else device_unix)


## The scheduled day, or {} when it is not known.
func day(date: String) -> Dictionary:
	return days.get(date, {})


## The cached level of a day as { content, par, levelVersion }, or {} when it is not on the
## device (or the cached copy is older than the day's version).
func level(date: String) -> Dictionary:
	var info := day(date)
	if info.is_empty():
		return {}
	var record: Variant = content.load_level(str(info["levelSlug"]))
	if record == null or int(record.get("levelVersion", 0)) < int(info["levelVersion"]):
		return {}
	return {
		"content": record["content"],
		"par": record.get("par", {}),
		"levelVersion": int(record["levelVersion"]),
	}


func is_playable(date: String) -> bool:
	return not level(date).is_empty()


## The known days after `date`, oldest first.
func upcoming(date: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var dates := days.keys()
	dates.sort()
	for key: String in dates:
		if key > date:
			out.append(days[key])
	return out


## Fetches the schedule and the levels that are not cached yet. `fetch` is a Callable(path) ->
## Dictionary (see ApiClient.fetch_json); it may be a coroutine. Returns { status, errors } with
## status "updated", "unchanged", "offline", "disabled", or "invalid". Never throws.
func refresh(fetch: Callable) -> Dictionary:
	var result := {"status": "unchanged", "errors": []}
	var response: Dictionary = await fetch.call("daily")
	if not response["ok"]:
		online_date = ""
		result["status"] = "disabled" if response["error"] == "disabled" else "offline"
		return result
	var schedule := SocialParse.daily(response["json"])
	if schedule.is_empty():
		result["status"] = "invalid"
		return result
	online_date = schedule["serverDate"]
	var next := _kept(online_date)
	for info: Dictionary in schedule["days"]:
		next[info["date"]] = info
	var changed := JSON.stringify(next) != JSON.stringify(days)
	days = next
	for info: Dictionary in schedule["days"]:
		var slug: String = info["levelSlug"]
		if content.cached_version(slug) >= int(info["levelVersion"]):
			continue
		var detail: Dictionary = await fetch.call("levels/%s" % slug)
		var problem := "the download failed"
		if detail["ok"]:
			problem = ContentSync.store_level(content, slug, detail["json"])
		if problem.is_empty():
			changed = true
		else:
			result["errors"].append("Daily level %s was not saved: %s" % [slug, problem])
	if changed:
		save()
		result["status"] = "updated"
	return result


## The days worth keeping when the date is `date`: today, the future, and a day back.
func _kept(date: String) -> Dictionary:
	var out := {}
	var oldest := DailyDates.shift(date, -KEEP_PAST_DAYS)
	for key: String in days:
		if key >= oldest:
			out[key] = days[key]
	return out
