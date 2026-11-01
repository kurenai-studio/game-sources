class_name ProgressSync
extends RefCounted
## Uploads local progress and merges the answer back. This is the ONLY code that sends progress
## anywhere: signed out, it makes no request at all. A failed or interrupted sync changes nothing
## on the device; the merge is applied only after the server answered, and it only adds or
## improves (see ProgressStore.merge_completions), so running it twice gives the same result.
##
## Programs the player solved are sent here too, one request per level (and per daily date), for
## the server to verify and score (see PlayerResults). The client never sends a score, only the
## program.
##
## Result: { status } with status "synced", "signed_out", "offline", or "failed", plus `message`.


static func run(client: AccountClient, progress: ProgressStore) -> Dictionary:
	if not client.account.signed_in():
		return {"status": "signed_out", "message": ""}
	var response := await client.call_authed("POST", "me/progress/sync", _request_body(progress))
	if not response["ok"]:
		return _failure(response)
	var merged := _apply(progress, response["json"])
	if not merged:
		return {"status": "failed", "message": "THE SERVER SENT SOMETHING UNREADABLE"}
	var kept := progress.save()
	client.account.last_sync_at = Time.get_unix_time_from_system()
	if not (client.account.save() and kept):
		# The merged result exists only in memory; do not claim the device is up to date.
		return {"status": "failed", "message": "COULD NOT SAVE ON THIS DEVICE"}
	return await _send_results(client, progress.results)


## The status and message for a failed request.
static func _failure(response: Dictionary) -> Dictionary:
	var error := str(response.get("error", ""))
	var status := "failed"
	if error == "signed_out":
		status = "signed_out"
	elif error in ["offline", "timeout", "disabled"]:
		status = "offline"
	return {"status": status, "message": str(response.get("message", ""))}


## Sends each waiting program, then each waiting daily result (with its date). A program the
## server will never accept (it is not valid, the level is gone, or it is not offered) is dropped;
## a failure of the connection leaves it for the next sync. Stops at the first failure so the
## retry wait applies.
static func _send_results(client: AccountClient, results: PlayerResults) -> Dictionary:
	var failure := await _send_levels(client, results)
	if failure.is_empty():
		failure = await _send_dailies(client, results)
	var saved := results.save()
	if not failure.is_empty():
		return failure
	if not saved:
		return {"status": "failed", "message": "COULD NOT SAVE ON THIS DEVICE"}
	return {"status": "synced", "message": ""}


## One request per level. {} when all were sent, else the failure.
static func _send_levels(client: AccountClient, results: PlayerResults) -> Dictionary:
	for slug in results.pending():
		var entry: Dictionary = results.queue[slug]
		var body := {
			"levelSlug": slug, "levelVersion": entry["levelVersion"], "program": entry["program"]
		}
		var response := await client.call_authed("POST", "me/submissions", body)
		if response["ok"] and typeof(response["json"]) == TYPE_DICTIONARY:
			results.apply_result(slug, response["json"])
			results.drop_if_unchanged(slug, entry)
		elif not response["ok"] and int(response.get("status", 0)) in [404, 409, 422]:
			results.drop_if_unchanged(slug, entry)
		else:
			return _failure(response) if not response["ok"] else _failure({"error": "failed"})
	return {}


## One request per day, claiming that day's challenge with `dailyDate`. {} when all were sent.
static func _send_dailies(client: AccountClient, results: PlayerResults) -> Dictionary:
	for date in results.pending_dailies():
		var entry: Dictionary = results.daily_queue[date]
		var body := {
			"levelSlug": entry["levelSlug"],
			"levelVersion": entry["levelVersion"],
			"program": entry["program"],
			"dailyDate": date,
		}
		var response := await client.call_authed("POST", "me/submissions", body)
		if response["ok"] and typeof(response["json"]) == TYPE_DICTIONARY:
			results.total = int(response["json"].get("total", results.total))
			results.apply_daily(response["json"])
			results.note_badges(response["json"])
			results.drop_daily_if_unchanged(date, entry)
		elif not response["ok"] and int(response.get("status", 0)) in [404, 409, 422]:
			results.drop_daily_if_unchanged(date, entry)
		else:
			return _failure(response) if not response["ok"] else _failure({"error": "failed"})
	return {}


static func _request_body(progress: ProgressStore) -> Dictionary:
	var completed: Array = []
	for item in progress.completions():
		var entry := {
			"levelSlug": item["levelId"],
			"levelVersion": item["levelVersion"],
			"bestCommands": item["bestCommands"],
		}
		if float(item["completedAt"]) > 0.0:
			entry["completedAt"] = item["completedAt"]
		completed.append(entry)
	var body := {"completed": completed}
	if progress.settings.settings_updated_at() > 0.0:
		body["settings"] = {
			"settings": progress.settings.synced_settings(),
			"updatedAt": progress.settings.settings_updated_at(),
		}
	return body


## Applies the server's merged result to the local data. False when it is not what was promised.
static func _apply(progress: ProgressStore, remote: Variant) -> bool:
	if typeof(remote) != TYPE_DICTIONARY or typeof(remote.get("completed")) != TYPE_ARRAY:
		return false
	var incoming: Array = []
	for raw: Variant in remote["completed"]:
		if typeof(raw) != TYPE_DICTIONARY:
			continue
		(
			incoming
			. append(
				{
					"levelId": str(raw.get("levelSlug", "")),
					"levelVersion": int(raw.get("levelVersion", 0)),
					"bestCommands": int(raw.get("bestCommands", 0)),
					"completedAt": float(raw.get("completedAt", 0.0)),
				}
			)
		)
	progress.merge_completions(incoming)
	var settings: Variant = remote.get("settings")
	if typeof(settings) == TYPE_DICTIONARY and typeof(settings.get("settings")) == TYPE_DICTIONARY:
		progress.settings.apply_synced_settings(
			settings["settings"], float(settings.get("updatedAt", 0.0))
		)
	return true
