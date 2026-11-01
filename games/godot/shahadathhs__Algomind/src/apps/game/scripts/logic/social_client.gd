class_name SocialClient
extends RefCounted
## Profile, boards, badges, the player's daily result, and share links, over the same
## authenticated path as everything else (AccountClient refreshes the token). Every method is a
## coroutine and returns { ok, message, data }: `data` is the parsed answer (see SocialParse),
## `message` a plain sentence when it failed, and `error` the transport error ("signed_out",
## "offline", "http", ...). Nothing here uploads progress; that stays in ProgressSync.

const PAGE := 20
const REPORT_REASON := "Name reported by a player"

var _client: AccountClient


func _init(client: AccountClient) -> void:
	_client = client


func signed_in() -> bool:
	return _client.account.signed_in()


func profile() -> Dictionary:
	return _finish(await _client.call_authed("GET", "me/profile"), SocialParse.profile)


## `changes` holds any of displayName (String or null), leaderboardOptIn, hideName.
func save_profile(changes: Dictionary) -> Dictionary:
	return _finish(await _client.call_authed("PUT", "me/profile", changes), SocialParse.profile)


## scope "points" (key is the period: all, week, month), "level" (key is the slug), or "daily"
## (key is the date). Boards are only for signed-in players; the token also gets their own place.
func board(scope: String, key: String, offset: int = 0) -> Dictionary:
	var path := board_path(scope, key, offset)
	if path.is_empty():
		return _bad("NO SUCH BOARD")
	return _finish(await _client.call_authed("GET", path), SocialParse.board)


func report(public_id: String) -> Dictionary:
	var body := {"publicId": public_id, "reason": REPORT_REASON}
	var response := await _client.call_authed("POST", "leaderboards/report", body)
	return {"ok": response["ok"], "message": _message(response), "data": {}}


func achievements() -> Dictionary:
	return _finish(await _client.call_authed("GET", "me/achievements"), SocialParse.achievements)


func daily_me() -> Dictionary:
	return _finish(await _client.call_authed("GET", "me/daily"), SocialParse.daily_me)


## A share link for a solved level (`date` empty) or daily (`date` set).
func share(level_slug: String, date: String = "") -> Dictionary:
	var body := {"kind": "daily" if not date.is_empty() else "level", "levelSlug": level_slug}
	if not date.is_empty():
		body["date"] = date
	return _finish(await _client.call_authed("POST", "me/share", body), SocialParse.share)


## The request path of a board page, or "" for a scope or key that is not valid.
static func board_path(scope: String, key: String, offset: int = 0) -> String:
	var paging := "limit=%d&offset=%d" % [PAGE, maxi(offset, 0)]
	match scope:
		"points":
			if key in ["all", "week", "month"]:
				return "leaderboards/points?period=%s&%s" % [key, paging]
		"level":
			if ContentStore.is_safe_name(key):
				return "leaderboards/levels/%s?%s" % [key, paging]
		"daily":
			if DailyDates.is_valid(key):
				return "leaderboards/daily/%s?%s" % [key, paging]
	return ""


func _finish(response: Dictionary, parser: Callable) -> Dictionary:
	if not response["ok"]:
		var failed := {"ok": false, "message": _message(response), "data": {}}
		failed["error"] = str(response.get("error", ""))
		failed["status"] = int(response.get("status", 0))
		return failed
	var data: Dictionary = parser.call(response["json"])
	if data.is_empty():
		return {
			"ok": false,
			"error": "parse",
			"message": "THE SERVER SENT SOMETHING UNREADABLE",
			"data": {},
		}
	return {"ok": true, "message": "", "data": data}


func _message(response: Dictionary) -> String:
	return "" if response["ok"] else SocialParse.message(response)


static func _bad(text: String) -> Dictionary:
	return {"ok": false, "error": "invalid", "message": text, "data": {}}
