class_name ShotServer
extends RefCounted
## Debug screenshots only (see main.gd): a stand-in for the API with canned answers, so every
## social screen can be captured without a network. It is never created in a normal run.
##
## `mode` picks the situation: "ok", "offline" (every request fails like a lost connection),
## "empty" (boards and badges with nothing in them), "notopted" (a player who is not on boards),
## "off_page" (the player is far down a long board), or "error" (the server answers with a failure).

const DATE := "2026-10-20"
const NAMES: Array[String] = [
	"Marlo", "Anonymous", "Ines K", "Tobias", "Ravi", "Anonymous", "Wen", "Sol", "Petra", "Jun"
]
const BADGES: Array[Array] = [
	["first-clear", "First clear", "Solve your first level.", "2026-10-12T09:00:00.000Z"],
	["daily-first", "Daily start", "Solve a daily challenge.", "2026-10-19T18:30:00.000Z"],
	["par-ten", "Par on ten", "Match par on ten levels.", ""],
	["streak-seven", "Seven days", "Solve the daily seven days in a row.", ""],
	["loop-first", "First loop", "Solve a level with a loop.", "2026-10-15T07:10:00.000Z"],
	["world-one", "World one", "Finish every level of the first world.", ""],
]

var mode := "ok"
## A valid level served as the daily level (its slug is replaced per request).
var level: Dictionary = {}


func _init(shot_mode: String = "ok", level_content: Dictionary = {}) -> void:
	mode = shot_mode
	level = level_content


## The authenticated request path: Callable(method, path, body, bearer).
func send(method: String, path: String, body: Variant, _bearer: String) -> Dictionary:
	if mode == "offline":
		return {"ok": false, "status": 0, "json": null, "error": "offline"}
	var route := path.split("?")[0]
	if mode == "error" and route != "auth/refresh":
		return _fail(500, "INTERNAL", "")
	var json: Variant = _answer(route, method, body)
	return _ok(json) if json != null else _fail(404, "NOT_FOUND", "")


func _answer(route: String, method: String, body: Variant) -> Variant:
	var mine := {"date": DATE, "levelSlug": "daily-elm"}
	mine["result"] = {"slots": 9, "steps": 31, "stars": 2}
	mine["streak"] = {"current": 3, "best": 5}
	var fixed := {
		"auth/refresh": {"accessToken": "shot", "refreshToken": "shot2", "expiresIn": 900},
		"me/achievements": _badges(),
		"me/daily": mine,
		"me/share": {"code": "k3x9q2ab", "path": "/s/k3x9q2ab"},
	}
	if fixed.has(route):
		return fixed[route]
	if route == "me/profile":
		return _profile(body if method == "PUT" else {})
	return _board(route) if route.begins_with("leaderboards/") else null


## The public request path: Callable(path) -> result (like ApiClient.fetch_json).
func fetch(path: String) -> Dictionary:
	if mode == "offline":
		return {"ok": false, "status": 0, "json": null, "error": "offline"}
	if path == "daily":
		return _ok(_schedule())
	if path.begins_with("levels/"):
		var slug := path.trim_prefix("levels/")
		var content := level.duplicate(true)
		content["slug"] = slug
		content["title"] = slug.trim_prefix("daily-").capitalize()
		return _ok(
			{
				"slug": slug,
				"levelVersion": 1,
				"schemaVersion": 1,
				"par": {"commands": 5, "steps": 12},
				"content": content,
			}
		)
	return _fail(404, "NOT_FOUND", "")


func _profile(changes: Variant) -> Dictionary:
	var opted := mode != "notopted"
	var name: Variant = "Marlo" if opted else null
	if typeof(changes) == TYPE_DICTIONARY and changes.has("displayName"):
		name = changes["displayName"]
	return {
		"displayName": name,
		"leaderboardOptIn": opted,
		"hideName": false,
		"publicId": "p-shot-0001",
		"total": 485,
		"rank": {"name": "Tinkerer", "next": {"name": "Architect", "at": 600}},
	}


func _schedule() -> Dictionary:
	var slugs := ["elm", "kelp", "oak", "elm"]
	var titles := ["medium", "hard", "easy", "medium"]
	var days: Array = []
	for i in 4:
		(
			days
			. append(
				{
					"date": DailyDates.shift(DATE, i),
					"levelSlug": "daily-%s" % slugs[i],
					"levelVersion": 1,
					"title": str(slugs[i]).capitalize(),
					"difficulty": titles[i],
					"maxCommands": 13,
					"par": 11,
					"source": "rotation",
				}
			)
		)
	return {"serverDate": DATE, "today": days[0], "upcoming": days.slice(1)}


func _board(route: String) -> Dictionary:
	if mode == "empty":
		return {"total": 0, "entries": [], "me": null}
	var points := route.begins_with("leaderboards/points")
	var entries: Array = []
	for i in NAMES.size():
		entries.append(_row(i + 1, NAMES[i], 950 - i * 70, 6 + i, 20 + i * 3, i == 3, points))
	var me: Variant = null
	if mode == "off_page":
		var mine := _row(27, "Marlo", 485, 12, 44, true, points)
		me = {
			"entry": mine,
			"around":
			[
				_row(26, "Kay", 490, 11, 40, false, points),
				mine,
				_row(28, "Lou", 480, 12, 46, false, points)
			],
		}
	elif mode == "notopted":
		me = null
	else:
		me = {"entry": entries[3], "around": [entries[2], entries[3], entries[4]]}
	return {"total": 48 if mode == "off_page" else 10, "entries": entries, "me": me}


func _row(
	rank: int, name: String, points: int, slots: int, steps: int, you: bool, on_points: bool
) -> Dictionary:
	var row := {"rank": rank, "publicId": "p-%d" % rank, "name": name, "you": you}
	if on_points:
		row["points"] = points
	else:
		row["slots"] = slots
		row["steps"] = steps
	return row


func _badges() -> Dictionary:
	var items: Array = []
	if mode != "empty":
		for badge in BADGES:
			(
				items
				. append(
					{
						"slug": badge[0],
						"title": badge[1],
						"description": badge[2],
						"earnedAt": badge[3] if not str(badge[3]).is_empty() else null,
					}
				)
			)
	return {"items": items}


static func _ok(json: Variant) -> Dictionary:
	return {"ok": true, "status": 200, "json": json, "error": ""}


static func _fail(status: int, code: String, message: String) -> Dictionary:
	return {
		"ok": false, "status": status, "json": {"code": code, "message": message}, "error": "http"
	}
