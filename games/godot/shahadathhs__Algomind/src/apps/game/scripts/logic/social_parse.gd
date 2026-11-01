class_name SocialParse
extends RefCounted
## Reads what the social endpoints answer (profile, boards, badges, daily, share) and words their
## errors. Pure functions. A parser returns {} when the answer is not what was promised, so a
## broken server can never crash a screen; the callers show a plain error instead.

const NO_NEXT := {}


## { displayName, optIn, hideName, publicId, total, rank: { name, next: { name, at } or {} } }.
static func profile(json: Variant) -> Dictionary:
	if typeof(json) != TYPE_DICTIONARY or typeof(json.get("rank")) != TYPE_DICTIONARY:
		return {}
	var rank: Dictionary = json["rank"]
	var next: Variant = rank.get("next")
	return {
		"displayName": str(json["displayName"]) if json.get("displayName") != null else "",
		"optIn": bool(json.get("leaderboardOptIn", false)),
		"hideName": bool(json.get("hideName", false)),
		"publicId": str(json.get("publicId", "")),
		"total": int(json.get("total", 0)),
		"rank":
		{
			"name": str(rank.get("name", "")),
			"next":
			(
				{"name": str(next.get("name", "")), "at": int(next.get("at", 0))}
				if typeof(next) == TYPE_DICTIONARY
				else NO_NEXT
			),
		},
	}


## { total, entries: [entry], me: { entry, around: [entry] } or {} }, where an entry is
## { rank, publicId, name, you, points } or { rank, publicId, name, you, slots, steps }.
static func board(json: Variant) -> Dictionary:
	if typeof(json) != TYPE_DICTIONARY or typeof(json.get("entries")) != TYPE_ARRAY:
		return {}
	var entries: Array = []
	for raw: Variant in json["entries"]:
		var entry := _entry(raw)
		if entry.is_empty():
			return {}
		entries.append(entry)
	var me := {}
	var raw_me: Variant = json.get("me")
	if typeof(raw_me) == TYPE_DICTIONARY:
		var mine := _entry(raw_me.get("entry"))
		var around: Array = []
		var raw_around: Variant = raw_me.get("around")
		for raw: Variant in raw_around if typeof(raw_around) == TYPE_ARRAY else []:
			var near := _entry(raw)
			if not near.is_empty():
				around.append(near)
		if not mine.is_empty():
			me = {"entry": mine, "around": around}
	return {"total": int(json.get("total", entries.size())), "entries": entries, "me": me}


## { items: [{ slug, title, description, earnedAt }] }, earnedAt "" when not earned yet.
static func achievements(json: Variant) -> Dictionary:
	if typeof(json) != TYPE_DICTIONARY or typeof(json.get("items")) != TYPE_ARRAY:
		return {}
	var items: Array = []
	for raw: Variant in json["items"]:
		if typeof(raw) != TYPE_DICTIONARY or typeof(raw.get("slug")) != TYPE_STRING:
			return {}
		var earned: Variant = raw.get("earnedAt")
		(
			items
			. append(
				{
					"slug": raw["slug"],
					"title": str(raw.get("title", raw["slug"])),
					"description": str(raw.get("description", "")),
					"earnedAt": str(earned) if earned != null else "",
				}
			)
		)
	return {"items": items}


## { serverDate, days: [day, ...] } with today's day first. A day is { date, levelSlug,
## levelVersion, title, difficulty, maxCommands, par, source }.
static func daily(json: Variant) -> Dictionary:
	if typeof(json) != TYPE_DICTIONARY or not DailyDates.is_valid(str(json.get("serverDate", ""))):
		return {}
	var days: Array = []
	var raw_days: Array = []
	if typeof(json.get("today")) == TYPE_DICTIONARY:
		raw_days.append(json["today"])
	if typeof(json.get("upcoming")) == TYPE_ARRAY:
		raw_days.append_array(json["upcoming"])
	for raw: Variant in raw_days:
		var day := day_info(raw)
		if not day.is_empty():
			days.append(day)
	return {"serverDate": str(json["serverDate"]), "days": days}


static func day_info(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY:
		return {}
	var slug := str(raw.get("levelSlug", ""))
	if not DailyDates.is_valid(str(raw.get("date", ""))) or slug.is_empty():
		return {}
	return {
		"date": str(raw["date"]),
		"levelSlug": slug,
		"levelVersion": int(raw.get("levelVersion", 0)),
		"title": str(raw.get("title", slug)),
		"difficulty": str(raw.get("difficulty", "easy")),
		"maxCommands": int(raw.get("maxCommands", 0)),
		"par": int(raw.get("par", 0)),
		"source": str(raw.get("source", "")),
	}


## { date, levelSlug, result: { slots, steps, stars } or {}, streak: { current, best } }.
static func daily_me(json: Variant) -> Dictionary:
	if typeof(json) != TYPE_DICTIONARY or typeof(json.get("streak")) != TYPE_DICTIONARY:
		return {}
	var result := {}
	var raw: Variant = json.get("result")
	if typeof(raw) == TYPE_DICTIONARY:
		result = {
			"slots": int(raw.get("slots", 0)),
			"steps": int(raw.get("steps", 0)),
			"stars": int(raw.get("stars", 0)),
		}
	return {
		"date": str(json.get("date", "")),
		"levelSlug": str(json.get("levelSlug", "")),
		"result": result,
		"streak":
		{
			"current": int(json["streak"].get("current", 0)),
			"best": int(json["streak"].get("best", 0)),
		},
	}


## { code, path } of a share link.
static func share(json: Variant) -> Dictionary:
	if typeof(json) != TYPE_DICTIONARY or typeof(json.get("code")) != TYPE_STRING:
		return {}
	return {"code": json["code"], "path": str(json.get("path", "/s/%s" % json["code"]))}


## A short, plain sentence for a failed result. The server's own reason is shown for name
## problems; everything else falls back to the account wording.
static func message(result: Dictionary) -> String:
	var body: Variant = result.get("json")
	var code := str(body.get("code", "")) if typeof(body) == TYPE_DICTIONARY else ""
	var reason := str(body.get("message", "")) if typeof(body) == TYPE_DICTIONARY else ""
	match code:
		"NAME_TAKEN":
			return "THAT NAME IS TAKEN. CHOOSE ANOTHER"
		"NAME_INVALID", "NAME_NOT_ALLOWED", "NAME_REQUIRED":
			return (
				reason.to_upper().trim_suffix(".")
				if not reason.is_empty()
				else _name_fallback(code)
			)
		"NO_RESULT":
			return "THE SERVER HAS NO SOLVED RESULT FOR THIS YET"
	if int(result.get("status", 0)) == 404:
		return "THIS BOARD IS NOT AVAILABLE"
	return AccountClient.describe(result)


static func _name_fallback(code: String) -> String:
	match code:
		"NAME_REQUIRED":
			return "CHOOSE A NAME OR HIDE YOUR NAME TO APPEAR ON BOARDS"
		"NAME_NOT_ALLOWED":
			return "THAT NAME IS NOT ALLOWED"
	return "USE 3 TO 20 LETTERS, NUMBERS, OR SPACES"


static func _entry(raw: Variant) -> Dictionary:
	if typeof(raw) != TYPE_DICTIONARY or not raw.has("rank"):
		return {}
	var entry := {
		"rank": int(raw["rank"]),
		"publicId": str(raw.get("publicId", "")),
		"name": str(raw.get("name", "")),
		"you": bool(raw.get("you", false)),
	}
	if raw.has("points"):
		entry["points"] = int(raw["points"])
	if raw.has("slots"):
		entry["slots"] = int(raw["slots"])
		entry["steps"] = int(raw.get("steps", 0))
	return entry
