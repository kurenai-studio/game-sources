class_name AccountFixtures
extends RefCounted
## A scripted stand-in for the API: it records every request and answers from queued responses.

var calls: Array[Dictionary] = []
## "METHOD path" -> Array of result Dictionaries, used in order (the last one repeats).
var routes := {}


func send(method: String, path: String, body: Variant, bearer: String) -> Dictionary:
	calls.append({"method": method, "path": path, "body": body, "bearer": bearer})
	var queue: Array = routes.get("%s %s" % [method, path], [])
	if queue.is_empty():
		return AccountFixtures.fail(404, "NOT_FOUND")
	var result: Dictionary = queue.pop_front() if queue.size() > 1 else queue[0]
	# A route can be slow: it answers a few frames later, so calls can overlap.
	for i in int(result.get("delay_frames", 0)):
		await Engine.get_main_loop().process_frame
	return result


func on(method: String, path: String, result: Dictionary) -> void:
	var key := "%s %s" % [method, path]
	if not routes.has(key):
		routes[key] = []
	routes[key].append(result)


func count(path: String) -> int:
	var n := 0
	for call in calls:
		if call["path"] == path:
			n += 1
	return n


static func ok(json: Variant = null, status: int = 200) -> Dictionary:
	return {"ok": true, "status": status, "json": json, "error": ""}


static func fail(status: int, code: String = "") -> Dictionary:
	var body: Variant = {"code": code, "message": code} if not code.is_empty() else null
	return {"ok": false, "status": status, "json": body, "error": "http"}


static func offline() -> Dictionary:
	return {"ok": false, "status": 0, "json": null, "error": "offline"}


static func session(
	email: String, access: String, refresh: String, expires: int = 900
) -> Dictionary:
	return ok(
		{
			"accessToken": access,
			"refreshToken": refresh,
			"expiresIn": expires,
			"user": {"id": "u1", "email": email, "role": "PLAYER", "mustChangePassword": false},
		}
	)
