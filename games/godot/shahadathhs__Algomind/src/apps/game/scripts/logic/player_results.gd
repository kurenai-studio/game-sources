class_name PlayerResults
extends RefCounted
## What the server needs to verify and score the player's clears, and what it answered.
##
## `queue` holds, per level, the best program the player solved it with and has not yet sent. It
## is only ever read by ProgressSync, the one place that uploads. `points` is the server's answer:
## the total and the best stars and points per level. The game never computes a total itself; the
## server's total wins. Nothing here touches the network.

const VERSION := 1

var path: String
## { levelSlug: { levelVersion, slots, program } }
var queue: Dictionary = {}
## The server's total, or -1 until a sync has told us.
var total := -1
## { levelSlug: { stars, points } } as last reported by the server.
var levels: Dictionary = {}
## { date: { levelSlug, levelVersion, slots, program } } waiting to be sent as daily results.
var daily_queue: Dictionary = {}
## { date: { levelSlug, slots } } the best result on this device per daily.
var daily_best: Dictionary = {}
## { current, best } as the server last said, {} until a sync has told us.
var streak: Dictionary = {}
## Titles of badges earned and not shown yet.
var badges: Array[String] = []


func _init(save_path: String = "user://results.json") -> void:
	path = save_path


func load_data() -> void:
	queue = {}
	total = -1
	levels = {}
	daily_queue = {}
	daily_best = {}
	streak = {}
	badges = []
	var parsed: Variant = AtomicFile.read_json(path)
	if typeof(parsed) != TYPE_DICTIONARY or int(parsed.get("version", 0)) != VERSION:
		return
	if typeof(parsed.get("queue")) == TYPE_DICTIONARY:
		for slug: String in parsed["queue"]:
			var entry: Variant = parsed["queue"][slug]
			if _valid_entry(entry):
				queue[slug] = entry
	if typeof(parsed.get("levels")) == TYPE_DICTIONARY:
		for slug: String in parsed["levels"]:
			var item: Variant = parsed["levels"][slug]
			if typeof(item) == TYPE_DICTIONARY:
				levels[slug] = {
					"stars": int(item.get("stars", 0)), "points": int(item.get("points", 0))
				}
	total = int(parsed.get("total", -1))
	_load_daily(parsed)


func save() -> bool:
	var data := {
		"version": VERSION,
		"queue": queue,
		"total": total,
		"levels": levels,
		"dailyQueue": daily_queue,
		"dailyBest": daily_best,
		"streak": streak,
		"badges": badges,
	}
	return AtomicFile.write_json(path, data)


## Remembers a solved program to send at the next sync. Per level only the program with the fewest
## slots is kept (a newer level version replaces an older one), so the queue stays small.
func queue_result(level_slug: String, level_version: int, program: Array, slots: int) -> void:
	var current: Variant = queue.get(level_slug)
	if current != null and int(current["levelVersion"]) == level_version:
		if int(current["slots"]) <= slots:
			return
	elif current != null and int(current["levelVersion"]) > level_version:
		return
	queue[level_slug] = {"levelVersion": level_version, "slots": slots, "program": program}


## Slugs with something waiting, in a stable order.
func pending() -> Array[String]:
	var slugs: Array[String] = []
	for slug: String in queue:
		slugs.append(slug)
	slugs.sort()
	return slugs


## Removes a sent entry, unless a better one replaced it while the request was in flight.
func drop_if_unchanged(level_slug: String, sent: Dictionary) -> void:
	var current: Variant = queue.get(level_slug)
	if current == null:
		return
	if (
		int(current["levelVersion"]) == int(sent["levelVersion"])
		and int(current["slots"]) >= int(sent["slots"])
	):
		queue.erase(level_slug)


## Remembers a solved daily to send at the next sync. Per date the program with the fewest slots
## is kept, so the queue stays small and the best result counts.
func queue_daily(
	date: String, level_slug: String, level_version: int, program: Array, slots: int
) -> void:
	var best: Dictionary = daily_best.get(date, {})
	if best.is_empty() or slots < int(best["slots"]):
		daily_best[date] = {"levelSlug": level_slug, "slots": slots}
	var current: Variant = daily_queue.get(date)
	if current != null and int(current["slots"]) <= slots:
		return
	daily_queue[date] = {
		"levelSlug": level_slug, "levelVersion": level_version, "slots": slots, "program": program
	}


## Dates with a daily result waiting, oldest first.
func pending_dailies() -> Array[String]:
	var dates: Array[String] = []
	for date: String in daily_queue:
		dates.append(date)
	dates.sort()
	return dates


## Removes a sent daily, unless a better one replaced it while the request was in flight.
func drop_daily_if_unchanged(date: String, sent: Dictionary) -> void:
	var current: Variant = daily_queue.get(date)
	if current != null and int(current["slots"]) >= int(sent["slots"]):
		daily_queue.erase(date)


## Records the server's answer to a daily submission: the streak, when it counted the day.
func apply_daily(result: Dictionary) -> void:
	var daily: Variant = result.get("daily")
	if typeof(daily) != TYPE_DICTIONARY or typeof(daily.get("streak")) != TYPE_DICTIONARY:
		return
	streak = {
		"current": int(daily["streak"].get("current", 0)),
		"best": int(daily["streak"].get("best", 0)),
	}


## Remembers the badges a submission earned, to be shown once.
func note_badges(result: Dictionary) -> void:
	var earned: Variant = result.get("achievements")
	if typeof(earned) != TYPE_ARRAY:
		return
	for item: Variant in earned:
		if typeof(item) == TYPE_DICTIONARY and not str(item.get("title", "")).is_empty():
			if not badges.has(str(item["title"])):
				badges.append(str(item["title"]))


## The new badge titles, and forgets them: they are shown once.
func take_badges() -> Array[String]:
	var shown := badges.duplicate()
	badges.clear()
	return shown


## Records the server's answer to one submission.
func apply_result(level_slug: String, result: Dictionary) -> void:
	var stars := int(result.get("stars", 0))
	var points := int(result.get("points", 0))
	var known: Dictionary = levels.get(level_slug, {"stars": 0, "points": 0})
	levels[level_slug] = {
		"stars": maxi(int(known["stars"]), stars), "points": maxi(int(known["points"]), points)
	}
	total = int(result.get("total", total))
	note_badges(result)


func stars_for(level_slug: String) -> int:
	return int(levels.get(level_slug, {}).get("stars", 0))


## Forgets what the previous account was told; the queue of unsent programs stays.
func clear_points() -> void:
	total = -1
	levels = {}
	streak = {}
	badges = []


func _load_daily(parsed: Dictionary) -> void:
	if typeof(parsed.get("dailyQueue")) == TYPE_DICTIONARY:
		for date: String in parsed["dailyQueue"]:
			var entry: Variant = parsed["dailyQueue"][date]
			if DailyDates.is_valid(date) and _valid_entry(entry) and entry.has("levelSlug"):
				daily_queue[date] = entry
	if typeof(parsed.get("dailyBest")) == TYPE_DICTIONARY:
		for date: String in parsed["dailyBest"]:
			var item: Variant = parsed["dailyBest"][date]
			if typeof(item) == TYPE_DICTIONARY and item.has("slots"):
				daily_best[date] = {
					"levelSlug": str(item.get("levelSlug", "")), "slots": int(item["slots"])
				}
	if typeof(parsed.get("streak")) == TYPE_DICTIONARY and parsed["streak"].has("current"):
		streak = {
			"current": int(parsed["streak"]["current"]),
			"best": int(parsed["streak"].get("best", 0)),
		}
	if typeof(parsed.get("badges")) == TYPE_ARRAY:
		for title: Variant in parsed["badges"]:
			badges.append(str(title))


static func _valid_entry(entry: Variant) -> bool:
	return (
		typeof(entry) == TYPE_DICTIONARY
		and entry.has("levelVersion")
		and entry.has("slots")
		and typeof(entry.get("program")) == TYPE_ARRAY
		and not entry["program"].is_empty()
	)
