extends Node
## ApiClient (autoload) — talks to the Galaxy Shooter backend
## (see backend/server.py). Every method takes a Callable that receives
## one Dictionary: {ok: bool, data: Variant, error: String}.
## When the backend is unreachable the game keeps working offline:
## scores are stored on the device and the leaderboard falls back to it.

func _request(method: HTTPClient.Method, path: String, body: Dictionary, use_auth: bool, cb: Callable) -> void:
	var http := HTTPRequest.new()
	http.timeout = 12.0
	add_child(http)
	var headers: PackedStringArray = ["Content-Type: application/json"]
	if use_auth and Session.token != "":
		headers.append("Authorization: Bearer " + Session.token)
	var body_str := ""
	if method != HTTPClient.METHOD_GET:
		body_str = JSON.stringify(body)
	var err := http.request(Session.api_url + path, headers, method, body_str)
	if err != OK:
		http.queue_free()
		cb.call({"ok": false, "data": null, "error": "Could not start the request."})
		return
	http.request_completed.connect(func(result: int, code: int, _headers: PackedStringArray, bytes: PackedByteArray) -> void:
		http.queue_free()
		if result != HTTPRequest.RESULT_SUCCESS:
			cb.call({"ok": false, "data": null, "error": "Server unreachable — playing offline."})
			return
		var text := bytes.get_string_from_utf8()
		var data: Variant = JSON.parse_string(text)
		if code >= 400:
			var msg := "Request failed (HTTP %d)." % code
			if typeof(data) == TYPE_DICTIONARY and data.has("error"):
				msg = str(data["error"])
			cb.call({"ok": false, "data": data, "error": msg})
			return
		cb.call({"ok": true, "data": data, "error": ""})
	)

func register(username: String, password: String, display_name: String, cb: Callable) -> void:
	_request(HTTPClient.METHOD_POST, "/api/auth/register",
		{"username": username, "password": password, "display_name": display_name}, false, cb)

func login(username: String, password: String, cb: Callable) -> void:
	_request(HTTPClient.METHOD_POST, "/api/auth/login",
		{"username": username, "password": password}, false, cb)

func guest(display_name: String, cb: Callable) -> void:
	_request(HTTPClient.METHOD_POST, "/api/auth/guest", {"display_name": display_name}, false, cb)

func submit_score(score: int, level: int, cb: Callable) -> void:
	_request(HTTPClient.METHOD_POST, "/api/scores", {"score": score, "level": level}, true, cb)

func fetch_leaderboard(limit: int, cb: Callable) -> void:
	_request(HTTPClient.METHOD_GET, "/api/leaderboard?limit=%d" % limit, {}, false, cb)

func ping(cb: Callable) -> void:
	_request(HTTPClient.METHOD_GET, "/api/health", {}, false, cb)
